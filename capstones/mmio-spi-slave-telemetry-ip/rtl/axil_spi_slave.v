// axil_spi_slave.v — AXI4-Lite SPI Slave IP
// SPI 모드0(CPOL=0 CPHA=0), 8비트 프레임, 주소[7:0]+데이터[7:0] 2바이트 R/W 프로토콜
// TX FIFO 4엔트리 / RX FIFO 4엔트리 / STATUS / CTRL 레지스터
// CDC: SCLK → sys_clk 더블 플립플롭 동기화
// 원본: capstones/mmio-spi-slave-telemetry-ip/rtl/axil_spi_slave.v

`timescale 1ns/1ps
`default_nettype none

module axil_spi_slave #(
    parameter BASE_ADDR  = 32'h401A_0000,
    parameter FIFO_DEPTH = 4
)(
    // 시스템 클럭/리셋
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    // AXI4-Lite 슬레이브 포트
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // SPI 슬레이브 포트 (외부 — Pmod JA)
    input  wire        spi_sclk,   // SPI 클럭 (ESP32 마스터)
    input  wire        spi_mosi,   // 마스터 → 슬레이브
    output wire        spi_miso,   // 슬레이브 → 마스터
    input  wire        spi_cs_n    // 칩 선택 액티브 로우
);

    // =========================================================
    // SPI 도메인 → sys_clk 도메인 CDC (더블 플립플롭 동기화)
    // =========================================================
    reg [1:0] sclk_sync, mosi_sync, cs_n_sync;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            sclk_sync <= 2'b00;
            mosi_sync <= 2'b00;
            cs_n_sync <= 2'b11;
        end else begin
            sclk_sync <= {sclk_sync[0], spi_sclk};
            mosi_sync <= {mosi_sync[0], spi_mosi};
            cs_n_sync <= {cs_n_sync[0], spi_cs_n};
        end
    end
    wire sclk_rise = (sclk_sync == 2'b01);  // SCLK 상승 에지 검출 (모드0: 샘플)
    wire sclk_fall = (sclk_sync == 2'b10);  // SCLK 하강 에지 검출 (모드0: 시프트)
    wire cs_active = !cs_n_sync[1];

    // =========================================================
    // SPI 수신 FSM — 2바이트 프레임: [addr_byte][data_byte]
    // =========================================================
    reg [3:0]  spi_bit_cnt;   // 비트 카운터 (0~15)
    reg [7:0]  spi_addr_byte; // 첫 번째 바이트 (주소 + R/W 플래그)
    reg [7:0]  spi_data_byte; // 두 번째 바이트 (데이터)
    reg [7:0]  spi_shift_in;  // 수신 시프트 레지스터
    reg [7:0]  spi_shift_out; // 송신 시프트 레지스터
    reg        spi_frame_done; // 2바이트 수신 완료 펄스 (1클럭)
    reg        spi_rd_request; // READ 요청 플래그

    // TX FIFO (4엔트리, 8비트)
    reg [7:0]  tx_fifo [0:FIFO_DEPTH-1];
    reg [1:0]  tx_rd_ptr, tx_wr_ptr;
    reg [2:0]  tx_cnt;         // 0~4
    wire       tx_full  = (tx_cnt == FIFO_DEPTH);
    wire       tx_empty = (tx_cnt == 0);

    // RX FIFO (4엔트리, 8비트)
    reg [7:0]  rx_fifo [0:FIFO_DEPTH-1];
    reg [1:0]  rx_rd_ptr, rx_wr_ptr;
    reg [2:0]  rx_cnt;         // 0~4
    wire       rx_valid = (rx_cnt > 0);

    // ---- SPI 시프트 레지스터 ----
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            spi_bit_cnt   <= 4'd0;
            spi_shift_in  <= 8'd0;
            spi_shift_out <= 8'd0;
            spi_addr_byte <= 8'd0;
            spi_data_byte <= 8'd0;
            spi_frame_done <= 1'b0;
            spi_rd_request <= 1'b0;
            tx_rd_ptr <= 2'd0;
        end else begin
            spi_frame_done <= 1'b0;
            if (!cs_active) begin
                // CS 비활성 — 초기화
                spi_bit_cnt   <= 4'd0;
                spi_shift_in  <= 8'd0;
                // MISO에 TX FIFO 첫 엔트리 프리로드
                spi_shift_out <= tx_empty ? 8'hFF : tx_fifo[tx_rd_ptr];
            end else begin
                if (sclk_rise) begin
                    // 샘플 (모드0: SCLK 상승에서 MOSI 캡처)
                    spi_shift_in <= {spi_shift_in[6:0], mosi_sync[1]};
                    spi_bit_cnt  <= spi_bit_cnt + 1'b1;

                    if (spi_bit_cnt == 4'd7) begin
                        // 첫 번째 바이트 완료 — 주소 바이트
                        spi_addr_byte <= {spi_shift_in[6:0], mosi_sync[1]};
                        spi_rd_request <= spi_shift_in[6]; // 수신 바이트 MSB (bit7): 1=읽기, 0=쓰기
                    end else if (spi_bit_cnt == 4'd15) begin
                        // 두 번째 바이트 완료 — 데이터 바이트
                        spi_data_byte  <= {spi_shift_in[6:0], mosi_sync[1]};
                        spi_frame_done <= 1'b1;
                        spi_bit_cnt    <= 4'd0;
                    end
                end
                if (sclk_fall) begin
                    // 시프트 아웃 (모드0: SCLK 하강에서 MISO 출력)
                    spi_shift_out <= {spi_shift_out[6:0], 1'b0};
                end
            end
        end
    end

    // MISO 출력: 시프트 레지스터 MSB
    assign spi_miso = cs_active ? spi_shift_out[7] : 1'bz;

    // =========================================================
    // RX FIFO 쓰기 (SPI 프레임 완료 시)
    // =========================================================
    integer k;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            rx_rd_ptr <= 2'd0;
            rx_wr_ptr <= 2'd0;
            rx_cnt    <= 3'd0;
            for (k = 0; k < FIFO_DEPTH; k = k + 1)
                rx_fifo[k] <= 8'd0;
        end else begin
            if (spi_frame_done && !spi_rd_request) begin
                // WRITE 프레임: 데이터를 RX FIFO에 적재
                if (rx_cnt < FIFO_DEPTH) begin
                    rx_fifo[rx_wr_ptr] <= spi_data_byte;
                    rx_wr_ptr <= rx_wr_ptr + 1'b1;
                    rx_cnt    <= rx_cnt + 1'b1;
                end
            end
            // AXI 측 RX FIFO 클리어 (CTRL[0])
            if (axil_rx_clear) begin
                rx_rd_ptr <= 2'd0;
                rx_wr_ptr <= 2'd0;
                rx_cnt    <= 3'd0;
            end
        end
    end

    // =========================================================
    // TX FIFO 쓰기 (AXI4-Lite)
    // =========================================================
    reg axil_tx_clear;
    reg axil_rx_clear;
    reg axil_write_en;
    reg [7:0]  axil_waddr;
    reg [31:0] axil_wdata;

    // TX FIFO 쓰기
    integer j;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            tx_wr_ptr <= 2'd0;
            tx_cnt    <= 3'd0;
            for (j = 0; j < FIFO_DEPTH; j = j + 1)
                tx_fifo[j] <= 8'd0;
        end else begin
            if (axil_write_en && axil_waddr[7:4] == 4'h0) begin
                // TX_DATA_0..3 (오프셋 0x00..0x0C)
                case (axil_waddr[3:2])
                    2'd0: tx_fifo[0] <= axil_wdata[7:0];
                    2'd1: tx_fifo[1] <= axil_wdata[7:0];
                    2'd2: tx_fifo[2] <= axil_wdata[7:0];
                    2'd3: tx_fifo[3] <= axil_wdata[7:0];
                endcase
            end
            if (axil_tx_clear) begin
                tx_rd_ptr <= 2'd0;
                tx_wr_ptr <= 2'd0;
                tx_cnt    <= 3'd0;
            end
        end
    end

    // =========================================================
    // AXI4-Lite 쓰기 채널
    // =========================================================
    reg [7:0] wr_addr_lat;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            axil_write_en <= 1'b0;
            axil_tx_clear <= 1'b0;
            axil_rx_clear <= 1'b0;
            axil_waddr    <= 8'd0;
            axil_wdata    <= 32'd0;
            wr_addr_lat   <= 8'd0;
        end else begin
            axil_write_en <= 1'b0;
            axil_tx_clear <= 1'b0;
            axil_rx_clear <= 1'b0;

            // AWREADY 핸드쉐이크
            if (!s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
                wr_addr_lat   <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // WREADY 핸드쉐이크
            if (!s_axi_wready && s_axi_wvalid) begin
                s_axi_wready  <= 1'b1;
                axil_waddr    <= wr_addr_lat;
                axil_wdata    <= s_axi_wdata;
                axil_write_en <= 1'b1;
                // CTRL 처리 (오프셋 0x24)
                if (wr_addr_lat == 8'h24) begin
                    axil_rx_clear <= s_axi_wdata[0];
                    axil_tx_clear <= s_axi_wdata[1];
                end
            end else begin
                s_axi_wready <= 1'b0;
            end

            // BVALID/BREADY
            if (axil_write_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // =========================================================
    // AXI4-Lite 읽기 채널
    // =========================================================
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'd0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr)
                    8'h00: s_axi_rdata <= {24'd0, tx_fifo[0]};
                    8'h04: s_axi_rdata <= {24'd0, tx_fifo[1]};
                    8'h08: s_axi_rdata <= {24'd0, tx_fifo[2]};
                    8'h0C: s_axi_rdata <= {24'd0, tx_fifo[3]};
                    8'h10: s_axi_rdata <= {24'd0, rx_fifo[0]};
                    8'h14: s_axi_rdata <= {24'd0, rx_fifo[1]};
                    8'h18: s_axi_rdata <= {24'd0, rx_fifo[2]};
                    8'h1C: s_axi_rdata <= {24'd0, rx_fifo[3]};
                    8'h20: s_axi_rdata <= {29'd0, cs_active, tx_full, rx_valid};
                    8'h24: s_axi_rdata <= 32'd0; // CTRL write-only
                    default: begin
                        s_axi_rdata <= 32'hDEAD_BEEF;
                        s_axi_rresp <= 2'b10; // SLVERR
                    end
                endcase
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
