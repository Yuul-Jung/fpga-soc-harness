/* mmio_bus.v — 단일 슬레이브 mmio-lite 버스 디코더
 * Origin: capstones/mmio-i2c-master-ip/rtl/mmio_bus.v
 * Verilog-2001.
 *
 * 주소 디코딩: 전체 주소 공간을 단일 슬레이브(I2C IP)에 연결.
 * rdata: 슬레이브가 cs=0일 때 32'd0 반환 가정.
 */
module mmio_bus (
    /* 마스터 포트 (CPU / demo_master) */
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output wire [31:0] m_rdata,
    input  wire        m_we,
    input  wire        m_valid,

    /* 슬레이브 0: I2C Master IP */
    output wire [15:0] s0_addr,
    output wire [31:0] s0_wdata,
    input  wire [31:0] s0_rdata,
    output wire        s0_we,
    output wire        s0_cs
);

/* 슬레이브 선택: 주소 비트[31:16]로 디코딩 (단일 슬레이브이므로 항상 선택) */
assign s0_cs    = m_valid;
assign s0_addr  = m_addr[15:0];
assign s0_wdata = m_wdata;
assign s0_we    = m_we;

assign m_rdata  = s0_cs ? s0_rdata : 32'd0;

endmodule
