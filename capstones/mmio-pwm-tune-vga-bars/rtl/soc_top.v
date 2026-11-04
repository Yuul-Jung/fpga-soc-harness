// SoC 코어: 마스터 포트(mmio-lite)를 밖으로 노출한다. 마스터는 데모 FSM, 테스트벤치, 나중에 CPU가 맡는다.
module soc_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output wire [31:0] m_rdata,
    output wire        m_ready,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire        pwm,
    output wire        amp_sd_n,
    output wire        tone,
    output wire        hsync,
    output wire        vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b
);
    wire        sel_gpio, sel_pwm, sel_vga;
    wire [31:0] rd_gpio, rd_pwm, rd_vga;

    mmio_bus u_bus (
        .valid(m_valid), .addr(m_addr),
        .sel_gpio(sel_gpio), .sel_pwm(sel_pwm), .sel_vga(sel_vga),
        .rdata_gpio(rd_gpio), .rdata_pwm(rd_pwm), .rdata_vga(rd_vga),
        .rdata(m_rdata), .ready(m_ready)
    );

    gpio u_gpio (
        .clk(clk), .rst(rst), .sel(sel_gpio), .we(m_we),
        .off(m_addr[7:0]), .wdata(m_wdata), .rdata(rd_gpio),
        .sw(sw), .led(led)
    );

    pwm_tone u_pwm (
        .clk(clk), .rst(rst), .sel(sel_pwm), .we(m_we),
        .off(m_addr[7:0]), .wdata(m_wdata), .rdata(rd_pwm),
        .pwm(pwm), .amp_sd_n(amp_sd_n), .tone(tone)
    );

    vga_bars u_vga (
        .clk(clk), .rst(rst), .sel(sel_vga), .we(m_we),
        .off(m_addr[7:0]), .wdata(m_wdata), .rdata(rd_vga),
        .hsync(hsync), .vsync(vsync), .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b)
    );
endmodule
