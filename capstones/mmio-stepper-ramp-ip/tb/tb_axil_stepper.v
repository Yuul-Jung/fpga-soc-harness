// tb_axil_stepper.v — axil_stepper 자체 점검 테스트벤치
// 출처: 하네스 직접 작성 Verilog-2001 원본
// 검증 항목:
//  1) AXI4-Lite 쓰기/읽기 기능
//  2) TARGET=8 스텝, 가감속 프로파일 완료
//  3) step_pulse 카운트 == TARGET
//  4) coil 패턴 변화 (전상 4단계 순환)
//  5) DONE 비트, IRQ_STATUS 발생 확인
//  6) IRQ_STATUS W1C 클리어, irq 소등 확인
//  7) ID/VER 레지스터 값 확인
// 판정: 모든 항목 통과 시 PASS, 하나라도 실패 시 FAIL
`default_nettype none
`timescale 1ns/1ps

module tb_axil_stepper;
    // ── 클럭/리셋 ────────────────────────────────────────────────
    reg clk, rst;
    localparam CLK_HALF = 5; // 10ns 주기 = 100MHz

    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    // ── DUT 포트 ────────────────────────────────────────────────
    reg  [15:0] s_awaddr;  reg  s_awvalid;  wire s_awready;
    reg  [31:0] s_wdata;   reg  s_wvalid;   wire s_wready;
    wire [1:0]  s_bresp;   wire s_bvalid;   reg  s_bready;
    reg  [15:0] s_araddr;  reg  s_arvalid;  wire s_arready;
    wire [31:0] s_rdata;   wire [1:0] s_rresp; wire s_rvalid; reg s_rready;
    wire [3:0]  coil;
    wire        step_out, dir_out, irq;

    axil_stepper dut (
        .clk(clk), .rst(rst),
        .s_awaddr(s_awaddr), .s_awvalid(s_awvalid), .s_awready(s_awready),
        .s_wdata(s_wdata),   .s_wvalid(s_wvalid),   .s_wready(s_wready),
        .s_bresp(s_bresp),   .s_bvalid(s_bvalid),   .s_bready(s_bready),
        .s_araddr(s_araddr), .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_rdata(s_rdata),   .s_rresp(s_rresp),     .s_rvalid(s_rvalid),
        .s_rready(s_rready),
        .coil(coil), .step_out(step_out), .dir_out(dir_out), .irq(irq)
    );

    // ── 계수기 ──────────────────────────────────────────────────
    integer step_count;    // step_pulse 계수
    integer coil_changes;  // coil 변화 횟수
    reg [3:0] prev_coil;
    integer fail_count;

    // step_pulse 감시
    always @(posedge clk) begin
        if (rst) begin
            step_count   <= 0;
            coil_changes <= 0;
            prev_coil    <= 4'b0001;
        end else begin
            if (step_out) step_count <= step_count + 1;
            if (coil !== prev_coil) begin
                coil_changes <= coil_changes + 1;
                prev_coil    <= coil;
            end
        end
    end

    // ── AXI4-Lite 태스크 ────────────────────────────────────────
    task axil_write;
        input [15:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            s_awaddr  = addr;   s_awvalid = 1'b1;
            s_wdata   = data;   s_wvalid  = 1'b1;
            s_bready  = 1'b1;
            // 주소 handshake
            @(posedge clk);
            while (!s_awready) @(posedge clk);
            @(negedge clk); s_awvalid = 1'b0;
            // 데이터 handshake (wready는 항상 1이므로 즉시)
            s_wvalid = 1'b0;
            // bresp 대기
            @(posedge clk);
            while (!s_bvalid) @(posedge clk);
            @(negedge clk); s_bready = 1'b0;
        end
    endtask

    task axil_read;
        input  [15:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            s_araddr  = addr;   s_arvalid = 1'b1;
            s_rready  = 1'b1;
            @(posedge clk);
            while (!s_arready) @(posedge clk);
            @(negedge clk); s_arvalid = 1'b0;
            @(posedge clk);
            while (!s_rvalid) @(posedge clk);
            data = s_rdata;
            @(negedge clk); s_rready = 1'b0;
        end
    endtask

    task check;
        input [255:0] name;
        input         cond;
        begin
            if (!cond) begin
                $display("FAIL: %0s", name);
                fail_count = fail_count + 1;
            end else begin
                $display("ok:   %0s", name);
            end
        end
    endtask

    // ── 메인 테스트 ──────────────────────────────────────────────
    reg [31:0] rval;
    integer    timeout;

    initial begin
        // 초기화
        rst = 1; fail_count = 0; step_count = 0; coil_changes = 0;
        s_awvalid = 0; s_wvalid = 0; s_bready = 1;
        s_arvalid = 0; s_rready = 1;
        s_awaddr = 0; s_wdata = 0; s_araddr = 0;
        repeat(4) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        // ── 테스트 1: ID/VER 확인 ──────────────────────────────
        axil_read(16'hFFF0, rval);
        check("ID == 0x53545050", rval === 32'h53545050);

        axil_read(16'hFFF4, rval);
        check("VER == 0x01000100", rval === 32'h01000100);

        // ── 테스트 2: 레지스터 쓰기/읽기 ──────────────────────
        // TARGET=8, MIN_PERIOD=2, MAX_PERIOD=10, DELTA=2, MODE=0(전상,4선)
        axil_write(16'h0004, 32'd8);       // TARGET_STEPS
        axil_write(16'h0008, 32'd2);       // MIN_PERIOD
        axil_write(16'h000C, 32'd10);      // MAX_PERIOD
        axil_write(16'h0010, 32'd2);       // DELTA_PERIOD
        axil_write(16'h0014, 32'd0);       // MODE = 전상·4선
        axil_write(16'hFFFC, 32'd1);       // IRQ_ENABLE[0] = 1

        axil_read(16'h0004, rval);
        check("TARGET_STEPS readback", rval === 32'd8);

        axil_read(16'hFFFC, rval);
        check("IRQ_ENABLE readback", rval === 32'd1);

        // ── 테스트 3: CTRL 초기값 (BUSY=0, DONE=0) ───────────
        axil_read(16'h0000, rval);
        check("CTRL BUSY=0 before start", rval[0] === 1'b0);

        // ── 테스트 4: 모터 가동 ────────────────────────────────
        axil_write(16'h0000, 32'h1); // CTRL START

        // DONE 대기 (최대 500 클럭)
        timeout = 0;
        rval = 32'b0;
        while (rval[1] !== 1'b1 && timeout < 500) begin
            @(posedge clk);
            axil_read(16'h0000, rval);
            timeout = timeout + 1;
        end
        check("DONE bit set within 500 clk", rval[1] === 1'b1);
        check("BUSY=0 after done", rval[0] === 1'b0);

        // ── 테스트 5: step_pulse 카운트 == TARGET ─────────────
        // step_out 과 step_pulse가 같으므로 step_count 사용
        check("step_count == 8", step_count === 8);

        // ── 테스트 6: coil 패턴 변화 (전상: 8번 변화) ──────────
        // coil_changes: 초기값 포함 최대 9번(reset→첫패턴 1 + 8스텝)
        // step_pulse마다 coil 변화하므로 step_count와 동일하거나 +1
        check("coil_changes >= 8", coil_changes >= 8);

        // ── 테스트 7: IRQ_STATUS[0] 발생 ──────────────────────
        axil_read(16'hFFF8, rval);
        check("IRQ_STATUS[0]=1 after done", rval[0] === 1'b1);
        check("irq output asserted", irq === 1'b1);

        // ── 테스트 8: W1C 클리어 ──────────────────────────────
        axil_write(16'hFFF8, 32'h1); // W1C
        @(posedge clk); @(posedge clk);

        axil_read(16'hFFF8, rval);
        check("IRQ_STATUS cleared by W1C", rval[0] === 1'b0);
        check("irq deasserted after clear", irq === 1'b0);

        // ── 판정 ──────────────────────────────────────────────
        $display("---");
        if (fail_count === 0) begin
            $display("PASS: 모든 항목 통과 (%0d checks)", 10);
        end else begin
            $display("FAIL: %0d 항목 실패", fail_count);
        end

        #100;
        $finish;
    end

    // ── 타임아웃 가드 ────────────────────────────────────────────
    initial begin
        #100000;
        $display("FAIL: 시뮬레이션 타임아웃 (100000 ns)");
        $finish;
    end

endmodule
`default_nettype wire
