class transaction;

    typedef enum { WRITE, READ } txn_type_e;

    rand txn_type_e txn_type;
    rand bit [31:0] waddr;
    rand bit [31:0] wdata;
    rand bit [3:0]  wstrb;
    rand int        aw_delay;
    rand int        w_delay;
    rand int        bready_delay;
    rand int        rready_delay;

    bit [31:0] rdata;
    bit [1:0]  response;

    constraint addr_aligned {
        waddr[1:0] == 2'b00;
    }

    constraint addr_offset {
        waddr[31:4] == 28'h0;
    }

    constraint strobe_valid {
        (txn_type == WRITE) -> (wstrb != 4'b0);
    }

    constraint reasonable_delays {
        aw_delay     inside { [0:20] };
        w_delay      inside { [0:20] };
        bready_delay inside { [0:20] };
        rready_delay inside { [0:20] };
    }

    task print();
        $display("TXN: type=%s addr=%0h data=%0h strobe=%b resp=%b",
                  txn_type.name(), waddr, wdata, wstrb, response);
    endtask

endclass


class sequencer;

    mailbox #(transaction) tx_to_drv;

    function new(mailbox #(transaction) tx_to_drv);
        this.tx_to_drv = tx_to_drv;
    endfunction

    task send(transaction tx);
        tx_to_drv.put(tx);
    endtask

endclass


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


class driver;

    mailbox #(transaction) tx_to_drv;
    virtual axi4_lite_if.DRIVER vif;

    function new(mailbox #(transaction) tx_to_drv,
                 virtual axi4_lite_if.DRIVER vif);
        this.tx_to_drv = tx_to_drv;
        this.vif       = vif;
    endfunction

    task run();
        transaction tx;
        initialize_signals();
        forever begin
            tx_to_drv.get(tx);
            if (tx.txn_type == transaction::WRITE)
                do_write(tx);
            else
                do_read(tx);
        end
    endtask

    task initialize_signals();
        @(vif.driver_cb);
        vif.driver_cb.awvalid <= 1'b0;
        vif.driver_cb.awaddr  <= 32'h0;
        vif.driver_cb.wvalid  <= 1'b0;
        vif.driver_cb.wdata   <= 32'h0;
        vif.driver_cb.wstrb   <= 4'h0;
        vif.driver_cb.bready  <= 1'b0;
        vif.driver_cb.arvalid <= 1'b0;
        vif.driver_cb.araddr  <= 32'h0;
        vif.driver_cb.rready  <= 1'b0;
    endtask

    task do_write(transaction tx);
        fork
            begin
                repeat(tx.aw_delay) @(vif.driver_cb);
                vif.driver_cb.awvalid <= 1'b1;
                vif.driver_cb.awaddr  <= tx.waddr;
                @(vif.driver_cb iff vif.driver_cb.awready == 1'b1);
                vif.driver_cb.awvalid <= 1'b0;
                vif.driver_cb.awaddr  <= 32'h0;
            end
            begin
                repeat(tx.w_delay) @(vif.driver_cb);
                vif.driver_cb.wvalid <= 1'b1;
                vif.driver_cb.wdata  <= tx.wdata;
                vif.driver_cb.wstrb  <= tx.wstrb;
                @(vif.driver_cb iff vif.driver_cb.wready == 1'b1);
                vif.driver_cb.wvalid <= 1'b0;
                vif.driver_cb.wdata  <= 32'h0;
                vif.driver_cb.wstrb  <= 4'h0;
            end
        join

        repeat(tx.bready_delay) @(vif.driver_cb);
        vif.driver_cb.bready <= 1'b1;
        @(vif.driver_cb iff vif.driver_cb.bvalid == 1'b1);
        tx.response = vif.driver_cb.bresp;
        vif.driver_cb.bready <= 1'b0;
    endtask

    task do_read(transaction tx);
        repeat(tx.aw_delay) @(vif.driver_cb);
        vif.driver_cb.arvalid <= 1'b1;
        vif.driver_cb.araddr  <= tx.waddr;
        @(vif.driver_cb iff vif.driver_cb.arready == 1'b1);
        vif.driver_cb.arvalid <= 1'b0;
        vif.driver_cb.araddr  <= 32'h0;

        repeat(tx.rready_delay) @(vif.driver_cb);
        vif.driver_cb.rready <= 1'b1;
        @(vif.driver_cb iff vif.driver_cb.rvalid == 1'b1);
        tx.rdata    = vif.driver_cb.rdata;
        tx.response = vif.driver_cb.rresp;
        vif.driver_cb.rready <= 1'b0;
    endtask

endclass


class monitor;

    virtual axi4_lite_if.MONITOR vif;
    mailbox #(transaction) mon_to_scb;

    function new(virtual axi4_lite_if.MONITOR vif,
                 mailbox #(transaction) mon_to_scb);
        this.vif        = vif;
        this.mon_to_scb = mon_to_scb;
    endfunction

    task run();
        fork
            monitor_write();
            monitor_read();
        join_none
    endtask

    task monitor_write();
    forever begin
        transaction tx = new();

        @(vif.monitor_cb iff (vif.monitor_cb.awvalid &&
                              vif.monitor_cb.awready));
        tx.txn_type = transaction::WRITE;
        tx.waddr    = vif.monitor_cb.awaddr;

        @(vif.monitor_cb iff (vif.monitor_cb.wvalid &&
                              vif.monitor_cb.wready));
        tx.wdata = vif.monitor_cb.wdata;
        tx.wstrb = vif.monitor_cb.wstrb;

        mon_to_scb.put(tx);  

        @(vif.monitor_cb iff (vif.monitor_cb.bvalid &&
                              vif.monitor_cb.bready));
        tx.response = vif.monitor_cb.bresp;
    end
endtask

    task monitor_read();
        forever begin
            transaction tx = new();

            @(vif.monitor_cb iff (vif.monitor_cb.arvalid &&
                                  vif.monitor_cb.arready));
            tx.txn_type = transaction::READ;
            tx.waddr    = vif.monitor_cb.araddr;

            @(vif.monitor_cb iff (vif.monitor_cb.rvalid &&
                                  vif.monitor_cb.rready));
            tx.rdata    = vif.monitor_cb.rdata;
            tx.response = vif.monitor_cb.rresp;

            mon_to_scb.put(tx);
        end
    endtask

endclass


class scoreboard;

    mailbox #(transaction) mon_to_scb;

    bit [31:0] ctrl_reg = 32'h00000000;
    bit [31:0] stat_reg = 32'h12345678;
    bit [31:0] din_reg  = 32'h00000000;
    bit [31:0] dout_reg = 32'h00000000;

    int pass_count = 0;
    int fail_count = 0;

    function new(mailbox #(transaction) mon_to_scb);
        this.mon_to_scb = mon_to_scb;
    endfunction

    task run();
        transaction tx;
        forever begin
            mon_to_scb.get(tx);
            if (tx.txn_type == transaction::WRITE)
                check_write(tx);
            else
                check_read(tx);
        end
    endtask

    task check_write(transaction tx);
        if (tx.response != 2'b00) begin
            $display("FAIL — write bad response addr=%0h", tx.waddr);
            fail_count++;
            return;
        end

        case(tx.waddr[3:2])
            2'b00: begin
                if (tx.wstrb[0]) ctrl_reg[7:0]   = tx.wdata[7:0];
                if (tx.wstrb[1]) ctrl_reg[15:8]  = tx.wdata[15:8];
                if (tx.wstrb[2]) ctrl_reg[23:16] = tx.wdata[23:16];
                if (tx.wstrb[3]) ctrl_reg[31:24] = tx.wdata[31:24];
            end
            2'b01: ;
            2'b10: begin
                if (tx.wstrb[0]) din_reg[7:0]   = tx.wdata[7:0];
                if (tx.wstrb[1]) din_reg[15:8]  = tx.wdata[15:8];
                if (tx.wstrb[2]) din_reg[23:16] = tx.wdata[23:16];
                if (tx.wstrb[3]) din_reg[31:24] = tx.wdata[31:24];
            end
            2'b11: begin
                if (tx.wstrb[0]) dout_reg[7:0]   = tx.wdata[7:0];
                if (tx.wstrb[1]) dout_reg[15:8]  = tx.wdata[15:8];
                if (tx.wstrb[2]) dout_reg[23:16] = tx.wdata[23:16];
                if (tx.wstrb[3]) dout_reg[31:24] = tx.wdata[31:24];
            end
        endcase

        $display("PASS — write addr=%0h data=%0h strobe=%b",
                  tx.waddr, tx.wdata, tx.wstrb);
        pass_count++;
    endtask

    task check_read(transaction tx);
        bit [31:0] expected;

        case(tx.waddr[3:2])
            2'b00: expected = ctrl_reg;
            2'b01: expected = stat_reg;
            2'b10: expected = din_reg;
            2'b11: expected = dout_reg;
        endcase

        if (tx.response != 2'b00) begin
            $display("FAIL — read bad response addr=%0h", tx.waddr);
            fail_count++;
            return;
        end

        if (tx.rdata !== expected) begin
            $display("FAIL — read addr=%0h got=%0h expected=%0h",
                      tx.waddr, tx.rdata, expected);
            fail_count++;
        end else begin
            $display("PASS — read addr=%0h data=%0h", tx.waddr, tx.rdata);
            pass_count++;
        end
    endtask

    task report();
        $display("─────────────────────────────");
        $display("TOTAL PASS: %0d", pass_count);
        $display("TOTAL FAIL: %0d", fail_count);
        $display("─────────────────────────────");
    endtask

endclass


class environment;

    sequencer  seqr;
    driver     drv;
    monitor    mon;
    scoreboard scb;

    mailbox #(transaction) seq_to_drv;
    mailbox #(transaction) mon_to_scb;

    virtual axi4_lite_if.DRIVER  drv_vif;
    virtual axi4_lite_if.MONITOR mon_vif;

    function new(virtual axi4_lite_if.DRIVER  drv_vif,
                 virtual axi4_lite_if.MONITOR mon_vif);
        this.drv_vif = drv_vif;
        this.mon_vif = mon_vif;
    endfunction

    function void build();
        seq_to_drv = new();
        mon_to_scb = new();

        seqr = new(seq_to_drv);
        drv  = new(seq_to_drv, drv_vif);
        mon  = new(mon_vif, mon_to_scb);
        scb  = new(mon_to_scb);
    endfunction

    task run();
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none
    endtask

    task wrap_up();
        scb.report();
    endtask

endclass


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
        env.run();

        $dumpfile("axi4_lite_tb.vcd");  
        $dumpvars(0, tb_top);

        dut_if.aresetn = 1'b0;
        repeat(5) @(posedge clk);
        dut_if.aresetn = 1'b1;
        repeat(2) @(posedge clk);

        begin
            transaction tx;

            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000000;
            tx.wdata        = 32'hDEADBEEF;
            tx.wstrb        = 4'b1111;
            tx.aw_delay     = 0;
            tx.w_delay      = 0;
            tx.bready_delay = 0;
            env.seqr.send(tx);

            tx = new();
            tx.txn_type     = transaction::READ;
            tx.waddr        = 32'h00000000;
            tx.aw_delay     = 0;
            tx.rready_delay = 0;
            env.seqr.send(tx);

            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000008;
            tx.wdata        = 32'hCAFEBABE;
            tx.wstrb        = 4'b1111;
            tx.aw_delay     = 0;
            tx.w_delay      = 0;
            tx.bready_delay = 0;
            env.seqr.send(tx);

            tx = new();
            tx.txn_type     = transaction::READ;
            tx.waddr        = 32'h00000008;
            tx.aw_delay     = 0;
            tx.rready_delay = 0;
            env.seqr.send(tx);
        end

        begin
            transaction tx;

            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000004;
            tx.wdata        = 32'hFFFFFFFF;
            tx.wstrb        = 4'b1111;
            tx.aw_delay     = 0;
            tx.w_delay      = 0;
            tx.bready_delay = 0;
            env.seqr.send(tx);

            tx = new();
            tx.txn_type     = transaction::READ;
            tx.waddr        = 32'h00000004;
            tx.aw_delay     = 0;
            tx.rready_delay = 0;
            env.seqr.send(tx);
        end

        begin
            transaction tx;
            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000000;
            tx.wdata        = 32'h11223344;
            tx.wstrb        = 4'b1111;
            tx.aw_delay     = 10;
            tx.w_delay      = 0;
            tx.bready_delay = 0;
            env.seqr.send(tx);
        end

        begin
            transaction tx;
            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000000;
            tx.wdata        = 32'hAABBCCDD;
            tx.wstrb        = 4'b1111;
            tx.aw_delay     = 0;
            tx.w_delay      = 0;
            tx.bready_delay = 20;
            env.seqr.send(tx);
        end

        begin
            transaction tx;

            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000000;
            tx.wdata        = 32'hFFFFFFFF;
            tx.wstrb        = 4'b1111;
            tx.aw_delay     = 0;
            tx.w_delay      = 0;
            tx.bready_delay = 0;
            env.seqr.send(tx);

            tx = new();
            tx.txn_type     = transaction::WRITE;
            tx.waddr        = 32'h00000000;
            tx.wdata        = 32'h00000000;
            tx.wstrb        = 4'b0101;
            tx.aw_delay     = 0;
            tx.w_delay      = 0;
            tx.bready_delay = 0;
            env.seqr.send(tx);

            tx = new();
            tx.txn_type     = transaction::READ;
            tx.waddr        = 32'h00000000;
            tx.aw_delay     = 0;
            tx.rready_delay = 0;
            env.seqr.send(tx);
        end

        begin
            transaction tx;
            repeat(20) begin
                tx = new();
                tx.randomize();
                env.seqr.send(tx);
            end
        end

        #2000;
        env.wrap_up();
        $finish;

    end

endmodule
