# AXI4-Lite Slave Verification Environment

## Overview
Class-based constrained random verification environment for an 
AXI4-Lite slave with four memory-mapped registers.

## Architecture
transaction → sequencer → driver → DUT
                                    ↓
scoreboard ← monitor ←─────────────┘

## Components
- Transaction: constrained random stimulus with delay knobs
- Driver: parallel AW/W channel fork-join with configurable delays
- Monitor: independent write and read observation threads
- Scoreboard: strobe-aware register model with pass/fail checking

## Corner Cases Covered
- W before AW ordering
- AW before W ordering  
- Slow BREADY (20 cycle delay)
- Partial write strobe (byte lane selection)
- Read-only register protection
- Back-to-back transactions
- 20 constrained random transactions

## Tools
- Simulator: Aldec Riviera-PRO / QuestaSim
- Language: SystemVerilog
- Platform: EDA Playground

## Results
All directed tests passing. Zero protocol violations observed.
