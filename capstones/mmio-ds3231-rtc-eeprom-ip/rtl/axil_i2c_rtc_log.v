// axil_i2c_rtc_log.v
// AXI4-Lite slave + I2C master for DS3231 RTC and 24LC256 EEPROM
// Verilog-2001. Pure RTL, no IP cores.
// Part of mmio-ds3231-rtc-eeprom-ip capstone (fpga-soc-harness).
//
// I2C clock: CLK_HZ / (2 * HALF_PERIOD) = 100e6 / (2*250) = 200 kHz
// Set HALF_PERIOD=125 for 400 kHz if SCL rise time allows.
//
// Register map (base 0x402B_0000, 32-bit word offset):
//   0x00  STATUS  [RO]  bit0=BUSY bit1=ACK_ERR bit2=DONE
//   0x04  CMD     [WO]  bit1:0  00=NOP 01=RTC_READ 10=EE_READ 11=EE_WRITE
//   0x08  EE_ADDR [RW]  EEPROM word address [14:0]
//   0x0C  EE_WDATA[RW]  EEPROM write data  [7:0]
//   0x10  EE_RDATA[RO]  EEPROM read  data  [7:0]
//   0x14  RTC_SEC [RO]  seconds  BCD
//   0x18  RTC_MIN [RO]  minutes  BCD
//   0x1C  RTC_HOUR[RO]  hours    BCD 24h
//   0x20  RTC_DAY [RO]  day-of-week [2:0]
//   0x24  RTC_DATE[RO]  date     BCD
//   0x28  RTC_MON [RO]  month    BCD
//   0x2C  RTC_YEAR[RO]  year     BCD 00-99

`default_nettype none
`timescale 1ns/1ps

module axil_i2c_rtc_log #(
    parameter CLK_HZ     = 100_000_000,
    parameter HALF_PERIOD = 250          // SCL half-period in clock cycles
) (
    // AXI4-Lite slave
    input  wire        s_aclk,
    input  wire        s_aresetn,
    // Write address channel
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,
    // Write data channel
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,
    // Write response channel
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,
    // Read address channel
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_ararready,
    // Read data channel
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,
    // I2C
    output reg         scl_o,
    output reg         scl_oe,   // 1=drive low, 0=tristate (pull-up high)
    input  wire        scl_i,
    output reg         sda_o,
    output reg         sda_oe,
    input  wire        sda_i
);

    // -----------------------------------------------------------------
    // Internal registers
    // -----------------------------------------------------------------
    reg        busy_r;
    reg        ack_err_r;
    reg        done_r;
    reg  [1:0] cmd_r;         // latched CMD
    reg [14:0] ee_addr_r;
    reg  [7:0] ee_wdata_r;
    reg  [7:0] ee_rdata_r;
    reg  [7:0] rtc_sec_r, rtc_min_r, rtc_hour_r;
    reg  [2:0] rtc_day_r;
    reg  [7:0] rtc_date_r, rtc_mon_r, rtc_year_r;

    // -----------------------------------------------------------------
    // AXI4-Lite write address/data latch
    // -----------------------------------------------------------------
    reg [31:0] aw_addr_latch;
    reg [31:0] w_data_latch;
    reg        aw_pending, w_pending;

    always @(posedge s_aclk) begin
        if (!s_aresetn) begin
            s_awready  <= 1'b1;
            s_wready   <= 1'b1;
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;
            s_bvalid   <= 1'b0;
            s_bresp    <= 2'b00;
        end else begin
            // Accept write address
            if (s_awvalid && s_awready) begin
                aw_addr_latch <= s_awaddr;
                aw_pending    <= 1'b1;
                s_awready     <= 1'b0;
            end
            // Accept write data
            if (s_wvalid && s_wready) begin
                w_data_latch <= s_wdata;
                w_pending    <= 1'b1;
                s_wready     <= 1'b0;
            end
            // Process once both channels received
            if (aw_pending && w_pending && !s_bvalid) begin
                // Decode address bits [5:2] → register index
                case (aw_addr_latch[5:2])
                    4'h1: begin // CMD (0x04) — only writable when not busy
                        if (!busy_r) begin
                            cmd_r   <= w_data_latch[1:0];
                            done_r  <= 1'b0;
                            ack_err_r <= 1'b0;
                        end
                    end
                    4'h2: ee_addr_r  <= w_data_latch[14:0]; // EE_ADDR
                    4'h3: ee_wdata_r <= w_data_latch[7:0];  // EE_WDATA
                    default: ; // read-only registers: ignore
                endcase
                s_bvalid   <= 1'b1;
                s_bresp    <= 2'b00;
                aw_pending <= 1'b0;
                w_pending  <= 1'b0;
                s_awready  <= 1'b1;
                s_wready   <= 1'b1;
            end
            if (s_bvalid && s_bready) s_bvalid <= 1'b0;
        end
    end

    // -----------------------------------------------------------------
    // AXI4-Lite read
    // -----------------------------------------------------------------
    always @(posedge s_aclk) begin
        if (!s_aresetn) begin
            s_ararready <= 1'b1;
            s_rvalid    <= 1'b0;
            s_rdata     <= 32'b0;
            s_rresp     <= 2'b00;
        end else begin
            if (s_arvalid && s_ararready) begin
                s_ararready <= 1'b0;
                case (s_araddr[5:2])
                    4'h0: s_rdata <= {29'b0, done_r, ack_err_r, busy_r};
                    4'h2: s_rdata <= {17'b0, ee_addr_r};
                    4'h3: s_rdata <= {24'b0, ee_wdata_r};
                    4'h4: s_rdata <= {24'b0, ee_rdata_r};
                    4'h5: s_rdata <= {24'b0, rtc_sec_r};
                    4'h6: s_rdata <= {24'b0, rtc_min_r};
                    4'h7: s_rdata <= {24'b0, rtc_hour_r};
                    4'h8: s_rdata <= {29'b0, rtc_day_r};
                    4'h9: s_rdata <= {24'b0, rtc_date_r};
                    4'hA: s_rdata <= {24'b0, rtc_mon_r};
                    4'hB: s_rdata <= {24'b0, rtc_year_r};
                    default: s_rdata <= 32'hDEAD_BEEF;
                endcase
                s_rvalid <= 1'b1;
                s_rresp  <= 2'b00;
            end
            if (s_rvalid && s_rready) begin
                s_rvalid    <= 1'b0;
                s_ararready <= 1'b1;
            end
        end
    end

    // -----------------------------------------------------------------
    // I2C Bit Master FSM
    // -----------------------------------------------------------------
    // States for the bit-level I2C engine
    localparam [4:0]
        BS_IDLE   = 5'd0,
        BS_START1 = 5'd1,  // SDA low while SCL high
        BS_START2 = 5'd2,  // SCL low
        BS_DATA_SCL_LO = 5'd3,
        BS_DATA_SET_SDA= 5'd4,
        BS_DATA_SCL_HI = 5'd5,
        BS_DATA_SAMPLE = 5'd6,
        BS_DATA_SCL_LO2= 5'd7,
        BS_ACK_SCL_LO  = 5'd8,
        BS_ACK_RELEASE = 5'd9,
        BS_ACK_SCL_HI  = 5'd10,
        BS_ACK_CHECK   = 5'd11,
        BS_ACK_SCL_LO2 = 5'd12,
        BS_STOP1  = 5'd13, // SCL high
        BS_STOP2  = 5'd14; // SDA high

    // High-level transaction FSM
    localparam [4:0]
        TS_IDLE        = 5'd0,
        TS_RTC_START   = 5'd1,
        TS_RTC_ADDR    = 5'd2,
        TS_RTC_REG     = 5'd3,
        TS_RTC_RSTART  = 5'd4,
        TS_RTC_RADDR   = 5'd5,
        TS_RTC_RBYTES  = 5'd6,
        TS_RTC_STOP    = 5'd7,
        TS_EE_START    = 5'd8,
        TS_EE_ADDR     = 5'd9,
        TS_EE_MSBADDR  = 5'd10,
        TS_EE_LSBADDR  = 5'd11,
        TS_EE_WBYTE    = 5'd12,
        TS_EE_RSTART   = 5'd13,
        TS_EE_RADDR    = 5'd14,
        TS_EE_RBYTE    = 5'd15,
        TS_EE_STOP     = 5'd16,
        TS_DONE        = 5'd17;

    reg [4:0]  ts_state;
    reg [4:0]  bs_state;
    reg [7:0]  i2c_tx_byte;    // byte to transmit
    reg [7:0]  i2c_rx_byte;    // received byte accumulator
    reg [2:0]  bit_cnt;        // bit counter 7..0
    reg        tx_bit;         // current bit being sent
    reg        rx_ack;         // 0=ACK received
    reg        read_mode;      // 1 during byte receive
    reg [$clog2(HALF_PERIOD)-1:0] clk_cnt;
    reg        bit_done;       // pulse: bit-level op complete
    reg        byte_done;      // pulse: byte (8 bits + ack) complete
    reg [3:0]  rtc_byte_idx;   // 0..6 for RTC read

    // half-period counter helper
    wire hp_tick = (clk_cnt == HALF_PERIOD[($clog2(HALF_PERIOD)-1):0] - 1);

    // Reset / initialise I2C lines
    always @(posedge s_aclk) begin
        if (!s_aresetn) begin
            scl_o  <= 1'b1; scl_oe <= 1'b0;
            sda_o  <= 1'b1; sda_oe <= 1'b0;
            clk_cnt<= 0;
            bs_state  <= BS_IDLE;
            ts_state  <= TS_IDLE;
            busy_r    <= 1'b0;
            ack_err_r <= 1'b0;
            done_r    <= 1'b0;
            cmd_r     <= 2'b00;
            bit_done  <= 1'b0;
            byte_done <= 1'b0;
            rtc_byte_idx <= 0;
            ee_rdata_r   <= 8'b0;
            {rtc_sec_r, rtc_min_r, rtc_hour_r} <= 24'b0;
            {rtc_day_r, rtc_date_r, rtc_mon_r, rtc_year_r} <= 32'b0;
        end else begin
            bit_done  <= 1'b0;
            byte_done <= 1'b0;
            clk_cnt   <= hp_tick ? 0 : clk_cnt + 1;

            // ---- Transaction FSM ----
            case (ts_state)
                TS_IDLE: begin
                    if (cmd_r != 2'b00 && !busy_r) begin
                        busy_r   <= 1'b1;
                        bs_state <= BS_START1;
                        case (cmd_r)
                            2'b01: begin ts_state <= TS_RTC_START; i2c_tx_byte <= 8'hD0; end // DS3231 write addr
                            2'b10: begin ts_state <= TS_EE_START;  i2c_tx_byte <= 8'hA0; end // 24LC256 write addr
                            2'b11: begin ts_state <= TS_EE_START;  i2c_tx_byte <= 8'hA0; end
                            default:;
                        endcase
                    end
                end

                // ---- RTC READ path ----
                TS_RTC_START: begin
                    if (bit_done) begin
                        ts_state     <= TS_RTC_ADDR;
                        i2c_tx_byte  <= 8'hD0; // DS3231 addr+W
                        bs_state     <= BS_DATA_SCL_LO;
                        bit_cnt      <= 3'd7;
                        read_mode    <= 1'b0;
                    end
                end
                TS_RTC_ADDR: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state    <= TS_RTC_REG;
                        i2c_tx_byte <= 8'h00; // register 0x00 = seconds
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b0;
                    end
                end
                TS_RTC_REG: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state    <= TS_RTC_RSTART;
                        bs_state    <= BS_START1; // repeated start
                    end
                end
                TS_RTC_RSTART: begin
                    if (bit_done) begin
                        ts_state    <= TS_RTC_RADDR;
                        i2c_tx_byte <= 8'hD1; // DS3231 addr+R
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b0;
                        rtc_byte_idx<= 4'd0;
                    end
                end
                TS_RTC_RADDR: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state    <= TS_RTC_RBYTES;
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b1;
                    end
                end
                TS_RTC_RBYTES: begin
                    if (byte_done) begin
                        // Store received byte
                        case (rtc_byte_idx)
                            4'd0: rtc_sec_r  <= i2c_rx_byte;
                            4'd1: rtc_min_r  <= i2c_rx_byte;
                            4'd2: rtc_hour_r <= i2c_rx_byte & 8'h3F; // mask century/12h bits
                            4'd3: rtc_day_r  <= i2c_rx_byte[2:0];
                            4'd4: rtc_date_r <= i2c_rx_byte;
                            4'd5: rtc_mon_r  <= i2c_rx_byte & 8'h1F;
                            4'd6: rtc_year_r <= i2c_rx_byte;
                            default:;
                        endcase
                        rtc_byte_idx <= rtc_byte_idx + 1;
                        if (rtc_byte_idx == 4'd6) begin
                            ts_state  <= TS_RTC_STOP;
                            bs_state  <= BS_STOP1;
                            read_mode <= 1'b0;
                        end else begin
                            bs_state  <= BS_DATA_SCL_LO;
                            bit_cnt   <= 3'd7;
                            read_mode <= 1'b1;
                        end
                    end
                end
                TS_RTC_STOP: begin
                    if (bit_done) ts_state <= TS_DONE;
                end

                // ---- EEPROM path (read or write) ----
                TS_EE_START: begin
                    if (bit_done) begin
                        ts_state    <= TS_EE_ADDR;
                        i2c_tx_byte <= 8'hA0; // 24LC256 addr+W
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b0;
                    end
                end
                TS_EE_ADDR: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state    <= TS_EE_MSBADDR;
                        i2c_tx_byte <= {1'b0, ee_addr_r[14:8]}; // MSB of word addr
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b0;
                    end
                end
                TS_EE_MSBADDR: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state    <= TS_EE_LSBADDR;
                        i2c_tx_byte <= ee_addr_r[7:0];
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b0;
                    end
                end
                TS_EE_LSBADDR: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        if (cmd_r == 2'b11) begin // EE_WRITE
                            ts_state    <= TS_EE_WBYTE;
                            i2c_tx_byte <= ee_wdata_r;
                            bs_state    <= BS_DATA_SCL_LO;
                            bit_cnt     <= 3'd7;
                            read_mode   <= 1'b0;
                        end else begin // EE_READ: repeated start
                            ts_state    <= TS_EE_RSTART;
                            bs_state    <= BS_START1;
                        end
                    end
                end
                TS_EE_WBYTE: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state  <= TS_EE_STOP;
                        bs_state  <= BS_STOP1;
                    end
                end
                TS_EE_RSTART: begin
                    if (bit_done) begin
                        ts_state    <= TS_EE_RADDR;
                        i2c_tx_byte <= 8'hA1; // 24LC256 addr+R
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b0;
                    end
                end
                TS_EE_RADDR: begin
                    if (byte_done) begin
                        if (rx_ack !== 1'b0) ack_err_r <= 1'b1;
                        ts_state    <= TS_EE_RBYTE;
                        bs_state    <= BS_DATA_SCL_LO;
                        bit_cnt     <= 3'd7;
                        read_mode   <= 1'b1;
                    end
                end
                TS_EE_RBYTE: begin
                    if (byte_done) begin
                        ee_rdata_r <= i2c_rx_byte;
                        ts_state   <= TS_EE_STOP;
                        bs_state   <= BS_STOP1;
                        read_mode  <= 1'b0;
                    end
                end
                TS_EE_STOP: begin
                    if (bit_done) ts_state <= TS_DONE;
                end

                TS_DONE: begin
                    done_r   <= 1'b1;
                    busy_r   <= 1'b0;
                    cmd_r    <= 2'b00;
                    ts_state <= TS_IDLE;
                    bs_state <= BS_IDLE;
                end

                default: ts_state <= TS_IDLE;
            endcase

            // ---- Bit-level I2C engine ----
            if (hp_tick) begin
                case (bs_state)
                    BS_IDLE: begin
                        scl_oe <= 1'b0; sda_oe <= 1'b0;
                    end
                    // START: SDA falls while SCL high
                    BS_START1: begin
                        scl_oe <= 1'b0;  // SCL high (released)
                        sda_oe <= 1'b1;  // SDA driven low
                        bs_state <= BS_START2;
                    end
                    BS_START2: begin
                        scl_oe   <= 1'b1; // SCL low
                        bs_state <= BS_IDLE; // let TS_FSM advance
                        bit_done <= 1'b1;
                    end
                    // Data bit: SCL low phase, set SDA
                    BS_DATA_SCL_LO: begin
                        tx_bit   <= read_mode ? 1'b1 : i2c_tx_byte[bit_cnt];
                        sda_oe   <= read_mode ? 1'b0 : !i2c_tx_byte[bit_cnt];
                        bs_state <= BS_DATA_SCL_HI;
                    end
                    BS_DATA_SCL_HI: begin
                        scl_oe   <= 1'b0; // SCL high
                        bs_state <= BS_DATA_SAMPLE;
                    end
                    BS_DATA_SAMPLE: begin
                        if (read_mode) i2c_rx_byte <= {i2c_rx_byte[6:0], sda_i};
                        bs_state <= BS_DATA_SCL_LO2;
                    end
                    BS_DATA_SCL_LO2: begin
                        scl_oe <= 1'b1; // SCL low
                        if (bit_cnt == 3'd0) begin
                            // After 8 bits → ACK phase
                            bs_state <= BS_ACK_SCL_LO;
                        end else begin
                            bit_cnt  <= bit_cnt - 1;
                            bs_state <= BS_DATA_SCL_LO;
                        end
                    end
                    // ACK: master releases SDA, slave drives low for ACK
                    BS_ACK_SCL_LO: begin
                        sda_oe   <= 1'b0; // release SDA
                        bs_state <= BS_ACK_RELEASE;
                    end
                    BS_ACK_RELEASE: begin
                        scl_oe   <= 1'b0; // SCL high
                        bs_state <= BS_ACK_CHECK;
                    end
                    BS_ACK_CHECK: begin
                        rx_ack   <= sda_i; // 0=ACK
                        bs_state <= BS_ACK_SCL_LO2;
                    end
                    BS_ACK_SCL_LO2: begin
                        scl_oe    <= 1'b1; // SCL low
                        byte_done <= 1'b1;
                        bs_state  <= BS_IDLE;
                    end
                    // STOP: SDA rises while SCL high
                    BS_STOP1: begin
                        sda_oe   <= 1'b1;  // SDA low first
                        scl_oe   <= 1'b0;  // SCL high
                        bs_state <= BS_STOP2;
                    end
                    BS_STOP2: begin
                        sda_oe   <= 1'b0;  // SDA released → high
                        bs_state <= BS_IDLE;
                        bit_done <= 1'b1;
                    end
                    default: bs_state <= BS_IDLE;
                endcase
            end
        end
    end

endmodule
`default_nettype wire
