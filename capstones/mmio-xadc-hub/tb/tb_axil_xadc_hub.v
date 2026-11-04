// tb_axil_xadc_hub.v
// 자체 점검 테스트벤치 — axil_xadc_hub.v만 시험 (XADC 프리미티브 없음)
// 모의 DRP 모델이 채널 주소별로 고정 응답을 돌려준다.
// 통과: "PASS" 출력. 실패: "FAIL: N checks failed" 출력.
`timescale 1ns/1ps
`default_nettype none

module tb_axil_xadc_hub;

    // -----------------------------------------------------------------------
    // 클럭·리셋
    // -----------------------------------------------------------------------
    reg clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    reg rst_n = 0;
    initial begin
        #12; rst_n = 1;
    end

    // -----------------------------------------------------------------------
    // DUT 포트 연결
    // -----------------------------------------------------------------------
    reg  [31:0] awaddr  = 0;
    reg         awvalid = 0;
    wire        awready;
    reg  [31:0] wdata   = 0;
    reg  [3:0]  wstrb   = 4'hF;
    reg         wvalid  = 0;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready  = 0;
    reg  [31:0] araddr  = 0;
    reg         arvalid = 0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready  = 0;
    wire        drp_den;
    wire        drp_dwe;
    wire [6:0]  drp_daddr;
    wire [15:0] drp_di;
    reg  [15:0] drp_do  = 0;
    reg         drp_drdy = 0;
    wire        irq;

    axil_xadc_hub #(
        .BASE_ADDR(32'h4009_0000)
    ) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        .s_axi_awaddr  (awaddr),
        .s_axi_awvalid (awvalid),
        .s_axi_awready (awready),
        .s_axi_wdata   (wdata),
        .s_axi_wstrb   (wstrb),
        .s_axi_wvalid  (wvalid),
        .s_axi_wready  (wready),
        .s_axi_bresp   (bresp),
        .s_axi_bvalid  (bvalid),
        .s_axi_bready  (bready),
        .s_axi_araddr  (araddr),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),
        .s_axi_rdata   (rdata),
        .s_axi_rresp   (rresp),
        .s_axi_rvalid  (rvalid),
        .s_axi_rready  (rready),
        .drp_den       (drp_den),
        .drp_dwe       (drp_dwe),
        .drp_daddr     (drp_daddr),
        .drp_di        (drp_di),
        .drp_do        (drp_do),
        .drp_drdy      (drp_drdy),
        .irq           (irq)
    );

    // -----------------------------------------------------------------------
    // 모의 DRP 모델 (1클럭 지연 응답)
    // 채널 주소 → 고정 ADC 결과 (DO[15:4]에 12비트 정렬)
    // VAUX0=0x10 → 0xABC0 (12비트=0xABC)
    // VAUX1=0x11 → 0x1230 (12비트=0x123)
    // VAUX8=0x18 → 0x4560 (12비트=0x456)
    // VAUX9=0x19 → 0x7890 (12비트=0x789)
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        drp_drdy <= 1'b0;
        drp_do   <= 16'h0;
        if (drp_den) begin
            case (drp_daddr)
                7'h10: drp_do <= 16'hABC0;
                7'h11: drp_do <= 16'h1230;
                7'h18: drp_do <= 16'h4560;
                7'h19: drp_do <= 16'h7890;
                default: drp_do <= 16'h0000;
            endcase
            drp_drdy <= 1'b1;
        end
    end

    // -----------------------------------------------------------------------
    // 태스크: AXI 쓰기
    // -----------------------------------------------------------------------
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            awaddr  <= addr; awvalid <= 1'b1;
            wdata   <= data; wvalid  <= 1'b1; wstrb <= 4'hF;
            @(posedge clk); #1;
            awvalid <= 1'b0;
            wvalid  <= 1'b0;
            bready  <= 1'b1;
            @(posedge clk); #1;
            @(posedge clk); #1;
            bready  <= 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    // 태스크: AXI 읽기
    // -----------------------------------------------------------------------
    reg [31:0] rd_data;
    task axi_read;
        input [31:0] addr;
        begin
            @(posedge clk); #1;
            araddr  <= addr; arvalid <= 1'b1;
            rready  <= 1'b1;
            @(posedge clk); #1;
            arvalid <= 1'b0;
            @(posedge clk); #1;
            rd_data <= rdata;
            rready  <= 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    // 검증 카운터
    // -----------------------------------------------------------------------
    integer fail_cnt = 0;

    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] tag;
        begin
            if (got !== exp) begin
                $display("FAIL [%0s]: got=0x%08X exp=0x%08X", tag, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // IRQ 대기 (타임아웃 포함)
    // -----------------------------------------------------------------------
    integer wait_cnt;
    reg irq_ok;
    task wait_irq;
        input integer timeout;
        begin
            irq_ok   = 0;
            wait_cnt = 0;
            while (!irq && wait_cnt < timeout) begin
                @(posedge clk); #1;
                wait_cnt = wait_cnt + 1;
            end
            if (irq) irq_ok = 1;
            else begin
                $display("FAIL: IRQ timeout after %0d cycles", timeout);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // 메인 시나리오
    // -----------------------------------------------------------------------
    initial begin
        // 리셋 해제 대기
        @(posedge rst_n);
        repeat(5) @(posedge clk);

        // ===================================================================
        // T1: avg_sel=0 (평균 1회, avg_len=1) 단일 스캔
        // ===================================================================
        $display("--- T1: avg_sel=0 단일 스캔 ---");
        // IRQ 활성화
        axi_write(32'h4009_0018, 32'h1);
        // CTRL: avg_sel=0, en=1
        axi_write(32'h4009_0014, 32'h1);

        // IRQ 대기 (최대 500 클럭)
        wait_irq(500);

        // 스캔 완료 후 ctrl_en 해제
        axi_write(32'h4009_0014, 32'h0);
        repeat(50) @(posedge clk);

        // 채널값 확인 (각 채널 12비트 평균 = 모의 DRP 값 그대로)
        axi_read(32'h4009_0000); check_eq(rd_data, 32'h0000_0ABC, "T1_CH0");
        axi_read(32'h4009_0004); check_eq(rd_data, 32'h0000_0123, "T1_CH1");
        axi_read(32'h4009_0008); check_eq(rd_data, 32'h0000_0456, "T1_CH2");
        axi_read(32'h4009_000C); check_eq(rd_data, 32'h0000_0789, "T1_CH3");

        // IRQ_STAT 확인 (스캔 완료 = 1)
        axi_read(32'h4009_001C); check_eq(rd_data, 32'h0000_0001, "T1_IRQ_STAT_before_W1C");
        // irq = irq_en & irq_stat = 1
        check_eq({31'h0, irq}, 32'h0000_0001, "T1_irq_high");

        // W1C: IRQ_STAT 클리어
        axi_write(32'h4009_001C, 32'h1);
        repeat(5) @(posedge clk);
        axi_read(32'h4009_001C); check_eq(rd_data, 32'h0000_0000, "T1_IRQ_STAT_after_W1C");
        check_eq({31'h0, irq}, 32'h0000_0000, "T1_irq_low");

        // ===================================================================
        // T2: avg_sel=1 (평균 2회, avg_len=2) 두 번 누적 평균
        // CH0: (0xABC + 0xABC) >> 1 = 0xABC (동일 값)
        // ===================================================================
        $display("--- T2: avg_sel=1 2회 평균 ---");
        axi_write(32'h4009_0018, 32'h1);
        // CTRL: avg_sel=1([4:2]=3'b001), en=1
        axi_write(32'h4009_0014, 32'h0000_0005);

        wait_irq(1500);

        axi_write(32'h4009_0014, 32'h0);
        repeat(50) @(posedge clk);

        // CH0 평균: (0xABC + 0xABC) >> 1 = 0xABC
        axi_read(32'h4009_0000); check_eq(rd_data, 32'h0000_0ABC, "T2_CH0_avg2");
        // CH3 평균: (0x789 + 0x789) >> 1 = 0x789
        axi_read(32'h4009_000C); check_eq(rd_data, 32'h0000_0789, "T2_CH3_avg2");

        // ID_VER 확인
        axi_read(32'h4009_00FC); check_eq(rd_data, 32'h0032_0100, "T2_ID_VER");

        // W1C 클리어
        axi_write(32'h4009_001C, 32'h1);
        repeat(5) @(posedge clk);
        axi_read(32'h4009_001C); check_eq(rd_data, 32'h0000_0000, "T2_IRQ_STAT_clear");

        // ===================================================================
        // 최종 결과
        // ===================================================================
        repeat(10) @(posedge clk);
        if (fail_cnt === 0)
            $display("PASS");
        else
            $display("FAIL: %0d checks failed", fail_cnt);
        $finish;
    end

    // 전체 타임아웃 보호
    initial begin
        #500000;
        $display("FAIL: global timeout");
        $finish;
    end

endmodule
`default_nettype wire
