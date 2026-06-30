class sequencer;

    mailbox #(transaction) tx_to_drv;

    function new(mailbox #(transaction) tx_to_drv);
        this.tx_to_drv = tx_to_drv;
    endfunction

    task send(transaction tx);
        tx_to_drv.put(tx);
    endtask

endclass
