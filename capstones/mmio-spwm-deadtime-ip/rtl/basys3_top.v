// basys3_top.v — mmio-spwm-deadtime-ip 보드 최상위 래퍼
// Basys3(XC7A35T) 독립 데모: 리셋 후 demo_master가 AXI4-Lite write로
// SPWM IP를 초기화(PERIOD=5000, MOD_IDX=26214, DEADTIME=50, EN=1).
// SPWM 출력 HIN_A/LIN_A/HIN_B/LIN_B는 Pmod JB 헤더(핀 1~4)에 연결.
// MicroBlaze V 통합 시 demo_master 제거, MBv가 AXI 마스터가 된다.
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none
`timescale 1ns/1ps

module basys3_top (
    input  wire        clk,         // W5, 100 MHz
    input  wire        btnC,        // T18, 리셋 (active high)
    // Pmod JB (H16/G16/F15/F16/G15/H14/G14/F14) — 상단 4핀 사용
    output wire        jb1,         // HIN_A → JB1
    output wire        jb2,         // LIN_A → JB2
    output wire        jb3,         // HIN_B → JB3
    output wire        jb4,         // LIN_B → JB4
    // 상태 LED
    output wire [15:0] led          // [3:0]=hin_a,lin_a,hin_b,lin_b [4]=trip [15:5]=0
);

    wire aresetn = ~btnC;

    // -----------------------------------------------------------------------
    // AXI4-Lite 버스 신호 (demo_master ↔ spwm_ip)
    // -----------------------------------------------------------------------
    wire [31:0] m_awaddr;
    wire        m_awvalid;
    wire        m_awready;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire        m_wvalid;
    wire        m_wready;
    wire [1:0]  m_bresp;
    wire        m_bvalid;
    wire        m_bready;
    wire [31:0] m_araddr;
    wire        m_arvalid;
    wire        m_arready;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rvalid;
    wire        m_rready;

    // SPWM 출력
    wire hin_a, lin_a, hin_b, lin_b, irq;

    // -----------------------------------------------------------------------
    // demo_master: 리셋 후 레지스터 순서대로 쓰는 AXI 마스터 FSM
    // 쓰기 순서: PERIOD → MOD_IDX → DEADTIME → CTRL(EN=1)
    // -----------------------------------------------------------------------
    demo_master #(
        .BASE (32'h4016_0000)
    ) u_demo (
        .clk       (clk),
        .resetn    (aresetn),
        .m_awaddr  (m_awaddr),
        .m_awvalid (m_awvalid),
        .m_awready (m_awready),
        .m_wdata   (m_wdata),
        .m_wstrb   (m_wstrb),
        .m_wvalid  (m_wvalid),
        .m_wready  (m_wready),
        .m_bvalid  (m_bvalid),
        .m_bready  (m_bready)
    );

    // -----------------------------------------------------------------------
    // spwm_ip 인스턴스
    // -----------------------------------------------------------------------
    spwm_ip #(
        .BASE_ADDR (32'h4016_0000)
    ) u_ip (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (aresetn),
        .s_axi_awaddr  (m_awaddr),
        .s_axi_awvalid (m_awvalid),
        .s_axi_awready (m_awready),
        .s_axi_wdata   (m_wdata),
        .s_axi_wstrb   (m_wstrb),
        .s_axi_wvalid  (m_wvalid),
        .s_axi_wready  (m_wready),
        .s_axi_bresp   (m_bresp),
        .s_axi_bvalid  (m_bvalid),
        .s_axi_bready  (m_bready),
        .s_axi_araddr  (32'h0),
        .s_axi_arvalid (1'b0),
        .s_axi_arready (m_arready),
        .s_axi_rdata   (m_rdata),
        .s_axi_rresp   (m_rresp),
        .s_axi_rvalid  (m_rvalid),
        .s_axi_rready  (1'b1),
        .trip_in       (1'b0),
        .hin_a         (hin_a),
        .lin_a         (lin_a),
        .hin_b         (hin_b),
        .lin_b         (lin_b),
        .irq           (irq)
    );

    // Pmod JB 출력
    assign jb1 = hin_a;
    assign jb2 = lin_a;
    assign jb3 = hin_b;
    assign jb4 = lin_b;

    // 상태 LED
    assign led = {11'b0, irq, lin_b, hin_b, lin_a, hin_a};

endmodule

// ---------------------------------------------------------------------------
// demo_master: 순차 AXI4-Lite write 마스터 (CTRL/PERIOD/MOD_IDX/DEADTIME)
// ---------------------------------------------------------------------------
module demo_master #(
    parameter [31:0] BASE = 32'h4016_0000
) (
    input  wire        clk,
    input  wire        resetn,
    // AXI4-Lite write only
    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,
    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wvalid,
    input  wire        m_wready,
    input  wire        m_bvalid,
    output wire        m_bready
);
    assign m_bready = 1'b1;

    // 쓰기 목록: (offset, data)
    // 0=PERIOD=5000, 1=MOD_IDX=26214, 2=DEADTIME=50, 3=CTRL.EN=1
    reg [2:0] step;
    reg       done;

    // 각 단계 주소/데이터
    function [31:0] cfg_addr;
        input [2:0] s;
        begin
            case (s)
            3'd0: cfg_addr = BASE + 32'h04; // PERIOD
            3'd1: cfg_addr = BASE + 32'h08; // MOD_IDX
            3'd2: cfg_addr = BASE + 32'h0C; // DEADTIME
            3'd3: cfg_addr = BASE + 32'h00; // CTRL
            default: cfg_addr = BASE;
            endcase
        end
    endfunction

    function [31:0] cfg_data;
        input [2:0] s;
        begin
            case (s)
            3'd0: cfg_data = 32'd5000;  // 10 kHz 반송파 @ 100 MHz
            3'd1: cfg_data = 32'd26214; // 80% 변조 지수
            3'd2: cfg_data = 32'd50;    // 500 ns 데드타임
            3'd3: cfg_data = 32'd1;     // EN=1
            default: cfg_data = 32'd0;
            endcase
        end
    endfunction

    reg [1:0] aw_st;  // 0=전송 대기 1=AW전송 2=W전송 3=B대기

    always @(posedge clk) begin
        if (!resetn) begin
            step      <= 3'd0;
            done      <= 1'b0;
            m_awvalid <= 1'b0;
            m_wvalid  <= 1'b0;
            m_awaddr  <= 32'h0;
            m_wdata   <= 32'h0;
            m_wstrb   <= 4'hF;
            aw_st     <= 2'd0;
        end else if (!done) begin
            case (aw_st)
            2'd0: begin // 주소+데이터 전송 시작
                m_awaddr  <= cfg_addr(step);
                m_wdata   <= cfg_data(step);
                m_wstrb   <= 4'hF;
                m_awvalid <= 1'b1;
                m_wvalid  <= 1'b1;
                aw_st     <= 2'd1;
            end
            2'd1: begin // AW와 W 핸드쉐이크 대기
                if (m_awready) m_awvalid <= 1'b0;
                if (m_wready)  m_wvalid  <= 1'b0;
                if (!m_awvalid && !m_wvalid) aw_st <= 2'd2;
                // 한쪽만 완료된 경우도 처리
                if (m_awready && m_awvalid) m_awvalid <= 1'b0;
                if (m_wready  && m_wvalid)  m_wvalid  <= 1'b0;
                if ((m_awready || !m_awvalid) && (m_wready || !m_wvalid))
                    aw_st <= 2'd2;
            end
            2'd2: begin // B 채널 완료 대기
                if (m_bvalid) begin
                    if (step == 3'd3)
                        done <= 1'b1;
                    else begin
                        step  <= step + 1'b1;
                        aw_st <= 2'd0;
                    end
                end
            end
            default: aw_st <= 2'd0;
            endcase
        end
    end

endmodule
