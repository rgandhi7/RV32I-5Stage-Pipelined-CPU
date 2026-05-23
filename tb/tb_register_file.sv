`timescale 1ns / 1ps

module tb_register_file();

    // 1. LOOSE WIRES: Pulling wires off the spool to use on our desk
    logic        clk;
    logic        we;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data, rs2_data;

    // 2. THE CHIP: Dropping the Register File onto the desk and connecting the loose wires to its metal legs
    register_file uut (
        .clk(clk),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // 3. THE METRONOME: Turning on a signal generator to flip the clock wire High/Low every 5 nanoseconds
    always #5 clk = ~clk;

    // 4. THE EXPERIMENT: Manually flipping switches to inject electricity
    initial begin
        // Start with all switches OFF (0 Volts)
        clk = 0; we = 0; 
        rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;
        
        #10; // Wait 10 nanoseconds for the electricity to settle

        // TEST A: Write the hex value 0xDEADBEEF into Mailbox 1
        rd_addr = 5'd1;           // Turn the Write dial to 1
        rd_data = 32'hDEADBEEF;   // Inject the data onto the wires
        we = 1;                   // Flip the Write Enable switch ON
        #10;                      // WAIT for the metronome to tick and open the vault door
        we = 0;                   // Flip the Write Enable switch OFF

        // TEST B: Read the data out of Mailbox 1
        rs1_addr = 5'd1;          // Turn the Read dial to 1 (Data will instantly shoot out)
        #10;

        // TEST C: Try to maliciously overwrite Mailbox 0 (The x0 Trap)
        rd_addr = 5'd0;           // Turn the Write dial to 0
        rd_data = 32'hFFFFFFFF;   // Inject maximum voltage
        we = 1;                   // Flip Write Enable ON
        #10;                      // WAIT for the tick (The hardware should block this)
        we = 0;

        // Check if Mailbox 0 survived
        rs2_addr = 5'd0;          // Turn Read dial 2 to Mailbox 0
        #20;

        $finish; // Turn off the power to the lab bench
    end

endmodule
