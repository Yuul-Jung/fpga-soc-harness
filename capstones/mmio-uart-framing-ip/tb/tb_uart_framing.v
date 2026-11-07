// tb_uart_framing.v — 자체 검증 테스트벤치
// 통과: stdout에 "PASS" 로 시작하는 줄 출력
// 실패: stdout에 "FAIL" 로 시작하는 줄 출력 후 $finish
// iverilog -g2001 -Wall -Wno-timescale -o tb_uart_framing tb/tb_uart_framing.v rtl/*.v && vvp tb_uart_framing

`timescale 1ns/1ps

module tb_uart_framing;

// ── 파라미터 ───────────────────────────────────────────────
// 시뮬레이션에서 빠른 보드레이트 사용 (클럭 주기 10ns)
// baud_div=4 → baud_period = 4×16×10ns = 640ns (1.5625 MHz)
localparam CLK_PERIOD = 10;      // 10ns = 100 MHz
localparam BAUD_DIV   = 4;
localparam BAUD_TICKS = BAUD_DIV * 16;  // 한 비트 = 64 클럭

// ── 신호 선언 ──────────────────────────────────────────────
reg clk, rst_n;
reg uart_rx_drv;

// AXI4-Lite 버스 (soc_top 마스터 포트를 직접 구동)
reg  [7:0]  m_awaddr;
reg         m_awvalid;
wire        m_awready;
reg  [31:0] m_wdata;
reg  [3:0]  m_wstrb;
reg         m_wvalid;
wire        m_wready;
wire [1:0]  m_bresp;
wire        m_bvalid;
reg         m_bready;
reg  [7:0]  m_araddr;
reg         m_arvalid;
wire        m_arready;
wire [31:0] m_rdata;
wire [1:0]  m_rresp;
wire        m_rvalid;
reg         m_rready;
wire        irq_out;

// ── DUT 인스턴스 ───────────────────────────────────────────
soc_top dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .uart_rx  (uart_rx_drv),
    .irq_out  (irq_out),
    .m_awaddr (m_awaddr),  .m_awvalid (m_awvalid), .m_awready (m_awready),
    .m_wdata  (m_wdata),   .m_wstrb   (m_wstrb),   .m_wvalid  (m_wvalid),
    .m_wready (m_wready),  .m_bresp   (m_bresp),   .m_bvalid  (m_bvalid),
    .m_bready (m_bready),
    .m_araddr (m_araddr),  .m_arvalid (m_arvalid), .m_arready (m_arready),
    .m_rdata  (m_rdata),   .m_rresp   (m_rresp),   .m_rvalid  (m_rvalid),
    .m_rready (m_rready)
);

// ── 클럭 ──────────────────────────────────────────────────
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// ── 실패 카운터 ───────────────────────────────────────────
integer fail_cnt;
initial fail_cnt = 0;

// ── 태스크: AXI4-Lite 쓰기 ────────────────────────────────
task axi_write;
    input [7:0]  addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        m_awaddr  = addr;  m_awvalid = 1'b1;
        m_wdata   = data;  m_wstrb   = 4'b1111; m_wvalid = 1'b1;
        fork
            begin wait(m_awready); @(posedge clk); #1; m_awvalid = 1'b0; end
            begin wait(m_wready);  @(posedge clk); #1; m_wvalid  = 1'b0; end
        join
        m_bready = 1'b1;
        wait(m_bvalid); @(posedge clk); #1; m_bready = 1'b0;
    end
endtask

// ── 태스크: AXI4-Lite 읽기 ────────────────────────────────
task axi_read;
    input  [7:0]  addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        m_araddr  = addr; m_arvalid = 1'b1;
        wait(m_arready); @(posedge clk); #1; m_arvalid = 1'b0;
        m_rready = 1'b1;
        wait(m_rvalid); data = m_rdata; @(posedge clk); #1; m_rready = 1'b0;
    end
endtask

// ── 태스크: 8N1 UART 한 바이트 전송 ──────────────────────
task uart_send_byte;
    input [7:0] d;
    integer i;
    begin
        // 스타트 비트
        uart_rx_drv = 1'b0;
        repeat(BAUD_TICKS) @(posedge clk);
        // 데이터 비트 (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            uart_rx_drv = d[i];
            repeat(BAUD_TICKS) @(posedge clk);
        end
        // 스톱 비트
        uart_rx_drv = 1'b1;
        repeat(BAUD_TICKS) @(posedge clk);
    end
endtask

// ── 태스크: 패킷 전송 [LEN][TYPE][PAYLOAD…][CRC_HI][CRC_LO] ──
task uart_send_packet;
    input [7:0]  pkt_len;
    input [7:0]  pkt_type;
    input [7:0]  p0, p1, p2, p3;
    input [15:0] crc;      // 테스트가 직접 계산해 넣는다
    integer i;
    begin
        uart_send_byte(pkt_len);
        uart_send_byte(pkt_type);
        for (i = 0; i < pkt_len; i = i + 1) begin
            case (i)
            0: uart_send_byte(p0);
            1: uart_send_byte(p1);
            2: uart_send_byte(p2);
            3: uart_send_byte(p3);
            default: uart_send_byte(8'hAA);
            endcase
        end
        uart_send_byte(crc[15:8]);
        uart_send_byte(crc[7:0]);
    end
endtask

// ── CRC-16/CCITT-FALSE 소프트웨어 모델 ───────────────────
function [15:0] sw_crc16;
    input [7:0] d;
    input [15:0] crc;
    integer i;
    reg [15:0] c;
    begin
        c = crc;
        for (i = 0; i < 8; i = i + 1) begin
            if (c[15] ^ d[7-i])
                c = (c << 1) ^ 16'h1021;
            else
                c = c << 1;
        end
        sw_crc16 = c;
    end
endfunction

function [15:0] calc_crc;
    input [7:0] pkt_len, pkt_type;
    input [7:0] p0, p1, p2, p3;
    reg [15:0] c;
    integer i;
    begin
        c = 16'hFFFF;
        c = sw_crc16(pkt_len,  c);
        c = sw_crc16(pkt_type, c);
        for (i = 0; i < pkt_len; i = i + 1) begin
            case (i)
            0: c = sw_crc16(p0, c);
            1: c = sw_crc16(p1, c);
            2: c = sw_crc16(p2, c);
            3: c = sw_crc16(p3, c);
            default: c = sw_crc16(8'hAA, c);
            endcase
        end
        calc_crc = c;
    end
endfunction

// ── 타임아웃 ─────────────────────────────────────────────
integer timeout_cnt;
initial begin
    #2_000_000;
    $display("FAIL timeout: 시뮬레이션이 2ms 안에 끝나지 않았다");
    $finish;
end

// ── 메인 테스트 ───────────────────────────────────────────
reg [31:0] rd;
reg [15:0] crc_expected;
integer wait_cnt;

initial begin
    // 초기화
    rst_n       = 1'b0;
    uart_rx_drv = 1'b1;    // 아이들 High
    m_awaddr    = 8'd0; m_awvalid = 1'b0;
    m_wdata     = 32'd0; m_wstrb = 4'd0; m_wvalid = 1'b0;
    m_bready    = 1'b0;
    m_araddr    = 8'd0; m_arvalid = 1'b0;
    m_rready    = 1'b0;
    fail_cnt    = 0;

    repeat(10) @(posedge clk);
    rst_n = 1'b1;
    repeat(5) @(posedge clk);

    // ──────────────────────────────────────────────────────
    // BAUD_DIV 설정 (0x08 ← BAUD_DIV=4)
    axi_write(8'h08, 32'd4);
    // IRQ_EN 활성 (0x04 ← 1)
    axi_write(8'h04, 32'd1);

    // ══════════════════════════════════════════════════════
    // 테스트 1: 정상 패킷 (LEN=3, TYPE=0x42, payload=0x11,0x22,0x33)
    // ══════════════════════════════════════════════════════
    crc_expected = calc_crc(8'd3, 8'h42, 8'h11, 8'h22, 8'h33, 8'h00);
    uart_send_packet(8'd3, 8'h42, 8'h11, 8'h22, 8'h33, 8'h00, crc_expected);

    // PKT_DONE 대기 (최대 200클럭)
    wait_cnt = 0;
    begin : wait_done1
        forever begin
            @(posedge clk);
            axi_read(8'h00, rd);
            if (rd[0]) disable wait_done1;
            wait_cnt = wait_cnt + 1;
            if (wait_cnt > 10000) begin
                $display("FAIL T1: PKT_DONE가 10000클럭 안에 셋되지 않았다");
                fail_cnt = fail_cnt + 1;
                disable wait_done1;
            end
        end
    end

    if (rd[0] !== 1'b1) begin
        $display("FAIL T1: STATUS.PKT_DONE=0"); fail_cnt = fail_cnt + 1;
    end else if (rd[1] !== 1'b1) begin
        $display("FAIL T1: STATUS.CRC_OK=0 (CRC 불일치)"); fail_cnt = fail_cnt + 1;
    end else begin
        // PKT_TYPE 확인
        axi_read(8'h0C, rd);
        if (rd[7:0] !== 8'h42) begin
            $display("FAIL T1: PKT_TYPE=0x%02X (expected 0x42)", rd[7:0]);
            fail_cnt = fail_cnt + 1;
        end
        // PKT_LEN 확인
        axi_read(8'h10, rd);
        if (rd[7:0] !== 8'd3) begin
            $display("FAIL T1: PKT_LEN=%0d (expected 3)", rd[7:0]);
            fail_cnt = fail_cnt + 1;
        end
        // DATA_0 확인
        axi_read(8'h14, rd);
        if (rd[7:0] !== 8'h11) begin
            $display("FAIL T1: DATA_0=0x%02X (expected 0x11)", rd[7:0]);
            fail_cnt = fail_cnt + 1;
        end
        if (fail_cnt == 0) $display("PASS T1: 정상 패킷 수신, CRC 일치");
    end

    // CLR_DONE
    axi_write(8'h04, 32'h3);  // IRQ_EN=1, CLR_DONE=1
    @(posedge clk);

    // ══════════════════════════════════════════════════════
    // 테스트 2: CRC 오류 패킷 (CRC를 의도적으로 반전)
    // ══════════════════════════════════════════════════════
    crc_expected = ~calc_crc(8'd2, 8'h01, 8'hAA, 8'hBB, 8'h00, 8'h00);
    uart_send_packet(8'd2, 8'h01, 8'hAA, 8'hBB, 8'h00, 8'h00, crc_expected);

    wait_cnt = 0;
    begin : wait_done2
        forever begin
            @(posedge clk);
            axi_read(8'h00, rd);
            if (rd[0]) disable wait_done2;
            wait_cnt = wait_cnt + 1;
            if (wait_cnt > 10000) begin
                $display("FAIL T2: PKT_DONE 대기 타임아웃");
                fail_cnt = fail_cnt + 1;
                disable wait_done2;
            end
        end
    end

    if (rd[0] !== 1'b1) begin
        $display("FAIL T2: PKT_DONE=0"); fail_cnt = fail_cnt + 1;
    end else if (rd[1] !== 1'b0) begin
        $display("FAIL T2: CRC_OK=1 (CRC 오류를 감지하지 못함)");
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T2: CRC 오류 패킷 감지 (CRC_OK=0)");
    end

    axi_write(8'h04, 32'h3);
    @(posedge clk);

    // ══════════════════════════════════════════════════════
    // 테스트 3: 페이로드 0바이트 패킷 (LEN=0)
    // ══════════════════════════════════════════════════════
    crc_expected = calc_crc(8'd0, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00);
    uart_send_packet(8'd0, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00, crc_expected);

    wait_cnt = 0;
    begin : wait_done3
        forever begin
            @(posedge clk);
            axi_read(8'h00, rd);
            if (rd[0]) disable wait_done3;
            wait_cnt = wait_cnt + 1;
            if (wait_cnt > 10000) begin
                $display("FAIL T3: PKT_DONE 대기 타임아웃");
                fail_cnt = fail_cnt + 1;
                disable wait_done3;
            end
        end
    end

    if (rd[0] !== 1'b1) begin
        $display("FAIL T3: PKT_DONE=0"); fail_cnt = fail_cnt + 1;
    end else if (rd[1] !== 1'b1) begin
        $display("FAIL T3: CRC_OK=0 (LEN=0 패킷 CRC 오류)");
        fail_cnt = fail_cnt + 1;
    end else begin
        axi_read(8'h10, rd);
        if (rd[7:0] !== 8'd0) begin
            $display("FAIL T3: PKT_LEN=%0d (expected 0)", rd[7:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS T3: 0바이트 페이로드 패킷 정상 처리");
        end
    end

    // ── 최종 결과 ─────────────────────────────────────────
    if (fail_cnt == 0) begin
        $display("PASS: 모든 테스트 통과 (3/3)");
    end else begin
        $display("FAIL: %0d건 실패", fail_cnt);
    end

    #100;
    $finish;
end

endmodule
