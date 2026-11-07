// tb_crc32_axil.v — CRC-32 AXI4-Lite IP 자체 점검형 테스트벤치
// slug: mmio-crc32-axil-ip
//
// 테스트 항목:
//   1. CTRL INIT 후 CRC_OUT = 0xFFFFFFFF
//   2. DATA_IN 0xFF 한 바이트 → CRC_OUT = 0x00FFFFFF
//   3. DATA_IN "123456789" (0x31..0x39) 9바이트 → CRC_OUT = 0x340BC6D9
//
// 주의: bready/rready를 사전 활성화하지 않는다 (데드락 방지).
//       응답 채널이 열릴 때만 활성화한다.
//
// 통과: "PASS: ..." 출력 / 실패: "FAIL: ..." 출력 후 $finish
// iverilog -g2001 -Wall 호환.

`default_nettype none
`timescale 1ns/1ps

module tb_crc32_axil;

    // ----------------------------------------------------------------
    // 파라미터
    // ----------------------------------------------------------------
    parameter DATA_W = 32;
    parameter ADDR_W = 4;

    // ----------------------------------------------------------------
    // 클럭·리셋
    // ----------------------------------------------------------------
    reg clk;
    reg rstn;

    initial clk = 1'b0;
    always #5 clk = ~clk;  // 100 MHz

    // ----------------------------------------------------------------
    // AXI4-Lite 버스
    // ----------------------------------------------------------------
    reg  [ADDR_W-1:0] awaddr;
    reg               awvalid;
    wire              awready;
    reg  [DATA_W-1:0] wdata;
    reg  [3:0]        wstrb;
    reg               wvalid;
    wire              wready;
    wire [1:0]        bresp;
    wire              bvalid;
    reg               bready;
    reg  [ADDR_W-1:0] araddr;
    reg               arvalid;
    wire              arready;
    wire [DATA_W-1:0] rdata;
    wire [1:0]        rresp;
    wire              rvalid;
    reg               rready;
    wire              ip2intc_irpt;

    // 초기화
    initial begin
        awaddr  = {ADDR_W{1'b0}};
        awvalid = 1'b0;
        wdata   = {DATA_W{1'b0}};
        wstrb   = 4'hF;
        wvalid  = 1'b0;
        bready  = 1'b0;
        araddr  = {ADDR_W{1'b0}};
        arvalid = 1'b0;
        rready  = 1'b0;
    end

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    crc32_axil #(
        .C_S_AXI_DATA_WIDTH(DATA_W),
        .C_S_AXI_ADDR_WIDTH(ADDR_W)
    ) u_dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rstn),
        .s_axi_awaddr  (awaddr),
        .s_axi_awprot  (3'b000),
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
        .s_axi_arprot  (3'b000),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),
        .s_axi_rdata   (rdata),
        .s_axi_rresp   (rresp),
        .s_axi_rvalid  (rvalid),
        .s_axi_rready  (rready),
        .ip2intc_irpt  (ip2intc_irpt)
    );

    // ----------------------------------------------------------------
    // axi_write 태스크
    // bready는 bvalid가 올 때만 활성 (사전 활성 금지)
    // ----------------------------------------------------------------
    task axi_write;
        input [ADDR_W-1:0] addr;
        input [DATA_W-1:0] data;
        integer timeout;
        begin
            // AW+W 동시 발행
            @(posedge clk);
            awaddr  <= addr;
            awvalid <= 1'b1;
            wdata   <= data;
            wstrb   <= 4'hF;
            wvalid  <= 1'b1;

            // 양쪽 핸드쉐이크 대기
            timeout = 0;
            while (!(awready && awvalid) || !(wready && wvalid)) begin
                @(posedge clk);
                if (awready && awvalid) awvalid <= 1'b0;
                if (wready  && wvalid)  wvalid  <= 1'b0;
                timeout = timeout + 1;
                if (timeout > 100) begin
                    $display("FAIL: axi_write timeout (AW/W) addr=%0h", addr);
                    $finish;
                end
            end
            @(posedge clk);
            awvalid <= 1'b0;
            wvalid  <= 1'b0;

            // bvalid 대기 후 bready 한 사이클 활성
            timeout = 0;
            while (!bvalid) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 100) begin
                    $display("FAIL: axi_write timeout (B) addr=%0h", addr);
                    $finish;
                end
            end
            bready <= 1'b1;
            @(posedge clk);
            bready <= 1'b0;
        end
    endtask

    // ----------------------------------------------------------------
    // axi_read 태스크
    // rready는 rvalid가 올 때만 활성 (사전 활성 금지)
    // ----------------------------------------------------------------
    task axi_read;
        input  [ADDR_W-1:0] addr;
        output [DATA_W-1:0] data;
        integer timeout;
        begin
            @(posedge clk);
            araddr  <= addr;
            arvalid <= 1'b1;

            // AR 핸드쉐이크 대기
            timeout = 0;
            while (!(arready && arvalid)) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 100) begin
                    $display("FAIL: axi_read timeout (AR) addr=%0h", addr);
                    $finish;
                end
            end
            @(posedge clk);
            arvalid <= 1'b0;

            // rvalid 대기 후 rready 한 사이클 활성, 데이터 캡처
            timeout = 0;
            while (!rvalid) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 100) begin
                    $display("FAIL: axi_read timeout (R) addr=%0h", addr);
                    $finish;
                end
            end
            rready <= 1'b1;
            data    = rdata;
            @(posedge clk);
            rready <= 1'b0;
        end
    endtask

    // ----------------------------------------------------------------
    // 메인 테스트
    // ----------------------------------------------------------------
    reg [DATA_W-1:0] rd;
    integer i;
    reg [7:0] test_bytes [0:8];  // "123456789"

    initial begin
        // "123456789" 바이트 초기화
        test_bytes[0] = 8'h31; // '1'
        test_bytes[1] = 8'h32; // '2'
        test_bytes[2] = 8'h33; // '3'
        test_bytes[3] = 8'h34; // '4'
        test_bytes[4] = 8'h35; // '5'
        test_bytes[5] = 8'h36; // '6'
        test_bytes[6] = 8'h37; // '7'
        test_bytes[7] = 8'h38; // '8'
        test_bytes[8] = 8'h39; // '9'

        // 리셋
        rstn = 1'b0;
        repeat (5) @(posedge clk);
        rstn = 1'b1;
        repeat (3) @(posedge clk);

        // -------------------------------------------------
        // 테스트 1: 리셋 후 CTRL INIT → CRC_OUT = 0xFFFFFFFF
        // -------------------------------------------------
        axi_write(4'h8, 32'h0000_0001);  // CTRL INIT=1
        axi_read (4'h4, rd);             // CRC_OUT
        if (rd !== 32'hFFFF_FFFF) begin
            $display("FAIL: T1 CTRL INIT: CRC_OUT=0x%08X expected 0xFFFFFFFF", rd);
            $finish;
        end
        $display("PASS: T1 CTRL INIT: CRC_OUT=0x%08X", rd);

        // -------------------------------------------------
        // 테스트 2: DATA_IN 0xFF → CRC_OUT = 0x00FFFFFF
        // -------------------------------------------------
        axi_write(4'h8, 32'h0000_0001);  // CTRL INIT (재초기화)
        axi_write(4'h0, 32'h0000_00FF);  // DATA_IN = 0xFF
        axi_read (4'h4, rd);             // CRC_OUT
        if (rd !== 32'h00FF_FFFF) begin
            $display("FAIL: T2 byte=0xFF: CRC_OUT=0x%08X expected 0x00FFFFFF", rd);
            $finish;
        end
        $display("PASS: T2 byte=0xFF: CRC_OUT=0x%08X", rd);

        // -------------------------------------------------
        // 테스트 3: "123456789" → CRC_OUT = 0x340BC6D9
        // -------------------------------------------------
        axi_write(4'h8, 32'h0000_0001);  // CTRL INIT
        for (i = 0; i < 9; i = i + 1) begin
            axi_write(4'h0, {24'h0, test_bytes[i]});
        end
        axi_read(4'h4, rd);  // CRC_OUT
        if (rd !== 32'h340B_C6D9) begin
            $display("FAIL: T3 '123456789': CRC_OUT=0x%08X expected 0x340BC6D9", rd);
            $finish;
        end
        $display("PASS: T3 '123456789': CRC_OUT=0x%08X", rd);

        // -------------------------------------------------
        // 테스트 4: ip2intc_irpt 항상 0
        // -------------------------------------------------
        if (ip2intc_irpt !== 1'b0) begin
            $display("FAIL: T4 ip2intc_irpt=%b expected 0", ip2intc_irpt);
            $finish;
        end
        $display("PASS: T4 ip2intc_irpt=0");

        $display("PASS: tb_crc32_axil — 전체 통과");
        $finish;
    end

    // 최대 실행 시간 보호
    initial begin
        #100000;
        $display("FAIL: timeout — 시뮬레이션이 종료되지 않음");
        $finish;
    end

endmodule
`default_nettype wire
