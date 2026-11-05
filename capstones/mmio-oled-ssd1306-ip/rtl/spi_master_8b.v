// spi_master_8b.v — 8비트 SPI 마스터 (CPOL=0 CPHA=0)
// 하네스 원본. 외부 코드 복사 아님.
// SCK = clk / (2 * CLK_DIV)   예) CLK_DIV=10, 100MHz → 5MHz
// MSB first. start 펄스 1클럭으로 전송 시작, done 펄스 1클럭으로 완료 알림.
`default_nettype none
`timescale 1ns/1ps

module spi_master_8b #(
    parameter integer CLK_DIV = 10
) (
    input  wire       clk,
    input  wire       rst_n,
    // 제어
    input  wire       start,       // 1-clock 펄스: 전송 시작 (byte_data도 같은 클럭)
    input  wire [7:0] byte_data,
    output reg        busy,
    output reg        done,        // 1-clock 완료 펄스
    // SPI 버스 (CS·DC는 상위 모듈이 제어)
    output reg        sck,
    output reg        mosi
);

    // ── 분주 카운터 ──────────────────────────────────────
    localparam DIV_W = $clog2(CLK_DIV + 1);
    reg [DIV_W-1:0] div_cnt;
    wire            div_tick = (div_cnt == CLK_DIV - 1);

    // ── 비트/엣지 카운터 ─────────────────────────────────
    // 16 SCK 엣지: 짝수=rising, 홀수=falling
    reg [4:0] edge_cnt;   // 0..15 (16개)

    // ── 시프트 레지스터 ───────────────────────────────────
    reg [7:0] shreg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy     <= 1'b0;
            done     <= 1'b0;
            sck      <= 1'b0;
            mosi     <= 1'b0;
            div_cnt  <= '0;
            edge_cnt <= 5'd0;
            shreg    <= 8'd0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                sck     <= 1'b0;
                mosi    <= 1'b0;
                div_cnt <= '0;
                if (start) begin
                    shreg    <= byte_data;
                    edge_cnt <= 5'd0;
                    busy     <= 1'b1;
                    mosi     <= byte_data[7];  // CPHA=0: MSB 미리 출력
                end
            end else begin
                // 분주
                if (!div_tick) begin
                    div_cnt <= div_cnt + 1'b1;
                end else begin
                    div_cnt <= '0;
                    if (edge_cnt[0] == 1'b0) begin
                        // 짝수 → SCK 상승 엣지 (슬레이브가 샘플)
                        sck <= 1'b1;
                    end else begin
                        // 홀수 → SCK 하강 엣지
                        sck <= 1'b0;
                        if (edge_cnt < 5'd15) begin
                            // 다음 비트 출력: 비트 순서 [7→6→5→…→0]
                            // 하강 엣지 번호 = edge_cnt>>1 = 0..6 → 비트 [6..0]
                            shreg <= {shreg[6:0], 1'b0};
                            mosi  <= shreg[6];
                        end else begin
                            // 마지막 하강 (edge_cnt==15): 완료
                            mosi <= 1'b0;
                            busy <= 1'b0;
                            done <= 1'b1;
                        end
                    end
                    edge_cnt <= edge_cnt + 5'd1;
                end
            end
        end
    end

endmodule
`default_nettype wire
