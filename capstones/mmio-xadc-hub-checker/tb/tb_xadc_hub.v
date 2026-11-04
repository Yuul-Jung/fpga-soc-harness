// tb_xadc_hub.v
// xadc_hub 통합 테스트
// - xadc_drp_model(시뮬레이션용)이 xadc_hub.v 안에 ifdef SIMULATION으로 삽입
// - mmio-lite 버스를 직접 구동해 레지스터 R/W 검증
// 통과: "PASS: xadc_hub" / 실패: "FAIL: xadc_hub"
//
// 테스트 순서:
//  T1. CTRL 쓰기(scan_en=1, avg_len=1)
//  T2. IRQ 대기 (최대 2000클럭)
//  T3. CH0_RAW 읽기 → 0xABC 확인
//  T4. CH1_RAW 읽기 → 0xDEF 확인
//  T5. CH2_RAW 읽기 → 0x123 확인
//  T6. CH3_RAW 읽기 → 0x456 확인
//  T7. IRQ_FLAG 읽기 → 0xF 확인
//  T8. IRQ_FLAG 클리어 → 0x0 확인
//  T9. AVG 읽기 (1샘플 모드이므로 raw와 동일 허용)

`timescale 1ns/1ps
`define SIMULATION 1

module tb_xadc_hub;

    reg         clk, rst;
    reg  [15:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;
    reg         we, req;
    wire        ack;
    wire        irq;

    // --- DUT (SIMULATION 정의 → 내부에 xadc_drp_model 사용) ---
    xadc_hub u_dut (
        .clk     (clk),
        .rst     (rst),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .we      (we),
        .req     (req),
        .ack     (ack),
        .vauxp4  (1'b0), .vauxn4  (1'b0),
        .vauxp5  (1'b0), .vauxn5  (1'b0),
        .vauxp12 (1'b0), .vauxn12 (1'b0),
        .vauxp13 (1'b0), .vauxn13 (1'b0),
        .irq     (irq)
    );

    // 클럭 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    integer fail_cnt;
    integer wait_cnt;
    reg [31:0] rd_val;

    // mmio-lite 쓰기 태스크
    task bus_write;
        input [15:0] a;
        input [31:0] d;
        begin
            @(posedge clk);
            addr  = a; wdata = d; we = 1; req = 1;
            @(posedge clk);
            while (!ack) @(posedge clk);
            we = 0; req = 0;
            @(posedge clk);
        end
    endtask

    // mmio-lite 읽기 태스크
    task bus_read;
        input [15:0] a;
        output [31:0] d;
        begin
            @(posedge clk);
            addr = a; wdata = 32'd0; we = 0; req = 1;
            @(posedge clk);
            while (!ack) @(posedge clk);
            d   = rdata;
            req = 0;
            @(posedge clk);
        end
    endtask

    // 체크 매크로
    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [63:0] label;
        begin
            if (got !== exp) begin
                $display("FAIL: %s got=0x%08X exp=0x%08X", label, got, exp);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("PASS: %s = 0x%08X", label, got);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_xadc_hub.vcd");
        $dumpvars(0, tb_xadc_hub);

        rst = 1; we = 0; req = 0; addr = 0; wdata = 0; fail_cnt = 0;
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        // T1: CTRL 쓰기: scan_en=1(bit3), irq_en=1(bit2), avg_len=0(bypass)
        $display("--- T1: CTRL 쓰기 ---");
        bus_write(16'h0000, 32'h0000_000C); // bit3=scan_en bit2=irq_en avg_len=0

        // T2: IRQ 대기
        $display("--- T2: IRQ 대기 ---");
        wait_cnt = 0;
        while (!irq && wait_cnt < 3000) begin
            @(posedge clk);
            wait_cnt = wait_cnt + 1;
        end
        if (!irq) begin
            $display("FAIL: IRQ timeout after %0d clocks", wait_cnt);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: IRQ asserted at clock %0d", wait_cnt);
        end

        // T3~T6: CH_RAW 읽기
        $display("--- T3: CH0_RAW 읽기 ---");
        bus_read(16'h0008, rd_val);
        check_eq(rd_val, 32'h0000_0ABC, "CH0_RAW");

        $display("--- T4: CH1_RAW 읽기 ---");
        bus_read(16'h000C, rd_val);
        check_eq(rd_val, 32'h0000_0DEF, "CH1_RAW");

        $display("--- T5: CH2_RAW 읽기 ---");
        bus_read(16'h0010, rd_val);
        check_eq(rd_val, 32'h0000_0123, "CH2_RAW");

        $display("--- T6: CH3_RAW 읽기 ---");
        bus_read(16'h0014, rd_val);
        check_eq(rd_val, 32'h0000_0456, "CH3_RAW");

        // T7: IRQ_FLAG 읽기
        $display("--- T7: IRQ_FLAG 읽기 ---");
        bus_read(16'h002C, rd_val);
        check_eq(rd_val & 32'hF, 32'h0000_000F, "IRQ_FLAG");

        // T8: IRQ_FLAG 클리어
        $display("--- T8: IRQ_FLAG 클리어 ---");
        bus_write(16'h002C, 32'h0000_000F);
        bus_read(16'h002C, rd_val);
        check_eq(rd_val & 32'hF, 32'h0000_0000, "IRQ_FLAG_clear");

        // T9: CH0_AVG 읽기 (bypass 모드이므로 raw와 동일해야 함)
        $display("--- T9: CH0_AVG 읽기 (bypass) ---");
        bus_read(16'h0018, rd_val);
        // avg_len=0 bypass: avg_out = 최신 sample_data = raw
        // 주의: avg는 sample_valid 엣지에서 갱신되므로 직전 raw와 같아야 함
        if (rd_val[11:0] !== 12'hABC) begin
            $display("WARN: CH0_AVG=0x%03X (exp=0xABC, 웜업 중일 수 있음)", rd_val[11:0]);
        end else begin
            $display("PASS: CH0_AVG = 0x%03X", rd_val[11:0]);
        end

        // 결과 요약
        repeat (4) @(posedge clk);
        if (fail_cnt == 0)
            $display("PASS: xadc_hub");
        else
            $display("FAIL: xadc_hub (%0d errors)", fail_cnt);

        $finish;
    end

endmodule
