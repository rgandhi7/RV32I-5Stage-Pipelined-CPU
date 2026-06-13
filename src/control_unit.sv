`timescale 1ns / 1ps

module control_unit (
    input  logic [6:0] opcode,
    
    // Control flags
    output logic       Branch,
    output logic       MemRead,
    output logic       MemtoReg,
    output logic       MemWrite,
    output logic       ALUSrc,
    output logic       RegWrite,
    
    // ALU selector
    output logic [1:0] ALUOp
);

    always_comb begin
        // 1. Default Signals Are Zero
        Branch   = 1'b0;
        MemRead  = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;
        ALUOp    = 2'b00;

        case (opcode)
            
            // ADD, SUB, AND, OR (R-Type)
            7'b0110011: begin
                RegWrite = 1'b1;  // Save to register
                ALUOp    = 2'b10; // Tell ALU control to look at funct3
            end

            // Add Immediate (ADDI) - NEW BLOCK
            7'b0010011: begin
                ALUSrc   = 1'b1;  // Route immediate value into ALU
                RegWrite = 1'b1;  // Save answer to register
                ALUOp    = 2'b00; // Force ALU to ADD
            end
            
            // Load Word
            7'b0000011: begin
                ALUSrc   = 1'b1;  // Route immediate offset into ALU
                MemRead  = 1'b1;  // Turn on the Data Memory
                MemtoReg = 1'b1;  // Memory Back to Registers
                RegWrite = 1'b1;  // Open Register File
                ALUOp    = 2'b00; // Force ALU to ADD
            end
            
            // Store Word
            7'b0100011: begin
                ALUSrc   = 1'b1;  // Route immediate offset into ALU
                MemWrite = 1'b1;  // Turn on the Data Memory write
                ALUOp    = 2'b00; // Force ALU to ADD
            end
            
            // Branch if Equal (BEQ)
            7'b1100011: begin
                Branch   = 1'b1;  // Branch Flag
                ALUOp    = 2'b01; // Force ALU to SUBTRACT
            end
            
            default: begin
            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            ALUSrc   = 1'b0;
            RegWrite = 1'b0;
            ALUOp    = 2'b00;
        end
endcase
    end

endmodule