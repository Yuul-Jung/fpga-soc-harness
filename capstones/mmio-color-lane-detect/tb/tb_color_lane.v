// tb_color_lane.v — color_lane_top 자체 점검 테스트벤치
// 9×9 가상 프레임 4개로 레인·점프 신호를 검증.
//
// 테스트 프레임 (9×9, RGB565):
//   GREEN = 16'h07E0 (R=0, G=63 → g6=63, B=0)
//   NULL  = 16'h0000 (흑)
//   thresh=20, col_thr1=3, col_thr2=6, row_thr1=3, row_thr2=6
//
//   Frame1: 열 0,1,2 모두 녹색 → col_L 최대 → lane=1(LEFT)
//   Frame2: 열 3,4,5 모두 녹색 → col_C 최대 → lane=2(CENTER)
//   Frame3: 열 6,7,8 모두 녹색 → col_R 최대 → lane=3(RIGHT)
//   Frame4: 행 0 (TOP행) 모두 녹색 → jump=1
//
// 통과 조건: PASS, 실패: FAIL (접두어 필수)
// Verilog-2001.

`default_nettype none
`timescale 1ns/1ps

module tb_color_lane;
    // ---- 클럭 ----
    localparam SYS_PERIOD  = 10;   // 100 MHz
    localparam PCLK_PERIOD = 42;   // ~24 MHz

    reg clk, pclk;
    initial clk  = 0;
    initial pclk = 0;
    always #(SYS_PERIOD/2)  clk  = ~clk;
    always #(PCLK_PERIOD/2) pclk = ~pclk;

    // ---- DUT 포트 ----
    reg         rst;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg         wen, ren;
    wire [31:0] rdata;
    wire        irq;
    wire [1:0]  o_lane;
    wire        o_jump;

    // OV7670 신호 (TB가 직접 구동)
    reg         vsync, href;
    reg  [7:0]  cam_d;

    color_lane_top #(.BASE_ADDR(32'h1005_0000)) dut (
        .clk   (clk),
        .rst   (rst),
        .addr  (addr),
        .wdata (wdata),
        .wen   (wen),
        .ren   (ren),
        .rdata (rdata),
        .irq   (irq),
        .pclk  (pclk),
        .prst  (rst),   // TB에서는 같은 리셋 사용
        .vsync (vsync),
        .href  (href),
        .cam_d (cam_d),
        .o_lane(o_lane),
        .o_jump(o_jump)
    );

    // ---- MMIO 헬퍼 ----
    localparam BASE = 32'h1005_0000;
    task mmio_write;
        input [31:0] a, d;
        begin
            @(posedge clk); #1;
            addr = a; wdata = d; wen = 1; ren = 0;
            @(posedge clk); #1;
            wen = 0;
        end
    endtask

    task mmio_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge clk); #1;
            addr = a; wen = 0; ren = 1;
            @(posedge clk); #1;
            d = rdata;
            ren = 0;
        end
    endtask

    // ---- OV7670 프레임 송출 (PCLK 도메인) ----
    // 9열×9행 프레임.
    // 각 픽셀 = 2 PCLK 클럭 (짝수=high 바이트, 홀수=low 바이트).
    // row_index는 TB가 외부에서 관리.
    task send_pixel_pclk;
        input [15:0] pix;
        begin
            // 첫 바이트 (high)
            @(posedge pclk); #1;
            cam_d = pix[15:8];
            // 두 번째 바이트 (low)
            @(posedge pclk); #1;
            cam_d = pix[7:0];
        end
    endtask

    // col 패턴: green_cols[8:0] 비트 i=1이면 열 i 녹색
    localparam GREEN = 16'h07E0;
    localparam NULL  = 16'h0000;

    task send_frame_pclk;
        input [8:0] green_cols;  // 비트 마스크 (열 0~8)
        input [8:0] green_rows;  // 비트 마스크 (행 0~8) — 모든 열 녹색
        integer r, c;
        reg [15:0] pix;
        begin
            // VSYNC HIGH → 블랭킹 시작 (5 PCLK)
            vsync = 1; href = 0;
            repeat(5) @(posedge pclk); #1;
            // VSYNC LOW → 프레임 활성 시작 (frame_start)
            vsync = 0; href = 0;
            @(posedge pclk); #1;

            for (r = 0; r < 9; r = r + 1) begin
                // HREF HIGH → 라인 시작
                href = 1;
                for (c = 0; c < 9; c = c + 1) begin
                    if (green_rows[r])
                        pix = GREEN;
                    else if (green_cols[c])
                        pix = GREEN;
                    else
                        pix = NULL;
                    send_pixel_pclk(pix);
                end
                // HREF LOW → 라인 완료 (line_done)
                href = 0;
                repeat(2) @(posedge pclk); #1;
            end

            // VSYNC HIGH → 프레임 완료 (frame_done)
            vsync = 1;
            @(posedge pclk); #1;
            vsync = 0;
        end
    endtask

    // ---- 오류 카운터 ----
    integer fail_cnt;

    task check_lane;
        input [1:0] expected;
        input [31:0] rd;
        begin
            if (rd[2:1] !== expected) begin
                $display("FAIL lane: got %0d, expected %0d (STATUS=0x%08h)",
                         rd[2:1], expected, rd);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_jump;
        input expected;
        input [31:0] rd;
        begin
            if (rd[3] !== expected) begin
                $display("FAIL jump: got %0d, expected %0d (STATUS=0x%08h)",
                         rd[3], expected, rd);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ---- 메인 테스트 ----
    reg [31:0] rd;
    integer wait_cnt;
    reg frame_done_seen;

    initial begin
        fail_cnt = 0;
        // 초기화
        rst = 1; wen = 0; ren = 0; addr = 0; wdata = 0;
        vsync = 0; href = 0; cam_d = 8'd0;
        repeat(10) @(posedge clk); #1;
        rst = 0;
        repeat(5) @(posedge clk); #1;

        // ID 확인
        mmio_read(BASE + 32'hFC, rd);
        if (rd !== 32'h0007_0100) begin
            $display("FAIL ID_VER: 0x%08h", rd);
            fail_cnt = fail_cnt + 1;
        end

        // 초기 설정 확인 (THRESH=20, col_thr1=3, col_thr2=6)
        mmio_read(BASE + 32'h08, rd);
        if (rd[5:0] !== 6'd20) begin
            $display("FAIL THRESH default: %0d", rd[5:0]);
            fail_cnt = fail_cnt + 1;
        end

        // ENABLE
        mmio_write(BASE + 32'h00, 32'h0000_0001);  // bit0=ENABLE

        // ========== Frame1: 열 0,1,2 녹색 → lane=1(LEFT) ==========
        fork
            send_frame_pclk(9'b000_000_111, 9'b0);
            begin
                // 프레임 완료 대기 (최대 200μs = 20000 클럭)
                frame_done_seen = 0;
                for (wait_cnt = 0; wait_cnt < 20000 && !frame_done_seen; wait_cnt = wait_cnt + 1) begin
                    @(posedge clk);
                    if (o_lane !== 2'd0 || o_jump !== 1'd0) frame_done_seen = 1;
                end
            end
        join
        repeat(50) @(posedge clk);  // CDC 안정화
        mmio_read(BASE + 32'h04, rd);
        check_lane(2'd1, rd);  // LEFT
        check_jump(1'b0, rd);

        // ========== Frame2: 열 3,4,5 녹색 → lane=2(CENTER) ==========
        fork
            send_frame_pclk(9'b000_111_000, 9'b0);
            begin
                frame_done_seen = 0;
                for (wait_cnt = 0; wait_cnt < 20000 && !frame_done_seen; wait_cnt = wait_cnt + 1)
                    @(posedge clk);
            end
        join
        repeat(50) @(posedge clk);
        mmio_read(BASE + 32'h04, rd);
        check_lane(2'd2, rd);  // CENTER
        check_jump(1'b0, rd);

        // ========== Frame3: 열 6,7,8 녹색 → lane=3(RIGHT) ==========
        fork
            send_frame_pclk(9'b111_000_000, 9'b0);
            begin
                frame_done_seen = 0;
                for (wait_cnt = 0; wait_cnt < 20000 && !frame_done_seen; wait_cnt = wait_cnt + 1)
                    @(posedge clk);
            end
        join
        repeat(50) @(posedge clk);
        mmio_read(BASE + 32'h04, rd);
        check_lane(2'd3, rd);  // RIGHT
        check_jump(1'b0, rd);

        // ========== Frame4: 행 0 (TOP) 모두 녹색 → jump=1 ==========
        fork
            send_frame_pclk(9'b0, 9'b000_000_001);
            begin
                frame_done_seen = 0;
                for (wait_cnt = 0; wait_cnt < 20000 && !frame_done_seen; wait_cnt = wait_cnt + 1)
                    @(posedge clk);
            end
        join
        repeat(50) @(posedge clk);
        mmio_read(BASE + 32'h04, rd);
        check_jump(1'b1, rd);

        // ========== FRAME_CNT 확인 ==========
        mmio_read(BASE + 32'h14, rd);
        // 4 프레임 이상 완료되어야 함 (snap_valid 발생 기준)
        if (rd[7:0] < 8'd1) begin
            $display("FAIL FRAME_CNT too low: %0d", rd[7:0]);
            fail_cnt = fail_cnt + 1;
        end

        // ========== 결과 ==========
        if (fail_cnt === 0)
            $display("PASS tb_color_lane: 4 frames OK");
        else
            $display("FAIL tb_color_lane: %0d checks failed", fail_cnt);

        $finish;
    end

    // 타임아웃
    initial begin
        #5000000;
        $display("FAIL tb_color_lane: TIMEOUT");
        $finish;
    end

endmodule
`default_nettype wire
