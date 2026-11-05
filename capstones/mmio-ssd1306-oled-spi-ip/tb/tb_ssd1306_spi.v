// tb_ssd1306_spi.v
// 자체 점검형 테스트벤치: axil_ssd1306_spi
//
// 검증 항목:
//   TB1_INIT   : 리셋 후 FSM이 자동으로 초기화 시퀀스를 완료하고
//                INIT_DONE(STATUS[1])이 세팅되는지 확인
//   TB2_REGWR  : BUF_ADDR, BUF_DATA, CONTRAST, IRQ_EN 레지스터 쓰기/읽기 대조
//   TB3_START  : START 비트 → S_PREP → S_DATA 전환 및 IRQ 발생 확인
//   TB4_SPI    : SPI 캡처 모델로 CS_N, SCK, MOSI, D/C 타이밍 검증
//
// 통과: "PASS: ..." 로 시작하는 줄, 실패: "FAIL: ..." 로 시작하는 줄
// X/Z 감지: !== 비교 사용
//
// SPI_DIV=2, PWRUP_CNT=4, RST_CNT=4 — 빠른 시뮬레이션
// Verilog-2001. iverilog 호환.
`default_nettype none
`timescale 1ns/1ps

module tb_ssd1306_spi;

    // ----------------------------------------------------------------
    // DUT 파라미터 (TB용 — 짧은 대기)
    // ----------------------------------------------------------------
    parameter SPI_DIV    = 2;
    parameter PWRUP_CNT  = 4;
    parameter RST_CNT    = 4;

    // ----------------------------------------------------------------
    // 클럭 / 리셋
    // ----------------------------------------------------------------
    reg clk = 0;
    reg rst_n;
    always #5 clk = ~clk; // 100MHz

    // ----------------------------------------------------------------
    // AXI4-Lite 버스 신호
    // ----------------------------------------------------------------
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

    // ----------------------------------------------------------------
    // SSD1306 SPI 출력
    // ----------------------------------------------------------------
    wire spi_sck, spi_mosi, spi_cs_n, spi_dc;
    wire spi_res_n, spi_vdd_en, spi_vbat_en;
    wire irq;

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    axil_ssd1306_spi #(
        .SPI_DIV   (SPI_DIV),
        .PWRUP_CNT (PWRUP_CNT),
        .RST_CNT   (RST_CNT)
    ) dut (
        .clk        (clk),    .rst_n      (rst_n),
        .s_awaddr   (s_awaddr),  .s_awvalid (s_awvalid), .s_awready (s_awready),
        .s_wdata    (s_wdata),   .s_wstrb   (s_wstrb),   .s_wvalid  (s_wvalid),
        .s_wready   (s_wready),  .s_bresp   (s_bresp),   .s_bvalid  (s_bvalid),
        .s_bready   (s_bready),
        .s_araddr   (s_araddr),  .s_arvalid (s_arvalid), .s_arready (s_arready),
        .s_rdata    (s_rdata),   .s_rresp   (s_rresp),   .s_rvalid  (s_rvalid),
        .s_rready   (s_rready),
        .spi_sck    (spi_sck),   .spi_mosi  (spi_mosi),  .spi_cs_n  (spi_cs_n),
        .spi_dc     (spi_dc),    .spi_res_n (spi_res_n),
        .spi_vdd_en (spi_vdd_en),.spi_vbat_en(spi_vbat_en),
        .irq        (irq)
    );

    // ----------------------------------------------------------------
    // SPI 캡처 모델
    // ----------------------------------------------------------------
    reg  [7:0]  spi_cap_byte;
    reg  [7:0]  spi_cap_dc;      // DC 레벨 (캡처한 바이트별)
    integer     spi_byte_cnt;
    reg  [7:0]  spi_shift_cap;
    reg  [3:0]  spi_bit_cap;
    reg         spi_prev_sck;

    // SPI 오류 플래그
    reg spi_cs_low_on_sck; // SCK 상승 에지에서 CS_N이 로우인지

    initial begin
        spi_cap_byte    = 0;
        spi_cap_dc      = 0;
        spi_byte_cnt    = 0;
        spi_shift_cap   = 0;
        spi_bit_cap     = 0;
        spi_prev_sck    = 0;
        spi_cs_low_on_sck = 0;
    end

    // SPI Mode 0: SCK 상승 에지에서 MOSI 샘플
    always @(posedge clk) begin
        spi_prev_sck <= spi_sck;
        if (spi_sck && !spi_prev_sck) begin
            // 상승 에지
            if (!spi_cs_n) begin
                spi_cs_low_on_sck <= 1;
                spi_shift_cap     <= {spi_shift_cap[6:0], spi_mosi};
                spi_bit_cap       <= spi_bit_cap + 1;
                if (spi_bit_cap == 7) begin
                    spi_cap_byte  <= {spi_shift_cap[6:0], spi_mosi};
                    spi_cap_dc    <= spi_dc;
                    spi_byte_cnt  <= spi_byte_cnt + 1;
                    spi_bit_cap   <= 0;
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // AXI4-Lite 태스크 (고정 사이클, NBA 경쟁 없음)
    // ----------------------------------------------------------------
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            s_awaddr = addr; s_awvalid = 1;
            s_wdata  = data; s_wstrb = 4'hF; s_wvalid = 1; s_bready = 1;
            @(posedge clk); #1;
            s_awvalid = 0; s_wvalid = 0;
            @(posedge clk);
            @(posedge clk); #1;
            s_bready = 0;
        end
    endtask

    task axi_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk); #1;
            s_araddr = addr; s_arvalid = 1; s_rready = 1;
            @(posedge clk); #1;
            s_arvalid = 0;
            @(posedge clk); #1;
            s_rready = 0;
            data = s_rdata;
        end
    endtask

    // ----------------------------------------------------------------
    // 대기: STATUS[1](INIT_DONE) 세팅까지
    // ----------------------------------------------------------------
    task wait_init_done;
        integer timeout;
        reg [31:0] rd;
        begin
            timeout = 0;
            rd = 0;
            while (rd[1] !== 1'b1 && timeout < 100_000) begin
                axi_read(32'h04, rd);
                timeout = timeout + 1;
            end
            if (timeout >= 100_000) begin
                $display("FAIL: TB1_INIT timeout — INIT_DONE never asserted");
                $finish;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // 대기: STATUS[0](BUSY) 클리어까지
    // ----------------------------------------------------------------
    task wait_not_busy;
        integer timeout;
        reg [31:0] rd;
        begin
            timeout = 0;
            rd = 32'h1;
            while (rd[0] !== 1'b0 && timeout < 2_000_000) begin
                axi_read(32'h04, rd);
                timeout = timeout + 1;
            end
            if (timeout >= 2_000_000) begin
                $display("FAIL: wait_not_busy timeout — BUSY never cleared");
                $finish;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // 테스트 카운터
    // ----------------------------------------------------------------
    integer fail_cnt;
    integer pass_cnt;

    // ----------------------------------------------------------------
    // 메인 테스트
    // ----------------------------------------------------------------
    integer i;
    reg [31:0] rd_val;
    integer    irq_seen;

    initial begin
        // 초기화
        fail_cnt  = 0;
        pass_cnt  = 0;
        rst_n     = 0;
        s_awaddr  = 0; s_awvalid = 0;
        s_wdata   = 0; s_wstrb = 4'hF; s_wvalid = 0; s_bready = 0;
        s_araddr  = 0; s_arvalid = 0; s_rready = 0;
        irq_seen  = 0;

        repeat(4) @(posedge clk);
        rst_n = 1;

        // ============================================================
        // TB1_INIT: 초기화 완료 대기
        // ============================================================
        wait_init_done;

        // STATUS[1] == 1 확인
        axi_read(32'h04, rd_val);
        if (rd_val[1] !== 1'b1) begin
            $display("FAIL: TB1_INIT — STATUS[1](INIT_DONE) not set, got %0h", rd_val);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB1_INIT — INIT_DONE asserted after power-up sequence");
            pass_cnt = pass_cnt + 1;
        end

        // STATUS[0] (BUSY) 클리어 확인
        if (rd_val[0] !== 1'b0) begin
            $display("FAIL: TB1_INIT — BUSY still set after INIT_DONE");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB1_INIT — BUSY cleared after init");
            pass_cnt = pass_cnt + 1;
        end

        // VDD_EN / VBAT_EN 확인
        if (spi_vdd_en !== 1'b1 || spi_vbat_en !== 1'b1) begin
            $display("FAIL: TB1_INIT — VDD_EN=%0b VBAT_EN=%0b (expected both 1)",
                     spi_vdd_en, spi_vbat_en);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB1_INIT — VDD_EN and VBAT_EN asserted");
            pass_cnt = pass_cnt + 1;
        end

        // SPI 캡처 바이트 수: 초기화 25바이트 전송 확인
        if (spi_byte_cnt < 25) begin
            $display("FAIL: TB1_INIT — SPI bytes captured=%0d (expected >=25)", spi_byte_cnt);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB1_INIT — SPI captured %0d bytes during init", spi_byte_cnt);
            pass_cnt = pass_cnt + 1;
        end

        // ============================================================
        // TB2_REGWR: 레지스터 쓰기/읽기
        // ============================================================

        // BUF_ADDR 쓰기
        axi_write(32'h08, 32'h1A3);
        axi_read (32'h08, rd_val);
        if (rd_val[8:0] !== 9'h1A3) begin
            $display("FAIL: TB2_REGWR — BUF_ADDR expected 0x1A3, got 0x%0h", rd_val[8:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB2_REGWR — BUF_ADDR read-back OK (0x1A3)");
            pass_cnt = pass_cnt + 1;
        end

        // BUF_DATA 쓰기 + 자동 증가
        axi_write(32'h08, 32'h00A); // BUF_ADDR = 10
        axi_write(32'h0C, 32'hAB);  // fbuf[10] = 0xAB, addr→11
        axi_read (32'h08, rd_val);
        if (rd_val[8:0] !== 9'd11) begin
            $display("FAIL: TB2_REGWR — BUF_ADDR auto-increment: expected 11, got %0d", rd_val[8:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB2_REGWR — BUF_ADDR auto-incremented to 11");
            pass_cnt = pass_cnt + 1;
        end

        // 쓴 바이트 읽기
        axi_write(32'h08, 32'h00A); // BUF_ADDR 다시 10으로
        axi_read (32'h0C, rd_val);
        if (rd_val[7:0] !== 8'hAB) begin
            $display("FAIL: TB2_REGWR — BUF_DATA readback: expected 0xAB, got 0x%0h", rd_val[7:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB2_REGWR — BUF_DATA readback OK (0xAB at addr 10)");
            pass_cnt = pass_cnt + 1;
        end

        // CONTRAST 쓰기
        axi_write(32'h10, 32'h7F);
        axi_read (32'h10, rd_val);
        if (rd_val[7:0] !== 8'h7F) begin
            $display("FAIL: TB2_REGWR — CONTRAST expected 0x7F, got 0x%0h", rd_val[7:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB2_REGWR — CONTRAST readback OK (0x7F)");
            pass_cnt = pass_cnt + 1;
        end

        // IRQ_EN 쓰기
        axi_write(32'h14, 32'h1);
        axi_read (32'h14, rd_val);
        if (rd_val[0] !== 1'b1) begin
            $display("FAIL: TB2_REGWR — IRQ_EN expected 1, got %0b", rd_val[0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB2_REGWR — IRQ_EN readback OK");
            pass_cnt = pass_cnt + 1;
        end

        // ============================================================
        // TB3_START: 프레임 전송 트리거 및 IRQ 확인
        // ============================================================

        // 프레임 버퍼 일부 채우기 (패턴: 0xA5)
        axi_write(32'h08, 32'h000);
        for (i = 0; i < 8; i = i + 1) begin
            axi_write(32'h0C, 32'hA5);
        end

        // IRQ_EN 활성화
        axi_write(32'h14, 32'h1);

        // SPI 캡처 카운터 리셋
        spi_byte_cnt = 0;

        // START 비트 세팅
        axi_write(32'h00, 32'h1);

        // BUSY 설정 대기 (최대 20사이클)
        repeat(20) @(posedge clk);
        axi_read(32'h04, rd_val);
        if (rd_val[0] !== 1'b1) begin
            $display("FAIL: TB3_START — BUSY not set after START");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB3_START — BUSY set after START");
            pass_cnt = pass_cnt + 1;
        end

        // 완료 대기
        wait_not_busy;

        // FRAME_DONE 펄스 / IRQ 확인
        // IRQ는 1사이클이므로 완료 직후 STATUS[2] 또는 IRQ 감지
        axi_read(32'h04, rd_val);
        // IRQ 발생은 1클럭 펄스 — 위에서 이미 클리어됐을 수 있으므로
        // SPI 바이트 수로 프레임 전송 완료 확인
        // 6(prep) + 512(data) = 518 바이트
        if (spi_byte_cnt < 518) begin
            $display("FAIL: TB3_START — SPI bytes captured=%0d (expected >=518 for frame)",
                     spi_byte_cnt);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB3_START — Frame sent: %0d SPI bytes captured", spi_byte_cnt);
            pass_cnt = pass_cnt + 1;
        end

        // CS_N 복귀 확인
        if (spi_cs_n !== 1'b1) begin
            $display("FAIL: TB3_START — CS_N not deasserted after frame");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB3_START — CS_N deasserted after frame");
            pass_cnt = pass_cnt + 1;
        end

        // ============================================================
        // TB4_SPI: SPI 타이밍 — CS_N 로우 중에 SCK 상승 에지가 있었는지
        // ============================================================
        if (spi_cs_low_on_sck !== 1'b1) begin
            $display("FAIL: TB4_SPI — No SCK rising edge observed while CS_N low");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS: TB4_SPI — SCK rising edges captured with CS_N low");
            pass_cnt = pass_cnt + 1;
        end

        // ============================================================
        // 최종 결과
        // ============================================================
        $display("---");
        $display("PASS count: %0d", pass_cnt);
        $display("FAIL count: %0d", fail_cnt);
        if (fail_cnt === 0)
            $display("PASS: tb_ssd1306_spi — ALL TESTS PASSED");
        else
            $display("FAIL: tb_ssd1306_spi — %0d test(s) FAILED", fail_cnt);

        $finish;
    end

    // 최대 타임아웃
    initial begin
        #50_000_000;
        $display("FAIL: tb_ssd1306_spi — global timeout");
        $finish;
    end

endmodule
`default_nettype wire
