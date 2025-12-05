`timescale 1ns / 1ps

module dht_top (
    input        clk,
    input        rst,
    input [7:0] humidity,
    input [7:0] temperature,
    // input        rx,
    // inout        dht_io,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output       led
);

    wire w_btn;
    wire w_tick;
    wire [7:0] w_temperature, w_humid;
    wire [7:0] w_start;
    wire [7:0] w_data;
    wire w_start_trigger, w_push_trigger;

    // uart_top U_UART (
    //     .clk(clk),
    //     .rst(rst),
    //     .rx(rx),
    //     .data(w_data),
    //     .push_trigger(w_push_trigger),
    //     .tx(tx),
    //     .rx_pop_data(w_start)
    // );

    fnd_controller_dht U_FND_CNTL_DHT (
        .clk(clk),
        .reset(rst),
        .temperature(temperature),
        .humid(humidity),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );
    // dht_tick_gen_1us U_TICK_GEN (
    //     .clk       (clk),
    //     .rst       (rst),
    //     .o_tick_1us(w_tick)
    // );
    // dht11_control_unit U_DHT11_CU (
    //     .clk          (clk),
    //     .rst          (rst),
    //     .i_start      (w_start),
    //     .dht_io       (dht_io),
    //     .o_valid      (led),
    //     .temperature  (w_temperature),
    //     .humid        (w_humid),
    //     .start_trigger(w_start_trigger)
    // );
    // dht_sender U_DHT_SENDER (
    //     .clk(clk),
    //     .rst(rst),
    //     .humidity(w_humid),
    //     .temperature(w_temperature),
    //     .start_trigger(w_start_trigger),
    //     .o_data(w_data),
    //     .push_trigger(w_push_trigger)
    // );

endmodule


