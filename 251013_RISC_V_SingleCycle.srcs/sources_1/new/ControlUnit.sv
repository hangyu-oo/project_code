`timescale 1ns / 1ps

`include "define.sv"

module ControlUnit (
    input  logic [31:0] instrcode,
    output logic        regFileWe,
    output logic [ 3:0] alucontrol,
    output logic aluSrcMuxSel,
    output logic we,
    output logic [1:0] strb
);

    wire [6:0] opcode = instrcode[6:0];
    wire [3:0] operator = {instrcode[30], instrcode[14:12]};
    wire [2:0] funct3 = instrcode[14:12];
    logic [4:0] signals;

    assign {regFileWe,aluSrcMuxSel,we,strb} = signals;

    always_comb begin
        signals = 5'b0;
        case (opcode)
            `OP_TYPE_R: signals = 5'b1_0_0_00;
            `OP_TYPE_I: signals = 5'b1_1_0_00;
            `OP_TYPE_S: begin
                case (funct3)
                    3'b000:signals = 5'b0_1_1_00;
                    3'b001:signals = 5'b0_1_1_01;
                    3'b010:signals = 5'b0_1_1_10; 
                endcase
            end
        endcase
    end

    always_comb begin
        alucontrol = `ADD;
        case (opcode)
            `OP_TYPE_R: alucontrol = operator;
            `OP_TYPE_I: begin
                if(operator == 4'b1101) alucontrol = operator;
                else alucontrol = {1'b0, operator[2:0]};
            end
            `OP_TYPE_S: alucontrol = `ADD;
        endcase
    end
endmodule
