`timescale 1ns / 1ps
`include "define.sv"

module DataPath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instrcode,
    input  logic        regFileWe,    // register file enable signal
    input  logic [ 3:0] alucontrol,
    input  logic aluSrcMuxSel,
    input  logic [31:0] d_rdata, 
    output logic [31:0] instrMemAddr,
    output logic [31:0] d_addr,
    output logic [31:0] d_wdata
);
    logic [31:0] RFData1, RFData2, aluResult;
    logic [31:0] PCOutData, PC_4_AdderResult;
    logic [31:0] immExt, aluSrcMuxOut;
    assign instrMemAddr = PCOutData;
    assign d_addr = aluResult;
    assign d_wdata = RFData2;

    RegisterFile U_REG_FILE (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrcode[19:15]),
        .RA2(instrcode[24:20]),
        .WA (instrcode[11:7]),
        .WD (aluResult),
        .RD1(RFData1),
        .RD2(RFData2)
    );
    alu U_ALU (
        .alucontrol(alucontrol),
        .a(RFData1),
        .b(aluSrcMuxOut),
        .result(aluResult)
    );

    register U_PC (
        .clk(clk),
        .rst(rst),
        .en (1'b1),
        .d  (PC_4_AdderResult),
        .q  (PCOutData)
    );

    adder U_PC_4_ADDER (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    mux_2x1 U_AluSrcMux(
    .x0(RFData2),
    .x1(immExt),
    .aluSrcMuxSel(aluSrcMuxSel),
    .y(aluSrcMuxOut)
);

    immExtend U_ImmExtend(
    .instrcode(instrcode),
    .immExt(immExt)
);
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:2**5-1];

    initial begin
        for (int i = 0; i < 32; i++) begin
            mem[i] = i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
    end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module alu (
    input  logic [ 3:0] alucontrol,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);
    always_comb begin
        result = 32'bx;
        case (alucontrol)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b[4:0];
            `SRL:  result = a >> b[4:0];
            `SRA:  result = $signed(a) >>> b[4:0];
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a) < (b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);

    assign y = a + b;
endmodule

module immExtend (
    input logic [31:0] instrcode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrcode [6:0];
    wire [3:0] operator = {instrcode[30], instrcode[14:12]};

    always_comb begin
        immExt = 32'bx;
        case (opcode)
        `OP_TYPE_I: immExt = {{20{instrcode[31]}}, instrcode[31:20]}; 
        `OP_TYPE_S: immExt = {{20{instrcode[31]}},instrcode[31:25],instrcode[11:7]};
        endcase
        
    end
    
endmodule

module mux_2x1 (
    input logic [31:0] x0,
    input logic [31:0] x1,
    input logic aluSrcMuxSel,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (aluSrcMuxSel)
            1'b0: y = x0;
            1'b1: y = x1;  
        endcase
    end
endmodule
