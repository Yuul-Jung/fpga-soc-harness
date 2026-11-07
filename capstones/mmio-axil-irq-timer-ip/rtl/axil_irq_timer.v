// axil_irq_timer.v
// AXI4-Lite 다운카운터 타이머 IP — FreeRTOS xSemaphoreGiveFromISR 통지 패턴 시연용
//
// 레지스터 맵 (로컬 오프셋, 베이스 0x4030_0000은 인터커넥트가 처리):
//   0x00  CTRL        (RW) bit[0]=enable, bit[1]=auto_reload
//   0x04  COUNT       (RW) 프리셋 카운트 값 (다운카운트 초기값, 1 이상)
//   0x08  IRQ_STATUS  (R)  bit[0]=expired(IRQ 대기 중), bit[1]=running
//   0x0C  IRQ_MASK    (RW) bit[0]=irq_en; 1이면 expired & irq_en → irq_out
//   0x10  IRQ_ACK     (W)  임의 값 쓰기 → expired 클리어 (우선순위 최고)
//   0x14  IRQ_FORCE   (W)  임의 값 쓰기 → expired 강제 세트 (테스트용)
//
// 동작:
//   CTRL[0]=1 세트 시 COUNT 값을 로드해 1씩 감산.
//   카운터가 1에 도달한 다음 클럭에 expired 세트, irq_out 어서트.
//   CTRL[1]=1(auto_reload): COUNT를 다시 로드해 연속 동작.
//   CTRL[1]=0(single-shot): 완료 후 enable 자동 클리어.
//
// 우선순위: ACK > (FORCE | timer) for expired flag.
// 단, AXI 쓰기와 타이머 만료가 동일 사이클에 겹치면 ACK가 이긴다.
//
// 준수: Verilog-2001, iverilog·verilator·yosys 호환
// IP 표준: irq_out = ip2intc_irpt

`default_nettype none
`timescale 1ns/1ps

module axil_irq_timer #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5    // 0x00..0x14 커버
)(
    // AXI4-Lite 클럭·리셋 (active-low reset)
    input  wire                     s_axil_aclk,
    input  wire                     s_axil_aresetn,
    // 쓰기 주소 채널
    input  wire [ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire [2:0]               s_axil_awprot,
    input  wire                     s_axil_awvalid,
    output reg                      s_axil_awready,
    // 쓰기 데이터 채널
    input  wire [DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [DATA_WIDTH/8-1:0]  s_axil_wstrb,
    input  wire                     s_axil_wvalid,
    output reg                      s_axil_wready,
    // 쓰기 응답 채널
    output reg  [1:0]               s_axil_bresp,
    output reg                      s_axil_bvalid,
    input  wire                     s_axil_bready,
    // 읽기 주소 채널
    input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire [2:0]               s_axil_arprot,
    input  wire                     s_axil_arvalid,
    output reg                      s_axil_arready,
    // 읽기 데이터 채널
    output reg  [DATA_WIDTH-1:0]    s_axil_rdata,
    output reg  [1:0]               s_axil_rresp,
    output reg                      s_axil_rvalid,
    input  wire                     s_axil_rready,
    // 인터럽트 출력 (ip2intc_irpt)
    output wire                     irq_out
);

// 레지스터 오프셋 셀렉터 (addr[4:2])
localparam SEL_CTRL       = 3'd0; // 0x00
localparam SEL_COUNT      = 3'd1; // 0x04
localparam SEL_IRQ_STATUS = 3'd2; // 0x08
localparam SEL_IRQ_MASK   = 3'd3; // 0x0C
localparam SEL_IRQ_ACK    = 3'd4; // 0x10
localparam SEL_IRQ_FORCE  = 3'd5; // 0x14

// 사용자 레지스터
reg [DATA_WIDTH-1:0] reg_ctrl;
reg [DATA_WIDTH-1:0] reg_count;
reg [DATA_WIDTH-1:0] reg_irq_mask;

// 인터럽트 / 타이머 상태
reg                  reg_expired;
reg                  reg_running;
reg [DATA_WIDTH-1:0] reg_counter;

// AXI 핸들셰이크 래치
reg [ADDR_WIDTH-1:0] aw_addr_lat;
reg                  aw_lat;

// 조합 디코드
wire wr_do  = s_axil_wvalid & aw_lat & ~s_axil_bvalid;
wire [2:0] wr_sel = aw_addr_lat[4:2];

// 타이머 만료: 카운터가 1일 때 다음 엣지에 0이 되며 expired를 세트
wire timer_expire_now = reg_running & (reg_counter == {{(DATA_WIDTH-1){1'b0}}, 1'b1});

// IRQ 출력
assign irq_out = reg_expired & reg_irq_mask[0];

// apply_wstrb: 바이트 단위 쓰기 적용
function [DATA_WIDTH-1:0] apply_wstrb;
    input [DATA_WIDTH-1:0] orig;
    input [DATA_WIDTH-1:0] wdata;
    input [DATA_WIDTH/8-1:0] wstrb;
    integer i;
    begin
        for (i = 0; i < DATA_WIDTH/8; i = i + 1)
            apply_wstrb[i*8 +: 8] = wstrb[i] ? wdata[i*8 +: 8] : orig[i*8 +: 8];
    end
endfunction

// ============================================================
// 블록 1: AXI 쓰기 핸들셰이크 (aw_lat, bvalid, awready, wready)
// ============================================================
always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        s_axil_bresp   <= 2'b00;
        aw_lat         <= 1'b0;
        aw_addr_lat    <= {ADDR_WIDTH{1'b0}};
    end else begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;

        // 쓰기 주소 래치
        if (s_axil_awvalid & ~aw_lat) begin
            aw_lat         <= 1'b1;
            aw_addr_lat    <= s_axil_awaddr;
            s_axil_awready <= 1'b1;
        end

        // 데이터 수락 → 응답 발행
        if (wr_do) begin
            s_axil_wready <= 1'b1;
            aw_lat        <= 1'b0;
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= 2'b00;
        end

        // 응답 소비
        if (s_axil_bvalid & s_axil_bready)
            s_axil_bvalid <= 1'b0;
    end
end

// ============================================================
// 블록 2: 사용자 레지스터 (CTRL, COUNT, IRQ_MASK)
// ============================================================
always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
        reg_ctrl     <= {DATA_WIDTH{1'b0}};
        reg_count    <= {DATA_WIDTH{1'b0}};
        reg_irq_mask <= {DATA_WIDTH{1'b0}};
    end else begin
        if (wr_do) begin
            case (wr_sel)
                SEL_CTRL:
                    reg_ctrl     <= apply_wstrb(reg_ctrl,     s_axil_wdata, s_axil_wstrb);
                SEL_COUNT:
                    reg_count    <= apply_wstrb(reg_count,    s_axil_wdata, s_axil_wstrb);
                SEL_IRQ_MASK:
                    reg_irq_mask <= apply_wstrb(reg_irq_mask, s_axil_wdata, s_axil_wstrb);
                default: ;
            endcase
        end else if (timer_expire_now & ~reg_ctrl[1]) begin
            // single-shot 완료: enable 자동 클리어 (AXI CTRL 쓰기보다 낮은 우선순위)
            reg_ctrl[0] <= 1'b0;
        end
    end
end

// ============================================================
// 블록 3: expired 플래그
//   우선순위: ACK(클리어) > FORCE|timer_expire(세트)
// ============================================================
always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
        reg_expired <= 1'b0;
    end else begin
        if (wr_do & (wr_sel == SEL_IRQ_ACK))
            // ACK: 최고 우선순위 클리어
            reg_expired <= 1'b0;
        else if ((wr_do & (wr_sel == SEL_IRQ_FORCE)) | timer_expire_now)
            // FORCE 또는 타이머 만료: 세트
            reg_expired <= 1'b1;
        // else: 유지
    end
end

// ============================================================
// 블록 4: 타이머 FSM (reg_counter, reg_running)
// ============================================================
always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
        reg_counter <= {DATA_WIDTH{1'b0}};
        reg_running <= 1'b0;
    end else begin
        if (!reg_running) begin
            // 시작 조건: enable=1, count>0
            if (reg_ctrl[0] & (|reg_count)) begin
                reg_counter <= reg_count;
                reg_running <= 1'b1;
            end
        end else begin
            // 실행 중
            if (timer_expire_now) begin
                if (reg_ctrl[1]) begin
                    // auto_reload: COUNT 재로드
                    reg_counter <= reg_count;
                end else begin
                    // single-shot: 정지
                    reg_counter <= {DATA_WIDTH{1'b0}};
                    reg_running <= 1'b0;
                end
            end else begin
                reg_counter <= reg_counter - {{(DATA_WIDTH-1){1'b0}}, 1'b1};
            end
            // enable 외부 클리어 감지 → 즉시 정지
            if (!reg_ctrl[0]) begin
                reg_counter <= {DATA_WIDTH{1'b0}};
                reg_running <= 1'b0;
            end
        end
    end
end

// ============================================================
// 블록 5: AXI 읽기 채널
// ============================================================
always @(posedge s_axil_aclk) begin
    if (!s_axil_aresetn) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= {DATA_WIDTH{1'b0}};
        s_axil_rresp   <= 2'b00;
    end else begin
        s_axil_arready <= 1'b0;

        if (s_axil_arvalid & ~s_axil_rvalid) begin
            s_axil_arready <= 1'b1;
            s_axil_rvalid  <= 1'b1;
            s_axil_rresp   <= 2'b00;
            case (s_axil_araddr[4:2])
                SEL_CTRL:
                    s_axil_rdata <= reg_ctrl;
                SEL_COUNT:
                    s_axil_rdata <= reg_count;
                SEL_IRQ_STATUS:
                    s_axil_rdata <= {{(DATA_WIDTH-2){1'b0}}, reg_running, reg_expired};
                SEL_IRQ_MASK:
                    s_axil_rdata <= reg_irq_mask;
                default:
                    s_axil_rdata <= {DATA_WIDTH{1'b0}};
            endcase
        end

        if (s_axil_rvalid & s_axil_rready)
            s_axil_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire
