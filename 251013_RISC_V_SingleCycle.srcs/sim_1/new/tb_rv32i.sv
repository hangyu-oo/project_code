`timescale 1ns / 1ps

module tb_rv32i();
logic clk;
logic rst;

MCU dut (.*);

always #5 clk = ~clk;

initial begin
    #00 clk = 0; rst = 1;
    #10 rst = 0;
    #50 $finish;
end
endmodule
