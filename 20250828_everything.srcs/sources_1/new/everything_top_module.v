`timescale 1ns / 1ps


module everything_top_module (
    input          clk,
    input          rst,
    input          Btn_L,
    input          Btn_R,
    input          Btn_U,
    input          Btn_D,
    input  [  1:0] sw,
    input          echo,      //from sr04
    input          rx,
    output         tx,
    output         trig,      //to sr04
    output [  3:0] fnd_com,
    output [  7:0] fnd_data,
    output [14:12] led,
    inout dht_io
);


    wire w_sr04_sender_done;
    wire [7:0] w_sr04_sender_data;
    wire w_sr04_dist_done;
    wire w_sr04_start_trigger, w_sw_w_start_trigger;
    wire [7:0] w_sw_w_data, w_sr04_data;
    wire [8:0] w_sr04_dist_data;
    wire w_cmd_u, w_cmd_d, w_cmd_l, w_cmd_r;
    wire [3:0] w_sw_w_fnd_com, w_sr04_fnd_com, w_dht11_fnd_com;
    wire [7:0] w_sw_w_fnd_data, w_sr04_fnd_data, w_dht11_fnd_data;
    wire [1:0] w_mode_sel;
    wire w_Btn_L, w_Btn_D, w_btn_R, w_Btn_U;
    wire [7:0] w_rx_pop_data;
    wire u_start_trigger;
    wire w_sw_w_mode, w_time_mode;
    wire w_sr04_cntrl_trigger;
    wire [7:0] w_humidity,w_temperature;
    wire [7:0] start_dht11;

    uart_top U_UART_TOP (
        .clk        (clk),
        .rst        (rst),
        .rx         (rx),
        .dist_done  (w_sr04_sender_done),  // from sr04 sender (done)
        .dist_data  (w_sr04_sender_data),  // from sr04 sender (data)
        .tx         (tx),
        .rx_pop_data(w_rx_pop_data),
        .u_start    (u_start_trigger)      // uart start trigger
    );

    mode_selector U_MODE_SELECTOR (
        .clk(clk),
        .rst(rst),
        .i_rx_data(w_rx_pop_data),  // from uart
        .i_start_trigger(u_start_trigger),  // from uart
        .o_sr04_data(w_sr04_data),  // to cu_top (sr04 controller)
        .o_sr04_start_trigger(w_sr04_start_trigger),  // to cu_top(sr04 start trigger)
        .o_sw_w_data(w_sw_w_data),  // to sw_w_data (sw_w controller)
        .o_sw_w_start_trigger(w_sw_w_start_trigger),  // to sw_w_data (sw_w start trigger)
        .mode_sel(w_mode_sel),
        .o_dht_start(start_dht11)  // to (3x1) x 2  mux
    );

    command_cu_top U_CU_TOP (
        .clk(clk),
        .rst(rst),
        .i_sr04_data(w_sr04_data),  // from sr04 receiver
        .i_sr04_start_trigger(w_sr04_start_trigger),  // from sr04 receiver
        .i_sw_w_data(w_sw_w_data),  // from sw_w receiver
        .i_sw_w_start_trigger(w_sw_w_start_trigger),  // from sw_w receiver
        .mode_sel            (w_mode_sel),  // from mode seletor
        .i_sw_w_mode(sw[1]),  // from sw 1
        .i_time_mode(sw[0]),  // from sw 0
        .dist_data(w_sr04_dist_data),  // from sr04 controller
        .dist_done(w_sr04_dist_done),  // from sr04 controller
        // .full(),  // from uart (don't send)
        .cmd_u(w_cmd_u),  // from uart key u 
        .cmd_d(w_cmd_d),  // from uart key d
        .cmd_l(w_cmd_l),  // from uart key l
        .cmd_r(w_cmd_r),  // from uart key r
        .o_sw_w_mode(w_sw_w_mode),
        .o_time_mode(w_time_mode),
        .sr04_start(w_sr04_cntrl_trigger),  // controller sr04_start_trigger
        .push(w_sr04_sender_done),  // to uart tx from cu
        .send_data(w_sr04_sender_data),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .dht_io(dht_io),
        .i_dht11_start_trigger(start_dht11)
    );

    sw_w_Top U_SW_W_TOP (
        .clk          (clk),
        .rst          (rst),
        .Btn_L        (w_Btn_L),          //clear / min plus
        .Btn_R        (w_btn_R),          //runstop
        .Btn_U        (w_Btn_U),          // sec plus
        .Btn_D        (w_Btn_D),          // hour plus
        .cmd_L        (w_cmd_l),
        .cmd_R        (w_cmd_r),
        .cmd_U        (w_cmd_u),
        .cmd_D        (w_cmd_d),
        .time_mode    (w_time_mode),      //시간,분/초,밀리초모드
        .sw_w_mode    (w_sw_w_mode),      //stopwatch watch mode
        .sw_w_fnd_com (w_sw_w_fnd_com),   // sw_w_fnd_com
        .sw_w_fnd_data(w_sw_w_fnd_data),  // sw_w_fnd_data
        .led_sec      (led[12]),
        .led_min      (led[13]),
        .led_hour     (led[14])
    );

    sr04_top U_SR04_TOP (
        .clk(clk),
        .rst(rst),
        .sr04_start(w_sr04_cntrl_trigger),  //from CU_TOP controller SR04 start trigger 
        .echo(echo),
        .trig(trig),  // sensor sr04 start_trigger
        .sr04_fnd_com(w_sr04_fnd_com),  // sr04_fnd_com
        .sr04_fnd_data(w_sr04_fnd_data),  // sr04_fnd_data
        .o_dist_done(w_sr04_dist_done),  // to sender
        .o_dist_data(w_sr04_dist_data)  // to sender
    );

    dht_top U_DHT_TOP (
        .clk(clk),
        .rst(rst),  
        // .rx(rx),
        // .dht_io(dht_io),
        .fnd_com(w_dht11_fnd_com),
        .fnd_data(w_dht11_fnd_data),
        .led(led[15]),
        .humidity(w_humidity),
        .temperature(w_temperature)
        // .tx(tx)
    );
    btn_debounce U_BTN_DEBOUNCE0 (
        .clk  (clk),
        .rst  (rst),
        .i_btn(Btn_L),
        .o_btn(w_Btn_L)
    );
    btn_debounce U_BTN_DEBOUNCE1 (
        .clk  (clk),
        .rst  (rst),
        .i_btn(Btn_R),
        .o_btn(w_btn_R)
    );
    btn_debounce U_BTN_DEBOUNCE2 (
        .clk  (clk),
        .rst  (rst),
        .i_btn(Btn_U),
        .o_btn(w_Btn_U)
    );
    btn_debounce U_BTN_DEBOUNCE3 (
        .clk  (clk),
        .rst  (rst),
        .i_btn(Btn_D),
        .o_btn(w_Btn_D)
    );
    mux_3x1 U_MUX_3X1 (
        .sw_w_data(w_sw_w_fnd_data),
        .sr04_data(w_sr04_fnd_data),
        .sw_w_com(w_sw_w_fnd_com),
        .sr04_com(w_sr04_fnd_com),
        .sel(w_mode_sel),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .dht11_com(w_dht11_fnd_com),
        .dht11_data(w_dht11_fnd_data)
    );

endmodule
