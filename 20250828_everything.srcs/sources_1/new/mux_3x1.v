`timescale 1ns / 1ps

module mux_3x1 (
    input  [7:0] sw_w_data,
    input  [7:0] sr04_data,
    input  [7:0] dht11_data,
    input  [3:0] sw_w_com,
    input  [3:0] sr04_com,
    input  [3:0] dht11_com,
    input  [1:0] sel,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);


    reg [3:0] r_fnd_com;
    reg [7:0] r_fnd_data;

    assign fnd_com  = r_fnd_com;
    assign fnd_data = r_fnd_data;

    always @(*) begin
        case (sel)
            2'b00: begin
                r_fnd_com  = sw_w_com;
                r_fnd_data = sw_w_data;
            end
            2'b01: begin
                r_fnd_com  = sr04_com;
                r_fnd_data = sr04_data;
            end
            2'b10: begin
                r_fnd_com = dht11_com;
                r_fnd_data = dht11_data;
            end
            default: begin
                r_fnd_com  = sw_w_com;
                r_fnd_data = sw_w_data;
            end
        endcase
    end
endmodule


