// basys3_jitter_mon_top.v — Basys3 최상위 (합성·보드 시연용, Verilog-2001)
// 하네스 직접 작성 원본.
//
// 역할:
//   1. 100 MHz → 1 kHz 틱 발생 (100,000 클럭 분주, 보드 시연용)
//   2. 리셋 후 2클럭 동안 cfg_fsm이 jmon IP를 초기화:
//        - THRESHOLD = 150000 (1.5 ms @ 100 MHz)
//        - CTRL      = 0x1 (enable_meas=1)
//   3. 이후 idle: tick_in=tick_1khz, 출력 표시
//      LED[15]   = irq (오버런 감지)
//      LED[7:0]  = overrun_cnt 최하위 8비트 (읽기는 cfg_fsm이 하지 않음;
//                  보드 시연에서는 IRQ만 표시, overrun_cnt는 보드 연결에서 생략)
//
// 참고: LED[7:0]은 irq 신호와 1kHz 틱 토글로 단순 표시.
//       정밀한 보드 검증(S3)은 사용자가 Vitis/로직 애널라이저로 수행.
//
`timescale 1ns/1ps
module basys3_jitter_mon_top (
    input  wire        clk,    // W5, 100 MHz
    input  wire        btnC,   // U18, 센터 버튼 → 리셋 (액티브 하이)
    output wire [15:0] led     // 상태 LED
);

    // ----------------------------------------------------------------
    // 버튼 2단 동기화 → 리셋
    // ----------------------------------------------------------------
    reg btn_s1, btn_s2;
    always @(posedge clk) begin
        btn_s1 <= btnC;
        btn_s2 <= btn_s1;
    end
    wire rst = btn_s2;

    // ----------------------------------------------------------------
    // 1 kHz 틱 생성 (100,000 클럭 분주)
    // ----------------------------------------------------------------
    localparam integer TICK_DIV = 100_000;
    reg [16:0] tick_cnt;  // ceil(log2(100000)) = 17
    reg        tick_1khz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt  <= 17'd0;
            tick_1khz <= 1'b0;
        end else if (tick_cnt >= TICK_DIV - 1) begin
            tick_cnt  <= 17'd0;
            tick_1khz <= ~tick_1khz;
        end else begin
            tick_cnt <= tick_cnt + 17'd1;
        end
    end

    // ----------------------------------------------------------------
    // cfg_fsm: 리셋 후 jmon IP 초기화 (2단계)
    // 상태:
    //   2'h0: THRESHOLD = 150000 쓰기
    //   2'h1: CTRL      = 0x1   쓰기
    //   2'h2: idle (버스 비활성)
    // ----------------------------------------------------------------
    reg [1:0]  cfg_state;
    reg        jmon_sel;
    reg        jmon_we;
    reg [15:0] jmon_offset;
    reg [31:0] jmon_wdata;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cfg_state  <= 2'h0;
            jmon_sel   <= 1'b0;
            jmon_we    <= 1'b0;
            jmon_offset <= 16'h0;
            jmon_wdata  <= 32'h0;
        end else begin
            // 기본: 버스 비활성
            jmon_sel <= 1'b0;
            jmon_we  <= 1'b0;
            case (cfg_state)
                2'h0: begin
                    // THRESHOLD = 150000 (1.5 ms @ 100 MHz)
                    jmon_sel    <= 1'b1;
                    jmon_we     <= 1'b1;
                    jmon_offset <= 16'h0014; // OFF_THRESHOLD
                    jmon_wdata  <= 32'd150_000;
                    cfg_state   <= 2'h1;
                end
                2'h1: begin
                    // CTRL: enable_meas=1, stats_clear=0
                    jmon_sel    <= 1'b1;
                    jmon_we     <= 1'b1;
                    jmon_offset <= 16'h0000; // OFF_CTRL
                    jmon_wdata  <= 32'h0000_0001;
                    cfg_state   <= 2'h2;
                end
                2'h2: begin
                    // idle: 버스 접근 없음
                    cfg_state <= 2'h2;
                end
                default: cfg_state <= 2'h2;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // loop_jitter_mon 인스턴스
    // ----------------------------------------------------------------
    wire [31:0] jmon_rdata;
    wire        jmon_irq;

    loop_jitter_mon u_jmon (
        .clk     (clk),
        .rst     (rst),
        .tick_in (tick_1khz),
        .sel     (jmon_sel),
        .we      (jmon_we),
        .offset  (jmon_offset),
        .wdata   (jmon_wdata),
        .rdata   (jmon_rdata),
        .irq     (jmon_irq)
    );

    // ----------------------------------------------------------------
    // LED 출력
    //   LED[15]   = irq (오버런 감지)
    //   LED[14]   = tick_1khz (동작 확인용 하트비트)
    //   LED[13:0] = 미사용 (0)
    // ----------------------------------------------------------------
    assign led[15]   = jmon_irq;
    assign led[14]   = tick_1khz;
    assign led[13:0] = 14'h0;

    // verilator lint_off UNUSED
    wire [31:0] _unused_rdata = jmon_rdata;
    // verilator lint_on UNUSED

endmodule
