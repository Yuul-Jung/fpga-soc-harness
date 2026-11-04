// tb_xadc_pwr_mon.v — XADC 전원 감시 IP 자체 점검 테스트벤치
// 모의 DRP 모델로 Vccint/Vccaux/Vccbram 판독·임계값 비교·IRQ 발생·W1C 소거 검증.
// 출력: "PASS" 또는 "FAIL <원인>" 로 시작하는 줄.
// Verilog-2001. iverilog 호환.
`timescale 1ns/1ps

// ============================================================
// 모의 DRP 모델: 고정 공급전압 값 반환
// Vccint  = 1.0V → 코드 = 1.0*4096/3 = 1365 = 0x555  → drp_do = 0x5550
// Vccaux  = 1.8V → 코드 = 1.8*4096/3 = 2457 = 0x999  → drp_do = 0x9990
// Vccbram = 1.0V → 코드 = 1.0*4096/3 = 1365 = 0x555  → drp_do = 0x5550
// ============================================================
module xadc_drp_model (
    input  wire        dclk,
    input  wire        den,
    input  wire        dwe,
    input  wire [6:0]  daddr,
    input  wire [15:0] di,
    output reg  [15:0] do_out,
    output reg         drdy
);
    // 외부에서 오버라이드 가능한 채널 값 (12비트 MSB-정렬)
    reg [15:0] val_vccint  = 16'h5550;  // 1.0V
    reg [15:0] val_vccaux  = 16'h9990;  // 1.8V
    reg [15:0] val_vccbram = 16'h5550;  // 1.0V

    always @(posedge dclk) begin
        drdy <= 1'b0;
        if (den && !dwe) begin
            case (daddr)
                7'h01: do_out <= val_vccint;
                7'h02: do_out <= val_vccaux;
                7'h06: do_out <= val_vccbram;
                default: do_out <= 16'h0;
            endcase
            drdy <= 1'b1;  // 1클럭 후 준비
        end
    end
endmodule

// ============================================================
// 테스트벤치 최상위
// ============================================================
module tb_xadc_pwr_mon;

    reg  clk;
    reg  resetn;

    // AXI4-Lite 마스터 신호
    reg  [31:0] awaddr;  reg  awvalid;  wire awready;
    reg  [31:0] wdata;   reg  [3:0] wstrb;  reg  wvalid;  wire wready;
    wire [1:0]  bresp;   wire bvalid;  reg  bready;
    reg  [31:0] araddr;  reg  arvalid; wire arready;
    wire [31:0] rdata;   wire [1:0] rresp;  wire rvalid;  reg  rready;

    // DRP
    wire        drp_den, drp_dwe;
    wire [6:0]  drp_daddr;
    wire [15:0] drp_di;
    wire [15:0] drp_do;    // wire: 모의 모델 출력에 연결
    wire        drp_drdy;  // wire: 모의 모델 출력에 연결

    wire irq;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    xadc_pwr_mon_ip #(.BASE_ADDR(32'h4016_0000)) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (resetn),
        .s_axi_awaddr  (awaddr),  .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata   (wdata),   .s_axi_wstrb  (wstrb),   .s_axi_wvalid (wvalid),  .s_axi_wready(wready),
        .s_axi_bresp   (bresp),   .s_axi_bvalid (bvalid),  .s_axi_bready (bready),
        .s_axi_araddr  (araddr),  .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata   (rdata),   .s_axi_rresp  (rresp),   .s_axi_rvalid (rvalid),  .s_axi_rready(rready),
        .drp_den       (drp_den),
        .drp_dwe       (drp_dwe),
        .drp_daddr     (drp_daddr),
        .drp_di        (drp_di),
        .drp_do        (drp_do),
        .drp_drdy      (drp_drdy),
        .irq           (irq)
    );

    // --------------------------------------------------------
    // 모의 DRP 모델 연결
    // --------------------------------------------------------
    xadc_drp_model u_drp (
        .dclk   (clk),
        .den    (drp_den),
        .dwe    (drp_dwe),
        .daddr  (drp_daddr),
        .di     (drp_di),
        .do_out (drp_do),
        .drdy   (drp_drdy)
    );

    // --------------------------------------------------------
    // 클럭
    // --------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // --------------------------------------------------------
    // 오류 카운터
    // --------------------------------------------------------
    integer errors;

    task check;
        input [255:0] desc;
        input         cond;
        begin
            if (!cond) begin
                $display("FAIL %0s", desc);
                errors = errors + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // AXI4-Lite 쓰기 태스크
    // --------------------------------------------------------
    task axil_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wstrb = 4'hF; wvalid = 1'b1;
            // AW+W 동시 핸드셰이크 (RTL이 같은 클럭에 awready/wready를 펄스함)
            // NBA 타이밍: posedge 직후 활성 영역에서는 아직 NBA 미반영.
            // 한 클럭 더 기다리면 두 신호 모두 visible. 분리 루프는 W를 놓침.
            @(posedge clk);
            while (!awready || !wready) @(posedge clk);
            #1;
            awvalid = 1'b0;
            wvalid  = 1'b0;
            // B 핸드셰이크
            bready = 1'b1;
            while (!bvalid) @(posedge clk);
            @(posedge clk); #1;
            bready = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // AXI4-Lite 읽기 태스크
    // --------------------------------------------------------
    task axil_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk); #1;
            araddr = addr; arvalid = 1'b1;
            rready = 1'b1;
            @(posedge clk);
            while (!arready) @(posedge clk);
            #1; arvalid = 1'b0;
            while (!rvalid) @(posedge clk);
            data = rdata;
            @(posedge clk); #1;
            rready = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // 테스트 시나리오
    // --------------------------------------------------------
    reg [31:0] rd;
    integer    i;

    initial begin
        errors  = 0;
        awaddr  = 0; awvalid = 0;
        wdata   = 0; wstrb = 4'hF; wvalid = 0;
        bready  = 0;
        araddr  = 0; arvalid = 0;
        rready  = 0;
        resetn  = 0;
        repeat(4) @(posedge clk);
        resetn = 1;
        repeat(2) @(posedge clk);

        // ------------------------------------------------
        // TC-1: IP_ID / IP_VER 확인
        // ------------------------------------------------
        axil_read(32'h4016_FFF0, rd);
        check("TC1-IP_ID", rd === 32'h5841_504D);
        axil_read(32'h4016_FFF4, rd);
        check("TC1-IP_VER", rd === 32'h0000_0100);

        // ------------------------------------------------
        // TC-2: 임계값 설정 — 모두 허용 범위 내
        //   Vccint  LO=0x400 HI=0x700  (공칭 0x555 → 정상)
        //   Vccaux  LO=0x800 HI=0xB00  (공칭 0x999 → 정상)
        //   Vccbram LO=0x400 HI=0x700  (공칭 0x555 → 정상)
        // ------------------------------------------------
        axil_write(32'h4016_0014, 32'h400);   // THR_INT_LO
        axil_write(32'h4016_0018, 32'h700);   // THR_INT_HI
        axil_write(32'h4016_001C, 32'h800);   // THR_AUX_LO
        axil_write(32'h4016_0020, 32'hB00);   // THR_AUX_HI
        axil_write(32'h4016_0024, 32'h400);   // THR_BRAM_LO
        axil_write(32'h4016_0028, 32'h700);   // THR_BRAM_HI
        axil_write(32'h4016_FFFC, 32'h7);     // IRQ_ENABLE=[2:0]=1

        // CTRL: en=1, auto=0 (한 번 스캔)
        axil_write(32'h4016_0000, 32'h1);

        // DRP FSM이 세 채널을 읽고 F_CMP까지 완료하기를 기다린다 (~20사이클)
        repeat(30) @(posedge clk);

        // 판독값 확인
        axil_read(32'h4016_0008, rd);
        check("TC2-VCCINT-raw", rd[15:4] === 12'h555);
        axil_read(32'h4016_000C, rd);
        check("TC2-VCCAUX-raw", rd[15:4] === 12'h999);
        axil_read(32'h4016_0010, rd);
        check("TC2-VCCBRAM-raw", rd[15:4] === 12'h555);

        // 임계값 내 → IRQ 없음
        axil_read(32'h4016_FFF8, rd);
        check("TC2-IRQ_STATUS-none", rd[2:0] === 3'b000);
        check("TC2-IRQ-low", irq === 1'b0);

        // ------------------------------------------------
        // TC-3: 저전압 위반 — Vccint를 과낮은 값으로 설정
        //   Vccint 모의 모델을 0x2220 (0x222→0.4V)으로 변경
        //   THR_INT_LO=0x400 이므로 0x222 < 0x400 → 위반
        // ------------------------------------------------
        u_drp.val_vccint = 16'h2220;
        // en=1 다시 토글 (한 번 더 스캔)
        axil_write(32'h4016_0000, 32'h0);
        repeat(2) @(posedge clk);
        axil_write(32'h4016_0000, 32'h1);
        repeat(30) @(posedge clk);

        axil_read(32'h4016_FFF8, rd);
        check("TC3-IRQ_STATUS-vccint", rd[0] === 1'b1);
        check("TC3-IRQ-high", irq === 1'b1);

        // ------------------------------------------------
        // TC-4: IRQ W1C 소거
        // ------------------------------------------------
        axil_write(32'h4016_FFF8, 32'h7);    // 모든 비트 클리어
        repeat(2) @(posedge clk);
        axil_read(32'h4016_FFF8, rd);
        check("TC4-IRQ_STATUS-cleared", rd[2:0] === 3'b000);
        check("TC4-IRQ-low-after-clear", irq === 1'b0);

        // 모의 모델 복원
        u_drp.val_vccint = 16'h5550;

        // ------------------------------------------------
        // TC-5: 고전압 위반 — Vccaux 상한 초과
        //   THR_AUX_HI=0xB00; Vccaux 모의 값을 0xC000 (0xC00=2.5V)
        // ------------------------------------------------
        u_drp.val_vccaux = 16'hC000;
        axil_write(32'h4016_0000, 32'h0);
        repeat(2) @(posedge clk);
        axil_write(32'h4016_0000, 32'h1);
        repeat(30) @(posedge clk);

        axil_read(32'h4016_FFF8, rd);
        check("TC5-IRQ_STATUS-vccaux", rd[1] === 1'b1);

        // 소거 후 최종 상태 클린
        axil_write(32'h4016_FFF8, 32'h7);
        repeat(2) @(posedge clk);

        // ------------------------------------------------
        // 결과 출력
        // ------------------------------------------------
        if (errors === 0)
            $display("PASS: 모든 TC 통과 (TC1~TC5)");
        else
            $display("FAIL: %0d개 체크 실패", errors);

        $finish;
    end

    // 타임아웃
    initial begin
        #500000;
        $display("FAIL: 타임아웃");
        $finish;
    end

endmodule
