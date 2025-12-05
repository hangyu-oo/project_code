`timescale 1ns / 1ps

module sr04_sender (
    input        clk,
    input        rst,
    input  [8:0] dist_data,
    input        dist_done,
    input        full,
    output       push,
    output [7:0] send_data
);

    localparam IDLE = 0, SEND = 1;
    reg s, ns;
    wire [31:0] w_send_data;
    reg [1:0] send_cnt_reg, send_cnt_next;
    reg push_reg, push_next;
    reg tx_done_reg, tx_done_next;
    reg [7:0] send_data_reg, send_data_next;

    datatoascii U_DtoA (
        .i_data(dist_data),
        .o_data(w_send_data)
    );

    assign send_data = send_data_reg;
    assign push = push_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s             <= IDLE;
            send_cnt_reg  <= 0;
            send_data_reg <= 0;
            tx_done_reg   <= 0;
            push_reg      <= 0;
        end else begin
            s             <= ns;
            send_cnt_reg  <= send_cnt_next;
            send_data_reg <= send_data_next;
            tx_done_reg   <= tx_done_next;
            push_reg      <= push_next;
        end
    end

    always @(*) begin
        ns             = s;
        send_cnt_next  = send_cnt_reg;
        send_data_next = send_data_reg;
        tx_done_next   = tx_done_reg;
        push_next      = push_reg;
        case (s)
            IDLE: begin
                tx_done_next  = 1'b0;
                send_cnt_next = 1'b0;
                push_next     = 1'b0;
                if (dist_done) begin
                    ns = SEND;
                end
            end

            SEND: begin
                if (~full) begin
                    push_next = 1;
                    if (send_cnt_reg < 4) begin
                        case (send_cnt_reg)
                            2'b00: send_data_next = w_send_data[31:24];
                            2'b01: send_data_next = w_send_data[23:16];
                            2'b10: send_data_next = w_send_data[15:8];
                            2'b11: send_data_next = w_send_data[7:0];
                        endcase
                        if (send_cnt_reg == 3) begin
                            ns = IDLE;
                            tx_done_next = 1'b1;
                        end else begin
                            send_cnt_next = send_cnt_reg + 1;
                        end
                    end
                end
            end
        endcase
    end
endmodule

module datatoascii (
    input  [13:0] i_data,
    output [31:0] o_data
);

    assign o_data[7:0]   = i_data % 10 + 8'h30;
    assign o_data[15:8]  = (i_data / 10) % 10 + 8'h30;
    assign o_data[23:16] = (i_data / 100) % 10 + 8'h30;
    assign o_data[31:24] = (i_data / 1000) % 10 + 8'h30;

endmodule