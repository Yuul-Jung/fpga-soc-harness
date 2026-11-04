// basys3_top.v — Basys3 보드 래퍼
// 100MHz 시스템 클럭, btnC 리셋, Pmod JA 모터 출력
// 내장 AXI4-Lite 데모 마스터: 리셋 후 레지스터 설정 → 모터 1회 가동
// 출처: 하네스 직접 작성 Verilog-2001 원본
`default_nettype none
`timescale 1ns/1ps

module basys3_top (
    input  wire       clk,          // 100 MHz
    input  wire       btnC,         // synchronous reset (active high)
    input  wire [1:0] sw,           // sw[0]=STEP_DIR mode, sw[1]=HALF_STEP
    output wire [3:0] jaMon,        // Pmod JA[3:0] → ULN2003 IN1~IN4
    output wire       jaStep,       // Pmod JA[4] → A4988 STEP (STEP/DIR mode)
    output wire       jaDir,        // Pmod JA[5] → A4988 DIR
    output wire [3:0] led,          // LED[3:0] = coil 패턴
    output wire       led_irq,      // LED[15] = IRQ 상태
    output wire       led_busy      // LED[14] = BUSY
);
    wire rst = btnC;

    // ── AXI4-Lite 버스 ───────────────────────────────────────────
    reg  [15:0] m_awaddr;  reg  m_awvalid;  wire m_awready;
    reg  [31:0] m_wdata;   reg  m_wvalid;   wire m_wready;
    wire [1:0]  m_bresp;   wire m_bvalid;   reg  m_bready;
    reg  [15:0] m_araddr;  reg  m_arvalid;  wire m_arready;
    wire [31:0] m_rdata;   wire [1:0] m_rresp; wire m_rvalid; reg m_rready;

    wire [3:0] coil_w;
    wire       step_w, dir_w, irq_w;

    axil_stepper u_ip (
        .clk(clk), .rst(rst),
        .s_awaddr(m_awaddr), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata),   .s_wvalid(m_wvalid),   .s_wready(m_wready),
        .s_bresp(m_bresp),   .s_bvalid(m_bvalid),   .s_bready(m_bready),
        .s_araddr(m_araddr), .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata(m_rdata),   .s_rresp(m_rresp),     .s_rvalid(m_rvalid),
        .s_rready(m_rready),
        .coil(coil_w), .step_out(step_w), .dir_out(dir_w), .irq(irq_w)
    );

    assign jaMon  = coil_w;
    assign jaStep = step_w;
    assign jaDir  = dir_w;
    assign led      = coil_w;
    assign led_irq  = irq_w;
    assign led_busy = 1'b0; // core_busy는 IP 내부 — 별도 읽기 생략

    // ── 데모 마스터 FSM ──────────────────────────────────────────
    // 리셋 후 순서: 레지스터 5개 쓰기 → CTRL START → 대기
    localparam W0 = 4'd0, W1 = 4'd1, W2 = 4'd2, W3 = 4'd3, W4 = 4'd4,
               W5 = 4'd5, WAIT_B = 4'd6, START = 4'd7,
               WAIT_B2 = 4'd8, IDLE2 = 4'd9;

    reg [3:0] ms;
    reg       wr_sent;

    // 보드에서 TARGET=32768(반상 8바퀴), MIN=200000, MAX=5000000, DELTA=10000
    // 시뮬에선 tb가 직접 AXI를 구동하므로 basys3_top은 보드 전용
    localparam T_TARGET = 24'd32768;
    localparam T_MIN_P  = 24'd200000;
    localparam T_MAX_P  = 24'd5000000;
    localparam T_DELTA  = 16'd10000;

    always @(posedge clk) begin
        if (rst) begin
            ms        <= W0;
            m_awvalid <= 1'b0; m_wvalid  <= 1'b0; m_bready  <= 1'b1;
            m_arvalid <= 1'b0; m_rready  <= 1'b1;
            m_awaddr  <= 16'b0; m_wdata  <= 32'b0;
            wr_sent   <= 1'b0;
        end else begin
            // bresp 자동 수락
            if (m_bvalid && m_bready) begin
                m_awvalid <= 1'b0;
                m_wvalid  <= 1'b0;
            end

            case (ms)
            W0: begin // TARGET_STEPS
                m_awaddr <= 16'h0004; m_wdata <= {8'b0, T_TARGET};
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= W1;
            end
            W1: begin // MIN_PERIOD
                m_awaddr <= 16'h0008; m_wdata <= {8'b0, T_MIN_P};
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= W2;
            end
            W2: begin // MAX_PERIOD
                m_awaddr <= 16'h000C; m_wdata <= {8'b0, T_MAX_P};
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= W3;
            end
            W3: begin // DELTA
                m_awaddr <= 16'h0010; m_wdata <= {16'b0, T_DELTA};
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= W4;
            end
            W4: begin // MODE (from switches)
                m_awaddr <= 16'h0014; m_wdata <= {30'b0, sw};
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= W5;
            end
            W5: begin // IRQ_ENABLE
                m_awaddr <= 16'hFFFC; m_wdata <= 32'h1;
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= START;
            end
            START: begin // CTRL START
                m_awaddr <= 16'h0000; m_wdata <= 32'h1;
                m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                if (m_awready && m_awvalid) ms <= IDLE2;
            end
            IDLE2: begin
                m_awvalid <= 1'b0; m_wvalid <= 1'b0;
                // IRQ가 오면 클리어 (간단 구현: IRQ 발생 시 W1C)
                if (irq_w && !wr_sent) begin
                    m_awaddr <= 16'hFFF8; m_wdata <= 32'h1;
                    m_awvalid <= 1'b1; m_wvalid <= 1'b1;
                    wr_sent <= 1'b1;
                end
            end
            default: ms <= W0;
            endcase
        end
    end

endmodule
`default_nettype wire
