`timescale 1ns / 1ps

module sw_w_sender (
    input        clk,
    input        rst,
    input        sw_w_mode,      //sw_w mode from command cu
    input        full,           // full from tx fifo
    input        start_trigger,  //from receiver
    output [7:0] o_data,         //data to tx fifo
    output       push_trigger    // trigger to tx fifo
);
    reg state_reg, state_next;
    localparam IDLE = 1'b0, SEND = 1'b1;

    reg [7:0] send_data_reg, send_data_next;
    reg [7:0] send_cnt_reg, send_cnt_next;
    reg push_trigger_reg, push_trigger_next;



    assign push_trigger = push_trigger_reg;
    assign o_data = send_data_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg        <= IDLE;
            send_data_reg    <= 0;
            send_cnt_reg     <= 0;
            push_trigger_reg <= 0;
        end else begin
            state_reg        <= state_next;
            send_data_reg    <= send_data_next;
            send_cnt_reg     <= send_cnt_next;
            push_trigger_reg <= push_trigger_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        case (state_reg)
            IDLE: begin
                send_data_next    = 8'b0;
                send_cnt_next     = 0;
                push_trigger_next = 0;
                if (start_trigger == 1) begin

                    state_next = SEND;
                end
            end
            SEND: begin
                push_trigger_next = 0;
                if (~full) begin
                    push_trigger_next = 1;
                    case (sw_w_mode)
                        1'b0: begin
                            case (send_cnt_reg)
                                8'h00: send_data_next = 8'h73;
                                8'h01: send_data_next = 8'h74;
                                8'h02: send_data_next = 8'h6F;
                                8'h03: send_data_next = 8'h70;
                                8'h04: send_data_next = 8'h77;
                                8'h05: send_data_next = 8'h61;
                                8'h06: send_data_next = 8'h74;
                                8'h07: send_data_next = 8'h63;
                                8'h08: send_data_next = 8'h68;
                                8'h09: send_data_next = 8'h20;
                                8'h0A: send_data_next = 8'h6D;
                                8'h0B: send_data_next = 8'h6F;
                                8'h0C: send_data_next = 8'h64;
                                8'h0D: send_data_next = 8'h65;
                            endcase
                            if (send_cnt_reg == 8'h0E) begin
                                push_trigger_next = 0;
                                send_cnt_next     = 0;
                                state_next        = IDLE;
                            end else begin
                                send_cnt_next = send_cnt_reg + 1;
                            end
                        end
                        1'b1: begin
                            case (send_cnt_reg)
                                8'h00: send_data_next = 8'h77;
                                8'h01: send_data_next = 8'h61;
                                8'h02: send_data_next = 8'h74;
                                8'h03: send_data_next = 8'h63;
                                8'h04: send_data_next = 8'h68;
                                8'h05: send_data_next = 8'h20;
                                8'h06: send_data_next = 8'h6D;
                                8'h07: send_data_next = 8'h6F;
                                8'h08: send_data_next = 8'h64;
                                8'h09: send_data_next = 8'h65;
                            endcase
                            if (send_cnt_reg == 8'h0A) begin
                                push_trigger_next = 0;
                                send_cnt_next     = 0;
                                state_next        = IDLE;
                            end else begin
                                send_cnt_next = send_cnt_reg + 1;
                            end
                        end
                    endcase


                end else begin
                    send_cnt_next  = send_cnt_reg;
                    send_data_next = send_data_reg;
                end
            end


        endcase
    end

endmodule
