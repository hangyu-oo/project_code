`timescale 1ns / 1ps

module ROM(
    input logic [31:0] addr, // 4의 배수로 들어옴
    output logic [31:0] data
    );

    logic [31:0] rom[0:2**8-1];

    initial begin
        // R_type code
        // rom[0] = 32'h006283b3; // add x7, x5, x6
        // rom[1] = 32'h406283b3; // sub
        // rom[2] = 32'h006293b3; // sll
        // rom[3] = 32'h0062d3b3; // srl
        // rom[4] = 32'h4062d3b3; // sra
        // rom[5] = 32'h0062a3b3; // slt
        // rom[6] = 32'h0062b3b3; // sltu
        // rom[7] = 32'h0062c3b3; // xor
        // rom[8] = 32'h0062e3b3; // or
        // rom[9] = 32'h0062f3b3; // and
        rom[0] = 32'h006020a3; // SW x6,1(x0)
        rom[1] = 32'h006090a3; // SH x6, 1(x1)
        rom[2] = 32'h006100a3;// SB x6,1(x2) 
    end
    assign data = rom[addr[31:2]]; // 4의 배수로 들어오기떄문에 앞에 3개는 신경쓰지 않아서 
endmodule
