// i2c_rd_byte.v — I2C 싱글 레지스터 읽기 엔진
// 하네스 직접 작성 Verilog-2001 원본. 외부 코드 미포함.
// 동작: START + (dev_addr<<1|0) + reg_addr + RSTART + (dev_addr<<1|1) + data_byte + NACK + STOP
// 비트 타이밍: CLK_DIV 클럭 1비트. Q1=CLK_DIV/4(SDA), Q2=CLK_DIV/2(SCL↑), Q3=3*CLK_DIV/4(샘플), Q4=CLK_DIV-1(SCL↓)

`default_nettype none
module i2c_rd_byte #(
    parameter CLK_DIV = 1000   // 100kHz @ 100MHz
) (
    input  wire       clk,
    input  wire       rst_n,
    // 제어
    input  wire       start,       // 1-pulse: 트랜잭션 시작
    input  wire [6:0] dev_addr,    // 7비트 슬레이브 주소
    input  wire [7:0] reg_addr,    // 읽을 레지스터
    // 결과
    output reg        done,        // 1-pulse: 완료(NACK/timeout 포함)
    output reg  [7:0] data_out,    // 읽은 바이트
    output reg        ack_err,     // 1=ACK 없음(NACK 또는 timeout)
    // I2C 버스 (오픈 드레인 에뮬레이션)
    output reg        scl_out,     // 1=Hi-Z, 0=drive low
    output reg        sda_out,     // 1=Hi-Z, 0=drive low
    input  wire       sda_in       // 버스 SDA 읽기
);

// ── 타이밍 상수 ──────────────────────────────────────────
localparam integer P_Q1  = CLK_DIV / 4;
localparam integer P_Q2  = CLK_DIV / 2;
localparam integer P_Q3  = (CLK_DIV * 3) / 4;
localparam integer P_END = CLK_DIV - 1;

// ── FSM 상태 ─────────────────────────────────────────────
localparam [4:0]
    S_IDLE    = 5'd0,
    S_START   = 5'd1,   // START 조건
    S_WA      = 5'd2,   // 쓰기 주소 (dev_addr<<1|0)
    S_WA_AK   = 5'd3,   // 쓰기 주소 ACK
    S_RA      = 5'd4,   // 레지스터 주소
    S_RA_AK   = 5'd5,   // 레지스터 주소 ACK
    S_RSTART  = 5'd6,   // 반복 START
    S_RD      = 5'd7,   // 읽기 주소 (dev_addr<<1|1)
    S_RD_AK   = 5'd8,   // 읽기 주소 ACK
    S_DATA    = 5'd9,   // 8비트 데이터 수신
    S_NACK    = 5'd10,  // 마스터 NACK 송출
    S_STOP    = 5'd11,  // STOP 조건
    S_DONE    = 5'd12;

reg [4:0] state;
reg [11:0] clk_cnt;   // CLK_DIV≤4095 가정 (최대 10bit면 충분, 여유 12bit)
reg [3:0]  bit_cnt;   // 비트 카운터 (0~7)
reg [7:0]  shift;     // TX/RX 시프트 레지스터

// 현재 클럭 위상 판단 (combinational)
wire phase_q1  = (clk_cnt == P_Q1[11:0]);
wire phase_q2  = (clk_cnt == P_Q2[11:0]);
wire phase_q3  = (clk_cnt == P_Q3[11:0]);
wire phase_end = (clk_cnt == P_END[11:0]);

// ── 메인 FSM ─────────────────────────────────────────────
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= S_IDLE;
        clk_cnt  <= 12'd0;
        bit_cnt  <= 4'd0;
        shift    <= 8'd0;
        scl_out  <= 1'b1;
        sda_out  <= 1'b1;
        done     <= 1'b0;
        data_out <= 8'd0;
        ack_err  <= 1'b0;
    end else begin
        done <= 1'b0;  // 기본 1사이클 펄스

        case (state)

        // ── IDLE ─────────────────────────────────────────
        S_IDLE: begin
            scl_out <= 1'b1; sda_out <= 1'b1;
            if (start) begin
                shift   <= {dev_addr, 1'b0};  // addr + W
                bit_cnt <= 4'd7;
                clk_cnt <= 12'd0;
                state   <= S_START;
            end
        end

        // ── START 조건: SCL Hi인 상태에서 SDA ↓ ─────────
        S_START: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b0;
            if (phase_q2) scl_out <= 1'b0;
            if (phase_end) begin
                clk_cnt <= 12'd0;
                state   <= S_WA;
            end
        end

        // ── 쓰기 주소 비트 송출 ───────────────────────────
        S_WA: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= shift[7];
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) begin  // 샘플 포인트 (필요 없지만 대칭성)
                /* TX: 슬레이브가 샘플 */
            end
            if (phase_end) begin
                scl_out <= 1'b0;
                shift   <= {shift[6:0], 1'b0};
                clk_cnt <= 12'd0;
                if (bit_cnt == 4'd0) begin
                    state <= S_WA_AK;
                end else begin
                    bit_cnt <= bit_cnt - 4'd1;
                end
            end
        end

        // ── 쓰기 주소 ACK 수신 ───────────────────────────
        S_WA_AK: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b1;  // 릴리즈
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) ack_err <= sda_in; // SDA Hi = NACK
            if (phase_end) begin
                scl_out <= 1'b0;
                clk_cnt <= 12'd0;
                if (ack_err) begin
                    state <= S_STOP;
                end else begin
                    shift   <= reg_addr;
                    bit_cnt <= 4'd7;
                    state   <= S_RA;
                end
            end
        end

        // ── 레지스터 주소 비트 송출 ──────────────────────
        S_RA: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= shift[7];
            if (phase_q2) scl_out <= 1'b1;
            if (phase_end) begin
                scl_out <= 1'b0;
                shift   <= {shift[6:0], 1'b0};
                clk_cnt <= 12'd0;
                if (bit_cnt == 4'd0) begin
                    state <= S_RA_AK;
                end else begin
                    bit_cnt <= bit_cnt - 4'd1;
                end
            end
        end

        // ── 레지스터 주소 ACK 수신 ───────────────────────
        S_RA_AK: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b1;
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) ack_err <= sda_in;
            if (phase_end) begin
                scl_out <= 1'b0;
                clk_cnt <= 12'd0;
                if (ack_err) begin
                    state <= S_STOP;
                end else begin
                    state <= S_RSTART;
                end
            end
        end

        // ── 반복 START ───────────────────────────────────
        S_RSTART: begin
            clk_cnt <= clk_cnt + 12'd1;
            // SDA Hi → SCL Hi → SDA Lo
            if (phase_q1) sda_out <= 1'b1;
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) sda_out <= 1'b0;
            if (phase_end) begin
                scl_out <= 1'b0;
                shift   <= {dev_addr, 1'b1};  // addr + R
                bit_cnt <= 4'd7;
                clk_cnt <= 12'd0;
                state   <= S_RD;
            end
        end

        // ── 읽기 주소 비트 송출 ──────────────────────────
        S_RD: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= shift[7];
            if (phase_q2) scl_out <= 1'b1;
            if (phase_end) begin
                scl_out <= 1'b0;
                shift   <= {shift[6:0], 1'b0};
                clk_cnt <= 12'd0;
                if (bit_cnt == 4'd0) begin
                    state <= S_RD_AK;
                end else begin
                    bit_cnt <= bit_cnt - 4'd1;
                end
            end
        end

        // ── 읽기 주소 ACK 수신 ───────────────────────────
        S_RD_AK: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b1;
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) ack_err <= sda_in;
            if (phase_end) begin
                scl_out <= 1'b0;
                clk_cnt <= 12'd0;
                if (ack_err) begin
                    state <= S_STOP;
                end else begin
                    bit_cnt <= 4'd7;
                    state   <= S_DATA;
                end
            end
        end

        // ── 8비트 데이터 수신 ────────────────────────────
        S_DATA: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b1;  // 릴리즈 (입력)
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) shift <= {shift[6:0], sda_in};  // MSB 먼저
            if (phase_end) begin
                scl_out <= 1'b0;
                clk_cnt <= 12'd0;
                if (bit_cnt == 4'd0) begin
                    data_out <= shift;
                    state    <= S_NACK;
                end else begin
                    bit_cnt <= bit_cnt - 4'd1;
                end
            end
        end

        // ── 마스터 NACK 송출 ─────────────────────────────
        S_NACK: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b1;  // NACK = SDA Hi
            if (phase_q2) scl_out <= 1'b1;
            if (phase_end) begin
                scl_out <= 1'b0;
                clk_cnt <= 12'd0;
                state   <= S_STOP;
            end
        end

        // ── STOP 조건: SCL Hi인 상태에서 SDA ↑ ─────────
        S_STOP: begin
            clk_cnt <= clk_cnt + 12'd1;
            if (phase_q1) sda_out <= 1'b0;
            if (phase_q2) scl_out <= 1'b1;
            if (phase_q3) sda_out <= 1'b1;
            if (phase_end) begin
                clk_cnt <= 12'd0;
                state   <= S_DONE;
            end
        end

        // ── DONE ─────────────────────────────────────────
        S_DONE: begin
            done  <= 1'b1;
            state <= S_IDLE;
        end

        default: state <= S_IDLE;
        endcase
    end
end

endmodule
`default_nettype wire
