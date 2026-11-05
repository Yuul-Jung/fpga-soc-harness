// pdm_cic_decimator.v
// CIC 3차 데시메이터: PDM 1비트 → 16비트 PCM
// R=41 (100MHz/41 ≈ 2.44MHz PDM 클럭, 출력 샘플레이트 ≈ 2.44MHz/41 ≈ 59.5 kHz → 추가 분주 선택)
// 단순화: R=41 로 100MHz에서 PCM ≈ 2.44 kHz (R=1024 단순 버전 대신 R=41 CIC 3차 사용)
// 주의: CIC 필터 출력 비트폭 = 1 + 3*log2(41) ≈ 1 + 3*5.4 ≈ 17 비트 → 하위 16비트 사용
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module pdm_cic_decimator #(
    parameter R = 41,          // 데시메이션 비율 (PDM 클럭 분주 겸)
    parameter STAGES = 3,      // CIC 단 수 (3차)
    parameter OUT_W = 16       // 출력 PCM 비트폭
)(
    input  wire        clk,
    input  wire        rst_n,
    // PDM 클럭 출력 (FPGA → 마이크)
    output reg         pdm_clk,
    // PDM 데이터 입력 (마이크 → FPGA)
    input  wire        pdm_data,
    // PCM 출력
    output reg  [OUT_W-1:0] pcm_out,
    output reg              pcm_valid
);
    // PDM 클럭 분주 카운터 (100MHz / 2 / R ≈ 목표 PDM 클럭)
    // pdm_clk는 R 카운트마다 토글 → 실제 PDM freq = 100MHz/(2*R)
    // R=41: 100MHz/82 ≈ 1.22 MHz PDM 클럭
    reg [$clog2(R)-1:0] clk_cnt;
    reg pdm_clk_r;

    always @(posedge clk) begin
        if (!rst_n) begin
            clk_cnt   <= 0;
            pdm_clk   <= 0;
            pdm_clk_r <= 0;
        end else begin
            if (clk_cnt == R-1) begin
                clk_cnt <= 0;
                pdm_clk <= ~pdm_clk;
            end else
                clk_cnt <= clk_cnt + 1;
            pdm_clk_r <= pdm_clk;
        end
    end

    // PDM 클럭 상승엣지 검출 (통합 단계용)
    wire pdm_clk_rise = pdm_clk & ~pdm_clk_r;

    // PDM 비트 → ±1 변환 (0→-1, 1→+1) 를 sign 처리
    // CIC 적분기: 각 단계 누산 (25비트 내부 버스)
    localparam ACC_W = 25;
    reg signed [ACC_W-1:0] intg[0:STAGES-1];

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            intg[0] <= 0; intg[1] <= 0; intg[2] <= 0;
        end else if (pdm_clk_rise) begin
            // 1단계 적분기: PDM 1→+1, 0→-1
            intg[0] <= intg[0] + (pdm_data ? {{(ACC_W-1){1'b0}}, 1'b1} :
                                             {{(ACC_W-1){1'b1}}, 1'b1} );
            intg[1] <= intg[1] + intg[0];
            intg[2] <= intg[2] + intg[1];
        end
    end

    // 데시메이션 카운터 (R 클릭마다 샘플링)
    reg [$clog2(R)-1:0] dec_cnt;
    reg dec_tick;
    reg signed [ACC_W-1:0] intg2_latch;

    always @(posedge clk) begin
        if (!rst_n) begin
            dec_cnt    <= 0;
            dec_tick   <= 0;
            intg2_latch <= 0;
        end else if (pdm_clk_rise) begin
            if (dec_cnt == R-1) begin
                dec_cnt    <= 0;
                dec_tick   <= 1;
                intg2_latch <= intg[2];
            end else begin
                dec_cnt  <= dec_cnt + 1;
                dec_tick <= 0;
            end
        end else
            dec_tick <= 0;
    end

    // CIC 빗살(Comb) 단계: 3개 (차분기)
    reg signed [ACC_W-1:0] comb_d[0:STAGES];
    reg signed [ACC_W-1:0] comb_q[0:STAGES];

    always @(posedge clk) begin
        if (!rst_n) begin
            comb_d[0] <= 0; comb_d[1] <= 0; comb_d[2] <= 0;
            comb_q[0] <= 0; comb_q[1] <= 0; comb_q[2] <= 0;
            pcm_out   <= 0;
            pcm_valid <= 0;
        end else begin
            pcm_valid <= 0;
            if (dec_tick) begin
                comb_d[0] <= intg2_latch;
                comb_q[0] <= comb_d[0];

                comb_d[1] <= intg2_latch  - comb_d[0];
                comb_q[1] <= comb_d[1];

                comb_d[2] <= comb_d[1] - comb_q[1];
                comb_q[2] <= comb_d[2];

                // 출력: 최상위 OUT_W 비트 선택 (비트 성장 고려)
                pcm_out   <= comb_d[2][ACC_W-1 : ACC_W-OUT_W];
                pcm_valid <= 1;
            end
        end
    end

endmodule
`default_nettype wire
