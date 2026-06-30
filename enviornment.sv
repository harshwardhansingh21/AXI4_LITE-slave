
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
