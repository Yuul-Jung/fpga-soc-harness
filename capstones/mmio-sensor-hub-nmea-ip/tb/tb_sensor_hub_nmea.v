// tb_sensor_hub_nmea.v — Self-checking testbench for sensor_hub_top
// Verilog-2001. Outputs "PASS" or "FAIL: <reason>" then $finish.
// Simulation params: CLK_HZ=10_000, I2C_HZ=1_000, BAUD=1_000
//   => I2C_HALF=4 (5 clk/step), BAUD_CNT=9 (10 clk/bit), BAUD_MID=4

`timescale 1ns/1ps

module tb_sensor_hub_nmea;

// ─── Clock / reset ───────────────────────────────────────────────────────────
parameter integer CLK_HZ  = 10_000;
parameter integer I2C_HZ  = 1_000;
parameter integer BAUD    = 1_000;

reg aclk = 0;
always #50 aclk = ~aclk;  // 100 ns period (10 MHz nominal for sim)

reg aresetn = 0;
initial begin
    repeat(8) @(posedge aclk);
    aresetn = 1;
end

// ─── DUT I/O wires ───────────────────────────────────────────────────────────
reg  [15:0] s_awaddr, s_araddr;
reg         s_awvalid, s_wvalid, s_bready, s_arvalid, s_rready;
wire        s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
reg  [31:0] s_wdata;
reg  [ 3:0] s_wstrb;
wire [ 1:0] s_bresp, s_rresp;
wire [31:0] s_rdata;

// I2C open-drain bus
wire i2c_scl_o, i2c_scl_t;
wire i2c_sda_o, i2c_sda_t;
wire i2c_sda_i;

wire uart_rx_w;   // connected to NMEA generator output
wire irq;

// Open-drain wired-AND
wire scl_bus = i2c_scl_t ? 1'b1 : i2c_scl_o;   // master only drives SCL
wire sda_from_master = i2c_sda_t ? 1'b1 : i2c_sda_o;
wire sda_from_slave;
wire sda_bus = sda_from_master & sda_from_slave; // wired-AND
assign i2c_sda_i = sda_bus;

// ─── DUT instantiation ───────────────────────────────────────────────────────
sensor_hub_top #(
    .CLK_HZ    (CLK_HZ),
    .I2C_HZ    (I2C_HZ),
    .BAUD      (BAUD),
    .FIFO_DEPTH(16)
) dut (
    .aclk       (aclk),
    .aresetn    (aresetn),
    .s_awaddr   (s_awaddr),  .s_araddr  (s_araddr),
    .s_awvalid  (s_awvalid), .s_wvalid  (s_wvalid),
    .s_bready   (s_bready),  .s_arvalid (s_arvalid),
    .s_rready   (s_rready),
    .s_awready  (s_awready), .s_wready  (s_wready),
    .s_bvalid   (s_bvalid),  .s_arready (s_arready),
    .s_rvalid   (s_rvalid),
    .s_wdata    (s_wdata),   .s_wstrb   (s_wstrb),
    .s_bresp    (s_bresp),   .s_rresp   (s_rresp),
    .s_rdata    (s_rdata),
    .i2c_scl_o  (i2c_scl_o), .i2c_scl_t (i2c_scl_t),
    .i2c_sda_o  (i2c_sda_o), .i2c_sda_t (i2c_sda_t),
    .i2c_sda_i  (i2c_sda_i),
    .uart_rx    (uart_rx_w),
    .irq        (irq)
);

// ─── AXI4-Lite helper tasks ──────────────────────────────────────────────────
task axil_write;
    input [15:0] addr;
    input [31:0] data;
    begin
        @(posedge aclk);
        s_awaddr  <= addr; s_awvalid <= 1'b1;
        s_wdata   <= data; s_wstrb   <= 4'hF; s_wvalid <= 1'b1;
        s_bready  <= 1'b1;
        // wait for both handshakes
        wait (s_awready && s_awvalid);
        @(posedge aclk);
        s_awvalid <= 1'b0; s_wvalid <= 1'b0;
        wait (s_bvalid);
        @(posedge aclk);
        s_bready <= 1'b0;
    end
endtask

task axil_read;
    input  [15:0] addr;
    output [31:0] data;
    begin
        @(posedge aclk);
        s_araddr  <= addr; s_arvalid <= 1'b1;
        s_rready  <= 1'b1;
        wait (s_arready && s_arvalid);
        @(posedge aclk);
        s_arvalid <= 1'b0;
        wait (s_rvalid);
        data = s_rdata;
        @(posedge aclk);
        s_rready <= 1'b0;
    end
endtask

// ─── I2C slave model (3 devices) ─────────────────────────────────────────────
// Returns: dev 0x68→0xA5, dev 0x76→0x5A, dev 0x1E→0x3C
// Open-drain: drives sda low only when needed; pull high otherwise.
reg sda_slave_drive = 1'b1;  // 1 = release (hi-z), 0 = drive low
assign sda_from_slave = sda_slave_drive ? 1'b1 : 1'b0;

// Slave state
parameter SS_IDLE      = 4'd0;
parameter SS_RADDR_W   = 4'd1;   // receive ADDR+W
parameter SS_RACK_W    = 4'd2;   // send ACK after ADDR+W
parameter SS_RREG      = 4'd3;   // receive REG byte
parameter SS_RACK_REG  = 4'd4;   // send ACK after REG
parameter SS_WAIT_RS   = 4'd5;   // wait for repeated START
parameter SS_RADDR_R   = 4'd6;   // receive ADDR+R
parameter SS_RACK_R    = 4'd7;   // send ACK after ADDR+R
parameter SS_SEND_DATA = 4'd8;   // send data byte
parameter SS_WAIT_NACK = 4'd9;   // receive NACK from master

reg [3:0] ss_state = SS_IDLE;
reg [3:0] ss_bit   = 4'd0;
reg [7:0] ss_shift = 8'd0;
reg [6:0] ss_addr  = 7'd0;
reg [7:0] ss_data  = 8'd0;   // byte to send
reg [7:0] ss_send_shift = 8'd0;
reg [2:0] ss_send_bit   = 3'd0;

// START condition: negedge SDA while SCL HIGH
always @(negedge sda_bus) begin
    if (scl_bus) begin
        // START or repeated-START
        if (ss_state == SS_WAIT_RS) begin
            ss_state       <= SS_RADDR_R;
            ss_bit         <= 4'd0;
            ss_shift       <= 8'd0;
            sda_slave_drive <= 1'b1;
        end else begin
            ss_state       <= SS_RADDR_W;
            ss_bit         <= 4'd0;
            ss_shift       <= 8'd0;
            sda_slave_drive <= 1'b1;
        end
    end
end

// STOP condition: posedge SDA while SCL HIGH
always @(posedge sda_bus) begin
    if (scl_bus) begin
        ss_state        <= SS_IDLE;
        sda_slave_drive <= 1'b1;
    end
end

// Data clock on SCL posedge (sample)
always @(posedge scl_bus) begin
    case (ss_state)
        SS_RADDR_W: begin
            ss_shift <= {ss_shift[6:0], sda_bus};
            if (ss_bit == 4'd7) begin
                ss_addr <= ss_shift[6:0];  // will be valid after this shift
            end
            ss_bit <= ss_bit + 4'd1;
        end
        SS_RREG: begin
            ss_shift <= {ss_shift[6:0], sda_bus};
            ss_bit   <= ss_bit + 4'd1;
        end
        SS_RADDR_R: begin
            ss_shift <= {ss_shift[6:0], sda_bus};
            if (ss_bit == 4'd7) begin
                // load data to send based on addr already captured
                case (ss_addr)
                    7'h68: ss_send_shift <= 8'hA5;
                    7'h76: ss_send_shift <= 8'h5A;
                    7'h1E: ss_send_shift <= 8'h3C;
                    default: ss_send_shift <= 8'hFF;
                endcase
            end
            ss_bit <= ss_bit + 4'd1;
        end
        SS_WAIT_NACK: begin
            // sample NACK bit (master holds SDA high) — just transition
        end
        default: ;
    endcase
end

// Drive on SCL negedge
always @(negedge scl_bus) begin
    case (ss_state)
        SS_RADDR_W: begin
            if (ss_bit == 4'd8) begin
                // Send ACK
                sda_slave_drive <= 1'b0;  // drive low
                ss_state        <= SS_RACK_W;
                ss_bit          <= 4'd0;
                ss_shift        <= 8'd0;
            end
        end
        SS_RACK_W: begin
            sda_slave_drive <= 1'b1;  // release
            ss_state        <= SS_RREG;
            ss_bit          <= 4'd0;
        end
        SS_RREG: begin
            if (ss_bit == 4'd8) begin
                // Send ACK
                sda_slave_drive <= 1'b0;
                ss_state        <= SS_RACK_REG;
                ss_bit          <= 4'd0;
            end
        end
        SS_RACK_REG: begin
            sda_slave_drive <= 1'b1;
            ss_state        <= SS_WAIT_RS;
            // wait for repeated start
        end
        SS_RADDR_R: begin
            if (ss_bit == 4'd8) begin
                // Send ACK
                sda_slave_drive <= 1'b0;
                ss_state        <= SS_RACK_R;
                ss_bit          <= 4'd0;
                ss_send_bit     <= 3'd7;
            end
        end
        SS_RACK_R: begin
            sda_slave_drive <= (ss_send_shift[7] == 1'b0) ? 1'b0 : 1'b1;
            ss_state        <= SS_SEND_DATA;
            ss_send_bit     <= 3'd6;
        end
        SS_SEND_DATA: begin
            if (ss_send_bit == 3'd0) begin
                // last bit driven, next negedge = after data byte, master sends NACK
                sda_slave_drive <= 1'b1;  // release for NACK
                ss_state        <= SS_WAIT_NACK;
            end else begin
                sda_slave_drive <= (ss_send_shift[ss_send_bit] == 1'b0) ? 1'b0 : 1'b1;
                ss_send_bit     <= ss_send_bit - 3'd1;
            end
        end
        SS_WAIT_NACK: begin
            sda_slave_drive <= 1'b1;
            ss_state        <= SS_IDLE;
        end
        default: ;
    endcase
end

// ─── NMEA UART generator ──────────────────────────────────────────────────────
// Sends: "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n"
// BAUD=1_000, CLK_HZ=10_000: 10 clk/bit
parameter integer BIT_PERIOD = CLK_HZ / BAUD;  // 10

reg  uart_tx_reg = 1'b1;
assign uart_rx_w = uart_tx_reg;

task uart_send_byte;
    input [7:0] b;
    integer i;
    begin
        // Start bit
        uart_tx_reg = 1'b0;
        repeat(BIT_PERIOD) @(posedge aclk);
        // 8 data bits LSB-first
        for (i = 0; i < 8; i = i + 1) begin
            uart_tx_reg = b[i];
            repeat(BIT_PERIOD) @(posedge aclk);
        end
        // Stop bit
        uart_tx_reg = 1'b1;
        repeat(BIT_PERIOD) @(posedge aclk);
    end
endtask

task uart_send_str;
    input [0:71*8-1] str;  // up to 71 bytes
    input integer    len;
    integer j;
    begin
        for (j = 0; j < len; j = j + 1)
            uart_send_byte(str[j*8 +: 8]);
    end
endtask

// ─── Timeout watchdog ─────────────────────────────────────────────────────────
integer cycle_cnt = 0;
always @(posedge aclk) begin
    cycle_cnt <= cycle_cnt + 1;
    if (cycle_cnt >= 80_000) begin
        $display("FAIL: timeout after 80000 cycles");
        $finish;
    end
end

// ─── Main test sequence ───────────────────────────────────────────────────────
reg [31:0] rd_data;
reg [31:0] status_val;
integer    poll_cnt;
integer    fail_flag;

initial begin
    // Default AXI signals
    s_awaddr = 0; s_awvalid = 0;
    s_wdata  = 0; s_wstrb   = 0; s_wvalid = 0;
    s_bready = 0;
    s_araddr = 0; s_arvalid = 0;
    s_rready = 0;
    fail_flag = 0;

    // ── Wait for reset release ──
    @(posedge aresetn);
    repeat(4) @(posedge aclk);

    // ── 1) Verify IP_ID ──
    axil_read(16'hFFF0, rd_data);
    if (rd_data !== 32'h534E_5348) begin
        $display("FAIL: IP_ID expected 0x534E5348, got 0x%08X", rd_data);
        $finish;
    end

    // ── 2) Enable scan + NMEA ──
    axil_write(16'h0000, 32'h0000_0005);  // scan_en=1, nmea_en=1

    // ── 3) Start NMEA sender in parallel ──
    // Fork-like: use a separate initial block below (nmea_sender)

    // ── 4) Poll for FIFO not empty (STATUS[0]=0) ──
    poll_cnt = 0;
    begin : FIFO_POLL
        forever begin
            axil_read(16'h0004, status_val);
            if (status_val[0] == 1'b0) disable FIFO_POLL;  // fifo_empty=0 → data ready
            poll_cnt = poll_cnt + 1;
            if (poll_cnt > 2000) begin
                $display("FAIL: FIFO empty after 2000 polls (STATUS=0x%08X)", status_val);
                fail_flag = 1;
                disable FIFO_POLL;
            end
            repeat(2) @(posedge aclk);
        end
    end

    if (!fail_flag) begin
        // ── 5) Read FIFO_DATA and verify non-X ──
        axil_read(16'h0008, rd_data);
        if (^rd_data === 1'bx) begin
            $display("FAIL: FIFO_DATA contains X/Z bits");
            fail_flag = 1;
        end

        // ── 6) Read FIFO_META ──
        axil_read(16'h000C, rd_data);
        if (^rd_data === 1'bx) begin
            $display("FAIL: FIFO_META contains X/Z bits");
            fail_flag = 1;
        end
    end

    if (!fail_flag) begin
        // ── 7) Poll for NMEA line ready (STATUS[3]=1) ──
        poll_cnt = 0;
        begin : NMEA_POLL
            forever begin
                axil_read(16'h0004, status_val);
                if (status_val[3] == 1'b1) disable NMEA_POLL;
                poll_cnt = poll_cnt + 1;
                if (poll_cnt > 3000) begin
                    $display("FAIL: NMEA line not ready after 3000 polls (STATUS=0x%08X)", status_val);
                    fail_flag = 1;
                    disable NMEA_POLL;
                end
                repeat(2) @(posedge aclk);
            end
        end
    end

    if (!fail_flag) begin
        // ── 8) Read NMEA_LEN and verify > 0 ──
        axil_read(16'h0010, rd_data);
        if (rd_data == 32'd0) begin
            $display("FAIL: NMEA_LEN is 0");
            fail_flag = 1;
        end else if (rd_data > 32'd90) begin
            $display("FAIL: NMEA_LEN=%0d exceeds buffer size 90", rd_data);
            fail_flag = 1;
        end
    end

    if (!fail_flag) begin
        // ── 9) Read first NMEA byte (should be 'G'=0x47, body after '$') ──
        axil_read(16'h0014, rd_data);
        if (rd_data[7:0] !== 8'h47) begin
            $display("FAIL: NMEA first byte expected 'G'(0x47), got 0x%02X", rd_data[7:0]);
            fail_flag = 1;
        end
    end

    if (!fail_flag) begin
        // ── 10) Timestamp sanity ──
        axil_read(16'h0018, rd_data);  // TS_HI (latches TS_LO)
        if (^rd_data === 1'bx) begin
            $display("FAIL: TS_HI contains X/Z");
            fail_flag = 1;
        end
        axil_read(16'h001C, rd_data);  // TS_LO
        if (^rd_data === 1'bx) begin
            $display("FAIL: TS_LO contains X/Z");
            fail_flag = 1;
        end
    end

    if (!fail_flag) begin
        // ── 11) W1C IRQ_STATUS ──
        axil_read(16'hFFF8, rd_data);
        if (rd_data[0] !== 1'b1) begin
            $display("FAIL: IRQ_STATUS[0] (fifo_ne) not set, got 0x%08X", rd_data);
            fail_flag = 1;
        end else begin
            // Clear bit 0
            axil_write(16'hFFF8, 32'h0000_0001);
            axil_read(16'hFFF8, rd_data);
            if (rd_data[0] !== 1'b0) begin
                $display("FAIL: IRQ_STATUS[0] not cleared by W1C (got 0x%08X)", rd_data);
                fail_flag = 1;
            end
        end
    end

    if (!fail_flag)
        $display("PASS");
    else
        $display("FAIL: see messages above");

    $finish;
end

// ─── NMEA sender process (runs in parallel with main sequence) ────────────────
// "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\r\n"
// Body (after '$', stored in nmea_buf): "GPGGA,...*47\r"  (nmea_wp counts these)
// Testbench sends full string including '$' and '\n'

// Using byte array approach via reg and task
reg [7:0] nmea_str [0:70];
integer   nmea_idx;

initial begin
    // Wait until reset + enable are done (main process writes CTRL at ~12 clocks after reset)
    @(posedge aresetn);
    repeat(20) @(posedge aclk);  // wait for CTRL write to complete

    // Load NMEA sentence bytes
    nmea_str[ 0] = "$"; nmea_str[ 1] = "G"; nmea_str[ 2] = "P";
    nmea_str[ 3] = "G"; nmea_str[ 4] = "G"; nmea_str[ 5] = "A";
    nmea_str[ 6] = ","; nmea_str[ 7] = "1"; nmea_str[ 8] = "2";
    nmea_str[ 9] = "3"; nmea_str[10] = "5"; nmea_str[11] = "1";
    nmea_str[12] = "9"; nmea_str[13] = ","; nmea_str[14] = "4";
    nmea_str[15] = "8"; nmea_str[16] = "0"; nmea_str[17] = "7";
    nmea_str[18] = "."; nmea_str[19] = "0"; nmea_str[20] = "3";
    nmea_str[21] = "8"; nmea_str[22] = ","; nmea_str[23] = "N";
    nmea_str[24] = ","; nmea_str[25] = "0"; nmea_str[26] = "1";
    nmea_str[27] = "1"; nmea_str[28] = "3"; nmea_str[29] = "1";
    nmea_str[30] = "."; nmea_str[31] = "0"; nmea_str[32] = "0";
    nmea_str[33] = "0"; nmea_str[34] = ","; nmea_str[35] = "E";
    nmea_str[36] = ","; nmea_str[37] = "1"; nmea_str[38] = ",";
    nmea_str[39] = "0"; nmea_str[40] = "8"; nmea_str[41] = ",";
    nmea_str[42] = "0"; nmea_str[43] = "."; nmea_str[44] = "9";
    nmea_str[45] = ","; nmea_str[46] = "5"; nmea_str[47] = "4";
    nmea_str[48] = "5"; nmea_str[49] = "."; nmea_str[50] = "4";
    nmea_str[51] = ","; nmea_str[52] = "M"; nmea_str[53] = ",";
    nmea_str[54] = "4"; nmea_str[55] = "6"; nmea_str[56] = ".";
    nmea_str[57] = "9"; nmea_str[58] = ","; nmea_str[59] = "M";
    nmea_str[60] = ","; nmea_str[61] = ","; nmea_str[62] = "*";
    nmea_str[63] = "4"; nmea_str[64] = "7"; nmea_str[65] = 8'h0D; // CR
    nmea_str[66] = 8'h0A; // LF

    for (nmea_idx = 0; nmea_idx < 67; nmea_idx = nmea_idx + 1) begin
        uart_send_byte(nmea_str[nmea_idx]);
    end
end

endmodule
