`timescale 1ns / 1ps

module tb_forwardhazard();

    // 1. Declare the wires to connect to the processor
    logic clk;
    logic reset;

    // 2. Instantiate your fully wired processor
    full_wiring uut (
        .clk(clk),
        .reset(reset)
    );

    // 3. Build the clock (ticks every 10ns)
    always #5 clk = ~clk;

    // 4. Run the simulation sequence
    initial begin
        // Initialize clock and hold processor in reset
        clk = 0;
        reset = 1;

        // Wait a moment, then release the reset to start the processor
        #20;
        reset = 0;

        // Let the processor run for 15 clock cycles. 
        // This is enough time for the 3 instructions to clear the pipeline.
        #150;
        
        // End simulation
        $finish;
    end

endmodule