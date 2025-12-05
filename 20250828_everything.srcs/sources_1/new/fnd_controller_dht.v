module fnd_controller_dht (
    input clk,
    input reset,
    input [7:0] humid,
    input [7:0] temperature,
    output [7:0] fnd_data,
    output [3:0] fnd_com

);
    wire [3:0] w_humid_1, w_humid_10, w_temperature_1, w_temperature_10;
    wire [1:0] w_sel;
    wire [3:0] w_bcd;
    wire w_clk_1khz;

    dht_clk_div_1khz U_CLK_DIV_1KHZ (
        .clk(clk),
        .reset(reset),
        .o_clk_1khz(w_clk_1khz)
    );
    dht_counter_4 U_COUNTER_4 (
        .clk  (w_clk_1khz),
        .reset(reset),
        .sel  (w_sel)
    );

    dht_digit_splitter U_DS (
        .humid(humid),
        .temperature(temperature),
        .humid_1(w_humid_1),
        .humid_10(w_humid_10),
        .temperature_1(w_temperature_1),
        .temperature_10(w_temperature_10)
    );

    dht_mux_4x1 U_Mux_4x1 (
        .humid_1(w_humid_1),
        .humid_10(w_humid_10),
        .temperature_1(w_temperature_1),
        .temperature_10(w_temperature_10),
        .sel(w_sel),
        .bcd(w_bcd)
    );

    dht_bcd_decoder U_BCD_DECODER (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    dht_decoder_2x4 U_DECOER_2x4 (
        .sel(w_sel),
        .fnd_com(fnd_com)
    );
endmodule

module dht_mux_4x1 (
    input  [3:0] humid_1,
    input  [3:0] humid_10,
    input  [3:0] temperature_1,
    input  [3:0] temperature_10,
    input  [1:0] sel,
    output [3:0] bcd
);

    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            2'b00: r_bcd = humid_1;
            2'b01: r_bcd = humid_10;
            2'b10: r_bcd = temperature_1;
            2'b11: r_bcd = temperature_10;
        endcase
    end

endmodule

module dht_clk_div_1khz (
    input  clk,
    input  reset,
    output o_clk_1khz
);

    reg [$clog2(100_000)-1:0] r_count;  // $clog2 는 내장함수
    reg r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_count <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_count == 100_000 - 1) begin
                r_count <= 0;
                r_clk_1khz <= 1'b1;
            end else begin
                r_count <= r_count + 1;
                r_clk_1khz <= 1'b0;
            end
        end
    end


endmodule

module dht_decoder_2x4 (
    input  [1:0] sel,
    output [3:0] fnd_com
);

    assign fnd_com = (sel == 2'b00) ? 4'b1110:
                     (sel == 2'b01) ? 4'b1101: 
                     (sel == 2'b10) ? 4'b1011: 
                     (sel == 2'b11) ? 4'b0111:4'b1111;

endmodule

module dht_counter_4 (
    input        clk,
    input        reset,
    output [1:0] sel

);
    reg [1:0] count;
    assign sel = count;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 2'b00;
        end else begin
            count <= count + 1;
        end
    end

endmodule

module dht_digit_splitter (
    input  [7:0] humid,
    input  [7:0] temperature,
    output [3:0] humid_1,
    output [3:0] humid_10,
    output [3:0] temperature_1,
    output [3:0] temperature_10
);

    assign humid_1 = humid % 10;
    assign humid_10 = (humid / 10) % 10;
    assign temperature_1 = temperature % 10;
    assign temperature_10 = (temperature / 10) % 10;
endmodule


module dht_bcd_decoder (
    input      [3:0] bcd,
    output reg [7:0] fnd_data

);
    always @(bcd) begin
        case (bcd)
            4'b0000: fnd_data = 8'hc0;  //0
            4'b0001: fnd_data = 8'hf9;  //1
            4'b0010: fnd_data = 8'ha4;  //2
            4'b0011: fnd_data = 8'hb0;  //3
            4'b0100: fnd_data = 8'h99;  //4
            4'b0101: fnd_data = 8'h92;  //5
            4'b0110: fnd_data = 8'h82;  //6
            4'b0111: fnd_data = 8'hf8;  //7
            4'b1000: fnd_data = 8'h80;  //8
            4'b1001: fnd_data = 8'h90;  //9
            4'b1010: fnd_data = 8'h88;
            4'b1011: fnd_data = 8'h83;
            4'b1100: fnd_data = 8'hc6;
            4'b1101: fnd_data = 8'ha1;
            4'b1110: fnd_data = 8'h86;
            4'b1111: fnd_data = 8'h8e;
            default: fnd_data = 8'hff;
        endcase
    end
endmodule