`ifndef AXI_IF_SV
`define AXI_IF_SV

interface axi_if (input logic clk);

  logic aresetn;

  // Write address channel
  logic [31:0] awaddr;
  logic        awvalid;
  logic        awready;

  // Write data channel
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wvalid;
  logic        wready;

  // Write response channel
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;

  // Read address channel
  logic [31:0] araddr;
  logic        arvalid;
  logic        arready;

  // Read data channel
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  logic        rready;

  modport DRIVER (
    input  clk, aresetn,
    output awaddr, awvalid,
    input  awready,
    output wdata, wstrb, wvalid,
    input  wready,
    input  bresp, bvalid,
    output bready,
    output araddr, arvalid,
    input  arready,
    input  rdata, rresp, rvalid,
    output rready
  );

  modport MONITOR (
    input clk, aresetn,
    input awaddr, awvalid, awready,
    input wdata, wstrb, wvalid, wready,
    input bresp, bvalid, bready,
    input araddr, arvalid, arready,
    input rdata, rresp, rvalid, rready
  );

endinterface

`endif
