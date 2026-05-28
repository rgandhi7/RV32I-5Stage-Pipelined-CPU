`timescale 1ns / 1ps

module alu_control (
    input  logic [1:0] ALUOp,
    input  logic [2:0] funct3,
    input  logic       funct7_bit,
    
    output logic [3:0] ALUCtrl
);

    always_comb begin
        // Default to Safety (ADD)
        ALUCtrl = 4'b0000;

        case (ALUOp)
            // Memory Load/Store: Force ADD (Ignore funct3)
            2'b00: begin
                ALUCtrl = 4'b0000; // Matches 'ADD' in your alu.sv
            end
            
            // Branch: Force SUBTRACT for comparison
            2'b01: begin
                ALUCtrl = 4'b1000; // Matches 'SUB' in your alu.sv
            end
            
            // R-Type Math: Look at Funct3 and Funct7 to decide
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (funct7_bit == 1'b1) 
                            ALUCtrl = 4'b1000; // SUB
                        else 
                            ALUCtrl = 4'b0000; // ADD
                    end
                    
                    3'b110: begin
                        ALUCtrl = 4'b0110;     // OR
                    end
                    
                    3'b111: begin
                        ALUCtrl = 4'b0111;     // AND
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end
    
endmodule