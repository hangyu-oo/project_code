`timescale 1ns / 1ps

module sr04_top (
    input        clk,
    input        rst,
    input        sr04_start,
    input        echo,
    output       trig,
    output [3:0] sr04_fnd_com,
    output [7:0] sr04_fnd_data,
    output       o_dist_done,
    output [8:0] o_dist_data
);

    wire w_tick;

    tick_gen_1us U_TICK_GEN_1US (
        .clk(clk),
        .rst(rst),
        .o_tick_1us(w_tick)
    );

    sr04_controller U_SR04_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .start(sr04_start),
        .echo(echo),
        .i_tick(w_tick),
        .o_trig(trig),
        .o_dist(o_dist_data),
        .dist_done(o_dist_done)
    );

    sr04_fnd_controller U_SR04_FND_CONTROLLER (
        .clk(clk),
        .reset(rst),
        .counter(o_dist_data),
        .fnd_com(sr04_fnd_com),
        .fnd_data(sr04_fnd_data)
    );

endmodule


module sr04_controller (
    input        clk,
    input        rst,
    input        start,
    input        echo,
    input        i_tick,
    output       o_trig,
    output [8:0] o_dist,
    output       dist_done
);

    localparam [1:0] IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, DIST = 2'b11;
    reg [1:0] state, next;
    reg [14:0] i_tick_cnt_reg, i_tick_cnt_next;
    reg start_trig_reg, start_trig_next;
    reg [8:0] o_dist_reg, o_dist_next;
    reg dist_done_reg, dist_done_next;

    assign o_trig = start_trig_reg;
    assign o_dist = o_dist_reg;
    assign dist_done = dist_done_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            i_tick_cnt_reg <= 0;
            start_trig_reg <= 0;
            o_dist_reg     <= 0;
            dist_done_reg  <= 0;
        end else begin
            state          <= next;
            i_tick_cnt_reg <= i_tick_cnt_next;
            start_trig_reg <= start_trig_next;
            o_dist_reg     <= o_dist_next;
            dist_done_reg  <= dist_done_next;
        end
    end

    always @(*) begin
        next            = state;
        i_tick_cnt_next = i_tick_cnt_reg;
        start_trig_next = start_trig_reg;
        o_dist_next     = o_dist_reg;
        dist_done_next  = dist_done_reg;
        case (state)
            IDLE: begin
                dist_done_next  = 0;
                start_trig_next = 1'b0;
                if (i_tick) begin
                    if (start == 1) begin
                        start_trig_next = 1'b1;
                        i_tick_cnt_next = 0;
                        next = START;
                    end
                end
            end
            START: begin
                if (i_tick) begin
                    if (i_tick_cnt_reg == 10) begin
                        start_trig_next = 1'b0;
                        next = WAIT;
                    end else begin
                        i_tick_cnt_next = i_tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (i_tick) begin
                    if (echo == 1) begin
                        i_tick_cnt_next = 0;
                        next = DIST;
                    end
                end
            end
            DIST: begin
                if (echo) begin
                    if (i_tick) begin
                        i_tick_cnt_next = i_tick_cnt_reg + 1;
                    end
                end else begin
                    o_dist_next = i_tick_cnt_reg / 58;
                    dist_done_next = 1;
                    next = IDLE;
                end
            end

        endcase
    end

endmodule

module tick_gen_1us (
    input  clk,
    input  rst,
    output o_tick_1us
);

    parameter TICK_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(TICK_COUNT)-1 : 0] counter_reg;
    reg tick_1us;

    assign o_tick_1us = tick_1us;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_1us    <= 1'b0;
        end else begin
            if (counter_reg == TICK_COUNT - 1) begin
                counter_reg <= 0;
                tick_1us <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_1us <= 1'b0;
            end
        end
    end

endmodule
