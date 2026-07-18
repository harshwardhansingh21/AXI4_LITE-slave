`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi_if.sv"
`include "transaction.sv"
`include "sequence.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
`include "scoreboard.sv"
`include "coverage.sv"
`include "env.sv"
`include "test.sv"

module axi_tb_top;

  // ---------------------------------------------------
  // Clock generation
  // ---------------------------------------------------
  logic clk;
  initial clk = 1'b0;
  always #5 clk = ~clk; // 100 MHz

  // ---------------------------------------------------
  // Interface instantiation
  // ---------------------------------------------------
  axi_if vif (.clk(clk));

  // ---------------------------------------------------
  // Reset generation — active-low, held for first few cycles
  // ---------------------------------------------------
  initial begin
    vif.aresetn = 1'b0;
    repeat (5) @(posedge clk);
    vif.aresetn = 1'b1;
  end

  // ---------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------
axi4_lite_slave dut (
    .S_AXI_ACLK     (clk),
    .S_AXI_ARESETn  (vif.aresetn),

    .S_AXI_AWADDR   (vif.awaddr),
    .S_AXI_AWVALID  (vif.awvalid),
    .S_AXI_AWREADY  (vif.awready),

    .S_AXI_WDATA    (vif.wdata),
    .S_AXI_WSTRB    (vif.wstrb),
    .S_AXI_WVALID   (vif.wvalid),
    .S_AXI_WREADY   (vif.wready),

    .S_AXI_BRESP    (vif.bresp),
    .S_AXI_BVALID   (vif.bvalid),
    .S_AXI_BREADY   (vif.bready),

    .S_AXI_ARADDR   (vif.araddr),
    .S_AXI_ARVALID  (vif.arvalid),
    .S_AXI_ARREADY  (vif.arready),

    .S_AXI_RDATA    (vif.rdata),
    .S_AXI_RRESP    (vif.rresp),
    .S_AXI_RVALID   (vif.rvalid),
    .S_AXI_RREADY   (vif.rready)
);

  // ---------------------------------------------------
  // Push virtual interface into config_db before run_test()
  // ---------------------------------------------------
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "uvm_test_top*", "vif", vif);
  end

  // ---------------------------------------------------
  // Waveform dump (EPWave / QuestaSim)
  // ---------------------------------------------------
  initial begin
    $dumpfile("axi_uvm.vcd");
    $dumpvars(0, axi_tb_top);
  end

  // ---------------------------------------------------
  // Kick off UVM
  // ---------------------------------------------------
  initial begin
    run_test(); // test class selected via +UVM_TESTNAME=<test> plusarg
  end

endmodule

`endif
