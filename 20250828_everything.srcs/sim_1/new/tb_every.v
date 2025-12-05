`timescale 1ns / 1ps

module tb_mode_selector;
    parameter micro_sec = 1000;
    parameter US = 1000, MS = 1_000_000;
    reg clk;

    reg rst;
    reg Btn_D, Btn_L, Btn_R, Btn_U;
    reg [1:0] sw;
    reg echo;
    reg rx;
    integer i;
    wire tx, trig;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    // assign dht_io = (dht11_sensor_enable) ? dht11_sensor_reg : 1'bz;

    everything_top_module dut (
        .clk     (clk),
        .rst     (rst),
        .Btn_L   (Btn_L),
        .Btn_R   (Btn_R),
        .Btn_U   (Btn_U),
        .Btn_D   (Btn_D),
        .sw      (sw),
        .echo    (echo),      //from sr04
        .rx      (rx),
        .tx      (tx),
        .trig    (trig),      //to sr04
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (led),
        .dht_io  (dht_io)
    );

    // 100MHz 클럭 생성
    always #5 clk = ~clk;  // 주기 10ns

    initial begin
        #0;
        clk = 0;
        rst = 1;
        Btn_D = 0;
        Btn_L = 0;
        Btn_R = 0;
        Btn_U = 0;
        echo = 0;
        sw = 0;
        rx = 0;
        #10;
        rst = 0;
        #100;

        send_uart("1");
        #10;
        send_uart("r");
        #10;
        send_uart("s");
        #10;
        send_uart("c");
        #10;
        send_uart("m");
        #10;
        send_uart("M");
        #10;
        sw[1] = 1;
        #10;
        send_uart("+");
        #10;
        send_uart("L");
        #10;
        send_uart("L");
        #10;
        send_uart("+");
        #10;
        send_uart("R");
        #10;
        send_uart("-");
        #10;
        sw[1] = 0;
        #100;

        $stop;
    end

    // // Stimulus
    // initial begin
    //     // 초기화
    //     rst = 1;
    //     clk = 0;
    //     Btn_D = 0;
    //     Btn_L = 0;
    //     Btn_R = 0;
    //     Btn_U = 0;
    //     echo = 0;
    //     sw = 0;
    //     rx = 1;
    //     dht11_sensor_enable = 0;
    //     dht11_sensor_reg = 0;
    //     dht11_sensor_data = 40'b10101010_00001111_11000110_00000000_01111111;
    //     i = 0;
    //     #200;
    //     rst = 0;
    //     #(1*MS);
    //     send_uart_byte("3");
    //     #(1*MS);
    //     #(1*MS);
    //     send_uart_byte(8'h73);

    //     // DHT11 start 시퀀스 시뮬레이션
    //     #(18 * MS);          // start LOW (18ms)
    //     #(30 * US);          // wait HIGH (30us)

    //     // sensor enable
    //     dht11_sensor_enable = 1;

    //     // sync 신호
    //     #(80 * US); 
    //     dht11_sensor_reg = 1;
    //     #(80 * US);

    //     // 40bit 데이터 전송
    //     for (i = 0; i < 40; i = i + 1) begin
    //         dht11_sensor_reg = 0;
    //         #(50 * US);       // LOW 50us
    //         dht11_sensor_reg = 1;
    //         if (dht11_sensor_data[39-i]) begin
    //             #(70 * US);    // HIGH 1
    //         end else begin
    //             #(28 * US);    // HIGH 0
    //         end
    //     end

    //     dht11_sensor_reg = 0;
    //     #(50 * US);
    //     dht11_sensor_enable = 0;

    //     #US;
    //     $stop;


    //     $stop;
    // end


    task send_uart(input [7:0] send_data);
        integer i;
        begin
            rx = 0;
            #(104166);
            for (i = 0; i < 8; i = i + 1) begin
                rx = send_data[i];
                #(104166);
            end
            rx = 1;
            #(104166);
        end
    endtask
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            // start bit
            rx = 0;
            #(104167);  // 1/9600*1e9 ns ≈ 104.167us
            // data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(104167);
            end
            // stop bit
            rx = 1;
            #(104167);
        end
    endtask
endmodule
