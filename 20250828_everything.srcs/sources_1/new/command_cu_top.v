`timescale 1ns / 1ps

module command_cu_top (
    input        clk,
    input        rst,
    input  [7:0] i_sr04_data,
    input        i_sr04_start_trigger,
    input  [7:0] i_sw_w_data,
    input        i_sw_w_start_trigger,
    input  [7:0] i_dht11_start_trigger,
    inout        dht_io,
    input  [1:0] mode_sel,
    input        i_sw_w_mode,
    input        i_time_mode,
    input  [8:0] dist_data,
    input        dist_done,
    // input        full,
    output [7:0] humidity,
    output [7:0] temperature,
    output       cmd_u,
    output       cmd_d,
    output       cmd_l,
    output       cmd_r,
    output       o_sw_w_mode,
    output       o_time_mode,
    output       sr04_start,
    output       push,
    output [7:0] send_data

);

  wire w_dht11_start_trigger;
  wire [7:0] w_humidity, w_temperature;
  wire w_o_sw_w_mode;
  wire w_sw_w_mode_changed;
  wire [7:0] w_sw_w_sender, w_sr04_sender, w_dht11_sender;
  wire w_sw_w_push, w_sr04_push, w_dht11_push;
  assign humidity = w_humidity;
  assign temperature = w_temperature;
  assign o_sw_w_mode = w_o_sw_w_mode;

  assign send_data =(mode_sel==2'b00)?w_sw_w_sender:
                    (mode_sel==2'b01)?w_sr04_sender:w_dht11_sender;
  assign push = (mode_sel == 2'b00) ? w_sw_w_push : (mode_sel == 2'b01) ? w_sr04_push : w_dht11_push;

  sr04_receiver U_SR04_RECEIVER (
      .clk       (clk),
      .rst       (rst),
      .command   (i_sr04_data),           //receiver data
      .rx_trigger(i_sr04_start_trigger),  //receiver start_trigger
      .sr04_start(sr04_start)
  );

  sr04_sender U_SR04_SENDER (
      .clk      (clk),
      .rst      (rst),
      .dist_data(dist_data),
      .dist_done(dist_done),
      .full     (0),
      .push     (w_sr04_push),
      .send_data(w_sr04_sender)
  );

  sw_w_receiver U_SW_W_RECEIVER (
      .clk                 (clk),
      .rst                 (rst),
      .rx_data             (i_sw_w_data),           //receiver data
      .rx_trigger          (i_sw_w_start_trigger),  //receiver start_trigger
      .i_sw_w_mode         (i_sw_w_mode),
      .i_time_mode         (i_time_mode),
      .cmd_u               (cmd_u),
      .cmd_d               (cmd_d),
      .cmd_l               (cmd_l),
      .cmd_r               (cmd_r),
      .o_sw_w_mode         (w_o_sw_w_mode),
      .o_time_mode         (o_time_mode),
      .mode_changed_trigger(w_sw_w_mode_changed)
  );
  sw_w_sender U_SW_W_SENDER (
      .clk          (clk),
      .rst          (rst),
      .sw_w_mode    (w_o_sw_w_mode),        //sw_w mode from command cu
      .full         (0),                    // full from tx fifo
      .start_trigger(w_sw_w_mode_changed),  //from receiver
      .o_data       (w_sw_w_sender),        //data to tx fifo
      .push_trigger (w_sw_w_push)           // trigger to tx fifo
  );

  dht11_receiver U_DHT11_RECEIVER (
      .clk(clk),
      .rst(rst),
      .i_start(i_dht11_start_trigger),
      .dht_io(dht_io),
      .o_valid(),
      .temperature(w_temperature),
      .humid(w_humidity),
      .start_trigger(w_dht11_start_trigger)
  );

  dht_sender U_DHT_SENDER (
      .clk(clk),
      .rst(rst),
      .humidity(w_humidity),
      .temperature(w_temperature),
      .start_trigger(w_dht11_start_trigger),
      .o_data(w_dht11_sender),
      .push_trigger(w_dht11_push)
  );

endmodule

