// xadc_pwr_mon_ip.v
// Artix-7 XADC 전원 감시 AXI4-Lite IP
// 내부 공급 전압 채널(Vccint/Vccaux/Vccbram)을 DRP로 읽어 임계값 위반 시 IRQ 발생.
// 외부 부품 없음 — XADC 온다이 채널만 사용.
// Verilog-2001. iverilog/verilator/yosys 호환.
// 출처: capstones/mmio-xadc-pwr-mon/capstone.json
`default_nettype none
`timescale 1ns/1ps

module xadc_pwr_mon_ip #(
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
    // DRP interface (to XADC primitive or simulation model)
    output reg         drp_den,
    output wire        drp_dwe,
    output reg  [6:0]  drp_daddr,
    output wire [15:0] drp_di,
    input  wire [15:0] drp_do,
    input  wire        drp_drdy,
    // Interrupt output
    output wire        irq
);

    // -----------------------------------------------------------------------
    // XADC 내부 공급 전압 DRP 상태 레지스터 주소 (Artix-7 UG480 Table 2-6)
    // -----------------------------------------------------------------------
    localparam [6:0] DRP_VCCINT  = 7'h01;  // Vccint  결과 (~1.0V 공칭)
    localparam [6:0] DRP_VCCAUX  = 7'h02;  // Vccaux  결과 (~1.8V 공칭)
    localparam [6:0] DRP_VCCBRAM = 7'h06;  // Vccbram 결과 (~1.0V 공칭)

    // DRP는 읽기 전용으로만 사용; 쓰기 없음
    assign drp_dwe = 1'b0;
    assign drp_di  = 16'h0;

    // -----------------------------------------------------------------------
    // 레지스터 오프셋 (기저 주소 BASE_ADDR 기준, [15:0] 사용)
    // -----------------------------------------------------------------------
    localparam [15:0]
        REG_CTRL        = 16'h0000,  // [0]=en [1]=auto (RW)
        REG_STATUS      = 16'h0004,  // [0]=busy [5:3]=viol_live (RO)
        REG_VCCINT      = 16'h0008,  // [15:4]=12비트 원시값 (RO)
        REG_VCCAUX      = 16'h000C,  // [15:4]=12비트 원시값 (RO)
        REG_VCCBRAM     = 16'h0010,  // [15:4]=12비트 원시값 (RO)
        REG_THR_INT_LO  = 16'h0014,  // [11:0]=Vccint 하한 (RW)
        REG_THR_INT_HI  = 16'h0018,  // [11:0]=Vccint 상한 (RW)
        REG_THR_AUX_LO  = 16'h001C,  // [11:0]=Vccaux 하한 (RW)
        REG_THR_AUX_HI  = 16'h0020,  // [11:0]=Vccaux 상한 (RW)
        REG_THR_BRAM_LO = 16'h0024,  // [11:0]=Vccbram 하한 (RW)
        REG_THR_BRAM_HI = 16'h0028,  // [11:0]=Vccbram 상한 (RW)
        REG_IP_ID       = 16'hFFF0,  // 0x5041_584D "PAXM" (RO)
        REG_IP_VER      = 16'hFFF4,  // 0x0000_0100 Rev1.0 (RO)
        REG_IRQ_STATUS  = 16'hFFF8,  // [2:0]=viol (W1C)
        REG_IRQ_ENABLE  = 16'hFFFC;  // [2:0]=마스크 (RW)

    // IP_ID 아스키: "XAPM" = 0x5841_504D
    localparam [31:0] IP_ID  = 32'h5841_504D;
    localparam [31:0] IP_VER = 32'h0000_0100;

    // -----------------------------------------------------------------------
    // DRP FSM 상태
    // -----------------------------------------------------------------------
    localparam [2:0]
        F_IDLE  = 3'd0,
        F_REQ1  = 3'd1,  // Vccint 읽기 요청
        F_WAI1  = 3'd2,  // Vccint drdy 대기
        F_REQ2  = 3'd3,  // Vccaux 읽기 요청
        F_WAI2  = 3'd4,  // Vccaux drdy 대기
        F_REQ3  = 3'd5,  // Vccbram 읽기 요청
        F_WAI3  = 3'd6,  // Vccbram drdy 대기
        F_CMP   = 3'd7;  // 임계값 비교 → IDLE

    reg [2:0]  fsm;
    reg        ctrl_en;
    reg        ctrl_auto;

    // 판독값 (12비트, raw[15:4])
    reg [11:0] rd_vccint;
    reg [11:0] rd_vccaux;
    reg [11:0] rd_vccbram;

    // 임계값 레지스터
    reg [11:0] thr_int_lo;  reg [11:0] thr_int_hi;
    reg [11:0] thr_aux_lo;  reg [11:0] thr_aux_hi;
    reg [11:0] thr_bram_lo; reg [11:0] thr_bram_hi;

    // IRQ
    reg  [2:0] irq_status;   // W1C
    reg  [2:0] irq_enable;
    wire [2:0] viol;         // 현재 임계값 위반 조합

    // 자동 스캔 카운터 (1024 클럭마다 한 사이클)
    reg [9:0] auto_cnt;
    reg       scan_trig;
    reg       prev_en;    // ctrl_en 상승에지 감지용 (non-auto one-shot)

    // -----------------------------------------------------------------------
    // AXI4-Lite 쓰기 래치
    // -----------------------------------------------------------------------
    reg        aw_ok;
    reg [15:0] aw_a;
    reg        wd_ok;
    reg [31:0] wd_d;
    reg        do_wr;

    // -----------------------------------------------------------------------
    // 임계값 위반 로직
    // -----------------------------------------------------------------------
    assign viol[0] = (rd_vccint  < thr_int_lo)  | (rd_vccint  > thr_int_hi);
    assign viol[1] = (rd_vccaux  < thr_aux_lo)  | (rd_vccaux  > thr_aux_hi);
    assign viol[2] = (rd_vccbram < thr_bram_lo) | (rd_vccbram > thr_bram_hi);
    assign irq     = |(irq_status & irq_enable);

    // -----------------------------------------------------------------------
    // DRP FSM — 세 채널 순차 읽기
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            fsm       <= F_IDLE;
            drp_den   <= 1'b0;
            drp_daddr <= 7'h0;
            scan_trig <= 1'b0;
            auto_cnt  <= 10'd0;
            prev_en   <= 1'b0;
        end else begin
            drp_den   <= 1'b0;  // 기본값 (1사이클 펄스)
            scan_trig <= 1'b0;
            prev_en   <= ctrl_en;  // 상승에지 감지를 위해 이전 값 저장

            // 자동 스캔 트리거
            if (ctrl_auto && ctrl_en) begin
                if (auto_cnt == 10'd1023) begin
                    auto_cnt  <= 10'd0;
                    scan_trig <= (fsm == F_IDLE);
                end else
                    auto_cnt <= auto_cnt + 10'd1;
            end else
                auto_cnt <= 10'd0;

            case (fsm)
                F_IDLE: begin
                    // non-auto 모드: ctrl_en 상승에지에서만 1회 트리거
                    if (scan_trig || (!ctrl_auto && ctrl_en && !prev_en))
                        fsm <= F_REQ1;
                end
                F_REQ1: begin
                    drp_den   <= 1'b1;
                    drp_daddr <= DRP_VCCINT;
                    fsm       <= F_WAI1;
                end
                F_WAI1: begin
                    if (drp_drdy) begin
                        rd_vccint <= drp_do[15:4];
                        fsm       <= F_REQ2;
                    end
                end
                F_REQ2: begin
                    drp_den   <= 1'b1;
                    drp_daddr <= DRP_VCCAUX;
                    fsm       <= F_WAI2;
                end
                F_WAI2: begin
                    if (drp_drdy) begin
                        rd_vccaux <= drp_do[15:4];
                        fsm       <= F_REQ3;
                    end
                end
                F_REQ3: begin
                    drp_den   <= 1'b1;
                    drp_daddr <= DRP_VCCBRAM;
                    fsm       <= F_WAI3;
                end
                F_WAI3: begin
                    if (drp_drdy) begin
                        rd_vccbram <= drp_do[15:4];
                        fsm        <= F_CMP;
                    end
                end
                F_CMP: begin
                    // 임계값 비교 후 IRQ_STATUS OR-업데이트
                    irq_status <= irq_status | viol;
                    fsm        <= F_IDLE;
                end
                default: fsm <= F_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite 슬레이브 — 쓰기 채널
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_ok <= 1'b0; wd_ok <= 1'b0; do_wr <= 1'b0;
            aw_a  <= 16'h0; wd_d  <= 32'h0;
        end else begin
            do_wr <= 1'b0;
            if (!aw_ok) begin
                if (s_axi_awvalid) begin
                    aw_a          <= s_axi_awaddr[15:0];
                    aw_ok         <= 1'b1;
                    s_axi_awready <= 1'b1;
                end
            end else
                s_axi_awready <= 1'b0;

            if (!wd_ok) begin
                if (s_axi_wvalid) begin
                    wd_d          <= s_axi_wdata;
                    wd_ok         <= 1'b1;
                    s_axi_wready  <= 1'b1;
                end
            end else
                s_axi_wready <= 1'b0;

            if (aw_ok && wd_ok && !s_axi_bvalid) begin
                do_wr  <= 1'b1;
                aw_ok  <= 1'b0;
                wd_ok  <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite 슬레이브 — 읽기 채널
    // -----------------------------------------------------------------------
    reg [15:0] ar_a;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
            s_axi_rresp   <= 2'b00;
            ar_a          <= 16'h0;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                ar_a          <= s_axi_araddr[15:0];
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                // 읽기 디코더
                case (s_axi_araddr[15:0])
                    REG_CTRL:        s_axi_rdata <= {30'h0, ctrl_auto, ctrl_en};
                    REG_STATUS:      s_axi_rdata <= {26'h0, viol, (fsm != F_IDLE)};
                    REG_VCCINT:      s_axi_rdata <= {16'h0, rd_vccint, 4'h0};
                    REG_VCCAUX:      s_axi_rdata <= {16'h0, rd_vccaux, 4'h0};
                    REG_VCCBRAM:     s_axi_rdata <= {16'h0, rd_vccbram, 4'h0};
                    REG_THR_INT_LO:  s_axi_rdata <= {20'h0, thr_int_lo};
                    REG_THR_INT_HI:  s_axi_rdata <= {20'h0, thr_int_hi};
                    REG_THR_AUX_LO:  s_axi_rdata <= {20'h0, thr_aux_lo};
                    REG_THR_AUX_HI:  s_axi_rdata <= {20'h0, thr_aux_hi};
                    REG_THR_BRAM_LO: s_axi_rdata <= {20'h0, thr_bram_lo};
                    REG_THR_BRAM_HI: s_axi_rdata <= {20'h0, thr_bram_hi};
                    REG_IP_ID:       s_axi_rdata <= IP_ID;
                    REG_IP_VER:      s_axi_rdata <= IP_VER;
                    REG_IRQ_STATUS:  s_axi_rdata <= {29'h0, irq_status};
                    REG_IRQ_ENABLE:  s_axi_rdata <= {29'h0, irq_enable};
                    default:         s_axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end else
                s_axi_arready <= 1'b0;

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end

    // -----------------------------------------------------------------------
    // 쓰기 디코더 (do_wr 펄스)
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            ctrl_en      <= 1'b0;
            ctrl_auto    <= 1'b0;
            thr_int_lo   <= 12'h000; thr_int_hi   <= 12'hFFF;
            thr_aux_lo   <= 12'h000; thr_aux_hi   <= 12'hFFF;
            thr_bram_lo  <= 12'h000; thr_bram_hi  <= 12'hFFF;
            irq_status   <= 3'b000;
            irq_enable   <= 3'b000;
        end else if (do_wr) begin
            case (aw_a)
                REG_CTRL:        {ctrl_auto, ctrl_en} <= wd_d[1:0];
                REG_THR_INT_LO:  thr_int_lo   <= wd_d[11:0];
                REG_THR_INT_HI:  thr_int_hi   <= wd_d[11:0];
                REG_THR_AUX_LO:  thr_aux_lo   <= wd_d[11:0];
                REG_THR_AUX_HI:  thr_aux_hi   <= wd_d[11:0];
                REG_THR_BRAM_LO: thr_bram_lo  <= wd_d[11:0];
                REG_THR_BRAM_HI: thr_bram_hi  <= wd_d[11:0];
                REG_IRQ_STATUS:  irq_status   <= irq_status & ~wd_d[2:0]; // W1C
                REG_IRQ_ENABLE:  irq_enable   <= wd_d[2:0];
                default: ;
            endcase
        end
    end

endmodule
`default_nettype wire
