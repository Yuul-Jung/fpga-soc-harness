// ov7670_capture.v — OV7670 픽셀 캡처 프런트엔드
// PCLK 도메인에서 RGB565 2바이트를 결합해 16비트 픽셀로 출력.
// HREF 활성+VSYNC 비활성 구간에서만 픽셀을 캡처한다.
// 도메인 교차는 상위 모듈(ov7670_sccb_top)이 처리한다.
// Verilog-2001, 외부 IP 없음.
//
// 타이밍 (OV7670 RGB565, 2클럭/픽셀 — PCLK 기준):
//   VSYNC high → 프레임 시작, VSYNC low → 프레임 활성
//   HREF high  → 라인 활성
//   PCLK ↑에서 D[7:0] 샘플링: 짝수=첫바이트(high), 홀수=두번째바이트(low)

`default_nettype none
module ov7670_capture (
    input  wire        pclk,          // 카메라 픽셀 클럭 (~24 MHz)
    input  wire        prst,          // PCLK 도메인 리셋 (시스템 리셋 동기화 필요)
    input  wire        vsync,         // 프레임 동기 (OV7670: high=블랭킹)
    input  wire        href,          // 수평 활성 (high=유효)
    input  wire [7:0]  d,             // 픽셀 데이터
    input  wire        capture_en,    // 캡처 활성화 (시스템 클럭 → PCLK 동기화 필요)
    output reg  [15:0] pixel_data,    // 결합된 RGB565 픽셀
    output reg         pixel_valid,   // 픽셀 유효 (1 PCLK 펄스)
    output reg         frame_start,   // 프레임 시작 (1 PCLK 펄스, VSYNC 하강)
    output reg         frame_done,    // 프레임 완료 (1 PCLK 펄스, VSYNC 상승)
    output reg [15:0]  line_cnt,      // 현재 프레임의 완료 라인 수
    output reg [15:0]  pixel_cnt      // 현재 라인의 픽셀 수 (디버그)
);
    reg        vsync_d;
    reg        href_d;
    reg        byte_phase; // 0=첫바이트, 1=두번째바이트
    reg  [7:0] byte_hi;    // 첫 바이트(high byte) 보관

    always @(posedge pclk) begin
        if (prst) begin
            vsync_d     <= 1'b0;
            href_d      <= 1'b0;
            byte_phase  <= 1'b0;
            byte_hi     <= 8'd0;
            pixel_data  <= 16'd0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            line_cnt    <= 16'd0;
            pixel_cnt   <= 16'd0;
        end else begin
            vsync_d     <= vsync;
            href_d      <= href;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_done  <= 1'b0;

            // VSYNC 하강 → 프레임 시작 (OV7670: high=블랭킹, low=활성)
            if (vsync_d && !vsync) begin
                frame_start <= 1'b1;
                line_cnt    <= 16'd0;
                byte_phase  <= 1'b0;
            end

            // VSYNC 상승 → 프레임 완료
            if (!vsync_d && vsync) begin
                frame_done <= 1'b1;
            end

            // HREF 하강 → 라인 완료
            if (href_d && !href) begin
                line_cnt  <= line_cnt + 1;
                byte_phase <= 1'b0;
                pixel_cnt  <= 16'd0;
            end

            // HREF 활성 + VSYNC 비활성 + capture_en → 픽셀 캡처
            if (capture_en && href && !vsync) begin
                if (!byte_phase) begin
                    byte_hi    <= d;
                    byte_phase <= 1'b1;
                end else begin
                    pixel_data  <= {byte_hi, d};  // RGB565
                    pixel_valid <= 1'b1;
                    byte_phase  <= 1'b0;
                    pixel_cnt   <= pixel_cnt + 1;
                end
            end else if (!href) begin
                byte_phase <= 1'b0;
            end
        end
    end
endmodule
`default_nettype wire
