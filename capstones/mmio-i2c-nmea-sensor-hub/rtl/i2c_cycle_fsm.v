// i2c_cycle_fsm.v
// I2C bit-bang master FSM: cycles through 3 device addresses
// Devices: MPU-6050(0x68), BMP280(0x76), HMC5883L(0x1E)
// Reads 6 bytes from each device register 0x3B (or device default start)
// 100 kHz I2C @ 100 MHz clock (each bit = 1000 cycles, 250 per phase)
// Verilog-2001

`timescale 1ns/1ps

module i2c_cycle_fsm #(
    parameter DEFAULT_PERIOD = 32'd10_000_000 // 100 ms cycle period
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] period_cfg,

    // I2C open-drain interface
    output reg         scl_o,
    output reg         scl_oe,   // 1=drive SCL low
    output reg         sda_o,
    output reg         sda_oe,   // 1=drive SDA low
    input  wire        sda_i,

    // Status
    output reg         busy,

    // Sample output
    output reg  [7:0]  dev_type,      // 0=MPU-6050, 1=BMP280, 2=HMC5883L
    output reg  [47:0] raw_data,      // 6 bytes
    output reg         sample_valid   // one-cycle pulse
);

    // Device address table: 3 devices × 7-bit I2C address
    // MPU-6050: 0x68, BMP280: 0x76, HMC5883L: 0x1E
    // Data register to start read: 0x3B for MPU, 0xF7 for BMP, 0x03 for HMC
    localparam [6:0] ADDR_MPU  = 7'h68;
    localparam [6:0] ADDR_BMP  = 7'h76;
    localparam [6:0] ADDR_HMC  = 7'h1E;
    localparam [7:0] REG_MPU   = 8'h3B;
    localparam [7:0] REG_BMP   = 8'hF7;
    localparam [7:0] REG_HMC   = 8'h03;

    // I2C bit timing: 100 kHz = 1000 cycles/bit at 100 MHz
    // 4 phases per bit: 250 cycles each
    localparam CLK_PER_PHASE = 10'd250;

    // FSM states
    localparam [4:0]
        S_IDLE       = 5'd0,
        S_WAIT       = 5'd1,
        S_START      = 5'd2,
        S_ADDR_W     = 5'd3,  // send addr+W (7 bit + 0)
        S_ACK_AW     = 5'd4,
        S_REG_BYTE   = 5'd5,
        S_ACK_REG    = 5'd6,
        S_RESTART    = 5'd7,
        S_ADDR_R     = 5'd8,  // send addr+R (7 bit + 1)
        S_ACK_AR     = 5'd9,
        S_DATA_BYTE  = 5'd10,
        S_MASTER_ACK = 5'd11,
        S_STOP       = 5'd12,
        S_PUSH       = 5'd13;

    reg [4:0]  state;
    reg [31:0] period_cnt;      // cycle timer
    reg [9:0]  phase_cnt;       // sub-bit phase counter
    reg [1:0]  phase;           // 0=SCL-low, 1=SCL-rise, 2=SCL-high, 3=SCL-fall
    reg [3:0]  bit_cnt;         // bits sent/received in current byte
    reg [2:0]  byte_cnt;        // bytes received (0-5)
    reg [1:0]  dev_idx;         // 0,1,2 device index
    reg [7:0]  tx_byte;         // byte being shifted out
    reg [7:0]  rx_byte;         // byte being shifted in
    reg [47:0] data_buf;        // accumulate 6 bytes

    // Combinational: current device address and register
    reg [6:0] cur_addr;
    reg [7:0] cur_reg;

    always @(*) begin
        case (dev_idx)
            2'd0: begin cur_addr = ADDR_MPU; cur_reg = REG_MPU; end
            2'd1: begin cur_addr = ADDR_BMP; cur_reg = REG_BMP; end
            default: begin cur_addr = ADDR_HMC; cur_reg = REG_HMC; end
        endcase
    end

    // Phase counter drives SCL
    always @(posedge clk) begin
        if (!rst_n) begin
            phase_cnt <= 10'd0;
            phase     <= 2'd0;
            scl_o     <= 1'b1;
            scl_oe    <= 1'b0;
            sda_o     <= 1'b1;
            sda_oe    <= 1'b0;
        end
    end

    // Main FSM
    always @(posedge clk) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            period_cnt   <= 32'd0;
            phase_cnt    <= 10'd0;
            phase        <= 2'd0;
            bit_cnt      <= 4'd0;
            byte_cnt     <= 3'd0;
            dev_idx      <= 2'd0;
            busy         <= 1'b0;
            sample_valid <= 1'b0;
            dev_type     <= 8'd0;
            raw_data     <= 48'd0;
            data_buf     <= 48'd0;
            tx_byte      <= 8'd0;
            rx_byte      <= 8'd0;
            scl_oe       <= 1'b0;
            sda_oe       <= 1'b0;
        end else begin
            sample_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy       <= 1'b0;
                    scl_oe     <= 1'b0;
                    sda_oe     <= 1'b0;
                    period_cnt <= 32'd0;
                    if (en) state <= S_WAIT;
                end

                S_WAIT: begin
                    if (!en) begin
                        state <= S_IDLE;
                    end else if (period_cnt >= period_cfg) begin
                        period_cnt <= 32'd0;
                        state      <= S_START;
                        busy       <= 1'b1;
                        phase_cnt  <= 10'd0;
                        phase      <= 2'd0;
                        byte_cnt   <= 3'd0;
                        data_buf   <= 48'd0;
                    end else begin
                        period_cnt <= period_cnt + 1'b1;
                    end
                end

                // START condition: SDA falls while SCL high
                S_START: begin
                    sda_oe <= 1'b1;  // pull SDA low
                    scl_oe <= 1'b0;  // SCL stays high
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        scl_oe    <= 1'b1; // pull SCL low
                        state     <= S_ADDR_W;
                        bit_cnt   <= 4'd0;
                        tx_byte   <= {cur_addr, 1'b0}; // addr + Write
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                // Send 8-bit byte (MSB first), then read ACK
                S_ADDR_W,
                S_REG_BYTE,
                S_ADDR_R: begin
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        phase     <= phase + 1'b1;
                        case (phase)
                            2'd0: begin // SCL low: set SDA
                                sda_oe <= ~tx_byte[7];
                                tx_byte <= {tx_byte[6:0], 1'b0};
                            end
                            2'd1: scl_oe <= 1'b0; // SCL rise
                            2'd2: ; // SCL high: hold
                            2'd3: begin // SCL fall
                                scl_oe <= 1'b1;
                                bit_cnt <= bit_cnt + 1'b1;
                                if (bit_cnt == 4'd7) begin
                                    // move to ACK state
                                    sda_oe <= 1'b0; // release SDA for ACK
                                    case (state)
                                        S_ADDR_W: state <= S_ACK_AW;
                                        S_REG_BYTE: state <= S_ACK_REG;
                                        S_ADDR_R:   state <= S_ACK_AR;
                                        default: state <= S_IDLE;
                                    endcase
                                    bit_cnt <= 4'd0;
                                end
                            end
                        endcase
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                // ACK: read SDA on SCL high
                S_ACK_AW,
                S_ACK_REG,
                S_ACK_AR: begin
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        phase     <= phase + 1'b1;
                        case (phase)
                            2'd1: scl_oe <= 1'b0; // SCL rise
                            2'd2: ; // read ACK (sda_i should be 0 for ACK)
                            2'd3: begin
                                scl_oe <= 1'b1;
                                // proceed regardless of NACK (best-effort)
                                case (state)
                                    S_ACK_AW: begin
                                        state   <= S_REG_BYTE;
                                        tx_byte <= cur_reg;
                                        bit_cnt <= 4'd0;
                                    end
                                    S_ACK_REG: state <= S_RESTART;
                                    S_ACK_AR: begin
                                        state    <= S_DATA_BYTE;
                                        byte_cnt <= 3'd0;
                                        rx_byte  <= 8'd0;
                                        bit_cnt  <= 4'd0;
                                        sda_oe   <= 1'b0;
                                    end
                                    default: state <= S_STOP;
                                endcase
                            end
                            default: ;
                        endcase
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                // Repeated START
                S_RESTART: begin
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        phase     <= phase + 1'b1;
                        case (phase)
                            2'd0: sda_oe <= 1'b0; // SDA high (release)
                            2'd1: scl_oe <= 1'b0; // SCL high
                            2'd2: sda_oe <= 1'b1; // SDA falls (START)
                            2'd3: begin
                                scl_oe  <= 1'b1;  // SCL low
                                state   <= S_ADDR_R;
                                tx_byte <= {cur_addr, 1'b1}; // addr + Read
                                bit_cnt <= 4'd0;
                            end
                        endcase
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                // Receive 6 data bytes
                S_DATA_BYTE: begin
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        phase     <= phase + 1'b1;
                        case (phase)
                            2'd0: ; // SCL low
                            2'd1: scl_oe <= 1'b0; // SCL rise
                            2'd2: begin // sample SDA
                                rx_byte <= {rx_byte[6:0], sda_i};
                            end
                            2'd3: begin // SCL fall
                                scl_oe  <= 1'b1;
                                bit_cnt <= bit_cnt + 1'b1;
                                if (bit_cnt == 4'd7) begin
                                    // Store byte
                                    data_buf <= {data_buf[39:0], rx_byte};
                                    rx_byte  <= 8'd0;
                                    bit_cnt  <= 4'd0;
                                    state    <= S_MASTER_ACK;
                                end
                            end
                        endcase
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                // Send ACK (after bytes 0-4) or NACK (after byte 5)
                S_MASTER_ACK: begin
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        phase     <= phase + 1'b1;
                        case (phase)
                            2'd0: begin
                                // ACK=0 (pull SDA), NACK=1 (release) for last byte
                                sda_oe <= (byte_cnt < 3'd5) ? 1'b1 : 1'b0;
                            end
                            2'd1: scl_oe <= 1'b0;
                            2'd2: ;
                            2'd3: begin
                                scl_oe   <= 1'b1;
                                byte_cnt <= byte_cnt + 1'b1;
                                if (byte_cnt == 3'd5) begin
                                    state <= S_STOP;
                                end else begin
                                    state <= S_DATA_BYTE;
                                end
                            end
                        endcase
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                // STOP condition: SDA rises while SCL high
                S_STOP: begin
                    if (phase_cnt >= CLK_PER_PHASE) begin
                        phase_cnt <= 10'd0;
                        phase     <= phase + 1'b1;
                        case (phase)
                            2'd0: sda_oe <= 1'b1; // SDA low
                            2'd1: scl_oe <= 1'b0; // SCL high
                            2'd2: sda_oe <= 1'b0; // SDA rises (STOP)
                            2'd3: state  <= S_PUSH;
                        endcase
                    end else begin
                        phase_cnt <= phase_cnt + 1'b1;
                    end
                end

                S_PUSH: begin
                    raw_data     <= data_buf;
                    dev_type     <= {5'd0, dev_idx};
                    sample_valid <= 1'b1;
                    dev_idx      <= (dev_idx == 2'd2) ? 2'd0 : dev_idx + 1'b1;
                    state        <= S_WAIT;
                    busy         <= 1'b0;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
