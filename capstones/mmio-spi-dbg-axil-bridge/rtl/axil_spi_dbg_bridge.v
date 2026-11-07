// axil_spi_dbg_bridge.v
// SPI slave (CPOL=0 CPHA=0 mode-0) → AXI4-Lite master debug bridge
//
// Frame format (8 bytes, MSB first on MOSI):
//   B0: CMD  (0x01=write, 0x02=read, others ignored)
//   B1: ADDR[23:16]
//   B2: ADDR[15:8]
//   B3: ADDR[7:0]   → AXI address = {8'h40, ADDR[23:0]}  (covers 0x4000_0000 .. 0x40FF_FFFF)
//   B4: DATA[31:24]
//   B5: DATA[23:16]
//   B6: DATA[15:8]
//   B7: DATA[7:0]
//
// MISO response (8 bytes, MSB first):
//   Write: all 0x00
//   Read:  B0-B3 = 0x00, B4-B7 = rdata[31:0]
//          AXI read is issued after B3; must complete before B4 starts.
//          Safe at f_sck ≤ f_aclk/10 with AXI slave latency ≤ 2 cycles.
//
// Verilog-2001 style, compatible with iverilog / verilator / yosys.

`timescale 1ns / 1ps

module axil_spi_dbg_bridge (
    input  wire        aclk,
    input  wire        aresetn,

    // SPI slave interface (Pmod JA, 3.3 V)
    input  wire        sck,
    input  wire        mosi,
    output reg         miso,
    input  wire        csn,

    // AXI4-Lite master interface
    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,

    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wvalid,
    input  wire        m_wready,

    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output reg         m_bready,

    output reg  [31:0] m_araddr,
    output reg         m_arvalid,
    input  wire        m_arready,

    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rvalid,
    output reg         m_rready,

    // Status
    output reg         busy
);

// -----------------------------------------------------------------------
// 2-stage synchronizers: SPI → aclk domain
// -----------------------------------------------------------------------
reg [1:0] sck_s, csn_s, mosi_s;
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        sck_s  <= 2'b11;
        csn_s  <= 2'b11;
        mosi_s <= 2'b00;
    end else begin
        sck_s  <= {sck_s[0],  sck};
        csn_s  <= {csn_s[0],  csn};
        mosi_s <= {mosi_s[0], mosi};
    end
end

wire sck_rise = (sck_s  == 2'b01);
wire sck_fall = (sck_s  == 2'b10);
wire csn_fall = (csn_s  == 2'b10);

// -----------------------------------------------------------------------
// SPI receive / transmit
// -----------------------------------------------------------------------
reg [2:0]  bit_cnt;    // counts bits 0..7 within a byte
reg [3:0]  byte_cnt;   // frame byte index 0..7
reg [7:0]  rx_shift;   // MOSI shift reg (MSB arrives first → shift left)
reg [7:0]  tx_load;    // next byte value to load into tx_shift

// Frame storage
reg [7:0]  r_cmd;
reg [23:0] r_addr;
reg [31:0] r_wdata;
reg [31:0] r_rdata;    // latched AXI read result

// Handshake pulses between SPI FSM and AXI FSM
reg  spi_do_rd;
reg  spi_do_wr;

// AXI read done flag (set when rvalid accepted, cleared on CSN fall)
reg  axi_rd_done;

// Return the byte to transmit for each frame position
function [7:0] tx_byte_for;
    input [3:0] bidx;
    input [31:0] rdata;
    case (bidx)
        4'd4: tx_byte_for = rdata[31:24];
        4'd5: tx_byte_for = rdata[23:16];
        4'd6: tx_byte_for = rdata[15:8];
        4'd7: tx_byte_for = rdata[7:0];
        default: tx_byte_for = 8'h00;
    endcase
endfunction

// -----------------------------------------------------------------------
// SPI FSM (runs in aclk domain, edge-detected on synchronized SPI signals)
// -----------------------------------------------------------------------
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        bit_cnt     <= 3'd0;
        byte_cnt    <= 4'd0;
        rx_shift    <= 8'h00;
        miso        <= 1'b0;
        r_cmd       <= 8'h00;
        r_addr      <= 24'h00;
        r_wdata     <= 32'h0;
        spi_do_rd   <= 1'b0;
        spi_do_wr   <= 1'b0;
        axi_rd_done <= 1'b0;
    end else begin
        // Clear single-cycle pulses
        spi_do_rd <= 1'b0;
        spi_do_wr <= 1'b0;

        // CSN falling edge: start new frame
        if (csn_fall) begin
            bit_cnt     <= 3'd0;
            byte_cnt    <= 4'd0;
            rx_shift    <= 8'h00;
            miso        <= 1'b0;   // B0 response is 0x00; MSB=0 is driven early
            axi_rd_done <= 1'b0;
        end

        // Sample MOSI on SCK rising edge (MSB arrives on first SCK rise)
        if (sck_rise && !csn_s[1]) begin
            rx_shift <= {rx_shift[6:0], mosi_s[1]};
        end

        // Latch AXI read result when available (can arrive during B4..B7 window)
        if (m_rvalid && m_rready) begin
            r_rdata     <= m_rdata;
            axi_rd_done <= 1'b1;
        end

        // SCK falling edge: advance bit counter, process completed byte,
        // drive next MISO bit
        if (sck_fall && !csn_s[1]) begin
            if (bit_cnt != 3'd7) begin
                // Mid-byte: shift out next MISO bit
                bit_cnt <= bit_cnt + 3'd1;
                miso    <= tx_load[6 - bit_cnt];  // drive next bit (bit 6, 5, ... 1)
            end else begin
                // Byte complete
                bit_cnt <= 3'd0;

                // Decode received byte
                case (byte_cnt)
                    4'd0: r_cmd        <= rx_shift;
                    4'd1: r_addr[23:16] <= rx_shift;
                    4'd2: r_addr[15:8]  <= rx_shift;
                    4'd3: begin
                        r_addr[7:0] <= rx_shift;
                        // Issue AXI read now (address is complete)
                        if (r_cmd == 8'h02) spi_do_rd <= 1'b1;
                    end
                    4'd4: r_wdata[31:24] <= rx_shift;
                    4'd5: r_wdata[23:16] <= rx_shift;
                    4'd6: r_wdata[15:8]  <= rx_shift;
                    4'd7: begin
                        r_wdata[7:0] <= rx_shift;
                        if (r_cmd == 8'h01) spi_do_wr <= 1'b1;
                    end
                    default: ;
                endcase

                byte_cnt <= byte_cnt + 4'd1;

                // Pre-load next TX byte MSB onto MISO
                // (master samples on the NEXT rising SCK edge)
                miso    <= tx_byte_for(byte_cnt + 4'd1, r_rdata)[7];
                tx_load <= tx_byte_for(byte_cnt + 4'd1, r_rdata);
            end
        end
    end
end

// -----------------------------------------------------------------------
// AXI4-Lite master FSM
// -----------------------------------------------------------------------
localparam AXI_IDLE    = 3'd0;
localparam AXI_RD_ADDR = 3'd1;
localparam AXI_RD_DATA = 3'd2;
localparam AXI_WR_ADDR = 3'd3;
localparam AXI_WR_DATA = 3'd4;
localparam AXI_WR_RESP = 3'd5;

reg [2:0] axi_st;
// latch addr at the moment we receive the pulse (SPI FSM may update r_addr after)
reg [31:0] axi_addr_latch;
reg [31:0] axi_wdata_latch;

// Track whether aw and w channels have been accepted
reg aw_done, w_done;

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        axi_st         <= AXI_IDLE;
        m_awaddr       <= 32'd0;
        m_awvalid      <= 1'b0;
        m_wdata        <= 32'd0;
        m_wstrb        <= 4'hF;
        m_wvalid       <= 1'b0;
        m_bready       <= 1'b0;
        m_araddr       <= 32'd0;
        m_arvalid      <= 1'b0;
        m_rready       <= 1'b0;
        busy           <= 1'b0;
        axi_addr_latch <= 32'd0;
        axi_wdata_latch<= 32'd0;
        aw_done        <= 1'b0;
        w_done         <= 1'b0;
    end else begin
        case (axi_st)
            AXI_IDLE: begin
                busy <= 1'b0;
                if (spi_do_rd) begin
                    // Latch address: upper 8 bits fixed at 0x40
                    axi_addr_latch <= {8'h40, r_addr[23:0]};
                    axi_st         <= AXI_RD_ADDR;
                    busy           <= 1'b1;
                end else if (spi_do_wr) begin
                    axi_addr_latch  <= {8'h40, r_addr[23:0]};
                    axi_wdata_latch <= r_wdata;
                    axi_st          <= AXI_WR_ADDR;
                    busy            <= 1'b1;
                    aw_done         <= 1'b0;
                    w_done          <= 1'b0;
                end
            end

            // --- Read path ---
            AXI_RD_ADDR: begin
                m_araddr  <= axi_addr_latch;
                m_arvalid <= 1'b1;
                if (m_arvalid && m_arready) begin
                    m_arvalid <= 1'b0;
                    m_rready  <= 1'b1;
                    axi_st    <= AXI_RD_DATA;
                end
            end

            AXI_RD_DATA: begin
                if (m_rvalid && m_rready) begin
                    m_rready <= 1'b0;
                    axi_st   <= AXI_IDLE;
                    busy     <= 1'b0;
                    // r_rdata is updated in SPI FSM via m_rvalid && m_rready
                end
            end

            // --- Write path ---
            AXI_WR_ADDR: begin
                // Drive AW and W simultaneously (AXI4-Lite allows this)
                m_awaddr  <= axi_addr_latch;
                m_awvalid <= !aw_done;
                m_wdata   <= axi_wdata_latch;
                m_wstrb   <= 4'hF;
                m_wvalid  <= !w_done;

                if (m_awvalid && m_awready) begin
                    m_awvalid <= 1'b0;
                    aw_done   <= 1'b1;
                end
                if (m_wvalid && m_wready) begin
                    m_wvalid <= 1'b0;
                    w_done   <= 1'b1;
                end

                // Both channels accepted: wait for B response
                if ((aw_done || (m_awvalid && m_awready)) &&
                    (w_done  || (m_wvalid  && m_wready))) begin
                    m_awvalid <= 1'b0;
                    m_wvalid  <= 1'b0;
                    m_bready  <= 1'b1;
                    axi_st    <= AXI_WR_RESP;
                end
            end

            AXI_WR_RESP: begin
                if (m_bvalid && m_bready) begin
                    m_bready <= 1'b0;
                    axi_st   <= AXI_IDLE;
                    busy     <= 1'b0;
                end
            end

            default: axi_st <= AXI_IDLE;
        endcase
    end
end

endmodule
