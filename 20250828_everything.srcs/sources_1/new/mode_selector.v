`timescale 1ns / 1ps


module mode_selector (
    input        clk,
    input        rst,
    input  [7:0] i_rx_data,
    input        i_start_trigger,
    output [7:0] o_sr04_data,
    output       o_sr04_start_trigger,
    output [7:0] o_sw_w_data,
    output       o_sw_w_start_trigger,
    output [7:0] o_dht_start,
    output [1:0] mode_sel
);

  localparam [1:0] SW_W_MODE = 2'b00, SR04_MODE = 2'b01, DHT11_MODE = 2'b10;

  reg [1:0] c_state, n_state, sel_reg, sel_next;

  assign mode_sel             = sel_reg;

  //SW_W_MODE
  assign o_sw_w_data          = (c_state == SW_W_MODE) ? i_rx_data : 0;
  assign o_sw_w_start_trigger = (c_state == SW_W_MODE) ? i_start_trigger : 0;
  // assign mode_sel             = (c_state == SW_W_MODE) ? sel_reg : 1;


  //sr04_mode
  assign o_sr04_data          = (c_state == SR04_MODE) ? i_rx_data : 0;
  assign o_sr04_start_trigger = (c_state == SR04_MODE) ? i_start_trigger : 0;
  // assign mode_sel             = (c_state == SR04_MODE) ? sel_reg : 0;

  assign o_dht_start          = (c_state == DHT11_MODE) ? i_rx_data : 0;

  //dht11_mode




  always @(posedge clk, posedge rst) begin
    if (rst) begin
      c_state <= SW_W_MODE;
      sel_reg <= 2'b00  ;
    end else begin
      c_state <= n_state;
      sel_reg <= sel_next;
    end
  end

  always @(*) begin
    n_state  = c_state;
    sel_next = sel_reg;
    if (i_start_trigger) begin
      case (i_rx_data)
        8'h31: begin
          //uart 1
          n_state  = SW_W_MODE;
          sel_next = 2'b00;
        end
        8'h32: begin
          //uart 2
          n_state  = SR04_MODE;
          sel_next = 2'b01;
        end
        8'h33: begin
          //uart 3
          n_state  = DHT11_MODE;
          sel_next = 2'b10;
        end
      endcase
    end
  end

endmodule
