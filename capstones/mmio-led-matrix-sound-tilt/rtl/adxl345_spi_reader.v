// adxl345_spi_reader.v
// ADXL345 SPI 마스터: 초기화 → X/Y 연속 읽기
// SPI Mode 3 (CPOL=1, CPHA=1). SCLK = clk / (2*CLK_DIV)
// ADXL345 멀티바이트 읽기: 주소 바이트(R=1, MB=1) + 6바이트 데이터(X0,X1,Y0,Y1,Z0,Z1)
//
// CI fix 4/4 — sclk_en wire화:
//   * sclk_en: reg → wire (state 조합 논리). proc_dff DFF 생성 불필요.
//     "Multiple edge sensitive events" yosys 오류 근본 해결.
//   * 이전 변경 유지: spi_sclk 직접 사용, data_valid ternary, spi_shift 제거, CNT_W
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module adxl345_spi_reader #(
    parameter CLK_DIV = 50,  // SCLK = clk / (2*CLK_DIV)
    parameter CNT_W   = 6    // ceil(log2(CLK_DIV)), default for CLK_DIV≤64
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

    // 초기화 명령 수
    localparam INIT_CNT = 3;

    // 상태 머신 (3비트, 7 상태)
    localparam S_RESET   = 3'd0;
    localparam S_WAIT    = 3'd1;  // 전원 안정 대기
    localparam S_INIT    = 3'd2;  // 초기화 스텁
    localparam S_IDLE    = 3'd3;  // 읽기 대기
    localparam S_READ_ST = 3'd4;  // CS 내리기 + SPI 개시
    localparam S_READ    = 3'd5;  // 56비트 클럭킹
    localparam S_READ_EN = 3'd6;  // CS 올리기 + 출력 래치

    reg [2:0]       state;
    reg [23:0]      wait_cnt;
    reg [2:0]       init_idx;
    reg [5:0]       bit_cnt;      // 0~55: 56비트 카운터
    reg [CNT_W-1:0] sclk_cnt;    // SCLK 반주기 카운터
    reg [55:0]      rx_shift;     // 7바이트 수신 버퍼
    reg [23:0]      read_period;  // 읽기 주기 카운터 (~10 ms)

    // sclk_en: state 조합 논리 → DFF 불필요, proc_dff 오류 회피
    wire sclk_en = (state == S_READ_ST) | (state == S_READ);

    always @(posedge clk) begin
        if (!rst_n) begin
            state       <= S_RESET;
            wait_cnt    <= 0;
            init_idx    <= 0;
            spi_sclk    <= 1'b1;
            spi_mosi    <= 1'b0;
            spi_cs_n    <= 1'b1;
            sclk_cnt    <= 0;
            bit_cnt     <= 0;
            rx_shift    <= 0;
            x_tilt      <= 0;
            y_tilt      <= 0;
            data_valid  <= 1'b0;
            read_period <= 0;
        end else begin

            // ---- SCLK 분주: 단일 if/else 체인 ----
            // CPOL=1 아이들=HIGH; sclk_en 시 CLK_DIV-1마다 토글
            if (!sclk_en) begin
                sclk_cnt <= 0;
                spi_sclk <= 1'b1;
            end else if (sclk_cnt == (CLK_DIV - 1)) begin
                sclk_cnt <= 0;
                spi_sclk <= ~spi_sclk;
            end else begin
                sclk_cnt <= sclk_cnt + 1;
            end

            // ---- data_valid: S_READ_EN 체류 주기에만 1 ----
            // ternary 단일 할당 → case 외부 default 없음
            // NBA 의미: state는 아래 FSM의 NBA보다 이전값을 읽음 (정상)
            data_valid <= (state == S_READ_EN) ? 1'b1 : 1'b0;

            // ---- FSM ----
            case (state)
                S_RESET: begin
                    wait_cnt <= 0;
                    state    <= S_WAIT;
                end

                S_WAIT: begin
                    // 100 ms 대기 (10,000,000 클럭 @ 100 MHz)
                    if (wait_cnt == 24'd10_000_000)
                        state <= S_INIT;
                    else
                        wait_cnt <= wait_cnt + 1;
                end

                S_INIT: begin
                    // 초기화 스텁: 실제 비트뱅 없이 INIT_CNT 사이클 대기
                    // (POWER_CTL/DATA_FORMAT/BW_RATE 순서 근사, 시뮬 호환)
                    // sclk_en은 wire(state 조합)로 S_INIT 중 항상 0 → SCLK 미동작(스텁 의도)
                    if (init_idx < INIT_CNT) begin
                        spi_cs_n <= 1'b0;
                        init_idx <= init_idx + 1;
                        wait_cnt <= 0;
                        // state = S_INIT 유지 (암묵적 DFF 유지)
                    end else begin
                        spi_cs_n    <= 1'b1;
                        state       <= S_IDLE;
                        read_period <= 0;
                    end
                end

                S_IDLE: begin
                    // ~10 ms(1,000,000 클럭)마다 읽기 개시
                    if (read_period == 24'd1_000_000) begin
                        read_period <= 0;
                        state       <= S_READ_ST;
                    end else begin
                        read_period <= read_period + 1;
                    end
                end

                S_READ_ST: begin
                    // 멀티바이트 읽기 준비: CS 내리기, 56비트 전송 개시
                    // sclk_en은 wire → S_READ_ST 진입 즉시 1 (state 조합)
                    spi_cs_n <= 1'b0;
                    spi_mosi <= 1'b0;
                    bit_cnt  <= 0;
                    rx_shift <= 0;
                    state    <= S_READ;
                end

                S_READ: begin
                    // CPOL=1 CPHA=1 엣지 판별:
                    //   spi_sclk==1, sclk_cnt==max → 다음 클럭에 하강엣지 → MOSI 출력 (CPHA=1)
                    //   spi_sclk==0, sclk_cnt==max → 다음 클럭에 상승엣지 → MISO 샘플 (CPHA=1)
                    // spi_sclk은 registered output; NBA로 이 블록에서는 이전 클럭의 값을 읽음
                    if (sclk_cnt == (CLK_DIV - 1)) begin
                        if (spi_sclk) begin
                            // 하강엣지 직전: MOSI 비트 설정
                            // 주소 바이트 0xF2 (R=1, MB=1, addr=0x32=DATAX0)
                            if (bit_cnt < 6'd8)
                                spi_mosi <= (8'hF2 >> (7 - bit_cnt[2:0])) & 1'b1;
                            else
                                spi_mosi <= 1'b0;  // 데이터 수신 중 MOSI=0
                        end else begin
                            // 상승엣지 직전: MISO 샘플
                            rx_shift <= {rx_shift[54:0], spi_miso};
                            bit_cnt  <= bit_cnt + 1;
                            if (bit_cnt == 6'd55) begin  // 56비트(7바이트) 완료
                                // sclk_en은 wire → state=S_READ_EN 전환 즉시 0
                                state <= S_READ_EN;
                            end
                        end
                    end
                end

                S_READ_EN: begin
                    // CS 복귀, 수신 데이터 래치
                    // rx_shift[55:48] = 주소 에코 (무시)
                    // rx_shift[47:40] = DATAX0, [39:32] = DATAX1
                    // rx_shift[31:24] = DATAY0, [23:16] = DATAY1
                    // 10비트 조합: {DATAX1[1:0]=rx_shift[33:32], DATAX0=rx_shift[47:40]}
                    spi_cs_n <= 1'b1;
                    x_tilt   <= {rx_shift[33:32], rx_shift[47:40]};
                    y_tilt   <= {rx_shift[17:16], rx_shift[31:24]};
                    state    <= S_IDLE;
                    // data_valid는 ternary에서 1 (state==S_READ_EN 조건)
                end

                default: state <= S_RESET;
            endcase
        end
    end

endmodule
`default_nettype wire
