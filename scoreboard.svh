`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_transaction, axi_scoreboard) imp;

  // Reference memory model — keyed by decoded register (addr[3:2] << 2)
  bit [31:0] mem_model [bit [31:0]];

  // Register map, matching the DUT's addr[3:2] decode
  localparam bit [1:0] REG_CTRL = 2'b00;
  localparam bit [1:0] REG_STAT = 2'b01; // read-only
  localparam bit [1:0] REG_DIN  = 2'b10;
  localparam bit [1:0] REG_DOUT = 2'b11;

  int unsigned pass_count = 0;
  int unsigned fail_count = 0;

  function new(string name = "axi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  virtual function void write(axi_transaction tr);
    if (tr.op == WRITE)
      check_write(tr);
    else
      check_read(tr);
  endfunction

  //---------------------------------------------------
  // WRITE check: DUT always OKAY; stat_reg writes are
  // silently dropped by the DUT (read-only)
  //---------------------------------------------------
  virtual function void check_write(axi_transaction tr);
    bit [31:0] merged_data;
    bit [31:0] reg_key;
    bit [1:0]  decode;

    decode  = tr.awaddr[3:2];
    reg_key = {decode, 2'b00};

    if (decode != REG_STAT) begin
      merged_data = mem_model.exists(reg_key) ? mem_model[reg_key] : 32'h0;
      for (int i = 0; i < 4; i++) begin
        if (tr.wstrb[i])
          merged_data[i*8 +: 8] = tr.wdata[i*8 +: 8];
      end
      mem_model[reg_key] = merged_data;
    end
    // else: stat_reg is read-only, DUT drops the write, model stays untouched

    if (tr.bresp !== RESP_OKAY) begin
      fail_count++;
      `uvm_error(get_type_name(),
        $sformatf("WRITE BRESP mismatch @addr=0x%0h: expected=OKAY actual=%0d",
                   tr.awaddr, tr.bresp))
    end else begin
      pass_count++;
      `uvm_info(get_type_name(),
        $sformatf("WRITE PASS @addr=0x%0h (reg_key=0x%0h) wdata=0x%0h wstrb=%0b%s",
                   tr.awaddr, reg_key, tr.wdata, tr.wstrb,
                   (decode == REG_STAT) ? " [STAT - write dropped by DUT]" : ""),
        UVM_HIGH)
    end
  endfunction

  //---------------------------------------------------
  // READ check: DUT always OKAY; data compared against
  // aliased reference model entry
  //---------------------------------------------------
  virtual function void check_read(axi_transaction tr);
    bit [31:0] expected_rdata;
    bit [31:0] reg_key;
    bit [1:0]  decode;

    decode  = tr.araddr[3:2];
    reg_key = {decode, 2'b00};

    // stat_reg resets to 32'h12345678 in the DUT and is never written,
    // so if the model has no entry for it, use that reset value instead of 0
    if (decode == REG_STAT && !mem_model.exists(reg_key))
      expected_rdata = 32'h12345678;
    else
      expected_rdata = mem_model.exists(reg_key) ? mem_model[reg_key] : 32'h0;

    if (tr.rresp !== RESP_OKAY) begin
      fail_count++;
      `uvm_error(get_type_name(),
        $sformatf("READ RRESP mismatch @addr=0x%0h: expected=OKAY actual=%0d",
                   tr.araddr, tr.rresp))
    end else if (tr.rdata !== expected_rdata) begin
      fail_count++;
      `uvm_error(get_type_name(),
        $sformatf("READ DATA mismatch @addr=0x%0h (reg_key=0x%0h): expected=0x%0h actual=0x%0h",
                   tr.araddr, reg_key, expected_rdata, tr.rdata))
    end else begin
      pass_count++;
      `uvm_info(get_type_name(),
        $sformatf("READ PASS @addr=0x%0h (reg_key=0x%0h) rdata=0x%0h",
                   tr.araddr, reg_key, tr.rdata), UVM_HIGH)
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
      $sformatf("SCOREBOARD SUMMARY: %0d PASS / %0d FAIL", pass_count, fail_count),
      UVM_LOW)
    if (fail_count == 0)
      `uvm_info(get_type_name(), "*** ALL CHECKS PASSED ***", UVM_LOW)
    else
      `uvm_error(get_type_name(), $sformatf("*** %0d CHECK(S) FAILED ***", fail_count))
  endfunction

endclass

`endif
