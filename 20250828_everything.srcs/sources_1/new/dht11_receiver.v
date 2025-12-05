module dht11_receiver (
    input        clk,
    input        rst,
    input  [7:0] i_start,
    inout        dht_io,
    output       o_valid,
    output [7:0] temperature,
    output [7:0] humid,
    output       start_trigger
);
    reg dht_out_reg, dht_out_next;
    reg [9:0] c_state, n_state;
    localparam IDLE = 0, SYNC = 1, WAIT = 2, SYNCL = 3, SYNCH = 4, DBS=5,DATA=6, FIN=7;
    reg dht_io_enable_reg, dht_io_enable_next;
    reg [15:0] t_cnt_reg, t_cnt_next;
    reg [39:0] buffer_reg, buffer_next;
    reg [31:0] bit_cnt_reg, bit_cnt_next;
    reg o_valid_reg, o_valid_next;
    reg start_trigger_reg, start_trigger_next;

    assign dht_io = (dht_io_enable_reg) ? dht_out_reg : 1'hz;
    assign temperature = buffer_reg[23:16];
    assign humid = buffer_reg[39:32];
    assign o_valid = o_valid_reg;
    assign start_trigger = start_trigger_reg;


     dht_tick_gen_1us U_DHT_TICK_GEN (
      .clk(clk),
      .rst(rst),
     .o_tick_1us(i_tick)
);


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dht_out_reg       <= 1;
            c_state           <= 0;
            dht_io_enable_reg <= 1;
            bit_cnt_reg       <= 0;
            buffer_reg        <= 0;
            t_cnt_reg         <= 0;
            o_valid_reg       <= 0;
            start_trigger_reg <= 0;
        end else begin
            dht_out_reg <= dht_out_next;
            c_state <= n_state;
            dht_io_enable_reg <= dht_io_enable_next;
            bit_cnt_reg <= bit_cnt_next;
            buffer_reg <= buffer_next;
            t_cnt_reg <= t_cnt_next;
            o_valid_reg <= o_valid_next;
            start_trigger_reg <= start_trigger_next;

        end
    end

    always @(*) begin
        dht_out_next = dht_out_reg;
        n_state = c_state;
        dht_io_enable_next = dht_io_enable_reg;
        bit_cnt_next = bit_cnt_reg;
        buffer_next = buffer_reg;
        t_cnt_next = t_cnt_reg;
        start_trigger_next = start_trigger_reg;
        o_valid_next = o_valid_reg;
        if (c_state != IDLE) begin
            if (t_cnt_reg > 30000) begin
                n_state = IDLE;
            end
        end
        case (c_state)
            IDLE: begin
                dht_out_next = 1'b1;
                dht_io_enable_next = 1'b1;
                bit_cnt_next = 0;
                o_valid_next = 0;
                start_trigger_next = 1'b0;
                t_cnt_next = 0;
                if (i_start == 8'h73) begin
                    dht_out_next = 1'b0;
                    n_state = SYNC;
                end
            end
            SYNC: begin
                dht_out_next = 1'b0;
                if (i_tick) begin
                    if (t_cnt_reg == 18000) begin
                        n_state = WAIT;
                        t_cnt_next = 0;
                        dht_out_next = 1'b1;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end

            end
            WAIT: begin
                dht_out_next = 1'b1;
                if (i_tick) begin
                    if (t_cnt_reg == 30) begin
                        n_state = SYNCL;
                        t_cnt_next = 0;
                        dht_io_enable_next = 0;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                dht_io_enable_next = 0;
                bit_cnt_next = 0;
                if (i_tick) begin
                    if (t_cnt_reg > 50) begin
                        if (dht_io) begin
                            n_state = SYNCH;
                            t_cnt_next = 0;
                        end
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end

            end
            SYNCH: begin
                if (i_tick) begin
                    t_cnt_next = t_cnt_reg + 1;
                    if (dht_io == 0) begin
                        n_state = DBS;
                        t_cnt_next = 0;
                    end
                end
            end
            DBS: begin
                t_cnt_next = 0;
                if (i_tick) begin
                    t_cnt_next = t_cnt_reg + 1;
                    if (dht_io == 1) begin
                        n_state = DATA;
                        buffer_next = buffer_reg << 1;
                        t_cnt_next = 0;
                    end
                end
            end
            DATA: begin
                if (i_tick) begin
                    t_cnt_next = t_cnt_reg + 1;
                    if (dht_io == 0) begin
                        if (t_cnt_reg > 50) begin
                            buffer_next[0] = 1;
                        end else begin
                            buffer_next[0] = 0;
                        end
                        bit_cnt_next = bit_cnt_reg + 1;
                        if (bit_cnt_reg == 39) begin
                            n_state = FIN;
                            t_cnt_next = 0;
                        end else begin
                            n_state = DBS;
                        end
                    end
                end
            end
            FIN: begin
                start_trigger_next = 1'b1;
                if (buffer_reg[7:0] == (buffer_reg[39:32]+ buffer_reg[31:24] + buffer_reg[23:16] + buffer_reg[15:8])) begin
                    o_valid_next = 1;
                end
                if (i_tick) begin
                    t_cnt_next = t_cnt_reg + 1;
                    if (t_cnt_reg == 18000) begin
                        n_state = IDLE;
                    end
                end
            end
        endcase
    end
endmodule


module dht_tick_gen_1us (
    input  clk,
    input  rst,
    output o_tick_1us
);

    parameter COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(COUNT)-1:0] tick_counter;
    reg tick;

    assign o_tick_1us = tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (tick_counter == COUNT - 1) begin
                tick_counter <= 0;
                tick <= 1'b1;
            end else begin
                tick_counter <= tick_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule