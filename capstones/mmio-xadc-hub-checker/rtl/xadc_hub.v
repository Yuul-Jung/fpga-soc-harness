// xadc_hub.v
// XADC Hub IP 최상위: drp_ctrl + avg_unit + xadc_regs
// 시뮬레이션: `ifdef SIMULATION → xadc_drp_model 사용
// 합성: XADC 프리미티브 (Yosys 블랙박스)

module xadc_hub (
    input  wire        clk,
    input  wire        rst,

    // mmio-lite 슬레이브 포트
    input  wire [15:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire        we,
    input  wire        req,
    output wire        ack,

    // 보드 아날로그 입력 (합성 시에만 의미 있음)
    input  wire        vauxp4,  vauxn4,
    input  wire        vauxp5,  vauxn5,
    input  wire        vauxp12, vauxn12,
    input  wire        vauxp13, vauxn13,

    output wire        irq
);

    // CTRL 필드
    wire [1:0] avg_len;
    wire       irq_en;
    wire       scan_en;

    // DRP 인터페이스
    wire       eoc;
    wire       den;
    wire [6:0] daddr;
    wire       drdy;
    wire [15:0] dout;

    // 채널 raw + valid
    wire [11:0] raw_ch [0:3];
    wire [3:0]  ch_valid;

    // 이동 평균 출력
    wire [11:0] avg_out_0, avg_out_1, avg_out_2, avg_out_3;

    // busy: 현재 스캔 중 여부
    wire busy = |ch_valid;

    // ============================================================
    // DRP FSM
    // ============================================================
    xadc_drp_ctrl u_drp (
        .clk     (clk),
        .rst     (rst),
        .scan_en (scan_en),
        .eoc     (eoc),
        .den     (den),
        .daddr   (daddr),
        .drdy    (drdy),
        .dout    (dout),
        .raw_ch  (raw_ch),
        .valid   (ch_valid)
    );

    // ============================================================
    // 이동 평균
    // ============================================================
    xadc_avg u_avg (
        .clk           (clk),
        .rst           (rst),
        .avg_len       (avg_len),
        .sample_valid  (ch_valid),
        .sample_data_0 (raw_ch[0]),
        .sample_data_1 (raw_ch[1]),
        .sample_data_2 (raw_ch[2]),
        .sample_data_3 (raw_ch[3]),
        .avg_out_0     (avg_out_0),
        .avg_out_1     (avg_out_1),
        .avg_out_2     (avg_out_2),
        .avg_out_3     (avg_out_3)
    );

    // ============================================================
    // 레지스터 맵
    // ============================================================
    xadc_regs u_regs (
        .clk      (clk),
        .rst      (rst),
        .addr     (addr),
        .wdata    (wdata),
        .rdata    (rdata),
        .we       (we),
        .req      (req),
        .ack      (ack),
        .avg_len  (avg_len),
        .irq_en   (irq_en),
        .scan_en  (scan_en),
        .busy     (busy),
        .ch_valid (ch_valid),
        .ch_raw_0 (raw_ch[0]),
        .ch_raw_1 (raw_ch[1]),
        .ch_raw_2 (raw_ch[2]),
        .ch_raw_3 (raw_ch[3]),
        .ch_avg_0 (avg_out_0),
        .ch_avg_1 (avg_out_1),
        .ch_avg_2 (avg_out_2),
        .ch_avg_3 (avg_out_3),
        .irq      (irq)
    );

    // ============================================================
    // XADC 프리미티브 or 시뮬레이션 모델
    // ============================================================
`ifdef SIMULATION
    xadc_drp_model u_xadc (
        .dclk  (clk),
        .rst   (rst),
        .den   (den),
        .daddr (daddr),
        .drdy  (drdy),
        .do    (dout),
        .eoc   (eoc)
    );
`else
    // Xilinx XADC 프리미티브 (합성 전용; Yosys가 블랙박스로 처리)
    // VAUXP/N 버스: bit[n] = VAUXP/N[n]
    wire [15:0] vauxp_bus;
    wire [15:0] vauxn_bus;
    assign vauxp_bus = { 2'b0, vauxp13, vauxp12,
                         6'b0, vauxp5,  vauxp4, 4'b0 };
    assign vauxn_bus = { 2'b0, vauxn13, vauxn12,
                         6'b0, vauxn5,  vauxn4, 4'b0 };

    XADC #(
        .INIT_40 (16'h9000),
        .INIT_41 (16'h2F0F),
        .INIT_42 (16'h0400),
        .INIT_48 (16'h0800),
        .INIT_49 (16'h3000),
        .INIT_4D (16'h3000),
        .SIM_MONITOR_FILE ("design.txt")
    ) INST_XADC (
        .DCLK    (clk),
        .RESET   (rst),
        .DEN     (den),
        .DWE     (1'b0),
        .DADDR   (daddr),
        .DI      (16'h0000),
        .DO      (dout),
        .DRDY    (drdy),
        .EOC     (eoc),
        .BUSY    (),
        .CHANNEL (),
        .EOS     (),
        .JTAGLOCKED (),
        .JTAGMODIFIED (),
        .JTAGBUSY (),
        .OT      (),
        .ALM     (),
        .VAUXP   (vauxp_bus),
        .VAUXN   (vauxn_bus),
        .VP      (1'b0),
        .VN      (1'b0),
        .CONVSTCLK (1'b0),
        .CONVST    (1'b0),
        .MUXADDR   ()
    );
`endif

endmodule
