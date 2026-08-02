`timescale 1ns / 1ps

module button_conditioner (
    input  logic clk,
    input  logic reset,        // NEW: Reset port
    input  logic btn_raw,
    output logic btn_pulse
);
    // 1. Synchronizer
    logic sync_1, sync_2;
    always_ff @(posedge clk) begin
        if (reset) begin
            sync_1 <= 0; 
            sync_2 <= 0;
        end else begin
            sync_1 <= btn_raw;
            sync_2 <= sync_1;
        end
    end

    // 2. Debounce Timer
    logic [19:0] counter;
    logic stable_state;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            stable_state <= 0;
        end else if (sync_2 == stable_state) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 20'd1000000) begin
                stable_state <= sync_2;
                counter <= 0;
            end
        end
    end

    // 3. Edge Detector
    logic last_state;
    always_ff @(posedge clk) begin
        if (reset) last_state <= 0;
        else       last_state <= stable_state;
    end

    assign btn_pulse = stable_state & ~last_state;
    
endmodule