`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env extends uvm_env;

  `uvm_component_utils(axi_env)

  axi_agent      agent;
  axi_scoreboard scoreboard;
  axi_coverage   coverage;

  function new(string name = "axi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Default to active unless a test overrides via config_db
    uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);

    agent      = axi_agent::type_id::create("agent", this);
    scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    coverage   = axi_coverage::type_id::create("coverage", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Analysis port fan-out: one monitor -> two independent listeners
    agent.monitor.ap.connect(scoreboard.imp);
    agent.monitor.ap.connect(coverage.analysis_export);
  endfunction

endclass

`endif
