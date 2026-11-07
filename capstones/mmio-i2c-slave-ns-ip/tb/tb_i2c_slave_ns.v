// tb_i2c_slave_ns.v — 자체 점검형 테스트벤치 (I2C 슬레이브 무클럭스트레칭)
// PASS 또는 FAIL로 시작하는 행을 출력. 비교는 !==으로 X/Z도 실패.
// 테스트:
//   T1: I2C WRITE (슬레이브 0x20, REG 0x00 ← 0xAB)
//   T2: AXI READ  (오프셋 0x00에서 0xAB 읽기)
//   T3: AXI WRITE (오프셋 0x04 ← 0xCD) 후 I2C READ (REG 0x01)
//   T4: STATUS 레지스터 (AXI 오프셋 0x20)에서 start_det 확인
//   T5: I2C_ADDR 레지스터 (AXI 오프셋 0x24) 기본값 0x20 확인
// Verilog-2001 / iverilog -g2001
// SPDX-License-Identifier: MIT

`timescale 1ns/1ps

module tb_i2c_slave_ns;

// ─── DUT 포트 ───
reg         clk, rst_n;
// AXI
reg  [7:0]  awaddr;  reg        awvalid;  wire awready;
reg  [31:0] wdata;   reg  [3:0] wstrb;    reg  wvalid; wire wready;
wire [1:0]  bresp;   wire       bvalid;   reg  bready;
reg  [7:0]  araddr;  reg        arvalid;  wire arready;
wire [31:0] rdata;   wire [1:0] rresp;    wire rvalid; reg  rready;
// I2C
reg         scl_drv;  // 마스터가 SCL을 구동 (open-drain 모델)
wire        scl_net;
reg         sda_drv;  // 마스터 SDA 드라이브 (1=pull-down, 0=Hi-Z)
wire        sda_net;

// ─── Open-drain 버스 모델 ───
// sda_drv=1 → SDA를 0으로 풀다운; DUT sda_oe=1도 같은 효과
assign scl_net = scl_drv ? 1'b0 : 1'b1;   // SCL 마스터 전용(슬레이브 스트레칭 없음)
assign sda_net = sda_drv ? 1'b0 : 1'bz;   // SDA 오픈 드레인 (DUT 내부에 inout)

// ─── DUT 인스턴스 ───
axil_i2c_slave_ns #(.DEFAULT_ADDR(7'h20)) dut (
    .S_AXI_ACLK    (clk),
    .S_AXI_ARESETN (rst_n),
    .S_AXI_AWADDR  (awaddr),
    .S_AXI_AWVALID (awvalid),
    .S_AXI_AWREADY (awready),
    .S_AXI_WDATA   (wdata),
    .S_AXI_WSTRB   (wstrb),
    .S_AXI_WVALID  (wvalid),
    .S_AXI_WREADY  (wready),
    .S_AXI_BRESP   (bresp),
    .S_AXI_BVALID  (bvalid),
    .S_AXI_BREADY  (bready),
    .S_AXI_ARADDR  (araddr),
    .S_AXI_ARVALID (arvalid),
    .S_AXI_ARREADY (arready),
    .S_AXI_RDATA   (rdata),
    .S_AXI_RRESP   (rresp),
    .S_AXI_RVALID  (rvalid),
    .S_AXI_RREADY  (rready),
    .SCL           (scl_net),
    .SDA           (sda_net)
);

// ─── 클럭 (100 MHz) ───
initial clk = 0;
always #5 clk = ~clk;  // 10 ns 주기

// ─── I2C 타이밍 (100 kHz = 10 µs 주기, 단위: ns) ───
// 시뮬레이션에서는 타이밍을 단축(50 클럭 = 500 ns)
localparam I2C_HALF = 500;   // SCL half-period in ns

// ─── 태스크: AXI4-Lite 쓰기 ───
task axi_write;
    input [7:0]  addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        awaddr = addr; awvalid = 1;
        wdata  = data; wstrb = 4'hF; wvalid = 1;
        // AW 채널 대기
        @(posedge clk);
        while (!awready) @(posedge clk);
        awvalid = 0;
        while (!wready)  @(posedge clk);
        wvalid = 0;
        // B 채널
        bready = 1;
        @(posedge clk);
        while (!bvalid)  @(posedge clk);
        bready = 0;
        @(posedge clk); #1;
    end
endtask

// ─── 태스크: AXI4-Lite 읽기 ───
reg [31:0] axi_rdata_buf;
task axi_read;
    input [7:0] addr;
    begin
        @(posedge clk); #1;
        araddr = addr; arvalid = 1;
        @(posedge clk);
        while (!arready) @(posedge clk);
        arvalid = 0;
        rready = 1;
        @(posedge clk);
        while (!rvalid) @(posedge clk);
        axi_rdata_buf = rdata;
        rready = 0;
        @(posedge clk); #1;
    end
endtask

// ─── 태스크: I2C SCL 한 비트 클럭 ───
task i2c_bit_clock;
    begin
        #(I2C_HALF); scl_drv = 1'b0;  // SCL HIGH (open-drain 해제)
        // 실제는 wire가 1이 되지만 scl_net = scl_drv ? 0 : 1 이므로 반전
        // scl_drv=0 → scl_net=1
        #(I2C_HALF); scl_drv = 1'b1;  // SCL LOW
    end
endtask

// ─── 태스크: I2C 바이트 송신 (마스터→슬레이브) ───
// scl_drv=1=LOW, scl_drv=0=HIGH
reg ack_bit;
task i2c_send_byte;
    input [7:0] byte_val;
    integer b;
    begin
        for (b = 7; b >= 0; b = b - 1) begin
            // SCL LOW 구간에 SDA 세팅
            sda_drv = ~byte_val[b];  // 1→LOW(pull-down), 0→Hi-Z(1)
            #(I2C_HALF/2);
            scl_drv = 1'b0;          // SCL HIGH (scl_drv=0 → scl_net=1)
            #(I2C_HALF);
            scl_drv = 1'b1;          // SCL LOW
            #(I2C_HALF/2);
        end
        // ACK 수신: SDA 릴리즈
        sda_drv = 1'b0;
        #(I2C_HALF/2);
        scl_drv = 1'b0;              // SCL HIGH
        #(I2C_HALF/4);
        ack_bit = sda_net;           // 슬레이브 ACK 샘플
        #(I2C_HALF*3/4);
        scl_drv = 1'b1;              // SCL LOW
        #(I2C_HALF/2);
    end
endtask

// ─── 태스크: I2C 바이트 수신 (슬레이브→마스터) ───
reg [7:0] i2c_recv_buf;
task i2c_recv_byte;
    input send_nack;    // 1=NACK(마지막 바이트), 0=ACK(계속)
    integer b;
    begin
        sda_drv = 1'b0;              // SDA 릴리즈 (슬레이브가 구동)
        for (b = 7; b >= 0; b = b - 1) begin
            #(I2C_HALF/2);
            scl_drv = 1'b0;          // SCL HIGH
            #(I2C_HALF/4);
            i2c_recv_buf[b] = sda_net; // 샘플
            #(I2C_HALF*3/4);
            scl_drv = 1'b1;          // SCL LOW
            #(I2C_HALF/2);
        end
        // 마스터 ACK/NACK 출력
        sda_drv = send_nack;         // NACK=1(Hi-Z=1 on bus) if pullup, ACK=1→LOW
        // 여기서는 단순화: send_nack=1이면 풀업(NACK), 0이면 풀다운(ACK)
        // sda_net의 open-drain 모델에 맞게: sda_drv=1 → SDA LOW (ACK)
        //                                    sda_drv=0 → SDA Hi-Z (NACK, 풀업 필요)
        // 풀업이 없으므로 간단히 처리: send_nack=0이면 ACK(sda_drv=1)
        sda_drv = send_nack ? 1'b0 : 1'b1;
        #(I2C_HALF/2);
        scl_drv = 1'b0;              // SCL HIGH
        #(I2C_HALF);
        scl_drv = 1'b1;              // SCL LOW
        sda_drv = 1'b0;
        #(I2C_HALF/2);
    end
endtask

// ─── 태스크: I2C START 조건 ───
task i2c_start;
    begin
        // SCL HIGH, SDA HIGH → SDA LOW (START)
        scl_drv = 1'b0; sda_drv = 1'b0;  // 버스 릴리즈
        #(I2C_HALF/2);
        sda_drv = 1'b1;   // SDA LOW (pull-down)
        #(I2C_HALF/2);
        scl_drv = 1'b1;   // SCL LOW
        #(I2C_HALF/2);
    end
endtask

// ─── 태스크: I2C STOP 조건 ───
task i2c_stop;
    begin
        // SCL LOW, SDA LOW → SCL HIGH → SDA HIGH
        scl_drv = 1'b1; sda_drv = 1'b1;  // 모두 LOW
        #(I2C_HALF/2);
        scl_drv = 1'b0;   // SCL HIGH
        #(I2C_HALF/2);
        sda_drv = 1'b0;   // SDA HIGH (Hi-Z → 풀업으로 HIGH)
        #(I2C_HALF);
    end
endtask

// ─── 테스트 변수 ───
integer fail_count;
integer test_id;

// ─── 메인 ───
initial begin
    // 초기화
    clk = 0; rst_n = 0;
    awaddr = 0; awvalid = 0;
    wdata  = 0; wstrb = 0; wvalid = 0;
    bready = 0;
    araddr = 0; arvalid = 0;
    rready = 0;
    scl_drv = 1'b1; sda_drv = 1'b0;  // SCL LOW, SDA Hi-Z
    fail_count = 0;
    ack_bit    = 1;

    // 리셋 해제
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);

    // ───────────────────────────────────────────────────
    // T1: I2C WRITE — 슬레이브 0x20, 레지스터 0x00 ← 0xAB
    // ───────────────────────────────────────────────────
    test_id = 1;
    i2c_start;
    i2c_send_byte(8'h40);  // 주소 0x20 + W(0) = 0x40
    if (ack_bit !== 1'b0) begin
        $display("FAIL: T1 주소 ACK 없음 (ack_bit=%0b)", ack_bit);
        fail_count = fail_count + 1;
    end
    i2c_send_byte(8'h00);  // 레지스터 주소 0x00
    if (ack_bit !== 1'b0) begin
        $display("FAIL: T1 레지스터 주소 ACK 없음");
        fail_count = fail_count + 1;
    end
    i2c_send_byte(8'hAB);  // 데이터 0xAB
    i2c_stop;
    repeat(20) @(posedge clk);

    // ───────────────────────────────────────────────────
    // T2: AXI READ — 오프셋 0x00에서 0xAB 확인
    // ───────────────────────────────────────────────────
    test_id = 2;
    axi_read(8'h00);
    if (axi_rdata_buf[7:0] !== 8'hAB) begin
        $display("FAIL: T2 AXI 읽기 기대 0xAB, 실제 0x%02X", axi_rdata_buf[7:0]);
        fail_count = fail_count + 1;
    end

    // ───────────────────────────────────────────────────
    // T3: AXI WRITE (REG1=0xCD) 후 I2C READ
    // ───────────────────────────────────────────────────
    test_id = 3;
    axi_write(8'h04, 32'h000000CD);  // REG1 ← 0xCD
    repeat(5) @(posedge clk);

    // I2C: START + ADDR(W) + REG_ADDR(0x01) + RESTART + ADDR(R) + 1바이트 READ + STOP
    i2c_start;
    i2c_send_byte(8'h40);  // 0x20 + W
    i2c_send_byte(8'h01);  // 레지스터 주소 0x01
    // Repeated START
    scl_drv = 1'b0; sda_drv = 1'b0;  // SCL HIGH
    #(I2C_HALF/2);
    sda_drv = 1'b1;   // SDA LOW (Repeated START)
    #(I2C_HALF/2);
    scl_drv = 1'b1;   // SCL LOW
    #(I2C_HALF/2);
    i2c_send_byte(8'h41);  // 0x20 + R(1) = 0x41
    if (ack_bit !== 1'b0) begin
        $display("FAIL: T3 읽기 주소 ACK 없음");
        fail_count = fail_count + 1;
    end
    i2c_recv_byte(1);  // 1바이트 수신 후 NACK
    if (i2c_recv_buf !== 8'hCD) begin
        $display("FAIL: T3 I2C 읽기 기대 0xCD, 실제 0x%02X", i2c_recv_buf);
        fail_count = fail_count + 1;
    end
    i2c_stop;
    repeat(20) @(posedge clk);

    // ───────────────────────────────────────────────────
    // T4: STATUS 레지스터에서 start_det 확인
    // ───────────────────────────────────────────────────
    test_id = 4;
    axi_read(8'h20);
    if (axi_rdata_buf[2] !== 1'b1) begin
        $display("FAIL: T4 start_det 비트 기대 1, 실제 %0b", axi_rdata_buf[2]);
        fail_count = fail_count + 1;
    end

    // ───────────────────────────────────────────────────
    // T5: I2C_ADDR 레지스터 기본값 0x20 확인
    // ───────────────────────────────────────────────────
    test_id = 5;
    axi_read(8'h24);
    if (axi_rdata_buf[6:0] !== 7'h20) begin
        $display("FAIL: T5 I2C_ADDR 기대 0x20, 실제 0x%02X", axi_rdata_buf[6:0]);
        fail_count = fail_count + 1;
    end

    // ───────────────────────────────────────────────────
    // 결과 출력
    // ───────────────────────────────────────────────────
    repeat(10) @(posedge clk);
    if (fail_count === 0)
        $display("PASS: all tests passed (T1~T5)");
    else
        $display("FAIL: %0d test(s) failed", fail_count);

    $finish;
end

// 타임아웃
initial begin
    #5_000_000;
    $display("FAIL: timeout");
    $finish;
end

endmodule
