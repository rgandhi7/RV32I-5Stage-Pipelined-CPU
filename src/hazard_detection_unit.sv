`timescale 1ns / 1ps

module hazard_detection_unit (
    input  logic       id_ex_MemRead,
    input  logic [4:0] id_ex_rd,
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,
    output logic       pc_write,
    output logic       if_id_write,
    output logic       flush_control
);

    always_comb begin
        // If the instruction in the Execute stage is a Load (MemRead == 1)
        // AND its destination register (rd) matches either of the source 
        // registers (rs1 or rs2) of the instruction in the Decode stage...
        if (id_ex_MemRead && (id_ex_rd != 5'b0) && 
           ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            
            // STALL THE PIPELINE for 1 clock cycle
            pc_write      = 1'b0; // Stop the Program Counter from advancing
            if_id_write   = 1'b0; // Freeze the instruction in the Decode stage
            flush_control = 1'b1; // Inject a "bubble" (NOP) into the Execute stage
            
        end else begin
            
            // NORMAL OPERATION
            pc_write      = 1'b1;
            if_id_write   = 1'b1;
            flush_control = 1'b0;
            
        end
    end

endmodule