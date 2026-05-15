module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,      // 1. ADDED: The enable pin from the Hazard Unit
    input  logic [31:0] next_pc,
    output logic [31:0] pc_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'h0000_0000;
        end else if (en) begin   // 2. ADDED: Only grab the next address if en == 1
            pc_out <= next_pc;
        end
    end

endmodule