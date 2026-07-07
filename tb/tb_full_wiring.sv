`timescale 1ns / 1ps

module tb_full_wiring();

    // virtual probes to connect to the motherboard pins
    logic clk;
    logic reset;

    // drop in the fully wired motherboard
    full_wiring dut (
        .clk(clk),
        .reset(reset)
    );

    // generate a continuous clock pulse (toggles every 5 nanoseconds)
    always begin
        #5 clk = ~clk;
    end

    // press the power button and run the simulation
    initial begin
        // start with the clock off and the reset button held down
        clk = 0;
        reset = 1;

        // hold reset for 10ns to let the hardware stabilize, then release it
        #10 reset = 0;

        // let the CPU run for 100ns (plenty of time for a 5-line script)
        #100;
        
        // kill the power and end the simulation
        $finish;
    end

endmodule