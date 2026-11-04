// tb_tilemap.v — 자체 점검 테스트벤치 (vga_timing + tilemap_axil)
// 검사 항목:
//   T1: ID/VER 레지스터 읽기
//   T2: 팔레트 읽기/쓰기
//   T3: 폰트 프로그래밍 후 타일 화소 출력 확인
//   T4: 프레임 끝 인터럽트 (IRQ_ENABLE + 프레임 대기 + W1C)
// 통과 기준: !==로 비교(X/Z도 실패). 마지막에 "PASS" 또는 "FAIL" 출력.
//
// 오프셋 주의: tilemap_axil은 1사이클 지연 렌더러이므로
//   h_count=col*8+1 의 등록 클럭에서 col*8의 화소가 출력된다.

`timescale 1ns/1ps

module tb_tilemap;

// ---- 클럭/리셋 ----
reg clk;
initial clk = 0;
always #20 clk = ~clk; // 25 MHz (40 ns 주기)

reg rst_n;

// ---- DUT 연결 ----
// vga_timing
wire [9:0] h_count, v_count;
wire       hsync, vsync, active, frame_end;

vga_timing u_vga (
    .clk_25m   (clk),
    .rst       (!rst_n),
    .h_count   (h_count),
    .v_count   (v_count),
    .hsync     (hsync),
    .vsync     (vsync),
    .active    (active),
    .frame_end (frame_end)
);

// tilemap_axil
reg  [15:0] awaddr;
reg         awvalid, wvalid;
reg  [31:0] wdata;
reg  [3:0]  wstrb;
wire        awready, wready, bvalid;
wire [1:0]  bresp;
reg         bready;

reg  [15:0] araddr;
reg         arvalid;
wire        arready;
wire [31:0] rdata;
wire        rvalid;
reg         rready;

wire [3:0] pix_r, pix_g, pix_b;
wire       irq;

tilemap_axil u_dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .s_axil_awaddr  (awaddr),
    .s_axil_awvalid (awvalid),
    .s_axil_awready (awready),
    .s_axil_wdata   (wdata),
    .s_axil_wstrb   (wstrb),
    .s_axil_wvalid  (wvalid),
    .s_axil_wready  (wready),
    .s_axil_bresp   (bresp),
    .s_axil_bvalid  (bvalid),
    .s_axil_bready  (bready),
    .s_axil_araddr  (araddr),
    .s_axil_arvalid (arvalid),
    .s_axil_arready (arready),
    .s_axil_rdata   (rdata),
    .s_axil_rresp   (),
    .s_axil_rvalid  (rvalid),
    .s_axil_rready  (rready),
    .h_count        (h_count),
    .v_count        (v_count),
    .active         (active),
    .frame_end      (frame_end),
    .pix_r          (pix_r),
    .pix_g          (pix_g),
    .pix_b          (pix_b),
    .irq            (irq)
);

// ---- 오류 카운터 ----
integer fail_cnt;

// ---- AXI 쓰기 태스크 ----
task axi_write;
    input [15:0] addr;
    input [31:0] d;
    begin
        @(negedge clk);
        awaddr  = addr; awvalid = 1'b1;
        wdata   = d;    wvalid  = 1'b1; wstrb = 4'hF;
        bready  = 1'b1;
        @(posedge clk); #1;
        awvalid = 1'b0; wvalid = 1'b0;
        @(posedge clk); #1;
    end
endtask

// ---- AXI 읽기 태스크 ----
reg [31:0] rd_result;
task axi_read;
    input [15:0] addr;
    begin
        @(negedge clk);
        araddr = addr; arvalid = 1'b1; rready = 1'b1;
        @(posedge clk); #1;
        arvalid = 1'b0;
        // rvalid가 1이 될 때까지 대기 (레벨 감지: NBA 이후 이미 1이면 즉시 통과)
        wait(rvalid === 1'b1);
        rd_result = rdata;
        @(posedge clk); #1;
        rready = 1'b0;
    end
endtask

// ---- 비교 태스크 ----
task check32;
    input [63:0] label; // 사용하지 않음 (문자열 비교 불필요)
    input [31:0] got;
    input [31:0] exp;
    begin
        if (got !== exp) begin
            $display("FAIL: got=%h exp=%h", got, exp);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

// ---- 메인 시퀀스 ----
integer i;
integer frame_cycles;
integer pixel_clk;
reg [3:0] exp_r, exp_g, exp_b;

initial begin
    fail_cnt = 0;
    // 초기화
    awvalid = 0; wvalid = 0; bready = 0;
    arvalid = 0; rready = 0;
    awaddr = 0; wdata = 0; wstrb = 4'hF;
    araddr = 0;

    // 리셋
    rst_n = 0;
    repeat(4) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);

    // ============================================================
    // T1: ID/VER 읽기
    // ============================================================
    axi_read(16'h0000);
    check32(0, rd_result, 32'h544D_4150);  // "TMAP"
    axi_read(16'h0004);
    check32(0, rd_result, 32'h0001_0000);  // VER 1.0

    // ============================================================
    // T2: 팔레트 쓰기/읽기
    //     PALETTE[0]=0x000(검정) → 0x248로 변경 후 읽기
    // ============================================================
    axi_write(16'h0028, 32'h0000_0248);
    axi_read (16'h0028);
    check32(0, rd_result[11:0], 12'h248);
    // 흰색(15) 기본값 확인
    axi_read(16'h0064);
    check32(0, rd_result[11:0], 12'hFFF);
    // 팔레트를 EGA 기본으로 복원
    axi_write(16'h0028, 32'h0000_0000);

    // ============================================================
    // T3: 폰트 프로그래밍 + 타일 배치 + 화소 출력 확인
    //   - tile_id=0x01, 폰트 행 0 = 8'b1010_1010 = 0xAA
    //   - tile 위치: col=2, row=1 → idx = 1*80+2 = 82
    //   - fg=15(흰색=0xFFF), bg=0(검정=0x000)
    //   - 타일 행 1 위치: v_count=8, h_count=16
    //   - 1사이클 지연이므로 h_count=17에서 col=16의 화소가 출력됨
    //   - 화소 비트 0(h=16): font[0xAA] bit7=1 → fg=15=0xFFF → R=0xF
    //   - 화소 비트 1(h=17): font[0xAA] bit6=0 → bg=0=0x000 → R=0x0
    // ============================================================

    // 폰트 프로그래밍: tile_id=0x01, 행 0
    axi_write(16'h0020, 32'h0000_0008);  // FONT_ADDR = 0x01*8+0 = 8
    axi_write(16'h0024, 32'h0000_00AA);  // FONT_DATA = 0xAA = 10101010b

    // 타일 배치: col=2, row=1, idx=82
    axi_write(16'h0018, 32'h0000_0052);  // TILE_ADDR = 82
    axi_write(16'h001C, 32'h0000_F001);  // TILE_DATA: fg=0, bg=F(흰), tile_id=1

    // VGA를 v=8, h=16 위치까지 대기 후 화소 확인
    // 실제 화소는 h=16+1=17 클럭에서 나타남 (1사이클 렌더 파이프라인)
    // v=8, h=16이 되는 사이클 수 = (8*800+16) = 6416 사이클 (리셋 후)
    // 그러나 리셋 후 vga 카운터도 0부터 시작하므로 직접 대기한다.
    fork
        begin : wait_pixel
            // v_count==8, h_count==17 (h+1 오프셋) 가 될 때까지 대기
            // 최대 1 프레임(420000 사이클) 내에 도달해야 함
            repeat(420001) begin
                @(posedge clk);
                if (v_count == 10'd8 && h_count == 10'd17) begin
                    // 이 사이클에서 h=16 위치의 화소가 등록됨
                    // pix_r은 1사이클 더 지나야 확정되므로 다음 클럭에서 확인
                    @(posedge clk);
                    // TILE_DATA 를 {bg=0xF,fg=0x0, tile_id=0x01}로 설정했으므로
                    // font 비트=1 → fg_color=0x0(검정 아님... 수정: fg=[7:4], bg=[15:12])
                    // 실제 TILE_DATA[15:8] = attr = {bg[3:0], fg[3:0]}
                    // wdata=0x0000_F001 → wdata[15:8]=0xF0 → bg=0xF(흰), fg=0x0(검정)
                    // pix_bit=1 → fg=0 → palette[0]=0x000 → R=0, G=0, B=0
                    // pix_bit=0 → bg=F → palette[F]=0xFFF → R=F, G=F, B=F
                    // 0xAA=10101010: bit7=1(fg색), bit6=0(bg색)
                    // h=16(pixel_x=0): font_row[7]=1 → fg=0 → black R=0
                    // h=17(pixel_x=1): 이 사이클에서 h=17 → pixel_x_q=1(h=16에서 등록됨)
                    // → font_row[7-1]=font_row[6]=0 → bg=F → white R=F
                    if (pix_r !== 4'h0 || pix_g !== 4'h0 || pix_b !== 4'h0) begin
                        $display("FAIL T3a: pix@h16=%h%h%h exp=000", pix_r,pix_g,pix_b);
                        fail_cnt = fail_cnt + 1;
                    end
                    @(posedge clk);
                    // 다음 클럭: h=18에서 h=17(pixel_x=1)의 화소 → bg=0xF → white
                    if (pix_r !== 4'hF || pix_g !== 4'hF || pix_b !== 4'hF) begin
                        $display("FAIL T3b: pix@h17=%h%h%h exp=FFF", pix_r,pix_g,pix_b);
                        fail_cnt = fail_cnt + 1;
                    end
                    disable wait_pixel;
                end
            end
        end
    join

    // ============================================================
    // T4: 프레임 끝 인터럽트
    //   IRQ_ENABLE bit0=1 설정 → 프레임 끝 대기 → irq=1 확인
    //   IRQ_STATUS W1C → irq=0 확인
    // ============================================================
    axi_write(16'h000C, 32'h0000_0001); // IRQ_ENABLE bit0=1

    // frame_end 펄스 대기 (최대 1 프레임)
    begin : wait_irq
        repeat(421000) begin
            @(posedge clk);
            if (irq) disable wait_irq;
        end
    end

    // irq 활성 확인
    if (irq !== 1'b1) begin
        $display("FAIL T4a: irq=%b exp=1", irq);
        fail_cnt = fail_cnt + 1;
    end

    // IRQ_STATUS 읽기 — bit0=1 확인
    axi_read(16'h0008);
    if (rd_result[0] !== 1'b1) begin
        $display("FAIL T4b: IRQ_STATUS=%h bit0 exp=1", rd_result);
        fail_cnt = fail_cnt + 1;
    end

    // W1C: IRQ_STATUS bit0 클리어
    axi_write(16'h0008, 32'h0000_0001);
    @(posedge clk); @(posedge clk);
    if (irq !== 1'b0) begin
        $display("FAIL T4c: irq=%b after W1C, exp=0", irq);
        fail_cnt = fail_cnt + 1;
    end

    // ============================================================
    // 최종 결과
    // ============================================================
    @(posedge clk);
    if (fail_cnt == 0)
        $display("PASS tilemap_axil: T1(ID/VER) T2(PALETTE) T3(PIXEL) T4(IRQ) all ok");
    else
        $display("FAIL tilemap_axil: %0d 개 오류", fail_cnt);

    $finish;
end

// 무한루프 방지 타임아웃: 2 프레임(840 ms @ 25 MHz)
initial begin
    #33_600_000; // 33.6 ms (840000 사이클 × 40 ns)
    $display("FAIL tb_tilemap: 타임아웃 (2 프레임 초과)");
    $finish;
end

endmodule
