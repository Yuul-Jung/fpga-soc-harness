// demo_master.v — PS/2 키보드 폴링 마스터 FSM (Verilog-2001)
// 하네스 직접 작성 원본.
//
// 역할:
//   - PS/2 키보드 MMIO를 1사이클 단위로 폴링한다.
//   - 새 키(kbd_ready=1)가 오면 DATA 레지스터를 읽어 ASCII를 추출한다.
//   - make 이벤트(key_up=0, valid=1)이면:
//     - LED 하위 8비트에 ASCII를 표시한다.
//     - UART TX가 쉬면 ASCII를 UART로 송신한다.
//   - break 이벤트(key_up=1, valid=1)이면:
//     - LED를 클리어한다.
//
// 버스 주소 (mmio-lite 맵, addr[31:0] 기준):
//   0x1000_0000 : GPIO LED  (WO: wdata[15:0])
//   0x1001_0000 : UART TX DATA (WO: wdata[7:0])
//   0x1001_0004 : UART TX STATUS (RO: bit0=busy)
//   0x1002_0000 : KBD STATUS (RO: bit0=kbd_ready)
//   0x1002_0004 : KBD DATA   (RO: {22'h0, key_up, valid, ascii[7:0]})
`timescale 1ns/1ps
module demo_master (
    input  wire        clk,
    input  wire        rst,
    // 버스 마스터 포트
    output reg         valid,
    output reg         we,
    output reg  [31:0] addr,
    output reg  [31:0] wdata,
    input  wire [31:0] rdata,
    input  wire        ready
);
    // FSM 상태
    localparam
        S_POLL_KBD   = 4'd0,  // KBD STATUS 읽기 요청
        S_WAIT_KBD   = 4'd1,  // STATUS 응답 대기
        S_READ_DATA  = 4'd2,  // KBD DATA 읽기 요청
        S_WAIT_DATA  = 4'd3,  // DATA 응답 대기
        S_CHK_UART   = 4'd4,  // UART STATUS 읽기 요청
        S_WAIT_UART  = 4'd5,  // UART STATUS 대기
        S_SEND_UART  = 4'd6,  // UART DATA 쓰기
        S_LED_MAKE   = 4'd7,  // LED 쓰기 (make)
        S_LED_BREAK  = 4'd8,  // LED 클리어 (break)
        S_IDLE       = 4'd9;  // 짧은 대기 (다음 폴링 전)

    reg [3:0]  state;
    reg [7:0]  ascii_hold;
    reg        key_up_hold;
    reg [7:0]  idle_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= S_POLL_KBD;
            valid      <= 1'b0;
            we         <= 1'b0;
            addr       <= 32'h0;
            wdata      <= 32'h0;
            ascii_hold <= 8'h0;
            key_up_hold<= 1'b0;
            idle_cnt   <= 8'd0;
        end else begin
            case (state)
                // ---- KBD STATUS 읽기 ----
                S_POLL_KBD: begin
                    valid <= 1'b1;
                    we    <= 1'b0;
                    addr  <= 32'h1002_0000;
                    wdata <= 32'h0;
                    state <= S_WAIT_KBD;
                end
                S_WAIT_KBD: begin
                    if (ready) begin
                        valid <= 1'b0;
                        if (rdata[0]) begin
                            // kbd_ready=1 → DATA 읽기
                            state <= S_READ_DATA;
                        end else begin
                            // 아직 없음 → 짧은 대기 후 다시
                            state    <= S_IDLE;
                            idle_cnt <= 8'd4;
                        end
                    end
                end
                // ---- KBD DATA 읽기 ----
                S_READ_DATA: begin
                    valid <= 1'b1;
                    we    <= 1'b0;
                    addr  <= 32'h1002_0004;
                    wdata <= 32'h0;
                    state <= S_WAIT_DATA;
                end
                S_WAIT_DATA: begin
                    if (ready) begin
                        valid       <= 1'b0;
                        ascii_hold  <= rdata[7:0];
                        key_up_hold <= rdata[9];
                        // valid 비트(bit8)가 세트된 경우에만 처리
                        if (rdata[8]) begin
                            if (rdata[9]) begin
                                // key_up → LED 클리어
                                state <= S_LED_BREAK;
                            end else begin
                                // make → UART 전송 가능 여부 확인
                                state <= S_LED_MAKE;
                            end
                        end else begin
                            // valid=0이면 무효 → 다시 폴링
                            state    <= S_IDLE;
                            idle_cnt <= 8'd4;
                        end
                    end
                end
                // ---- LED 쓰기 (make) ----
                S_LED_MAKE: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= 32'h1000_0000;
                    wdata <= {24'h0, ascii_hold};
                    state <= S_CHK_UART;
                end
                // ---- UART STATUS 읽기 ----
                S_CHK_UART: begin
                    if (ready) begin
                        // LED 쓰기 완료, UART 상태 확인
                        valid <= 1'b1;
                        we    <= 1'b0;
                        addr  <= 32'h1001_0004;
                        wdata <= 32'h0;
                        state <= S_WAIT_UART;
                    end
                end
                S_WAIT_UART: begin
                    if (ready) begin
                        valid <= 1'b0;
                        if (!rdata[0]) begin
                            // busy=0 → 전송 가능
                            state <= S_SEND_UART;
                        end else begin
                            // 바쁨 → 잠시 대기
                            state    <= S_IDLE;
                            idle_cnt <= 8'd4;
                        end
                    end
                end
                // ---- UART DATA 쓰기 ----
                S_SEND_UART: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= 32'h1001_0000;
                    wdata <= {24'h0, ascii_hold};
                    state <= S_POLL_KBD;
                end
                // ---- LED 클리어 (break) ----
                S_LED_BREAK: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= 32'h1000_0000;
                    wdata <= 32'h0000_0000;
                    state <= S_POLL_KBD;
                end
                // ---- 짧은 대기 ----
                S_IDLE: begin
                    valid <= 1'b0;
                    if (idle_cnt == 8'd0) begin
                        state <= S_POLL_KBD;
                    end else begin
                        idle_cnt <= idle_cnt - 8'd1;
                    end
                end
                default: state <= S_POLL_KBD;
            endcase
        end
    end
endmodule
