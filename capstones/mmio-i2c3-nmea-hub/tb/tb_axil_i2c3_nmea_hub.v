// tb_axil_i2c3_nmea_hub.v — 자체 점검형 테스트벤치
// PASS/FAIL 출력 규약: "PASS ..." / "FAIL ..." 로 시작하는 $display
// TEST_MODE(CTRL[8]=1)로 FIFO 직접 주입해 I2C/UART 슬레이브 모델 없이 검증
// TC1: 리셋 후 레지스터 기본값
// TC2: TEST_MODE FIFO 주입 + 팝
// TC3: TEST_MODE FIFO 풀(16엔트리) + 오버플로 무시
// TC4: FIFO_CLR 동작
// TC5: IRQ_EN/IRQ_PEND W1C 동작
// TC6: ID/VER 레지스터 값

`timescale 1ns/1ps
`default_nettype none

module tb_axil_i2c3_nmea_hub;

localparam CLK_PERIOD = 10;  // 100MHz

reg         aclk;
reg         aresetn;

// AXI4-Lite 버스
reg  [15:0] s_awaddr;
reg         s_awvalid;
wire        s_awready;
reg  [31:0] s_wdata;
reg  [3:0]  s_wstrb;
reg         s_wvalid;
wire        s_wready;
wire [1:0]  s_bresp;
wire        s_bvalid;
reg         s_bready;
reg  [15:0] s_araddr;
reg         s_arvalid;
wire        s_arready;
wire [31:0] s_rdata;
wire [1:0]  s_rresp;
wire        s_rvalid;
reg         s_rready;

// I2C (테스트에서 미사용, Hi-Z)
wire scl_w;
wire sda_w;

// UART (테스트에서 미사용, Hi)
reg         uart_rx;
wire        irq_out;

integer fail_cnt;
integer tc;

// ── DUT 인스턴스 ─────────────────────────────────────────
axil_i2c3_nmea_hub #(
    .CLK_DIV_I2C (1000),
    .CLK_DIV_UART(10417)
) dut (
    .aclk      (aclk),
    .aresetn   (aresetn),
    .s_awaddr  (s_awaddr),
    .s_awvalid (s_awvalid),
    .s_awready (s_awready),
    .s_wdata   (s_wdata),
    .s_wstrb   (s_wstrb),
    .s_wvalid  (s_wvalid),
    .s_wready  (s_wready),
    .s_bresp   (s_bresp),
    .s_bvalid  (s_bvalid),
    .s_bready  (s_bready),
    .s_araddr  (s_araddr),
    .s_arvalid (s_arvalid),
    .s_arready (s_arready),
    .s_rdata   (s_rdata),
    .s_rresp   (s_rresp),
    .s_rvalid  (s_rvalid),
    .s_rready  (s_rready),
    .scl       (scl_w),
    .sda       (sda_w),
    .uart_rx   (uart_rx),
    .irq_out   (irq_out)
);

// ── 클럭 ─────────────────────────────────────────────────
initial aclk = 0;
always #(CLK_PERIOD/2) aclk = ~aclk;

// ── AXI4-Lite 헬퍼 태스크 ────────────────────────────────
task axil_write;
    input [15:0] addr;
    input [31:0] data;
    begin
        @(posedge aclk); #1;
        s_awaddr  = addr; s_awvalid = 1;
        s_wdata   = data; s_wstrb = 4'hF; s_wvalid = 1;
        s_bready  = 1;
        // 주소 수락
        @(posedge aclk);
        while (!s_awready) @(posedge aclk);
        s_awvalid = 0;
        // 데이터 수락
        while (!s_wready) @(posedge aclk);
        s_wvalid = 0;
        // 응답 수락
        while (!s_bvalid) @(posedge aclk);
        @(posedge aclk); #1;
        s_bready = 0;
    end
endtask

task axil_read;
    input  [15:0] addr;
    output [31:0] data;
    begin
        @(posedge aclk); #1;
        s_araddr  = addr; s_arvalid = 1;
        s_rready  = 1;
        @(posedge aclk);
        while (!s_arready) @(posedge aclk);
        s_arvalid = 0;
        while (!s_rvalid) @(posedge aclk);
        data = s_rdata;
        @(posedge aclk); #1;
        s_rready = 0;
    end
endtask

// ── 체크 태스크 ──────────────────────────────────────────
task check_eq;
    input [255:0] name;
    input [31:0]  got;
    input [31:0]  expected;
    begin
        if (got !== expected) begin
            $display("FAIL TC%0d: %s got=0x%08x expected=0x%08x", tc, name, got, expected);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

// ── 테스트 메인 ──────────────────────────────────────────
reg [31:0] rd;
integer i;

initial begin
    fail_cnt   = 0;
    aresetn    = 0;
    uart_rx    = 1;
    s_awvalid  = 0; s_awaddr  = 0;
    s_wvalid   = 0; s_wdata   = 0; s_wstrb = 0;
    s_bready   = 0;
    s_arvalid  = 0; s_araddr  = 0;
    s_rready   = 0;

    repeat(5) @(posedge aclk);
    aresetn = 1;
    repeat(3) @(posedge aclk);

    // ── TC1: 리셋 후 기본값 ──────────────────────────────
    tc = 1;
    axil_read(16'h0000, rd); check_eq("CTRL default",      rd, 32'h0000_0000);
    axil_read(16'h0004, rd); check_eq("STATUS init",       rd, 32'h0000_0001);  // FIFO_EMPTY=1
    axil_read(16'h0010, rd); check_eq("FIFO_CNT init",     rd, 32'h0000_0000);
    axil_read(16'hFFF0, rd); check_eq("ID_REG",            rd, 32'h4855_4231);  // HUB1
    axil_read(16'hFFF4, rd); check_eq("VER_REG",           rd, 32'h0001_0000);
    $display("TC1: basic register defaults checked");

    // ── TC2: TEST_MODE FIFO 주입 + 팝 ──────────────────
    tc = 2;
    // TEST_MODE 활성 (CTRL[8]=1, EN=1)
    axil_write(16'h0000, 32'h0000_0101);  // TEST_MODE=1, EN=1
    // FIFO_INJ에 sensor_id=0, data=0xABCDEF
    axil_write(16'h001C, 32'h00AB_CDEF);
    repeat(2) @(posedge aclk);
    axil_read(16'h0010, rd); check_eq("FIFO_CNT after 1 inj", rd, 32'h0000_0001);
    axil_read(16'h0004, rd); check_eq("STATUS not empty",     rd[0], 1'b0);  // FIFO_EMPTY=0

    axil_read(16'h0008, rd); check_eq("FIFO_DATA pop",        rd, 32'h00AB_CDEF);
    axil_read(16'h0010, rd); check_eq("FIFO_CNT after pop",   rd, 32'h0000_0000);
    axil_read(16'h0004, rd); check_eq("STATUS empty after pop", rd[0], 1'b1);
    $display("TC2: TEST_MODE inject and pop OK");

    // ── TC3: FIFO 풀(16엔트리) + 오버플로 무시 ─────────
    tc = 3;
    for (i = 0; i < 16; i = i + 1) begin
        axil_write(16'h001C, {8'd0, 8'd0, 8'h00, i[7:0]});
    end
    repeat(5) @(posedge aclk);
    axil_read(16'h0010, rd); check_eq("FIFO_CNT full", rd, 32'd16);
    axil_read(16'h0004, rd); check_eq("STATUS FIFO_FULL", rd[1], 1'b1);

    // 17번째 주입: 드롭되어야 함
    axil_write(16'h001C, 32'hFF_FFFF);
    repeat(2) @(posedge aclk);
    axil_read(16'h0010, rd); check_eq("FIFO_CNT overflow ignored", rd, 32'd16);
    $display("TC3: FIFO full and overflow drop OK");

    // ── TC4: FIFO_CLR ───────────────────────────────────
    tc = 4;
    axil_write(16'h0000, 32'h0000_0181);  // FIFO_CLR=1 | TEST_MODE=1 | EN=1
    repeat(2) @(posedge aclk);
    axil_read(16'h0010, rd); check_eq("FIFO_CNT after CLR", rd, 32'h0000_0000);
    axil_read(16'h0004, rd); check_eq("STATUS FIFO_EMPTY after CLR", rd[0], 1'b1);
    $display("TC4: FIFO_CLR OK");

    // ── TC5: IRQ_EN / IRQ_PEND W1C ─────────────────────
    tc = 5;
    // 한 항목 주입으로 IRQ_PEND 세트 유도
    axil_write(16'h001C, 32'h01_000001);  // sensor_id=1, data=1
    repeat(5) @(posedge aclk);
    axil_read(16'hFFFC, rd); check_eq("IRQ_PEND set", rd[0], 1'b1);
    // IRQ_EN 활성
    axil_write(16'hFFF8, 32'h0000_0001);
    @(posedge aclk);
    if (irq_out !== 1'b1)
        $display("FAIL TC5: irq_out expected 1 got %b", irq_out);
    // IRQ_PEND W1C
    axil_write(16'hFFFC, 32'h0000_0001);
    repeat(3) @(posedge aclk);
    axil_read(16'hFFFC, rd); check_eq("IRQ_PEND cleared", rd[0], 1'b0);
    $display("TC5: IRQ_EN / IRQ_PEND W1C OK");

    // ── TC6: I2C_DIV / UART_DIV 레지스터 R/W ───────────
    tc = 6;
    axil_write(16'h0014, 32'd500);
    axil_read (16'h0014, rd); check_eq("I2C_DIV write", rd, 32'd500);
    axil_write(16'h0018, 32'd20833);
    axil_read (16'h0018, rd); check_eq("UART_DIV write", rd, 32'd20833);
    // I2C_DIV < 8이면 클램프
    axil_write(16'h0014, 32'd4);
    axil_read (16'h0014, rd); check_eq("I2C_DIV clamp", rd, 32'd8);
    $display("TC6: I2C_DIV / UART_DIV R/W and clamp OK");

    // ── 최종 결과 ─────────────────────────────────────────
    repeat(5) @(posedge aclk);
    if (fail_cnt == 0)
        $display("PASS all %0d checks", 6);
    else
        $display("FAIL %0d checks failed", fail_cnt);

    $finish;
end

// 타임아웃 가드
initial begin
    #5_000_000;
    $display("FAIL timeout");
    $finish;
end

endmodule
`default_nettype wire
