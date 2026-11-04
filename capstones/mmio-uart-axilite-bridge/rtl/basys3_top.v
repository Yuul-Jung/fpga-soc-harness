// basys3_top.v — Basys3 최상위 래퍼 + demo_gpio_slave
//
// 핀 배정:
//   clk        W5   100 MHz 보드 클럭
//   rst        W19  btnC 액티브 하이 리셋
//   uart_rxd   D4   USB-UART RXD (PC→FPGA)
//   uart_txd   C4   USB-UART TXD (FPGA→PC)
//   led[15:0]  V17–U1  상태 LED
//   sw[15:0]   V17–U1 범위 외  슬라이드 스위치
//
// 출처: 하네스 직접 작성 원본. 외부 코드 없음.

`timescale 1ns/1ps

// ─────────────────────────────────────────────
// demo_gpio_slave — AXI4-Lite 슬레이브 (데모 전용)
//
// 오프셋  이름        접근  설명
//  0x0000  GPIO_DATA   RW   쓰기→led_reg, 읽기→sw
//  0x0004  GPIO_DIR    RO   항상 0xFFFF0000
// ─────────────────────────────────────────────
module demo_gpio_slave (
    input  wire        clk,
    input  wire        rst,

    // AXI4-Lite 슬레이브 포트
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,

    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,

    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,

    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,

    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // GPIO
    input  wire [15:0] sw,
    output reg  [15:0] led_reg
);
    // 쓰기 주소 래치
    reg [31:0] aw_addr_lat;
    reg        aw_latched;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_awready  <= 1'b1;
            s_wready   <= 1'b1;
            s_bvalid   <= 1'b0;
            s_bresp    <= 2'b00;
            s_arready  <= 1'b0;
            s_rvalid   <= 1'b0;
            s_rdata    <= 32'h0;
            s_rresp    <= 2'b00;
            led_reg    <= 16'h0;
            aw_addr_lat<= 32'h0;
            aw_latched <= 1'b0;
        end else begin
            // ── 쓰기 ──────────────────────────────────────
            // AW 채널
            if (s_awvalid && s_awready) begin
                aw_addr_lat <= s_awaddr;
                aw_latched  <= 1'b1;
                s_awready   <= 1'b0;
            end
            // W 채널
            if (s_wvalid && s_wready) begin
                if (aw_latched || (s_awvalid && s_awready)) begin
                    // GPIO_DATA (오프셋 0x0000)
                    if ((aw_latched ? aw_addr_lat[3:0] : s_awaddr[3:0]) == 4'h0) begin
                        if (s_wstrb[0]) led_reg[ 7:0] <= s_wdata[ 7:0];
                        if (s_wstrb[1]) led_reg[15:8] <= s_wdata[15:8];
                    end
                    // GPIO_DIR (오프셋 0x0004)는 RO, 무시
                end
                s_wready   <= 1'b0;
                s_bvalid   <= 1'b1;
                s_bresp    <= 2'b00;
                aw_latched <= 1'b0;
            end
            // B 채널
            if (s_bvalid && s_bready) begin
                s_bvalid  <= 1'b0;
                s_awready <= 1'b1;
                s_wready  <= 1'b1;
            end

            // ── 읽기 ──────────────────────────────────────
            if (!s_arready) begin
                s_arready <= 1'b1;
            end
            if (s_arvalid && s_arready) begin
                s_arready <= 1'b0;
                s_rvalid  <= 1'b1;
                s_rresp   <= 2'b00;
                case (s_araddr[3:0])
                    4'h0:    s_rdata <= {16'h0, sw};         // GPIO_DATA: 읽기→SW
                    4'h4:    s_rdata <= 32'hFFFF0000;         // GPIO_DIR
                    default: s_rdata <= 32'h0;
                endcase
            end
            if (s_rvalid && s_rready) begin
                s_rvalid  <= 1'b0;
                s_arready <= 1'b1;
            end
        end
    end
endmodule


// ─────────────────────────────────────────────
// basys3_top — 최상위 래퍼
// ─────────────────────────────────────────────
module basys3_top (
    input  wire        clk,       // W5  100 MHz
    input  wire        rst,       // W19 btnC (액티브 하이)

    input  wire        uart_rxd,  // D4  USB-UART RXD
    output wire        uart_txd,  // C4  USB-UART TXD

    input  wire [15:0] sw,        // 슬라이드 스위치
    output wire [15:0] led        // LED
);
    // ── AXI4-Lite 버스 신호 ──────────────────────
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

    // ── 브리지 인스턴스 ──────────────────────────
    uart_axilite_bridge #(.BAUD_DIV(868)) u_bridge (
        .clk        (clk),
        .rst        (rst),
        .uart_rx_pin(uart_rxd),
        .uart_tx_pin(uart_txd),
        .m_awaddr   (m_awaddr),   .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata    (m_wdata),    .m_wstrb  (m_wstrb),
        .m_wvalid   (m_wvalid),   .m_wready (m_wready),
        .m_bresp    (m_bresp),    .m_bvalid (m_bvalid),  .m_bready (m_bready),
        .m_araddr   (m_araddr),   .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_rdata    (m_rdata),    .m_rresp  (m_rresp),
        .m_rvalid   (m_rvalid),   .m_rready (m_rready),
        .busy       (busy),
        .err_flag   (err_flag)
    );

    // ── GPIO 슬레이브 인스턴스 ───────────────────
    demo_gpio_slave u_gpio (
        .clk      (clk),
        .rst      (rst),
        .s_awaddr (m_awaddr),  .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata  (m_wdata),   .s_wstrb  (m_wstrb),
        .s_wvalid (m_wvalid),  .s_wready (m_wready),
        .s_bresp  (m_bresp),   .s_bvalid (m_bvalid),  .s_bready (m_bready),
        .s_araddr (m_araddr),  .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata  (m_rdata),   .s_rresp  (m_rresp),
        .s_rvalid (m_rvalid),  .s_rready (m_rready),
        .sw       (sw),
        .led_reg  (gpio_led)
    );

    // LED 배선: [0]=busy [1]=err_flag [15:2]=gpio_led[15:2]
    assign led[0]    = busy;
    assign led[1]    = err_flag;
    assign led[15:2] = gpio_led[15:2];

endmodule
