`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 18:28:58
// Design Name: 
// Module Name: tb_OV7670
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


module tb_OV7670();

    // Clock & Reset
    logic clk;
    logic reset;

    // OV7670 Interface
    logic xclk;
    logic pclk;
    logic href;
    logic vsync;
    logic [7:0] data;

    // VGA Interface
    logic h_sync, v_sync;
    logic [3:0] r_port, g_port, b_port;

    // SCCB (ignored)
    logic SIO_C;
    tri  SIO_D;

    logic DE;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;

    /*
    OV7670_CAM dut (
        .clk(clk),
        .reset(reset),
        .xclk(xclk),
        .pclk(pclk),
        .href(href),
        .vsync(vsync),
        .data(data),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .r_port(r_port),
        .g_port(g_port),
        .b_port(b_port),
        .SIO_C(SIO_C),
        .SIO_D(SIO_D)
    );
    */

    VGA_Syncher DUT(
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    always #5 clk = ~clk;
    
    initial begin
        #00; clk = 0; reset = 1;
        #10; reset = 0;
    end

endmodule
