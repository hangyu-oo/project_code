`timescale 1ns / 1ps

module sw_w_receiver (
    input        clk,
    input        rst,
    input  [7:0] rx_data,
    input        rx_trigger,
    input        i_sw_w_mode,
    input        i_time_mode,
    output       cmd_u,
    output       cmd_d,
    output       cmd_l,
    output       cmd_r,
    output       o_sw_w_mode,
    output       o_time_mode,
    output       mode_changed_trigger
);
    wire w_sw0_rising_edge, w_sw0_falling_edge;
    wire w_sw1_rising_edge, w_sw1_falling_edge;
    assign mode_changed_trigger = w_sw1_falling_edge || w_sw1_rising_edge;
    switch_edge_detect U_SW0_EDGE_DETECT (
        .clk         (clk),
        .rst         (rst),
        .switch      (i_time_mode),
        .Rising_edge (w_sw0_rising_edge),
        .Falling_edge(w_sw0_falling_edge)
    );
    switch_edge_detect U_SW1_EDGE_DETECT (
        .clk         (clk),
        .rst         (rst),
        .switch      (i_sw_w_mode),
        .Rising_edge (w_sw1_rising_edge),
        .Falling_edge(w_sw1_falling_edge)
    );

    // 모드/상태
    localparam MODE_SW = 1'b0, MODE_W = 1'b1;
    // 시간 표시 모드
    localparam HOUR_MIN = 1'b1, SEC_MSEC = 1'b0;

    localparam [1:0] RUN = 2'b00, STOP = 2'b01, CLEAR = 2'b10, SW_IDLE = 2'b11;

    localparam [2:0] LEFT  = 3'b000,
                    RIGHT = 3'b001,
                    UP    = 3'b010,
                    DOWN  = 3'b011,
                    W_IDLE= 3'b100;

    // ASCII
    localparam [7:0] CH_r = 8'h72,  //r
    CH_s = 8'h73,  //s
    CH_c = 8'h63,  //c
    CH_m = 8'h6d,  //m
    CH_M = 8'h4d,  //M
    CH_plus = 8'h2b,  //+
    CH_minus = 8'h2d,  //-
    CH_L = 8'h4c,  //L
    CH_R = 8'h52;  //R

    // 레지스터
    reg mode_reg, mode_next;
    reg time_mode_reg, time_mode_next;
    reg [1:0] sw_reg, sw_next;
    reg [2:0] w_reg, w_next;
    reg last_run_stop_reg, last_run_stop_next;

    // 출력 매핑
    assign cmd_r = (sw_reg == RUN || sw_reg == STOP || w_reg == RIGHT) ? 1 : 0;
    assign cmd_l = (sw_reg == CLEAR || w_reg == LEFT) ? 1 : 0;
    assign cmd_u = (w_reg == UP) ? 1 : 0;
    assign cmd_d = (w_reg == DOWN) ? 1 : 0;
    assign o_sw_w_mode = mode_reg;
    assign o_time_mode = time_mode_reg;

    // 순차 블록
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode_reg          <= MODE_SW;
            time_mode_reg     <= SEC_MSEC;
            sw_reg            <= SW_IDLE;
            w_reg             <= W_IDLE;
            last_run_stop_reg <= STOP;
        end else begin
            mode_reg          <= mode_next;
            time_mode_reg     <= time_mode_next;
            sw_reg            <= sw_next;
            w_reg             <= w_next;
            last_run_stop_reg <= last_run_stop_next;
        end
    end

    // 조합 블록
    always @(*) begin
        //초기화
        mode_next          = mode_reg;
        sw_next            = sw_reg;
        w_next             = w_reg;
        last_run_stop_next = last_run_stop_reg;
        time_mode_next     = time_mode_reg;

        // time_mode switch
        if (time_mode_reg == SEC_MSEC) begin
            if (rx_trigger && rx_data == CH_M) begin
                time_mode_next = HOUR_MIN;
            end else if (w_sw0_rising_edge) begin
                time_mode_next = HOUR_MIN;
            end else begin
                time_mode_next = time_mode_reg;
            end
        end else if (time_mode_reg == HOUR_MIN) begin
            if (rx_trigger && rx_data == CH_M) begin
                time_mode_next = SEC_MSEC;
            end else if (w_sw0_falling_edge) begin
                time_mode_next = SEC_MSEC;
            end else begin
                time_mode_next = time_mode_reg;
            end
        end

        //sw_w_mode switch
        if (mode_reg == MODE_SW) begin
            if (rx_trigger && rx_data == CH_m) begin
                mode_next = MODE_W;
            end else if (w_sw1_rising_edge) begin
                mode_next = MODE_W;
            end else begin
                mode_next = mode_reg;
            end
        end else if (mode_reg == MODE_W) begin
            if (rx_trigger && rx_data == CH_m) begin
                mode_next = MODE_SW;
            end else if (w_sw1_falling_edge) begin
                mode_next = MODE_SW;
            end else begin
                mode_next = mode_reg;
            end
        end
        // mode swap initailize
        if (mode_next != mode_reg) begin
            sw_next = SW_IDLE;
            w_next  = W_IDLE;
        end

        // stopwatch mode
        if (mode_reg == MODE_SW) begin
            if (sw_reg != SW_IDLE) begin
                sw_next = SW_IDLE;
            end else begin
                if (rx_trigger) begin
                    case (rx_data)
                        CH_r: begin
                            if (last_run_stop_reg == STOP) begin
                                sw_next = RUN;
                                last_run_stop_next = RUN;
                            end else sw_next = SW_IDLE;
                        end
                        CH_s: begin
                            if (last_run_stop_reg == RUN) begin
                                sw_next = STOP;
                                last_run_stop_next = STOP;
                            end else sw_next = SW_IDLE;
                        end
                        CH_c: begin
                            sw_next = CLEAR;
                        end
                    endcase
                end
            end
        end

        // watch mode
        if (mode_reg == MODE_W) begin
            if (w_reg != W_IDLE) begin
                w_next = W_IDLE;
            end else begin
                if (rx_trigger) begin
                    case (rx_data)
                        CH_plus: begin
                            w_next = UP;
                        end
                        CH_minus: begin
                            w_next = DOWN;
                        end
                        CH_L: begin
                            w_next = LEFT;
                        end
                        CH_R: begin
                            w_next = RIGHT;
                        end
                    endcase
                end
            end

        end
    end
endmodule



module switch_edge_detect (
    input      clk,
    input      rst,
    input      switch,
    output reg Rising_edge,
    output reg Falling_edge
);
    reg delay1, delay2;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            delay1 <= 0;
            delay2 <= 0;
        end else begin
            delay1 <= switch;
            delay2 <= delay1;
            Falling_edge = ~delay1 & delay2;
            Rising_edge  = delay1 & ~delay2;
        end
    end

endmodule
