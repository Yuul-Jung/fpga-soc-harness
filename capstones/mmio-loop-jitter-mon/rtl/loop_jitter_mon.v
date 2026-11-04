// loop_jitter_mon.v — 제어 루프 지터 측정 IP (Verilog-2001)
// 하네스 직접 작성 원본.
//
// 측정 원리:
//   tick_in의 상승 에지 사이 클럭 수를 세어 PERIOD_LAST에 기록.
//   PERIOD_MIN = min(전체), PERIOD_MAX = max(전체).
//   측정 주기 > THRESHOLD(0이 아닐 때)이면 OVERRUN_CNT++ 및 IRQ_STATUS[0] 셋.
//
// mmio-lite 슬레이브 인터페이스:
//   sel     : 이 슬레이브 선택 (상위 디코더에서 addr[31:16] 비교)
//   we      : 1=쓰기, 0=읽기
//   offset  : addr[15:0]
//   wdata   : 32비트 쓰기 데이터
//   rdata   : 32비트 읽기 데이터 (sel=1인 사이클에 유효)
//
// IP 표준 rev.1 관리 레지스터:
//   0xFFF0  ID         = 0x4A4D_4F4E ('JMON')
//   0xFFF4  VER        = 0x0100_0100  [31:24]=표준rev1, [15:8]=주1, [7:0]=부0
//   0xFFF8  IRQ_STATUS  W1C, bit[0]=overrun_irq
//   0xFFFC  IRQ_ENABLE  bit[0]=overrun_irq 활성화 (리셋 시 0)
//
// 기능 레지스터:
//   0x0000  CTRL         bit[0]=enable_meas, bit[1]=stats_clear(W만, 읽기=0)
//   0x0004  PERIOD_MIN   RO, 리셋/stats_clear 시 32'hFFFF_FFFF
//   0x0008  PERIOD_MAX   RO, 리셋/stats_clear 시 32'h0
//   0x000C  PERIOD_LAST  RO, 마지막 측정 주기
//   0x0010  OVERRUN_CNT  RO, 오버런 누적 횟수
//   0x0014  THRESHOLD    RW, 0이면 오버런 검출 비활성
//
`timescale 1ns/1ps
module loop_jitter_mon (
    input  wire        clk,
    input  wire        rst,          // 비동기, 액티브 하이
    // 측정 대상
    input  wire        tick_in,      // 주기 측정 대상 신호
    // mmio-lite 슬레이브
    input  wire        sel,          // 이 슬레이브가 선택됨
    input  wire        we,           // 1=쓰기
    input  wire [15:0] offset,       // 레지스터 오프셋
    input  wire [31:0] wdata,        // 쓰기 데이터
    output reg  [31:0] rdata,        // 읽기 데이터
    // 인터럽트
    output wire        irq           // 레벨, IRQ_STATUS & IRQ_ENABLE
);

    // ----------------------------------------------------------------
    // 오프셋 상수
    // ----------------------------------------------------------------
    localparam [15:0]
        OFF_CTRL        = 16'h0000,
        OFF_PERIOD_MIN  = 16'h0004,
        OFF_PERIOD_MAX  = 16'h0008,
        OFF_PERIOD_LAST = 16'h000C,
        OFF_OVERRUN_CNT = 16'h0010,
        OFF_THRESHOLD   = 16'h0014,
        OFF_ID          = 16'hFFF0,
        OFF_VER         = 16'hFFF4,
        OFF_IRQ_STATUS  = 16'hFFF8,
        OFF_IRQ_ENABLE  = 16'hFFFC;

    // ID, VER 상수
    localparam [31:0] CONST_ID  = 32'h4A4D_4F4E; // 'J','M','O','N'
    localparam [31:0] CONST_VER = 32'h0100_0100; // rev1, major1, minor0

    // ----------------------------------------------------------------
    // tick_in 2단 동기화 + 상승 에지 검출
    // ----------------------------------------------------------------
    reg tick_s1, tick_s2, tick_s3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_s1 <= 1'b0;
            tick_s2 <= 1'b0;
            tick_s3 <= 1'b0;
        end else begin
            tick_s1 <= tick_in;
            tick_s2 <= tick_s1;
            tick_s3 <= tick_s2;
        end
    end
    // 2단 동기화 후 상승 에지: tick_s2가 올라가고 tick_s3가 아직 낮은 순간
    wire tick_rise = tick_s2 & ~tick_s3;

    // ----------------------------------------------------------------
    // 버스 쓰기 디코드 보조 신호
    // ----------------------------------------------------------------
    wire wr_ctrl        = sel && we && (offset == OFF_CTRL);
    wire wr_threshold   = sel && we && (offset == OFF_THRESHOLD);
    wire wr_irq_status  = sel && we && (offset == OFF_IRQ_STATUS);
    wire wr_irq_enable  = sel && we && (offset == OFF_IRQ_ENABLE);
    wire do_stats_clear = wr_ctrl && wdata[1];

    // ----------------------------------------------------------------
    // 레지스터 선언
    // ----------------------------------------------------------------
    reg        enable_meas;
    reg [31:0] period_min;
    reg [31:0] period_max;
    reg [31:0] period_last;
    reg [31:0] overrun_cnt;
    reg [31:0] threshold;
    reg        irq_status;
    reg        irq_enable;

    // 주기 측정 카운터 및 상태
    reg [31:0] cnt;
    reg        first_tick;   // 첫 번째 에지는 카운터 초기화만

    // ----------------------------------------------------------------
    // 단일 always 블록: 버스 쓰기(우선) + 측정 로직
    // 버스 쓰기와 측정이 같은 사이클에 겹치면 버스 쓰기를 우선한다.
    // ----------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable_meas  <= 1'b0;
            period_min   <= 32'hFFFF_FFFF;
            period_max   <= 32'h0;
            period_last  <= 32'h0;
            overrun_cnt  <= 32'h0;
            threshold    <= 32'h0;
            irq_status   <= 1'b0;
            irq_enable   <= 1'b0;
            cnt          <= 32'h0;
            first_tick   <= 1'b1;
        end else if (do_stats_clear) begin
            // CTRL[1]=1 쓰기: 통계 초기화 (enable_meas도 CTRL[0]으로 갱신)
            enable_meas  <= wdata[0];
            period_min   <= 32'hFFFF_FFFF;
            period_max   <= 32'h0;
            period_last  <= 32'h0;
            overrun_cnt  <= 32'h0;
            irq_status   <= 1'b0;
            cnt          <= 32'h0;
            first_tick   <= 1'b1;
        end else begin
            // --- 버스 쓰기 처리 ---
            if (wr_ctrl)       enable_meas  <= wdata[0];
            if (wr_threshold)  threshold    <= wdata;
            if (wr_irq_status) irq_status   <= irq_status & ~wdata[0]; // W1C
            if (wr_irq_enable) irq_enable   <= wdata[0];

            // --- 측정 로직 (enable_meas 중에만) ---
            if (enable_meas) begin
                cnt <= cnt + 32'h1;
                if (tick_rise) begin
                    if (first_tick) begin
                        // 첫 에지: 카운터만 초기화, 통계는 아직 없음
                        cnt        <= 32'h0;
                        first_tick <= 1'b0;
                    end else begin
                        // 두 번째 에지부터: 주기 기록 및 통계 갱신
                        period_last <= cnt;
                        if (cnt < period_min) period_min <= cnt;
                        if (cnt > period_max) period_max <= cnt;
                        // 오버런 검출: threshold!=0 && 주기 > threshold
                        if ((threshold != 32'h0) && (cnt > threshold)) begin
                            if (overrun_cnt != 32'hFFFF_FFFF) // 포화 방지
                                overrun_cnt <= overrun_cnt + 32'h1;
                            irq_status <= 1'b1;
                        end
                        cnt <= 32'h0;
                    end
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // 읽기 MUX (조합)
    // ----------------------------------------------------------------
    always @(*) begin
        case (offset)
            OFF_CTRL:        rdata = {30'h0, 1'b0, enable_meas}; // bit[1]은 always 0
            OFF_PERIOD_MIN:  rdata = period_min;
            OFF_PERIOD_MAX:  rdata = period_max;
            OFF_PERIOD_LAST: rdata = period_last;
            OFF_OVERRUN_CNT: rdata = overrun_cnt;
            OFF_THRESHOLD:   rdata = threshold;
            OFF_ID:          rdata = CONST_ID;
            OFF_VER:         rdata = CONST_VER;
            OFF_IRQ_STATUS:  rdata = {31'h0, irq_status};
            OFF_IRQ_ENABLE:  rdata = {31'h0, irq_enable};
            default:         rdata = 32'h0;
        endcase
    end

    // ----------------------------------------------------------------
    // 인터럽트 출력 (레벨)
    // ----------------------------------------------------------------
    assign irq = irq_status & irq_enable;

endmodule
