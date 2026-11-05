// tb_onewire_bm.v — axil_onewire_bm 자체 점검 테스트벤치
// DS18B20 행동 모델 포함 (presence pulse + 비트 에코)
// 통과: "PASS: ..." 로 시작하는 줄 출력
// 실패: "FAIL: ..." 로 시작하는 줄 출력 후 $finish
//
// 검증 항목:
//   T1: RST 연산 — DQ Low 480µs → release → presence pulse 출력 → PRESENCE=1
//   T2: WR_BIT=0 연산 — DQ Low 71µs → release → STATUS.BUSY→0
//   T3: WR_BIT=1 연산 — DQ Low 6µs → high 64µs → STATUS.BUSY→0
//   T4: RD_BIT 연산 — master Low 6µs → DS18B20가 '1' 에코 → RBIT=1
//   T5: RD_BIT 연산 — master Low 6µs → DS18B20가 '0' 에코 → RBIT=0
//   T6: IRQ_EN=1 → IRQ가 연산 완료 후 1클럭 뒤 1이 됨, ICLR 후 0이 됨

`default_nettype none
`timescale 1ns/1ps

module tb_onewire_bm;

// ------------------------------------------------------------
// 타이밍 (100 MHz = 10 ns 주기)
// ------------------------------------------------------------
localparam CLK_PERIOD = 10;        // 10 ns = 100 MHz
localparam CLK_MHZ    = 100;

// 1-Wire 시간 허용 오차 (클럭 사이클 ±2)
localparam TOL        = 2 * CLK_PERIOD; // 20 ns

// DS18B20 presence pulse 타이밍 (데이터시트)
localparam DS_PRESENCE_DLY =  15000; // 15 µs 후 presence 시작
localparam DS_PRESENCE_LEN =  60000; // 60 µs 동안 Low

// 에코 비트=0 → 마스터 low 직후부터 슬레이브가 60µs 동안 Low 유지
// 에코 비트=1 → 슬레이브 개입 없음 (풀업으로 High)
localparam DS_BIT0_LEN     =  60000; // 60 µs

// ------------------------------------------------------------
// 클럭 / 리셋
// ------------------------------------------------------------
reg clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

reg rst_n = 0;
initial begin
    #(CLK_PERIOD * 5);
    rst_n = 1;
end

// ------------------------------------------------------------
// 1-Wire 버스 (오픈드레인 시뮬레이션)
// master: ow_drive=1 → DQ=0
// slave:  ds_drive=1 → DQ=0
// 풀업 : 둘 다 0이면 DQ=1
// ------------------------------------------------------------
wire   ow_drive;    // 마스터 출력
reg    ds_drive;    // DS18B20 모델 출력 (open-drain)
wire   ow_sense;    // DQ 현재 값 (버스)

// 오픈드레인 AND: 어느 쪽이든 1이면 bus=Low
assign ow_sense = (ow_drive | ds_drive) ? 1'b0 : 1'b1;

// ------------------------------------------------------------
// AXI4-Lite 마스터 신호
// ------------------------------------------------------------
reg  [31:0] s_awaddr  = 0;
reg         s_awvalid = 0;
wire        s_awready;
reg  [31:0] s_wdata   = 0;
reg  [3:0]  s_wstrb   = 4'hF;
reg         s_wvalid  = 0;
wire        s_wready;
wire [1:0]  s_bresp;
wire        s_bvalid;
reg         s_bready  = 0;

reg  [31:0] s_araddr  = 0;
reg         s_arvalid = 0;
wire        s_arready;
wire [31:0] s_rdata;
wire [1:0]  s_rresp;
wire        s_rvalid;
reg         s_rready  = 0;

wire        irq;

// ------------------------------------------------------------
// DUT
// ------------------------------------------------------------
axil_onewire_bm #(
    .CLK_MHZ(CLK_MHZ)
) dut (
    .clk            (clk),
    .rst_n          (rst_n),

    .s_axil_awaddr  (s_awaddr),
    .s_axil_awvalid (s_awvalid),
    .s_axil_awready (s_awready),
    .s_axil_wdata   (s_wdata),
    .s_axil_wstrb   (s_wstrb),
    .s_axil_wvalid  (s_wvalid),
    .s_axil_wready  (s_wready),
    .s_axil_bresp   (s_bresp),
    .s_axil_bvalid  (s_bvalid),
    .s_axil_bready  (s_bready),

    .s_axil_araddr  (s_araddr),
    .s_axil_arvalid (s_arvalid),
    .s_axil_arready (s_arready),
    .s_axil_rdata   (s_rdata),
    .s_axil_rresp   (s_rresp),
    .s_axil_rvalid  (s_rvalid),
    .s_axil_rready  (s_rready),

    .ow_drive       (ow_drive),
    .ow_sense       (ow_sense),
    .irq            (irq)
);

// ------------------------------------------------------------
// AXI4-Lite 쓰기 태스크
// ------------------------------------------------------------
task axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        // awready가 1(=aw_done=0)인 것을 확인한 뒤 주소/데이터 제시
        @(posedge clk); #1;
        while (!s_awready) begin @(posedge clk); #1; end
        s_awaddr  = addr; s_awvalid = 1;
        s_wdata   = data; s_wstrb   = 4'hF; s_wvalid = 1;
        s_bready  = 1;
        @(posedge clk); #1;  // DUT가 AW+W 캡처 (aw_done/w_done ← 1)
        s_awvalid = 0; s_wvalid = 0;
        // bvalid가 올 때까지 대기 (do_write → bvalid_r ← 1)
        while (!s_bvalid) begin @(posedge clk); #1; end
        @(posedge clk); #1;  // B 핸드셰이크 완료 (bvalid=1,bready=1 → 클리어)
        s_bready  = 0;
    end
endtask

// AXI4-Lite 읽기 태스크
task axi_read;
    input  [31:0] addr;
    output [31:0] data;
    begin
        // arready가 1(=ar_active=0)인 것을 확인한 뒤 주소 제시
        @(posedge clk); #1;
        while (!s_arready) begin @(posedge clk); #1; end
        s_araddr  = addr; s_arvalid = 1; s_rready = 1;
        @(posedge clk); #1;  // DUT가 AR 캡처 (ar_active←1)
        s_arvalid = 0;
        // rvalid(=ar_active)가 올 때까지 대기
        while (!s_rvalid) begin @(posedge clk); #1; end
        data = s_rdata;
        @(posedge clk); #1;  // R 핸드셰이크 완료 (ar_active←0)
        s_rready  = 0;
    end
endtask

// BUSY 폴링: STATUS[0]=0 될 때까지 대기
task wait_not_busy;
    reg [31:0] status;
    integer timeout;
    begin
        timeout = 0;
        axi_read(32'h04, status);
        while (status[0] && timeout < 2000000) begin
            @(posedge clk);
            axi_read(32'h04, status);
            timeout = timeout + 1;
        end
        if (timeout >= 2000000) begin
            $display("FAIL: BUSY timeout after 2M cycles");
            $finish;
        end
    end
endtask

// OP 설정 + START
task start_op;
    input [1:0] op;    // 00=NOP 01=RST 10=WR 11=RD
    input       wbit;  // WR_BIT 값 (OP=WR일 때만 유효)
    input       irqen; // IRQ_EN 비트
    reg [31:0]  ctrl_val;
    begin
        ctrl_val = {15'd0, irqen, 13'd0, wbit, op};
        axi_write(32'h00, ctrl_val); // CTRL 설정
        axi_write(32'h08, 32'd1);    // START = 1
    end
endtask

// ------------------------------------------------------------
// DS18B20 행동 모델
// ------------------------------------------------------------
// 역할:
//   - RST(DQ Low 480µs) 감지 → 15µs 후 60µs presence pulse 출력
//   - RD_BIT 슬롯 (DQ Low 6µs 후 release) 감지 → 에코 비트 출력
//   단순화: presence 감지는 ow_drive 하강·상승 에지로 판단
//          에코 비트는 ds_expected_bit 레지스터로 외부에서 설정
// ------------------------------------------------------------
reg ds_expected_bit = 1'b1; // 테스트가 에코 비트 설정

// presence 모델
// ow_drive: 1→DQ Low, 0→DQ released
// 480µs Low → release 감지하면 15µs 후 presence 60µs
integer ow_low_start_ns;
integer ow_low_duration_ns;

initial begin
    ds_drive = 0;
    ow_low_start_ns = 0;
    ow_low_duration_ns = 0;
end

// 모델은 RTL이 DQ를 낮출 때 (`ow_drive` 상승) 타이머 시작,
// 풀어줄 때 (`ow_drive` 하강) 기간 측정 → RST면 presence pulse
always @(negedge ow_drive) begin : ds_presence_model
    integer low_dur;
    low_dur = $time - ow_low_start_ns;
    // 480µs ± 10µs 이면 RST 슬롯으로 간주
    if (low_dur >= 400000 && low_dur <= 1000000) begin
        // presence pulse: 15µs 후 60µs Low
        #(DS_PRESENCE_DLY);
        ds_drive = 1;
        #(DS_PRESENCE_LEN);
        ds_drive = 0;
    end
end

always @(posedge ow_drive) begin : ds_timer_start
    ow_low_start_ns = $time;
end

// 에코 비트=0 모델: RD 슬롯(6µs Low) 감지 → 60µs Low
// ow_drive 하강 후 슬롯이 6µs ± 2µs이면 RD 슬롯으로 간주
always @(negedge ow_drive) begin : ds_echo_model
    integer low_dur2;
    low_dur2 = $time - ow_low_start_ns;
    if (low_dur2 >= 4000 && low_dur2 <= 10000) begin
        // RD 슬롯: ds_expected_bit=0이면 Low 에코
        if (!ds_expected_bit) begin
            ds_drive = 1;
            #(DS_BIT0_LEN);
            ds_drive = 0;
        end
        // ds_expected_bit=1이면 개입 없음 (풀업이 1로 유지)
    end
end

// ------------------------------------------------------------
// 메인 테스트
// ------------------------------------------------------------
reg [31:0] status_val;
integer fail_count;

initial begin
    fail_count = 0;
    ds_drive   = 0;
    @(posedge rst_n);
    @(posedge clk); #1;

    $display("=== T1: RST 연산 — PRESENCE 감지 ===");
    // OP=RST, IRQ_EN=1
    start_op(2'b01, 1'b0, 1'b1);
    // 약 960µs 대기 (480+70+410 µs = 960µs = 96000 클럭)
    wait_not_busy();
    axi_read(32'h04, status_val);
    if (status_val[1] !== 1'b1) begin
        $display("FAIL: T1 PRESENCE=0, STATUS=%h", status_val);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T1 PRESENCE=1, STATUS=%h", status_val);
    end

    // IRQ 확인
    if (irq !== 1'b1) begin
        $display("FAIL: T1 IRQ가 1이어야 함. irq=%b", irq);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T1 IRQ=1 확인");
    end
    // ICLR
    axi_write(32'h0C, 32'd1);
    @(posedge clk); #1;
    if (irq !== 1'b0) begin
        $display("FAIL: T1 ICLR 후 IRQ=1 (기대=0). irq=%b", irq);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T1 ICLR 후 IRQ=0");
    end

    // 짧은 갭
    repeat(100) @(posedge clk);

    $display("=== T2: WR_BIT=0 연산 ===");
    start_op(2'b10, 1'b0, 1'b0); // WR_BIT=0
    wait_not_busy();
    axi_read(32'h04, status_val);
    if (status_val[0] !== 1'b0) begin
        $display("FAIL: T2 BUSY 해제 안 됨, STATUS=%h", status_val);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T2 WR_BIT=0 완료, STATUS=%h", status_val);
    end

    repeat(100) @(posedge clk);

    $display("=== T3: WR_BIT=1 연산 ===");
    start_op(2'b10, 1'b1, 1'b0); // WR_BIT=1
    wait_not_busy();
    axi_read(32'h04, status_val);
    if (status_val[0] !== 1'b0) begin
        $display("FAIL: T3 BUSY 해제 안 됨, STATUS=%h", status_val);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T3 WR_BIT=1 완료, STATUS=%h", status_val);
    end

    repeat(100) @(posedge clk);

    $display("=== T4: RD_BIT — DS18B20가 '1' 에코 ===");
    ds_expected_bit = 1'b1; // 슬레이브가 Low를 당기지 않음 → RBIT=1
    start_op(2'b11, 1'b0, 1'b0);
    wait_not_busy();
    axi_read(32'h04, status_val);
    if (status_val[2] !== 1'b1) begin
        $display("FAIL: T4 RBIT=0 (기대=1), STATUS=%h", status_val);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T4 RBIT=1, STATUS=%h", status_val);
    end

    repeat(100) @(posedge clk);

    $display("=== T5: RD_BIT — DS18B20가 '0' 에코 ===");
    ds_expected_bit = 1'b0; // 슬레이브가 Low 에코 → RBIT=0
    start_op(2'b11, 1'b0, 1'b0);
    wait_not_busy();
    axi_read(32'h04, status_val);
    if (status_val[2] !== 1'b0) begin
        $display("FAIL: T5 RBIT=1 (기대=0), STATUS=%h", status_val);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T5 RBIT=0, STATUS=%h", status_val);
    end
    ds_expected_bit = 1'b1; // 복원

    repeat(100) @(posedge clk);

    $display("=== T6: IRQ_EN=1 / ICLR 연산 순환 ===");
    start_op(2'b10, 1'b1, 1'b1); // WR_BIT=1, IRQ_EN=1
    wait_not_busy();
    // IRQ는 완료 다음 사이클에 1이 됨
    @(posedge clk); #1;
    if (irq !== 1'b1) begin
        $display("FAIL: T6 IRQ가 1이어야 함. irq=%b", irq);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T6 IRQ=1 확인");
    end
    axi_write(32'h0C, 32'd1); // ICLR
    @(posedge clk); #1;
    if (irq !== 1'b0) begin
        $display("FAIL: T6 ICLR 후 IRQ=1 (기대=0)");
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: T6 ICLR 후 IRQ=0");
    end

    // ── 최종 판정 ──────────────────────────────
    $display("=========================================");
    if (fail_count === 0) begin
        $display("PASS: 전체 %0d개 항목 모두 통과", 9);
    end else begin
        $display("FAIL: %0d개 항목 실패", fail_count);
    end
    $display("=========================================");
    $finish;
end

// 무한 루프 안전장치 (10 ms)
initial begin
    #10_000_000_000; // 10초 (ns 단위)
    $display("FAIL: 시뮬레이션 시간 초과 (10s)");
    $finish;
end

endmodule
`default_nettype wire
