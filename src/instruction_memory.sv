`timescale 1ns / 1ps

module instruction_memory (
    input  logic [31:0] pc_addr,
    output logic [31:0] instruction
);

    // 256-row memory grid
    logic [31:0] rom_array [0:255];

    // flash the memory on startup using an external file
    initial begin
        $readmemh("program.mem", rom_array);
    end
    
    // divide address by 4 and output the instruction
    assign instruction = rom_array[pc_addr[9:2]];

endmodule