// mmio_bus.v — MMIO-lite 주소 디코더 / 버스 MUX (3 슬레이브)
// addr[31:16] 기준 슬레이브 선택:
//   0x1000 → GPIO
//   0x1001 → UART
//   0x1002 → MOTOR_SAFETY
// ready는 항상 1 (1사이클 응답, back-pressure 없음)

`default_nettype none

module mmio_bus (
    // 마스터 → 버스
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output reg  [31:0] m_rdata,
    output wire        m_ready,

    // 슬레이브 0 — GPIO
    output wire        s0_valid,
    output wire        s0_we,
    output wire [31:0] s0_addr,
    output wire [31:0] s0_wdata,
    input  wire [31:0] s0_rdata,

    // 슬레이브 1 — UART
    output wire        s1_valid,
    output wire        s1_we,
    output wire [31:0] s1_addr,
    output wire [31:0] s1_wdata,
    input  wire [31:0] s1_rdata,

    // 슬레이브 2 — MOTOR_SAFETY
    output wire        s2_valid,
    output wire        s2_we,
    output wire [31:0] s2_addr,
    output wire [31:0] s2_wdata,
    input  wire [31:0] s2_rdata
);

    wire sel0 = (m_addr[31:16] == 16'h1000);
    wire sel1 = (m_addr[31:16] == 16'h1001);
    wire sel2 = (m_addr[31:16] == 16'h1002);

    assign s0_valid = m_valid & sel0;
    assign s1_valid = m_valid & sel1;
    assign s2_valid = m_valid & sel2;

    assign s0_we    = m_we;
    assign s1_we    = m_we;
    assign s2_we    = m_we;

    assign s0_addr  = m_addr;
    assign s1_addr  = m_addr;
    assign s2_addr  = m_addr;

    assign s0_wdata = m_wdata;
    assign s1_wdata = m_wdata;
    assign s2_wdata = m_wdata;

    assign m_ready  = 1'b1;

    always @(*) begin
        if      (sel0) m_rdata = s0_rdata;
        else if (sel1) m_rdata = s1_rdata;
        else if (sel2) m_rdata = s2_rdata;
        else           m_rdata = 32'd0;
    end

endmodule

`default_nettype wire
