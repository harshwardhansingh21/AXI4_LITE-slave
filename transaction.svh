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
