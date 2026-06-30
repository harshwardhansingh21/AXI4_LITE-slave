
interface axi4_lite_if (input logic clk);

    logic        aresetn;

    logic [31:0] awaddr;
    logic        awvalid;
    logic        awready;

    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;

    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;

    logic [31:0] araddr;
    logic        arvalid;
    logic        arready;

    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output aresetn;
        output awaddr;
        output awvalid;
        input  awready;
        output wdata;
        output wstrb;
        output wvalid;
        input  wready;
        input  bresp;
        input  bvalid;
        output bready;
        output araddr;
        output arvalid;
        input  arready;
        input  rdata;
        input  rresp;
        input  rvalid;
        output rready;
    endclocking

    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input aresetn;
        input awaddr;
        input awvalid;
        input awready;
        input wdata;
        input wstrb;
        input wvalid;
        input wready;
        input bresp;
        input bvalid;
        input bready;
        input araddr;
        input arvalid;
        input arready;
        input rdata;
        input rresp;
        input rvalid;
        input rready;
    endclocking

    modport DRIVER  (clocking driver_cb,  input clk);
    modport MONITOR (clocking monitor_cb, input clk);

endinterface
