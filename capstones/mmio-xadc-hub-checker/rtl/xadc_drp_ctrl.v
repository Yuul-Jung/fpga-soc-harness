// xadc_drp_ctrl.v
// XADC DRP 채널 순회 FSM
// 4개 보조 채널(VAUXP/N 4,5,12,13)을 순서대로 읽어 raw_data, valid를 올린다.
// XADC가 EOC를 올리면 DRP den+daddr로 순서대로 읽는다.
// Verilog-2001 호환 (iverilog/verilator/yosys). 개별 출력 포트 사용.

module xadc_drp_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire        scan_en,       // 1=순환 스캔, 0=정지

    // DRP 인터페이스 (XADC 또는 모의 모델)
    input  wire        eoc,           // end-of-conversion
    output reg         den,           // DRP enable
    output reg  [6:0]  daddr,         // DRP 주소
    input  wire        drdy,          // DRP data ready
    input  wire [15:0] dout,          // DRP data out

    // 출력 (채널별 12비트 원시값 — 개별 포트, Verilog-2001 호환)
    output reg  [11:0] raw_ch0,  // VAUXP/N[4]  (DRP 0x14)
    output reg  [11:0] raw_ch1,  // VAUXP/N[5]  (DRP 0x15)
    output reg  [11:0] raw_ch2,  // VAUXP/N[12] (DRP 0x1C)
    output reg  [11:0] raw_ch3,  // VAUXP/N[13] (DRP 0x1D)
    output reg  [3:0]  valid          // 갱신 펄스 (1클럭)
);

    // FSM 상태
    localparam S_IDLE  = 3'd0;
    localparam S_WAIT  = 3'd1; // EOC 대기
    localparam S_READ  = 3'd2; // den 올리기
    localparam S_DRDY  = 3'd3; // drdy 대기
    localparam S_NEXT  = 3'd4; // 다음 채널 또는 종료

    reg [2:0] state;
    reg [1:0] ch_idx; // 현재 채널 인덱스 0..3

    // 채널 인덱스에서 DRP 주소를 반환하는 함수
    // VAUXP/N[4]=0x14, [5]=0x15, [12]=0x1C, [13]=0x1D
    function [6:0] ch_addr;
        input [1:0] idx;
        case (idx)
            2'd0: ch_addr = 7'h14;
            2'd1: ch_addr = 7'h15;
            2'd2: ch_addr = 7'h1C;
            2'd3: ch_addr = 7'h1D;
            default: ch_addr = 7'h00;
        endcase
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= S_WAIT;
            ch_idx  <= 2'd0;
            den     <= 1'b0;
            daddr   <= 7'h00;
            valid   <= 4'b0;
            raw_ch0 <= 12'd0;
            raw_ch1 <= 12'd0;
            raw_ch2 <= 12'd0;
            raw_ch3 <= 12'd0;
        end else begin
            den   <= 1'b0;
            valid <= 4'b0;

            case (state)
                S_WAIT: begin
                    if (scan_en && eoc) begin
                        ch_idx <= 2'd0;
                        state  <= S_READ;
                    end
                end

                S_READ: begin
                    den   <= 1'b1;
                    daddr <= ch_addr(ch_idx);
                    state <= S_DRDY;
                end

                S_DRDY: begin
                    if (drdy) begin
                        // 채널별 12비트 원시값 저장 (상위 12비트)
                        case (ch_idx)
                            2'd0: begin raw_ch0 <= dout[15:4]; valid[0] <= 1'b1; end
                            2'd1: begin raw_ch1 <= dout[15:4]; valid[1] <= 1'b1; end
                            2'd2: begin raw_ch2 <= dout[15:4]; valid[2] <= 1'b1; end
                            2'd3: begin raw_ch3 <= dout[15:4]; valid[3] <= 1'b1; end
                            default: ;
                        endcase
                        state <= S_NEXT;
                    end
                end

                S_NEXT: begin
                    if (ch_idx == 2'd3)
                        state <= S_WAIT; // 모든 채널 읽기 완료
                    else begin
                        ch_idx <= ch_idx + 1'b1;
                        state  <= S_READ;
                    end
                end

                default: state <= S_WAIT;
            endcase
        end
    end

endmodule
