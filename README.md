# UVM Verification Environment for a RISC-V Instruction Decoder
## What this verifies

The DUT is `DecodeUnit`, a Chisel-generated RTL block from the
[riscv-boom](https://github.com/riscv-boom/riscv-boom) project. It decodes a 32-bit
RISC-V instruction word into the internal micro-op fields the rest of the core needs
(ALU op, register indices, immediate, control signals, etc.).

Instruction coverage: **RV32I, RV64I, RV32M, RV64M, RV32A, RV64A** (scoped down from
the full IMAFDC set by the mentor to keep the lab focused).

## How it works

- Constrained-random `item`s are randomized and driven into the DUT (`driver.sv`)
  through a virtual interface (`decode_if.sv`).
- `monitor.sv` samples the DUT's outputs and forwards transactions to the scoreboard
  over an analysis port.
- `scoreboard.sv` holds an independent golden model (`decode_table_package.sv`) that
  computes the expected decode result and compares it field-by-field against the DUT.
- Each test (`test_case/test_*.sv`) generates and checks **10,000 randomized items**.
- Simulated with **Cadence Xcelium** (`xrun`), UVM 1.2 (`-uvmhome CDNS-1.2`).

## Two real bugs found and fixed here

1. **False fail in `test_RV32I`** -- a `CSRRC` instruction's opcode bits happened to
   collide with the `SFENCE.VMA` pattern used by the (PLA-minimized) decode table.
   `mem_cmd` is a don't-care field for CSR instructions, but the scoreboard compared
   it unconditionally. Fixed by only comparing `mem_cmd` when `fu_code == FU_MEM`.
2. **9 extra PASS counted in `test_RV32A`** -- the monitor kept sampling after the
   driver had already finished sending all 10,000 items, re-sending the last
   transaction to the scoreboard during the test's wind-down window. Fixed the
   monitor's sampling condition so it stops with the sequence.

Both were found by adding temporary `uvm_info` logging to the scoreboard, dumping the
log to a file, and grepping for the failing instruction/signal before cross-checking
against the RTL.

## How to run

```bash
cd sim
make run            # defaults to TEST=test_RV32I
make run TEST=test_RV32A
make wave           # opens the waveform in SimVision (requires wave.shm from a run)
make clean
```

Requires Cadence Xcelium (`xrun`) with a UVM 1.2 (CDNS-1.2) license.

## Structure

```
sim/                   Makefile + filelist.f (simulation entry point)
src/boom_decode/       RTL (DecodeUnit.v) + UVM testbench (item, driver, monitor,
                        scoreboard, agent, env, base_test, tb) + test_case/
```
