`timescale 1ns / 1ps

module full_wiring (
    input  logic        clk,
    input  logic        reset,
    
    // --- NEW MMIO PORTS ---
    input  logic [15:0] sw,          // 16 physical switches
    input  logic        btn_enter,   // Raw center button
    output logic [15:0] led,         // 16 physical LEDs
    
    output logic [31:0] pc_out,   
    output logic [31:0] alu_out   
);

    // internal routing
    logic [31:0] current_pc;
    logic [31:0] next_pc;
    logic [31:0] fetched_instruction;
    
    // control signals
    logic        Branch;
    logic        MemRead;
    logic        MemtoReg;
    logic        MemWrite;
    logic        ALUSrc;
    logic        RegWrite;
    logic [1:0]  ALUOp;
    logic [3:0]  ALUCtrl;
    
    // reg file wires
    logic [31:0] reg_read_data1;
    logic [31:0] reg_read_data2;
    logic [31:0] reg_write_data;

    // alu wires
    logic [31:0] alu_operand_b;
    logic [31:0] alu_result;
    logic        alu_zero;

    // memory wire
    logic [31:0] mem_read_data;

    // extract immediate based on opcode
    logic [31:0] immediate_val;
                            
    // pc and branch logic
    logic [31:0] pc_plus_4;
    logic [31:0] branch_target;
    logic        branch_taken;

    // pipeline wires
    logic pc_write;
    logic if_id_write;
    logic flush_control;

    // if/id wires
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instruction;

    // id/ex wires
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_reg_data1;
    logic [31:0] id_ex_reg_data2;
    logic [31:0] id_ex_imm;
    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;
    logic        id_ex_RegWrite;
    logic        id_ex_MemtoReg;
    logic        id_ex_MemRead;
    logic        id_ex_MemWrite;
    logic        id_ex_Branch;
    logic        id_ex_ALUSrc;
    logic [1:0]  id_ex_ALUOp;
    logic [2:0]  id_ex_funct3;
    logic        id_ex_funct7;

    // forwarding wires
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;
    logic [31:0] forwarded_a_val;
    logic [31:0] forwarded_b_val;

    // ex/mem wires
    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_reg_data2;
    logic [31:0] ex_mem_branch_target;
    logic [4:0]  ex_mem_rd;
    logic        ex_mem_alu_zero;
    logic        ex_mem_RegWrite;
    logic        ex_mem_MemtoReg;
    logic        ex_mem_MemRead;
    logic        ex_mem_MemWrite;
    logic        ex_mem_Branch;

    // mem/wb wires
    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_mem_read_data; // EDIT 1: Restored registered read-data wire
    logic [4:0]  mem_wb_rd;
    logic        mem_wb_RegWrite;
    logic        mem_wb_MemtoReg;

    // 1. The Debouncer (Now with Reset)
    logic clean_btn_pulse;

    button_conditioner enter_btn_sync (
        .clk       (clk),
        .reset     (reset),          // Wired to the CPU's global reset
        .btn_raw   (btn_enter),
        .btn_pulse (clean_btn_pulse)
    );

    // 2. The Clear-on-Read Hardware Flag
    logic btn_pending;
    logic btn_read_now;
    
    // Detect the exact cycle the CPU reads address 0x1004
    assign btn_read_now = (ex_mem_alu_result == 32'h00001004) && ex_mem_MemRead;

    always_ff @(posedge clk) begin
        if (reset) begin
            btn_pending <= 1'b0;
        end else if (clean_btn_pulse) begin
            btn_pending <= 1'b1;     // Latch the physical press
        end else if (btn_read_now) begin
            btn_pending <= 1'b0;     // Clear it the moment the CPU consumes it
        end
    end

    // 3. The Updated MMIO Mux
    logic [31:0] mmio_read_data;

    always_comb begin
        if (ex_mem_alu_result == 32'h00001000) begin
            mmio_read_data = {16'b0, sw};                  // Route Switches
        end else if (ex_mem_alu_result == 32'h00001004) begin
            mmio_read_data = {31'b0, btn_pending};         // Route the Sticky Flag
        end else begin
            mmio_read_data = mem_read_data;                // Route RAM
        end
    end
    // IF/ID register
    always_ff @(posedge clk) begin
        if (reset || branch_taken) begin
            if_id_pc          <= 0;
            if_id_instruction <= 0;
        end else if (if_id_write) begin 
            if_id_pc          <= current_pc;
            if_id_instruction <= fetched_instruction;
        end
    end

    // ID/EX register
    always_ff @(posedge clk) begin
        if (reset) begin
            id_ex_pc        <= 0;
            id_ex_reg_data1 <= 0;
            id_ex_reg_data2 <= 0;
            id_ex_imm       <= 0;
            id_ex_rs1       <= 0;
            id_ex_rs2       <= 0;
            id_ex_rd        <= 0;
            
            id_ex_RegWrite  <= 0;
            id_ex_MemtoReg  <= 0;
            id_ex_MemRead   <= 0;
            id_ex_MemWrite  <= 0;
            id_ex_Branch    <= 0;
            id_ex_ALUSrc    <= 0;
            id_ex_ALUOp     <= 0;
            id_ex_funct3    <= 0;
            id_ex_funct7    <= 0;
        end else begin
            id_ex_pc        <= if_id_pc; 
            id_ex_reg_data1 <= reg_read_data1;
            id_ex_reg_data2 <= reg_read_data2;
            id_ex_imm       <= immediate_val;
            
            // Clear rs1/rs2 on flush to avoid NOP execution glitches
            id_ex_rs1       <= (flush_control || branch_taken) ? 5'b0 : if_id_instruction[19:15];
            id_ex_rs2       <= (flush_control || branch_taken) ? 5'b0 : if_id_instruction[24:20];
            id_ex_rd        <= if_id_instruction[11:7];
              
            // Flush control muxes
            id_ex_RegWrite  <= (flush_control || branch_taken) ? 1'b0 : RegWrite;
            id_ex_MemtoReg  <= (flush_control || branch_taken) ? 1'b0 : MemtoReg;
            id_ex_MemRead   <= (flush_control || branch_taken) ? 1'b0 : MemRead;
            id_ex_MemWrite  <= (flush_control || branch_taken) ? 1'b0 : MemWrite;
            id_ex_Branch    <= (flush_control || branch_taken) ? 1'b0 : Branch;
            id_ex_ALUSrc    <= (flush_control || branch_taken) ? 1'b0 : ALUSrc;
            id_ex_ALUOp     <= (flush_control || branch_taken) ? 2'b00 : ALUOp;
            id_ex_funct3    <= if_id_instruction[14:12];
            id_ex_funct7    <= if_id_instruction[30];
        end
    end

    // EX/MEM register
    always_ff @(posedge clk) begin
        if (reset) begin
            ex_mem_alu_result    <= 0;
            ex_mem_reg_data2     <= 0;
            ex_mem_branch_target <= 0;
            ex_mem_rd            <= 0;
            ex_mem_alu_zero      <= 0;
            
            ex_mem_RegWrite      <= 0;
            ex_mem_MemtoReg      <= 0;
            ex_mem_MemRead       <= 0;
            ex_mem_MemWrite      <= 0;
            ex_mem_Branch        <= 0;
        end else begin
            ex_mem_alu_result    <= alu_result;
            ex_mem_reg_data2     <= forwarded_b_val; // Capture post-forwarding value for sw
            ex_mem_branch_target <= id_ex_pc + id_ex_imm; 
            ex_mem_rd            <= id_ex_rd;
            ex_mem_alu_zero      <= alu_zero;
            
            // Squash control signals on taken branches
            ex_mem_RegWrite      <= branch_taken ? 1'b0 : id_ex_RegWrite;
            ex_mem_MemtoReg      <= branch_taken ? 1'b0 : id_ex_MemtoReg;
            ex_mem_MemRead       <= branch_taken ? 1'b0 : id_ex_MemRead;
            ex_mem_MemWrite      <= branch_taken ? 1'b0 : id_ex_MemWrite;
            ex_mem_Branch        <= branch_taken ? 1'b0 : id_ex_Branch;
        end
    end


    // MEM/WB register
    always_ff @(posedge clk) begin
        if (reset) begin
            mem_wb_alu_result    <= 0;
            mem_wb_mem_read_data <= 0; 
            mem_wb_rd            <= 0;
            mem_wb_RegWrite      <= 0;
            mem_wb_MemtoReg      <= 0;
        end else begin
            mem_wb_alu_result    <= ex_mem_alu_result;
            mem_wb_mem_read_data <= mmio_read_data; // Capture the Mux output here
            mem_wb_rd            <= ex_mem_rd;
            mem_wb_RegWrite      <= ex_mem_RegWrite;
            mem_wb_MemtoReg      <= ex_mem_MemtoReg;
        end
    end

    // Immediate Extractor (Decode Stage)
    assign immediate_val = (if_id_instruction[6:0] == 7'b0100011) ? 
                           {{20{if_id_instruction[31]}}, if_id_instruction[31:25], if_id_instruction[11:7]} : // sw
                           (if_id_instruction[6:0] == 7'b1100011) ? 
                           {{20{if_id_instruction[31]}}, if_id_instruction[7], if_id_instruction[30:25], if_id_instruction[11:8], 1'b0} : // beq
                           {{20{if_id_instruction[31]}}, if_id_instruction[31:20]}; // addi, lw
                           
    // PC & Branch Logic
    assign pc_plus_4    = current_pc + 4;
    assign branch_taken = ex_mem_Branch & ex_mem_alu_zero;
    assign next_pc      = branch_taken ? ex_mem_branch_target : pc_plus_4;

    pc my_pc (
        .clk(clk),
        .rst(reset),
        .en(pc_write | branch_taken),
        .next_pc(next_pc),
        .pc_out(current_pc)
    );

    instruction_memory imem (
        .pc_addr(current_pc),
        .instruction(fetched_instruction)
    );

    control_unit main_ctrl (
        .opcode(if_id_instruction[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ALUOp(ALUOp)
    );

    alu_control alu_ctrl (
        .ALUOp(id_ex_ALUOp),
        .funct3(id_ex_funct3), 
        .funct7_bit(id_ex_funct7),
        .ALUCtrl(ALUCtrl)
    );

    hazard_detection_unit hazard_unit (
        .id_ex_MemRead(id_ex_MemRead),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(if_id_instruction[19:15]),
        .if_id_rs2(if_id_instruction[24:20]),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .flush_control(flush_control)
    );

    // EDIT 3: Writeback Mux reads from registered pipeline data
    assign reg_write_data = mem_wb_MemtoReg ? mem_wb_mem_read_data : mem_wb_alu_result;

    register_file regs (
        .clk(clk),
        .we(mem_wb_RegWrite),
        .rs1_addr(if_id_instruction[19:15]),
        .rs2_addr(if_id_instruction[24:20]),
        .rd_addr(mem_wb_rd),
        .rd_data(reg_write_data),
        .rs1_data(reg_read_data1),
        .rs2_data(reg_read_data2)
    );

    // Forwarding Unit (Single Instance)
    forwarding_unit fwd_unit (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_RegWrite(ex_mem_RegWrite),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_RegWrite(mem_wb_RegWrite),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // Forwarding Multiplexers
    assign forwarded_a_val = (forward_a == 2'b10) ? ex_mem_alu_result :
                             (forward_a == 2'b01) ? reg_write_data :
                             id_ex_reg_data1;

    assign forwarded_b_val = (forward_b == 2'b10) ? ex_mem_alu_result :
                             (forward_b == 2'b01) ? reg_write_data :
                             id_ex_reg_data2;

    assign alu_operand_b   = id_ex_ALUSrc ? id_ex_imm : forwarded_b_val;

    alu main_alu (
        .a(forwarded_a_val),                    
        .b(alu_operand_b),                      
        .alu_ctrl(ALUCtrl),                    
        .result(alu_result),
        .zero(alu_zero)
    );

    logic safe_ram_write_en;
    
    // Only allow RAM writes if the address is normal memory (less than 0x1000)
    assign safe_ram_write_en = ex_mem_MemWrite & (ex_mem_alu_result < 32'h00001000);

    // The LED Register (Address 0x2000)
    always_ff @(posedge clk) begin
        if (reset) begin
            led <= 16'b0;
        end else if (ex_mem_MemWrite && (ex_mem_alu_result == 32'h00002000)) begin
            led <= ex_mem_reg_data2[15:0]; // Grab bottom 16 bits of the stored word
        end
    end

    data_memory dmem (
        .clk(clk),
        .MemRead(ex_mem_MemRead),
        .MemWrite(safe_ram_write_en),  // Use the protected write signal here!
        .address(ex_mem_alu_result),
        .write_data(ex_mem_reg_data2),
        .read_data(mem_read_data)
    );

    assign pc_out  = current_pc;
    assign alu_out = alu_result;

endmodule// Forwarding and hazard control lines connected
// Forwarding and hazard control lines connected
