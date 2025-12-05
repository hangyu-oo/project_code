`timescale 1ns/1ps

// ========= 시뮬 파라미터 =========
parameter CLOCK_PERIOD_NS = 10;          // 100 MHz
parameter BAUD            = 9600;
parameter BIT_PER_CLOCK   = 100_000_000 / BAUD;  // = 10416
parameter BIT_PERIOD      = BIT_PER_CLOCK * CLOCK_PERIOD_NS;

// ========= DUT용 인터페이스 =========
interface uart_apb_if();
  // clock/reset
  logic clk;
  logic rst;

  // UART pins
  logic rx;
  logic tx;

  // APB
  logic [3:0]  PADDR;
  logic [31:0] PWDATA;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;

  // for scoreboard/monitor sharing
  logic [7:0] gen_data;    // generator가 만든 데이터 (참값)
  logic [7:0] tx_captured; // monitor가 캡처한 데이터
endinterface

// ========= 트랜잭션 =========
class transaction;
  rand bit [7:0] data;
       bit [7:0] observed;

  function void display(string tag);
    $display("%t [%s] data=%0d(0x%02h) observed=%0d(0x%02h)",
              $time, tag, data, data, observed, observed);
  endfunction
endclass

// ========= 제너레이터 =========
class generator;
  mailbox #(transaction) gen2drv;
  event                  gen_next;

  int total;

  function new(mailbox #(transaction) gen2drv, event gen_next);
    this.gen2drv = gen2drv;
    this.gen_next = gen_next;
  endfunction

  task run(int n);
    repeat(n) begin
      transaction tr = new();
      assert(tr.randomize()) else $fatal("[GEN] randomize failed");
      total++;
      gen2drv.put(tr);
      tr.display("GEN");
      @(gen_next);
    end
  endtask
endclass

// ========= UART 라인 드라이버 (rx 비트뱅잉) =========
class uart_line_driver;
  virtual uart_apb_if vif;
  mailbox #(transaction) gen2drv;

  function new(mailbox #(transaction) gen2drv, virtual uart_apb_if vif);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task reset();
    vif.rx  = 1'b1; // idle
    vif.rst = 1'b1;
    repeat (5) @(posedge vif.clk);
    vif.rst = 1'b0;
    $display("[%0t][DRV] reset done", $time);
  endtask

  // 8N1, LSB-first (고정)
  task send_byte(bit [7:0] b);
    // start
    vif.rx = 1'b0;
    #(BIT_PERIOD);

    // data bits (LSB -> MSB)
    for (int i = 0; i < 8; i++) begin
      vif.rx = b[i];
      #(BIT_PERIOD);
    end

    // stop
    vif.rx = 1'b1;
    #(BIT_PERIOD);
  endtask

  task run();
    forever begin
      transaction tr; gen2drv.get(tr);
      vif.gen_data = tr.data;     // 참값 공유
      send_byte(tr.data);
      tr.display("DRV");
      @(posedge vif.clk); // 한 박자 여유
    end
  endtask
endclass

// ========= APB 매니저 BFM (RX 읽어 TX 쓰기) =========
class apb_manager;
  virtual uart_apb_if vif;

  // 레지스터 오프셋
  localparam RXDATA = 4'h0; // [3:2]==2'b00
  localparam STATUS = 4'h4; // [3:2]==2'b01, [0]=rx_empty
  localparam TXDATA = 4'h8; // [3:2]==2'b10

  function new(virtual uart_apb_if vif);
    this.vif = vif;
  endfunction

  // APB primitive
  task apb_idle();
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b0;
    vif.PADDR   <= '0;
    vif.PWDATA  <= '0;
    @(posedge vif.clk);
  endtask

  task apb_read(input [3:0] addr, output logic [31:0] rdata);
    // SETUP
    vif.PSEL    <= 1'b1;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b0;
    vif.PADDR   <= addr;
    @(posedge vif.clk);

    // ACCESS
    vif.PENABLE <= 1'b1;
    do @(posedge vif.clk); while (!vif.PREADY);

    rdata = vif.PRDATA;

    // IDLE
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    @(posedge vif.clk);
  endtask

  task apb_write(input [3:0] addr, input [31:0] wdata);
    // SETUP
    vif.PSEL    <= 1'b1;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b1;
    vif.PADDR   <= addr;
    vif.PWDATA  <= wdata;
    @(posedge vif.clk);

    // ACCESS
    vif.PENABLE <= 1'b1;
    do @(posedge vif.clk); while (!vif.PREADY);

    // IDLE
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b0;
    @(posedge vif.clk);
  endtask

  // RX_EMPTY 폴링 → 데이터 읽기 → TX로 쓰기
  task run();
    apb_idle();
    forever begin
      logic [31:0] status, rxdata32;
      // rx_empty==0 될 때까지 폴링
      do begin
        apb_read(STATUS, status);
      end while (status[0] == 1'b1); // 1이면 empty

      // 데이터 읽고
      apb_read(RXDATA, rxdata32);
      // 바로 TX FIFO에 씀
      apb_write(TXDATA, {24'h0, rxdata32[7:0]});
    end
  endtask
endclass

// ========= UART TX 모니터 (tx 라인에서 바이트 복원) =========
class uart_tx_monitor;
  virtual uart_apb_if vif;
  mailbox #(transaction) mon2scb;
  transaction tr; // 멤버로 둠

  function new(mailbox #(transaction) mon2scb, virtual uart_apb_if vif);
    this.vif = vif;
    this.mon2scb = mon2scb;
    this.tr = new(); // 여기서 한 번만 생성
  endfunction

  task run();
    forever begin
      // start 비트 하강에지 검출
      @(negedge vif.tx);
      // 데이터 비트 0의 중앙을 맞추기 위해 0.5비트 대기 후
      #(BIT_PERIOD/2);

      tr.observed = '0;
      // 정확히 8개의 데이터 비트만 샘플 (LSB 먼저)
      for (int i=0; i<8; i++) begin
        #(BIT_PERIOD);
        tr.observed[i] = vif.tx;
      end

      // stop 비트는 1이어야 함 (경고만)
      #(BIT_PERIOD);
      if (vif.tx !== 1'b1) begin
        $warning("[%0t][MON] stop bit is not HIGH", $time);
      end

      tr.data = vif.gen_data;
      vif.tx_captured = tr.observed;
      tr.display("MON");
      mon2scb.put(tr);
      tr = new(); // 다음 사이클용 새 객체
    end
  endtask
endclass


// ========= 스코어보드 =========
class scoreboard;
  mailbox #(transaction) mon2scb;
  event                  gen_next;

  int pass, fail;

  function new(mailbox #(transaction) mon2scb, event gen_next);
    this.mon2scb = mon2scb;
    this.gen_next = gen_next;
  endfunction

  task run();
    forever begin
      transaction tr; mon2scb.get(tr);
      if (tr.observed === tr.data) begin
        pass++;
        $display("[%0t][SCB] PASS recv=0x%02h send=0x%02h", $time, tr.observed, tr.data);
      end else begin
        fail++;
        $display("[%0t][SCB] FAIL recv=0x%02h send=0x%02h", $time, tr.observed, tr.data);
      end
      -> gen_next;
    end
  endtask
endclass

// ========= 환경 =========
class environment;
  // plumbing
  mailbox #(transaction) gen2drv;
  mailbox #(transaction) mon2scb;

  generator        gen;
  uart_line_driver drv_uart;
  apb_manager      apb;
  uart_tx_monitor  mon;
  scoreboard       scb;

  event gen_next;

  virtual uart_apb_if vif;

  function new(virtual uart_apb_if vif);
    this.vif = vif;
    gen2drv = new();
    mon2scb = new();
    gen     = new(gen2drv, gen_next);
    drv_uart= new(gen2drv, vif);
    apb     = new(vif);
    mon     = new(mon2scb, vif);
    scb     = new(mon2scb, gen_next);
  endfunction

  task reset();
    drv_uart.reset();
  endtask

  task run(int n);
    fork
      gen.run(n);
      drv_uart.run();
      apb.run();
      mon.run();
      scb.run();
    join_any
  endtask

  task report();
    $display("================================");
    $display("            TEST REPORT         ");
    $display(" total : %0d", gen.total);
    $display(" pass  : %0d", scb.pass);
    $display(" fail  : %0d", scb.fail);
    $display("================================");
  endtask
endclass

// ========= DUT 인스턴스 =========
// 주의: DUT 포트명은 네가 준 Uart_Periph와 동일하게 사용
module tb_uart_periph_loopback;
  uart_apb_if uif();
  environment env;

  // DUT
  Uart_Periph dut (
    .PCLK   (uif.clk),
    .PRESET (uif.rst),
    .PADDR  (uif.PADDR),
    .PWDATA (uif.PWDATA),
    .PWRITE (uif.PWRITE),
    .PENABLE(uif.PENABLE),
    .PSEL   (uif.PSEL),
    .PRDATA (uif.PRDATA),
    .PREADY (uif.PREADY),
    .rx     (uif.rx),
    .tx     (uif.tx)
  );

  // 100 MHz
  initial uif.clk = 0;
  always #(CLOCK_PERIOD_NS/2) uif.clk = ~uif.clk;

  initial begin
    // 기본값
    uif.PADDR   = '0;
    uif.PWDATA  = '0;
    uif.PWRITE  = 0;
    uif.PENABLE = 0;
    uif.PSEL    = 0;
    uif.rx      = 1'b1;

    env = new(uif);
    env.reset();
    // 100회 테스트
    env.run(100);

    // 약간의 여유 후 마감
    repeat (1000) @(posedge uif.clk);
    env.report();
    $stop;
  end
endmodule
