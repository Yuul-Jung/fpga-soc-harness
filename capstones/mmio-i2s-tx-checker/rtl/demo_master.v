// demo_master.v — I2S TX MMIO 체커 FSM (7상태)
// I2S 초기화 → IRQ 폴링 → frame_done 카운터 → LED 갱신
// 버스 주소맵 (64KB 창, addr[31:16] 기준):
//   GPIO  0x1000_xxxx: LED=0x00, SW=0x04
//   UART  0x1001_xxxx: DATA=0x00, STATUS=0x04  (미사용)
//   I2S   0x1002_xxxx: CTRL=0x0000, STATUS=0x0004,
//                      L_DATA=0x0008, R_DATA=0x000C,
//                      IRQ_STATUS=0xFFF8, IRQ_ENABLE=0xFFFC
`timescale 1ns/1ps
module demo_master (
    input  wire        clk,
    input  wire        rst,
    // mmio-lite 마스터 포트
    output reg         m_valid,
    output reg         m_we,
    output reg  [31:0] m_addr,
    output reg  [31:0] m_wdata,
    input  wire [31:0] m_rdata,
    input  wire        m_ready
);
    // 상태 인코딩
    localparam S_WR_L    = 3'd0; // L_DATA = 0xA5A5
    localparam S_WR_R    = 3'd1; // R_DATA = 0x5A5A
    localparam S_EN_TX   = 3'd2; // CTRL   = 1 (TX_EN)
    localparam S_EN_IRQ  = 3'd3; // IRQ_ENABLE = 1
    localparam S_RD_IRQ  = 3'd4; // IRQ_STATUS 읽기; bit[0]=1이면 → S_CL_IRQ
    localparam S_CL_IRQ  = 3'd5; // IRQ_STATUS W1C (bit[0]=1 써서 클리어)
    localparam S_WR_LED  = 3'd6; // GPIO LED에 frame_done 카운터 출력

    reg [2:0]  state;
    reg [15:0] frame_cnt; // frame_done 발생 횟수 카운터

    // 상태 전이 (버스 핸드셰이크: m_valid & m_ready → 완료)
    always @(posedge clk) begin
        if (rst) begin
            state     <= S_WR_L;
            frame_cnt <= 16'd0;
            m_valid   <= 1'b0;
            m_we      <= 1'b0;
            m_addr    <= 32'd0;
            m_wdata   <= 32'd0;
        end else begin
            if (m_valid && m_ready) begin
                // 현재 트랜잭션 완료
                m_valid <= 1'b0;
                case (state)
                    S_WR_L:   state <= S_WR_R;
                    S_WR_R:   state <= S_EN_TX;
                    S_EN_TX:  state <= S_EN_IRQ;
                    S_EN_IRQ: state <= S_RD_IRQ;
                    S_RD_IRQ: begin
                        // 읽기 완료 — rdata를 평가한다
                        if (m_rdata[0]) begin
                            frame_cnt <= frame_cnt + 16'd1;
                            state     <= S_CL_IRQ;
                        end
                        // bit[0]=0이면 같은 상태를 반복 (다음 사이클에 valid 다시 설정됨)
                    end
                    S_CL_IRQ: state <= S_WR_LED;
                    S_WR_LED: state <= S_RD_IRQ; // 계속 폴링
                    default:  state <= S_RD_IRQ;
                endcase
            end
        end
    end

    // 출력 조합 블록 (m_valid가 0일 때 다음 트랜잭션을 즉시 발행)
    always @(posedge clk) begin
        if (rst) begin
            // 리셋 직후 초기 트랜잭션 준비는 아래 else 블록이 처리
        end else if (!m_valid) begin
            m_valid <= 1'b1;
            case (state)
                S_WR_L: begin
                    m_we    <= 1'b1;
                    m_addr  <= 32'h1002_0008; // I2S L_DATA
                    m_wdata <= 32'h0000_A5A5;
                end
                S_WR_R: begin
                    m_we    <= 1'b1;
                    m_addr  <= 32'h1002_000C; // I2S R_DATA
                    m_wdata <= 32'h0000_5A5A;
                end
                S_EN_TX: begin
                    m_we    <= 1'b1;
                    m_addr  <= 32'h1002_0000; // I2S CTRL
                    m_wdata <= 32'h0000_0001; // TX_EN=1
                end
                S_EN_IRQ: begin
                    m_we    <= 1'b1;
                    m_addr  <= 32'h1002_FFFC; // I2S IRQ_ENABLE
                    m_wdata <= 32'h0000_0001; // frame_done IRQ 활성화
                end
                S_RD_IRQ: begin
                    m_we    <= 1'b0;
                    m_addr  <= 32'h1002_FFF8; // I2S IRQ_STATUS
                    m_wdata <= 32'd0;
                end
                S_CL_IRQ: begin
                    m_we    <= 1'b1;
                    m_addr  <= 32'h1002_FFF8; // I2S IRQ_STATUS W1C
                    m_wdata <= 32'h0000_0001; // bit[0]=1 → W1C 클리어
                end
                S_WR_LED: begin
                    m_we    <= 1'b1;
                    m_addr  <= 32'h1000_0000; // GPIO LED
                    m_wdata <= {16'd0, frame_cnt};
                end
                default: begin
                    m_we    <= 1'b0;
                    m_addr  <= 32'd0;
                    m_wdata <= 32'd0;
                end
            endcase
        end
    end

endmodule
