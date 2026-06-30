`timescale 1ns/1ps

module tb_top;

    logic clk;

    initial clk = 0;
    always #5 clk = ~clk;

    axi4_lite_if dut_if(.clk(clk));

    axi4_lite_slave dut(
        .S_AXI_ACLK     (dut_if.clk),
        .S_AXI_ARESETn  (dut_if.aresetn),
        .S_AXI_AWADDR   (dut_if.awaddr),
        .S_AXI_AWVALID  (dut_if.awvalid),
        .S_AXI_AWREADY  (dut_if.awready),
        .S_AXI_WDATA    (dut_if.wdata),
        .S_AXI_WSTRB    (dut_if.wstrb),
        .S_AXI_WVALID   (dut_if.wvalid),
        .S_AXI_WREADY   (dut_if.wready),
        .S_AXI_BRESP    (dut_if.bresp),
        .S_AXI_BVALID   (dut_if.bvalid),
        .S_AXI_BREADY   (dut_if.bready),
        .S_AXI_ARADDR   (dut_if.araddr),
        .S_AXI_ARVALID  (dut_if.arvalid),
        .S_AXI_ARREADY  (dut_if.arready),
        .S_AXI_RDATA    (dut_if.rdata),
        .S_AXI_RRESP    (dut_if.rresp),
        .S_AXI_RVALID   (dut_if.rvalid),
        .S_AXI_RREADY   (dut_if.rready)
    );

    environment env;

    initial begin
        env = new(dut_if, dut_if);
        env.build();

        $dumpfile("axi4_lite_tb.vcd");
        $dumpvars(0, tb_top);

        // Reset
        dut_if.aresetn = 1'b0;
        repeat(5) @(posedge clk);
        dut_if.aresetn = 1'b1;
        repeat(2) @(posedge clk);

        env.run_components();
        env.gen.run();
        #2000;

        env.wrap_up();
        $finish;
    end

endmodule
