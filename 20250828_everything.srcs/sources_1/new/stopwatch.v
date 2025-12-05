`timescale 1ns / 1ps


module stopwatch (
    input        clk,
    input        rst,
    input        sw_w_mode,
    input        Btn_L,      //clear
    input        Btn_R,      //runstop
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire w_runstop, w_clear;
    wire w_btn_l, w_btn_r;


    stopwatch_dp U_SW_DP (
        .clk(clk),
        .rst(rst && ~sw_w_mode),
        .i_runstop(w_runstop),
        .i_clear(w_clear),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)

    );

    stopwatch_cu U_SW_CU (
        .clk(clk),
        .rst(rst && ~sw_w_mode),
        .i_runstop(Btn_R & ~sw_w_mode),
        .i_clear(Btn_L & ~sw_w_mode),
        .o_run_stop(w_runstop),
        .o_clear(w_clear)
    );


endmodule
