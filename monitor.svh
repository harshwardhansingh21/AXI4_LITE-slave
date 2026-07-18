`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;
  uvm_analysis_port #(axi_transaction) ap;

  function new(string name = "axi_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface not set for monitor - check config_db path (uvm_test_top* wildcard)")
  endfunction

  virtual task run_phase(uvm_phase phase);
    wait (vif.aresetn == 1'b1);

    fork
      monitor_write();
      monitor_read();
    join
  endtask

  //---------------------------------------------------
  // Watch write channel: capture AW+W address/data,
  // then wait for B response, then broadcast full txn
  //---------------------------------------------------
  virtual task monitor_write();
    axi_transaction tr;
    forever begin
      @(posedge vif.clk);
      if (vif.awvalid && vif.awready) begin
        tr = axi_transaction::type_id::create("tr");
        tr.op     = WRITE;
        tr.awaddr = vif.awaddr;

        // wait for W handshake (may already have happened same cycle or later)
        if (!(vif.wvalid && vif.wready)) begin
          do @(posedge vif.clk); while (!(vif.wvalid && vif.wready));
        end
        tr.wdata = vif.wdata;
        tr.wstrb = vif.wstrb;

        // wait for B response
        do @(posedge vif.clk); while (!(vif.bvalid && vif.bready));
        tr.bresp = vif.bresp;

        ap.write(tr);
      end
    end
  endtask

  //---------------------------------------------------
  // Watch read channel: capture AR address,
  // then wait for R response, then broadcast full txn
  //---------------------------------------------------
  virtual task monitor_read();
    axi_transaction tr;
    forever begin
      @(posedge vif.clk);
      if (vif.arvalid && vif.arready) begin
        tr = axi_transaction::type_id::create("tr");
        tr.op     = READ;
        tr.araddr = vif.araddr;

        // wait for R response
        do @(posedge vif.clk); while (!(vif.rvalid && vif.rready));
        tr.rdata = vif.rdata;
        tr.rresp = vif.rresp;

        ap.write(tr);
      end
    end
  endtask

endclass

`endif
