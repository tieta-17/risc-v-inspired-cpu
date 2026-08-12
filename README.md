# RISC-V Inspired CPU

## Description

I started this project as an extension of work I did in my ECE 2330 class at UVA: Digital Logic Design.

In that class, we designed and built a simple single-cycle CPU in VHDL. Validation was done with testbenches and visualization using Quartus Prime Lite.

I wanted to actually learn Verilog rather than just read about it, so instead of reimplementing the same VHDL project line-for-line, I decided to build something new: a from-scratch CPU with a custom ISA, taken all the way from a single-cycle datapath to a fully pipelined, hazard-aware processor that models the structure of a real RISC-V core.

Every module in this project (register file, ALU, control unit, pipeline registers, hazard detection, and forwarding logic) was built and independently verified with its own Icarus Verilog testbench before being wired into the next layer up. I spent time trying to understand every signal in this design.

## Architecture

- **32-bit, RISC-V-inspired ISA**, 16 general-purpose registers (`x0` hardwired to zero), custom 8-instruction encoding with room to grow to 16
- **5-stage pipeline**: Fetch → Decode → Execute → Memory → Write-back, with dedicated pipeline registers (`if_id`, `id_ex`, `ex_mem`, `mem_wb`) between each stage
- **Hazard handling**:
  - Load-use hazard detection with automatic pipeline stalling
  - Forwarding unit covering both EX/MEM and MEM/WB bypass paths
  - Same-cycle write-through in the register file (handles the write-back/decode same-cycle read case)
  - Branch flushing on taken branches, squashing wrong-path instructions in both IF/ID and ID/EX

## Instruction Set

| Opcode | Mnemonic | Type | Meaning |
|---|---|---|---|
| 0000 | ADD  | R | `rd = rs1 + rs2` |
| 0001 | SUB  | R | `rd = rs1 - rs2` |
| 0010 | AND  | R | `rd = rs1 & rs2` |
| 0011 | OR   | R | `rd = rs1 \| rs2` |
| 0100 | ADDI | I | `rd = rs1 + imm` |
| 0101 | LW   | I | `rd = MEM[rs1 + imm]` |
| 0110 | SW   | I | `MEM[rs1 + imm] = rd` |
| 0111 | BEQ  | I | `if (rs1 == rd) PC += imm` |

## Status

The pipelined CPU is functionally complete and passes a growing testbench suite covering:
- Individual ALU operations and control-unit decode logic
- EX/MEM and MEM/WB forwarding, tested independently and in combination
- Load-use stalling
- Taken and not-taken branches, including forwarding into a branch's own comparison
- A full multiplication-via-loop test program, exercising a loop-carried data hazard and repeated branch flushing across many iterations, end to end

## What's next

- FPGA bring-up on a Tang Nano 9K — top-level wrapper, real program loading, first bitstream flash
- Extending the ISA (shifts, unconditional jump, more instructions)
- Eventually: a from-scratch build targeting real RV32I encoding