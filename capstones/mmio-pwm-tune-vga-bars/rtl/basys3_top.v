// Basys3 최상위: btnC=리셋, btnU=8음 재생 시작. 스위치 SW[7:0]=음량. Pmod AMP2는 JA, VGA는 보드 커넥터.
module basys3_top (
    input  wire        clk,
    input  wire        btnC,
    input  wire        btnU,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire        amp_pwm,
    output wire        amp_gain,
    output wire        amp_sd_n,
    output wire        Hsync,
    output wire        Vsync,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue
);
    reg r1 = 1'b0, r2 = 1'b0;
    always @(posedge clk) begin
        r1 <= btnC;
        r2 <= r1;
    end
    wire rst = r2;

    wire        m_valid, m_we, m_ready;
    wire [31:0] m_addr, m_wdata, m_rdata;
    wire        tone_unused;

    assign amp_gain = 1'b0;   // Pmod AMP2 저이득

    demo_master u_master (
        .clk(clk), .rst(rst), .btn(btnU),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready)
    );

    soc_top u_soc (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(sw), .led(led),
        .pwm(amp_pwm), .amp_sd_n(amp_sd_n), .tone(tone_unused),
        .hsync(Hsync), .vsync(Vsync), .vga_r(vgaRed), .vga_g(vgaGreen), .vga_b(vgaBlue)
    );
endmodule
