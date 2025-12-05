`timescale 1ns / 1ps

module dht_sender (
    input        clk,
    input        rst,
    input  [7:0] humidity,
    input  [7:0] temperature,
    input        start_trigger,
    output [7:0] o_data,
    output       push_trigger
);

    wire [31:0] w_ascii_data;
    dht_datatoascii U_DtoA (
        .humidity(humidity),
        .temperature(temperature),
        .o_data(w_ascii_data)
    );

    localparam IDLE = 0, SEND = 1,WAIT=2;

    reg [1:0]c_state, n_state;
    reg [7:0] o_data_reg, o_data_next;
    reg [10:0] send_cnt_reg, send_cnt_next;
    reg push_trigger_reg, push_trigger_next;

    assign o_data = o_data_reg;
    assign push_trigger = push_trigger_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            send_cnt_reg <= 0;
            o_data_reg <= 8'd0;
            push_trigger_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            o_data_reg <= o_data_next;
            send_cnt_reg <= send_cnt_next;
            push_trigger_reg <= push_trigger_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        o_data_next = o_data_reg;
        send_cnt_next = send_cnt_reg;
        push_trigger_next = 1'b0; 

        case (c_state)
            IDLE: begin
                send_cnt_next = 0;
                o_data_next   = 8'd0;
                if (start_trigger ) begin
                    n_state = SEND;
                end
            end

            SEND: begin
                if (send_cnt_reg < 30) begin
                    case (send_cnt_reg)
                        0:  o_data_next = 8'h74;  // 't'
                        1:  o_data_next = 8'h65;  // 'e'
                        2:  o_data_next = 8'h6D;  // 'm'
                        3:  o_data_next = 8'h70;  // 'p'
                        4:  o_data_next = 8'h65;  // 'e'
                        5:  o_data_next = 8'h72;  // 'r'
                        6:  o_data_next = 8'h61;  // 'a'
                        7:  o_data_next = 8'h74;  // 't'
                        8:  o_data_next = 8'h75;  // 'u'
                        9:  o_data_next = 8'h72;  // 'r'
                        10: o_data_next = 8'h65;  // 'e'
                        11: o_data_next = 8'h20;  // 공백
                        12: o_data_next = 8'h3A;  // :
                        13: o_data_next = 8'h20;  // 공백
                        14: o_data_next = w_ascii_data[31:24];
                        15: o_data_next = w_ascii_data[23:16];
                        16: o_data_next = 8'h20; // 공백
                        17: o_data_next = 8'h68;  // 'h'
                        18: o_data_next = 8'h75;  // 'u'
                        19: o_data_next = 8'h6D;  // 'm'
                        20: o_data_next = 8'h69;  // 'i'
                        21: o_data_next = 8'h64;  // 'd'
                        22: o_data_next = 8'h69;  // 'i'
                        23: o_data_next = 8'h74;  // 't'
                        24: o_data_next = 8'h79;  // 'y'
                        25: o_data_next = 8'h20;  // 공백
                        26: o_data_next = 8'h3A;  // : 
                        27: o_data_next = 8'h20;  // 공백
                        28: o_data_next = w_ascii_data[15:8];
                        29: o_data_next = w_ascii_data[7:0];
                    endcase
                    push_trigger_next = 1'b1;
                    send_cnt_next = send_cnt_reg + 1;
                end else begin
                    n_state = WAIT;
                end
            end
            WAIT : begin
                if (start_trigger==0) begin
                    n_state = IDLE;
                end
            end
        endcase
    end


endmodule

module dht_datatoascii (
    input  [ 7:0] humidity,
    input  [ 7:0] temperature,
    output [31:0] o_data
);
    assign o_data[7:0]   = humidity % 10 + 8'h30;
    assign o_data[15:8]  = (humidity / 10) % 10 + 8'h30;
    assign o_data[23:16] = temperature % 10 + 8'h30;
    assign o_data[31:24] = (temperature / 10) % 10 + 8'h30;
endmodule
