module register_file (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);
    logic [31:0] registers [31:0];

    // Asynchronous reads with write-through bypass
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 :
                       (we && (rd_addr == rs1_addr)) ? rd_data :
                       registers[rs1_addr];

    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 :
                       (we && (rd_addr == rs2_addr)) ? rd_data :
                       registers[rs2_addr];

    always_ff @(posedge clk) begin
        if (we && rd_addr != 5'b00000) begin
            registers[rd_addr] <= rd_data;
        end
    end
endmodule