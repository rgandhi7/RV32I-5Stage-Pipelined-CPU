`timescale 1ns / 1ps

module basys3_top (
    input  logic        clk,     // 100MHz clock straight from the board
    input  logic        btnC,    // Center button (Reset)
    input  logic        btnU,    // Up button (Our new Enter button)
    input  logic [15:0] sw,      // The 16 physical switches
    output logic [15:0] led      // The 16 physical LEDs
);

    // 1. Slow down the clock to ~1.5Hz
    // logic [25:0] clk_div;
    // logic slow_clk;

    // always_ff @(posedge clk) begin
        // clk_div <= clk_div + 1; 
    // end
    // assign slow_clk = clk_div[25]; 

    // Wires to catch the debug outputs (optional, can leave disconnected if unused)
    logic [31:0] top_pc_out;
    logic [31:0] top_alu_out;

    // 2. Drop our custom CPU motherboard into the Basys 3 chassis
    full_wiring my_cpu (
        .clk        (clk),     // Feed it the normal clock
        .reset      (btnC),         // Center button is reset
        
        // --- The New MMIO Connections ---
        .sw         (sw),           // Solder physical switches to motherboard
        .btn_enter  (btnU),         // Solder physical Up button to motherboard
        .led        (led),          // Solder motherboard LED driver to physical LEDs
        
        .pc_out     (top_pc_out),   
        .alu_out    (top_alu_out)   
    );

    // Note: We completely removed the old `assign led = top_alu_out[15:0];`
    // The CPU is now in full control of the LEDs via memory address 0x2000!

endmodule