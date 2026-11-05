// AXI4-Lite Slave Register File IP
// slug: mmio-axilite-regfile-ip
// Harness original. References: ZipCPU easyaxil apply_wstrb pattern and $clog2
// decoder concept (no code copied). MicroBlaze V IP standard wrapper.
//
// Registers (base relative):
//   0x00  CTRL     RW  general-purpose control
//   0x04  STATUS   RW  bit[0]=data_pending (HW set on DATA write, SW clear)
//   0x08  DATA     RW  data register; write side-effect: sets STATUS[0]
//   0x0C  IRQ_MASK RW  bit[0]=data_irq_en; ip2intc_irpt when STATUS[0] & IRQ_MASK[0]
//
// Verilog-2001. iverilog/verilator/yosys compatible.

`default_nettype none
`timescale 1ns/1ps

module axilite_regfile #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // System
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,
    // Write address channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
    input  wire [2:0]                          s_axi_awprot,   // unused, AXI required
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,
    // Write data channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,
    // Write response channel
    output wire [1:0]                          s_axi_bresp,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,
    // Read address channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
    input  wire [2:0]                          s_axi_arprot,   // unused, AXI required
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,
    // Read data channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output wire [1:0]                          s_axi_rresp,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready,
    // Interrupt output (MicroBlaze V / INTC channel 13)
    output wire                                ip2intc_irpt
);

    // ----------------------------------------------------------------
    // Parameters
    // ----------------------------------------------------------------
    localparam integer NREGS = 4;
    localparam integer ABITS = $clog2(NREGS);  // = 2

    localparam [ABITS-1:0] REG_CTRL    = 2'd0;
    localparam [ABITS-1:0] REG_STATUS  = 2'd1;
    localparam [ABITS-1:0] REG_DATA    = 2'd2;
    localparam [ABITS-1:0] REG_IRQMASK = 2'd3;

    // ----------------------------------------------------------------
    // Register file
    // ----------------------------------------------------------------
    reg [C_S_AXI_DATA_WIDTH-1:0] regfile [0:NREGS-1];

    // ----------------------------------------------------------------
    // apply_wstrb: byte-enable write merge
    // Source: ZipCPU easyaxil pattern (concept; not copied)
    // ----------------------------------------------------------------
    function [31:0] apply_wstrb;
        input [31:0] orig;
        input [31:0] wdata;
        input [3:0]  wstrb;
        begin
            apply_wstrb[7:0]   = wstrb[0] ? wdata[7:0]   : orig[7:0];
            apply_wstrb[15:8]  = wstrb[1] ? wdata[15:8]  : orig[15:8];
            apply_wstrb[23:16] = wstrb[2] ? wdata[23:16] : orig[23:16];
            apply_wstrb[31:24] = wstrb[3] ? wdata[31:24] : orig[31:24];
        end
    endfunction

    // ================================================================
    // Write path
    // ================================================================

    // Write address latch
    reg                            aw_lat;
    reg [C_S_AXI_ADDR_WIDTH-1:0]  aw_addr;

    // Write data latch
    reg                                       w_lat;
    reg [C_S_AXI_DATA_WIDTH-1:0]             w_data;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0]         w_strb;

    // Write response state
    reg b_act;

    // Combinational ready: accept new item when not already holding one
    assign s_axi_awready = !aw_lat;
    assign s_axi_wready  = !w_lat;

    // Commit: both address and data latched, no pending response
    wire do_commit = aw_lat && w_lat && !b_act;

    // $clog2 address decoder: addr[ABITS+1:2] = addr[3:2] for NREGS=4
    wire [ABITS-1:0] wr_sel = aw_addr[ABITS+1:2];

    // Write address latch
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            aw_lat  <= 1'b0;
            aw_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_lat  <= 1'b1;
                aw_addr <= s_axi_awaddr;
            end else if (do_commit) begin
                aw_lat  <= 1'b0;
            end
        end
    end

    // Write data latch
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            w_lat  <= 1'b0;
            w_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
            w_strb <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin
                w_lat  <= 1'b1;
                w_data <= s_axi_wdata;
                w_strb <= s_axi_wstrb;
            end else if (do_commit) begin
                w_lat  <= 1'b0;
            end
        end
    end

    // Write response
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            b_act <= 1'b0;
        end else begin
            if (do_commit)
                b_act <= 1'b1;
            else if (s_axi_bvalid && s_axi_bready)
                b_act <= 1'b0;
        end
    end

    assign s_axi_bvalid = b_act;
    assign s_axi_bresp  = 2'b00;  // OKAY

    // Register file write with DATA side-effect
    integer i;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            for (i = 0; i < NREGS; i = i + 1)
                regfile[i] <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else if (do_commit) begin
            if (wr_sel == REG_DATA) begin
                // DATA write: update DATA and set STATUS[0] (data_pending)
                regfile[REG_DATA]      <= apply_wstrb(regfile[REG_DATA], w_data, w_strb);
                regfile[REG_STATUS][0] <= 1'b1;
            end else begin
                regfile[wr_sel] <= apply_wstrb(regfile[wr_sel], w_data, w_strb);
            end
        end
    end

    // ================================================================
    // Read path
    // ================================================================

    reg                           ar_lat;
    reg [C_S_AXI_ADDR_WIDTH-1:0] ar_addr;
    reg                           r_act;

    wire [ABITS-1:0] rd_sel = ar_addr[ABITS+1:2];

    assign s_axi_arready = !ar_lat;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            ar_lat  <= 1'b0;
            ar_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            r_act   <= 1'b0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                ar_lat  <= 1'b1;
                ar_addr <= s_axi_araddr;
                r_act   <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                ar_lat  <= 1'b0;
                r_act   <= 1'b0;
            end
        end
    end

    assign s_axi_rvalid = r_act;
    assign s_axi_rresp  = 2'b00;
    assign s_axi_rdata  = regfile[rd_sel];

    // ================================================================
    // IRQ output — registered for glitch-free output
    // ip2intc_irpt = STATUS[0] AND IRQ_MASK[0]
    // ================================================================
    reg irq_r;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            irq_r <= 1'b0;
        else
            irq_r <= regfile[REG_STATUS][0] & regfile[REG_IRQMASK][0];
    end
    assign ip2intc_irpt = irq_r;

    // Suppress unused input warnings (prot bits are AXI-required, not used)
    // verilator lint_off UNUSED
    wire _unused = &{s_axi_awprot, s_axi_arprot};
    // verilator lint_on UNUSED

endmodule
`default_nettype wire
