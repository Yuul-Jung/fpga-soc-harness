// ps2_kbd.v — PS/2 키보드 디코더 + MMIO 슬레이브 (Verilog-2001)
// 하네스 직접 작성 원본.
//
// 역할:
//   - ps2_rx에서 스캔코드를 받아 make/break 시퀀스를 처리한다.
//   - 스캔코드를 ASCII로 변환한다.
//   - MMIO 레지스터 인터페이스를 제공한다.
//
// PS/2 Set 2 특수 코드:
//   0xF0 : Break prefix (다음 바이트는 뗌 코드)
//   0xE0 : Extended key prefix (여기서는 무시)
//
// MMIO 레지스터 (오프셋 7:0 기준):
//   0x00 STATUS : {31'h0, kbd_ready}   kbd_ready=1 → 새 문자 수신
//   0x04 DATA   : {22'h0, key_up, valid, ascii[7:0]}
//                 key_up=1 → 키 뗌(break), valid=1 → ASCII 유효
//                 DATA를 읽으면 kbd_ready가 클리어된다.
`timescale 1ns/1ps
module ps2_kbd (
    input  wire       clk,
    input  wire       rst,
    // ps2_rx 입력
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    // verilator lint_off UNUSED
    input  wire       rx_err,   // 오류 카운트용 (현재 버전은 무시)
    // verilator lint_on UNUSED
    // MMIO 슬레이브 인터페이스
    input  wire       sel,
    input  wire       we,
    input  wire [7:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // 인터럽트 (선택 — 현재 버전은 출력만)
    output wire       irq
);
    // verilator lint_off UNUSED
    wire [31:0] _unused_wdata = wdata;
    // verilator lint_on UNUSED

    // ----------------------------------------------------------------
    // 스캔코드 → ASCII 함수
    // ----------------------------------------------------------------
    function [7:0] scan_to_ascii;
        input [7:0] sc;
        case (sc)
            8'h1C: scan_to_ascii = 8'h61; // a
            8'h32: scan_to_ascii = 8'h62; // b
            8'h21: scan_to_ascii = 8'h63; // c
            8'h23: scan_to_ascii = 8'h64; // d
            8'h24: scan_to_ascii = 8'h65; // e
            8'h2B: scan_to_ascii = 8'h66; // f
            8'h34: scan_to_ascii = 8'h67; // g
            8'h33: scan_to_ascii = 8'h68; // h
            8'h43: scan_to_ascii = 8'h69; // i
            8'h3B: scan_to_ascii = 8'h6A; // j
            8'h42: scan_to_ascii = 8'h6B; // k
            8'h4B: scan_to_ascii = 8'h6C; // l
            8'h3A: scan_to_ascii = 8'h6D; // m
            8'h31: scan_to_ascii = 8'h6E; // n
            8'h44: scan_to_ascii = 8'h6F; // o
            8'h4D: scan_to_ascii = 8'h70; // p
            8'h15: scan_to_ascii = 8'h71; // q
            8'h2D: scan_to_ascii = 8'h72; // r
            8'h1B: scan_to_ascii = 8'h73; // s
            8'h2C: scan_to_ascii = 8'h74; // t
            8'h3C: scan_to_ascii = 8'h75; // u
            8'h2A: scan_to_ascii = 8'h76; // v
            8'h1D: scan_to_ascii = 8'h77; // w
            8'h22: scan_to_ascii = 8'h78; // x
            8'h35: scan_to_ascii = 8'h79; // y
            8'h1A: scan_to_ascii = 8'h7A; // z
            8'h45: scan_to_ascii = 8'h30; // 0
            8'h16: scan_to_ascii = 8'h31; // 1
            8'h1E: scan_to_ascii = 8'h32; // 2
            8'h26: scan_to_ascii = 8'h33; // 3
            8'h25: scan_to_ascii = 8'h34; // 4
            8'h2E: scan_to_ascii = 8'h35; // 5
            8'h36: scan_to_ascii = 8'h36; // 6
            8'h3D: scan_to_ascii = 8'h37; // 7
            8'h3E: scan_to_ascii = 8'h38; // 8
            8'h46: scan_to_ascii = 8'h39; // 9
            8'h29: scan_to_ascii = 8'h20; // space
            8'h5A: scan_to_ascii = 8'h0D; // Enter (CR)
            8'h66: scan_to_ascii = 8'h08; // Backspace
            8'h76: scan_to_ascii = 8'h1B; // Escape
            8'h0D: scan_to_ascii = 8'h09; // Tab
            default: scan_to_ascii = 8'h00; // 미지원
        endcase
    endfunction

    // ----------------------------------------------------------------
    // 디코더 FSM
    //   IDLE     : 일반 make 코드 대기
    //   BREAK    : F0 받음, 다음 바이트는 break 코드
    //   EXTENDED : E0 받음, 다음 바이트를 무시 (simple version)
    // ----------------------------------------------------------------
    localparam S_IDLE = 2'd0, S_BREAK = 2'd1, S_EXTENDED = 2'd2;
    reg [1:0] state;

    // 출력 레지스터
    reg       kbd_ready;
    reg [7:0] ascii_buf;
    reg       key_up_buf;

    assign irq = kbd_ready; // 준비되면 IRQ 발생 (외부에서 연결 선택)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= S_IDLE;
            kbd_ready <= 1'b0;
            ascii_buf <= 8'h00;
            key_up_buf<= 1'b0;
        end else begin
            if (rx_valid) begin
                case (state)
                    S_IDLE: begin
                        if (rx_data == 8'hF0) begin
                            state <= S_BREAK;
                        end else if (rx_data == 8'hE0) begin
                            state <= S_EXTENDED;
                        end else begin
                            // Make 코드
                            if (scan_to_ascii(rx_data) != 8'h00) begin
                                ascii_buf  <= scan_to_ascii(rx_data);
                                key_up_buf <= 1'b0;
                                kbd_ready  <= 1'b1;
                            end
                        end
                    end
                    S_BREAK: begin
                        // Break 코드: 뗌 이벤트
                        if (scan_to_ascii(rx_data) != 8'h00) begin
                            ascii_buf  <= scan_to_ascii(rx_data);
                            key_up_buf <= 1'b1;
                            kbd_ready  <= 1'b1;
                        end
                        state <= S_IDLE;
                    end
                    S_EXTENDED: begin
                        // E0 접두어: 현재 버전은 다음 바이트를 무시
                        if (rx_data == 8'hF0)
                            state <= S_BREAK; // E0 F0 → extended break
                        else
                            state <= S_IDLE;
                    end
                    default: state <= S_IDLE;
                endcase
            end

            // MMIO 읽기: DATA를 읽으면 kbd_ready 클리어
            if (sel && ~we && (off == 8'h04))
                kbd_ready <= 1'b0;
        end
    end

    // ----------------------------------------------------------------
    // MMIO 읽기 조합 로직
    // ----------------------------------------------------------------
    always @* begin
        rdata = 32'h0000_0000;
        if (sel && ~we) begin
            case (off)
                8'h00: rdata = {31'h0, kbd_ready};
                8'h04: rdata = {22'h0, key_up_buf, (ascii_buf != 8'h00), ascii_buf};
                default: rdata = 32'h0000_0000;
            endcase
        end
    end
endmodule
