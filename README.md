# AXI4-Lite Slave — RTL Design & Verification

A from-scratch implementation of an AXI4-Lite slave interface, built in Verilog/SystemVerilog with a class-based constrained-random verification environment.

## Overview

AXI4-Lite is a lightweight subset of the AMBA AXI4 protocol, widely used for register-style, low-throughput peripheral interfaces in SoC designs. This project implements a fully protocol-compliant AXI4-Lite slave and verifies it using a self-built object-oriented SystemVerilog testbench — no UVM, built ground-up to understand the fundamentals before abstracting them away.

## Features

- Independent write and read channel handling (AW, W, B, AR, R)
- Full handshake logic across all five channels (VALID/READY on each)
- FSM-based channel sequencing to guarantee protocol-compliant ordering
- Write address and write data channels accepted independently before response (per AXI4-Lite spec)
- Parameterizable address and data width

## Repository Structure

```
axi4-lite-slave/
├── rtl/
│   └── axi4_lite_slave.v        # DUT
├── tb/
│   ├── transaction.sv           # Stimulus packet class
│   ├── generator.sv             # Constrained-random stimulus generator
│   ├── driver.sv                # Drives transactions to DUT via interface
│   ├── monitor_in.sv            # Captures input-side activity
│   ├── monitor_out.sv           # Captures output-side activity
│   ├── scoreboard.sv            # Checks write/read data integrity
│   ├── environment.sv           # Connects all components
│   ├── axi4_lite_if.sv          # Interface definition
│   └── tb_top.sv                # Top-level testbench
├── waveforms/
│   └── *.png                    # Simulation waveform screenshots
└── README.md
```

## Verification Environment

The testbench follows a class-based, constrained-random verification (CRV) methodology with 7 components:

| Component | Responsibility |
|---|---|
| Transaction | Defines the stimulus packet (address, data, control signals) |
| Generator | Produces constrained-random transactions |
| Driver | Drives transactions onto the DUT interface |
| Monitor  |  observes input and output interface activity |
| Scoreboard | Compares expected vs. actual data to check correctness |
| Environment | Instantiates and connects all components |

This separation mirrors the structure UVM later formalizes — building it manually first was deliberate, to understand what UVM's automation actually replaces.

## Tools Used

- Simulator: EDA Playground (Aldec Riviera-PRO)
- Waveform viewer: GTKWave / EPWave
- Language: Verilog (RTL), SystemVerilog (testbench)

## Bugs Found

During simulation, the constrained-random environment surfaced a real **BVALID protocol violation** — a case that directed testing would likely have missed. This is the core value proposition of CRV over directed testing: it explores corners of the state space a human wouldn't think to write by hand.

## Roadmap

- [ ] Add SystemVerilog Assertions (SVA) for protocol-level checking (bind-based, non-intrusive)
- [ ] Add functional coverage (transaction types, address ranges, corner cases)
- [ ] Upgrade RTL to full AXI4 (burst transfers, narrow transfers, unaligned addressing)
- [ ] Migrate testbench to UVM (sequence-sequencer-driver architecture)

## Author

Harshwardhan Singh (Harshuu)
B.Tech ECE, BIT Mesra | RTL Design & Verification
[LinkedIn] · [GitHub]
