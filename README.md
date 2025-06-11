# FPGA XOR Neural Network – Arduino MKR Vidor 4000 (Verilog)

This project implements a simple feedforward neural network in Verilog to solve the classic XOR problem, running on the Arduino MKR Vidor 4000 FPGA board. It demonstrates how neural network inference can be mapped to hardware for educational and experimental purposes.

## Overview

- **Objective:** Hardware implementation of a 2-8-1 neural network for XOR logic.
- **Platform:** Arduino MKR Vidor 4000 FPGA.
- **Toolchain:** Intel Quartus Prime (Lite Edition) for synthesis and bitstream generation.
- **Languages:** Verilog (FPGA logic), C/C++ (optional Arduino/host interface).

## Directory Structure

```plaintext
arduino/     - Arduino source files (host interface, JTAG, etc.)
python/      - Python training script for generating weights
src/         - Verilog source files, Quartus project, constraints
scripts/     - Utility scripts (e.g., bitstream_generation.sh)
verilator/   - Verilator testbenches and simulation files
```

## Getting Started

### Prerequisites

- Intel Quartus Prime (Lite Edition)
- Arduino IDE (for uploading host code)
- Familiarity with FPGA development and the MKR Vidor 4000

### Build & Deployment

1. **Project Setup**
   - Open the Quartus project in `src/` or copy files as needed.
   - Assign FPGA pins using the provided constraint files (`.qsf`, `.sdc`).
   - Run synthesis and bitstream generation (see `scripts/bitstream_generation.sh`). 

2. **Programming the FPGA**
   - Upload the Arduino code from `arduino/` and program the FPGA with the generated bitstream.
   - Ensure all hardware connections are correct.

3. **Testing & Validation**
   - Use the Verilator testbenches in `verilator/` to simulate the neural network.
   - Provide inputs via switches, GPIO, or serial; observe outputs on LEDs or via serial/host.

## How It Works

- The neural network is hardcoded with pre-trained weights for XOR.
- Inputs are set via hardware or serial interface.
- Outputs are shown on LEDs or sent to the host system.

## Customization

- Change weights or network architecture in the Verilog source to experiment with other logic functions.
- Optimize performance by pipelining or modifying the computation flow.

## License

This project is open source and some files are based on []() project. See `LICENSE` for details.
