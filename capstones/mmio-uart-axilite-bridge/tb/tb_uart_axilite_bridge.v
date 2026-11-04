// tb_uart_axilite_bridge.v — UART→AXI4-Lite 브리지 자동 검증 테스트벤치
//
// 테스트 항목:
//   TC1: 쓰기 (0x57 + ADDR 0x0000_0000 + DATA 0xABCD_1234) → ACK 0x06 확인
//       GPIO_DATA 읽기 → 슬레이브 led_reg 확인
//   TC2: 읽기 (0x52 + ADDR 0x0004) GPIO_DIR → 0x05+0xFFFF0000 확인
//   TC3: SW→GPIO 읽기 (sw=0x5A5A)
//
// 통과: PASS, 실패: FAIL (각 줄 첫 글자)
// 비교: !== (X/Z도 실패로 처리)
//
// 출처: 하네스 직접 작성 원본. 외부 코드 없음.

`timescale 1ns/1ps

module tb_uart_axilite_bridge;

    // ─── 파라미터 ───────────────────────────────────
    localparam BAUD_DIV  = 20;    // 시뮬레이션 속도: 실제 868 대신 20클럭/비트
    localparam CLK_HALF  = 5;     // 100 MHz 클럭 반주기 (ns)
    localparam BIT_TICKS = BAUD_DIV; // 비트당 클럭 수

    // ─── 클럭 / 리셋 ────────────────────────────────
    reg clk = 0;
    reg rst = 1;
    always #CLK_HALF clk = ~clk;

    // ─── DUT 신호 ───────────────────────────────────
    reg  uart_rxd_drv = 1'b1;   // PC→FPGA (테스트벤치가 구동)
    wire uart_txd;               // FPGA→PC
    reg  [15:0] sw = 16'h0000;
    wire [15:0] led;

    // ─── DUT ────────────────────────────────────────
    basys3_top #() dut (   // BAUD_DIV는 내부 로컬 — 직접 override 불가
        .clk     (clk),
        .rst     (rst),
        .uart_rxd(uart_rxd_drv),
        .uart_txd(uart_txd),
        .sw      (sw),
        .led     (led)
    );

    // BAUD_DIV override: DUT 내부 u_bridge의 파라미터를 시뮬레이션 속도로 변경하기 위해
    // 하위 인스턴스 직접 접근 (iverilog 허용)
    // → 대신 별도 모듈 계층으로 직접 테스트한다 (아래 참조)

    // ─── UART 전송 태스크 (테스트벤치→DUT) ──────────
    // BIT_TICKS 클럭씩 각 비트를 구동
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // 스타트 비트
            @(posedge clk); #1;
            uart_rxd_drv = 1'b0;
            repeat (BIT_TICKS) @(posedge clk);
            // 데이터 비트 (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                #1; uart_rxd_drv = data[i];
                repeat (BIT_TICKS) @(posedge clk);
            end
            // 스톱 비트
            #1; uart_rxd_drv = 1'b1;
            repeat (BIT_TICKS) @(posedge clk);
        end
    endtask

    // ─── UART 수신 태스크 (DUT→테스트벤치) ──────────
    task recv_byte;
        output [7:0] data;
        integer i;
        begin
            // 스타트 비트 하강 에지 대기
            @(negedge uart_txd);
            // 반주기 대기 (중간 샘플)
            repeat (BIT_TICKS/2) @(posedge clk);
            // 데이터 비트 샘플 (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                repeat (BIT_TICKS) @(posedge clk);
                data[i] = uart_txd;
            end
            // 스톱 비트 대기
            repeat (BIT_TICKS) @(posedge clk);
        end
    endtask

    // ─── 직접 테스트 모듈 (파라미터화) ─────────────
    // basys3_top은 파라미터를 외부로 내보내지 않으므로
    // uart_axilite_bridge + demo_gpio_slave를 직접 인스턴스화

    // AXI4-Lite 버스 신호
    wire [31:0] m_awaddr;
    wire        m_awvalid, m_awready;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire        m_wvalid, m_wready;
    wire [1:0]  m_bresp;
    wire        m_bvalid, m_bready;
    wire [31:0] m_araddr;
    wire        m_arvalid, m_arready;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rvalid, m_rready;
    wire        busy, err_flag;
    wire [15:0] gpio_led;
    wire        uart_txd2;

    reg  uart_rxd2 = 1'b1;
    reg  [15:0] sw2 = 16'h0000;

    uart_axilite_bridge #(.BAUD_DIV(BAUD_DIV)) u_brg (
        .clk        (clk),  .rst     (rst),
        .uart_rx_pin(uart_rxd2), .uart_tx_pin(uart_txd2),
        .m_awaddr(m_awaddr), .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata (m_wdata),  .m_wstrb  (m_wstrb),
        .m_wvalid(m_wvalid), .m_wready (m_wready),
        .m_bresp (m_bresp),  .m_bvalid (m_bvalid),  .m_bready(m_bready),
        .m_araddr(m_araddr), .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_rdata (m_rdata),  .m_rresp  (m_rresp),
        .m_rvalid(m_rvalid), .m_rready (m_rready),
        .busy(busy), .err_flag(err_flag)
    );

    demo_gpio_slave u_gpio (
        .clk(clk), .rst(rst),
        .s_awaddr(m_awaddr), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata (m_wdata),  .s_wstrb  (m_wstrb),
        .s_wvalid(m_wvalid), .s_wready (m_wready),
        .s_bresp (m_bresp),  .s_bvalid (m_bvalid),  .s_bready(m_bready),
        .s_araddr(m_araddr), .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata (m_rdata),  .s_rresp  (m_rresp),
        .s_rvalid(m_rvalid), .s_rready (m_rready),
        .sw(sw2), .led_reg(gpio_led)
    );

    // ─── 수신 태스크 (uart_txd2 기준) ───────────────
    task recv_byte2;
        output [7:0] data;
        integer i;
        begin
            @(negedge uart_txd2);
            repeat (BIT_TICKS/2) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                repeat (BIT_TICKS) @(posedge clk);
                data[i] = uart_txd2;
            end
            repeat (BIT_TICKS) @(posedge clk);
        end
    endtask

    // ─── 전송 태스크 (uart_rxd2 기준) ───────────────
    task send_byte2;
        input [7:0] data;
        integer i;
        begin
            @(posedge clk); #1;
            uart_rxd2 = 1'b0;
            repeat (BIT_TICKS) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                #1; uart_rxd2 = data[i];
                repeat (BIT_TICKS) @(posedge clk);
            end
            #1; uart_rxd2 = 1'b1;
            repeat (BIT_TICKS) @(posedge clk);
        end
    endtask

    // ─── 검사 변수 ───────────────────────────────────
    integer fail_count;
    reg [7:0] rx_byte;
    reg [31:0] rx_word;

    // ─── 메인 ────────────────────────────────────────
    initial begin
        fail_count = 0;

        // 리셋
        rst = 1;
        repeat (10) @(posedge clk);
        @(posedge clk); #1; rst = 0;
        repeat (5) @(posedge clk);

        // ════════════════════════════════════════════
        // TC1: 쓰기 — 0xABCD1234를 주소 0x00000000에 씀
        // ════════════════════════════════════════════
        // 프레임: 0x57 0x00 0x00 0x00 0x00 0xAB 0xCD 0x12 0x34
        send_byte2(8'h57);       // 'W'
        send_byte2(8'h00);       // ADDR[31:24]
        send_byte2(8'h00);       // ADDR[23:16]
        send_byte2(8'h00);       // ADDR[15:8]
        send_byte2(8'h00);       // ADDR[7:0]
        send_byte2(8'hAB);       // DATA[31:24]
        send_byte2(8'hCD);       // DATA[23:16]
        send_byte2(8'h12);       // DATA[15:8]
        send_byte2(8'h34);       // DATA[7:0]

        // ACK 수신 (0x06)
        recv_byte2(rx_byte);
        if (rx_byte !== 8'h06) begin
            $display("FAIL TC1a: write ACK got 0x%02X, expected 0x06", rx_byte);
            fail_count = fail_count + 1;
        end else
            $display("PASS TC1a: write ACK = 0x06");

        // GPIO 슬레이브 led_reg 확인
        repeat (5) @(posedge clk);
        if (gpio_led !== 16'h1234) begin
            $display("FAIL TC1b: led_reg got 0x%04X, expected 0x1234", gpio_led);
            fail_count = fail_count + 1;
        end else
            $display("PASS TC1b: led_reg = 0x1234");

        // ════════════════════════════════════════════
        // TC2: GPIO_DIR 읽기 — 주소 0x00000004 → 0xFFFF0000
        // ════════════════════════════════════════════
        send_byte2(8'h52);       // 'R'
        send_byte2(8'h00);       // ADDR[31:24]
        send_byte2(8'h00);       // ADDR[23:16]
        send_byte2(8'h00);       // ADDR[15:8]
        send_byte2(8'h04);       // ADDR[7:0]

        recv_byte2(rx_byte);
        if (rx_byte !== 8'h05) begin
            $display("FAIL TC2a: read ACK got 0x%02X, expected 0x05", rx_byte);
            fail_count = fail_count + 1;
        end else
            $display("PASS TC2a: read ACK = 0x05");

        recv_byte2(rx_word[31:24]);
        recv_byte2(rx_word[23:16]);
        recv_byte2(rx_word[15:8]);
        recv_byte2(rx_word[7:0]);

        if (rx_word !== 32'hFFFF0000) begin
            $display("FAIL TC2b: GPIO_DIR got 0x%08X, expected 0xFFFF0000", rx_word);
            fail_count = fail_count + 1;
        end else
            $display("PASS TC2b: GPIO_DIR = 0xFFFF0000");

        // ════════════════════════════════════════════
        // TC3: SW→GPIO 읽기 (sw2=0x5A5A)
        // ════════════════════════════════════════════
        sw2 = 16'h5A5A;
        repeat (3) @(posedge clk);

        send_byte2(8'h52);       // 'R'
        send_byte2(8'h00);
        send_byte2(8'h00);
        send_byte2(8'h00);
        send_byte2(8'h00);       // GPIO_DATA 주소

        recv_byte2(rx_byte);
        if (rx_byte !== 8'h05) begin
            $display("FAIL TC3a: read ACK got 0x%02X, expected 0x05", rx_byte);
            fail_count = fail_count + 1;
        end else
            $display("PASS TC3a: read ACK = 0x05");

        recv_byte2(rx_word[31:24]);
        recv_byte2(rx_word[23:16]);
        recv_byte2(rx_word[15:8]);
        recv_byte2(rx_word[7:0]);

        if (rx_word !== 32'h00005A5A) begin
            $display("FAIL TC3b: GPIO_DATA (SW) got 0x%08X, expected 0x00005A5A", rx_word);
            fail_count = fail_count + 1;
        end else
            $display("PASS TC3b: GPIO_DATA (SW=0x5A5A) = 0x00005A5A");

        // ════════════════════════════════════════════
        // TC4: err_flag가 쓰기/읽기 성공 후 클리어 상태 확인
        // ════════════════════════════════════════════
        repeat (5) @(posedge clk);
        if (err_flag !== 1'b0) begin
            $display("FAIL TC4: err_flag should be 0 after clean transactions");
            fail_count = fail_count + 1;
        end else
            $display("PASS TC4: err_flag = 0");

        // ════════════════════════════════════════════
        // 최종 판정
        // ════════════════════════════════════════════
        repeat (10) @(posedge clk);
        if (fail_count == 0)
            $display("PASS ALL: all %0d checks passed", 6);
        else
            $display("FAIL: %0d check(s) failed", fail_count);

        $finish;
    end

    // 타임아웃 가드
    initial begin
        #2000000;
        $display("FAIL TIMEOUT: simulation exceeded limit");
        $finish;
    end

endmodule
