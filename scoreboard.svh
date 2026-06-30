
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
