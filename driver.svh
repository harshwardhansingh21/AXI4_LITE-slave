`ifndef  UVM_DRIVER_SV
`define  UVM_DRIVER_SV

class axi_driver extends uvm_driver#(axi_transaction);

    virtual axi_if vif;

    `uvm_component_utils(axi_driver)

    function new(string name="axi_driver",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!(uvm_config_db#(virtual axi_if)::get(this,"","vif",vif)))
        `uvm_fatal(get_type_name(),"Virtual interface not set for driver - check config_db path (uvm_test_top* wildcard)")
    endfunction

      virtual task run_phase(uvm_phase phase);
    // Idle all signals until reset deasserts
    drive_reset_values();
    wait (vif.aresetn == 1'b1);

    forever begin
      seq_item_port.get_next_item(req);
      if (req.op == WRITE)
        do_write(req);
      else
        do_read(req);
      seq_item_port.item_done();
    end
  endtask

  //---------------------------------------------------
  // Reset defaults
  //---------------------------------------------------
  virtual task drive_reset_values();
    vif.awvalid <= 0;
    vif.wvalid  <= 0;
    vif.bready  <= 0;
    vif.arvalid <= 0;
    vif.rready  <= 0;
  endtask

  //---------------------------------------------------
  // Write transaction: AW + W channels, then B channel
  //---------------------------------------------------
  virtual task do_write(axi_transaction tr);
    @(posedge vif.clk);
    vif.awaddr  <= tr.awaddr;
    vif.awvalid <= 1'b1;
    vif.wdata   <= tr.wdata;
    vif.wstrb   <= tr.wstrb;
    vif.wvalid  <= 1'b1;

    // Wait for both address and data to be accepted (AXI4-Lite allows independent handshakes)
    fork
      begin : aw_hs
        do @(posedge vif.clk); while (!vif.awready);
        vif.awvalid <= 1'b0;
      end
      begin : w_hs
        do @(posedge vif.clk); while (!vif.wready);
        vif.wvalid <= 1'b0;
      end
    join

    // Apply BREADY delay knob before asserting
    repeat (tr.bready_delay) @(posedge vif.clk);
    vif.bready <= 1'b1;
    do @(posedge vif.clk); while (!vif.bvalid);
    tr.bresp <= vif.bresp;
    vif.bready <= 1'b0;
  endtask

  //---------------------------------------------------
  // Read transaction: AR channel, then R channel
  //---------------------------------------------------
  virtual task do_read(axi_transaction tr);
    // Apply ARVALID delay knob before asserting
    repeat (tr.arvalid_delay) @(posedge vif.clk);
    @(posedge vif.clk);
    vif.araddr  <= tr.araddr;
    vif.arvalid <= 1'b1;

    do @(posedge vif.clk); while (!vif.arready);
    vif.arvalid <= 1'b0;

    vif.rready <= 1'b1;
    do @(posedge vif.clk); while (!vif.rvalid);
    tr.rdata <= vif.rdata;
    tr.rresp <= vif.rresp;
    vif.rready <= 1'b0;
  endtask
endclass
