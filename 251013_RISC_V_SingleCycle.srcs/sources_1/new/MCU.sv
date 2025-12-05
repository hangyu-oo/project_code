`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic rst
);

    logic [31:0] instrcode, instrMemAddr;
    logic d_we;
    logic [1:0] d_strb;
    logic [31:0] d_addr, d_wdata, d_rdata;

    CPU_RV32I U_RV32I (
        .clk(clk),
        .rst(rst),
        .instrcode(instrcode),
        .d_rdata(d_rdata),
        .instrMemAddr(instrMemAddr),
        .d_we(d_we),
        .d_strb(d_strb),
        .d_addr(d_addr),
        .d_wdata(d_wdata)
    );

    ROM U_ROM (
        .addr(instrMemAddr), 
        .data(instrcode)
    );

    RAM U_RAM(
        .clk(clk),
        .strb(d_strb),
        .we(d_we),
        .rAddr(d_addr[7:0]),
        .wAddr(d_addr[7:0]),
        .wData(d_wdata),
        .rData(d_rdata)
    );
endmodule
