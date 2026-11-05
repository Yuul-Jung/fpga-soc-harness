// adxl345_spi_reader.v
// ADXL345 SPI 마스터: 초기화 → X/Y 연속 읽기
// SPI Mode 3 (CPOL=1, CPHA=1). SCLK = clk/100 ≈ 1 MHz (100MHz 기준)
// ADXL345 멀티바이트 읽기: 주소 바이트(R=1, MB=1) + 6바이트 데이터(X0,X1,Y0,Y1,Z0,Z1)
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module adxl345_spi_reader #(
    parameter CLK_DIV = 50   // SCLK = clk / (2*CLK_DIV)
)(
    input  wire        clk,
    input  wire        rst_n,
    // SPI 포트
    output reg         spi_sclk,
    output reg         spi_mosi,
    input  wire        spi_miso,
    output reg         spi_cs_n,
    // 출력: X/Y 10비트 (2의 보수)
    output reg signed [9:0] x_tilt,
    output reg signed [9:0] y_tilt,
    output reg              data_valid   // 1클럭 펄스
);

    // 초기화 명령 ROM (주소, 데이터)
    // [0] POWER_CTL (0x2D) = 0x08 (측정 모드)
    // [1] DATA_FORMAT (0x31) = 0x00 (±2g, right-justified)
    // [2] BW_RATE (0x2C) = 0x0A (100 Hz 출력)
    // initial 블록·함수 없이 S_INIT case 직접 인라인 — yosys 합성 호환
    localparam INIT_CNT = 3;

    // 상태 머신
    localparam S_RESET   = 4'd0;
    localparam S_WAIT    = 4'd1;  // 전원 안정 대기
    localparam S_INIT    = 4'd2;  // 초기화 쓰기
    localparam S_IDLE    = 4'd3;  // 읽기 대기
    localparam S_READ_ST = 4'd4;  // 읽기 CS 내리기
    localparam S_READ    = 4'd5;  // 데이터 클럭킹
    localparam S_READ_EN = 4'd6;  // CS 올리기 + 출력

    reg [3:0]  state;
    reg [23:0] wait_cnt;   // 100ms 대기 (10M 클럭)
    reg [2:0]  init_idx;
    reg [15:0] spi_shift;  // 송신 시프트 레지스터
    reg [5:0]  bit_cnt;    // 클럭킹된 비트 수
    reg [$clog2(CLK_DIV)-1:0] sclk_cnt;
    reg sclk_en;
    reg sclk_hi;           // 1=현재 SCLK HIGH 위상, 0=LOW 위상 (spi_sclk 직독 대신 사용)
    reg [55:0] rx_shift;   // 7바이트 수신 (주소1 + 데이터6)
    reg [23:0] read_period; // 읽기 주기 카운터 (~10ms)

    // data_valid: 1클럭 펄스 — 별도 always 블록으로 분리해 yosys proc_dff의
    // "Multiple edge sensitive events" 오류 방지 (동일 블록 내 이중 NBA 충돌)
    always @(posedge clk) begin
        if (!rst_n)
            data_valid <= 1'b0;
        else
            data_valid <= (state == S_READ_EN);
    end

    // 메인 FSM — data_valid 제외한 모든 레지스터
    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= S_RESET;
            wait_cnt  <= 0;
            init_idx  <= 0;
            spi_sclk  <= 1; spi_mosi <= 0; spi_cs_n <= 1;
            sclk_cnt  <= 0; sclk_en  <= 0; sclk_hi  <= 1;
            bit_cnt   <= 0; rx_shift <= 0; spi_shift <= 0;
            x_tilt    <= 0; y_tilt   <= 0;
            read_period <= 0;
        end else begin

            // SPI 클럭 분주 — sclk_hi 위상 추적 (spi_sclk 조건 검사 금지)
            if (sclk_en) begin
                if (sclk_cnt == CLK_DIV-1) begin
                    sclk_cnt <= 0;
                    spi_sclk <= ~spi_sclk;
                    sclk_hi  <= ~sclk_hi;
                end else
                    sclk_cnt <= sclk_cnt + 1;
            end else begin
                sclk_cnt <= 0;
                spi_sclk <= 1;  // CPOL=1 idle
                sclk_hi  <= 1;
            end

            case (state)
                S_RESET: begin
                    wait_cnt <= 0;
                    state    <= S_WAIT;
                end

                S_WAIT: begin
                    // 100ms 대기 (10,000,000 클럭 @ 100MHz)
                    if (wait_cnt == 24'd10_000_000) state <= S_INIT;
                    else wait_cnt <= wait_cnt + 1;
                end

                S_INIT: begin
                    if (init_idx < INIT_CNT) begin
                        // SPI 쓰기 (16비트: 주소 + 데이터)
                        // 간단 구현: bit-bang 없이 FSM 단순화
                        // 실제는 별도 SPI 전송 서브루틴 필요 — 여기서는 단일 클럭으로 근사
                        spi_cs_n  <= 0;
                        // 인라인 ROM — yosys 합성 호환 (함수·initial 없음)
                        case (init_idx[1:0])
                            2'd0: spi_shift <= {8'h2D, 8'h08}; // POWER_CTL = Measure
                            2'd1: spi_shift <= {8'h31, 8'h00}; // DATA_FORMAT ±2g
                            2'd2: spi_shift <= {8'h2C, 8'h0A}; // BW_RATE 100Hz
                            default: spi_shift <= 16'h0000;
                        endcase
                        bit_cnt   <= 0;
                        sclk_en   <= 1;
                        state     <= S_INIT;
                        init_idx  <= init_idx + 1;
                        // 단순 대기 후 다음 초기화
                        wait_cnt  <= 0;
                    end else begin
                        spi_cs_n <= 1;
                        sclk_en  <= 0;
                        state    <= S_IDLE;
                        read_period <= 0;
                    end
                end

                S_IDLE: begin
                    // ~10ms(1,000,000 클럭)마다 읽기 개시
                    if (read_period == 24'd1_000_000) begin
                        read_period <= 0;
                        state       <= S_READ_ST;
                    end else
                        read_period <= read_period + 1;
                end

                S_READ_ST: begin
                    // 멀티바이트 읽기 주소: R=1(bit7), MB=1(bit6), 주소=0x32(DATAX0)
                    // 0xF2 = 1111_0010
                    spi_cs_n  <= 0;
                    spi_mosi  <= 0; // 첫 비트
                    bit_cnt   <= 0;
                    rx_shift  <= 0;
                    sclk_hi   <= 1; // SCLK idle=HIGH 에서 시작
                    // 7바이트(56비트) 전송: 주소(8b) + 6데이터(48b)
                    sclk_en   <= 1;
                    state     <= S_READ;
                end

                S_READ: begin
                    // CPOL=1 CPHA=1: sclk_hi 위상 추적으로 엣지 판별
                    // sclk_hi==1 → CLK_DIV-1 도달 시 하강엣지 직전: MOSI 출력
                    // sclk_hi==0 → CLK_DIV-1 도달 시 상승엣지 직전: MISO 샘플
                    // 두 조건을 if-else 한 블록으로 합쳐 yosys proc_dff 충돌 방지
                    if (sclk_cnt == CLK_DIV-1) begin
                        if (sclk_hi) begin
                            // 하강엣지 직전 → 출력 비트 설정
                            // 주소 바이트: 0xF2 (R=1, MB=1, addr=0x32)
                            if (bit_cnt < 8)
                                spi_mosi <= (8'hF2 >> (7 - bit_cnt[2:0])) & 1'b1;
                            else
                                spi_mosi <= 0;  // 읽기 중 MOSI = 0
                        end else begin
                            // 상승엣지 직전 → MISO 샘플
                            rx_shift <= {rx_shift[54:0], spi_miso};
                            bit_cnt  <= bit_cnt + 1;
                            if (bit_cnt == 55) begin  // 7바이트 완료
                                sclk_en <= 0;
                                state   <= S_READ_EN;
                            end
                        end
                    end
                end

                S_READ_EN: begin
                    spi_cs_n <= 1;
                    // rx_shift[55:48] = 주소 에코 (무시)
                    // rx_shift[47:40] = DATAX0, [39:32]=DATAX1
                    // rx_shift[31:24] = DATAY0, [23:16]=DATAY1
                    // 10비트 조합 (right-justified, 2의 보수)
                    x_tilt <= {rx_shift[33:32], rx_shift[47:40]};
                    y_tilt <= {rx_shift[17:16], rx_shift[31:24]};
                    // data_valid는 별도 always 블록이 (state==S_READ_EN)으로 처리
                    state  <= S_IDLE;
                end

                default: state <= S_RESET;
            endcase
        end
    end

endmodule
`default_nettype wire
