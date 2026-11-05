// tb_jstk2_servo.v — 자체 점검 테스트벤치 (PASS/FAIL 출력)
// jstk2_servo_ip 검증:
//   1. JSTK2 SPI 응답 모델: 5바이트 반환 (X=0x200, Y=0x1FF, BTN=0x01)
//   2. 샘플 완료 IRQ 확인
//   3. 서보 A PWM 펄스 폭 측정 (기대값: 1,500,000 클럭)
//   4. 레지스터 읽기 검증 (JSTK2_X, JSTK2_Y, JSTK2_BTN, ID, VER)
// !==을 사용해 X/Z도 실패로 처리
`timescale 1ns/1ps

module tb_jstk2_servo;

// ─── DUT 포트 ─────────────────────────────────────────────────────
reg         clk;
reg         rst_n;
reg  [31:0] s_awaddr;
reg         s_awvalid;
wire        s_awready;
reg  [31:0] s_wdata;
reg  [3:0]  s_wstrb;
reg         s_wvalid;
wire        s_wready;
wire [1:0]  s_bresp;
wire        s_bvalid;
reg         s_bready;
reg  [31:0] s_araddr;
reg         s_arvalid;
wire        s_arready;
wire [31:0] s_rdata;
wire [1:0]  s_rresp;
wire        s_rvalid;
reg         s_rready;
wire        irq;
wire        spi_cs_n;
wire        spi_sclk;
wire        spi_mosi;
reg         spi_miso;
wire        pwm_a;
wire        pwm_b;

// ─── DUT 인스턴스 (가속: SAMPLE_PERIOD_MS=1로 단축) ──────────────
jstk2_servo_ip #(
    .CLK_FREQ_HZ      (100_000_000),
    .SPI_CLK_HZ       (  1_000_000),
    .SAMPLE_PERIOD_MS (1)           // 테스트 가속: 1 ms 샘플
) dut (
    .s_axi_aclk    (clk),
    .s_axi_aresetn (rst_n),
    .s_axi_awaddr  (s_awaddr),
    .s_axi_awvalid (s_awvalid),
    .s_axi_awready (s_awready),
    .s_axi_wdata   (s_wdata),
    .s_axi_wstrb   (s_wstrb),
    .s_axi_wvalid  (s_wvalid),
    .s_axi_wready  (s_wready),
    .s_axi_bresp   (s_bresp),
    .s_axi_bvalid  (s_bvalid),
    .s_axi_bready  (s_bready),
    .s_axi_araddr  (s_araddr),
    .s_axi_arvalid (s_arvalid),
    .s_axi_arready (s_arready),
    .s_axi_rdata   (s_rdata),
    .s_axi_rresp   (s_rresp),
    .s_axi_rvalid  (s_rvalid),
    .s_axi_rready  (s_rready),
    .irq           (irq),
    .spi_cs_n      (spi_cs_n),
    .spi_sclk      (spi_sclk),
    .spi_mosi      (spi_mosi),
    .spi_miso      (spi_miso),
    .pwm_a         (pwm_a),
    .pwm_b         (pwm_b)
);

// ─── 클럭 ─────────────────────────────────────────────────────────
initial clk = 0;
always #5 clk = ~clk; // 100 MHz

// ─── JSTK2 SPI 슬레이브 모델 ─────────────────────────────────────
// MISO에 고정 패킷 반환: X_L=0x00, X_H=0x08(=512>>2?→10bit 표현),
// 실제 PmodJSTK2 형식: byte0=JSTK_X[7:0], byte1={6'b0, JSTK_X[9:8]}
//                       byte2=JSTK_Y[7:0], byte3={6'b0, JSTK_Y[9:8]}
//                       byte4={6'b0, BTN2, BTN1}
// 테스트 값: X=512(0x200), Y=511(0x1FF), BTN=0x01(BTN1 눌림)
// 5바이트 = 40비트: 0x00_02_FF_01_01
// byte0(X_L)=0x00, byte1(X_H)=0x02, byte2(Y_L)=0xFF, byte3(Y_H)=0x01, byte4(BTN)=0x01
localparam [39:0] SPI_MISO_DATA = 40'h00_02_FF_01_01;
// 예상 파싱: X = {X_H[1:0], X_L} = {2'b10, 8'h00} = 10'b10_0000_0000 = 512
//            Y = {Y_H[1:0], Y_L} = {2'b01, 8'hFF} = 10'b01_1111_1111 = 511
//            BTN = 0x01[1:0] = 2'b01 (BTN1=1, BTN2=0)

reg [5:0]  miso_bit_cnt;
reg [39:0] miso_shift;
reg        spi_cs_n_prev;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_miso      <= 1'b0;
        miso_bit_cnt  <= 6'd0;
        miso_shift    <= SPI_MISO_DATA;
        spi_cs_n_prev <= 1'b1;
    end else begin
        spi_cs_n_prev <= spi_cs_n;
        // CS# 하강: 새 전송 시작, MISO 데이터 준비
        if (spi_cs_n_prev && !spi_cs_n) begin
            miso_shift   <= SPI_MISO_DATA;
            miso_bit_cnt <= 6'd0;
        end
        // SCLK 상승에지에서 MISO 비트 출력 (Mode 0)
        if (!spi_cs_n && spi_sclk) begin
            spi_miso     <= miso_shift[39];
            miso_shift   <= {miso_shift[38:0], 1'b0};
            miso_bit_cnt <= miso_bit_cnt + 1'b1;
        end
    end
end

// ─── AXI 태스크 ───────────────────────────────────────────────────
integer fail_count;

task axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        s_awaddr  <= addr;
        s_awvalid <= 1'b1;
        s_wdata   <= data;
        s_wstrb   <= 4'hF;
        s_wvalid  <= 1'b1;
        @(posedge clk); #1;
        while (!(s_awready && s_wready)) @(posedge clk); #1;
        s_awvalid <= 1'b0;
        s_wvalid  <= 1'b0;
        s_bready  <= 1'b1;
        @(posedge clk); #1;
        while (!s_bvalid) @(posedge clk); #1;
        s_bready  <= 1'b0;
    end
endtask

task axi_read;
    input  [31:0] addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        s_araddr  <= addr;
        s_arvalid <= 1'b1;
        s_rready  <= 1'b1;
        @(posedge clk); #1;
        while (!s_rvalid) @(posedge clk); #1;
        data      <= s_rdata;
        s_arvalid <= 1'b0;
        s_rready  <= 1'b0;
    end
endtask

task check_eq;
    input [31:0] got;
    input [31:0] exp;
    input [255:0] msg;
    begin
        if (got !== exp) begin
            $display("FAIL: %s got=0x%08X exp=0x%08X", msg, got, exp);
            fail_count = fail_count + 1;
        end
    end
endtask

// ─── 메인 테스트 ──────────────────────────────────────────────────
reg [31:0] rd_data;
integer    timeout;
integer    irq_got;

// 서보 A PWM 펄스 폭 측정 변수
real      pwm_rise_time;
real      pwm_fall_time;
real      pulse_width_clk;
integer   pulse_meas_done;

// PWM 측정 프로세스
real clk_period = 10.0; // ns
real pwm_a_prev;

initial begin
    // 초기화
    fail_count   = 0;
    irq_got      = 0;
    pulse_meas_done = 0;
    s_awaddr     = 0; s_awvalid = 0;
    s_wdata      = 0; s_wstrb   = 0; s_wvalid = 0;
    s_bready     = 0;
    s_araddr     = 0; s_arvalid = 0; s_rready = 0;
    spi_miso     = 0;
    rst_n        = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);

    // ── 테스트 1: ID/VER 레지스터 확인 ──────────────────────────
    axi_read(32'h401F_FFF0, rd_data);
    check_eq(rd_data, 32'h4A535356, "ID reg");
    axi_read(32'h401F_FFF4, rd_data);
    check_eq(rd_data, 32'h01010000, "VER reg");
    $display("T1 ID/VER OK");

    // ── 테스트 2: CTRL 쓰기 → JSTK2+PWM 활성 ───────────────────
    axi_write(32'h401F_0014, 32'h3); // CTRL[0]=1, CTRL[1]=1
    axi_write(32'h401F_000C, 32'd1_500_000); // SERVO_A = 1.5 ms 중앙
    axi_write(32'h401F_0010, 32'd1_500_000); // SERVO_B = 1.5 ms 중앙
    axi_write(32'h401F_FFFC, 32'h1);         // IRQ_ENABLE[0]=1
    $display("T2 CTRL/SERVO write done");

    // ── 테스트 3: IRQ 발생 대기 (JSTK2 샘플 완료) ───────────────
    // SAMPLE_PERIOD_MS=1 → 100,000클럭 주기 + SPI 전송시간
    // 최대 대기: 500,000 클럭 (5 ms)
    timeout = 500000;
    irq_got = 0;
    while (timeout > 0 && !irq) begin
        @(posedge clk);
        timeout = timeout - 1;
    end
    if (!irq) begin
        $display("FAIL: IRQ timeout after JSTK2 sample");
        fail_count = fail_count + 1;
    end else begin
        $display("T3 IRQ received OK (timeout_left=%0d)", timeout);
        irq_got = 1;
    end

    // ── 테스트 4: IRQ 소거 (W1C) ─────────────────────────────────
    axi_write(32'h401F_FFF8, 32'h1); // IRQ_STATUS W1C
    @(posedge clk); @(posedge clk);
    axi_read(32'h401F_FFF8, rd_data);
    check_eq(rd_data[0], 1'b0, "IRQ_STATUS cleared");
    $display("T4 IRQ W1C OK");

    // ── 테스트 5: JSTK2 레지스터 값 확인 ────────────────────────
    // SPI 모델: X=512=0x200, Y=511=0x1FF, BTN=0x01
    axi_read(32'h401F_0000, rd_data);
    check_eq(rd_data[9:0], 10'd512, "JSTK2_X=512");
    axi_read(32'h401F_0004, rd_data);
    check_eq(rd_data[9:0], 10'd511, "JSTK2_Y=511");
    axi_read(32'h401F_0008, rd_data);
    check_eq(rd_data[1:0], 2'b01, "JSTK2_BTN=0x01");
    $display("T5 JSTK2 regs OK");

    // ── 테스트 6: 서보 A PWM 펄스 폭 측정 ───────────────────────
    // 현재 SERVO_A=1,500,000. 이를 2,000,000(2ms 최대)로 변경해 더 넓은 폭 측정
    axi_write(32'h401F_000C, 32'd1_200_000); // 1.2 ms
    // 서보 PWM은 20ms 주기. 한 주기 내 펄스 측정
    // 최대 대기: 3,000,000 클럭 (다음 주기)
    // pwm_a 상승에지 대기
    timeout = 3_000_000;
    while (pwm_a && timeout > 0) begin @(posedge clk); timeout = timeout - 1; end // 하강 대기
    while (!pwm_a && timeout > 0) begin @(posedge clk); timeout = timeout - 1; end // 상승 대기
    if (timeout <= 0) begin
        $display("FAIL: PWM_A no rising edge");
        fail_count = fail_count + 1;
    end else begin
        pwm_rise_time = $realtime;
        while (pwm_a && timeout > 0) begin @(posedge clk); timeout = timeout - 1; end
        pwm_fall_time = $realtime;
        pulse_width_clk = (pwm_fall_time - pwm_rise_time) / 10.0; // ns → 클럭
        $display("T6 PWM_A pulse_width=%.0f clk (exp=1200000, tol±5)", pulse_width_clk);
        if (pulse_width_clk < 1_199_995 || pulse_width_clk > 1_200_005) begin
            $display("FAIL: PWM_A pulse width out of tolerance");
            fail_count = fail_count + 1;
        end else begin
            $display("T6 PWM_A pulse width OK");
        end
    end

    // ── 최종 판정 ────────────────────────────────────────────────
    if (fail_count === 0)
        $display("PASS: all tests passed");
    else
        $display("FAIL: %0d test(s) failed", fail_count);

    $finish;
end

// 타임아웃 가드
initial begin
    #60_000_000; // 60 ms (시뮬레이션 단위 ns) = 6,000,000 클럭
    $display("FAIL: global simulation timeout");
    $finish;
end

endmodule
