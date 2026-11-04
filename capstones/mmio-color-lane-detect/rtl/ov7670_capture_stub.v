// ov7670_capture_stub.v — OV7670 캡처 프런트엔드 스텁
// PCLK 도메인에서 RGB565 2바이트를 조합해 pixel_valid, frame_start,
// frame_done, line_done 펄스를 출력한다.
// 실제 카메라 연결 시 mmio-ov7670-sccb-capture의 ov7670_capture.v로 교체.
//
// VSYNC 극성(OV7670): HIGH = 블랭킹(프레임 사이), LOW = 활성 프레임
//   frame_start = VSYNC 하강 에지 (vsync_d && !vsync)
//   frame_done  = VSYNC 상승 에지 (!vsync_d && vsync)
// HREF: HIGH = 유효 픽셀 데이터
//   line_done   = HREF 하강 에지 (href_d && !href)
//
// Verilog-2001, 외부 IP 없음.

`default_nettype none
module ov7670_capture_stub (
    input  wire        pclk,         // 카메라 픽셀 클럭 (~24 MHz)
    input  wire        prst,         // PCLK 도메인 리셋
    input  wire        vsync,        // 프레임 동기 (OV7670: high=블랭킹)
    input  wire        href,         // 수평 활성 (high=유효)
    input  wire [7:0]  d,            // 픽셀 데이터
    input  wire        capture_en,   // 캡처 활성화 (SYS→PCLK 동기화 완료)
    output reg  [15:0] pixel_data,   // 결합된 RGB565
    output reg         pixel_valid,  // 1 PCLK 펄스, 픽셀 유효
    output reg         frame_start,  // 1 PCLK 펄스, 프레임 시작
    output reg         frame_done,   // 1 PCLK 펄스, 프레임 완료
    output reg         line_done     // 1 PCLK 펄스, 라인 완료(HREF 하강)
);
    reg       vsync_d;
    reg       href_d;
    reg       byte_phase;  // 0=첫 바이트(high), 1=두 번째(low)
    reg [7:0] byte_hi;

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
            line_done   <= 1'b0;
        end else begin
            vsync_d     <= vsync;
            href_d      <= href;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            line_done   <= 1'b0;

            // VSYNC 하강 → 프레임 시작
            if (vsync_d && !vsync) begin
                frame_start <= 1'b1;
                byte_phase  <= 1'b0;
            end
            // VSYNC 상승 → 프레임 완료
            if (!vsync_d && vsync)
                frame_done <= 1'b1;

            // HREF 하강 → 라인 완료
            if (href_d && !href) begin
                line_done  <= 1'b1;
                byte_phase <= 1'b0;
            end

            // HREF 활성 + VSYNC 비활성 + capture_en → 픽셀 캡처
            if (capture_en && href && !vsync) begin
                if (!byte_phase) begin
                    byte_hi    <= d;
                    byte_phase <= 1'b1;
                end else begin
                    pixel_data  <= {byte_hi, d};
                    pixel_valid <= 1'b1;
                    byte_phase  <= 1'b0;
                end
            end else if (!href) begin
                byte_phase <= 1'b0;
            end
        end
    end
endmodule
`default_nettype wire
