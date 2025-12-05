`timescale 1ns / 1ps
module sr04_receiver (
    input        clk,
    input        rst,
    input  [7:0] command,
    // input        pop,
    input        rx_trigger,
    output       sr04_start
);

    reg sr04_start_reg, sr04_start_next;

    assign sr04_start = sr04_start_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            sr04_start_reg <= 0;
        end else begin
            sr04_start_reg <= sr04_start_next;
        end
    end

    always @(*) begin
        sr04_start_next = sr04_start_reg;
        if (rx_trigger) begin
            sr04_start_next = 0;
            if (command == 8'h72) begin
                sr04_start_next = 1;
            end
        end
    end

endmodule