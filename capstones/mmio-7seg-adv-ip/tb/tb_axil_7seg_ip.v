// tb_axil_7seg_ip.v
// Self-checking testbench for axil_7seg_ip
// HARNESS: mmio-7seg-adv-ip (I-072)
// License: MIT
//
// Outputs "PASS" on success, "FAIL: <reason>" on first failure.
// Compatible with: iverilog, verilator (with --main --timing)
//
// Test plan:
//   T1  Reset state: an=1111 (all off), reg_ctrl reset=0x1F0F
//   T2  Write DATA=0x1234, CTRL enable+bright=15+blank=0
//       → after mux cycles: anodes toggle, seg patterns match hex encoder
//   T3  Blank digit 0 → an[0] stays high for digit 0's slot
//   T4  dp_en digit 1 → dp_out low during digit 1's slot
//   T5  en=0 → all outputs forced high (all off)
//   T6  Read back DATA and CTRL registers via AXI read

`timescale 1ns/1ps

module tb_axil_7seg_ip;

    // ---------------------------------------------------------------
    // Clock and reset
    // ---------------------------------------------------------------
    reg aclk;
    reg aresetn;

    initial aclk = 0;
    always #5 aclk = ~aclk; // 100 MHz

    // ---------------------------------------------------------------
    // DUT I/O
    // ---------------------------------------------------------------
    reg  [7:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    reg  [7:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;
    wire [3:0]  an;
    wire [6:0]  seg;
    wire        dp_out;

    axil_7seg_ip #(
        .CLK_HZ    (100_000_000),
        .REFRESH_HZ(1000)
    ) dut (
        .aclk   (aclk),    .aresetn(aresetn),
        .awaddr (awaddr),   .awvalid(awvalid),  .awready(awready),
        .wdata  (wdata),    .wstrb  (wstrb),    .wvalid (wvalid),   .wready(wready),
        .bresp  (bresp),    .bvalid (bvalid),   .bready (bready),
        .araddr (araddr),   .arvalid(arvalid),  .arready(arready),
        .rdata  (rdata),    .rresp  (rresp),    .rvalid (rvalid),   .rready(rready),
        .an     (an),       .seg    (seg),       .dp_out (dp_out)
    );

    // ---------------------------------------------------------------
    // Task: AXI4-Lite write (address + data in same cycle, wait done)
    // ---------------------------------------------------------------
    task axil_write;
        input [7:0]  addr;
        input [31:0] data;
        input [3:0]  strb;
        integer timeout;
        begin
            // Present address
            @(posedge aclk);
            awaddr  <= addr;
            awvalid <= 1'b1;
            wdata   <= data;
            wstrb   <= strb;
            wvalid  <= 1'b1;
            bready  <= 1'b1;
            // Wait for address handshake
            timeout = 0;
            while (!awready && timeout < 100) begin @(posedge aclk); timeout=timeout+1; end
            @(posedge aclk);
            awvalid <= 1'b0;
            // Wait for data handshake
            timeout = 0;
            while (!wready && timeout < 100) begin @(posedge aclk); timeout=timeout+1; end
            @(posedge aclk);
            wvalid  <= 1'b0;
            // Wait for response
            timeout = 0;
            while (!bvalid && timeout < 100) begin @(posedge aclk); timeout=timeout+1; end
            @(posedge aclk);
            bready  <= 1'b0;
        end
    endtask

    // ---------------------------------------------------------------
    // Task: AXI4-Lite read (return value via reg)
    // ---------------------------------------------------------------
    reg [31:0] rd_result;
    task axil_read;
        input  [7:0]  addr;
        integer timeout;
        begin
            @(posedge aclk);
            araddr  <= addr;
            arvalid <= 1'b1;
            rready  <= 1'b1;
            timeout = 0;
            while (!arready && timeout < 100) begin @(posedge aclk); timeout=timeout+1; end
            @(posedge aclk);
            arvalid <= 1'b0;
            timeout = 0;
            while (!rvalid && timeout < 100) begin @(posedge aclk); timeout=timeout+1; end
            rd_result <= rdata;
            @(posedge aclk);
            rready  <= 1'b0;
        end
    endtask

    // ---------------------------------------------------------------
    // Task: advance mux to target digit slot (approximate)
    //   MUX_DIV = 100000 cycles per digit
    // ---------------------------------------------------------------
    localparam MUX_DIV = 100000;
    task wait_digit;
        input [1:0] target;
        integer i;
        // Wait until digit_sel == target by scanning an bits
        // an[0]=low for digit 0, an[1]=low for digit 1, etc.
        // Run for up to 4*MUX_DIV cycles
        begin
            for (i = 0; i < 4*MUX_DIV; i = i+1) begin
                @(posedge aclk);
                // Check if the right anode is active
                if (target == 2'd0 && an[0] === 1'b0) i = 4*MUX_DIV; // break
                if (target == 2'd1 && an[1] === 1'b0) i = 4*MUX_DIV;
                if (target == 2'd2 && an[2] === 1'b0) i = 4*MUX_DIV;
                if (target == 2'd3 && an[3] === 1'b0) i = 4*MUX_DIV;
            end
        end
    endtask

    // ---------------------------------------------------------------
    // Expected segment patterns (active-low, {g,f,e,d,c,b,a})
    // ---------------------------------------------------------------
    function [6:0] exp_seg;
        input [3:0] h;
        case (h)
            4'h0: exp_seg = 7'b100_0000;
            4'h1: exp_seg = 7'b111_1001;
            4'h2: exp_seg = 7'b010_0100;
            4'h3: exp_seg = 7'b011_0000;
            4'h4: exp_seg = 7'b001_1001;
            4'h5: exp_seg = 7'b001_0010;
            4'h6: exp_seg = 7'b000_0010;
            4'h7: exp_seg = 7'b111_1000;
            4'h8: exp_seg = 7'b000_0000;
            4'h9: exp_seg = 7'b001_0000;
            4'hA: exp_seg = 7'b000_1000;
            4'hB: exp_seg = 7'b000_0011;
            4'hC: exp_seg = 7'b100_0110;
            4'hD: exp_seg = 7'b010_0001;
            4'hE: exp_seg = 7'b000_0110;
            4'hF: exp_seg = 7'b000_1110;
        endcase
    endfunction

    // ---------------------------------------------------------------
    // Fail counter and check macro
    // ---------------------------------------------------------------
    integer fail_count;
    reg [127:0] fail_msg;

    // ---------------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------------
    integer i;
    initial begin
        fail_count = 0;
        // Initial values
        awaddr  = 8'h00;  awvalid = 1'b0;
        wdata   = 32'h0;  wstrb   = 4'h0;  wvalid  = 1'b0;  bready  = 1'b0;
        araddr  = 8'h00;  arvalid = 1'b0;  rready  = 1'b0;
        aresetn = 1'b0;
        repeat (10) @(posedge aclk);
        aresetn = 1'b1;
        repeat (5)  @(posedge aclk);

        // ============================================================
        // T1: Reset state — all anodes high, seg all high (all off)
        // ============================================================
        // After reset: en=1, blank=0xF → all digits blanked → an=1111
        if (an !== 4'b1111) begin
            $display("FAIL: T1 reset an expected 1111, got %b", an);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // T2: Enable digits 0-3, DATA=0x1234, CTRL=bright=15, blank=0
        //   DATA: d3=0, d2=1, d1=2, d0=3  (reg_data[15:0]=0x0123... wait)
        //   Register map: [3:0]=d0, [7:4]=d1, [11:8]=d2, [15:12]=d3
        //   For digits d0=4, d1=3, d2=2, d3=1 → DATA=0x0001_2340...
        //   Let's use DATA=0x0000_4321: d3=4, d2=3, d1=2, d0=1
        //   CTRL: en=1 (bit12), bright=15 (bits 11:8), dp_en=0, blank=0
        //         = 0x0000_1F00
        // ============================================================
        axil_write(8'h00, 32'h0000_4321, 4'hF); // DATA
        axil_write(8'h04, 32'h0000_1F00, 4'hF); // CTRL: en=1,bright=F,blank=0,dp=0

        // Wait for digit 0 (d0=1 → seg=1)
        wait_digit(2'd0);
        if (an !== 4'b1110) begin
            $display("FAIL: T2 digit0 an expected 1110, got %b", an);
            fail_count = fail_count + 1;
        end
        if (seg !== exp_seg(4'h1)) begin
            $display("FAIL: T2 digit0 seg expected %b (hex 1), got %b", exp_seg(4'h1), seg);
            fail_count = fail_count + 1;
        end

        // Wait for digit 1 (d1=2 → seg for 2)
        wait_digit(2'd1);
        if (an !== 4'b1101) begin
            $display("FAIL: T2 digit1 an expected 1101, got %b", an);
            fail_count = fail_count + 1;
        end
        if (seg !== exp_seg(4'h2)) begin
            $display("FAIL: T2 digit1 seg expected %b (hex 2), got %b", exp_seg(4'h2), seg);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // T3: Blank digit 0 → an stays 1111 during digit 0 slot
        // ============================================================
        axil_write(8'h04, 32'h0000_1F01, 4'hF); // blank[0]=1, rest same
        wait_digit(2'd0);
        if (an !== 4'b1111) begin
            $display("FAIL: T3 blank digit0 an expected 1111, got %b", an);
            fail_count = fail_count + 1;
        end
        // Digit 1 should still show
        wait_digit(2'd1);
        if (an !== 4'b1101) begin
            $display("FAIL: T3 digit1 (non-blanked) an expected 1101, got %b", an);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // T4: dp_en digit 1 → dp_out=0 during digit 1 slot
        //   CTRL: blank=0x1 (digit0), dp_en=0x2 (digit1), bright=15, en=1
        //       = [12]=1, [11:8]=0xF, [7:4]=0x2, [3:0]=0x1
        //       = 0x0000_1F21
        // ============================================================
        axil_write(8'h04, 32'h0000_1F21, 4'hF);
        wait_digit(2'd1);
        if (dp_out !== 1'b0) begin
            $display("FAIL: T4 dp digit1 expected 0, got %b", dp_out);
            fail_count = fail_count + 1;
        end
        // Digit 2 dp should be off (dp_en[2]=0)
        wait_digit(2'd2);
        if (dp_out !== 1'b1) begin
            $display("FAIL: T4 dp digit2 expected 1 (off), got %b", dp_out);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // T5: en=0 → all outputs high
        // ============================================================
        axil_write(8'h04, 32'h0000_0F00, 4'hF); // en=0 (bit12 clear), bright=15
        // Wait a few mux cycles
        repeat (MUX_DIV * 2) @(posedge aclk);
        if (an !== 4'b1111) begin
            $display("FAIL: T5 en=0 an expected 1111, got %b", an);
            fail_count = fail_count + 1;
        end
        if (seg !== 7'b111_1111) begin
            $display("FAIL: T5 en=0 seg expected 1111111, got %b", seg);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // T6: Read back registers
        // ============================================================
        // Re-enable to avoid confusion; write known values
        axil_write(8'h00, 32'h0000_ABCD, 4'hF);
        axil_write(8'h04, 32'h0000_1F00, 4'hF);
        repeat (5) @(posedge aclk);

        axil_read(8'h00);
        if (rd_result !== 32'h0000_ABCD) begin
            $display("FAIL: T6 DATA readback expected 0000ABCD, got %08h", rd_result);
            fail_count = fail_count + 1;
        end

        axil_read(8'h04);
        if (rd_result !== 32'h0000_1F00) begin
            $display("FAIL: T6 CTRL readback expected 00001F00, got %08h", rd_result);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Result
        // ============================================================
        if (fail_count === 0)
            $display("PASS: all tests passed (T1-T6)");
        else
            $display("FAIL: %0d test(s) failed", fail_count);

        $finish;
    end

    // ---------------------------------------------------------------
    // Timeout guard (10 ms sim = 1,000,000 cycles @ 100 MHz)
    // The test needs ~4 * 100000 * 4 = 1.6M cycles for mux waits
    // Allow 7M cycles
    // ---------------------------------------------------------------
    initial begin
        #70_000_000; // 70 ms sim time
        $display("FAIL: simulation timeout");
        $finish;
    end

endmodule
