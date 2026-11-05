// tb_axil_oled_ssd1306.v — SSD1306 OLED IP 자체 점검 테스트벤치
// 하네스 원본. 외부 코드 복사 아님.
// 검증 항목:
//   1. 초기화 완료 후 STATUS[0]=init_done=1 확인
//   2. SPI 바이트열에서 초기화 명령(AE, 8D/14, AFf 등) 확인
//   3. 프레임 버퍼 쓰기 후 en_refresh=1 → SPI에 프레임 데이터 출력 확인
//   PASS/FAIL 출력 (비교 !==, X/Z도 실패)
`default_nettype none
`timescale 1ns/1ps

module tb_axil_oled_ssd1306;

    // ── DUT 클럭/리셋 ─────────────────────────────────────
    reg  clk = 0;
    reg  rst_n = 0;
    always #5 clk = ~clk;  // 100MHz

    // ── DUT 포트 ─────────────────────────────────────────
    reg  [7:0]  s_awaddr  = 0;
    reg         s_awvalid = 0;
    wire        s_awready;
    reg  [31:0] s_wdata   = 0;
    reg  [3:0]  s_wstrb   = 4'hF;
    reg         s_wvalid  = 0;
    wire        s_wready;
    wire [1:0]  s_bresp;
    wire        s_bvalid;
    reg         s_bready  = 1;
    reg  [7:0]  s_araddr  = 0;
    reg         s_arvalid = 0;
    wire        s_arready;
    wire [31:0] s_rdata;
    wire [1:0]  s_rresp;
    wire        s_rvalid;
    reg         s_rready  = 1;
    wire        oled_sck;
    wire        oled_mosi;
    wire        oled_cs_n;
    wire        oled_dc;
    wire        oled_res_n;
    wire        irq_refresh_done;

    axil_oled_ssd1306 #(
        .CLK_DIV (2),    // 빠른 시뮬레이션: SCK = 100MHz/4 = 25MHz
        .INIT_LEN(24)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .s_awaddr         (s_awaddr),
        .s_awvalid        (s_awvalid),
        .s_awready        (s_awready),
        .s_wdata          (s_wdata),
        .s_wstrb          (s_wstrb),
        .s_wvalid         (s_wvalid),
        .s_wready         (s_wready),
        .s_bresp          (s_bresp),
        .s_bvalid         (s_bvalid),
        .s_bready         (s_bready),
        .s_araddr         (s_araddr),
        .s_arvalid        (s_arvalid),
        .s_arready        (s_arready),
        .s_rdata          (s_rdata),
        .s_rresp          (s_rresp),
        .s_rvalid         (s_rvalid),
        .s_rready         (s_rready),
        .oled_sck         (oled_sck),
        .oled_mosi        (oled_mosi),
        .oled_cs_n        (oled_cs_n),
        .oled_dc          (oled_dc),
        .oled_res_n       (oled_res_n),
        .irq_refresh_done (irq_refresh_done)
    );

    // ── SPI 비트 수신기 ───────────────────────────────────
    // 상승 엣지에서 MOSI 샘플 → 8비트 모이면 큐에 push
    integer    bit_idx = 0;
    reg [7:0]  rx_byte = 0;
    // 수신 바이트 큐 (최대 1024개)
    reg [7:0]  rx_q [0:1023];
    reg [9:0]  rx_head = 0;
    reg [9:0]  rx_tail = 0;

    // DC·CS 샘플을 바이트와 함께 저장
    reg [7:0]  rxdc_q  [0:1023];  // 1=데이터, 0=명령
    reg        dc_at_byte;

    always @(posedge oled_sck) begin
        if (!oled_cs_n) begin
            rx_byte  <= {rx_byte[6:0], oled_mosi};
            bit_idx  <= bit_idx + 1;
            if (bit_idx == 7) begin
                rx_q   [rx_tail] <= {rx_byte[6:0], oled_mosi};
                rxdc_q [rx_tail] <= oled_dc;
                rx_tail          <= rx_tail + 10'd1;
                bit_idx          <= 0;
            end
        end
    end

    // ── AXI-Lite 헬퍼 태스크 ─────────────────────────────
    task axil_write;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            s_awaddr = addr; s_awvalid = 1;
            s_wdata  = data; s_wvalid  = 1;
            wait (s_awready && s_wready);
            @(posedge clk); #1;
            s_awvalid = 0; s_wvalid = 0;
            wait (s_bvalid);
            @(posedge clk); #1;
        end
    endtask

    task axil_read;
        input  [7:0]  addr;
        output [31:0] data;
        begin
            @(posedge clk); #1;
            s_araddr = addr; s_arvalid = 1;
            wait (s_arready);
            @(posedge clk); #1;
            s_arvalid = 0;
            wait (s_rvalid);
            data = s_rdata;
            @(posedge clk); #1;
        end
    endtask

    // ── 큐에서 다음 바이트 꺼내기 ────────────────────────
    task rx_pop;
        output [7:0] byte_out;
        output       dc_out;
        begin
            if (rx_head == rx_tail) begin
                $display("FAIL: rx_pop on empty queue");
                $finish;
            end
            byte_out = rx_q   [rx_head];
            dc_out   = rxdc_q [rx_head];
            rx_head  = rx_head + 10'd1;
        end
    endtask

    // ── 타임아웃 대기 ──────────────────────────────────────
    task wait_spi_bytes;
        input integer cnt;
        input integer timeout_ns;
        integer elapsed;
        begin
            elapsed = 0;
            while ((rx_tail - rx_head) < cnt && elapsed < timeout_ns) begin
                #10; elapsed = elapsed + 10;
            end
            if (elapsed >= timeout_ns) begin
                $display("FAIL: timeout waiting for %0d SPI bytes (got %0d)", cnt, rx_tail - rx_head);
                $finish;
            end
        end
    endtask

    // ── 메인 테스트 ──────────────────────────────────────
    reg [31:0] rdata;
    reg [7:0]  b;
    reg        dc;
    integer    i;
    reg        all_pass;
    integer    fail_cnt;
    // init_check 배열과 플래그 — 모듈 레벨에 선언 (익명 블록 내 선언은 SV 전용)
    reg [7:0]  init_check [0:23];
    reg        init_dc_ok;

    initial begin
        all_pass = 1; fail_cnt = 0;

        // 리셋
        rst_n = 0;
        repeat (20) @(posedge clk);
        rst_n = 1;
        repeat (5)  @(posedge clk);

        // ════════════════════════════════════════════════
        // TEST 1: 초기화 명령 시퀀스 확인
        // ════════════════════════════════════════════════
        // 초기화 완료까지 기다림 (24바이트 × 20클럭/바이트 × CLK_DIV=2 ≒ 2000ns)
        // 넉넉히 100us 대기
        wait_spi_bytes(24, 100_000);

        // STATUS[0] = init_done = 1 확인
        axil_read(8'h04, rdata);
        if (rdata[0] !== 1'b1) begin
            $display("FAIL: init_done not set after init sequence (STATUS=0x%08X)", rdata);
            all_pass = 0; fail_cnt = fail_cnt + 1;
        end

        // SPI 바이트 큐에서 24바이트 체크
        // 주요 확인: AE(0), 8D(8), 14(9), A4(22), AF(23)
        // 모두 명령(dc=0)
        begin
            init_dc_ok = 1;
            init_check[ 0] = 8'hAE;
            init_check[ 1] = 8'hD5;
            init_check[ 2] = 8'h80;
            init_check[ 3] = 8'hA8;
            init_check[ 4] = 8'h1F;
            init_check[ 5] = 8'hD3;
            init_check[ 6] = 8'h00;
            init_check[ 7] = 8'h40;
            init_check[ 8] = 8'h8D;
            init_check[ 9] = 8'h14;
            init_check[10] = 8'h20;
            init_check[11] = 8'h00;
            init_check[12] = 8'hA1;
            init_check[13] = 8'hC8;
            init_check[14] = 8'hDA;
            init_check[15] = 8'h02;
            init_check[16] = 8'h81;
            init_check[17] = 8'hCF;
            init_check[18] = 8'hD9;
            init_check[19] = 8'hF1;
            init_check[20] = 8'hDB;
            init_check[21] = 8'h40;
            init_check[22] = 8'hA4;
            init_check[23] = 8'hAF;

            for (i = 0; i < 24; i = i + 1) begin
                rx_pop(b, dc);
                if (b !== init_check[i]) begin
                    $display("FAIL: init_rom[%0d] expected 0x%02X got 0x%02X", i, init_check[i], b);
                    all_pass = 0; fail_cnt = fail_cnt + 1;
                end
                if (dc !== 1'b0) begin
                    $display("FAIL: init byte %0d DC should be 0 (command), got 1", i);
                    all_pass = 0; fail_cnt = fail_cnt + 1;
                    init_dc_ok = 0;
                end
            end
            if (all_pass && init_dc_ok)
                $display("PASS: init sequence OK (24 bytes, all DC=0)");
        end

        // ════════════════════════════════════════════════
        // TEST 2: 프레임 버퍼 쓰기 + 갱신 확인
        // 첫 페이지 첫 열에 0xA5, 나머지 0x00 (기본값)
        // ════════════════════════════════════════════════

        // BUF_ADDR = {page=0, col=0} = 0x000
        axil_write(8'h08, 32'h0000_0000);
        // BUF_DATA = 0xA5
        axil_write(8'h0C, 32'h0000_00A5);
        // BUF_ADDR = {page=0, col=1} = 0x001
        axil_write(8'h08, 32'h0000_0001);
        // BUF_DATA = 0x5A
        axil_write(8'h0C, 32'h0000_005A);

        // CTRL[0]=1: 갱신 활성화
        axil_write(8'h00, 32'h0000_0001);

        // 갱신 완료 대기: 4페이지 × (3헤더 + 128데이터) = 524바이트
        // CLK_DIV=2: 한 바이트 ≈ 160ns → 524 × 160ns ≈ 85us
        // 넉넉히 500us
        wait_spi_bytes(524, 500_000);

        // IRQ 확인
        // (irq_refresh_done는 1클럭 펄스. 이미 소진됐을 수 있으니 STATUS[4] 대신 로그로 확인)

        // 큐에서 첫 페이지 헤더 3바이트 확인 (B0, 00, 10)
        rx_pop(b, dc);
        if (b !== 8'hB0 || dc !== 1'b0) begin
            $display("FAIL: page0 hdr[0] expected B0/dc=0, got %02X/dc=%0b", b, dc);
            all_pass = 0; fail_cnt = fail_cnt + 1;
        end
        rx_pop(b, dc);
        if (b !== 8'h00 || dc !== 1'b0) begin
            $display("FAIL: page0 hdr[1] expected 00/dc=0, got %02X/dc=%0b", b, dc);
            all_pass = 0; fail_cnt = fail_cnt + 1;
        end
        rx_pop(b, dc);
        if (b !== 8'h10 || dc !== 1'b0) begin
            $display("FAIL: page0 hdr[2] expected 10/dc=0, got %02X/dc=%0b", b, dc);
            all_pass = 0; fail_cnt = fail_cnt + 1;
        end

        // 첫 두 데이터 바이트 확인
        rx_pop(b, dc);
        if (b !== 8'hA5 || dc !== 1'b1) begin
            $display("FAIL: frame[0,0] expected A5/dc=1, got %02X/dc=%0b", b, dc);
            all_pass = 0; fail_cnt = fail_cnt + 1;
        end
        rx_pop(b, dc);
        if (b !== 8'h5A || dc !== 1'b1) begin
            $display("FAIL: frame[0,1] expected 5A/dc=1, got %02X/dc=%0b", b, dc);
            all_pass = 0; fail_cnt = fail_cnt + 1;
        end

        if (all_pass)
            $display("PASS: frame data OK (page header + pixel bytes verified)");

        // ════════════════════════════════════════════════
        // 최종 결과
        // ════════════════════════════════════════════════
        if (all_pass && fail_cnt == 0) begin
            $display("PASS: ALL CHECKS OK");
        end else begin
            $display("FAIL: %0d check(s) failed", fail_cnt);
        end
        $finish;
    end

    // 안전 타임아웃
    initial begin
        #10_000_000; // 10ms
        $display("FAIL: global timeout");
        $finish;
    end

    // VCD 덤프 (옵션)
    // initial begin
    //     $dumpfile("tb.vcd");
    //     $dumpvars(0, tb_axil_oled_ssd1306);
    // end

endmodule
`default_nettype wire
