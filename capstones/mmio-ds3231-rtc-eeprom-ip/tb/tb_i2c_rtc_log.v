// tb_i2c_rtc_log.v
// Self-checking testbench for axil_i2c_rtc_log.
// Outputs: "PASS: ..." or "FAIL: ..." prefix lines.
// Verilog-2001. Requires iverilog/vvp.

`timescale 1ns/1ps
`default_nettype none

module tb_i2c_rtc_log;

    // ----------------------------------------------------------------
    // Clock and reset
    // ----------------------------------------------------------------
    reg clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    reg resetn;
    initial begin
        resetn = 0;
        #200;
        resetn = 1;
    end

    // ----------------------------------------------------------------
    // AXI4-Lite master signals
    // ----------------------------------------------------------------
    reg  [31:0] awaddr = 0;  reg awvalid = 0; wire awready;
    reg  [31:0] wdata  = 0;  reg [3:0] wstrb = 4'hF; reg wvalid = 0; wire wready;
    wire [1:0]  bresp;       wire bvalid; reg bready = 1;
    reg  [31:0] araddr = 0;  reg arvalid = 0; wire arready;
    wire [31:0] rdata;       wire [1:0] rresp; wire rvalid; reg rready = 1;

    // ----------------------------------------------------------------
    // I2C bus (open-drain wired-AND with pull-up)
    // ----------------------------------------------------------------
    wire scl_o, scl_oe, scl_i;
    wire sda_o, sda_oe, sda_i;

    // Pull-up: bus is 1 unless someone drives it low
    wire scl_bus, sda_bus;
    assign scl_bus = scl_oe     ? 1'b0 : 1'b1;   // master side
    assign sda_bus = sda_oe     ? 1'b0 :
                     ds3231_sda_lo ? 1'b0 :
                     eeprom_sda_lo ? 1'b0 : 1'b1;
    assign scl_i = scl_bus;
    assign sda_i = sda_bus;

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    axil_i2c_rtc_log #(
        .CLK_HZ      (100_000_000),
        .HALF_PERIOD (10)   // fast for simulation: 5 MHz I2C
    ) dut (
        .s_aclk    (clk),   .s_aresetn (resetn),
        .s_awaddr  (awaddr), .s_awvalid (awvalid), .s_awready (awready),
        .s_wdata   (wdata),  .s_wstrb   (wstrb),   .s_wvalid  (wvalid), .s_wready (wready),
        .s_bresp   (bresp),  .s_bvalid  (bvalid),  .s_bready  (bready),
        .s_araddr  (araddr), .s_arvalid (arvalid), .s_ararready(arready),
        .s_rdata   (rdata),  .s_rresp   (rresp),   .s_rvalid  (rvalid), .s_rready (rready),
        .scl_o(scl_o), .scl_oe(scl_oe), .scl_i(scl_i),
        .sda_o(sda_o), .sda_oe(sda_oe), .sda_i(sda_i)
    );

    // ----------------------------------------------------------------
    // DS3231 behavioural model (respond only to address 0x68)
    // Returns time: sec=0x45, min=0x30, hour=0x14, day=3,
    //               date=0x07, mon=0x11, year=0x26
    // ----------------------------------------------------------------
    reg ds3231_sda_lo;
    reg [7:0] ds3231_regs [0:6];
    initial begin
        ds3231_regs[0] = 8'h45; // sec
        ds3231_regs[1] = 8'h30; // min
        ds3231_regs[2] = 8'h14; // hour 24h
        ds3231_regs[3] = 8'h03; // day
        ds3231_regs[4] = 8'h07; // date
        ds3231_regs[5] = 8'h11; // month
        ds3231_regs[6] = 8'h26; // year
    end

    reg [3:0] ds3231_bit_cnt;
    reg [7:0] ds3231_rx;
    reg [7:0] ds3231_reg_ptr;
    reg [2:0] ds3231_byte_in_xfer;
    reg       ds3231_addressed;
    reg       ds3231_read_mode;

    task ds3231_send_byte;
        input [7:0] byt;
        integer k;
        begin
            for (k = 7; k >= 0; k = k-1) begin
                @(negedge scl_bus);
                ds3231_sda_lo <= (byt[k] == 0) ? 1 : 0;
            end
            // ACK: master drives SDA low during ack clock
            @(negedge scl_bus);
            ds3231_sda_lo <= 0; // release, master sends NACK for last byte
        end
    endtask

    initial begin
        ds3231_sda_lo   = 0;
        ds3231_addressed= 0;
        ds3231_read_mode= 0;
        ds3231_reg_ptr  = 0;
        ds3231_byte_in_xfer = 0;
        ds3231_rx = 0;
    end

    // Detect START (SDA falls while SCL high)
    always @(negedge sda_bus) begin
        if (scl_bus) begin
            // START or repeated START
            ds3231_bit_cnt    <= 0;
            ds3231_rx         <= 0;
            ds3231_byte_in_xfer <= 0;
        end
    end

    // Sample on SCL rising edge
    always @(posedge scl_bus) begin
        ds3231_rx <= {ds3231_rx[6:0], sda_bus};
        ds3231_bit_cnt <= ds3231_bit_cnt + 1;

        if (ds3231_bit_cnt == 7) begin
            // 8 bits received
            ds3231_bit_cnt <= 0;
            if (ds3231_byte_in_xfer == 0) begin
                // Address byte
                if (ds3231_rx[7:1] == 7'h68) begin
                    ds3231_addressed  <= 1;
                    ds3231_read_mode  <= ds3231_rx[0];
                    // ACK: pull SDA low on next SCL high
                    @(negedge scl_bus);
                    ds3231_sda_lo <= 1;
                    @(posedge scl_bus); @(negedge scl_bus);
                    ds3231_sda_lo <= 0;
                    ds3231_byte_in_xfer <= 1;
                    if (ds3231_read_mode) begin
                        // Start sending RTC bytes
                        fork
                            begin : send_rtc
                                integer i;
                                for (i = 0; i < 7; i = i+1) begin
                                    ds3231_send_byte(ds3231_regs[i]);
                                end
                            end
                        join
                    end
                end
            end else if (!ds3231_read_mode) begin
                // Data byte (register pointer)
                ds3231_reg_ptr <= ds3231_rx;
                @(negedge scl_bus);
                ds3231_sda_lo <= 1;
                @(posedge scl_bus); @(negedge scl_bus);
                ds3231_sda_lo <= 0;
                ds3231_byte_in_xfer <= ds3231_byte_in_xfer + 1;
            end
        end
    end

    // ----------------------------------------------------------------
    // 24LC256 behavioural model (respond only to address 0x50)
    // Memory: simple 32KB array, pre-loaded with test pattern
    // ----------------------------------------------------------------
    reg eeprom_sda_lo;
    reg [7:0] ee_mem [0:32767];
    reg [14:0] ee_addr_ptr;
    reg [3:0]  ee_bit_cnt;
    reg [7:0]  ee_rx;
    reg [2:0]  ee_byte_cnt;
    reg        ee_addressed;
    reg        ee_rmode;

    integer j;
    initial begin
        for (j = 0; j < 32768; j = j+1)
            ee_mem[j] = j[7:0];
        eeprom_sda_lo = 0;
        ee_addressed  = 0;
        ee_rmode      = 0;
        ee_addr_ptr   = 0;
        ee_bit_cnt    = 0;
        ee_byte_cnt   = 0;
        ee_rx         = 0;
    end

    task ee_ack;
        begin
            @(negedge scl_bus);
            eeprom_sda_lo <= 1;
            @(posedge scl_bus);
            @(negedge scl_bus);
            eeprom_sda_lo <= 0;
        end
    endtask

    task ee_send_byte;
        input [7:0] byt;
        integer k;
        begin
            for (k = 7; k >= 0; k = k-1) begin
                @(negedge scl_bus);
                eeprom_sda_lo <= (byt[k] == 0) ? 1 : 0;
            end
            @(negedge scl_bus);
            eeprom_sda_lo <= 0; // NACK from master on last byte is fine
        end
    endtask

    always @(negedge sda_bus) begin
        if (scl_bus) begin
            ee_bit_cnt  <= 0;
            ee_rx       <= 0;
            ee_byte_cnt <= 0;
        end
    end

    always @(posedge scl_bus) begin
        ee_rx      <= {ee_rx[6:0], sda_bus};
        ee_bit_cnt <= ee_bit_cnt + 1;
        if (ee_bit_cnt == 7) begin
            ee_bit_cnt <= 0;
            if (ee_byte_cnt == 0) begin
                // Address byte
                if (ee_rx[7:1] == 7'h50) begin
                    ee_addressed <= 1;
                    ee_rmode     <= ee_rx[0];
                    ee_ack;
                    ee_byte_cnt <= 1;
                    if (ee_rmode) begin
                        ee_send_byte(ee_mem[ee_addr_ptr]);
                    end
                end
            end else if (ee_byte_cnt == 1 && !ee_rmode) begin
                ee_addr_ptr[14:8] <= ee_rx[6:0];
                ee_ack;
                ee_byte_cnt <= 2;
            end else if (ee_byte_cnt == 2 && !ee_rmode) begin
                ee_addr_ptr[7:0] <= ee_rx;
                ee_ack;
                ee_byte_cnt <= 3;
            end else if (ee_byte_cnt == 3 && !ee_rmode) begin
                ee_mem[ee_addr_ptr] <= ee_rx;
                ee_ack;
                ee_byte_cnt <= 0;
            end
        end
    end

    // ----------------------------------------------------------------
    // AXI4-Lite helper tasks
    // ----------------------------------------------------------------
    task axil_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            awaddr <= addr; awvalid <= 1;
            wdata  <= data; wvalid  <= 1;
            @(posedge clk);
            while (!awready) @(posedge clk);
            awvalid <= 0;
            while (!wready) @(posedge clk);
            wvalid <= 0;
            while (!bvalid) @(posedge clk);
        end
    endtask

    task axil_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            araddr <= addr; arvalid <= 1;
            @(posedge clk);
            while (!arready) @(posedge clk);
            arvalid <= 0;
            while (!rvalid) @(posedge clk);
            data <= rdata;
        end
    endtask

    task wait_done;
        // Poll STATUS until DONE (bit2) set or timeout
        integer timeout;
        reg [31:0] status;
        begin
            timeout = 0;
            status  = 0;
            while (status[2] !== 1'b1 && timeout < 500000) begin
                axil_read(32'h402B_0000, status);
                timeout = timeout + 1;
            end
            if (timeout >= 500000)
                $display("FAIL: wait_done timeout");
        end
    endtask

    // ----------------------------------------------------------------
    // Test sequence
    // ----------------------------------------------------------------
    integer fail_count;
    reg [31:0] rd;

    initial begin
        fail_count = 0;
        @(posedge resetn);
        #100;

        // ---- Test 1: RTC READ ----
        // Write CMD = 01 (RTC_READ)
        axil_write(32'h402B_0004, 32'h00000001);
        wait_done;

        // Check STATUS: DONE=1, ACK_ERR=0
        axil_read(32'h402B_0000, rd);
        if (rd[2] !== 1'b1 || rd[1] !== 1'b0) begin
            $display("FAIL: T1 STATUS expected DONE=1 ACK_ERR=0, got %h", rd);
            fail_count = fail_count + 1;
        end

        // Check RTC registers
        axil_read(32'h402B_0014, rd); // RTC_SEC
        if (rd[7:0] !== 8'h45) begin
            $display("FAIL: T1 RTC_SEC expected 0x45 got 0x%02h", rd[7:0]);
            fail_count = fail_count + 1;
        end

        axil_read(32'h402B_0018, rd); // RTC_MIN
        if (rd[7:0] !== 8'h30) begin
            $display("FAIL: T1 RTC_MIN expected 0x30 got 0x%02h", rd[7:0]);
            fail_count = fail_count + 1;
        end

        axil_read(32'h402B_001C, rd); // RTC_HOUR
        if (rd[7:0] !== 8'h14) begin
            $display("FAIL: T1 RTC_HOUR expected 0x14 got 0x%02h", rd[7:0]);
            fail_count = fail_count + 1;
        end

        axil_read(32'h402B_002C, rd); // RTC_YEAR
        if (rd[7:0] !== 8'h26) begin
            $display("FAIL: T1 RTC_YEAR expected 0x26 got 0x%02h", rd[7:0]);
            fail_count = fail_count + 1;
        end

        // ---- Test 2: EEPROM READ ----
        // Write EE_ADDR = 0x0010
        axil_write(32'h402B_0008, 32'h00000010);
        // Write CMD = 10 (EE_READ)
        axil_write(32'h402B_0004, 32'h00000002);
        wait_done;

        axil_read(32'h402B_0000, rd);
        if (rd[2] !== 1'b1) begin
            $display("FAIL: T2 STATUS DONE not set");
            fail_count = fail_count + 1;
        end

        axil_read(32'h402B_0010, rd); // EE_RDATA
        if (rd[7:0] !== 8'h10) begin
            $display("FAIL: T2 EE_RDATA expected 0x10 got 0x%02h", rd[7:0]);
            fail_count = fail_count + 1;
        end

        // ---- Test 3: EEPROM WRITE ----
        axil_write(32'h402B_0008, 32'h00000020); // EE_ADDR = 0x0020
        axil_write(32'h402B_000C, 32'h000000AB); // EE_WDATA = 0xAB
        axil_write(32'h402B_0004, 32'h00000003); // CMD = 11 (EE_WRITE)
        wait_done;

        // Verify via model memory
        if (ee_mem[15'h0020] !== 8'hAB) begin
            $display("FAIL: T3 EE write data not in model memory");
            fail_count = fail_count + 1;
        end

        // ---- Final verdict ----
        if (fail_count == 0)
            $display("PASS: all tests passed (RTC_READ, EE_READ, EE_WRITE)");
        else
            $display("FAIL: %0d test(s) failed", fail_count);

        $finish;
    end

    // Simulation guard
    initial begin
        #20_000_000;
        $display("FAIL: simulation timeout");
        $finish;
    end

endmodule
`default_nettype wire
