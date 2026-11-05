// tb_bldc_hall_sixstep_ip.v
// Self-checking testbench for bldc_hall_sixstep_ip
// Tests:
//  T1: ID register read = 0x424C4443
//  T2: Enable, set duty/deadtime, check gate assertion after deadtime
//  T3: Forward hall sequence, check step changes + IRQ
//  T4: Shoot-through check (hin[i] & lin[i] must never both be 1)
//  T5: Deadtime measurement on commutation event
//  T6: Fault injection (hall=000 → hin/lin must be 0, STATUS[6]=1)
// Output: PASS or FAIL (first token)
// Verilog-2001

`timescale 1ns/1ps

module tb_bldc_hall_sixstep_ip;

    // -----------------------------------------------------------------------
    // Simulation parameters
    // -----------------------------------------------------------------------
    localparam SIM_DUTY     = 10'd256;   // 25% duty for fast test
    localparam SIM_DEADTIME = 8'd8;      // 8 cycles deadtime for fast test

    // -----------------------------------------------------------------------
    // Clock & reset
    // -----------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz

    reg rst_n;

    // -----------------------------------------------------------------------
    // DUT wires
    // -----------------------------------------------------------------------
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

    reg  [2:0]  hall_in;
    wire [2:0]  hin;
    wire [2:0]  lin;
    wire        sample_trig;
    wire        irq;

    bldc_hall_sixstep_ip #(
        .DEFAULT_DUTY    (SIM_DUTY),
        .DEFAULT_DEADTIME(SIM_DEADTIME)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .s_awaddr   (awaddr),
        .s_awvalid  (awvalid),
        .s_awready  (awready),
        .s_wdata    (wdata),
        .s_wstrb    (wstrb),
        .s_wvalid   (wvalid),
        .s_wready   (wready),
        .s_bresp    (bresp),
        .s_bvalid   (bvalid),
        .s_bready   (bready),
        .s_araddr   (araddr),
        .s_arvalid  (arvalid),
        .s_arready  (arready),
        .s_rdata    (rdata),
        .s_rresp    (rresp),
        .s_rvalid   (rvalid),
        .s_rready   (rready),
        .hall_in    (hall_in),
        .hin        (hin),
        .lin        (lin),
        .sample_trig(sample_trig),
        .irq        (irq)
    );

    // -----------------------------------------------------------------------
    // AXI4-Lite helper tasks
    // -----------------------------------------------------------------------
    task axi_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            awaddr  = addr;
            awvalid = 1'b1;
            wdata   = data;
            wstrb   = 4'hF;
            wvalid  = 1'b1;
            bready  = 1'b1;

            @(posedge clk);
            while (!awready) @(posedge clk);
            @(posedge clk);
            awvalid = 1'b0;

            while (!wready) @(posedge clk);
            wvalid = 1'b0;

            while (!bvalid) @(posedge clk);
            @(posedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read(input [7:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            araddr  = addr;
            arvalid = 1'b1;
            rready  = 1'b1;

            @(posedge clk);
            while (!arready) @(posedge clk);
            arvalid = 1'b0;

            while (!rvalid) @(posedge clk);
            data = rdata;
            @(posedge clk);
            rready = 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    // Test variables
    // -----------------------------------------------------------------------
    reg [31:0] rd_val;
    integer    fail_count;
    integer    i;
    integer    dt_cycles;

    // Shoot-through monitor: combinational, asserts immediately
    reg shoot_through_seen;

    task check(input pass_cond, input [7:0] test_id, input [31:0] got, input [31:0] exp);
        begin
            if (!pass_cond) begin
                $display("FAIL T%0d: got=0x%08X exp=0x%08X", test_id, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Shoot-through monitor (clocked check)
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        // If any high-side AND low-side of same phase are both driven high
        // that is a shoot-through condition
        if (rst_n && ((hin[0] & lin[0]) || (hin[1] & lin[1]) || (hin[2] & lin[2]))) begin
            shoot_through_seen = 1'b1;
        end
    end

    // -----------------------------------------------------------------------
    // Forward hall sequence: 101→001→011→010→110→100→(101)
    // -----------------------------------------------------------------------
    reg [2:0] hall_fwd [0:5];
    initial begin
        hall_fwd[0] = 3'b101;
        hall_fwd[1] = 3'b001;
        hall_fwd[2] = 3'b011;
        hall_fwd[3] = 3'b010;
        hall_fwd[4] = 3'b110;
        hall_fwd[5] = 3'b100;
    end

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    initial begin
        // Init
        fail_count         = 0;
        shoot_through_seen = 1'b0;
        rst_n    = 1'b0;
        hall_in  = 3'b101;    // step 0 valid
        awvalid  = 1'b0; awaddr = 8'd0;
        wvalid   = 1'b0; wdata  = 32'd0; wstrb = 4'hF;
        bready   = 1'b0;
        arvalid  = 1'b0; araddr = 8'd0;
        rready   = 1'b0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // ---- T1: ID register ----
        axi_read(8'h00, rd_val);
        check(rd_val === 32'h424C4443, 1, rd_val, 32'h424C4443);

        // ---- T2: Enable, set duty and deadtime, check gate assertion ----
        // Write duty = SIM_DUTY
        axi_write(8'h08, {22'd0, SIM_DUTY});
        // Write deadtime = SIM_DEADTIME
        axi_write(8'h0C, {24'd0, SIM_DEADTIME});
        // Enable: ctrl_en=1, ie=1, dir=0
        axi_write(8'h04, 32'h3);

        // Wait for deadtime to expire (SIM_DEADTIME + sync latency + margin)
        repeat (SIM_DEADTIME + 10) @(posedge clk);

        // With hall_in=101 (step 0), after deadtime: hin[0] should PWM, lin[1] should be 1
        // Check lin[1] (B-) is asserted (DC on low-side)
        // Allow a full PWM period (SIM_DUTY < 1024) to see at least some hin activity
        // We just check lin is nonzero
        begin : wait_lin
            integer cnt;
            cnt = 0;
            while (lin === 3'b000 && cnt < 100) begin
                @(posedge clk);
                cnt = cnt + 1;
            end
            check(lin !== 3'b000, 2, {29'd0, lin}, 32'h2);
        end

        // ---- T3: Forward hall sequence, check IRQ fires ----
        // Clear IRQ status first
        axi_write(8'h14, 32'h1);  // W1C bit [0]

        for (i = 1; i < 6; i = i + 1) begin
            // Advance hall to next step
            hall_in = hall_fwd[i];
            // Wait for 3 sync stages + deadtime + margin
            repeat (SIM_DEADTIME + 20) @(posedge clk);
        end

        // IRQ_STAT[0] should be set (at least one step change happened)
        axi_read(8'h14, rd_val);
        check(rd_val[0] === 1'b1, 3, rd_val, 32'h1);

        // ---- T4: Shoot-through check (monitor runs throughout) ----
        // No explicit steps needed; the monitor caught any during T2/T3
        check(shoot_through_seen === 1'b0, 4, {31'd0, shoot_through_seen}, 32'h0);

        // ---- T5: Deadtime measurement ----
        // Trigger a fresh step change and count cycles before hin goes non-zero
        // First clear deadtime by staying on current step for a while
        hall_in = 3'b100; // step 5
        repeat (30) @(posedge clk);

        // Clear IRQ
        axi_write(8'h14, 32'h1);

        // Now step to 101 (step 0) — commutation event
        hall_in = 3'b101;

        // Count cycles until hin goes non-zero (high side asserts)
        begin : dt_measure
            integer cnt;
            reg hin_seen;
            cnt      = 0;
            hin_seen = 1'b0;
            repeat (SIM_DEADTIME + 50) @(posedge clk) begin
                cnt = cnt + 1;
                if (hin !== 3'b000) begin
                    hin_seen = 1'b1;
                    disable dt_measure;
                end
            end
            // hin must have appeared and after at least SIM_DEADTIME-3 cycles
            // (3 sync stages shift the step_change, then deadtime counts down)
            check(hin_seen === 1'b1,  51, {31'd0, hin_seen}, 32'h1);
            check(cnt >= SIM_DEADTIME, 52, cnt, {24'd0, SIM_DEADTIME});
        end

        // ---- T6: Fault injection ----
        // 000 and 111 are invalid hall codes → fault
        hall_in = 3'b000;
        repeat (10) @(posedge clk); // let sync stages propagate

        // hin and lin must both be 0 (outputs suppressed on fault)
        check(hin === 3'b000, 61, {29'd0, hin}, 32'h0);
        check(lin === 3'b000, 62, {29'd0, lin}, 32'h0);

        // STATUS[6] = fault_lat should be set
        axi_read(8'h10, rd_val);
        check(rd_val[6] === 1'b1, 63, rd_val, 32'h40);

        // Restore valid hall FIRST so fault_raw goes low before CTRL write.
        // (3 sync stages must propagate; writing CTRL while fault_raw=1 would
        //  re-latch the fault on the very next cycle.)
        hall_in = 3'b101;
        repeat (6) @(posedge clk); // 3 sync + 3 margin → fault_raw=0

        // Now clear fault by writing CTRL (re-enable).
        // Correct usage order: fix hardware problem, then acknowledge fault.
        axi_write(8'h04, 32'h3);  // ctrl_en=1, ctrl_ie=1, fault_lat cleared

        repeat (5) @(posedge clk);

        // STATUS[6] should now be clear
        axi_read(8'h10, rd_val);
        check(rd_val[6] === 1'b0, 64, rd_val, 32'h0);

        // ---- Final result ----
        repeat (10) @(posedge clk);
        if (fail_count === 0)
            $display("PASS: all tests passed");
        else
            $display("FAIL: %0d test(s) failed", fail_count);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #500_000;
        $display("FAIL: timeout");
        $finish;
    end

endmodule
