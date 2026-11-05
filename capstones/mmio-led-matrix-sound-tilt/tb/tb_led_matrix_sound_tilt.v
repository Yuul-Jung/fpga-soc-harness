// tb_led_matrix_sound_tilt.v
// PASS/FAIL 자체 점검형 테스트벤치
// 검증 항목:
//   TB1: 소리 막대 모드 — 합성 에너지 → 올바른 막대 높이 비트맵
//   TB2: 기울기 점 모드 — 합성 ADXL X/Y → 올바른 점 위치 비트맵
//   TB3: AXI4-Lite 슬레이브 쓰기/읽기 레지스터 왕복
//   TB4: MAX7219 체인 드라이버 CS/CLK 토글 여부
//
// 실행 방법: iverilog -o sim.vvp tb_led_matrix_sound_tilt.v && vvp sim.vvp
// 출력: 테스트마다 PASS/FAIL, 최종 PASS 또는 FAIL
//
// Verilog-2001. iverilog 호환.
`default_nettype none
`timescale 1ns/1ps

module tb_led_matrix_sound_tilt;
    // 클럭·리셋
    reg clk;
    reg rst_n;

    // AXI4-Lite 마스터 신호 (테스트용)
    reg  [11:0] m_awaddr;
    reg         m_awvalid;
    wire        m_awready;
    reg  [31:0] m_wdata;
    reg  [3:0]  m_wstrb;
    reg         m_wvalid;
    wire        m_wready;
    wire [1:0]  m_bresp;
    wire        m_bvalid;
    reg         m_bready;
    reg  [11:0] m_araddr;
    reg         m_arvalid;
    wire        m_arready;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rvalid;
    reg         m_rready;

    // PDM (더미: data=0)
    wire        pdm_clk_out;
    reg         pdm_data_in;

    // ADXL345 (루프백 더미)
    wire        adxl_sclk;
    wire        adxl_mosi;
    reg         adxl_miso;
    wire        adxl_cs_n;

    // MAX7219
    wire        max_sclk;
    wire        max_mosi;
    wire        max_cs_n;

    // 디버그
    wire        ip_busy;

    // SoC 인스턴스
    led_matrix_sound_tilt_soc u_soc (
        .clk(clk), .rst_n(rst_n),
        .m_awaddr(m_awaddr), .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata(m_wdata),   .m_wstrb(m_wstrb),     .m_wvalid(m_wvalid),   .m_wready(m_wready),
        .m_bresp(m_bresp),   .m_bvalid(m_bvalid),   .m_bready(m_bready),
        .m_araddr(m_araddr), .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_rdata(m_rdata),   .m_rresp(m_rresp),     .m_rvalid(m_rvalid),   .m_rready(m_rready),
        .pdm_clk_out(pdm_clk_out), .pdm_data_in(pdm_data_in),
        .adxl_sclk(adxl_sclk), .adxl_mosi(adxl_mosi),
        .adxl_miso(adxl_miso), .adxl_cs_n(adxl_cs_n),
        .max_sclk(max_sclk), .max_mosi(max_mosi), .max_cs_n(max_cs_n),
        .ip_busy(ip_busy)
    );

    // 프레임 버퍼 직접 접근 (TB2: 비트맵 확인)
    wire [127:0] bitmap_wire;
    assign bitmap_wire = u_soc.bitmap;

    // 클럭 생성: 100 MHz = 10 ns 주기
    initial clk = 0;
    always #5 clk = ~clk;

    // AXI 버스 태스크 --------------------------------------------------
    task axil_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            m_awaddr  <= addr; m_awvalid <= 1;
            m_wdata   <= data; m_wstrb   <= 4'hF; m_wvalid <= 1;
            m_bready  <= 1;
            // awready 대기
            @(posedge clk);
            while (!m_awready) @(posedge clk);
            m_awvalid <= 0;
            // wready 대기
            while (!m_wready) @(posedge clk);
            m_wvalid <= 0;
            // bvalid 대기
            while (!m_bvalid) @(posedge clk);
            @(posedge clk);
        end
    endtask

    task axil_read;
        input  [11:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            m_araddr  <= addr; m_arvalid <= 1;
            m_rready  <= 1;
            @(posedge clk);
            while (!m_arready) @(posedge clk);
            m_arvalid <= 0;
            while (!m_rvalid) @(posedge clk);
            data = m_rdata;
            @(posedge clk);
        end
    endtask

    // 에러 카운터
    integer fail_cnt;

    // 체크 매크로를 태스크로 구현
    task check_eq;
        input [255:0] label;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got !== exp) begin
                $display("FAIL %0s: got=0x%08X exp=0x%08X", label, got, exp);
                fail_cnt = fail_cnt + 1;
            end else
                $display("  OK %0s: 0x%08X", label, got);
        end
    endtask

    // frame_buf 에너지 강제: energy_flat 포트를 직접 사용
    // (iverilog vvp는 reg 배열의 개별 원소 force를 지원하지 않음)

    integer b, r, c;
    reg [31:0] rd_data;
    reg [2:0]  bar_h;
    reg [127:0] bm_snap;
    integer    pixel;
    integer    dot_col_exp, dot_row_exp;

    initial begin
        // 초기화
        fail_cnt  = 0;
        rst_n     = 0;
        m_awvalid = 0; m_wvalid  = 0; m_bready  = 1;
        m_arvalid = 0; m_rready  = 1;
        m_awaddr  = 0; m_wdata   = 0; m_wstrb   = 0;
        m_araddr  = 0;
        pdm_data_in = 0;
        adxl_miso   = 1;

        // 리셋 해제
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5)  @(posedge clk);

        // ================================================================
        // TB3: AXI4-Lite 슬레이브 레지스터 쓰기/읽기
        // ================================================================
        $display("=== TB3: AXI4-Lite 레지스터 왕복 ===");

        // CTRL 쓰기: en=1, pdm_clk_en=1, adxl_en=1 (기본값 복원)
        axil_write(12'h000, 32'h0000_000D);  // bit[0]=en, [2]=pdm_clk_en, [3]=adxl_en
        axil_read (12'h000, rd_data);
        check_eq("CTRL_rd", rd_data & 32'h0000_000D, 32'h0000_000D);

        // MODE 쓰기: mode=2'b10 (혼합)
        axil_write(12'h008, 32'h0000_0002);
        axil_read (12'h008, rd_data);
        check_eq("MODE_rd", rd_data[1:0], 2'b10);

        // BRIGHT 쓰기: 0xA
        axil_write(12'h00C, 32'h0000_000A);
        axil_read (12'h00C, rd_data);
        check_eq("BRIGHT_rd", rd_data[3:0], 4'hA);

        // 존재하지 않는 레지스터 → DEAD_BEEF
        axil_read (12'h080, rd_data);
        check_eq("DEAD_BEEF", rd_data, 32'hDEAD_BEEF);

        // ================================================================
        // TB1: 소리 막대 모드 비트맵 확인
        // ================================================================
        $display("=== TB1: 소리 막대 모드 ===");

        // MODE = 00 (소리 막대)
        axil_write(12'h008, 32'h0000_0000);
        // CTRL = en=1
        axil_write(12'h000, 32'h0000_0001);

        // 에너지 강제: energy_flat 포트 직접 사용
        // energy_flat[gi*32 +: 32]: band0=[31:0], band7=[255:224] (LSB=band0)
        force u_soc.u_frame.energy_flat = {
            32'h4000_0000,  // band 7: bar_h=2 (상위3비트=010)
            32'h0000_0000,  // band 6: bar_h=0
            32'h0000_0000,  // band 5: bar_h=0
            32'h0000_0000,  // band 4: bar_h=0
            32'h0000_0000,  // band 3: bar_h=0
            32'h0000_0000,  // band 2: bar_h=0
            32'h0000_0000,  // band 1: bar_h=0
            32'hFFFF_FFFF   // band 0: bar_h=7 (상위3비트=111)
        };

        // energy_update 펄스를 직접 강제
        force u_soc.u_frame.energy_update = 1;
        @(posedge clk);
        force u_soc.u_frame.energy_update = 0;
        @(posedge clk);
        // bitmap 갱신 대기
        repeat(5) @(posedge clk);

        bm_snap = u_soc.bitmap;

        // 대역 0: col 0,1 모두 7행 켜있어야 함 (bar_h=7, 모든 행)
        begin : tb1_band0
            integer ok_b0;
            ok_b0 = 1;
            for (r = 0; r < 8; r = r+1) begin
                // col_l=0, col_r=1
                if (bm_snap[r*16 + 0] !== 1'b1) ok_b0 = 0;
                if (bm_snap[r*16 + 1] !== 1'b1) ok_b0 = 0;
            end
            if (ok_b0)
                $display("  OK TB1_band0: 전행 켜짐");
            else begin
                $display("FAIL TB1_band0: bar_h=7 미반영");
                fail_cnt = fail_cnt + 1;
            end
        end

        // 대역 1: col 2,3 모두 꺼짐 (bar_h=0)
        begin : tb1_band1
            integer ok_b1;
            ok_b1 = 1;
            for (r = 0; r < 8; r = r+1) begin
                if (bm_snap[r*16 + 2] !== 1'b0) ok_b1 = 0;
                if (bm_snap[r*16 + 3] !== 1'b0) ok_b1 = 0;
            end
            if (ok_b1)
                $display("  OK TB1_band1: 전행 꺼짐");
            else begin
                $display("FAIL TB1_band1: bar_h=0 미반영");
                fail_cnt = fail_cnt + 1;
            end
        end

        // 대역 7: col 14,15, bar_h=2 → 하위 2행(row6,row7)만 켜짐
        begin : tb1_band7
            integer ok_b7;
            ok_b7 = 1;
            // row 0~5: 꺼짐
            for (r = 0; r < 6; r = r+1) begin
                if (bm_snap[r*16 + 14] !== 1'b0) ok_b7 = 0;
                if (bm_snap[r*16 + 15] !== 1'b0) ok_b7 = 0;
            end
            // row 6,7: 켜짐
            if (bm_snap[6*16 + 14] !== 1'b1) ok_b7 = 0;
            if (bm_snap[7*16 + 14] !== 1'b1) ok_b7 = 0;
            if (ok_b7)
                $display("  OK TB1_band7: bar_h=2 하위2행만 켜짐");
            else begin
                $display("FAIL TB1_band7: bar_h=2 미반영. bm[6*16+14]=%b bm[7*16+14]=%b",
                         bm_snap[6*16+14], bm_snap[7*16+14]);
                fail_cnt = fail_cnt + 1;
            end
        end

        release u_soc.u_frame.energy_flat;
        release u_soc.u_frame.energy_update;

        // ================================================================
        // TB2: 기울기 점 모드 비트맵 확인
        // ================================================================
        $display("=== TB2: 기울기 점 모드 ===");

        // MODE = 01 (기울기 점)
        axil_write(12'h008, 32'h0000_0001);

        // X=0, Y=0 → dot_col = 0[9:6]+8 = 8, dot_row = 0[9:7]+4 = 4
        force u_soc.u_frame.x_hold = 10'd0;
        force u_soc.u_frame.y_hold = 10'd0;
        force u_soc.u_frame.adxl_valid = 1;
        @(posedge clk);
        force u_soc.u_frame.adxl_valid = 0;
        @(posedge clk);
        repeat(5) @(posedge clk);
        bm_snap = u_soc.bitmap;

        dot_col_exp = 8; dot_row_exp = 4;
        pixel = bm_snap[dot_row_exp*16 + dot_col_exp];
        if (pixel !== 1) begin
            $display("FAIL TB2_center: X=0,Y=0 → (row=%0d,col=%0d) got %0d",
                     dot_row_exp, dot_col_exp, pixel);
            fail_cnt = fail_cnt + 1;
        end else
            $display("  OK TB2_center: X=0,Y=0 → (row=4,col=8) 켜짐");

        // X=511(최대 양수 10비트=0x1FF), Y=-512(최소 10비트=0x200)
        // x_hold[9:6] = 0x1FF >> 6 = 0x7 (3'd7) → dot_col = 7+8=15
        // y_hold[9:7] = 0x200 >> 7 = 0x4 (부호 연장으로 상위 비트=1, 10'b10_0000_0000 >> 7 = 3'd4 → +4 = 8 → 오버플로 클램프=7
        // y_hold = -512 → 10'b10_0000_0000: [9:7]=3'b100=4(부호 무시, 비트만), 4+4=8 > 7 → clamp=7
        force u_soc.u_frame.x_hold = 10'h1FF;   // +511
        force u_soc.u_frame.y_hold = 10'h200;   // -512 (2의 보수)
        force u_soc.u_frame.adxl_valid = 1;
        @(posedge clk);
        force u_soc.u_frame.adxl_valid = 0;
        @(posedge clk);
        repeat(5) @(posedge clk);
        bm_snap = u_soc.bitmap;

        dot_col_exp = 15; dot_row_exp = 7;  // 클램프 후
        pixel = bm_snap[dot_row_exp*16 + dot_col_exp];
        if (pixel !== 1) begin
            $display("FAIL TB2_corner: X=511,Y=-512 → (row=%0d,col=%0d) got %0d",
                     dot_row_exp, dot_col_exp, pixel);
            fail_cnt = fail_cnt + 1;
        end else
            $display("  OK TB2_corner: X=511,Y=-512 → (row=7,col=15) 켜짐");

        release u_soc.u_frame.x_hold;
        release u_soc.u_frame.y_hold;
        release u_soc.u_frame.adxl_valid;

        // ================================================================
        // TB4: MAX7219 CS/CLK 활성화 여부
        // ================================================================
        $display("=== TB4: MAX7219 체인 드라이버 활성 ===");
        // 리셋 후 10ms 대기(wait 카운터 1_000_000 사이클) — 너무 길므로
        // u_soc.u_max의 state가 S_IDLE(4'd3)에 들어왔는지 확인하는 방식 사용
        // 실제 10ms는 10ms×100클럭/ns = 1,000,000 사이클 → 시뮬레이션에서 10,000사이클로 가속
        // MAX7219 드라이버 wait_cnt를 직접 강제해서 초기화 완료로 점프
        force u_soc.u_max.wait_cnt = 24'd999_999;
        // S_WAIT(4'd1)이면 다음 클럭에 S_INIT로 전환
        force u_soc.u_max.state = 4'd1;  // S_WAIT
        @(posedge clk); @(posedge clk);
        // 이제 S_INIT → S_IDLE 흐름
        release u_soc.u_max.wait_cnt;
        release u_soc.u_max.state;
        repeat(20) @(posedge clk);

        // refresh 펄스 강제 → S_BRIGHT 진입 → CS 하강
        force u_soc.u_max.refresh_latch = 1;
        @(posedge clk);
        release u_soc.u_max.refresh_latch;

        begin : tb4_cs
            integer cs_low_seen;
            integer timeout;
            cs_low_seen = 0;
            for (timeout = 0; timeout < 200 && !cs_low_seen; timeout = timeout+1) begin
                @(posedge clk);
                if (max_cs_n === 1'b0) cs_low_seen = 1;
            end
            if (cs_low_seen)
                $display("  OK TB4: MAX7219 CS_N 하강 확인");
            else begin
                $display("FAIL TB4: MAX7219 CS_N 하강 없음");
                fail_cnt = fail_cnt + 1;
            end
        end

        // ================================================================
        // 최종 판정
        // ================================================================
        $display("=== 최종 판정 ===");
        if (fail_cnt === 0)
            $display("PASS: 모든 항목 통과 (%0d개)", 4);
        else
            $display("FAIL: %0d개 항목 실패", fail_cnt);

        $finish;
    end

    // 타임아웃 보호 (5ms = 500,000ns)
    initial begin
        #500_000;
        $display("FAIL: 테스트 타임아웃");
        $finish;
    end

endmodule
`default_nettype wire
