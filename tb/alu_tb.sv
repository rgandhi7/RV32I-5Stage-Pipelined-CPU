`timescale 1ns / 1ps

module alu_tb();

    logic [31:0] tb_a;
    logic [31:0] tb_b;
    logic [3:0]  tb_alu_ctrl;
    logic [31:0] tb_result;
    logic        tb_zero;

    alu uut (
        .a(tb_a),
        .b(tb_b),
        .alu_ctrl(tb_alu_ctrl),
        .result(tb_result),
        .zero(tb_zero)
    );

    initial begin
        // Test 1: ADD
        tb_a = 32'd10; tb_b = 32'd15; tb_alu_ctrl = 4'b0000; 
        #10; 
        
        // Test 2: SUB (Zero Flag Test)
        tb_a = 32'd100; tb_b = 32'd100; tb_alu_ctrl = 4'b1000; 
        #10;

        // Test 3: AND
        tb_a = 32'hFFFF0000; tb_b = 32'h00FF0000; tb_alu_ctrl = 4'b0111; 
        #10;

        // Test 4: SLL
        tb_a = 32'd1; tb_b = 32'd4; tb_alu_ctrl = 4'b0001; 
        #10;

        // Test 5: SLT (Signed Negative)
        tb_a = 32'hFFFFFFFF; tb_b = 32'd10; tb_alu_ctrl = 4'b0010; 
        #10;

        // Test 6: SLTU (Unsigned Negative)
        tb_a = 32'hFFFFFFFF; tb_b = 32'd10; tb_alu_ctrl = 4'b0011; 
        #10;

        // Test 7: Default Trash Catch
        tb_a = 32'd999; tb_b = 32'd999; tb_alu_ctrl = 4'b1111; 
        #10;

        $finish;
    end
endmodule