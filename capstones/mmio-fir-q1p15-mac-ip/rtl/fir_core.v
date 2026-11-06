// fir_core.v — 16탭 Q1.15 FIR 필터 MAC 코어
// capstone: mmio-fir-q1p15-mac-ip (stage T4)
// 형식: Verilog-2001, iverilog/verilator/yosys 호환
//
// 수치 형식:
//   입출력: s16 Q1.15 (부호 1비트 + 소수 15비트, 범위 [-1, +1))
//   계수:   s16 Q1.15
//   곱:     s32 Q2.30 = product[31:0]
//   누산기: s36, 소수 28비트 (Q6+.28). 36비트 중 비트28 = 2^0(=1의 자리)
//           sign extension: {{6{product[31]}}, product[31:2]} = 36비트
//   출력 추출: acc[28:13] (bit28=1의 자리, bit13=2^-15=Q1.15 LSB)
//   반올림: acc에 2^12 더한 뒤 추출
//   포화:  acc_rounded[35:28] ∉ {8'h00, 8'hFF}이면 포화
//
// 자원 추정 (yosys 기준, XC7A35T):
//   DSP48E1 ~16개, LUTRAM ~1블록, LUT ~100

`default_nettype none
`timescale 1ns/1ps

module fir_core #(
    parameter NUM_TAPS  = 16,
    parameter DATA_W    = 16,
    parameter COEF_W    = 16,
    parameter ADDR_W    = 4
) (
    input  wire                 clk,
    input  wire                 rst_n,

    // AXI4-Stream 샘플 입력 (Q1.15)
    input  wire [DATA_W-1:0]    s_axis_data,
    input  wire                 s_axis_valid,
    output reg                  s_axis_ready,

    // AXI4-Stream 필터 출력 (Q1.15)
    output reg  [DATA_W-1:0]    m_axis_data,
    output reg                  m_axis_valid,
    input  wire                 m_axis_ready,

    // 계수 쓰기 포트
    input  wire                 coeff_we,
    input  wire [ADDR_W-1:0]    coeff_addr,
    input  wire [COEF_W-1:0]    coeff_wdat,

    // 제어
    input  wire                 enable,
    input  wire                 bypass,
    output reg                  busy
);

// ─────────────────────────────────────────────
// 1. 계수 RAM (분산 RAM; 합성기가 LUTRAM으로 추론)
// ─────────────────────────────────────────────
reg signed [COEF_W-1:0] coeff_ram [0:NUM_TAPS-1];

integer ci;
initial begin
    for (ci = 0; ci < NUM_TAPS; ci = ci + 1)
        coeff_ram[ci] = 0;
end

always @(posedge clk) begin
    if (coeff_we)
        coeff_ram[coeff_addr] <= $signed(coeff_wdat);
end

// ─────────────────────────────────────────────
// 2. 샘플 시프트 레지스터
//    posedge clk에서 s_axis_valid && s_axis_ready이면 오른쪽으로 이동
// ─────────────────────────────────────────────
reg signed [DATA_W-1:0] sr [0:NUM_TAPS-1];

always @(posedge clk) begin : sr_blk
    integer k;
    if (!rst_n) begin
        for (k = 0; k < NUM_TAPS; k = k + 1)
            sr[k] <= 0;
    end else if (s_axis_valid && s_axis_ready) begin
        sr[0] <= $signed(s_axis_data);
        for (k = 1; k < NUM_TAPS; k = k + 1)
            sr[k] <= sr[k-1];
    end
end

// ─────────────────────────────────────────────
// 3. FSM: IDLE → COMPUTE → OUTPUT
// ─────────────────────────────────────────────
localparam ST_IDLE    = 2'd0;
localparam ST_COMPUTE = 2'd1;
localparam ST_OUTPUT  = 2'd2;

reg [1:0]            state;
reg [ADDR_W-1:0]     tap_idx;

// 누산기: s36, 소수 28비트
// Q2.30 곱 → 오른쪽 2비트 버려 Q4.28 (30비트) → {{6{sign}}, 30비트} = 36비트 Q6+.28
// 비트 대응: bit28 = 2^0 = 1의 자리, bit35 = 부호
localparam ACC_W = 36;
reg signed [ACC_W-1:0]   acc;

// MAC 파이프라인 1단계
reg signed [DATA_W-1:0]  mac_a;
reg signed [COEF_W-1:0]  mac_b;
reg                       mac_valid;

// 32비트 곱 Q2.30 (합성기 → DSP48E1 추론)
wire signed [DATA_W+COEF_W-1:0] product;
assign product = mac_a * mac_b;

// ─────────────────────────────────────────────
// 4. 포화+반올림 조합 논리 (Verilog-2001: 모듈 레벨 선언)
// ─────────────────────────────────────────────
// 반올림: acc + 2^12 (bit12에서 반올림)
// 추출:   acc_rounded[28:13] = Q1.15 출력 (bit28=1의 자리, bit13=LSB)
// 포화:   acc_rounded[35:28] ∈ {00, FF}만 정상 범위
reg signed [ACC_W-1:0]   acc_rounded;
reg                       ovf_pos;    // 양수 오버플로
reg                       ovf_neg;    // 음수 오버플로
reg signed [DATA_W-1:0]  out_sat;

always @(*) begin
    acc_rounded = acc + 36'h1000;   // +2^12 반올림

    // acc_rounded[35:28] 검사 (8비트 정수 부분)
    // 정상 범위: 8'h00(양수 0 <= V < 1) 또는 8'hFF(음수 -1 <= V < 0)
    ovf_pos = (~acc_rounded[35]) & (|acc_rounded[34:28]);
    ovf_neg =  acc_rounded[35]  & (~(&acc_rounded[34:28]));

    if (ovf_pos)
        out_sat = 16'sh7FFF;
    else if (ovf_neg)
        out_sat = 16'sh8000;
    else
        out_sat = acc_rounded[28:13];   // Q1.15 추출
end

// ─────────────────────────────────────────────
// 5. FSM 순차 로직
// ─────────────────────────────────────────────
always @(posedge clk) begin
    if (!rst_n) begin
        state        <= ST_IDLE;
        tap_idx      <= 0;
        acc          <= 0;
        mac_a        <= 0;
        mac_b        <= 0;
        mac_valid    <= 1'b0;
        s_axis_ready <= 1'b0;
        m_axis_valid <= 1'b0;
        m_axis_data  <= 0;
        busy         <= 1'b0;
    end else begin
        mac_valid <= 1'b0;  // 기본 비활성 (각 state에서 필요시 1로)

        case (state)

        // ── IDLE: 샘플 대기
        ST_IDLE: begin
            busy <= 1'b0;
            if (!enable) begin
                s_axis_ready <= 1'b0;
                m_axis_valid <= 1'b0;
            end else if (bypass) begin
                // bypass: 입력 → 출력 직결
                s_axis_ready <= (m_axis_ready || !m_axis_valid);
                if (s_axis_valid && s_axis_ready) begin
                    m_axis_data  <= s_axis_data;
                    m_axis_valid <= 1'b1;
                end else if (m_axis_ready) begin
                    m_axis_valid <= 1'b0;
                end
            end else begin
                // 정상 FIR 모드
                m_axis_valid <= 1'b0;
                s_axis_ready <= 1'b1;
                if (s_axis_valid) begin
                    // 샘플 수신 → MAC 시작
                    s_axis_ready <= 1'b0;
                    busy         <= 1'b1;
                    tap_idx      <= 0;
                    acc          <= 0;
                    // 탭 0 사전 로드 (다음 사이클 COMPUTE에서 누산)
                    mac_a     <= $signed(s_axis_data);
                    mac_b     <= coeff_ram[0];
                    mac_valid <= 1'b1;
                    state     <= ST_COMPUTE;
                end
            end
        end

        // ── COMPUTE: 순차 MAC (NUM_TAPS 사이클)
        // 타임라인:
        //   IDLE→COMPUTE: mac_a=sr[0], mac_b=coeff[0], mac_valid=1, tap_idx=0
        //   COMPUTE(tap=0): 누산 sr[0]*coeff[0]; 로드 sr[1]/coeff[1]; tap→1
        //   ...
        //   COMPUTE(tap=14): 누산 sr[14]*coeff[14]; 로드 sr[15]/coeff[15]; tap→15
        //   COMPUTE(tap=15): 누산 sr[15]*coeff[15]; → ST_OUTPUT
        ST_COMPUTE: begin
            if (mac_valid) begin
                // product[31:0] Q2.30 → 오른쪽 2비트 버려 Q4.28 30비트
                // 부호 확장 6비트 → 36비트 Q6+.28
                acc <= acc + {{6{product[31]}}, product[31:2]};
            end

            if (tap_idx < NUM_TAPS - 1) begin
                // 다음 탭 준비
                tap_idx   <= tap_idx + 1'b1;
                mac_a     <= sr[tap_idx + 1'b1];
                mac_b     <= coeff_ram[tap_idx + 1'b1];
                mac_valid <= 1'b1;
            end else begin
                // 마지막 탭 완료 → 출력
                state <= ST_OUTPUT;
            end
        end

        // ── OUTPUT: 조합 논리 결과 (out_sat) 등록 → 출력
        ST_OUTPUT: begin
            busy         <= 1'b0;
            m_axis_data  <= out_sat;
            m_axis_valid <= 1'b1;
            if (m_axis_ready) begin
                m_axis_valid <= 1'b0;
                state        <= ST_IDLE;
            end
        end

        default: state <= ST_IDLE;
        endcase
    end
end

endmodule

`default_nettype wire
