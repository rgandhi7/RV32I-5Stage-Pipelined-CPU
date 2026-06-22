`timescale 1ns / 1ps

module data_memory (
    input  logic        clk,
    input  logic        MemRead,
    input  logic        MemWrite,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    
    output logic [31:0] read_data
);

    // the physical memory grid: 256 rows, each 32 bits wide
    logic [31:0] memory_array [0:255];

    // read logic is instant (combinational)
    always_comb begin
        if (MemRead == 1'b1) begin
            // divide the incoming address by 4 by only looking at wires 9 through 2
            read_data = memory_array[address[9:2]];
        end else begin
            // if we aren't explicitly reading, output zero to keep the motherboard wires clean
            read_data = 32'b0;
        end
    end

    // write logic is dangerous, it only happens on the exact clock tick (sequential)
    always_ff @(posedge clk) begin
        if (MemWrite == 1'b1) begin
            memory_array[address[9:2]] <= write_data;
        end
    end

endmodule