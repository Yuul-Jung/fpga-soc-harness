// iir_band_energy.v
// 8대역 IIR 2차 대역통과 필터 뱅크 + 에너지 누산
// 샘플레이트 ≈ 1.22kHz (PDM clk/R/R 2단계 후). 실제 사용 시 PDM 출력 샘플레이트에 맞게 계수 조정 필요.
// 이 RTL은 구조 시연용이며 계수는 Q12 고정소수점 근사값(설계 의도).
//
// 각 대역: b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
// 에너지: 128 샘플마다 y^2 누산 → energy[band] 갱신
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module iir_band_energy #(
    parameter N_BANDS = 8,    // 대역 수
    parameter PCM_W   = 16,   // 입력 PCM 비트폭
    parameter ENERGY_W = 32,  // 에너지 출력 비트폭
    parameter WINDOW   = 128  // 에너지 누산 창 (샘플 수)
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire signed [PCM_W-1:0]   pcm_in,
    input  wire                       pcm_valid,
    // 에너지 출력 (N_BANDS × ENERGY_W 평탄화)
    output reg  [N_BANDS*ENERGY_W-1:0] energy_flat,
    output reg                          energy_update  // WINDOW 샘플마다 1클럭 펄스
);
    // ---- Q12 고정소수점 계수 (설계 의도; 실제 Fs에 맞게 재계산 필요) ----
    // b0, b1, b2, a1, a2 (부호 없음 저장, 사용 시 부호 처리)
    // 단순화: 모든 대역 동일 BPF 형태, 중심 주파수만 다르게 근사
    // 실제 구현에서는 scipy.signal.iirfilter로 계수를 계산하고 Q12 근사 사용
    // 여기서는 대역 0~7 순서로 b0, a1, a2 (b1=0, b2=-b0 for BPF)
    // b0[k], -a1[k], -a2[k] 형태로 Q12 정수로 저장
    // Q12: 1.0 = 4096
    localparam Q = 12;
    localparam Q_HALF = (1 << (Q-1));

    // 각 대역의 계수 (b0, a1_neg, a2_neg) in Q12
    // 대역 0: Fc≈100Hz, 대역 7: Fc≈3000Hz (Fs=~2.44kHz 기준 근사)
    // 주의: Fs에 비해 Fc가 높으면 계수 불안정 → 대역 4~7은 Fs/2 이하로 조정 필요
    function [11:0] coef_b0;
        input [2:0] band;
        case(band)
            3'd0: coef_b0 = 12'd205;  // ≈0.05*4096
            3'd1: coef_b0 = 12'd246;
            3'd2: coef_b0 = 12'd307;
            3'd3: coef_b0 = 12'd369;
            3'd4: coef_b0 = 12'd410;
            3'd5: coef_b0 = 12'd451;
            3'd6: coef_b0 = 12'd492;
            3'd7: coef_b0 = 12'd512;
            default: coef_b0 = 12'd0;
        endcase
    endfunction

    function signed [12:0] coef_a1;  // -a1 (Q12, 부호 있음)
        input [2:0] band;
        case(band)
            3'd0: coef_a1 = 13'sd3686;   // ≈0.9*4096
            3'd1: coef_a1 = 13'sd3563;
            3'd2: coef_a1 = 13'sd3399;
            3'd3: coef_a1 = 13'sd3195;
            3'd4: coef_a1 = 13'sd2949;
            3'd5: coef_a1 = 13'sd2663;
            3'd6: coef_a1 = 13'sd2334;
            3'd7: coef_a1 = 13'sd1966;
            default: coef_a1 = 13'sd0;
        endcase
    endfunction

    // a2 ≈ -(1 - 2*b0/4096)^2 근사 (안정 조건 충족용 단순 근사)
    function signed [12:0] coef_a2;
        input [2:0] band;
        case(band)
            3'd0: coef_a2 = -13'sd3686;  // -a2 (부호 반전)
            3'd1: coef_a2 = -13'sd3481;
            3'd2: coef_a2 = -13'sd3195;
            3'd3: coef_a2 = -13'sd2867;
            3'd4: coef_a2 = -13'sd2498;
            3'd5: coef_a2 = -13'sd2089;
            3'd6: coef_a2 = -13'sd1638;
            3'd7: coef_a2 = -13'sd1147;
            default: coef_a2 = 13'sd0;
        endcase
    endfunction

    // 각 대역의 상태: x[n-1], x[n-2], y[n-1], y[n-2]
    // 24비트 내부 정밀도
    localparam ST_W = 24;
    reg signed [ST_W-1:0] xd1 [0:N_BANDS-1];
    reg signed [ST_W-1:0] xd2 [0:N_BANDS-1];
    reg signed [ST_W-1:0] yd1 [0:N_BANDS-1];
    reg signed [ST_W-1:0] yd2 [0:N_BANDS-1];

    // 에너지 누산
    reg [ENERGY_W-1:0] energy_acc [0:N_BANDS-1];
    reg [$clog2(WINDOW):0] samp_cnt;

    // 순차 처리 FSM (1샘플에 8대역 순차 처리)
    reg [3:0] band_idx;
    reg       processing;
    reg signed [ST_W-1:0] pcm_hold;

    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k=0; k<N_BANDS; k=k+1) begin
                xd1[k] <= 0; xd2[k] <= 0;
                yd1[k] <= 0; yd2[k] <= 0;
                energy_acc[k] <= 0;
            end
            energy_flat  <= 0;
            energy_update <= 0;
            samp_cnt  <= 0;
            band_idx  <= 0;
            processing <= 0;
            pcm_hold  <= 0;
        end else begin
            energy_update <= 0;

            // 새 샘플 도착 → 처리 시작
            if (pcm_valid && !processing) begin
                pcm_hold  <= {{(ST_W-PCM_W){pcm_in[PCM_W-1]}}, pcm_in};
                band_idx  <= 0;
                processing <= 1;
            end

            if (processing) begin
                // 1클럭에 1대역 처리
                begin : band_proc
                    reg signed [ST_W+Q-1:0] acc;
                    reg signed [ST_W-1:0]   y_new;
                    acc = $signed({{Q{pcm_hold[ST_W-1]}}, pcm_hold})
                        * $signed({1'b0, coef_b0(band_idx[2:0])});
                    // b2 = -b0, b1=0 (대역통과 근사)
                    acc = acc - $signed({{Q{xd2[band_idx][ST_W-1]}}, xd2[band_idx]})
                              * $signed({1'b0, coef_b0(band_idx[2:0])});
                    // 피드백 a1, a2 (부호 포함)
                    acc = acc + $signed({{Q{yd1[band_idx][ST_W-1]}}, yd1[band_idx]})
                              * $signed(coef_a1(band_idx[2:0]));
                    acc = acc + $signed({{Q{yd2[band_idx][ST_W-1]}}, yd2[band_idx]})
                              * $signed(coef_a2(band_idx[2:0]));
                    y_new = acc[ST_W+Q-1:Q];  // Q12 스케일 제거

                    // 상태 갱신
                    xd2[band_idx] <= xd1[band_idx];
                    xd1[band_idx] <= pcm_hold[ST_W-1:0];
                    yd2[band_idx] <= yd1[band_idx];
                    yd1[band_idx] <= y_new;

                    // 에너지 누산: y^2 (상위 16비트 사용해 오버플로 방지)
                    energy_acc[band_idx] <= energy_acc[band_idx]
                        + (y_new[ST_W-1:ST_W-16] * y_new[ST_W-1:ST_W-16]);
                end

                if (band_idx == N_BANDS-1) begin
                    processing <= 0;
                    samp_cnt   <= samp_cnt + 1;
                    if (samp_cnt == WINDOW-1) begin
                        samp_cnt <= 0;
                        // 에너지 출력 갱신
                        for (k=0; k<N_BANDS; k=k+1) begin
                            energy_flat[k*ENERGY_W +: ENERGY_W] <= energy_acc[k];
                            energy_acc[k] <= 0;
                        end
                        energy_update <= 1;
                    end
                end else
                    band_idx <= band_idx + 1;
            end
        end
    end

endmodule
`default_nettype wire
