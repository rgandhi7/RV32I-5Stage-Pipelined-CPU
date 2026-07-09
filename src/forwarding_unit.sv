`timescale 1ns / 1ps

module forwarding_unit (
    input logic [4:0] id_ex_rs1,
    input logic [4:0] id_ex_rs2,
    input logic [4:0] ex_mem_rd,
    input logic       ex_mem_RegWrite,
    input logic [4:0] mem_wb_rd,
    input logic       mem_wb_RegWrite,
    
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin
        if (ex_mem_RegWrite && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end else if (mem_wb_RegWrite && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end else begin
            forward_a = 2'b00;
        end
    end

    always_comb begin
        if (ex_mem_RegWrite && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end else if (mem_wb_RegWrite && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end else begin
            forward_b = 2'b00;
        end
    end

endmodule