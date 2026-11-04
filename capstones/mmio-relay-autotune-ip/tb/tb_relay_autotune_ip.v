// tb_relay_autotune_ip.v — 릴레이 자동 튜닝 IP 자체 점검 테스트벤치
// 1차+지연 모터 모델로 한계 사이클 주기를 해석값과 대조한다.
// 출력: "PASS" 또는 "FAIL <원인>" 로 시작하는 줄.
// Verilog-2001. iverilog 호환.
`timescale 1ns/1ps

// ============================================================
// 1차+지연 모터 모델 (정수 근사)
//   속도(k+1) = speed(k) - speed(k)/τ + Km * relay_out(k-Td)
//   Km=1 (스케일), τ=200클럭, Td=10클럭
//   speed 범위: 0 ~ 65535 (부호 없음 16비트)
// ============================================================
module motor_model (
    input  wire        clk,
    input  wire        resetn,
    input  wire        relay_dir,  // 1=정방향, 0=역방향
    input  wire [15:0] relay_amp,  // 릴레이 진폭
    output reg  [15:0] speed_out
);
    // 지연 버퍼 (10클럭)
    reg relay_hist [0:9];
    integer i;

    // 32비트 내부 속도 (Q16 고정소수점)
    reg [31:0] spd_fp;

    // 파라미터
    localparam [15:0] TAU = 200;   // 시상수 클럭 수
    localparam [15:0] KM  = 1;     // 이득 (정수)
    localparam        SCALE = 256; // Q8 스케일

    always @(posedge clk) begin
        if (!resetn) begin
            spd_fp   <= 32'd16384 * 256; // 초기 속도 16384 (setpoint 근처)
            speed_out <= 16'd16384;
            for (i = 0; i < 10; i = i + 1)
                relay_hist[i] <= 1'b1;
        end else begin
            // 지연 버퍼 시프트
            for (i = 9; i > 0; i = i - 1)
                relay_hist[i] <= relay_hist[i-1];
            relay_hist[0] <= relay_dir;

            // 1차 감쇠 + 릴레이 입력 (Q8 정수 계산)
            begin : update
                reg [31:0] decay;
                reg [31:0] drive;
                reg [31:0] nxt;
                decay = spd_fp / TAU;
                drive = relay_hist[9] ? (relay_amp * SCALE) : 0;
                // 역방향이면 감속
                nxt = spd_fp - decay + drive;
                if (nxt > 32'd65535 * SCALE) nxt = 32'd65535 * SCALE;
                spd_fp   <= nxt;
                speed_out <= nxt[23:8]; // Q8→정수
            end
        end
    end
endmodule

// ============================================================
// 테스트벤치 최상위
// ============================================================
module tb_relay_autotune_ip;

    reg  clk;
    reg  resetn;

    // AXI4-Lite 마스터 신호
    reg  [31:0] awaddr;  reg  awvalid;  wire awready;
    reg  [31:0] wdata;   reg  [3:0] wstrb;  reg  wvalid;  wire wready;
    wire [1:0]  bresp;   wire bvalid;  reg  bready;
    reg  [31:0] araddr;  reg  arvalid; wire arready;
    wire [31:0] rdata;   wire [1:0] rresp;  wire rvalid;  reg  rready;

    // 모터 모델 연결
    wire        relay_out;
    wire [15:0] speed_in;
    wire        irq;

    reg  [15:0] relay_amp_val;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    relay_autotune_ip #(.BASE_ADDR(32'h401E_0000)) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (resetn),
        .s_axi_awaddr  (awaddr),  .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata   (wdata),   .s_axi_wstrb  (wstrb),   .s_axi_wvalid (wvalid),  .s_axi_wready(wready),
        .s_axi_bresp   (bresp),   .s_axi_bvalid (bvalid),  .s_axi_bready (bready),
        .s_axi_araddr  (araddr),  .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata   (rdata),   .s_axi_rresp  (rresp),   .s_axi_rvalid (rvalid),  .s_axi_rready(rready),
        .speed_in      (speed_in),
        .relay_out     (relay_out),
        .irq           (irq)
    );

    // --------------------------------------------------------
    // 모터 모델
    // --------------------------------------------------------
    motor_model u_motor (
        .clk       (clk),
        .resetn    (resetn),
        .relay_dir (relay_out),
        .relay_amp (relay_amp_val),
        .speed_out (speed_in)
    );

    // --------------------------------------------------------
    // 클럭 100 MHz
    // --------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

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
            @(posedge clk);
            while (!awready || !wready) @(posedge clk);
            #1;
            awvalid = 1'b0; wvalid = 1'b0;
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
            while (!arready || !rvalid) @(posedge clk);
            data = rdata;
            #1;
            arvalid = 1'b0;
            @(posedge clk); #1;
            rready = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // 테스트 시나리오
    // --------------------------------------------------------
    reg [31:0] rd;
    integer    timeout_cnt;

    initial begin
        errors  = 0;
        relay_amp_val = 16'd4096;  // 모터 모델에 전달할 릴레이 진폭
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
        axil_read(32'h401E_FFF0, rd);
        check("TC1-IP_ID",  rd === 32'h5245_4C59);
        axil_read(32'h401E_FFF4, rd);
        check("TC1-IP_VER", rd === 32'h0000_0100);

        // ------------------------------------------------
        // TC-2: 초기 상태 — CTRL=0, IRQ=0
        // ------------------------------------------------
        axil_read(32'h401E_0000, rd);
        check("TC2-CTRL-init", rd[0] === 1'b0);
        axil_read(32'h401E_FFFC, rd);
        check("TC2-IRQ_STATUS-init", rd[0] === 1'b0);
        check("TC2-IRQ-low", irq === 1'b0);

        // ------------------------------------------------
        // TC-3: 릴레이 FSM 동작 — 한계 사이클 완료
        //   SETPOINT = 16384, RELAY_AMP = 4096, IRQ_ENABLE = 1
        //   ctrl_en 0→1 토글로 시작
        //   모터 모델이 setpoint를 2회 교차하면 IRQ 발생
        // ------------------------------------------------
        axil_write(32'h401E_0004, 32'd16384); // SETPOINT
        axil_write(32'h401E_0008, 32'd4096);  // RELAY_AMP
        axil_write(32'h401E_FFF8, 32'h1);     // IRQ_ENABLE
        // ctrl_en = 1 (상승에지 → FSM_RUN)
        axil_write(32'h401E_0000, 32'h1);

        // IRQ가 올 때까지 대기 (최대 20000사이클)
        timeout_cnt = 0;
        while (irq !== 1'b1 && timeout_cnt < 20000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end
        check("TC3-IRQ-high",        irq === 1'b1);
        axil_read(32'h401E_FFFC, rd);
        check("TC3-IRQ_STATUS-set",  rd[0] === 1'b1);
        // 교차 횟수 >= 2
        axil_read(32'h401E_0014, rd);
        check("TC3-CROSS_CNT>=2",    rd[15:0] >= 16'd2);
        // 주기 카운터 > 0
        axil_read(32'h401E_000C, rd);
        check("TC3-PERIOD_CNT>0",    rd > 32'd0);

        // ------------------------------------------------
        // TC-4: IRQ W1C 소거
        // ------------------------------------------------
        axil_write(32'h401E_0000, 32'h0);     // ctrl_en=0 → FSM_IDLE 복귀
        repeat(2) @(posedge clk);
        axil_write(32'h401E_FFFC, 32'h1);     // W1C 소거
        repeat(2) @(posedge clk);
        axil_read(32'h401E_FFFC, rd);
        check("TC4-IRQ_STATUS-cleared", rd[0] === 1'b0);
        check("TC4-IRQ-low", irq === 1'b0);

        // ------------------------------------------------
        // TC-5: ctrl_en 재토글로 2번째 측정 가능
        // ------------------------------------------------
        axil_write(32'h401E_0000, 32'h1);
        timeout_cnt = 0;
        while (irq !== 1'b1 && timeout_cnt < 20000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end
        check("TC5-IRQ-2nd-run", irq === 1'b1);
        axil_write(32'h401E_0000, 32'h0);
        repeat(2) @(posedge clk);
        axil_write(32'h401E_FFFC, 32'h1);
        repeat(2) @(posedge clk);
        check("TC5-IRQ-low-after-2nd-clear", irq === 1'b0);

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
        #1500000;
        $display("FAIL: 타임아웃");
        $finish;
    end

endmodule
