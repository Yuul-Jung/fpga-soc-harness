// sccb_tx.v — SCCB (I2C-like) 마스터 송신기
// OV7670 카메라 레지스터 설정용 2선 직렬 프로토콜 FSM
// SCCB는 ACK 비트를 "don't care"(NA)로 취급하지만 이 구현은 감시한다.
// Verilog-2001, 외부 IP 없음.
//
// 인터페이스:
//   clk, rst  — 시스템 클럭(100 MHz), 동기 리셋
//   start     — 1클럭 펄스로 전송 시작
//   dev_addr  — 슬레이브 주소 7비트 [6:0]
//   reg_addr  — 레지스터 주소 8비트
//   reg_data  — 쓸 값 8비트
//   sio_c     — SCCB 클럭 출력
//   sio_d_out — SCCB 데이터 출력
//   sio_d_oe  — 데이터 선 출력 활성화 (0 = 하이임피던스 for NA 비트)
//   sio_d_in  — 데이터 선 입력 (NA 비트 감시)
//   done      — 전송 완료 1클럭 펄스
//   na_err    — NA 비트가 0(에러) 1클럭 펄스 (경고)

`default_nettype none
module sccb_tx #(
    parameter CLK_HZ   = 100_000_000,
    parameter SCCB_KHZ = 100          // 100 kHz (최대 400 kHz)
)(
    input  wire       clk, rst,
    input  wire       start,
    input  wire [6:0] dev_addr,
    input  wire [7:0] reg_addr,
    input  wire [7:0] reg_data,
    output reg        sio_c,
    output reg        sio_d_out,
    output reg        sio_d_oe,
    input  wire       sio_d_in,
    output reg        done,
    output reg        na_err
);
    // 클럭 분주: 1/4 주기(high, low 각 2단계)
    localparam HALF_CNT = (CLK_HZ / (SCCB_KHZ * 1000)) / 2;
    localparam CNT_W    = 10;

    // 보낼 비트 패킷: 1 START + (8+NA)*3위상 + 1 STOP = 29 비트 단계
    // 상태: IDLE, START, DATA, NA(x3), STOP, DONE
    localparam S_IDLE  = 3'd0;
    localparam S_START = 3'd1;
    localparam S_DATA  = 3'd2;
    localparam S_NA    = 3'd3;
    localparam S_STOP  = 3'd4;
    localparam S_DONE  = 3'd5;

    reg [2:0]      state;
    reg [CNT_W-1:0] cnt;       // 클럭 분주 카운터
    reg [4:0]      bit_idx;   // 0~7: 현재 바이트 비트, 8: NA
    reg [1:0]      byte_sel;  // 0=장치주소+W, 1=레지스터주소, 2=데이터
    reg [7:0]      shift_reg;
    reg            clk_phase; // 0=low절반, 1=high절반

    // 보낼 바이트 선택
    wire [7:0] cur_byte = (byte_sel == 2'd0) ? {dev_addr, 1'b0} :
                          (byte_sel == 2'd1) ? reg_addr : reg_data;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            sio_c     <= 1'b1;
            sio_d_out <= 1'b1;
            sio_d_oe  <= 1'b1;
            done      <= 1'b0;
            na_err    <= 1'b0;
            cnt       <= 0;
            bit_idx   <= 0;
            byte_sel  <= 0;
            clk_phase <= 0;
        end else begin
            done   <= 1'b0;
            na_err <= 1'b0;
            case (state)
                S_IDLE: begin
                    sio_c <= 1'b1; sio_d_out <= 1'b1; sio_d_oe <= 1'b1;
                    if (start) begin
                        state    <= S_START;
                        cnt      <= 0;
                        byte_sel <= 0;
                    end
                end
                S_START: begin
                    // START: SCL high, SDA: 1→0
                    sio_c     <= 1'b1;
                    sio_d_out <= (cnt < HALF_CNT/2) ? 1'b1 : 1'b0;
                    sio_d_oe  <= 1'b1;
                    if (cnt >= HALF_CNT - 1) begin
                        cnt       <= 0;
                        bit_idx   <= 7;
                        shift_reg <= cur_byte;
                        clk_phase <= 0;
                        state     <= S_DATA;
                        sio_c     <= 1'b0;
                    end else cnt <= cnt + 1;
                end
                S_DATA: begin
                    if (cnt < HALF_CNT - 1) begin
                        cnt <= cnt + 1;
                    end else begin
                        cnt       <= 0;
                        clk_phase <= ~clk_phase;
                        sio_c     <= clk_phase; // 토글
                        if (clk_phase) begin  // falling edge → 다음 비트 준비
                            if (bit_idx == 0) begin
                                // 8비트 완료 → NA 단계
                                state    <= S_NA;
                                sio_d_oe <= 1'b0;  // 릴리즈 (입력으로)
                            end else begin
                                bit_idx   <= bit_idx - 1;
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            end
                        end
                    end
                    sio_d_out <= shift_reg[7];
                    sio_d_oe  <= 1'b1;
                end
                S_NA: begin
                    sio_d_oe <= 1'b0;
                    if (cnt < HALF_CNT - 1) begin
                        cnt <= cnt + 1;
                    end else begin
                        cnt       <= 0;
                        clk_phase <= ~clk_phase;
                        sio_c     <= clk_phase;
                        if (clk_phase) begin  // falling
                            if (!sio_d_in) na_err <= 1'b1; // NA=0 에러
                            if (byte_sel == 2'd2) begin
                                state <= S_STOP;
                            end else begin
                                byte_sel  <= byte_sel + 1;
                                bit_idx   <= 7;
                                shift_reg <= (byte_sel == 2'd0) ? reg_addr : reg_data;
                                state     <= S_DATA;
                                sio_d_oe  <= 1'b1;
                            end
                        end
                    end
                end
                S_STOP: begin
                    // STOP: SCL high, SDA: 0→1
                    sio_c     <= 1'b1;
                    sio_d_oe  <= 1'b1;
                    sio_d_out <= (cnt >= HALF_CNT/2) ? 1'b1 : 1'b0;
                    if (cnt >= HALF_CNT - 1) begin
                        done  <= 1'b1;
                        state <= S_IDLE;
                        cnt   <= 0;
                    end else cnt <= cnt + 1;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
