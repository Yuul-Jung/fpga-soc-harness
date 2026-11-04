/* soc_top.v — SoC 코어 (I2C Master 데모)
 * Origin: capstones/mmio-i2c-master-ip/rtl/soc_top.v
 * Verilog-2001.
 *
 * 구성: demo_master → mmio_bus → i2c_master_ip
 * CPU 없이 demo_master FSM이 MMIO를 직접 구동한다.
 */
module soc_top #(
    parameter CLK_DIV = 1000
)(
    input  wire       clk,
    input  wire       rst_n,
    /* I2C 오픈드레인 출력 */
    output wire       scl_o,
    output wire       sda_o,
    input  wire       sda_i,
    /* 결과 LED */
    output wire [7:0] led
);

/* --- 내부 버스 신호 --- */
wire [31:0] m_addr, m_wdata, m_rdata;
wire        m_we, m_valid;

wire [15:0] s0_addr;
wire [31:0] s0_wdata, s0_rdata;
wire        s0_we, s0_cs;
wire        i2c_irq;

/* --- 인스턴스 --- */
demo_master u_demo (
    .clk     (clk),
    .rst_n   (rst_n),
    .m_addr  (m_addr),
    .m_wdata (m_wdata),
    .m_rdata (m_rdata),
    .m_we    (m_we),
    .m_valid (m_valid),
    .led     (led)
);

mmio_bus u_bus (
    .m_addr   (m_addr),
    .m_wdata  (m_wdata),
    .m_rdata  (m_rdata),
    .m_we     (m_we),
    .m_valid  (m_valid),
    .s0_addr  (s0_addr),
    .s0_wdata (s0_wdata),
    .s0_rdata (s0_rdata),
    .s0_we    (s0_we),
    .s0_cs    (s0_cs)
);

i2c_master_ip #(.CLK_DIV(CLK_DIV)) u_i2c (
    .clk        (clk),
    .rst_n      (rst_n),
    .mmio_addr  (s0_addr),
    .mmio_wdata (s0_wdata),
    .mmio_rdata (s0_rdata),
    .mmio_we    (s0_we),
    .mmio_cs    (s0_cs),
    .scl_o      (scl_o),
    .sda_o      (sda_o),
    .sda_i      (sda_i),
    .irq        (i2c_irq)
);

endmodule
