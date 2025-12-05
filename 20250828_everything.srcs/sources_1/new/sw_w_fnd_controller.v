`timescale 1ns / 1ps

module sw_w_fnd_controller (
    input         clk,
    input         reset,
    input         mode,
    input  [23:0] i_time,
    output [ 7:0] fnd_data,
    output [ 3:0] fnd_com
);

    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [3:0] w_bcd1, w_bcd2;
    wire [3:0] w_bcd;
    wire [2:0] w_sel;
    wire w_clk_1khz;
    wire [3:0] w_dot_data;

    clk_div_1khz U_CLK_DIV_1KHZ (
        .clk(clk),
        .reset(reset),
        .o_clk_1khz(w_clk_1khz)
    );
    counter_8 U_COUNTER_8 (
        .clk  (w_clk_1khz),
        .reset(reset),
        .sel  (w_sel)
    );

    decoder_2X4 U_DECODER_2X4 (
        .sel(w_sel[1:0]),
        .fnd_com(fnd_com)
    );

    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS (
        .count_data(i_time[6:0]),
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10)

    );

    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS (
        .count_data(i_time[12:7]),
        .digit_1(w_sec_digit_1),
        .digit_10(w_sec_digit_10)

    );
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS (
        .count_data(i_time[18:13]),
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS (
        .count_data(i_time[23:19]),
        .digit_1(w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    mux_2x1_bcd U_SW_CNTL (
        .sec_msec(w_bcd1),
        .hour_min(w_bcd2),
        .sel(mode),
        .bcd(w_bcd)
    );

    comparator_msec U_COMP_DOT (
        .msec(i_time[6:0]),
        .dot_data(w_dot_data)
    );

    mux_8x1 U_Mux_8x1_Msec_Sec (
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10),
        .digit_100(w_sec_digit_1),
        .digit_1000(w_sec_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_bcd1)
    );
    mux_8x1 U_Mux_8x1_Min_Hour (
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10),
        .digit_100(w_hour_digit_1),
        .digit_1000(w_hour_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_bcd2)
    );

    bcd_decoder U_BCD_DECODER (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

endmodule


module comparator_msec (
    input  [6:0] msec,
    output [3:0] dot_data
);

    assign dot_data = (msec < 50) ? 4'hf : 4'he;

endmodule

module mux_2x1_bcd (

    input  [3:0] sec_msec,
    input  [3:0] hour_min,
    input        sel,
    output [3:0] bcd
);
    assign bcd = sel ? hour_min : sec_msec;

endmodule

module clk_div_1khz (
    input  clk,
    input  reset,
    output o_clk_1khz
);

    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter  <= 0;
                r_clk_1khz <= 1'b1;
            end else begin
                r_counter  <= r_counter + 1;
                r_clk_1khz <= 1'b0;
            end
        end
    end

endmodule






module counter_8 (
    input        clk,
    input        reset,
    output [2:0] sel
);

    reg [2:0] counter;  //2bit 카운터 선언
    assign sel = counter;


    always @(posedge clk, posedge reset) begin
        if (reset) begin  //reset이 걸리면 초기화
            //initial
            counter <= 0;  // <= 출력해라 10진수 0을
        end else begin  //else면 동작해라
            //operation
            counter <= counter + 1;  //1더해라
        end
    end

endmodule

module decoder_2X4 (
    input  [1:0] sel,
    output [3:0] fnd_com
);
    //삼항연산자( (조건) ? 참 : 거짓 )로 assign
    assign fnd_com =(sel==2'b00) ? 4'b1110:
                    (sel==2'b01) ? 4'b1101:
                    (sel==2'b10) ? 4'b1011:
                    (sel==2'b11) ? 4'b0111:4'b1111;



endmodule


module mux_8x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] digit_5,
    input  [3:0] digit_6,
    input  [3:0] digit_7,     //dot display
    input  [3:0] digit_8,
    input  [2:0] sel,
    output [3:0] bcd
);
    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000:  r_bcd = digit_1;
            3'b001:  r_bcd = digit_10;
            3'b010:  r_bcd = digit_100;
            3'b011:  r_bcd = digit_1000;
            3'b100:  r_bcd = digit_5;
            3'b101:  r_bcd = digit_6;
            3'b110:  r_bcd = digit_7;
            3'b111:  r_bcd = digit_8;
            default: r_bcd = digit_1;
        endcase
    end

endmodule






module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] count_data,
    output [3:0] digit_1,
    output [3:0] digit_10

);
    assign digit_1  = count_data % 10;
    assign digit_10 = (count_data / 10) % 10;


endmodule



module bcd_decoder (
    input [3:0] bcd,
    output reg [7:0] fnd_data //기본값 wire이기때문에 값을 유지하기 위해 reg로 선언
);

    always @(bcd) begin
        case (bcd)  //case문
            4'b0000:
            fnd_data = 8'hC0; //bcd 가 4비트 0000 일때 fnd_data에 8비트 c0을 유지해라 다음변화가있을 때까지
            4'b0001: fnd_data = 8'hf9;
            4'b0010: fnd_data = 8'ha4;
            4'b0011: fnd_data = 8'hb0;
            4'b0100: fnd_data = 8'h99;
            4'b0101: fnd_data = 8'h92;
            4'b0110: fnd_data = 8'h82;
            4'b0111: fnd_data = 8'hf8;
            4'b1000: fnd_data = 8'h80;
            4'b1001: fnd_data = 8'h90;
            4'b1010: fnd_data = 8'h88;  //~9
            4'b1011: fnd_data = 8'h83;
            4'b1100: fnd_data = 8'hc6;
            4'b1101: fnd_data = 8'ha1;
            4'b1110: fnd_data = 8'h7f;  //only dot display
            4'b1111: fnd_data = 8'hff;  // all off

            default: fnd_data = 8'hff;  //무조건(가능하면) 넣어주기
        endcase
    end  //always 출력 (fnd_data) data_type은 reg 타입이어야한다

endmodule
