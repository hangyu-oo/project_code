`timescale 1ns / 1ps

module Uart_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // inoutport signals
    input  logic        rx,
    output logic        tx
);

    logic [7:0] rx_wdata, tx_wdata;
    logic [7:0] rx_rdata, tx_rdata;
    logic tx_start;
    logic rx_done, rx_full, rx_empty;
    logic tx_busy, tx_full, tx_empty;


    APB_SlaveIntf_UART U_UART_APB_SLAVEINTF_UART (
        .*,
        .rx_rdata(rx_rdata),
        .rx_empty(rx_empty),
        .tx_data (tx_wdata)
    );

    fifo U_FIFO_RX (
        .clk(PCLK),
        .reset(PRESET),
        .wr(rx_done && !rx_full),
        .rd(!rx_empty && (PSEL && PENABLE && !PWRITE && (PADDR[3:2] == 2'b00))),
        .wdata(rx_wdata),
        .full(rx_full),
        .empty(rx_empty),
        .rdata(rx_rdata)
    );

    fifo U_FIFO_TX (
        .clk  (PCLK),
        .reset(PRESET),
        .wr   (PSEL && PENABLE && PWRITE && (PADDR[3:2] == 2'b10) && !tx_full),
        .rd   (!tx_empty && !tx_busy),
        .wdata(PWDATA[7:0]),
        .full (tx_full),
        .empty(tx_empty),
        .rdata(tx_rdata)
    );

    uart U_UART (
        .clk     (PCLK),
        .reset   (PRESET),
        .rx      (rx),
        .tx_start(!tx_empty && !tx_busy),
        .tx_data (tx_rdata),
        .tx      (tx),
        .rx_data (rx_wdata),
        .rx_done (rx_done),
        .tx_busy (tx_busy)
    );
endmodule


module APB_SlaveIntf_UART (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal signals
    input  logic [ 7:0] rx_rdata,
    input  logic        rx_empty,
    output logic [ 7:0] tx_data
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign slv_reg0[7:0] = rx_rdata;
    assign slv_reg1[0]   = rx_empty;
    assign tx_data       = slv_reg2[7:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            //slv_reg0 <= 0;
            //slv_reg1 <= 0;
            slv_reg2 <= 0;
            //slv_reg3 <= 0;
            //slv_reg4 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;
                        2'd1: ;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: ;
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule
// module APB_SlaveIntf_UART (
//     input  logic        PCLK,
//     input  logic        PRESET,
//     input  logic [3:0]  PADDR,
//     input  logic        PWRITE,
//     input  logic        PENABLE,
//     input  logic [31:0] PWDATA,
//     input  logic        PSEL,
//     output logic [31:0] PRDATA,
//     output logic        PREADY,
//     input  logic [7:0]  rx_rdata,
//     input  logic        rx_empty,
//     output logic [7:0]  tx_data
// );

//     logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

//     assign slv_reg0[7:0] = rx_rdata;
//     assign slv_reg1[0]   = rx_empty;
//     assign tx_data        = slv_reg2[7:0];

//     always_ff @(posedge PCLK or posedge PRESET) begin
//         if (PRESET) begin
//             PRDATA   <= 32'b0;
//             PREADY   <= 1'b0;
//             slv_reg2 <= 32'b0;
//         end else begin
//             if (PSEL && !PENABLE) begin
//                 if (PWRITE && (PADDR[3:2] == 2'd2)) begin
//                     slv_reg2 <= PWDATA;
//                 end
//             end

//             if (PSEL && PENABLE) begin
//                 PREADY <= 1'b1;
//                 if (!PWRITE) begin
//                     case (PADDR[3:2])
//                         2'd0: PRDATA <= slv_reg0;
//                         2'd1: PRDATA <= slv_reg1;
//                         2'd2: PRDATA <= slv_reg2;
//                         2'd3: PRDATA <= slv_reg3;
//                         default: PRDATA <= 32'h0;
//                     endcase
//                 end
//             end
//         end
//     end
// endmodule

module uart (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       tx_busy
);
    logic b_tick;

    baud_tick_generator U_BAUD_TICK_GEN (
        .clk   (clk),
        .reset (reset),
        .b_tick(b_tick)
    );

    uart_rx U_UART_RX (
        .clk    (clk),
        .reset  (reset),
        .b_tick (b_tick),
        .rx     (rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .reset   (reset),
        .b_tick  (b_tick),
        .tx_start(tx_start),
        .tx_data (tx_data),
        .tx      (tx),
        .tx_busy (tx_busy)
    );

endmodule

module uart_tx (
    input        clk,
    input        reset,
    input        b_tick,
    input        tx_start,
    input  [7:0] tx_data,
    output       tx,
    output       tx_busy
);
    localparam [1:0] IDLE = 2'b00, TX_START = 2'b01, TX_DATA =2'b10, TX_STOP = 2'b11;

    reg [1:0] state_reg, next_state;
    reg tx_busy_reg, tx_busy_next;
    reg tx_reg, tx_next;
    reg [7:0] data_buf_reg, data_buf_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;


    assign tx_busy = tx_busy_reg;
    assign tx = tx_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg <= IDLE;
            tx_busy_reg <= 1'b0;
            tx_reg <= 1'b1;
            data_buf_reg <= 8'h00;
            b_tick_cnt_reg <= 4'b0000;
            bit_cnt_reg <= 3'b000;
        end else begin
            state_reg <= next_state;
            tx_busy_reg <= tx_busy_next;
            tx_reg <= tx_next;
            data_buf_reg <= data_buf_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end

    always @(*) begin
        next_state = state_reg;
        tx_busy_next = tx_busy_reg;
        tx_next = tx_reg;
        data_buf_next = data_buf_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        case (state_reg)
            IDLE: begin
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                if (tx_start) begin
                    b_tick_cnt_next = 0;
                    data_buf_next = tx_data;
                    next_state = TX_START;
                end
            end
            TX_START: begin
                tx_next = 1'b0;
                tx_busy_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next = 0;
                        next_state = TX_DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            TX_DATA: begin
                tx_next = data_buf_reg[0];
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            next_state = TX_STOP;
                        end else begin
                            b_tick_cnt_next = 0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_buf_next = data_buf_reg >> 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            TX_STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        next_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module uart_rx (
    input  logic       clk,
    input  logic       reset,
    input  logic       b_tick,
    input  logic       rx,
    output logic [7:0] rx_data,
    output logic       rx_done
);

    localparam [1:0] RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;

    logic [1:0] c_state, n_state;
    logic [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [7:0] rx_buf_reg, rx_buf_next;
    logic rx_done_reg, rx_done_next;

    assign rx_data = rx_buf_reg;
    assign rx_done = rx_done_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= RX_IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            rx_buf_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            c_state <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            rx_buf_reg <= rx_buf_next;
            rx_done_reg <= rx_done_next;
        end
    end

    always_comb begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        rx_buf_next = rx_buf_reg;
        rx_done_next = rx_done_reg;
        case (c_state)
            RX_IDLE: begin
                rx_done_next = 0;
                if (!rx) begin
                    b_tick_cnt_next = 0;
                    bit_cnt_next = 0;
                    n_state = RX_START;
                end
            end
            RX_START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        n_state         = RX_DATA;
                        bit_cnt_next    = 0;
                        b_tick_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            RX_DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        rx_buf_next[bit_cnt_reg] = rx;
                        if (bit_cnt_reg == 7) begin
                            n_state = RX_STOP; 
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            RX_STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        rx_done_next    = 1'b1;
                        n_state         = RX_IDLE;
                        b_tick_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module baud_tick_generator (
    input  logic clk,
    input  logic reset,
    output logic b_tick
);

    parameter BAUDRATE = 9600 * 16;
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;

    logic [$clog2(BAUD_COUNT)-1:0] counter_reg;
    logic b_tick_reg;

    assign b_tick = b_tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            b_tick_reg  <= 0;
        end else begin
            if (counter_reg == BAUD_COUNT - 1) begin
                counter_reg <= 0;
                b_tick_reg  <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                b_tick_reg  <= 1'b0;
            end
        end
    end
endmodule

module fifo (
    input  logic       clk,
    input  logic       reset,
    input  logic       wr,
    input  logic       rd,
    input  logic [7:0] wdata,
    output logic       full,
    output logic       empty,
    output logic [7:0] rdata
);

    logic [2:0] wptr;
    logic [2:0] rptr;
    logic wr_en;

    assign wr_en = wr & ~full;

    register_file U_REG_FILE (
        .*,
        .wr(wr_en)
    );
    fifo_cu U_FIFO_CU (.*);

endmodule

module register_file #(
    parameter AWIDTH = 3
) (
    input  logic                clk,
    input  logic                wr,
    input  logic [(AWIDTH)-1:0] wptr,
    input  logic [(AWIDTH)-1:0] rptr,
    input  logic [         7:0] wdata,
    output logic [         7:0] rdata
);

    logic [7:0] ram[0:2**AWIDTH -1];

    assign rdata = ram[rptr];
    always_ff @(posedge clk) begin
        if (wr) begin
            ram[wptr] <= wdata;
        end
    end
endmodule

module fifo_cu #(
    parameter AWIDTH = 3
) (
    input  logic                clk,
    input  logic                reset,
    input  logic                wr,     // push
    input  logic                rd,     // pop
    output logic [AWIDTH-1 : 0] wptr,
    output logic [AWIDTH-1 : 0] rptr,
    output logic                full,
    output logic                empty
);


    //output
    logic [AWIDTH-1:0] wptr_reg, wptr_next;
    logic [AWIDTH-1:0] rptr_reg, rptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            wr, rd
        })
            2'b01: begin
                //pop
                full_next = 1'b0;
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (rptr_next == wptr_reg) begin
                        //하나 증가시킬애랑 현재 wptr이랑 같냐
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin
                //push
                empty_next = 1'b0;
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        // 하나 증가시킬애랑 현재 rptr이랑 같냐
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    //not be full, empty
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end

            end
        endcase
    end
endmodule

// `timescale 1ns / 1ps

// module Uart_Periph (
//     // global signal
//     input  logic        PCLK,
//     input  logic        PRESET,
//     // APB Interface Signals
//     input  logic [ 3:0] PADDR,
//     input  logic [31:0] PWDATA,
//     input  logic        PWRITE,
//     input  logic        PENABLE,
//     input  logic        PSEL,
//     output logic [31:0] PRDATA,
//     output logic        PREADY,
//     // inoutport signals
//     input  logic        rx,
//     output logic        tx
// );

//     // ===== RX/TX 경로 신호 =====
//     logic [7:0] rx_wdata;
//     logic [7:0] rx_rdata;
//     logic [7:0] tx_rdata;

//     logic       rx_done, rx_full, rx_empty;
//     logic       tx_busy, tx_full, tx_empty;

//     // ===== APB 슬레이브 (상태/레지스터 맵) =====
//     //  - tx_data는 레지스터 미러 용도이므로 여기선 굳이 사용하지 않음
//     logic [7:0] tx_wdata_dummy;
//     APB_SlaveIntf_UART U_UART_APB_SLAVEINTF_UART (
//         .PCLK,
//         .PRESET,
//         .PADDR,
//         .PWRITE,
//         .PENABLE,
//         .PWDATA,
//         .PSEL,
//         .PRDATA,
//         .PREADY,
//         .rx_rdata (rx_rdata),
//         .rx_empty (rx_empty),
//         .tx_data  (tx_wdata_dummy) // 미러용 (쓰기엔 아래서 PWDATA 직접 사용)
//     );

//     // ===== RX FIFO (UART RX -> CPU 읽기) =====
//     fifo U_FIFO_RX (
//         .clk   (PCLK),
//         .reset (PRESET),
//         .wr    (rx_done && !rx_full),
//         .rd    (!rx_empty && (PSEL && PENABLE && !PWRITE && (PADDR[3:2] == 2'b00))),
//         .wdata (rx_wdata),
//         .full  (rx_full),
//         .empty (rx_empty),
//         .rdata (rx_rdata)
//     );

//     // ====== TX 시작/POP 펄스 생성 (핵심 수정) ======
//     // raw 조건: 보낼 데이터 있고, 현재 전송 중이 아닐 때
//     wire  tx_start_raw = (!tx_empty && !tx_busy);

//     // 상승에지 검출 → pop 펄스 (N클럭)
//     logic tx_start_prev;
//     always_ff @(posedge PCLK or posedge PRESET) begin
//         if (PRESET) tx_start_prev <= 1'b0;
//         else        tx_start_prev <= tx_start_raw;
//     end
//     wire tx_pop = tx_start_raw & ~tx_start_prev;

//     // UART 시작 신호는 pop보다 1클럭 지연 (N+1클럭)
//     logic tx_start_d;
//     always_ff @(posedge PCLK or posedge PRESET) begin
//         if (PRESET) tx_start_d <= 1'b0;
//         else        tx_start_d <= tx_pop;
//     end

//     // ===== TX FIFO (CPU 쓰기 -> UART TX 읽기) =====
//     fifo U_FIFO_TX (
//         .clk   (PCLK),
//         .reset (PRESET),
//         .wr    (PSEL && PENABLE && PWRITE && (PADDR[3:2] == 2'b10) && !tx_full),
//         .rd    (tx_pop),              // ★ pop은 N클럭에 1클럭 펄스
//         .wdata (PWDATA[7:0]),         // ★ 쓰기는 PWDATA 직접 사용(동일 사이클에 안전)
//         .full  (tx_full),
//         .empty (tx_empty),
//         .rdata (tx_rdata)
//     );

//     // ===== UART (TX는 N+1클럭에 시작) =====
//     uart U_UART (
//         .clk     (PCLK),
//         .reset   (PRESET),
//         .rx      (rx),
//         .tx_start(tx_start_d),        // ★ pop의 다음 클럭에 전송 시작
//         .tx_data (tx_rdata),
//         .tx      (tx),
//         .rx_data (rx_wdata),
//         .rx_done (rx_done),
//         .tx_busy (tx_busy)
//     );

// endmodule



// module APB_SlaveIntf_UART (
//     // global signals
//     input  logic        PCLK,
//     input  logic        PRESET,
//     // APB Interface Signals
//     input  logic [ 3:0] PADDR,
//     input  logic        PWRITE,
//     input  logic        PENABLE,
//     input  logic [31:0] PWDATA,
//     input  logic        PSEL,
//     output logic [31:0] PRDATA,
//     output logic        PREADY,
//     // Internal signals
//     input  logic [ 7:0] rx_rdata,
//     input  logic        rx_empty,
//     output logic [ 7:0] tx_data
// );
//     logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

//     assign slv_reg0[7:0] = rx_rdata;
//     assign slv_reg1[0]   = rx_empty;
//     assign tx_data       = slv_reg2[7:0];

//     always_ff @(posedge PCLK, posedge PRESET) begin
//         if (PRESET) begin
//             //slv_reg0 <= 0;
//             //slv_reg1 <= 0;
//             slv_reg2 <= 0;
//             //slv_reg3 <= 0;
//             //slv_reg4 <= 0;
//         end else begin
//             if (PSEL && PENABLE) begin
//                 PREADY <= 1'b1;
//                 if (PWRITE) begin
//                     case (PADDR[3:2])
//                         2'd0: ;
//                         2'd1: ;
//                         2'd2: slv_reg2 <= PWDATA;
//                         2'd3: ;
//                     endcase
//                 end else begin
//                     case (PADDR[3:2])
//                         2'd0: PRDATA <= slv_reg0;
//                         2'd1: PRDATA <= slv_reg1;
//                         2'd2: PRDATA <= slv_reg2;
//                         2'd3: PRDATA <= slv_reg3;
//                     endcase
//                 end
//             end else begin
//                 PREADY <= 1'b0;
//             end
//         end
//     end

// endmodule

// module uart (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic       rx,
//     input  logic       tx_start,
//     input  logic [7:0] tx_data,
//     output logic       tx,
//     output logic [7:0] rx_data,
//     output logic       rx_done,
//     output logic       tx_busy
// );
//     logic b_tick;

//     baud_tick_generator U_BAUD_TICK_GEN (
//         .clk   (clk),
//         .reset (reset),
//         .b_tick(b_tick)
//     );

//     uart_rx U_UART_RX (
//         .clk    (clk),
//         .reset  (reset),
//         .b_tick (b_tick),
//         .rx     (rx),
//         .rx_data(rx_data),
//         .rx_done(rx_done)
//     );

//     uart_tx U_UART_TX (
//         .clk     (clk),
//         .reset   (reset),
//         .b_tick  (b_tick),
//         .tx_start(tx_start),
//         .tx_data (tx_data),
//         .tx      (tx),
//         .tx_busy (tx_busy)
//     );

// endmodule

// module uart_tx (
//     input        clk,
//     input        reset,
//     input        b_tick,
//     input        tx_start,
//     input  [7:0] tx_data,
//     output       tx,
//     output       tx_busy
// );
//     localparam [1:0] IDLE = 2'b00, TX_START = 2'b01, TX_DATA =2'b10, TX_STOP = 2'b11;

//     reg [1:0] state_reg, next_state;
//     reg tx_busy_reg, tx_busy_next;
//     reg tx_reg, tx_next;
//     reg [7:0] data_buf_reg, data_buf_next;
//     reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
//     reg [2:0] bit_cnt_reg, bit_cnt_next;


//     assign tx_busy = tx_busy_reg;
//     assign tx = tx_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             state_reg <= IDLE;
//             tx_busy_reg <= 1'b0;
//             tx_reg <= 1'b1;
//             data_buf_reg <= 8'h00;
//             b_tick_cnt_reg <= 4'b0000;
//             bit_cnt_reg <= 3'b000;
//         end else begin
//             state_reg <= next_state;
//             tx_busy_reg <= tx_busy_next;
//             tx_reg <= tx_next;
//             data_buf_reg <= data_buf_next;
//             b_tick_cnt_reg <= b_tick_cnt_next;
//             bit_cnt_reg <= bit_cnt_next;
//         end
//     end

//     always @(*) begin
//         next_state = state_reg;
//         tx_busy_next = tx_busy_reg;
//         tx_next = tx_reg;
//         data_buf_next = data_buf_reg;
//         b_tick_cnt_next = b_tick_cnt_reg;
//         bit_cnt_next = bit_cnt_reg;
//         case (state_reg)
//             IDLE: begin
//                 tx_next = 1'b1;
//                 tx_busy_next = 1'b0;
//                 if (tx_start) begin
//                     b_tick_cnt_next = 0;
//                     data_buf_next = tx_data;
//                     next_state = TX_START;
//                 end
//             end
//             TX_START: begin
//                 tx_next = 1'b0;
//                 tx_busy_next = 1'b1;
//                 if (b_tick) begin
//                     if (b_tick_cnt_reg == 15) begin
//                         b_tick_cnt_next = 0;
//                         bit_cnt_next = 0;
//                         next_state = TX_DATA;
//                     end else begin
//                         b_tick_cnt_next = b_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//             TX_DATA: begin
//                 tx_next = data_buf_reg[0];
//                 if (b_tick) begin
//                     if (b_tick_cnt_reg == 15) begin
//                         if (bit_cnt_reg == 7) begin
//                             b_tick_cnt_next = 0;
//                             next_state = TX_STOP;
//                         end else begin
//                             b_tick_cnt_next = 0;
//                             bit_cnt_next = bit_cnt_reg + 1;
//                             data_buf_next = data_buf_reg >> 1;
//                         end
//                     end else begin
//                         b_tick_cnt_next = b_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//             TX_STOP: begin
//                 tx_next = 1'b1;
//                 if (b_tick) begin
//                     if (b_tick_cnt_reg == 15) begin
//                         next_state = IDLE;
//                     end else begin
//                         b_tick_cnt_next = b_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//         endcase
//     end

// endmodule

// module uart_rx (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic       b_tick,
//     input  logic       rx,
//     output logic [7:0] rx_data,
//     output logic       rx_done
// );

//     localparam [1:0] RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;

//     logic [1:0] c_state, n_state;
//     logic [4:0] b_tick_cnt_reg, b_tick_cnt_next;
//     logic [2:0] bit_cnt_reg, bit_cnt_next;
//     logic [7:0] rx_buf_reg, rx_buf_next;
//     logic rx_done_reg, rx_done_next;

//     assign rx_data = rx_buf_reg;
//     assign rx_done = rx_done_reg;

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             c_state <= RX_IDLE;
//             b_tick_cnt_reg <= 0;
//             bit_cnt_reg <= 0;
//             rx_buf_reg <= 0;
//             rx_done_reg <= 0;
//         end else begin
//             c_state <= n_state;
//             b_tick_cnt_reg <= b_tick_cnt_next;
//             bit_cnt_reg <= bit_cnt_next;
//             rx_buf_reg <= rx_buf_next;
//             rx_done_reg <= rx_done_next;
//         end
//     end

//     always_comb begin
//         n_state = c_state;
//         b_tick_cnt_next = b_tick_cnt_reg;
//         bit_cnt_next = bit_cnt_reg;
//         rx_buf_next = rx_buf_reg;
//         rx_done_next = rx_done_reg;
//         case (c_state)
//             RX_IDLE: begin
//                 rx_done_next = 0;
//                 if (!rx) begin
//                     b_tick_cnt_next = 0;
//                     bit_cnt_next = 0;
//                     n_state = RX_START;
//                 end
//             end
//             RX_START: begin
//                 if (b_tick) begin
//                     if (b_tick_cnt_reg == 7) begin
//                         n_state         = RX_DATA;
//                         bit_cnt_next    = 0;
//                         b_tick_cnt_next = 0;
//                     end else begin
//                         b_tick_cnt_next = b_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//             RX_DATA: begin
//                 if (b_tick) begin
//                     if (b_tick_cnt_reg == 15) begin
//                         b_tick_cnt_next = 0;
//                         rx_buf_next[bit_cnt_reg] = rx;
//                         if (bit_cnt_reg == 7) begin
//                             n_state = RX_STOP; 
//                         end else begin
//                             bit_cnt_next = bit_cnt_reg + 1;
//                         end
//                     end else begin
//                         b_tick_cnt_next = b_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//             RX_STOP: begin
//                 if (b_tick) begin
//                     if (b_tick_cnt_reg == 15) begin
//                         rx_done_next    = 1'b1;
//                         n_state         = RX_IDLE;
//                         b_tick_cnt_next = 0;
//                     end else begin
//                         b_tick_cnt_next = b_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//         endcase
//     end
// endmodule

// module baud_tick_generator (
//     input  logic clk,
//     input  logic reset,
//     output logic b_tick
// );

//     parameter BAUDRATE = 9600 * 16;
//     localparam BAUD_COUNT = 100_000_000 / BAUDRATE;

//     logic [$clog2(BAUD_COUNT)-1:0] counter_reg;
//     logic b_tick_reg;

//     assign b_tick = b_tick_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             counter_reg <= 0;
//             b_tick_reg  <= 0;
//         end else begin
//             if (counter_reg == BAUD_COUNT - 1) begin
//                 counter_reg <= 0;
//                 b_tick_reg  <= 1'b1;
//             end else begin
//                 counter_reg <= counter_reg + 1;
//                 b_tick_reg  <= 1'b0;
//             end
//         end
//     end
// endmodule

// module fifo (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic       wr,
//     input  logic       rd,
//     input  logic [7:0] wdata,
//     output logic       full,
//     output logic       empty,
//     output logic [7:0] rdata
// );

//     logic [2:0] wptr;
//     logic [2:0] rptr;
//     logic wr_en;

//     assign wr_en = wr & ~full;

//     register_file U_REG_FILE (
//         .*,
//         .wr(wr_en)
//     );
//     fifo_cu U_FIFO_CU (.*);

// endmodule

// module register_file #(
//     parameter AWIDTH = 3
// ) (
//     input  logic                clk,
//     input  logic                wr,
//     input  logic [(AWIDTH)-1:0] wptr,
//     input  logic [(AWIDTH)-1:0] rptr,
//     input  logic [         7:0] wdata,
//     output logic [         7:0] rdata,
//     input logic                 rd
// );

//     logic [7:0] ram[0:2**AWIDTH -1];
//     logic [7:0] rdata_reg;

//     assign rdata = ram[rptr];
//     always_ff @(posedge clk) begin
//         if (wr) ram[wptr] <= wdata;
//         if (rd) rdata_reg <= ram[rptr];   // ★ pop 시점의 값을 1클럭 홀드
//     end    
// endmodule

// module fifo_cu #(
//     parameter AWIDTH = 3
// ) (
//     input  logic                clk,
//     input  logic                reset,
//     input  logic                wr,     // push
//     input  logic                rd,     // pop
//     output logic [AWIDTH-1 : 0] wptr,
//     output logic [AWIDTH-1 : 0] rptr,
//     output logic                full,
//     output logic                empty
// );


//     //output
//     logic [AWIDTH-1:0] wptr_reg, wptr_next;
//     logic [AWIDTH-1:0] rptr_reg, rptr_next;
//     logic full_reg, full_next;
//     logic empty_reg, empty_next;

//     assign wptr  = wptr_reg;
//     assign rptr  = rptr_reg;
//     assign full  = full_reg;
//     assign empty = empty_reg;

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             wptr_reg  <= 0;
//             rptr_reg  <= 0;
//             full_reg  <= 0;
//             empty_reg <= 1;
//         end else begin
//             wptr_reg  <= wptr_next;
//             rptr_reg  <= rptr_next;
//             full_reg  <= full_next;
//             empty_reg <= empty_next;
//         end
//     end

//     always_comb begin
//         wptr_next  = wptr_reg;
//         rptr_next  = rptr_reg;
//         full_next  = full_reg;
//         empty_next = empty_reg;
//         case ({
//             wr, rd
//         })
//             2'b01: begin
//                 //pop
//                 full_next = 1'b0;
//                 if (!empty_reg) begin
//                     rptr_next = rptr_reg + 1;
//                     full_next = 1'b0;
//                     if (rptr_next == wptr_reg) begin
//                         //하나 증가시킬애랑 현재 wptr이랑 같냐
//                         empty_next = 1'b1;
//                     end
//                 end
//             end
//             2'b10: begin
//                 //push
//                 empty_next = 1'b0;
//                 if (!full_reg) begin
//                     wptr_next  = wptr_reg + 1;
//                     empty_next = 1'b0;
//                     if (wptr_next == rptr_reg) begin
//                         // 하나 증가시킬애랑 현재 rptr이랑 같냐
//                         full_next = 1'b1;
//                     end
//                 end
//             end
//             2'b11: begin
//                 if (empty_reg == 1'b1) begin
//                     wptr_next  = wptr_reg + 1;
//                     empty_next = 1'b0;
//                 end else if (full_reg == 1'b1) begin
//                     rptr_next = rptr_reg + 1;
//                     full_next = 1'b0;
//                 end else begin
//                     //not be full, empty
//                     wptr_next = wptr_reg + 1;
//                     rptr_next = rptr_reg + 1;
//                 end

//             end
//         endcase
//     end
// endmodule