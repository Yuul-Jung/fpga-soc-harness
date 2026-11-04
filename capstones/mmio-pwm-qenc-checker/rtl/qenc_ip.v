// qenc_ip.v — 4× 직교 엔코더 카운터 IP (IP 표준 Rev.1 관리 레지스터 포함)
// 레지스터 맵:
//   0x0000  CTRL    [0]=enable, [1]=clear_pos (SC: 쓰면 클리어, 자동으로 0으로 돌아옴)
//   0x0004  POS     RO, signed 32-bit 위치
//   0x0008  DIR     RO, bit0=1(CW), 0(CCW) — 마지막 이동 방향
//   0x000C  ERR     RO, [15:0] 비정상 전이 횟수
//   0xFFF0  ID      RO = 0x51454E43 ("QENC")
//   0xFFF4  VER     RO = {8'h01,8'h00,8'h00,8'h01}
//   0xFFF8  IRQ_STATUS  [0]=overflow W1C
//   0xFFFC  IRQ_ENABLE  [0]=overflow IRQ 허용
//
// 4× 디코딩: Gray 코드 2비트 FSM으로 모든 에지에서 ±1 카운트
//   CW  순서: 2'b00 → 2'b01 → 2'b11 → 2'b10 → 2'b00 (+1 each step)
//   CCW 순서: 2'b00 → 2'b10 → 2'b11 → 2'b01 → 2'b00 (-1 each step)
// 비정상 전이(00→11, 11→00, 01→10, 10→01): ERR 카운터 증가
// 2단 동기화: a_in/b_in → 2단 FF → {a_s, b_s}
`timescale 1ns/1ps
module qenc_ip (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        a_in,
    input  wire        b_in,
    output wire        irq
);
    // 제어 레지스터
    reg         enable;
    reg         irq_enable;
    reg         irq_status;

    // 엔코더 상태
    reg  [31:0] pos;
    reg         dir;        // 1=CW, 0=CCW
    reg  [15:0] err;

    // 2단 동기화
    reg  [1:0]  a_ff, b_ff;
    wire        a_s = a_ff[1];
    wire        b_s = b_ff[1];

    // 직전 상태 저장
    reg  [1:0]  prev;

    wire wr = sel && we;

    always @(posedge clk) begin
        if (rst) begin
            enable     <= 1'b0;
            irq_enable <= 1'b0;
            irq_status <= 1'b0;
            pos        <= 32'd0;
            dir        <= 1'b1;
            err        <= 16'd0;
            a_ff       <= 2'b0;
            b_ff       <= 2'b0;
            prev       <= 2'b0;
        end else begin
            // 2단 동기화
            a_ff <= {a_ff[0], a_in};
            b_ff <= {b_ff[0], b_in};

            // IRQ_STATUS W1C
            if (wr && (off == 16'hFFF8))
                irq_status <= irq_status & ~wdata[0];

            // 레지스터 쓰기
            if (wr) begin
                case (off)
                    16'h0000: begin
                        enable <= wdata[0];
                        if (wdata[1]) begin
                            pos <= 32'd0;
                            err <= 16'd0;
                        end
                    end
                    16'hFFFC: irq_enable <= wdata[0];
                    default: ;
                endcase
            end

            // 직교 디코딩 (enable=1일 때만)
            if (enable) begin
                prev <= {a_s, b_s};
                // 현재 상태와 이전 상태로 전이 판정
                case ({prev, a_s, b_s})
                    // CW 전이: +1
                    4'b00_01, 4'b01_11, 4'b11_10, 4'b10_00: begin
                        pos <= pos + 32'd1;
                        dir <= 1'b1;
                        // pos가 최댓값에서 overflow 검출
                        if (pos == 32'h7FFF_FFFF)
                            irq_status <= 1'b1;
                    end
                    // CCW 전이: -1
                    4'b00_10, 4'b10_11, 4'b11_01, 4'b01_00: begin
                        pos <= pos - 32'd1;
                        dir <= 1'b0;
                        if (pos == 32'h8000_0000)
                            irq_status <= 1'b1;
                    end
                    // 비정상 전이 (두 비트 동시 변환)
                    4'b00_11, 4'b11_00, 4'b01_10, 4'b10_01: begin
                        err <= err + 16'd1;
                    end
                    // 변화 없음
                    default: ;
                endcase
            end
        end
    end

    assign irq = irq_status & irq_enable;

    // 읽기
    always @* begin
        case (off)
            16'h0000: rdata = {30'd0, 1'b0, enable};
            16'h0004: rdata = pos;
            16'h0008: rdata = {31'd0, dir};
            16'h000C: rdata = {16'd0, err};
            16'hFFF0: rdata = 32'h5145_4E43; // "QENC"
            16'hFFF4: rdata = 32'h0100_0001;
            16'hFFF8: rdata = {31'd0, irq_status};
            16'hFFFC: rdata = {31'd0, irq_enable};
            default:  rdata = 32'h0000_0000;
        endcase
    end
endmodule
