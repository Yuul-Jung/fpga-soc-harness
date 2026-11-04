// i2s_clk_gen.v — I2S 클럭 계층 생성기 (순수 정수 분주기, sys_clk 동기)
// 입력: 100 MHz sys_clk
// 출력: MCLK 12.5 MHz (÷8), BCLK 3.125 MHz (÷32), LRCLK 97.656 kHz (÷1024)
// 클럭 비율: BCLK:MCLK = 1:4, BCLK/LRCLK = 32 (16비트 스테레오 LJ 포맷)
// 주의: Vivado에서 BCLK/MCLK/LRCLK를 generated clock으로 선언해야 타이밍 분석이 정확하다.
`timescale 1ns/1ps
module i2s_clk_gen (
    input  wire clk,    // 100 MHz 시스템 클럭
    input  wire rst,    // 동기 리셋 (active high)
    output wire mclk,   // 12.5 MHz = 100 MHz / 8
    output wire bclk,   // 3.125 MHz = 100 MHz / 32
    output wire lrclk   // 97.656 kHz = 100 MHz / 1024
);

    // --- MCLK: 토글 주기 4 sys_clk → 12.5 MHz ---
    reg [2:0] mclk_cnt;
    reg       mclk_r;
    always @(posedge clk) begin
        if (rst) begin
            mclk_cnt <= 3'd0;
            mclk_r   <= 1'b0;
        end else if (mclk_cnt == 3'd3) begin
            mclk_cnt <= 3'd0;
            mclk_r   <= ~mclk_r;
        end else begin
            mclk_cnt <= mclk_cnt + 3'd1;
        end
    end
    assign mclk = mclk_r;

    // --- BCLK: 토글 주기 16 sys_clk → 3.125 MHz ---
    reg [4:0] bclk_cnt;
    reg       bclk_r;
    always @(posedge clk) begin
        if (rst) begin
            bclk_cnt <= 5'd0;
            bclk_r   <= 1'b0;
        end else if (bclk_cnt == 5'd15) begin
            bclk_cnt <= 5'd0;
            bclk_r   <= ~bclk_r;
        end else begin
            bclk_cnt <= bclk_cnt + 5'd1;
        end
    end
    assign bclk = bclk_r;

    // --- LRCLK: 토글 주기 512 sys_clk → 97.656 kHz ---
    // 1 LRCLK 주기 = 1024 sys_clk = 32 BCLK 주기 = 16비트 × 2채널
    reg [9:0] lr_cnt;
    reg       lrclk_r;
    always @(posedge clk) begin
        if (rst) begin
            lr_cnt  <= 10'd0;
            lrclk_r <= 1'b0;
        end else if (lr_cnt == 10'd511) begin
            lr_cnt  <= 10'd0;
            lrclk_r <= ~lrclk_r;
        end else begin
            lr_cnt  <= lr_cnt + 10'd1;
        end
    end
    assign lrclk = lrclk_r;

endmodule
