// basys3_top_onewire.v — Basys3 보드 최상위 래퍼 (1-Wire DS18B20 데모)
// 슬롯 [0E] 0x400E_0000  intc=6  (동결 맵 mbv-frozen-v2 §[0E])
//
// 이 래퍼는 axil_onewire_bm IP를 직접 AXI4-Lite로 구동하는
// demo_onewire 소프트웨어 대체 FSM을 포함한다.
// 실제 MicroBlaze V 통합 시 demo_onewire 블록을 CPU 연결로 대체한다.
//
// 연결:
//   Pmod JA[0] (pin 1) ← DQ 오픈드레인 출력 (ow_drive=1 → Low)
//   Pmod JA[0] (pin 1) → DQ 현재 값 (ow_sense, 외부 4.7 kΩ 풀업 to 3.3V)
//   LED[7]  — PRESENCE 감지 표시
//   LED[6]  — 마지막 읽은 비트(RBIT)
//   LED[5]  — BUSY
//   LED[4]  — IRQ 계류
//   7-세그 — 미사용 (상위 모듈에서 연결)

`default_nettype none
`timescale 1ns/1ps

// ============================================================
// 보드 최상위 래퍼
// ============================================================
module basys3_top_onewire (
    input  wire        clk,         // 100 MHz Basys3 시스템 클럭
    input  wire        btnC,        // 중앙 버튼 → active-high 리셋

    // Pmod JA — 1-Wire 오픈드레인
    output wire        JA_drive,    // JA[0] 출력: 1 → DQ Low 구동
    input  wire        JA_sense,    // JA[0] 입력: 풀업 경유 DQ 현재 값

    // 상태 LED
    output wire [7:0]  led
);

// ------------------------------------------------------------
// 리셋 동기화 (active-low)
// ------------------------------------------------------------
reg [3:0] rst_sr;
always @(posedge clk)
    rst_sr <= {rst_sr[2:0], btnC};
wire rst_n = ~rst_sr[3];

// ------------------------------------------------------------
// AXI4-Lite 버스 신호 (데모 FSM → axil_onewire_bm)
// ------------------------------------------------------------
reg  [31:0] m_awaddr;
reg         m_awvalid;
wire        m_awready;
reg  [31:0] m_wdata;
reg  [3:0]  m_wstrb;
reg         m_wvalid;
wire        m_wready;
wire [1:0]  m_bresp;
wire        m_bvalid;
reg         m_bready;

reg  [31:0] m_araddr;
reg         m_arvalid;
wire        m_arready;
wire [31:0] m_rdata;
wire [1:0]  m_rresp;
wire        m_rvalid;
reg         m_rready;

wire        irq_line;

// ------------------------------------------------------------
// axil_onewire_bm 인스턴스
// ------------------------------------------------------------
axil_onewire_bm #(
    .CLK_MHZ(100)
) u_ow (
    .clk            (clk),
    .rst_n          (rst_n),

    .s_axil_awaddr  (m_awaddr),
    .s_axil_awvalid (m_awvalid),
    .s_axil_awready (m_awready),
    .s_axil_wdata   (m_wdata),
    .s_axil_wstrb   (m_wstrb),
    .s_axil_wvalid  (m_wvalid),
    .s_axil_wready  (m_wready),
    .s_axil_bresp   (m_bresp),
    .s_axil_bvalid  (m_bvalid),
    .s_axil_bready  (m_bready),

    .s_axil_araddr  (m_araddr),
    .s_axil_arvalid (m_arvalid),
    .s_axil_arready (m_arready),
    .s_axil_rdata   (m_rdata),
    .s_axil_rresp   (m_rresp),
    .s_axil_rvalid  (m_rvalid),
    .s_axil_rready  (m_rready),

    .ow_drive       (JA_drive),
    .ow_sense       (JA_sense),
    .irq            (irq_line)
);

// ------------------------------------------------------------
// AXI4-Lite 쓰기 헬퍼 태스크 (합성 불가 task; FSM으로 대체)
// 아래 demo_onewire 모듈로 분리
// ------------------------------------------------------------

// ------------------------------------------------------------
// 데모 FSM: RST → WR(0xCC=SKIP ROM, LSB first) → WR(0x44=CONVERT T) →
//           RST → WR(0xCC) → WR(0xBE=READ SCRATCHPAD) →
//           RD×72비트(9바이트) → 존재 감지 LED 점등
// 실제 SoC에서는 이 블록을 MicroBlaze V C 드라이버로 대체한다.
// ------------------------------------------------------------

// 레지스터 오프셋 (기저 주소 없이, 하위 4비트만 사용)
localparam CTRL_OFF  = 32'h00; // 실제 주소는 TOP에서 더함
localparam START_OFF = 32'h08;
localparam ICLR_OFF  = 32'h0C;
localparam STAT_OFF  = 32'h04;

// CTRL 비트 필드
localparam OP_NOP   = 2'b00;
localparam OP_RST   = 2'b01;
localparam OP_WR    = 2'b10;
localparam OP_RD    = 2'b11;
// CTRL 비트: [16]=IRQ_EN, [2]=WBIT, [1:0]=OP

// 데모 FSM 상태
localparam D_IDLE        = 6'd0;
localparam D_SET_RST     = 6'd1;  // CTRL = RST
localparam D_START_RST   = 6'd2;  // START = 1
localparam D_WAIT_RST    = 6'd3;  // 완료 대기
localparam D_CHECK_PRES  = 6'd4;  // STATUS 읽기 → PRESENCE 확인
localparam D_SET_WR      = 6'd5;  // CTRL = WR + WBIT
localparam D_START_WR    = 6'd6;  // START = 1
localparam D_WAIT_WR     = 6'd7;  // 완료 대기
localparam D_SET_RD      = 6'd8;  // CTRL = RD
localparam D_START_RD    = 6'd9;  // START = 1
localparam D_WAIT_RD     = 6'd10; // 완료 대기
localparam D_READ_STAT   = 6'd11; // STATUS 읽기 → RBIT 수집
localparam D_DONE        = 6'd12; // 완료

// 커맨드 바이트 — LSB first 순서로 비트 추출
// SKIP ROM = 0xCC = 8'b1100_1100
// CONVERT T = 0x44 = 8'b0100_0100
// READ SCRATCHPAD = 0xBE = 8'b1011_1110
localparam [7:0] CMD_SKIP_ROM    = 8'hCC;
localparam [7:0] CMD_CONVERT_T   = 8'h44;
localparam [7:0] CMD_READ_SCPAD  = 8'hBE;

// 시퀀스 단계 인덱스 (총 비트 수)
// RST(1) + 8비트(SKIP) + 8비트(CONVERT T) + RST(1) + 8비트(SKIP) + 8비트(READSCPAD) + 72비트(RD) = 106단계
// 단순화: 비트 카운터와 커맨드 배열로 관리

reg  [5:0]  dstate;
reg  [5:0]  dstate_next_after_wait; // 대기 후 복귀할 상태
reg  [7:0]  cmd_byte;    // 현재 처리 중인 바이트
reg  [2:0]  bit_cnt;     // 현재 바이트의 비트 인덱스 (0=LSB)
reg  [3:0]  byte_step;   // 커맨드 시퀀스 단계
// byte_step: 0=SKIP1, 1=CONV_T, 2=SKIP2, 3=READ_SCPAD, 4~12=RD바이트0~8
reg  [71:0] rd_data;     // 9바이트(72비트) 수집 버퍼
reg  [6:0]  rd_bit_idx;  // 72비트 중 현재 비트 인덱스
reg         presence_lat;// 첫 RST 후 PRESENCE 래치

// AXI4-Lite 쓰기 단계 소형 FSM (내포)
localparam AXI_IDLE   = 2'd0;
localparam AXI_AW_W   = 2'd1; // AW·W 동시 발행
localparam AXI_B      = 2'd2; // B 채널 대기
localparam AXI_READ   = 2'd3; // AR 발행 → R 채널 대기

reg [1:0]  axi_state;
reg [31:0] axi_waddr_lat, axi_wdata_lat;
reg        axi_do_write; // 1사이클 펄스: 쓰기 트리거
reg        axi_do_read;  // 1사이클 펄스: 읽기 트리거
reg [31:0] axi_raddr_lat;
reg        axi_write_done;
reg        axi_read_done;
reg [31:0] axi_rdata_lat;

// AXI4-Lite 소형 FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_state     <= AXI_IDLE;
        m_awvalid     <= 1'b0; m_wvalid  <= 1'b0; m_bready  <= 1'b0;
        m_arvalid     <= 1'b0; m_rready  <= 1'b0;
        m_awaddr      <= 32'd0; m_wdata  <= 32'd0; m_wstrb   <= 4'hF;
        m_araddr      <= 32'd0;
        axi_write_done <= 1'b0;
        axi_read_done  <= 1'b0;
        axi_rdata_lat  <= 32'd0;
    end else begin
        axi_write_done <= 1'b0;
        axi_read_done  <= 1'b0;

        case (axi_state)
        AXI_IDLE: begin
            if (axi_do_write) begin
                m_awaddr  <= axi_waddr_lat;
                m_awvalid <= 1'b1;
                m_wdata   <= axi_wdata_lat;
                m_wstrb   <= 4'hF;
                m_wvalid  <= 1'b1;
                m_bready  <= 1'b1;
                axi_state <= AXI_AW_W;
            end else if (axi_do_read) begin
                m_araddr  <= axi_raddr_lat;
                m_arvalid <= 1'b1;
                m_rready  <= 1'b1;
                axi_state <= AXI_READ;
            end
        end
        AXI_AW_W: begin
            if (m_awready) m_awvalid <= 1'b0;
            if (m_wready)  m_wvalid  <= 1'b0;
            if (m_bvalid && m_bready) begin
                m_bready       <= 1'b0;
                axi_write_done <= 1'b1;
                axi_state      <= AXI_IDLE;
            end
        end
        AXI_READ: begin
            if (m_arready) m_arvalid <= 1'b0;
            if (m_rvalid && m_rready) begin
                m_rready      <= 1'b0;
                axi_rdata_lat <= m_rdata;
                axi_read_done <= 1'b1;
                axi_state     <= AXI_IDLE;
            end
        end
        default: axi_state <= AXI_IDLE;
        endcase
    end
end

// 데모 FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dstate        <= D_IDLE;
        axi_do_write  <= 1'b0;
        axi_do_read   <= 1'b0;
        axi_waddr_lat <= 32'd0;
        axi_wdata_lat <= 32'd0;
        axi_raddr_lat <= 32'd0;
        cmd_byte      <= 8'd0;
        bit_cnt       <= 3'd0;
        byte_step     <= 4'd0;
        rd_data       <= 72'd0;
        rd_bit_idx    <= 7'd0;
        presence_lat  <= 1'b0;
        dstate_next_after_wait <= D_IDLE;
    end else begin
        axi_do_write <= 1'b0;
        axi_do_read  <= 1'b0;

        case (dstate)
        // 1초 대기 후 RST
        D_IDLE: begin
            byte_step <= 4'd0;
            bit_cnt   <= 3'd0;
            rd_bit_idx <= 7'd0;
            rd_data   <= 72'd0;
            dstate    <= D_SET_RST;
        end

        // ── RST 연산 ──────────────────────────────
        D_SET_RST: begin
            if (axi_state == AXI_IDLE) begin
                axi_waddr_lat <= CTRL_OFF;
                axi_wdata_lat <= {15'd0, 1'b1, 13'd0, 1'b0, OP_RST}; // IRQ_EN=1, OP=RST
                axi_do_write  <= 1'b1;
                dstate        <= D_START_RST;
            end
        end
        D_START_RST: begin
            if (axi_write_done) begin
                axi_waddr_lat <= START_OFF;
                axi_wdata_lat <= 32'd1;
                axi_do_write  <= 1'b1;
                dstate        <= D_WAIT_RST;
            end
        end
        D_WAIT_RST: begin
            if (axi_write_done) begin
                // STATUS 읽기를 폴링으로 대기
                axi_raddr_lat <= STAT_OFF;
                axi_do_read   <= 1'b1;
                dstate        <= D_CHECK_PRES;
            end
        end
        D_CHECK_PRES: begin
            if (axi_read_done) begin
                if (axi_rdata_lat[0]) begin
                    // 아직 BUSY — 다시 읽기
                    axi_raddr_lat <= STAT_OFF;
                    axi_do_read   <= 1'b1;
                end else begin
                    presence_lat <= axi_rdata_lat[1]; // PRESENCE 비트
                    if (byte_step == 4'd0 || byte_step == 4'd3) begin
                        // 첫 RST 완료: SKIP ROM 커맨드 시작
                        // byte_step=0 → SKIP ROM before CONVERT T
                        // byte_step=3 → SKIP ROM before READ SCRATCHPAD
                        cmd_byte  <= (byte_step == 4'd0) ? CMD_SKIP_ROM : CMD_SKIP_ROM;
                        bit_cnt   <= 3'd0;
                        dstate    <= D_SET_WR;
                    end else begin
                        dstate <= D_DONE; // 비정상
                    end
                end
            end
        end

        // ── 바이트 쓰기 (LSB first) ──────────────
        D_SET_WR: begin
            if (axi_state == AXI_IDLE) begin
                axi_waddr_lat <= CTRL_OFF;
                axi_wdata_lat <= {15'd0, 1'b1, 12'd0, cmd_byte[bit_cnt], OP_WR};
                axi_do_write  <= 1'b1;
                dstate        <= D_START_WR;
            end
        end
        D_START_WR: begin
            if (axi_write_done) begin
                axi_waddr_lat <= START_OFF;
                axi_wdata_lat <= 32'd1;
                axi_do_write  <= 1'b1;
                dstate        <= D_WAIT_WR;
            end
        end
        D_WAIT_WR: begin
            if (axi_write_done) begin
                axi_raddr_lat <= STAT_OFF;
                axi_do_read   <= 1'b1;
                // 완료 후 다음 비트/바이트 계속
            end
            if (axi_read_done) begin
                if (axi_rdata_lat[0]) begin
                    // BUSY — 계속 폴링
                    axi_raddr_lat <= STAT_OFF;
                    axi_do_read   <= 1'b1;
                end else begin
                    // 비트 완료
                    if (bit_cnt == 3'd7) begin
                        // 현재 바이트 완료 → 다음 단계
                        bit_cnt <= 3'd0;
                        case (byte_step)
                        4'd0: begin // SKIP ROM 완료 → CONVERT T
                            cmd_byte  <= CMD_CONVERT_T;
                            byte_step <= 4'd1;
                            dstate    <= D_SET_WR;
                        end
                        4'd1: begin // CONVERT T 완료 → 두 번째 RST
                            byte_step <= 4'd2;
                            dstate    <= D_SET_RST;
                        end
                        4'd2: begin // 2차 SKIP ROM 완료 → READ SCRATCHPAD
                            cmd_byte  <= CMD_READ_SCPAD;
                            byte_step <= 4'd3;
                            dstate    <= D_SET_WR;
                        end
                        4'd3: begin // READ SCRATCHPAD 커맨드 완료 → 72비트 읽기
                            byte_step <= 4'd4;
                            rd_bit_idx <= 7'd0;
                            dstate    <= D_SET_RD;
                        end
                        default: dstate <= D_DONE;
                        endcase
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                        dstate  <= D_SET_WR;
                    end
                end
            end
        end

        // ── 비트 읽기 (스크래치패드 72비트) ─────
        D_SET_RD: begin
            if (axi_state == AXI_IDLE) begin
                axi_waddr_lat <= CTRL_OFF;
                axi_wdata_lat <= {15'd0, 1'b1, 13'd0, OP_RD}; // IRQ_EN=1, OP=RD
                axi_do_write  <= 1'b1;
                dstate        <= D_START_RD;
            end
        end
        D_START_RD: begin
            if (axi_write_done) begin
                axi_waddr_lat <= START_OFF;
                axi_wdata_lat <= 32'd1;
                axi_do_write  <= 1'b1;
                dstate        <= D_WAIT_RD;
            end
        end
        D_WAIT_RD: begin
            if (axi_write_done) begin
                axi_raddr_lat <= STAT_OFF;
                axi_do_read   <= 1'b1;
            end
            if (axi_read_done) begin
                if (axi_rdata_lat[0]) begin
                    axi_raddr_lat <= STAT_OFF;
                    axi_do_read   <= 1'b1;
                end else begin
                    dstate <= D_READ_STAT;
                end
            end
        end
        D_READ_STAT: begin
            if (axi_state == AXI_IDLE) begin
                // STATUS의 RBIT[2] 읽기 (이미 axi_rdata_lat에 있음)
                rd_data[rd_bit_idx] <= axi_rdata_lat[2];
                if (rd_bit_idx == 7'd71) begin
                    dstate <= D_DONE;
                end else begin
                    rd_bit_idx <= rd_bit_idx + 1'b1;
                    dstate     <= D_SET_RD;
                end
            end
        end

        D_DONE: begin
            // 완료: 다시 대기하지 않고 유지 (리셋 시 재시작)
        end

        default: dstate <= D_IDLE;
        endcase
    end
end

// ------------------------------------------------------------
// LED 출력 (STATUS 레지스터에서 직접 연결하기 어려우므로
// 데모 FSM 상태 변수 활용)
// ------------------------------------------------------------
// STATUS 폴링 직접 반영하지 않고, IRQ 라인과 presence_lat 활용
assign led[7] = presence_lat;         // PRESENCE 감지 여부
assign led[6] = axi_rdata_lat[2];     // 마지막 STATUS의 RBIT
assign led[5] = axi_rdata_lat[0];     // 마지막 STATUS의 BUSY
assign led[4] = irq_line;             // 현재 IRQ 상태
assign led[3] = (dstate == D_DONE);   // 시퀀스 완료
assign led[2] = rd_data[0];           // 첫 번째 읽은 비트
assign led[1] = rd_data[8];           // 2번째 바이트 첫 비트
assign led[0] = rd_data[16];          // 3번째 바이트 첫 비트

endmodule
`default_nettype wire
