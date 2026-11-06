// uart_rx.v — 8N1 UART 수신기
// 오버샘플링 x16, 보드레이트 분주기 외부 입력(baud_div)
// baud_div = clk_freq / (baud × 16)
// 115200 bps @ 100 MHz → baud_div = 54
// PASS/FAIL 자체 검증은 tb_uart_framing.v 에서 수행

`timescale 1ns/1ps
module uart_rx (
    input  wire        clk,
    input  wire        rst_n,
    // 보드레이트 분주기 (run-time 설정)
    input  wire [15:0] baud_div,    // 클럭 / (baud x16)
    // 직렬 입력
    input  wire        rx,
    // 출력
    output reg  [7:0]  rx_data,
    output reg         rx_valid     // 1클럭 strobe: 바이트 완료
);

// ── 분주 카운터 ──────────────────────────────────────────
reg [15:0] div_cnt;
reg        baud_tick;   // 1클럭 pulse, 16x baud

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_cnt   <= 16'd0;
        baud_tick <= 1'b0;
    end else begin
        if (div_cnt == baud_div - 1) begin
            div_cnt   <= 16'd0;
            baud_tick <= 1'b1;
        end else begin
            div_cnt   <= div_cnt + 16'd1;
            baud_tick <= 1'b0;
        end
    end
end

// ── FSM ───────────────────────────────────────────────────
localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0] state;
reg [3:0] tick_cnt;  // 0..15 오버샘플 카운터
reg [3:0] bit_idx;   // 0..7 데이터 비트 인덱스
reg [7:0] shift_reg;

// RX 2-단계 동기화 (메타스태빌리티 방지)
reg rx_s0, rx_s1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) { rx_s1, rx_s0 } <= 2'b11;
    else        { rx_s1, rx_s0 } <= { rx_s0, rx };
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        tick_cnt  <= 4'd0;
        bit_idx   <= 4'd0;
        shift_reg <= 8'd0;
        rx_data   <= 8'd0;
        rx_valid  <= 1'b0;
    end else begin
        rx_valid <= 1'b0;  // 기본은 Low

        case (state)
        IDLE: begin
            if (!rx_s1) begin          // 스타트 비트 에지 감지
                state    <= START;
                tick_cnt <= 4'd0;
            end
        end

        START: begin
            if (baud_tick) begin
                if (tick_cnt == 4'd7) begin  // 스타트 비트 중앙 샘플
                    if (!rx_s1) begin
                        state   <= DATA;
                        tick_cnt <= 4'd0;
                        bit_idx  <= 4'd0;
                    end else begin
                        state <= IDLE;  // 노이즈로 판단
                    end
                end else begin
                    tick_cnt <= tick_cnt + 4'd1;
                end
            end
        end

        DATA: begin
            if (baud_tick) begin
                if (tick_cnt == 4'd15) begin  // 각 비트 중앙(16번째 틱)
                    shift_reg <= {rx_s1, shift_reg[7:1]};  // LSB first
                    tick_cnt  <= 4'd0;
                    if (bit_idx == 4'd7) begin
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 4'd1;
                    end
                end else begin
                    tick_cnt <= tick_cnt + 4'd1;
                end
            end
        end

        STOP: begin
            if (baud_tick) begin
                if (tick_cnt == 4'd15) begin
                    if (rx_s1) begin           // 스톱 비트 확인
                        rx_data  <= shift_reg;
                        rx_valid <= 1'b1;
                    end
                    // 스톱 비트 오류 → 조용히 버림
                    state    <= IDLE;
                    tick_cnt <= 4'd0;
                end else begin
                    tick_cnt <= tick_cnt + 4'd1;
                end
            end
        end

        default: state <= IDLE;
        endcase
    end
end

endmodule
