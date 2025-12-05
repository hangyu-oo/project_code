`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/22 18:15:16
// Design Name: 
// Module Name: QVGAReader
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module QVGAReader(
    input  logic        clk,
    input  logic        reset,
    input  logic        DE,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] imgData,
    output logic [16:0] addr,
    output logic [ 3:0] r_port,
    output logic [ 3:0] g_port,
    output logic [ 3:0] b_port
);

    // Pipeline Stage 1: 곱셈만 (MREG 활용)
    logic [16:0] mult_result;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            mult_result <= 17'd0;
        end else begin
            mult_result <= 320 * y_pixel;  // 곱셈 결과만 레지스터링
        end
    end
    
    // Pipeline Stage 2: 덧셈 (PREG 활용)
    logic [16:0] addr_calc;
    logic [9:0]  x_pixel_d1;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            addr_calc  <= 17'd0;
            x_pixel_d1 <= 10'd0;
        end else begin
            x_pixel_d1 <= x_pixel;              // x_pixel도 1클럭 지연
            addr_calc  <= mult_result + x_pixel_d1;  // 덧셈 결과 레지스터링
        end
    end
    
    // Enable 신호 파이프라인 (주소 계산과 동기화)
    logic img_display_en;
    logic img_display_en_d1;
    logic img_display_en_d2;
    logic img_display_en_d3;
    
    assign img_display_en = DE && (x_pixel < 320) && (y_pixel < 240);
    
    always_ff @(posedge clk) begin
        if (reset) begin
            img_display_en_d1 <= 1'b0;
            img_display_en_d2 <= 1'b0;
            img_display_en_d3 <= 1'b0;
        end else begin
            img_display_en_d1 <= img_display_en;   // Stage 1
            img_display_en_d2 <= img_display_en_d1; // Stage 2
            img_display_en_d3 <= img_display_en_d2; // Stage 3 (Frame Buffer 지연)
        end
    end
    
    // 주소 출력
    assign addr = img_display_en_d2 ? addr_calc : 17'd0;
    
    // RGB 출력 (Frame Buffer 1클럭 지연 보상)
    assign {r_port, g_port, b_port} = img_display_en_d3 ? 
        {imgData[15:12], imgData[10:7], imgData[4:1]} : 12'd0;

endmodule
