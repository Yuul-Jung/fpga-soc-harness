// soc_top.v — SoC 최상위: demo_master + mmio_bus + gpio + uart_tx + i2s_tx
// mmio-lite 마스터(demo_master)가 단일 마스터로 세 슬레이브를 구동한다.
// I2S 클럭(mclk, bclk, lrclk)은 basys3_top의 i2s_clk_gen에서 공급받는다.
`timescale 1ns/1ps
module soc_top (
    input  wire        clk,
    input  wire        rst,
    // I2S 클럭 (basys3_top에서 공급)
    input  wire        mclk,
    input  wire        bclk,
    input  wire        lrclk,
    // GPIO
    input  wire [15:0] sw,
    output wire [15:0] led,
    // UART
    output wire        txd,
    // I2S 출력
    output wire        sdin
);

    // -------------------------------------------------------
    // mmio-lite 버스 신호
    // -------------------------------------------------------
    wire        m_valid;
    wire        m_we;
    wire [31:0] m_addr;
    wire [31:0] m_wdata;
    wire [31:0] m_rdata;
    wire        m_ready;

    // -------------------------------------------------------
    // 슬레이브 선택 신호
    // -------------------------------------------------------
    wire        sel_gpio, sel_uart, sel_i2s;

    // -------------------------------------------------------
    // 슬레이브 읽기 데이터
    // -------------------------------------------------------
    wire [31:0] rdata_gpio, rdata_uart, rdata_i2s;

    // -------------------------------------------------------
    // IRQ (내부에서만 사용, lint 억제)
    // -------------------------------------------------------
    wire        irq_i2s;
    // verilator lint_off UNUSED
    wire _unused_irq = irq_i2s;
    // verilator lint_on UNUSED

    // -------------------------------------------------------
    // 인스턴스
    // -------------------------------------------------------

    // 마스터: I2S 초기화 및 IRQ 폴링 FSM
    demo_master u_master (
        .clk     (clk),
        .rst     (rst),
        .m_valid (m_valid),
        .m_we    (m_we),
        .m_addr  (m_addr),
        .m_wdata (m_wdata),
        .m_rdata (m_rdata),
        .m_ready (m_ready)
    );

    // 주소 디코더: addr[31:16] 기준 64KB 창
    mmio_bus u_bus (
        .valid      (m_valid),
        .we         (m_we),
        .addr       (m_addr),
        .wdata      (m_wdata),
        .sel_gpio   (sel_gpio),
        .sel_uart   (sel_uart),
        .sel_i2s    (sel_i2s),
        .rdata_gpio (rdata_gpio),
        .rdata_uart (rdata_uart),
        .rdata_i2s  (rdata_i2s),
        .rdata      (m_rdata),
        .ready      (m_ready)
    );

    // GPIO 슬레이브 (8비트 오프셋)
    gpio u_gpio (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_gpio),
        .we    (m_we),
        .off   (m_addr[7:0]),
        .wdata (m_wdata),
        .rdata (rdata_gpio),
        .sw    (sw),
        .led   (led)
    );

    // UART TX 슬레이브 (8비트 오프셋)
    uart_tx u_uart (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_uart),
        .we    (m_we),
        .off   (m_addr[7:0]),
        .wdata (m_wdata),
        .rdata (rdata_uart),
        .txd   (txd)
    );

    // I2S TX 슬레이브 (16비트 오프셋, 0xFFF0~FFFC mgmt 레지스터 접근용)
    i2s_tx u_i2s (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_i2s),
        .we    (m_we),
        .off   (m_addr[15:0]),
        .wdata (m_wdata),
        .rdata (rdata_i2s),
        .mclk  (mclk),
        .bclk  (bclk),
        .lrclk (lrclk),
        .sdin  (sdin),
        .irq   (irq_i2s)
    );

endmodule
