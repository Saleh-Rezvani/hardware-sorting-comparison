# Hardware Sorting Algorithms Comparison

Bachelor's degree final project. Implements and compares four sorting algorithms in SystemVerilog on FPGA:

- **Bitonic Sort**
- **Odd-Even Transposition Sort**
- **Insertion Sort**
- **Merge Sort**

## Comparison Criteria

| Metric | Description |
|---|---|
| Area | LUTs, FFs, BRAMs, DSPs |
| Frequency | Fmax after place & route |
| Throughput | Words sorted per second |
| Latency | Cycles from first input to first output |
| Scalability | How metrics change with array size |

## Data Format

- **Word width**: 8-bit signed
- **Array depth**: Parameterized

## Architecture

```
Input FIFO -> Sorter Core -> Output FIFO
```

Wrapped in an AXI interface and packaged as a Vivado IP. Integrated with a soft CPU and BRAM for benchmarking.

## Repository Structure

- `rtl/`: Synthesizable SystemVerilog source
- `tb/`: Testbenches
- `scripts/`: Vivado TCL scripts and shell runners
- `constraints/`: Timing constraints
- `vivado/`: Generated Vivado project files (gitignored, disposable)
- `sw/`: Software driver for the soft CPU
- `matlab/`: MATLAB scripts for graph generation
- `docs/`: Results data (CSV) and comparison reports

## Prerequisites

- Xilinx Vivado 2018.3 or newer (tested on Vivado 2019.2; WebPACK / Standard edition is sufficient).
- Vivado binaries available in PATH, or standard install paths.

## Setup & Simulation

Source files in `rtl/` and `tb/` are referenced remotely by Vivado rather than copied. Any edits made in `rtl/` are immediately picked up by Vivado without re-importing and vice-versa. The `vivado/` directory is disposable and can be deleted or rebuilt at any time.

### Method 1: Headless Simulation (CLI)

Run simulation directly from terminal from the repo root. You can pass an optional testbench name (defaults to `fifo_tb`):

- **Windows CMD**:
  ```cmd
  scripts\run_sim.bat
  scripts\run_sim.bat fifo_tb
  ```
  *(Double-clicking `run_sim.bat` in Windows Explorer also works; it will keep the window open after simulation completes.)*

- **Windows PowerShell**:
  ```powershell
  .\scripts\run_sim.ps1
  .\scripts\run_sim.ps1 fifo_tb
  ```

- **Linux / Bash**:
  ```bash
  ./scripts/run_sim.sh
  ./scripts/run_sim.sh fifo_tb
  ```

- **Direct Vivado Batch Mode**:
  ```bash
  vivado -mode batch -source scripts/sim.tcl -nolog -nojournal
  ```

### Method 2: Vivado GUI

1. Open Vivado.
2. In the Vivado Tcl Console, navigate to the repo root and recreate the project:
   ```tcl
   cd /path/to/Bachelor
   source scripts/create_sim_project.tcl
   ```
3. In the Flow Navigator, click **Run Simulation -> Run Behavioral Simulation**.
