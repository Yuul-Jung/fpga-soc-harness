// speed_pi_ip.v — 속도 PI 제어 IP
// 기능: 4× 직교 엔코더 동기화, 창 계수 속도 측정, 8.8 고정소수점 PI FSM, PWM 출력
// IP 표준 Rev.1 관리 레지스터(0xFFF0~FFFC) 포함
// 파라미터: WINDOW_CYCLES=1_000_000(합성, 10ms@100MHz) / 1000(시뮬레이션)
`timescale 1ns/1ps
module speed_pi_ip #(
    parameter WINDOW_CYCLES = 1_000_000
) (
    input  wire        clk,
    input  wire        rst,
    // MMIO 슬레이브 포트
    input  wire        valid,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // 엔코더 입력
    input  wire        enc_a,
    input  wire        enc_b,
    // PWM 출력
    output reg         pwm_out
);
    // ----- 관리 레지스터 상수 -----
    localparam IP_ID  = 32'h53504931; // "SPI1"
    localparam IP_VER = 32'h01000001;

    // ----- 제어 레지스터 -----
    reg         ctrl_en;
    reg         ctrl_clr;
    reg  [15:0] target;
    reg  [15:0] kp;
    reg  [15:0] ki;
    reg  [15:0] period;
    reg  [15:0] min_duty;
    reg         irq_en;
    reg         irq_status;

    // ----- 엔코더 동기화 (2단) -----
    reg a1, a2, b1, b2;
    wire a_s = a2;
    wire b_s = b2;

    // ----- 4× 에지 검출 -----
    reg  a_prev, b_prev;
    wire a_rise =  a_s && !a_prev;
    wire a_fall = !a_s &&  a_prev;
    wire b_rise =  b_s && !b_prev;
    wire b_fall = !b_s &&  b_prev;
    // CW: A 상승/하강·B 상태, B 상승/하강·A 상태
    wire cw  = (a_rise && !b_s) || (a_fall &&  b_s) ||
               (b_rise &&  a_s) || (b_fall && !a_s);
    wire ccw = (a_rise &&  b_s) || (a_fall && !b_s) ||
               (b_rise && !a_s) || (b_fall &&  a_s);

    // ----- 창 계수 -----
    reg [31:0] win_cnt;
    reg [15:0] edge_acc;
    reg [15:0] speed_reg;

    // ----- PWM -----
    reg [15:0] duty_reg;
    reg [15:0] pwm_cnt;

    // ----- PI 적분기 -----
    reg signed [31:0] integrator;

    // ----- PI 계산용 임시 변수 (모듈 레벨) -----
    reg signed [31:0] error_fp;
    reg signed [31:0] p_term;
    reg signed [31:0] i_term;
    reg signed [31:0] output_fp;
    reg signed [31:0] new_integ;
    reg        [15:0] duty_new;

    // =================== 동기 로직 ===================
    always @(posedge clk) begin
        if (rst) begin
            a1 <= 1'b0; a2 <= 1'b0;
            b1 <= 1'b0; b2 <= 1'b0;
            a_prev <= 1'b0; b_prev <= 1'b0;
            win_cnt   <= 32'd0;
            edge_acc  <= 16'd0;
            speed_reg <= 16'd0;
            integrator <= 32'sd0;
            duty_reg  <= 16'd0;
            pwm_cnt   <= 16'd0;
            pwm_out   <= 1'b0;
            ctrl_en   <= 1'b0;
            ctrl_clr  <= 1'b0;
            target    <= 16'd0;
            kp        <= 16'h0080;
            ki        <= 16'h0010;
            period    <= 16'd4000;
            min_duty  <= 16'd0;
            irq_en    <= 1'b0;
            irq_status <= 1'b0;
            rdata     <= 32'd0;
            // PI 임시 변수 초기화
            error_fp  <= 32'sd0;
            p_term    <= 32'sd0;
            i_term    <= 32'sd0;
            output_fp <= 32'sd0;
            new_integ <= 32'sd0;
            duty_new  <= 16'd0;
        end else begin
            // 2단 동기화
            a1 <= enc_a; a2 <= a1;
            b1 <= enc_b; b2 <= b1;
            a_prev <= a_s;
            b_prev <= b_s;

            // MMIO R/W
            if (valid) begin
                rdata <= 32'd0;
                if (!we) begin
                    case (off)
                        16'h0000: rdata <= {30'd0, ctrl_clr, ctrl_en};
                        16'h0004: rdata <= {16'd0, target};
                        16'h0008: rdata <= {16'd0, kp};
                        16'h000C: rdata <= {16'd0, ki};
                        16'h0010: rdata <= {16'd0, speed_reg};
                        16'h0014: rdata <= {16'd0, period};
                        16'h0018: rdata <= {16'd0, duty_reg};
                        16'h001C: rdata <= {16'd0, min_duty};
                        16'hFFF0: rdata <= IP_ID;
                        16'hFFF4: rdata <= IP_VER;
                        16'hFFF8: rdata <= {31'd0, irq_status};
                        16'hFFFC: rdata <= {31'd0, irq_en};
                        default:  rdata <= 32'd0;
                    endcase
                end else begin
                    case (off)
                        16'h0000: begin ctrl_en <= wdata[0]; ctrl_clr <= wdata[1]; end
                        16'h0004: target   <= wdata[15:0];
                        16'h0008: kp       <= wdata[15:0];
                        16'h000C: ki       <= wdata[15:0];
                        16'h0014: period   <= wdata[15:0];
                        16'h001C: min_duty <= wdata[15:0];
                        16'hFFF8: irq_status <= irq_status & ~wdata[0];
                        16'hFFFC: irq_en   <= wdata[0];
                        default: ;
                    endcase
                end
            end

            // ctrl_clr 처리 및 자동 해제
            if (ctrl_clr) begin
                integrator <= 32'sd0;
                duty_reg   <= 16'd0;
                edge_acc   <= 16'd0;
                win_cnt    <= 32'd0;
                ctrl_clr   <= 1'b0;
            end else if (ctrl_en) begin
                // 에지 누산
                if (cw && edge_acc < 16'hFFFF)
                    edge_acc <= edge_acc + 16'd1;
                else if (ccw && edge_acc > 16'd0)
                    edge_acc <= edge_acc - 16'd1;

                // 창 완료
                if (win_cnt >= WINDOW_CYCLES - 1) begin
                    win_cnt   <= 32'd0;
                    speed_reg <= edge_acc;
                    edge_acc  <= 16'd0;
                    irq_status <= 1'b1;

                    // PI 계산 (8.8 고정소수점, 비블로킹 대입 순서 유지)
                    // error = (target - speed) << 8  (8.8 스케일)
                    error_fp  <= ($signed({1'b0, target}) - $signed({1'b0, edge_acc})) <<< 8;
                    p_term    <= ($signed({1'b0, kp}) * (($signed({1'b0, target}) - $signed({1'b0, edge_acc})) <<< 8)) >>> 8;
                    new_integ <= integrator + (($signed({1'b0, ki}) * (($signed({1'b0, target}) - $signed({1'b0, edge_acc})) <<< 8)) >>> 8);
                end else begin
                    win_cnt <= win_cnt + 32'd1;
                end

                // PI 2사이클째: integrator 클램프 및 출력 업데이트
                // (새 창 직후 p_term/new_integ가 준비됨)
                // integrator 클램프: [-8388608, 8388607] (23비트 정수 부분)
                if (new_integ > $signed(32'sd8388607))
                    integrator <= 32'sd8388607;
                else if (new_integ < -$signed(32'sd8388608))
                    integrator <= -$signed(32'sd8388608);
                else
                    integrator <= new_integ;

                output_fp <= p_term + integrator;

                // 출력 클램프 및 duty 업데이트
                if (output_fp < $signed(32'sd0)) begin
                    duty_reg <= min_duty;
                end else if ((output_fp >>> 8) > $signed({1'b0, period})) begin
                    duty_reg <= period;
                end else begin
                    duty_new <= output_fp[23:8];
                    if (output_fp[23:8] < min_duty)
                        duty_reg <= min_duty;
                    else
                        duty_reg <= output_fp[23:8];
                end
            end

            // PWM 생성
            if (period > 16'd0) begin
                if (pwm_cnt >= period - 16'd1)
                    pwm_cnt <= 16'd0;
                else
                    pwm_cnt <= pwm_cnt + 16'd1;
                pwm_out <= (ctrl_en && (pwm_cnt < duty_reg)) ? 1'b1 : 1'b0;
            end else begin
                pwm_out <= 1'b0;
            end
        end
    end
endmodule
