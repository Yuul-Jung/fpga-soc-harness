// axil_7seg_ip.v
// AXI4-Lite 7-Segment Display Advanced IP for Basys3
// HARNESS: mmio-7seg-adv-ip (I-072), free_slot [1F] = 0x401F_0000
// License: MIT
// Features:
//   - Per-digit hex display (0-F) via AXI4-Lite registers
//   - Per-digit blank control (blank[3:0])
//   - Per-digit decimal point control (dp_en[3:0])
//   - 16-step PWM brightness control (bright[3:0])
//   - Parameterized refresh rate and clock
// Verilog-2001 only: compatible with iverilog, verilator, yosys
//
// Register map (base 0x401F_0000):
//   0x00: DATA  [15:12]=d3, [11:8]=d2, [7:4]=d1, [3:0]=d0  (hex 0-F)
//   0x04: CTRL  [3:0]=blank, [7:4]=dp_en, [11:8]=bright, [12]=en
//               reset = 0x00001F0F  (en=1, bright=15, blank=0xF, dp=0)
//
// Output:
//   an[3:0]  : anode select, active-low (Basys3 common-anode)
//   seg[6:0] : cathode bits {g,f,e,d,c,b,a}, active-low
//   dp_out   : decimal point, active-low

`timescale 1ns/1ps

module axil_7seg_ip #(
    parameter CLK_HZ     = 100_000_000, // 100 MHz
    parameter REFRESH_HZ = 1000         // per-digit refresh rate
)(
    // AXI4-Lite slave
    input  wire        aclk,
    input  wire        aresetn,
    // Write address channel
    input  wire [7:0]  awaddr,
    input  wire        awvalid,
    output reg         awready,
    // Write data channel
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        wvalid,
    output reg         wready,
    // Write response channel
    output reg  [1:0]  bresp,
    output reg         bvalid,
    input  wire        bready,
    // Read address channel
    input  wire [7:0]  araddr,
    input  wire        arvalid,
    output reg         arready,
    // Read data channel
    output reg  [31:0] rdata,
    output reg  [1:0]  rresp,
    output reg         rvalid,
    input  wire        rready,
    // 7-segment display outputs (active-low, Basys3 common-anode)
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp_out
);

    // ---------------------------------------------------------------
    // Register bank
    // ---------------------------------------------------------------
    reg [31:0] reg_data; // 0x00
    reg [31:0] reg_ctrl; // 0x04

    // Named fields
    wire [3:0] d3     = reg_data[15:12];
    wire [3:0] d2     = reg_data[11:8];
    wire [3:0] d1     = reg_data[7:4];
    wire [3:0] d0     = reg_data[3:0];
    wire [3:0] blank  = reg_ctrl[3:0];
    wire [3:0] dp_en  = reg_ctrl[7:4];
    wire [3:0] bright = reg_ctrl[11:8];
    wire       en     = reg_ctrl[12];

    // ---------------------------------------------------------------
    // AXI4-Lite write FSM
    // ---------------------------------------------------------------
    reg       aw_lat; // latch write address
    reg [7:0] aw_addr_lat;

    always @(posedge aclk) begin
        if (!aresetn) begin
            awready    <= 1'b0;
            wready     <= 1'b0;
            bvalid     <= 1'b0;
            bresp      <= 2'b00;
            aw_lat     <= 1'b0;
            aw_addr_lat<= 8'h00;
            reg_data   <= 32'h0000_0000;
            reg_ctrl   <= 32'h0000_1F0F; // en=1, bright=15, blank=0xF
        end else begin
            // Defaults
            awready <= 1'b0;
            wready  <= 1'b0;

            // Latch write address
            if (awvalid && !aw_lat) begin
                aw_lat      <= 1'b1;
                aw_addr_lat <= awaddr;
                awready     <= 1'b1;
            end

            // Write data
            if (wvalid && aw_lat) begin
                wready  <= 1'b1;
                aw_lat  <= 1'b0;
                bvalid  <= 1'b1;
                bresp   <= 2'b00;
                // Write to register (byte strobe)
                case (aw_addr_lat[3:2])
                    2'd0: begin
                        if (wstrb[0]) reg_data[7:0]   <= wdata[7:0];
                        if (wstrb[1]) reg_data[15:8]  <= wdata[15:8];
                        if (wstrb[2]) reg_data[23:16] <= wdata[23:16];
                        if (wstrb[3]) reg_data[31:24] <= wdata[31:24];
                    end
                    2'd1: begin
                        if (wstrb[0]) reg_ctrl[7:0]   <= wdata[7:0];
                        if (wstrb[1]) reg_ctrl[15:8]  <= wdata[15:8];
                        if (wstrb[2]) reg_ctrl[23:16] <= wdata[23:16];
                        if (wstrb[3]) reg_ctrl[31:24] <= wdata[31:24];
                    end
                    default: ; // ignore unmapped
                endcase
            end

            // Clear bvalid on handshake
            if (bvalid && bready)
                bvalid <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // AXI4-Lite read FSM
    // ---------------------------------------------------------------
    always @(posedge aclk) begin
        if (!aresetn) begin
            arready <= 1'b0;
            rvalid  <= 1'b0;
            rdata   <= 32'h0;
            rresp   <= 2'b00;
        end else begin
            arready <= 1'b0;
            if (arvalid && !rvalid) begin
                arready <= 1'b1;
                rvalid  <= 1'b1;
                rresp   <= 2'b00;
                case (araddr[3:2])
                    2'd0:    rdata <= reg_data;
                    2'd1:    rdata <= reg_ctrl;
                    default: rdata <= 32'h0;
                endcase
            end
            if (rvalid && rready)
                rvalid <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // Hex-to-7-segment encoder (combinational, active-low output)
    // Segment order: {g, f, e, d, c, b, a}
    // ---------------------------------------------------------------
    function [6:0] hex_to_seg;
        input [3:0] hex;
        case (hex)
            4'h0: hex_to_seg = 7'b100_0000; // 0: a,b,c,d,e,f ON  g OFF
            4'h1: hex_to_seg = 7'b111_1001; // 1: b,c ON
            4'h2: hex_to_seg = 7'b010_0100; // 2: a,b,d,e,g ON
            4'h3: hex_to_seg = 7'b011_0000; // 3: a,b,c,d,g ON
            4'h4: hex_to_seg = 7'b001_1001; // 4: b,c,f,g ON
            4'h5: hex_to_seg = 7'b001_0010; // 5: a,c,d,f,g ON
            4'h6: hex_to_seg = 7'b000_0010; // 6: a,c,d,e,f,g ON
            4'h7: hex_to_seg = 7'b111_1000; // 7: a,b,c ON
            4'h8: hex_to_seg = 7'b000_0000; // 8: all ON
            4'h9: hex_to_seg = 7'b001_0000; // 9: a,b,c,d,f,g ON
            4'hA: hex_to_seg = 7'b000_1000; // A: a,b,c,e,f,g ON
            4'hB: hex_to_seg = 7'b000_0011; // b: c,d,e,f,g ON
            4'hC: hex_to_seg = 7'b100_0110; // C: a,d,e,f ON
            4'hD: hex_to_seg = 7'b010_0001; // d: b,c,d,e,g ON
            4'hE: hex_to_seg = 7'b000_0110; // E: a,d,e,f,g ON
            4'hF: hex_to_seg = 7'b000_1110; // F: a,e,f,g ON
            default: hex_to_seg = 7'b111_1111; // all segments off
        endcase
    endfunction

    wire [6:0] seg_d0 = hex_to_seg(d0);
    wire [6:0] seg_d1 = hex_to_seg(d1);
    wire [6:0] seg_d2 = hex_to_seg(d2);
    wire [6:0] seg_d3 = hex_to_seg(d3);

    // ---------------------------------------------------------------
    // 4-digit multiplexer
    // Refresh at REFRESH_HZ per digit, cycle through 4 digits
    // ---------------------------------------------------------------
    localparam MUX_DIV = CLK_HZ / REFRESH_HZ;
    localparam MUX_BITS = 17; // ceil(log2(100000)) = 17

    reg [MUX_BITS-1:0] mux_cnt;
    reg [1:0]          digit_sel; // 0..3

    always @(posedge aclk) begin
        if (!aresetn) begin
            mux_cnt   <= 0;
            digit_sel <= 2'd0;
        end else begin
            if (mux_cnt >= MUX_DIV - 1) begin
                mux_cnt   <= 0;
                digit_sel <= digit_sel + 1'b1;
            end else begin
                mux_cnt <= mux_cnt + 1'b1;
            end
        end
    end

    // ---------------------------------------------------------------
    // PWM brightness generator
    // 16 levels: duty = (bright+1)/16 of each digit period
    // bright=0: 1/16, bright=15: 16/16=100%
    // PWM_STEP = MUX_DIV / 16 = 6250 cycles per brightness level
    // pwm_cnt increments every PWM_STEP cycles within each digit slot
    // ---------------------------------------------------------------
    localparam PWM_BITS = 4;
    localparam PWM_STEP = MUX_DIV >> PWM_BITS; // 6250 — no multiplier needed
    // ceil(log2(6250)) = 13 bits for step counter
    reg [PWM_BITS-1:0] pwm_cnt;
    reg [12:0]         pwm_step_cnt;

    always @(posedge aclk) begin
        if (!aresetn) begin
            pwm_cnt      <= 4'd0;
            pwm_step_cnt <= 13'd0;
        end else if (mux_cnt == 0) begin
            // Reset both counters at every digit boundary
            pwm_cnt      <= 4'd0;
            pwm_step_cnt <= 13'd0;
        end else begin
            if (pwm_step_cnt >= PWM_STEP - 1) begin
                pwm_step_cnt <= 13'd0;
                pwm_cnt      <= pwm_cnt + 1'b1;
            end else begin
                pwm_step_cnt <= pwm_step_cnt + 13'd1;
            end
        end
    end

    // PWM gate: HIGH when pwm_cnt <= bright (duty cycle)
    wire pwm_gate = (pwm_cnt <= bright);

    // ---------------------------------------------------------------
    // Anode and segment mux output
    // ---------------------------------------------------------------
    reg [3:0] an_reg;
    reg [6:0] seg_reg;
    reg       dp_reg;

    always @(*) begin
        // Default: all off
        an_reg  = 4'b1111;
        seg_reg = 7'b111_1111;
        dp_reg  = 1'b1;

        if (en && pwm_gate) begin
            case (digit_sel)
                2'd0: begin
                    an_reg  = blank[0] ? 4'b1111 : 4'b1110;
                    seg_reg = blank[0] ? 7'b111_1111 : seg_d0;
                    dp_reg  = blank[0] ? 1'b1 : ~dp_en[0];
                end
                2'd1: begin
                    an_reg  = blank[1] ? 4'b1111 : 4'b1101;
                    seg_reg = blank[1] ? 7'b111_1111 : seg_d1;
                    dp_reg  = blank[1] ? 1'b1 : ~dp_en[1];
                end
                2'd2: begin
                    an_reg  = blank[2] ? 4'b1111 : 4'b1011;
                    seg_reg = blank[2] ? 7'b111_1111 : seg_d2;
                    dp_reg  = blank[2] ? 1'b1 : ~dp_en[2];
                end
                2'd3: begin
                    an_reg  = blank[3] ? 4'b1111 : 4'b0111;
                    seg_reg = blank[3] ? 7'b111_1111 : seg_d3;
                    dp_reg  = blank[3] ? 1'b1 : ~dp_en[3];
                end
            endcase
        end
    end

    assign an     = an_reg;
    assign seg    = seg_reg;
    assign dp_out = dp_reg;

endmodule
