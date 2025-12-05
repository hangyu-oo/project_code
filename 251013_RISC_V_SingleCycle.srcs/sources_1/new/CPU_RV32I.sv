`timescale 1ns / 1ps

module CPU_RV32I (
    input logic clk,
    input logic rst,
    input logic [31:0] instrcode,
    input logic [31:0] d_rdata,
    output logic [31:0] instrMemAddr,
    output logic d_we,
    output logic [1:0] d_strb,
    output logic [31:0] d_addr,
    output logic [1:0] d_wdata
);

    logic       regFileWe;
    logic [3:0] alucontrol;
    logic aluSrcMuxSel;
    ControlUnit U_CONTROL_UNIT (.*,.we(d_we),.strb(d_strb));
    DataPath U_DATA_PATH (.*);
endmodule
