// spwm_ip.v — 단상 풀브리지 SPWM 생성기 AXI4-Lite IP
// 32-항목 Q15 사인 LUT 기반 SPWM + 데드타임 FSM (레그 A/B 각 1개).
// 소프트웨어에서 AXI4-Lite 레지스터로 반송파 주기·변조 지수·데드타임·EN/TRIP 제어.
// Verilog-2001. iverilog/verilator/yosys 호환.
// 출처: capstones/mmio-spwm-deadtime-ip/capstone.json
`default_nettype none
`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// 레지스터 오프셋 (기저 주소 BASE_ADDR 기준, [3:2] 사용)
// 0x00 CTRL    [0]=EN [1]=TRIP_CLR(1-write clears latch)
// 0x04 PERIOD  [15:0] 반송파 반주기 틱 (기본 5000)
// 0x08 MOD_IDX [14:0] Q15 변조 지수 0..32767
// 0x0C DEADTIME[9:0]  데드타임 클럭 틱 (기본 50 = 500 ns)
// 0x10 STATUS  [0]=ACTIVE [1]=TRIP_LATCH  (읽기 전용)
// 0x14 ID      0x5350_5731 "SPW1"         (읽기 전용)
// 0x18 PHASE_CTR[4:0] 사인 LUT 인덱스    (읽기 전용)
// ---------------------------------------------------------------------------

module spwm_ip #(
    parameter BASE_ADDR = 32'h4016_0000
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // AW
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // W
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // B
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // AR
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // R
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // 외부 입력
    input  wire        trip_in,   // 1 = 외부 고장(즉시 트립)
    // SPWM 출력 (H-브리지 게이트 드라이버로)
    output wire        hin_a,     // 레그 A 상단
    output wire        lin_a,     // 레그 A 하단
    output wire        hin_b,     // 레그 B 상단
    output wire        lin_b,     // 레그 B 하단
    // 인터럽트
    output wire        irq        // STATUS[1] TRIP_LATCH
);

    // -----------------------------------------------------------------------
    // 레지스터
    // -----------------------------------------------------------------------
    reg         reg_en;
    reg  [15:0] reg_period;      // 반송파 반주기 (기본 5000)
    reg  [14:0] reg_mod_idx;     // Q15 변조 지수 (기본 26214)
    reg  [9:0]  reg_deadtime;    // 데드타임 틱 (기본 50)
    reg         trip_latch;      // 트립 래치

    // -----------------------------------------------------------------------
    // 사인 LUT 함수 (32항목, Q15 부호 있음)
    // sin(2π*i/32) × 32767, i=0..31
    // -----------------------------------------------------------------------
    function signed [15:0] sine_lut;
        input [4:0] idx;
        begin
            case (idx)
            5'd0:  sine_lut = 16'sd0;
            5'd1:  sine_lut = 16'sd6393;
            5'd2:  sine_lut = 16'sd12539;
            5'd3:  sine_lut = 16'sd18204;
            5'd4:  sine_lut = 16'sd23170;
            5'd5:  sine_lut = 16'sd27245;
            5'd6:  sine_lut = 16'sd30273;
            5'd7:  sine_lut = 16'sd32137;
            5'd8:  sine_lut = 16'sd32767;
            5'd9:  sine_lut = 16'sd32137;
            5'd10: sine_lut = 16'sd30273;
            5'd11: sine_lut = 16'sd27245;
            5'd12: sine_lut = 16'sd23170;
            5'd13: sine_lut = 16'sd18204;
            5'd14: sine_lut = 16'sd12539;
            5'd15: sine_lut = 16'sd6393;
            5'd16: sine_lut = 16'sd0;
            5'd17: sine_lut = -16'sd6393;
            5'd18: sine_lut = -16'sd12539;
            5'd19: sine_lut = -16'sd18204;
            5'd20: sine_lut = -16'sd23170;
            5'd21: sine_lut = -16'sd27245;
            5'd22: sine_lut = -16'sd30273;
            5'd23: sine_lut = -16'sd32137;
            5'd24: sine_lut = -16'sd32767;
            5'd25: sine_lut = -16'sd32137;
            5'd26: sine_lut = -16'sd30273;
            5'd27: sine_lut = -16'sd27245;
            5'd28: sine_lut = -16'sd23170;
            5'd29: sine_lut = -16'sd18204;
            5'd30: sine_lut = -16'sd12539;
            5'd31: sine_lut = -16'sd6393;
            default: sine_lut = 16'sd0;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // SPWM 코어: 삼각 반송파 + 사인 기준파 비교 → raw_pwm
    // -----------------------------------------------------------------------
    reg  [15:0] carrier;         // 삼각파 카운터 0..reg_period
    reg         car_dir;         // 0=상승, 1=하강
    reg  [4:0]  phase_ctr;       // 사인 LUT 인덱스 0..31

    wire signed [15:0] s_q15    = sine_lut(phase_ctr);
    // 변조 지수 × 사인값 → Q30, >>15 → Q15 오프셋
    wire signed [30:0] ms_prod  = $signed({1'b0, reg_mod_idx}) * s_q15;
    // 오프셋 범위: -32767*32767 >> 15 ≈ -32767 ~ +32767
    wire signed [15:0] ref_off  = ms_prod[30:15];
    // 기준파: PERIOD/2(중심) + 오프셋
    wire signed [17:0] ref_wide = $signed({2'b00, {1'b0, reg_period[15:1]}})
                                + $signed({{2{ref_off[15]}}, ref_off});
    // 범위를 [0, reg_period]로 클램프
    wire [15:0] sine_ref = (ref_wide[17]) ? 16'd0 :          // 음수면 0
                           (ref_wide > $signed({2'b00, reg_period})) ? reg_period :
                           ref_wide[15:0];

    wire raw_pwm = reg_en && !trip_latch && (sine_ref > carrier);

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || !reg_en || trip_latch) begin
            carrier   <= 16'd0;
            car_dir   <= 1'b0;
            phase_ctr <= 5'd0;
        end else begin
            if (car_dir == 1'b0) begin
                if (carrier >= reg_period) begin
                    car_dir   <= 1'b1;
                    carrier   <= carrier - 1'b1;
                    phase_ctr <= phase_ctr + 1'b1; // 반주기마다 위상 전진
                end else
                    carrier <= carrier + 1'b1;
            end else begin
                if (carrier == 16'd0) begin
                    car_dir   <= 1'b0;
                    carrier   <= carrier + 1'b1;
                    phase_ctr <= phase_ctr + 1'b1;
                end else
                    carrier <= carrier - 1'b1;
            end
        end
    end

    // -----------------------------------------------------------------------
    // 데드타임 FSM (레그 A용)
    // 천이 감지 → 양쪽 비활성 → dt_ticks 카운트 → 목표 상태
    // -----------------------------------------------------------------------
    reg  [1:0] dtA_st;           // 0=STEADY 1=DT_RISE 2=DT_FALL
    reg  [9:0] dtA_cnt;
    reg        pwm_prev;
    reg        hin_a_r, lin_a_r;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || trip_latch || !reg_en) begin
            dtA_st  <= 2'd0;
            dtA_cnt <= 10'd0;
            hin_a_r <= 1'b0;
            lin_a_r <= 1'b0;
            pwm_prev<= 1'b0;
        end else begin
            pwm_prev <= raw_pwm;
            case (dtA_st)
            2'd0: begin // STEADY
                if (raw_pwm && !pwm_prev) begin  // 상승 엣지 → 데드타임 후 HIN
                    hin_a_r <= 1'b0;
                    lin_a_r <= 1'b0;
                    dtA_cnt <= reg_deadtime;
                    dtA_st  <= 2'd1;
                end else if (!raw_pwm && pwm_prev) begin  // 하강 엣지 → 데드타임 후 LIN
                    hin_a_r <= 1'b0;
                    lin_a_r <= 1'b0;
                    dtA_cnt <= reg_deadtime;
                    dtA_st  <= 2'd2;
                end else begin
                    hin_a_r <= raw_pwm;
                    lin_a_r <= !raw_pwm;
                end
            end
            2'd1: begin // DT_RISE: 카운트 후 HIN=1
                if (dtA_cnt == 10'd0) begin
                    hin_a_r <= 1'b1;
                    lin_a_r <= 1'b0;
                    dtA_st  <= 2'd0;
                end else
                    dtA_cnt <= dtA_cnt - 1'b1;
            end
            2'd2: begin // DT_FALL: 카운트 후 LIN=1
                if (dtA_cnt == 10'd0) begin
                    hin_a_r <= 1'b0;
                    lin_a_r <= 1'b1;
                    dtA_st  <= 2'd0;
                end else
                    dtA_cnt <= dtA_cnt - 1'b1;
            end
            default: dtA_st <= 2'd0;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // 데드타임 FSM (레그 B용) — raw_pwm 반전 입력
    // -----------------------------------------------------------------------
    reg  [1:0] dtB_st;
    reg  [9:0] dtB_cnt;
    reg        npwm_prev;
    reg        hin_b_r, lin_b_r;
    wire       raw_pwm_b = !raw_pwm;  // 레그 B는 반전

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || trip_latch || !reg_en) begin
            dtB_st   <= 2'd0;
            dtB_cnt  <= 10'd0;
            hin_b_r  <= 1'b0;
            lin_b_r  <= 1'b0;
            npwm_prev<= 1'b0;
        end else begin
            npwm_prev <= raw_pwm_b;
            case (dtB_st)
            2'd0: begin
                if (raw_pwm_b && !npwm_prev) begin
                    hin_b_r <= 1'b0;
                    lin_b_r <= 1'b0;
                    dtB_cnt <= reg_deadtime;
                    dtB_st  <= 2'd1;
                end else if (!raw_pwm_b && npwm_prev) begin
                    hin_b_r <= 1'b0;
                    lin_b_r <= 1'b0;
                    dtB_cnt <= reg_deadtime;
                    dtB_st  <= 2'd2;
                end else begin
                    hin_b_r <= raw_pwm_b;
                    lin_b_r <= !raw_pwm_b;
                end
            end
            2'd1: begin
                if (dtB_cnt == 10'd0) begin
                    hin_b_r <= 1'b1;
                    lin_b_r <= 1'b0;
                    dtB_st  <= 2'd0;
                end else
                    dtB_cnt <= dtB_cnt - 1'b1;
            end
            2'd2: begin
                if (dtB_cnt == 10'd0) begin
                    hin_b_r <= 1'b0;
                    lin_b_r <= 1'b1;
                    dtB_st  <= 2'd0;
                end else
                    dtB_cnt <= dtB_cnt - 1'b1;
            end
            default: dtB_st <= 2'd0;
            endcase
        end
    end

    assign hin_a = hin_a_r;
    assign lin_a = lin_a_r;
    assign hin_b = hin_b_r;
    assign lin_b = lin_b_r;
    assign irq   = trip_latch;

    // -----------------------------------------------------------------------
    // 슛스루 감지 assertion (합성 시 무시; 시뮬레이션 전용)
    // -----------------------------------------------------------------------
    // synthesis translate_off
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn) begin
            if (hin_a_r && lin_a_r)
                $display("SHOOT-THROUGH DETECTED: hin_a=1 lin_a=1 at time %0t", $time);
            if (hin_b_r && lin_b_r)
                $display("SHOOT-THROUGH DETECTED: hin_b=1 lin_b=1 at time %0t", $time);
        end
    end
    // synthesis translate_on

    // -----------------------------------------------------------------------
    // AXI4-Lite 슬레이브: 쓰기 채널
    // -----------------------------------------------------------------------
    reg [31:0] wr_addr_lat;
    reg [31:0] wr_data_lat;
    reg        wr_addr_valid;
    reg        wr_data_valid;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready  <= 1'b1;
            s_axi_wready   <= 1'b1;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            wr_addr_valid  <= 1'b0;
            wr_data_valid  <= 1'b0;
            reg_en         <= 1'b0;
            reg_period     <= 16'd5000;
            reg_mod_idx    <= 15'd26214;
            reg_deadtime   <= 10'd50;
            trip_latch     <= 1'b0;
        end else begin
            // 외부 트립
            if (trip_in)
                trip_latch <= 1'b1;

            // AW 래치
            if (s_axi_awready && s_axi_awvalid) begin
                wr_addr_lat   <= s_axi_awaddr;
                wr_addr_valid <= 1'b1;
                s_axi_awready <= 1'b0;
            end
            // W 래치
            if (s_axi_wready && s_axi_wvalid) begin
                wr_data_lat   <= s_axi_wdata;
                wr_data_valid <= 1'b1;
                s_axi_wready  <= 1'b0;
            end
            // 쓰기 완료: 두 채널 모두 도착하면 처리
            if (wr_addr_valid && wr_data_valid && !s_axi_bvalid) begin
                case (wr_addr_lat[7:2])
                6'd0: begin  // CTRL
                    reg_en <= wr_data_lat[0];
                    if (wr_data_lat[1])
                        trip_latch <= 1'b0;
                end
                6'd1: reg_period   <= wr_data_lat[15:0];   // PERIOD
                6'd2: reg_mod_idx  <= wr_data_lat[14:0];   // MOD_IDX
                6'd3: reg_deadtime <= wr_data_lat[9:0];    // DEADTIME
                default: ; // STATUS/ID/PHASE_CTR는 읽기 전용
                endcase
                s_axi_bvalid   <= 1'b1;
                s_axi_bresp    <= 2'b00;
                wr_addr_valid  <= 1'b0;
                wr_data_valid  <= 1'b0;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid   <= 1'b0;
                s_axi_awready  <= 1'b1;
                s_axi_wready   <= 1'b1;
            end
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite 슬레이브: 읽기 채널
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[7:2])
                6'd0: s_axi_rdata <= {30'h0, trip_latch, reg_en};  // CTRL 미러
                6'd1: s_axi_rdata <= {16'h0, reg_period};
                6'd2: s_axi_rdata <= {17'h0, reg_mod_idx};
                6'd3: s_axi_rdata <= {22'h0, reg_deadtime};
                6'd4: s_axi_rdata <= {30'h0, trip_latch, reg_en};  // STATUS
                6'd5: s_axi_rdata <= 32'h5350_5731;                 // ID "SPW1"
                6'd6: s_axi_rdata <= {27'h0, phase_ctr};            // PHASE_CTR
                default: s_axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

endmodule
