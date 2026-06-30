
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
