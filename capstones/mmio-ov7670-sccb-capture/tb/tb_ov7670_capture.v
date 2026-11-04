// tb_ov7670_capture.v — ov7670_capture 모듈 자체 점검 테스트벤치
// 카메라 모델: PCLK 24 MHz 모의, VSYNC·HREF·픽셀 데이터 시퀀스 생성
// 프레임 1개(2라인, 라인당 4픽셀)를 보내고 픽셀 값·카운터를 검증한다.
// 통과: "PASS: ..." , 실패: "FAIL: ..." 로 시작하는 줄 출력 후 $finish
// Verilog-2001, 외부 IP 없음.

`timescale 1ns/1ps
`default_nettype none
module tb_ov7670_capture;
    // 타이밍 (PCLK 24 MHz ≒ 41.67 ns → 42 ns 사용)
    localparam PCLK_P = 42; // ns

    // DUT 신호
    reg        pclk, prst;
    reg        vsync, href;
    reg  [7:0] d;
    reg        capture_en;
    wire [15:0] pixel_data;
    wire        pixel_valid;
    wire        frame_start;
    wire        frame_done;
    wire [15:0] line_cnt;
    wire [15:0] pixel_cnt;

    // DUT 인스턴스
    ov7670_capture dut (
        .pclk(pclk), .prst(prst),
        .vsync(vsync), .href(href),
        .d(d),
        .capture_en(capture_en),
        .pixel_data(pixel_data), .pixel_valid(pixel_valid),
        .frame_start(frame_start), .frame_done(frame_done),
        .line_cnt(line_cnt), .pixel_cnt(pixel_cnt)
    );

    // PCLK 생성
    initial pclk = 0;
    always #(PCLK_P/2) pclk = ~pclk;

    // ----------------------------------------------------------------
    // 태스크: 1클럭 PCLK 대기
    // ----------------------------------------------------------------
    task pclk1; begin @(posedge pclk); #1; end endtask

    // ----------------------------------------------------------------
    // 태스크: 한 픽셀(2바이트) 전송 (HREF=1, capture_en=1 가정)
    // ----------------------------------------------------------------
    task send_pixel;
        input [7:0] hi, lo;
        begin
            d = hi; pclk1; // 첫 바이트
            d = lo; pclk1; // 두 번째 바이트 → pixel_valid 발생
        end
    endtask

    // ----------------------------------------------------------------
    // 태스크: HREF 한 라인 전송 (N 픽셀)
    // ----------------------------------------------------------------
    task send_line;
        input integer npix;
        input [15:0] base_val; // 첫 픽셀 값 (이후 +1씩)
        integer i;
        begin
            href = 1'b1;
            for (i = 0; i < npix; i = i + 1) begin
                send_pixel(base_val[15:8] + i, base_val[7:0] + i);
            end
            href = 1'b0;
            pclk1; // HREF 하강 처리
        end
    endtask

    // ----------------------------------------------------------------
    // 검증 변수
    // ----------------------------------------------------------------
    integer   pixel_count;
    reg [15:0] last_pix;
    integer   frame_start_cnt;
    integer   frame_done_cnt;
    integer   line_cnt_val;

    // 이벤트 카운터 (posedge pclk에서 래치)
    always @(posedge pclk) begin
        if (prst) begin
            pixel_count     <= 0;
            last_pix        <= 16'd0;
            frame_start_cnt <= 0;
            frame_done_cnt  <= 0;
        end else begin
            if (pixel_valid) begin
                pixel_count <= pixel_count + 1;
                last_pix    <= pixel_data;
            end
            if (frame_start) frame_start_cnt <= frame_start_cnt + 1;
            if (frame_done)  frame_done_cnt  <= frame_done_cnt + 1;
        end
    end

    // ----------------------------------------------------------------
    // 테스트 시나리오
    // ----------------------------------------------------------------
    initial begin
        // 초기화
        prst = 1; vsync = 0; href = 0; d = 8'd0; capture_en = 1;
        pixel_count = 0; last_pix = 0;
        frame_start_cnt = 0; frame_done_cnt = 0;

        repeat(5) pclk1;
        prst = 0;
        repeat(3) pclk1;

        // ============================================================
        // 테스트 1: 프레임 1개 (2라인 × 4픽셀 = 8픽셀)
        // OV7670 타이밍: VSYNC high → 블랭킹, 하강 → 프레임 시작
        //               VSYNC low → 활성 구간, HREF 라인들
        //               VSYNC 상승 → 프레임 완료
        // ============================================================

        // 블랭킹 구간 (VSYNC high)
        vsync = 1'b1;
        repeat(4) pclk1;

        // VSYNC 하강 → frame_start 기대
        vsync = 1'b0;
        pclk1; // 에지 처리

        // 라인 1: 4픽셀 (hi: 0xAB+0..3, lo: 0xCD+0..3)
        send_line(4, 16'hABCD);
        pclk1; // 라인 간 간격

        // 라인 2: 4픽셀
        send_line(4, 16'h1234);
        pclk1;

        // VSYNC 상승 → frame_done 기대
        vsync = 1'b1;
        pclk1;
        pclk1;

        // 추가 대기
        repeat(5) pclk1;

        // ---- 검증 ----
        // 1. frame_start: 1회
        if (frame_start_cnt !== 1) begin
            $display("FAIL: frame_start 횟수 불일치 (기대=1, 실제=%0d)", frame_start_cnt);
            $finish;
        end

        // 2. frame_done: 1회
        if (frame_done_cnt !== 1) begin
            $display("FAIL: frame_done 횟수 불일치 (기대=1, 실제=%0d)", frame_done_cnt);
            $finish;
        end

        // 3. 픽셀 수: 8 (2라인 × 4픽셀)
        if (pixel_count !== 8) begin
            $display("FAIL: 픽셀 수 불일치 (기대=8, 실제=%0d)", pixel_count);
            $finish;
        end

        // 4. line_cnt: 2 (두 라인 완료)
        if (line_cnt !== 16'd2) begin
            $display("FAIL: line_cnt 불일치 (기대=2, 실제=%0d)", line_cnt);
            $finish;
        end

        // 5. 마지막 픽셀 값 검증 (라인2의 4번째 픽셀: hi=0x12+3=0x15, lo=0x34+3=0x37)
        if (last_pix !== 16'h1537) begin
            $display("FAIL: 마지막 픽셀 불일치 (기대=0x1537, 실제=0x%04X)", last_pix);
            $finish;
        end

        // ============================================================
        // 테스트 2: capture_en=0 → 픽셀 무시
        // ============================================================
        capture_en = 1'b0;
        pixel_count = 0; // 카운터 직접 초기화 (reg이므로 가능)
        vsync = 1'b1; repeat(2) pclk1;
        vsync = 1'b0; pclk1;
        send_line(4, 16'hDEAD);
        vsync = 1'b1; pclk1;
        repeat(3) pclk1;

        if (pixel_count !== 0) begin
            $display("FAIL: capture_en=0인데 픽셀 캡처됨 (count=%0d)", pixel_count);
            $finish;
        end

        // ============================================================
        // 테스트 3: VSYNC 중 HREF=1 → 픽셀 무시 (블랭킹 구간)
        // ============================================================
        capture_en = 1'b1;
        pixel_count = 0;
        vsync = 1'b1; // 블랭킹
        href  = 1'b1;
        d = 8'hFF;
        pclk1; pclk1; pclk1; pclk1;
        href = 1'b0;
        pclk1;

        if (pixel_count !== 0) begin
            $display("FAIL: VSYNC=1 블랭킹 중 픽셀 캡처됨 (count=%0d)", pixel_count);
            $finish;
        end

        $display("PASS: ov7670_capture — 픽셀 8개, line_cnt=2, 마지막=0x1537 확인");
        $finish;
    end

    // 타임아웃 가드
    initial begin
        #(PCLK_P * 5000);
        $display("FAIL: 전체 테스트 타임아웃 (5000 PCLK 초과)");
        $finish;
    end

    initial begin
        $dumpfile("tb_ov7670_capture.vcd");
        $dumpvars(0, tb_ov7670_capture);
    end
endmodule
`default_nettype wire
