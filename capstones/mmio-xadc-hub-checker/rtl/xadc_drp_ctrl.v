// xadc_drp_ctrl.v
// XADC DRP 채널 순회 FSM
// 4개 보조 채널(VAUXP/N 4,5,12,13)을 순서대로 읽어 raw_data, valid를 올린다.
// XADC가 EOC를 올리면 DRP den+daddr로 순서대로 읽는다.
// 시뮬레이션: `ifdef SIMULATION 으로 xadc_drp_model을 사용.

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

    // 출력 (채널별 12비트 원시값)
    output reg  [11:0] raw_ch [0:3],  // 채널 0..3
    output reg  [3:0]  valid          // 갱신 펄스 (1클럭)
);

    // DRP 주소: VAUXP/N[4]=0x14, [5]=0x15, [12]=0x1C, [13]=0x1D
    localparam [6:0] CH_ADDR [0:3] = '{7'h14, 7'h15, 7'h1C, 7'h1D};

    // FSM 상태
    localparam S_IDLE  = 3'd0;
    localparam S_WAIT  = 3'd1; // EOC 대기
    localparam S_READ  = 3'd2; // den 올리기
    localparam S_DRDY  = 3'd3; // drdy 대기
    localparam S_NEXT  = 3'd4; // 다음 채널 또는 종료

    reg [2:0] state;
    reg [1:0] ch_idx; // 현재 채널 인덱스 0..3

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state  <= S_WAIT;
            ch_idx <= 2'd0;
            den    <= 1'b0;
            daddr  <= 7'h00;
            valid  <= 4'b0;
            for (i = 0; i < 4; i = i + 1)
                raw_ch[i] <= 12'd0;
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
                    daddr <= CH_ADDR[ch_idx];
                    state <= S_DRDY;
                end

                S_DRDY: begin
                    if (drdy) begin
                        raw_ch[ch_idx] <= dout[15:4]; // 상위 12비트
                        valid[ch_idx]  <= 1'b1;
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
