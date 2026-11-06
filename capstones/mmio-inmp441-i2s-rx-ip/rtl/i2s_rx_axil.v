// i2s_rx_axil.v — AXI4-Lite I2S RX IP (IP표준 Rev1)
// 역할: INMP441 I2S MEMS 마이크에서 24비트 PCM을 수신하는 AXI4-Lite 슬레이브 IP.
//       BCLK·LRCLK를 내부 발생(CLK_DIV=48, 100MHz→≈1.042MHz BCLK, ≈16.3kHz LRCLK).
//       Verilog-2001 스타일. iverilog/verilator/yosys 호환.
//
// 레지스터 맵 (AXI4-Lite 베이스 + 오프셋):
//   0x0000  DATA_L      [23:0] 왼쪽 채널 PCM, 부호 확장 32비트 (R)
//   0x0004  DATA_R      [23:0] 오른쪽 채널 PCM (INMP441 모노 → 항상 0) (R)
//   0x0008  STATUS      bit0=data_valid, bit1=overflow (R/W1C)
//   0x000C  CTRL        bit0=enable (R/W)
//   0xFFF0  ID          0x49325358 ("I2SX") (R)
//   0xFFF4  VER         0x01000100 (std_rev=1, major=1, minor=0) (R)
//   0xFFF8  IRQ_STATUS  bit0=data_valid IRQ 원인 (R/W1C)
//   0xFFFC  IRQ_ENABLE  bit0=data_valid IRQ 허용 (R/W)

`default_nettype none
`timescale 1ns/1ps

module i2s_rx_axil #(
    parameter CLK_DIV = 48   // BCLK 반주기 (100MHz 사이클 수)
) (
    // 클럭·리셋
    input  wire        clk,
    input  wire        rst,          // 동기, 하이 활성

    // AXI4-Lite 슬레이브 포트
    input  wire [15:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [15:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    output reg  [31:0] s_axil_rdata,
    output reg  [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,

    // I2S 외부 핀 (마이크 방향)
    output wire        bclk_out,     // 비트 클럭 (마이크에 공급)
    output wire        lrclk_out,    // 채널 선택 클럭 (마이크에 공급)
    input  wire        dout_in,      // 마이크 직렬 데이터 (DOUT)

    // 인터럽트
    output wire        irq           // data_valid IRQ (레벨)
);

    // ─────────────────────────────────────────
    // 1. I2S 클럭 발생
    // ─────────────────────────────────────────
    reg [6:0]  bclk_cnt;    // 0 .. CLK_DIV-1
    reg        bclk_r;      // BCLK 레지스터
    reg [5:0]  bit_pos;     // 0..63 (LRCLK 한 주기 내 비트 위치)
    reg        lrclk_r;     // LRCLK 레지스터

    wire bclk_rise;         // 1클럭 폭 BCLK 상승 엣지 펄스
    wire bclk_fall;         // 1클럭 폭 BCLK 하강 엣지 펄스

    wire en = ctrl_reg[0];  // forward declaration (defined below)

    reg bclk_q;
    assign bclk_rise = (bclk_r & ~bclk_q);
    assign bclk_fall = (~bclk_r & bclk_q);

    always @(posedge clk) bclk_q <= bclk_r;

    always @(posedge clk) begin
        if (rst || !en) begin
            bclk_cnt <= 0;
            bclk_r   <= 0;
            bit_pos  <= 0;
            lrclk_r  <= 0;
        end else begin
            if (bclk_cnt == CLK_DIV - 1) begin
                bclk_cnt <= 0;
                bclk_r   <= ~bclk_r;
                // BCLK 하강 시(bclk_r 현재 1, 다음 0) bit_pos 증가
                if (bclk_r) begin
                    bit_pos <= (bit_pos == 63) ? 0 : bit_pos + 1;
                    lrclk_r <= (bit_pos >= 32) ? 1'b1 : 1'b0;
                end
            end else
                bclk_cnt <= bclk_cnt + 1;
        end
    end

    assign bclk_out  = bclk_r;
    assign lrclk_out = lrclk_r;

    // ─────────────────────────────────────────
    // 2. I2S RX 시프트 레지스터
    // ─────────────────────────────────────────
    // BCLK 상승 엣지에서 DOUT 샘플. bit_pos 1..32 → 왼쪽, 33..64 → 오른쪽.
    // INMP441: 32비트 슬롯에서 MSB first, 비트 1(bit_pos=1)이 MSB.
    reg [31:0] shift_r;
    reg [23:0] pcm_l_next;
    reg [23:0] pcm_r_next;
    reg        frame_done;   // 오른쪽 채널 마지막 비트 직후

    always @(posedge clk) begin
        frame_done <= 0;
        if (rst || !en) begin
            shift_r <= 0;
        end else if (bclk_rise) begin
            shift_r <= {shift_r[30:0], dout_in};
            // bit_pos=32 → 왼쪽 프레임 완료 (비트 1~32 수신)
            if (bit_pos == 31) begin   // 0-based: 위치 31이 왼쪽 32번째 비트
                pcm_l_next <= shift_r[22:0];  // MSB first: shift_r[23:0] 첫 24비트
            end
            // bit_pos=63 → 오른쪽 프레임 완료
            if (bit_pos == 63) begin
                pcm_r_next <= shift_r[22:0];
                frame_done <= 1;
            end
        end
    end

    // ─────────────────────────────────────────
    // 3. 레지스터 파일
    // ─────────────────────────────────────────
    reg [31:0] data_l_reg;
    reg [31:0] data_r_reg;
    reg [1:0]  status_reg;   // [0]=data_valid, [1]=overflow
    reg [0:0]  ctrl_reg;     // [0]=enable
    reg [0:0]  irq_status_r;
    reg [0:0]  irq_enable_r;

    // 샘플 캡처
    always @(posedge clk) begin
        if (rst) begin
            data_l_reg  <= 0;
            data_r_reg  <= 0;
            status_reg  <= 0;
            irq_status_r<= 0;
        end else if (frame_done) begin
            if (status_reg[0])
                status_reg[1] <= 1;   // overflow: 이전 샘플을 읽지 않음
            data_l_reg  <= {{8{pcm_l_next[23]}}, pcm_l_next};
            data_r_reg  <= 32'd0;     // INMP441 모노, 오른쪽은 0
            status_reg[0] <= 1;
            irq_status_r  <= 1;
        end
    end

    assign irq = irq_status_r[0] & irq_enable_r[0];

    // ─────────────────────────────────────────
    // 4. AXI4-Lite 슬레이브 FSM
    // ─────────────────────────────────────────
    // 쓰기: AW+W 채널을 함께 받은 뒤 B 채널 응답
    // 읽기: AR 채널 받은 뒤 R 채널 응답
    reg aw_pend;
    reg [15:0] aw_addr;
    reg w_pend;
    reg [31:0] w_data;

    // AW 채널
    always @(posedge clk) begin
        if (rst) begin
            s_axil_awready <= 1;
            aw_pend        <= 0;
            aw_addr        <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                aw_addr        <= s_axil_awaddr;
                aw_pend        <= 1;
                s_axil_awready <= 0;
            end
            if (s_axil_bvalid && s_axil_bready) begin
                aw_pend        <= 0;
                s_axil_awready <= 1;
            end
        end
    end

    // W 채널
    always @(posedge clk) begin
        if (rst) begin
            s_axil_wready <= 1;
            w_pend        <= 0;
            w_data        <= 0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                w_data        <= s_axil_wdata;
                w_pend        <= 1;
                s_axil_wready <= 0;
            end
            if (s_axil_bvalid && s_axil_bready) begin
                w_pend        <= 0;
                s_axil_wready <= 1;
            end
        end
    end

    // B 채널 (쓰기 완료)
    always @(posedge clk) begin
        if (rst) begin
            s_axil_bvalid <= 0;
            s_axil_bresp  <= 0;
            ctrl_reg      <= 0;
            irq_enable_r  <= 0;
        end else begin
            if (aw_pend && w_pend && !s_axil_bvalid) begin
                s_axil_bvalid <= 1;
                s_axil_bresp  <= 2'b00;
                // 레지스터 쓰기
                case (aw_addr[15:0])
                    16'h0008: status_reg  <= status_reg  & ~w_data[1:0]; // W1C
                    16'h000C: ctrl_reg    <= w_data[0:0];
                    16'hFFF8: irq_status_r<= irq_status_r & ~w_data[0:0]; // W1C
                    16'hFFFC: irq_enable_r<= w_data[0:0];
                    default: ; // R-only 레지스터는 무시
                endcase
            end
            if (s_axil_bvalid && s_axil_bready)
                s_axil_bvalid <= 0;
        end
    end

    // AR + R 채널
    reg ar_pend;
    reg [15:0] ar_addr;

    always @(posedge clk) begin
        if (rst) begin
            s_axil_arready <= 1;
            ar_pend        <= 0;
            ar_addr        <= 0;
            s_axil_rvalid  <= 0;
            s_axil_rdata   <= 0;
            s_axil_rresp   <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                ar_addr        <= s_axil_araddr;
                ar_pend        <= 1;
                s_axil_arready <= 0;
            end
            if (ar_pend && !s_axil_rvalid) begin
                s_axil_rvalid <= 1;
                s_axil_rresp  <= 2'b00;
                ar_pend       <= 0;
                // DATA_L 읽기 → data_valid 자동 클리어
                if (ar_addr[15:0] == 16'h0000) begin
                    status_reg[0] <= 0;
                    irq_status_r  <= 0;
                end
                case (ar_addr[15:0])
                    16'h0000: s_axil_rdata <= data_l_reg;
                    16'h0004: s_axil_rdata <= data_r_reg;
                    16'h0008: s_axil_rdata <= {30'd0, status_reg};
                    16'h000C: s_axil_rdata <= {31'd0, ctrl_reg};
                    16'hFFF0: s_axil_rdata <= 32'h4932_5358; // "I2SX"
                    16'hFFF4: s_axil_rdata <= 32'h0100_0100; // VER
                    16'hFFF8: s_axil_rdata <= {31'd0, irq_status_r};
                    16'hFFFC: s_axil_rdata <= {31'd0, irq_enable_r};
                    default:  s_axil_rdata <= 32'd0;
                endcase
            end
            if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid  <= 0;
                s_axil_arready <= 1;
            end
        end
    end

endmodule
`default_nettype wire
