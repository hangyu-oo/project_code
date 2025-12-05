`timescale 1ns / 1ps


module watch_cu (
    input        clk,
    input        rst,
    input        Btn_L,
    input        Btn_U,
    input        Btn_D,
    input        Btn_R,
    output [1:0] set_sec,
    output [1:0] set_min,
    output [1:0] set_hour,
    output [2:0] led,
    input        sw_w_mode
);

    parameter [1:0] MODE_SEC = 2'b00, MODE_MIN = 2'b01, MODE_HOUR = 2'b10;

    reg [1:0] mode_reg, mode_next;

    assign set_sec  = (mode_reg == MODE_SEC) ? {Btn_U, Btn_D} : 0;
    assign set_min  = (mode_reg == MODE_MIN) ? {Btn_U, Btn_D} : 0;
    assign set_hour = (mode_reg == MODE_HOUR) ? {Btn_U, Btn_D} : 0;
    assign led[0]   = sw_w_mode ? ((mode_reg == MODE_SEC) ? 1 : 0) : 0;
    assign led[1]   = sw_w_mode ? ((mode_reg == MODE_MIN) ? 1 : 0) : 0;
    assign led[2]   = sw_w_mode ? ((mode_reg == MODE_HOUR) ? 1 : 0) : 0;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            mode_reg <= MODE_SEC;
        end else begin
            mode_reg <= mode_next;
        end
    end


    always @(*) begin
        mode_next = mode_reg;
        case (mode_reg)
            MODE_SEC: begin
                if (Btn_R) begin
                    mode_next = MODE_HOUR;
                end else if (Btn_L) begin
                    mode_next = MODE_MIN;
                end
            end
            MODE_MIN: begin
                if (Btn_R) begin
                    mode_next = MODE_SEC;
                end else if (Btn_L) begin
                    mode_next = MODE_HOUR;
                end
            end
            MODE_HOUR: begin
                if (Btn_R) begin
                    mode_next = MODE_MIN;
                end else if (Btn_L) begin
                    mode_next = MODE_SEC;
                end
            end
        endcase
    end

endmodule
