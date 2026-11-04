// tb_axil_sla_wrap.v — 자체 점검형 테스트벤치
// I-067 소프트 논리 분석기 IP (mmio-sla-bram-capture, T2)
// Verilog-2001. iverilog 호환.
//
// 통과 → "PASS" 로 시작하는 줄, 실패 → "FAIL" 로 시작하는 줄 출력.
// 비교는 !== 로 X/Z도 실패로 센다.
//
// 테스트 케이스:
//   TC1: ARM + FORCE 트리거 → STATUS.FULL=1, STATUS.TRIG_FOUND=1, STATUS.ARMED=1
//   TC2: ARM + 실제 상승 에지 (ch0) → TRIG_FOUND=1, RD_DATA[trig_addr] bit0=1
//   TC3: CH_EN 마스킹 → ARM + FORCE → RD_DATA에 비활성 채널 비트 = 0
//
// DEPTH_LOG2=8 (256 샘플)으로 짧게 설정해 빠른 시뮬레이션.

`timescale 1ns/1ps
`default_nettype none

module tb_axil_sla_wrap;

    // ── 클럭 ──────────────────────────────────────────────
    reg aclk;
    initial aclk = 0;
    always #5 aclk = ~aclk;  // 100 MHz (10 ns 주기)

    // ── DUT 포트 ──────────────────────────────────────────
    reg        aresetn;
    reg  [7:0] s_awaddr;
    reg        s_awvalid;
    wire       s_awready;
    reg  [31:0] s_wdata;
    reg  [3:0]  s_wstrb;
    reg         s_wvalid;
    wire        s_wready;
    wire [1:0]  s_bresp;
    wire        s_bvalid;
    reg         s_bready;
    reg  [7:0]  s_araddr;
    reg         s_arvalid;
    wire        s_arready;
    wire [31:0] s_rdata;
    wire [1:0]  s_rresp;
    wire        s_rvalid;
    reg         s_rready;
    reg  [15:0] ch_in;

    // ── DUT 인스턴스 (DEPTH_LOG2=8, 256 샘플) ───────────
    axil_sla_wrap #(
        .DEPTH_LOG2(8)
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
        .ch_in     (ch_in)
    );

    // ── 실패 카운터 ───────────────────────────────────────
    integer fail_cnt;

    // ── AXI4-Lite 헬퍼 태스크 ────────────────────────────
    task axil_write;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(posedge aclk); #1;
            s_awaddr = addr; s_awvalid = 1;
            s_wdata  = data; s_wvalid  = 1; s_wstrb = 4'hF;
            s_bready = 1;
            wait(s_bvalid); @(posedge aclk); #1;
            s_awvalid = 0;
            s_wvalid  = 0;
            s_bready  = 0;
        end
    endtask

    task axil_read;
        input  [7:0]  addr;
        output [31:0] data;
        begin
            @(posedge aclk); #1;
            s_araddr = addr; s_arvalid = 1;
            wait(s_arready); @(posedge aclk); #1;
            s_arvalid = 0;
            s_rready  = 1;
            wait(s_rvalid);
            data = s_rdata;
            @(posedge aclk); #1;
            s_rready = 0;
        end
    endtask

    // ── 체크 헬퍼 ────────────────────────────────────────
    task check_eq;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got !== exp) begin
                $display("FAIL %0s: got=%0h exp=%0h", name, got, exp);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("pass %0s: %0h", name, got);
            end
        end
    endtask

    task check_ne;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  neq;
        begin
            if (got === neq) begin
                $display("FAIL %0s: got=%0h (expected !==%0h)", name, got, neq);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("pass %0s: %0h != %0h", name, got, neq);
            end
        end
    endtask

    // ── 메인 ─────────────────────────────────────────────
    reg [31:0] rd;
    reg [7:0]  trig_a;
    integer    i;

    initial begin
        // 초기화
        fail_cnt  = 0;
        aresetn   = 0;
        s_awvalid = 0; s_wvalid = 0; s_bready = 0;
        s_arvalid = 0; s_rready = 0;
        s_awaddr  = 0; s_wdata = 0; s_wstrb = 0;
        s_araddr  = 0;
        ch_in = 16'h0000;

        repeat(5) @(posedge aclk);
        aresetn = 1;
        repeat(2) @(posedge aclk);

        // 공통 설정: TRIG_CH=0, PRETRIG=10, CH_EN=0xFFFF, TRIG_POL=0(상승)
        axil_write(8'h08, 32'h0);        // TRIG_CH=0
        axil_write(8'h0C, 32'd10);       // PRETRIG=10
        axil_write(8'h10, 32'hFFFF);     // CH_EN=0xFFFF

        // ────────────────────────────────────────────────
        // TC1: ARM + FORCE 트리거
        //   PRETRIG=10 → 10클럭 대기 후 FORCE 발생
        //   256 - pretrig(10) + 트리거 위치 ≈ 256 샘플 채움
        //   STATUS: FULL=1, TRIG_FOUND=1, ARMED=1
        // ────────────────────────────────────────────────
        $display("=== TC1: ARM + FORCE 트리거 ===");
        axil_write(8'h00, 32'h1);  // ARM (bit0=1)
        // pre-trigger 채움 대기 (2단 FF + pre_cnt=10 + 여유)
        repeat(20) @(posedge aclk);
        // FORCE 트리거 (bit1=1)
        axil_write(8'h00, 32'h2);
        // 256 샘플 캡처 대기 (256 클럭 + 여유)
        repeat(300) @(posedge aclk);

        axil_read(8'h04, rd);
        check_eq("TC1:ARMED",      rd & 32'h1, 32'h1);
        check_eq("TC1:FULL",       (rd >> 2) & 32'h1, 32'h1);
        check_eq("TC1:TRIG_FOUND", (rd >> 3) & 32'h1, 32'h1);

        // ────────────────────────────────────────────────
        // TC2: ARM + 실제 상승 에지 (ch0=bit0)
        //   PRETRIG=0으로 설정 → 즉시 트리거 검출 가능
        //   ch_in[0] 를 0→1로 올리면 트리거 발생
        //   RD_DATA[trig_addr][0] = 1 이어야 함
        // ────────────────────────────────────────────────
        $display("=== TC2: ARM + 실제 상승 에지 ===");
        axil_write(8'h0C, 32'd0);   // PRETRIG=0
        ch_in = 16'h0000;

        axil_write(8'h00, 32'h1);   // ARM
        // 2단 FF 전파 + 여유
        repeat(5) @(posedge aclk);
        // ch0 상승 에지
        @(posedge aclk); #1;
        ch_in = 16'h0001;
        // 2단 FF 전파 대기
        repeat(5) @(posedge aclk);
        // 256 샘플 채움 대기
        repeat(280) @(posedge aclk);

        axil_read(8'h04, rd);
        check_eq("TC2:TRIG_FOUND", (rd >> 3) & 32'h1, 32'h1);
        check_eq("TC2:FULL",       (rd >> 2) & 32'h1, 32'h1);

        // trig_addr 읽기 (STATUS[19:8])
        trig_a = (rd >> 8) & 8'hFF;
        $display("pass TC2:TRIG_ADDR=%0d", trig_a);

        // trig_addr 위치의 샘플: ch0=1 이어야 함
        axil_write(8'h14, {24'd0, trig_a});  // RD_ADDR=trig_addr
        repeat(3) @(posedge aclk);           // BRAM 1사이클 레이턴시 + 여유
        axil_read(8'h18, rd);
        check_eq("TC2:RD_DATA_bit0_at_trig", rd & 32'h1, 32'h1);

        // ────────────────────────────────────────────────
        // TC3: CH_EN 마스킹
        //   CH_EN=0x00FE (bit0 비활성) → ARM + FORCE
        //   캡처 후 모든 샘플의 bit0 = 0 이어야 함 (ch_in[0]=1 유지)
        // ────────────────────────────────────────────────
        $display("=== TC3: CH_EN 마스킹 ===");
        axil_write(8'h10, 32'h00FE);  // CH_EN: bit0 비활성
        axil_write(8'h0C, 32'd5);     // PRETRIG=5
        ch_in = 16'h0001;              // bit0=1 (하지만 마스킹됨)

        axil_write(8'h00, 32'h1);     // ARM
        repeat(15) @(posedge aclk);
        axil_write(8'h00, 32'h2);     // FORCE
        repeat(300) @(posedge aclk);

        axil_read(8'h04, rd);
        check_eq("TC3:FULL", (rd >> 2) & 32'h1, 32'h1);

        // 주소 0의 샘플 읽기: bit0은 마스킹되어 0이어야 함
        axil_write(8'h14, 32'h0);     // RD_ADDR=0
        repeat(3) @(posedge aclk);
        axil_read(8'h18, rd);
        check_eq("TC3:RD_DATA_bit0_masked", rd & 32'h1, 32'h0);

        // ────────────────────────────────────────────────
        // 최종 판정
        // ────────────────────────────────────────────────
        if (fail_cnt === 0)
            $display("PASS all %0d checks", 7);
        else
            $display("FAIL %0d check(s) failed", fail_cnt);

        $finish;
    end

    // ── 타임아웃 ─────────────────────────────────────────
    initial begin
        #2000000;
        $display("FAIL timeout");
        $finish;
    end

endmodule

`default_nettype wire
