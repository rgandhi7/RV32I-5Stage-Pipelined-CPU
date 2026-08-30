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

```text
[ IF ] ---> [ ID ] ---> [ EX ] ---> [ MEM ] ---> [ WB ]
  |           |           |            |
  |           |           +-- Forward --+
  +-- Hazard Unit -------+
