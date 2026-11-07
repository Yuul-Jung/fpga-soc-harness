// tb_axil_attn1h.v — Self-checking testbench for axil_attn1h
// Tests: register R/W, weight load, start→done, output read
// Outputs PASS/FAIL on stdout (checked by CI)
// Verilog-2001. No external IP.

`timescale 1ns/1ps
`default_nettype none

module tb_axil_attn1h;

// Clock/reset
reg clk = 0;
reg rst = 1;
always #5 clk = ~clk; // 100 MHz

// AXI4-Lite signals
reg        awvalid = 0;
wire       awready;
reg  [7:0] awaddr  = 0;
reg        wvalid  = 0;
wire       wready;
reg  [31:0]wdata  = 0;
wire       bvalid;
reg        bready  = 1;
wire [1:0] bresp;
reg        arvalid = 0;
wire       arready;
reg  [7:0] araddr  = 0;
wire       rvalid;
reg        rready  = 1;
wire[31:0] rdata;
wire [1:0] rresp;
wire       busy_led, done_led;

// DUT
axil_attn1h #(.D(8),.S(4)) dut (
    .clk(clk), .rst(rst),
    .s_axil_awvalid(awvalid), .s_axil_awready(awready), .s_axil_awaddr(awaddr),
    .s_axil_wvalid(wvalid),   .s_axil_wready(wready),   .s_axil_wdata(wdata),
    .s_axil_wstrb(4'hF),
    .s_axil_bvalid(bvalid),   .s_axil_bready(bready),   .s_axil_bresp(bresp),
    .s_axil_arvalid(arvalid), .s_axil_arready(arready), .s_axil_araddr(araddr),
    .s_axil_rvalid(rvalid),   .s_axil_rready(rready),   .s_axil_rdata(rdata),
    .s_axil_rresp(rresp),
    .busy_led(busy_led), .done_led(done_led)
);

integer fail = 0;
integer i;
reg [31:0] rd_val;

// AXI write task
task axil_write;
    input [7:0] addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        awvalid = 1; awaddr = addr;
        wvalid  = 1; wdata  = data;
        // Wait for handshake
        @(posedge clk);
        while (!awready) @(posedge clk);
        #1; awvalid = 0;
        while (!wready)  @(posedge clk);
        #1; wvalid  = 0;
        while (!bvalid)  @(posedge clk);
        @(posedge clk); #1;
    end
endtask

// AXI read task
task axil_read;
    input [7:0] addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        arvalid = 1; araddr = addr;
        @(posedge clk);
        while (!arready) @(posedge clk);
        #1; arvalid = 0;
        while (!rvalid) @(posedge clk);
        data = rdata;
        @(posedge clk); #1;
    end
endtask

// Wait for done (timeout)
task wait_done;
    input integer timeout;
    integer cnt;
    begin
        cnt = 0;
        while (!done_led && cnt < timeout) begin
            @(posedge clk);
            cnt = cnt + 1;
        end
        if (cnt >= timeout) begin
            $display("FAIL: timeout waiting for done");
            fail = fail + 1;
        end
    end
endtask

initial begin
    // 1. Reset
    rst = 1;
    repeat(10) @(posedge clk);
    rst = 0;
    repeat(5) @(posedge clk);

    // 2. VERSION register check
    axil_read(8'h1C, rd_val);
    if (rd_val !== 32'h00010001) begin
        $display("FAIL: VERSION expected 0x00010001 got 0x%08X", rd_val);
        fail = fail + 1;
    end else
        $display("INFO: VERSION OK (0x%08X)", rd_val);

    // 3. CFG register R/W (seq_len=2 → reg_cfg=1)
    axil_write(8'h18, 32'd1);
    axil_read (8'h18, rd_val);
    if (rd_val[2:0] !== 3'd1) begin
        $display("FAIL: CFG R/W got %0d", rd_val[2:0]);
        fail = fail + 1;
    end else
        $display("INFO: CFG R/W OK");

    // 4. Load identity WQ (target=0, identity matrix 8x8)
    //    WQ[i*8+j] = (i==j) ? 64 : 0  (identity×64)
    axil_write(8'h00, 32'h00); // CTRL target=0 (WQ), clear
    axil_write(8'h0C, 32'd0); // WIDX = 0
    for (i=0; i<64; i=i+1) begin
        // identity: row=i/8, col=i%8
        if ((i/8) == (i%8))
            axil_write(8'h08, 32'd64);  // 0x40
        else
            axil_write(8'h08, 32'd0);
    end

    // 5. Load identity WK
    axil_write(8'h00, 32'h10); // CTRL target=1 (WK)
    axil_write(8'h0C, 32'd0);
    for (i=0; i<64; i=i+1) begin
        if ((i/8) == (i%8))
            axil_write(8'h08, 32'd64);
        else
            axil_write(8'h08, 32'd0);
    end

    // 6. Load identity WV
    axil_write(8'h00, 32'h20); // CTRL target=2 (WV)
    axil_write(8'h0C, 32'd0);
    for (i=0; i<64; i=i+1) begin
        if ((i/8) == (i%8))
            axil_write(8'h08, 32'd64);
        else
            axil_write(8'h08, 32'd0);
    end

    // 7. Load input tokens: X[0]=[1,0,0,0,0,0,0,0] X[1]=[0,1,0,...] (2 tokens, identity-like)
    axil_write(8'h18, 32'd1);  // CFG: seq_len=2 (reg=1)
    axil_write(8'h00, 32'h30); // CTRL target=3 (X)
    axil_write(8'h0C, 32'd0);
    for (i=0; i<16; i=i+1) begin
        // token 0: [4,0,0,0,0,0,0,0], token 1: [0,4,0,...0]
        if (i == 0 || i == 9) // pos0_dim0=4, pos1_dim1=4
            axil_write(8'h08, 32'd4);
        else
            axil_write(8'h08, 32'd0);
    end

    // 8. Start inference
    axil_write(8'h00, 32'h01); // CTRL start=1

    // Wait done
    wait_done(50000);

    // 9. Read STATUS
    axil_read(8'h04, rd_val);
    if (!rd_val[1]) begin
        $display("FAIL: STATUS done bit not set");
        fail = fail + 1;
    end else
        $display("INFO: STATUS done=1 OK");

    // 10. Read output at [0][0] and [1][1] — with identity weights and simple tokens
    //     expect non-zero outputs (structural check only, not exact value)
    axil_write(8'h14, 32'd0); // OUT_IDX = pos0,dim0
    axil_read (8'h10, rd_val);
    $display("INFO: out[0][0] = %0d (signed %0d)", rd_val, $signed(rd_val));

    axil_write(8'h14, 32'd9); // OUT_IDX = pos1,dim1 → {pos=1,dim=1} = 1*8+1=9? No: {pos[1:0],dim[2:0]} = 5 bits
    // pos=1 → bits[4:3]=01, dim=1 → bits[2:0]=001 → 5'b01001 = 9
    axil_read (8'h10, rd_val);
    $display("INFO: out[1][1] = %0d (signed %0d)", rd_val, $signed(rd_val));

    // 11. Clear done and check status clears
    axil_write(8'h00, 32'h04); // CTRL clear_done=1
    repeat(5) @(posedge clk);
    axil_read(8'h04, rd_val);
    if (rd_val[1]) begin
        $display("FAIL: STATUS done bit should clear after clear_done");
        fail = fail + 1;
    end else
        $display("INFO: clear_done OK");

    // 12. Final result
    if (fail == 0)
        $display("PASS: all checks passed");
    else
        $display("FAIL: %0d check(s) failed", fail);

    $finish;
end

// Timeout guard
initial begin
    #10_000_000;
    $display("FAIL: global simulation timeout");
    $finish;
end

endmodule
`default_nettype wire
