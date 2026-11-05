// jstk2_spi.v — PmodJSTK2 SPI 마스터 (5바이트 전이중 교환)
// 하네스 원본 (외부 코드 포함 없음)
// SPI Mode 0 (CPOL=0, CPHA=0), 클럭 100 MHz → 50 클럭 토글 → 1 MHz SCLK
// 5바이트 TX: {0x01, 0x00, 0x00, 0x00, 0x00}  RX: {X_L, X_H, Y_L, Y_H, BTN}
// sample_period: 100 ms 샘플링 주기 (파라미터)
`default_nettype none

module jstk2_spi #(
    parameter CLK_FREQ_HZ    = 100_000_000,
    parameter SPI_CLK_HZ     =   1_000_000,
    parameter SAMPLE_PERIOD_MS = 100       // 샘플링 주기 (ms)
) (
    input  wire       clk,
    input  wire       rst_n,
    // 활성화
    input  wire       en,          // 1=샘플링 활성
    // 결과 레지스터
    output reg [9:0]  jstk_x,
    output reg [9:0]  jstk_y,
    output reg [1:0]  jstk_btn,
    output reg        sample_done, // 1클럭 펄스, 새 샘플 도착
    // SPI 포트
    output reg        spi_cs_n,
    output reg        spi_sclk,
    output reg        spi_mosi,
    input  wire       spi_miso
);

localparam SCLK_DIV    = CLK_FREQ_HZ / SPI_CLK_HZ / 2; // 50 클럭 per 반주기
localparam SAMPLE_CNT  = CLK_FREQ_HZ / 1000 * SAMPLE_PERIOD_MS; // 샘플 주기 클럭 수
localparam N_BYTES     = 5;
localparam N_BITS      = N_BYTES * 8; // 40

// 상태 머신
localparam S_IDLE    = 2'd0;
localparam S_ASSERT  = 2'd1; // CS# 하강 후 1 클럭 대기
localparam S_XFER    = 2'd2; // 비트 전송
localparam S_DONE    = 2'd3; // CS# 해제

reg [1:0]  state;
reg [26:0] period_cnt;    // 샘플 주기 카운터
reg [5:0]  div_cnt;       // SCLK 분주 카운터 (0~49)
reg [5:0]  bit_cnt;       // 전송 비트 카운터 (0~39)
reg        sclk_phase;    // 0=low, 1=high
reg [39:0] tx_shift;      // TX 쉬프트 레지스터
reg [39:0] rx_shift;      // RX 쉬프트 레지스터

// TX 데이터 고정: {0x01, 0x00, 0x00, 0x00, 0x00}
localparam [39:0] TX_DATA = 40'h01_00_00_00_00;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= S_IDLE;
        period_cnt  <= 27'd0;
        div_cnt     <= 6'd0;
        bit_cnt     <= 6'd0;
        sclk_phase  <= 1'b0;
        tx_shift    <= 40'd0;
        rx_shift    <= 40'd0;
        spi_cs_n    <= 1'b1;
        spi_sclk    <= 1'b0;
        spi_mosi    <= 1'b0;
        jstk_x      <= 10'd512;
        jstk_y      <= 10'd512;
        jstk_btn    <= 2'b00;
        sample_done <= 1'b0;
    end else begin
        sample_done <= 1'b0; // 기본 소거

        case (state)
            S_IDLE: begin
                spi_cs_n   <= 1'b1;
                spi_sclk   <= 1'b0;
                if (!en) begin
                    period_cnt <= 27'd0;
                end else if (period_cnt >= SAMPLE_CNT - 1) begin
                    period_cnt <= 27'd0;
                    state      <= S_ASSERT;
                    tx_shift   <= TX_DATA;
                    rx_shift   <= 40'd0;
                    bit_cnt    <= 6'd0;
                    div_cnt    <= 6'd0;
                    sclk_phase <= 1'b0;
                end else begin
                    period_cnt <= period_cnt + 1'b1;
                end
            end

            S_ASSERT: begin
                // CS# 활성(LOW), 최소 1 클럭 대기
                spi_cs_n <= 1'b0;
                spi_mosi <= tx_shift[39]; // MSB first
                state    <= S_XFER;
                div_cnt  <= 6'd0;
            end

            S_XFER: begin
                if (div_cnt < SCLK_DIV - 1) begin
                    div_cnt <= div_cnt + 1'b1;
                end else begin
                    div_cnt    <= 6'd0;
                    sclk_phase <= ~sclk_phase;
                    spi_sclk   <= ~sclk_phase; // 현재 반주기 반전

                    if (!sclk_phase) begin
                        // 하강에지(SCLK 1→0): 다음 MOSI 준비
                        if (bit_cnt < N_BITS - 1) begin
                            bit_cnt  <= bit_cnt + 1'b1;
                            tx_shift <= {tx_shift[38:0], 1'b0};
                            spi_mosi <= tx_shift[38];
                        end
                    end else begin
                        // 상승에지(SCLK 0→1): MISO 샘플
                        rx_shift <= {rx_shift[38:0], spi_miso};
                        if (bit_cnt == N_BITS - 1) begin
                            state <= S_DONE;
                        end
                    end
                end
            end

            S_DONE: begin
                spi_cs_n <= 1'b1;
                spi_sclk <= 1'b0;
                // 수신 데이터 파싱: RX = {X_L, X_H, Y_L, Y_H, BTN}
                // X = {X_H[1:0], X_L[7:0]} (10비트)
                // Y = {Y_H[1:0], Y_L[7:0]} (10비트)
                // BTN = BTN_BYTE[1:0]
                jstk_x   <= {rx_shift[30:29], rx_shift[39:32]}; // {X_H[1:0], X_L}
                jstk_y   <= {rx_shift[22:21], rx_shift[31:24]}; // {Y_H[1:0], Y_L}
                jstk_btn <= rx_shift[17:16];                     // BTN 바이트 [1:0]
                sample_done <= 1'b1;
                state    <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule
`default_nettype wire
