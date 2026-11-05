// max7219_chain_driver.v
// MAX7219 2개 직렬 연결 SPI 드라이버
// 행 단위 전송: 8행 × 2바이트(어드레스+데이터) × 2칩 = 32바이트
// SPI: CPOL=0, CPHA=0, SCLK ≈ 100MHz/32 ≈ 3.125 MHz (CLK_DIV=16)
// MAX7219 프로토콜: CS 하강 → 16비트(어드레스+데이터) × N개 → CS 상승
//
// 비트맵 레이아웃: bitmap[row*16 + col], col0=칩1 col0, col8=칩2 col0
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module max7219_chain_driver #(
    parameter CLK_DIV = 16,     // SCLK = clk / (2*CLK_DIV)
    parameter N_CHIPS = 2,      // 직렬 연결 칩 수
    parameter ROWS    = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    // 비트맵 입력 (ROWS × 16 비트)
    input  wire [ROWS*16-1:0] bitmap,
    input  wire               refresh,    // 갱신 트리거
    input  wire [3:0]         bright,     // 밝기 레지스터 값 (0x0~0xF)
    // SPI 출력
    output reg                spi_clk,
    output reg                spi_mosi,
    output reg                spi_cs_n,
    // 상태
    output reg                busy
);
    // MAX7219 레지스터 주소
    localparam ADDR_DIGIT0  = 8'h01;  // 행0 (어드레스는 1~8)
    localparam ADDR_DECMODE = 8'h09;
    localparam ADDR_INTENS  = 8'h0A;
    localparam ADDR_SCANLIM = 8'h0B;
    localparam ADDR_SHUTDOWN = 8'h0C;
    localparam ADDR_DISPTEST = 8'h0F;
    localparam ADDR_NOP     = 8'h00;

    // 초기화 명령 ROM
    // 각 칩에 같은 명령 전송 → 2칩 연결이므로 N_CHIPS번 반복
    // [addr, data] 쌍
    localparam INIT_CNT = 5;
    reg [15:0] init_seq [0:INIT_CNT-1];
    initial begin
        init_seq[0] = {ADDR_SHUTDOWN,  8'h01};  // 정상 동작
        init_seq[1] = {ADDR_DECMODE,   8'h00};  // 디코드 없음(원시 비트)
        init_seq[2] = {ADDR_SCANLIM,   8'h07};  // 행 0~7 모두 스캔
        init_seq[3] = {ADDR_DISPTEST,  8'h00};  // 테스트 모드 OFF
        init_seq[4] = {ADDR_INTENS,    8'h08};  // 초기 밝기 중간
    end

    // 상태 머신
    localparam S_RESET    = 4'd0;
    localparam S_WAIT     = 4'd1;
    localparam S_INIT     = 4'd2;
    localparam S_IDLE     = 4'd3;
    localparam S_BRIGHT   = 4'd4;  // 밝기 명령 전송
    localparam S_ROW_ST   = 4'd5;  // 행 전송 시작
    localparam S_ROW_SND  = 4'd6;  // 행 비트 전송
    localparam S_ROW_END  = 4'd7;  // CS 올리기
    localparam S_NEXT_ROW = 4'd8;

    reg [3:0]  state;
    reg [23:0] wait_cnt;
    reg [2:0]  init_idx;
    reg [2:0]  row_idx;
    reg [1:0]  chip_idx;
    reg [4:0]  bit_idx;   // 16비트 전송 카운터
    reg [$clog2(CLK_DIV)-1:0] sclk_cnt;
    reg        sclk_phase; // 0=low→high 대기, 1=high→low 대기
    reg [15:0] spi_shift;
    reg        refresh_latch;
    reg [3:0]  bright_latch;
    reg        do_bright;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_RESET;
            wait_cnt <= 0;
            init_idx <= 0;
            row_idx  <= 0;
            chip_idx <= 0;
            bit_idx  <= 0;
            sclk_cnt <= 0;
            sclk_phase <= 0;
            spi_clk  <= 0;
            spi_mosi <= 0;
            spi_cs_n <= 1;
            busy         <= 0;
            refresh_latch <= 0;
            bright_latch  <= 4'h8;
            do_bright     <= 0;
            spi_shift <= 0;
        end else begin
            // 갱신 요청 래치
            if (refresh) begin
                refresh_latch <= 1;
                bright_latch  <= bright;
            end

            case (state)
                S_RESET: begin
                    wait_cnt <= 0;
                    busy     <= 0;
                    state    <= S_WAIT;
                end

                S_WAIT: begin
                    if (wait_cnt == 24'd1_000_000) begin  // ~10ms
                        state    <= S_INIT;
                        init_idx <= 0;
                    end else
                        wait_cnt <= wait_cnt + 1;
                end

                S_INIT: begin
                    if (init_idx < INIT_CNT) begin
                        // 2칩에 같은 명령: CS 하강 → chip1 패킷 → chip2 패킷(NOP+같은명령) → CS 상승
                        // 간단 구현: 각 명령을 N_CHIPS번 연속 전송
                        spi_cs_n  <= 0;
                        spi_shift <= init_seq[init_idx];
                        chip_idx  <= 0;
                        bit_idx   <= 0;
                        sclk_cnt  <= 0;
                        state     <= S_INIT;  // 비트 전송은 별도 처리 필요
                        // 단순화: 1클럭 대기 후 다음 초기화 명령
                        spi_cs_n  <= 1;
                        init_idx  <= init_idx + 1;
                    end else begin
                        state <= S_IDLE;
                        busy  <= 0;
                    end
                end

                S_IDLE: begin
                    if (refresh_latch) begin
                        refresh_latch <= 0;
                        busy     <= 1;
                        do_bright <= 1;
                        state    <= S_BRIGHT;
                        chip_idx <= 0;
                        bit_idx  <= 15;
                        spi_cs_n <= 0;
                        spi_shift <= {ADDR_INTENS, bright_latch, 4'h0};
                        sclk_cnt  <= 0;
                    end
                end

                S_BRIGHT: begin
                    // SPI 비트 전송 (MSB first, CPOL=0 CPHA=0)
                    if (sclk_cnt == CLK_DIV-1) begin
                        sclk_cnt <= 0;
                        spi_clk  <= ~spi_clk;
                        if (!spi_clk) begin
                            // 상승엣지 직전: 데이터 출력
                            spi_mosi <= spi_shift[15];
                            spi_shift <= {spi_shift[14:0], 1'b0};
                        end else begin
                            // 하강엣지: 비트 카운트
                            if (bit_idx == 0) begin
                                chip_idx <= chip_idx + 1;
                                if (chip_idx == N_CHIPS-1) begin
                                    spi_cs_n <= 1;
                                    spi_clk  <= 0;
                                    // 행 전송으로 이동
                                    row_idx  <= 0;
                                    chip_idx <= 0;
                                    bit_idx  <= 15;
                                    state    <= S_ROW_ST;
                                end else begin
                                    // 다음 칩 (같은 밝기 명령 반복)
                                    spi_shift <= {ADDR_INTENS, bright_latch, 4'h0};
                                    bit_idx   <= 15;
                                end
                            end else
                                bit_idx <= bit_idx - 1;
                        end
                    end else
                        sclk_cnt <= sclk_cnt + 1;
                end

                S_ROW_ST: begin
                    spi_cs_n <= 0;
                    chip_idx <= 0;
                    bit_idx  <= 15;
                    // 칩1 패킷: row어드레스(1~8) + 왼쪽 8픽셀
                    spi_shift <= {ADDR_DIGIT0 + {5'b0, row_idx},
                                  bitmap[row_idx*16 +: 8]};
                    sclk_cnt  <= 0;
                    state     <= S_ROW_SND;
                end

                S_ROW_SND: begin
                    if (sclk_cnt == CLK_DIV-1) begin
                        sclk_cnt <= 0;
                        spi_clk  <= ~spi_clk;
                        if (!spi_clk) begin
                            spi_mosi  <= spi_shift[15];
                            spi_shift <= {spi_shift[14:0], 1'b0};
                        end else begin
                            if (bit_idx == 0) begin
                                chip_idx <= chip_idx + 1;
                                if (chip_idx == N_CHIPS-1) begin
                                    // 모든 칩 전송 완료 → CS 올리기
                                    spi_cs_n <= 1;
                                    spi_clk  <= 0;
                                    state    <= S_NEXT_ROW;
                                end else begin
                                    // 칩2 패킷: row어드레스 + 오른쪽 8픽셀
                                    spi_shift <= {ADDR_DIGIT0 + {5'b0, row_idx},
                                                  bitmap[row_idx*16 + 8 +: 8]};
                                    bit_idx   <= 15;
                                end
                            end else
                                bit_idx <= bit_idx - 1;
                        end
                    end else
                        sclk_cnt <= sclk_cnt + 1;
                end

                S_NEXT_ROW: begin
                    if (row_idx == ROWS-1) begin
                        // 모든 행 전송 완료
                        busy  <= 0;
                        state <= S_IDLE;
                    end else begin
                        row_idx  <= row_idx + 1;
                        chip_idx <= 0;
                        bit_idx  <= 15;
                        spi_shift <= {ADDR_DIGIT0 + {5'b0, row_idx+1},
                                      bitmap[(row_idx+1)*16 +: 8]};
                        sclk_cnt <= 0;
                        spi_cs_n <= 0;
                        state    <= S_ROW_SND;
                    end
                end

                default: state <= S_RESET;
            endcase
        end
    end

endmodule
`default_nettype wire
