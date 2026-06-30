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
