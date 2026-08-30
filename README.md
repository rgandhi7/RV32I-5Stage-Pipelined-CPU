# 5-Stage Pipelined RV32I CPU Core

A 32-bit RISC-V processor core designed in SystemVerilog, synthesized and implemented on the Digilent Basys 3 FPGA (Artix-7). The core features a classic 5-stage pipeline architecture with explicit pipeline register isolation between stages, full hardware data forwarding, hazard detection with load-use stalling, and control hazard handling.

---

## Hardware Demonstration (Security Vault State Machine)

![Basys 3 Security Vault Demo](hardware-demo/demo.gif)

*The processor executing an assembly-level security vault program loaded into instruction ROM. Inputs from the Basys 3 board switches and buttons are synchronized via `button_sync.sv`, processed through the CPU pipeline, and displayed on the onboard LEDs.*

### Demonstration Walkthrough
1. **System Reset & Initial Query:** The sequence begins with a full system reset. Querying the system via the top button with no switches set (`0`) returns 4 LEDs, confirming the vault is locked.
2. **Intermediate Access Checks:** Switches are toggled sequentially to test incorrect or partial passkeys (`2` -> `10`). Pressing the query button evaluates the input through the pipeline, maintaining the locked state (4 LEDs).
3. **Vault Unlock:** Setting the final correct passkey (`42`) and querying the system completes the authentication sequence, illuminating all 16 LEDs to signify a successful unlock.

---

## Microarchitecture & Stage Separation

    [ IF ] ---> [ ID ] ---> [ EX ] ---> [ MEM ] ---> [ WB ]
      |           |           |            |
      |           |           +-- Forward --+
      +-- Hazard Unit -------+

### 1. Explicit Pipeline Register Separation
The CPU enforces strict temporal and physical isolation between execution phases through dedicated pipeline registers clocked synchronously on the global clock edge:
- **IF/ID Register:** Captures the fetched 32-bit instruction from `instruction_memory.sv` and the current PC value.
- **ID/EX Register:** Buffers decoded control signals from `control_unit.sv`, register operand values read from `register_file.sv`, sign-extended immediates, and source/destination register addresses (RS1, RS2, RD).
- **EX/MEM Register:** Holds the ALU execution result from `alu.sv`, write-data for memory stores, destination register index (RD), and memory control flags (`MemRead`, `MemWrite`, `RegWrite`).
- **MEM/WB Register:** Binds memory load data read from `data_memory.sv` and computed ALU results alongside write-back control signals (`MemtoReg`, `RegWrite`).

### 2. Pipeline Execution Stages
- **Instruction Fetch (IF):** PC generation via `pc.sv` with branch target multiplexing, fetching instructions from `instruction_memory.sv`.
- **Instruction Decode (ID):** Dual-port asynchronous read / synchronous write access to 31 32-bit registers (`register_file.sv`, `x0` hardwired to 0), immediate generation, and main control decoding via `control_unit.sv`.
- **Execute (EX):** Fine-grained arithmetic/logic execution driven by `alu.sv` and `alu_control.sv`, branch condition evaluation, and branch target address calculation.
- **Memory Access (MEM):** Synchronous data memory load/store operations executed via `data_memory.sv`.
- **Writeback (WB):** Multiplexes between memory load data and ALU execution outputs to update the register file.

---

## Hazard Mitigation & Control Logic

- **Data Forwarding Unit (`forwarding_unit.sv`):** Resolves EX/EX and MEM/EX Read-After-Write (RAW) hazards by bypassing execution outputs from EX/MEM and MEM/WB pipeline registers directly into the EX-stage ALU inputs, preventing execution stalls for dependent instructions.
- **Hazard Detection Unit (`hazard_detection_unit.sv`):** Detects Load-Use data dependencies where a load instruction in EX/MEM is followed by an instruction consuming that data in ID/EX. Automatically inserts a 1-cycle pipeline bubble (clearing ID/EX control signals) while freezing updates to `pc.sv` and the IF/ID register.
- **Control Hazard Handling:** Evaluates branch conditions (`BEQ`) in the EX stage. Upon a taken branch, flushes speculatively fetched instructions in the IF/ID and ID/EX pipeline registers to maintain architectural state integrity.

---

## Directory & File Structure

    ├── constraints/
    │   └── basys3_constraint.xdc      <-- Xilinx pin mapping & clock constraints
    ├── firmware/
    │   └── program.mem                <-- Hex machine code initialized in instruction ROM
    ├── hardware-demo/
    │   └── demo.gif                   <-- Basys 3 vault security execution demo
    ├── src/
    │   ├── alu.sv                     <-- Arithmetic Logic Unit
    │   ├── alu_control.sv             <-- ALU control decoder
    │   ├── basys3_module.sv           <-- FPGA top-level wrapper & clock division
    │   ├── button_sync.sv             <-- Input button debouncing & synchronization
    │   ├── control_unit.sv            <-- Main pipeline control logic
    │   ├── data_memory.sv             <-- Data RAM module
    │   ├── forwarding_unit.sv         <-- EX/MEM & MEM/WB data hazard forwarding logic
    │   ├── full_wiring.sv             <-- Datapath integration & pipeline register interconnects
    │   ├── hazard_detection_unit.sv   <-- Load-use stall detection & pipeline freeze logic
    │   ├── instruction_memory.sv      <-- Instruction ROM initialized with program.mem
    │   ├── pc.sv                      <-- Program counter logic
    │   └── register_file.sv           <-- 32 x 32-bit register file
    └── tb/                            <-- Verification testbenches

---

## Toolchain & Hardware Specs

- **HDL Language:** SystemVerilog
- **Synthesis & Implementation:** Xilinx Vivado
- **Target FPGA:** Digilent Basys 3 (Xilinx Artix-7 XC7A35T)
- **Top Level Interconnect:** `full_wiring.sv` wrapped inside `basys3_module.sv`
