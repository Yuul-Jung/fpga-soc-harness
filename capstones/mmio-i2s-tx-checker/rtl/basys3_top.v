// basys3_top.v — Basys3 보드 래퍼
// 2단 리셋 동기화 + i2s_clk_gen 인스턴스 + soc_top 연결
// Pmod JA 핀 배정 (Digilent 표준):
//   JA1 (J1)  → i2s_lrclk
//   JA2 (L2)  → i2s_sdin
//   JA4 (G2)  → i2s_mclk
//   JA7 (H1)  → i2s_bclk
`timescale 1ns/1ps
module basys3_top (
    input  wire        clk,        // 100 MHz 온보드 클럭 (W5)
    input  wire        btnC,       // 리셋 버튼 (U18)
    input  wire [15:0] sw,         // 슬라이드 스위치
    output wire [15:0] led,        // LED
    output wire        RsTx,       // UART TX → USB-UART
    // Pmod JA — I2S2 모듈
    output wire        i2s_mclk,   // JA4 (G2)
    output wire        i2s_bclk,   // JA7 (H1)
    output wire        i2s_lrclk,  // JA1 (J1)
    output wire        i2s_sdin    // JA2 (L2)
);

    // -------------------------------------------------------
    // 2단 리셋 동기화 (btnC → rst, active high)
    // -------------------------------------------------------
    reg rst_s1, rst_s2;
    wire rst = rst_s2;

    always @(posedge clk) begin
        rst_s1 <= btnC;
        rst_s2 <= rst_s1;
    end

    // -------------------------------------------------------
    // I2S 클럭 생성기
    // -------------------------------------------------------
    wire mclk_w, bclk_w, lrclk_w;

    i2s_clk_gen u_clkgen (
        .clk   (clk),
        .rst   (rst),
        .mclk  (mclk_w),
        .bclk  (bclk_w),
        .lrclk (lrclk_w)
    );

    // -------------------------------------------------------
    // SoC 코어
    // -------------------------------------------------------
    wire sdin_w;
    wire txd_w;

    soc_top u_soc (
        .clk   (clk),
        .rst   (rst),
        .mclk  (mclk_w),
        .bclk  (bclk_w),
        .lrclk (lrclk_w),
        .sw    (sw),
        .led   (led),
        .txd   (txd_w),
        .sdin  (sdin_w)
    );

    // -------------------------------------------------------
    // Pmod JA 출력 연결
    // -------------------------------------------------------
    assign i2s_mclk  = mclk_w;
    assign i2s_bclk  = bclk_w;
    assign i2s_lrclk = lrclk_w;
    assign i2s_sdin  = sdin_w;

    // -------------------------------------------------------
    // UART TX 연결
    // -------------------------------------------------------
    assign RsTx = txd_w;

endmodule
