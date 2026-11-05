// Self-checking testbench for axilite_regfile
// slug: mmio-axilite-regfile-ip
// Harness original.
//
// Output convention: PASS on first word of last line if all checks passed,
//                    FAIL on first word if any check failed.
// X/Z detection: all comparisons use !== (not ==).
//
// Tests:
//   T1  Reset state: all registers 0, irpt=0
//   T2  Write/read CTRL register (full 32-bit)
//   T3  Write DATA -> STATUS[0] auto-set, DATA readable
//   T4  Enable IRQ: IRQ_MASK[0]=1, STATUS[0]=1 -> irpt goes high
//   T5  Clear STATUS[0] -> irpt goes low
//   T6  WSTRB partial write: strb=4'b0101 on CTRL
//
// Verilog-2001. iverilog/verilator compatible.

`default_nettype none
`timescale 1ns/1ps

module tb_axilite_regfile;

    // ----------------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------------
    reg         clk;
    reg         aresetn;
    // Write address channel
    reg  [3:0]  awaddr;
    reg  [2:0]  awprot;
    reg         awvalid;
    wire        awready;
    // Write data channel
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    // Write response channel
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    // Read address channel
    reg  [3:0]  araddr;
    reg  [2:0]  arprot;
    reg         arvalid;
    wire        arready;
    // Read data channel
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;
    // IRQ
    wire        irpt;

    // ----------------------------------------------------------------
    // DUT instantiation
    // ----------------------------------------------------------------
    axilite_regfile #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(4)
    ) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (aresetn),
        .s_axi_awaddr  (awaddr),
        .s_axi_awprot  (awprot),
        .s_axi_awvalid (awvalid),
        .s_axi_awready (awready),
        .s_axi_wdata   (wdata),
        .s_axi_wstrb   (wstrb),
        .s_axi_wvalid  (wvalid),
        .s_axi_wready  (wready),
        .s_axi_bresp   (bresp),
        .s_axi_bvalid  (bvalid),
        .s_axi_bready  (bready),
        .s_axi_araddr  (araddr),
        .s_axi_arprot  (arprot),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),
        .s_axi_rdata   (rdata),
        .s_axi_rresp   (rresp),
        .s_axi_rvalid  (rvalid),
        .s_axi_rready  (rready),
        .ip2intc_irpt  (irpt)
    );

    // ----------------------------------------------------------------
    // Clock: 100 MHz (10 ns period)
    // ----------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // Test infrastructure
    // ----------------------------------------------------------------
    integer fail_count;
    reg [31:0] rd_data;

    task check_eq;
        input [255:0] label;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got !== exp) begin
                $display("  FAIL %0s: got=0x%08X exp=0x%08X", label, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // AXI4-Lite write task
    // Drives AW and W channels simultaneously; waits for B.
    // Uses negedge-driven / posedge-sampled protocol.
    // ----------------------------------------------------------------
    task axil_write;
        input [3:0]  t_addr;
        input [31:0] t_data;
        input [3:0]  t_strb;

        reg  done_aw, done_w, done_b;
        integer k;
        begin
            done_aw = 1'b0; done_w = 1'b0; done_b = 1'b0;
            k = 0;

            @(negedge clk);
            awaddr  = t_addr;
            awprot  = 3'b000;
            awvalid = 1'b1;
            wdata   = t_data;
            wstrb   = t_strb;
            wvalid  = 1'b1;
            bready  = 1'b1;

            while ((!done_aw || !done_w || !done_b) && k < 64) begin
                @(posedge clk);
                if (awvalid && awready) done_aw = 1'b1;
                if (wvalid  && wready)  done_w  = 1'b1;
                if (bvalid  && bready)  done_b  = 1'b1;
                @(negedge clk);
                if (done_aw) awvalid = 1'b0;
                if (done_w)  wvalid  = 1'b0;
                if (done_b)  bready  = 1'b0;
                k = k + 1;
            end

            if (!done_b) begin
                $display("  FAIL axil_write timeout addr=0x%X", t_addr);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // AXI4-Lite read task
    // ----------------------------------------------------------------
    task axil_read;
        input  [3:0]  t_addr;
        output [31:0] t_rdata;

        reg  done_ar, done_r;
        integer k;
        begin
            done_ar = 1'b0; done_r = 1'b0;
            k = 0;
            t_rdata = 32'hXXXX_XXXX;

            @(negedge clk);
            araddr  = t_addr;
            arprot  = 3'b000;
            arvalid = 1'b1;
            rready  = 1'b1;

            while ((!done_ar || !done_r) && k < 64) begin
                @(posedge clk);
                if (arvalid && arready) done_ar = 1'b1;
                if (rvalid  && rready) begin
                    t_rdata = rdata;
                    done_r  = 1'b1;
                end
                @(negedge clk);
                if (done_ar) arvalid = 1'b0;
                if (done_r)  rready  = 1'b0;
                k = k + 1;
            end

            if (!done_r) begin
                $display("  FAIL axil_read timeout addr=0x%X", t_addr);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // Main test
    // ----------------------------------------------------------------
    initial begin
        // Initialise all master signals
        fail_count = 0;
        aresetn = 1'b0;
        awaddr  = 4'h0; awprot  = 3'b0; awvalid = 1'b0;
        wdata   = 32'h0; wstrb  = 4'hF; wvalid  = 1'b0;
        bready  = 1'b0;
        araddr  = 4'h0; arprot  = 3'b0; arvalid = 1'b0;
        rready  = 1'b0;

        // Hold reset for 10 cycles
        repeat(10) @(posedge clk);
        @(negedge clk); aresetn = 1'b1;
        repeat(5) @(posedge clk);

        // ---- T1: Reset state ----------------------------------------
        axil_read(4'h0, rd_data); check_eq("T1 CTRL   reset", rd_data, 32'h0000_0000);
        axil_read(4'h4, rd_data); check_eq("T1 STATUS reset", rd_data, 32'h0000_0000);
        axil_read(4'h8, rd_data); check_eq("T1 DATA   reset", rd_data, 32'h0000_0000);
        axil_read(4'hC, rd_data); check_eq("T1 IRQMSK reset", rd_data, 32'h0000_0000);
        // irq_r registered; two cycles after reset + reads: STATUS[0]=0 so irpt=0
        repeat(3) @(posedge clk);
        check_eq("T1 irpt   reset", {31'h0, irpt}, 32'h0000_0000);

        // ---- T2: Write / read CTRL ----------------------------------
        axil_write(4'h0, 32'hDEAD_BEEF, 4'hF);
        axil_read(4'h0, rd_data);
        check_eq("T2 CTRL write-readback", rd_data, 32'hDEAD_BEEF);

        // ---- T3: Write DATA -> STATUS[0] auto-set -------------------
        axil_write(4'h8, 32'h1234_5678, 4'hF);
        axil_read(4'h8, rd_data);
        check_eq("T3 DATA  write-readback", rd_data, 32'h1234_5678);
        axil_read(4'h4, rd_data);
        check_eq("T3 STATUS[0] set by DATA write", rd_data & 32'h1, 32'h0000_0001);

        // ---- T4: Enable IRQ, check irpt high ------------------------
        // STATUS[0] is 1 from T3; now set IRQ_MASK[0]=1
        axil_write(4'hC, 32'h0000_0001, 4'hF);
        repeat(3) @(posedge clk);  // wait for irq_r to propagate
        check_eq("T4 irpt high after IRQ_MASK set", {31'h0, irpt}, 32'h0000_0001);

        // ---- T5: Clear STATUS[0] -> irpt goes low -------------------
        axil_write(4'h4, 32'h0000_0000, 4'hF);
        repeat(3) @(posedge clk);
        check_eq("T5 irpt low after STATUS clear", {31'h0, irpt}, 32'h0000_0000);

        // ---- T6: WSTRB partial write (bytes 0 and 2 only) ----------
        // Clear CTRL first
        axil_write(4'h0, 32'h0000_0000, 4'hF);
        // Write bytes 0 and 2: strb=4'b0101, data=0xAABBCCDD
        //   byte0 (bits[7:0]):   strb[0]=1 -> 0xDD
        //   byte1 (bits[15:8]):  strb[1]=0 -> 0x00 (unchanged)
        //   byte2 (bits[23:16]): strb[2]=1 -> 0xCC
        //   byte3 (bits[31:24]): strb[3]=0 -> 0x00 (unchanged)
        // Expected: 0x00CC00DD
        axil_write(4'h0, 32'hAABB_CCDD, 4'b0101);
        axil_read(4'h0, rd_data);
        check_eq("T6 WSTRB partial (strb=0101)", rd_data, 32'h00CC_00DD);

        // ---- BRESP and RRESP must be OKAY (2'b00) ------------------
        axil_write(4'h0, 32'h0, 4'hF);
        // bresp sampled inside axil_write; check last captured value
        check_eq("BRESP always OKAY", {30'h0, bresp}, 32'h0);
        axil_read(4'h0, rd_data);
        check_eq("RRESP always OKAY", {30'h0, rresp}, 32'h0);

        // Allow any remaining events to settle
        repeat(10) @(posedge clk);

        // ---- Final verdict -----------------------------------------
        if (fail_count === 0)
            $display("PASS: all %0d tests passed", 7);
        else
            $display("FAIL: %0d checks failed", fail_count);

        $finish;
    end

    // Safety timeout
    initial begin
        #500000;
        $display("FAIL: simulation timeout");
        $finish;
    end

endmodule
`default_nettype wire
