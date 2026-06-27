module axi4_lite_slave (
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETn,
    input  wire [31:0] S_AXI_AWADDR,
    input  wire        S_AXI_AWVALID,
    output wire        S_AXI_AWREADY,
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output wire        S_AXI_WREADY,
    output wire [1:0]  S_AXI_BRESP,
    output wire        S_AXI_BVALID,
    input  wire        S_AXI_BREADY,
    input  wire [31:0] S_AXI_ARADDR,
    input  wire        S_AXI_ARVALID,
    output wire        S_AXI_ARREADY,
    output wire [31:0] S_AXI_RDATA,
    output wire [1:0]  S_AXI_RRESP,
    output wire        S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);

    reg [31:0] ctrl_reg;
    reg [31:0] stat_reg;
    reg [31:0] din_reg;
    reg [31:0] dout_reg;

    reg        awready_reg;
    reg        wready_reg;
    reg        bvalid_reg;
    reg        arready_reg;
    reg        rvalid_reg;
    reg [31:0] rdata_reg;

    assign S_AXI_AWREADY = awready_reg;
    assign S_AXI_WREADY  = wready_reg;
    assign S_AXI_BVALID  = bvalid_reg;
    assign S_AXI_ARREADY = arready_reg;
    assign S_AXI_RVALID  = rvalid_reg;
    assign S_AXI_RDATA   = rdata_reg;
    assign S_AXI_BRESP   = 2'b00;
    assign S_AXI_RRESP   = 2'b00;

    reg [31:0] captured_wdata;
    reg [3:0]  captured_wstrb;
    reg [31:0] captured_awaddr;
    reg [31:0] captured_araddr;
    reg        aw_received;
    reg        w_received;
    reg        ar_received;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn) begin
        if (!S_AXI_ARESETn) begin
            awready_reg     <= 1'b0;
            wready_reg      <= 1'b0;
            captured_awaddr <= 32'h0;
            captured_wdata  <= 32'h0;
            captured_wstrb  <= 4'h0;
            aw_received     <= 1'b0;
            w_received      <= 1'b0;
        end
        else begin
            if (S_AXI_AWVALID && !aw_received && !bvalid_reg) begin
                awready_reg     <= 1'b1;
                captured_awaddr <= S_AXI_AWADDR;
                aw_received     <= 1'b1;
            end else begin
                awready_reg <= 1'b0;
            end

            if (S_AXI_WVALID && !w_received && !bvalid_reg) begin
                wready_reg     <= 1'b1;
                captured_wdata <= S_AXI_WDATA;
                captured_wstrb <= S_AXI_WSTRB;
                w_received     <= 1'b1;
            end else begin
                wready_reg <= 1'b0;
            end

            if (S_AXI_BVALID && S_AXI_BREADY) begin
                aw_received <= 1'b0;
                w_received  <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn) begin
        if (!S_AXI_ARESETn) begin
            bvalid_reg <= 1'b0;
            ctrl_reg   <= 32'h0;
            din_reg    <= 32'h0;
            dout_reg   <= 32'h0;
            stat_reg   <= 32'h12345678;
        end
        else begin
            if (w_received && aw_received && !bvalid_reg) begin
                case (captured_awaddr[3:2])
                    2'b00: begin
                        if (captured_wstrb[0]) ctrl_reg[7:0]   <= captured_wdata[7:0];
                        if (captured_wstrb[1]) ctrl_reg[15:8]  <= captured_wdata[15:8];
                        if (captured_wstrb[2]) ctrl_reg[23:16] <= captured_wdata[23:16];
                        if (captured_wstrb[3]) ctrl_reg[31:24] <= captured_wdata[31:24];
                    end
                    2'b01: ;
                    2'b10: begin
                        if (captured_wstrb[0]) din_reg[7:0]   <= captured_wdata[7:0];
                        if (captured_wstrb[1]) din_reg[15:8]  <= captured_wdata[15:8];
                        if (captured_wstrb[2]) din_reg[23:16] <= captured_wdata[23:16];
                        if (captured_wstrb[3]) din_reg[31:24] <= captured_wdata[31:24];
                    end
                    2'b11: begin
                        if (captured_wstrb[0]) dout_reg[7:0]   <= captured_wdata[7:0];
                        if (captured_wstrb[1]) dout_reg[15:8]  <= captured_wdata[15:8];
                        if (captured_wstrb[2]) dout_reg[23:16] <= captured_wdata[23:16];
                        if (captured_wstrb[3]) dout_reg[31:24] <= captured_wdata[31:24];
                    end
                endcase
                bvalid_reg <= 1'b1;
            end
            else if (bvalid_reg && S_AXI_BREADY) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn) begin
        if (!S_AXI_ARESETn) begin
            captured_araddr <= 32'h0;
            ar_received     <= 1'b0;
            arready_reg     <= 1'b0;
        end
        else begin
            if (S_AXI_ARVALID && !ar_received) begin
                arready_reg     <= 1'b1;
                captured_araddr <= S_AXI_ARADDR;
                ar_received     <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end

            if (S_AXI_RVALID && S_AXI_RREADY) begin
                ar_received <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn) begin
        if (!S_AXI_ARESETn) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 32'h0;
        end
        else begin
            if (ar_received && !rvalid_reg) begin
                case (captured_araddr[3:2])
                    2'b00: rdata_reg <= ctrl_reg;
                    2'b01: rdata_reg <= stat_reg;
                    2'b10: rdata_reg <= din_reg;
                    2'b11: rdata_reg <= dout_reg;
                endcase
                rvalid_reg <= 1'b1;
            end
            else if (rvalid_reg && S_AXI_RREADY) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

endmodule
