
module sw_w_Top (
    input        clk,
    input        rst,
    input        Btn_L,      //clear / min plus
    input        Btn_R,      //runstop
    input        Btn_U,      // sec plus
    input        Btn_D,      // hour plus
    input        cmd_L,
    input        cmd_R,
    input        cmd_U,
    input        cmd_D,
    input        time_mode,  //시간,분/초,밀리초모드
    input        sw_w_mode,
    output [3:0] sw_w_fnd_com,
    output [7:0] sw_w_fnd_data,
    output       led_sec,
    output       led_min,
    output       led_hour
);

    wire [6:0] w_sw_msec, w_watch_msec;
    wire [5:0] w_sw_sec, w_watch_sec, w_sw_min, w_watch_min;
    wire [4:0] w_sw_hour, w_watch_hour;
    wire [23:0] w_i_time;
    wire [ 2:0] w_led;

    assign led_sec  = w_led[0];
    assign led_min  = w_led[1];
    assign led_hour = w_led[2];

    stopwatch U_STOPWATCH (
        .clk(clk),
        .rst(rst),
        .sw_w_mode(sw_w_mode),
        .Btn_L(Btn_L||cmd_L),  //clear
        .Btn_R(Btn_R||cmd_R),  //runstop
        .msec(w_sw_msec),
        .sec(w_sw_sec),
        .min(w_sw_min),
        .hour(w_sw_hour)
    );

    watch U_WATCH (
        .clk(clk),
        .rst(rst),
        .Btn_L(Btn_L||cmd_L),  // min plus
        .Btn_U(Btn_U||cmd_U),  // sec plus
        .Btn_D(Btn_D||cmd_D),  // hour plus
        .Btn_R(Btn_R||cmd_R),
        .sw_w_mode(sw_w_mode),
        .msec(w_watch_msec),
        .sec(w_watch_sec),
        .min(w_watch_min),
        .hour(w_watch_hour),
        .led(w_led)
    );
    
    Mux_2x1 U_SW_W_CNTL (
        .i_time_stopwatch({w_sw_hour, w_sw_min, w_sw_sec, w_sw_msec}),
        .i_time_watch({w_watch_hour, w_watch_min, w_watch_sec, w_watch_msec}),
        .sw_w_mode(sw_w_mode),
        .i_time(w_i_time)
    );
    sw_w_fnd_controller U_SW_W_FND_CNTL (
        .clk(clk),
        .reset(rst),
        .mode(time_mode),
        .i_time(w_i_time),
        .fnd_data(sw_w_fnd_data),
        .fnd_com(sw_w_fnd_com)
    );
endmodule



module Mux_2x1 (
    input  [23:0] i_time_stopwatch,
    input  [23:0] i_time_watch,
    input         sw_w_mode,
    output [23:0] i_time
);
    assign i_time = sw_w_mode ? i_time_watch : i_time_stopwatch;
endmodule
