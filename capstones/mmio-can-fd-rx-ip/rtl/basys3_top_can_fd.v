// basys3_top_can_fd.v — Basys3 최상위 래퍼 (CAN FD RX IP)
// 클럭 W5(100 MHz), 리셋 U18(액티브 로우 BTN0), CAN RX L2(Pmod JA pin2)
// AXI4-Lite 마스터 포트를 밖으로 노출해 CPU 연결 지점으로 둔다.

`timescale 1ns/1ps

module basys3_top_can_fd (
    // Basys3 보드 핀
    input  wire        clk_100mhz,   // W5
    input  wire        rst_n_btn,    // U18 (BTN0, 액티브 로우)
    input  wire        can_rx_pin,   // L2 (Pmod JA pin2, 트랜시버 RXD)

    // AXI4-Lite 마스터 포트 (CPU 연결 지점)
    // Write address channel
    input  wire [31:0] m_awaddr,     // CPU → slave
    input  wire        m_awvalid,
    output wire        m_awready,    // slave → CPU
    // Write data channel
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    input  wire        m_wvalid,
    output wire        m_wready,
    // Write response channel
    output wire [1:0]  m_bresp,
    output wire        m_bvalid,
    input  wire        m_bready,
    // Read address channel
    input  wire [31:0] m_araddr,
    input  wire        m_arvalid,
    output wire        m_arready,
    // Read data channel
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,
    output wire        m_rvalid,
    input  wire        m_rready
);

    // ------------------------------------------------------------------
    // IBUFG 클럭 버퍼
    // ------------------------------------------------------------------
    wire clk;
    IBUFG u_clkbuf (
        .I (clk_100mhz),
        .O (clk)
    );

    // ------------------------------------------------------------------
    // 동기 리셋 (버튼 액티브 로우 → aresetn 액티브 로우)
    // ------------------------------------------------------------------
    reg [1:0] rst_sync;
    wire aresetn = rst_sync[1];

    always @(posedge clk or negedge rst_n_btn) begin
        if (!rst_n_btn)
            rst_sync <= 2'b00;
        else
            rst_sync <= {rst_sync[0], 1'b1};
    end

    // ------------------------------------------------------------------
    // axil_can_fd_rx 인스턴스
    // AXI4-Lite 슬레이브 주소 폭 6비트 (0x00~0x34)
    // ------------------------------------------------------------------
    axil_can_fd_rx #(
        .DATA_W      (32),
        .ADDR_W      (6),
        .CLK_PER_BIT (200),   // 100 MHz / 500 kbit/s
        .SAMPLE_PT   (150)    // 75% 샘플 포인트
    ) u_can_rx (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (aresetn),
        // Write address
        .s_axi_awaddr  (m_awaddr[5:0]),
        .s_axi_awvalid (m_awvalid),
        .s_axi_awready (m_awready),
        // Write data
        .s_axi_wdata   (m_wdata),
        .s_axi_wstrb   (m_wstrb),
        .s_axi_wvalid  (m_wvalid),
        .s_axi_wready  (m_wready),
        // Write response
        .s_axi_bresp   (m_bresp),
        .s_axi_bvalid  (m_bvalid),
        .s_axi_bready  (m_bready),
        // Read address
        .s_axi_araddr  (m_araddr[5:0]),
        .s_axi_arvalid (m_arvalid),
        .s_axi_arready (m_arready),
        // Read data
        .s_axi_rdata   (m_rdata),
        .s_axi_rresp   (m_rresp),
        .s_axi_rvalid  (m_rvalid),
        .s_axi_rready  (m_rready),
        // CAN 수신
        .can_rx        (can_rx_pin)
    );

    // ------------------------------------------------------------------
    // 미사용 상위 주소 비트 억제 (Verilator -Wall)
    // ------------------------------------------------------------------
    wire _unused_top = &{1'b0, m_awaddr[31:6], m_araddr[31:6], 1'b0};

endmodule
