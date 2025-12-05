`timescale 1ns / 1ps


module watch (
    input        clk,
    input        rst,
    input        Btn_L,
    input        Btn_U,
    input        Btn_D,
    input        Btn_R,
    input        sw_w_mode,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    output [2:0] led
);

    wire [1:0] w_set_sec, w_set_min, w_set_hour;
    wire [2:0] w_led;
    

    watch_cu U_watch_cu (
        .clk(clk),
        .rst(rst && sw_w_mode),
        .Btn_L(Btn_L && sw_w_mode),
        .Btn_U(Btn_U && sw_w_mode),
        .Btn_D(Btn_D && sw_w_mode),
        .Btn_R(Btn_R && sw_w_mode),
        .set_sec(w_set_sec),
        .set_min(w_set_min),
        .set_hour(w_set_hour),
        .led(led),
        .sw_w_mode(sw_w_mode)
    );

    watch_dp U_W_DP (
        .clk(clk),
        .rst(rst && sw_w_mode),
        .btn_sec_set(w_set_sec),
        .btn_min_set(w_set_min),
        .btn_hour_set(w_set_hour),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

endmodule
