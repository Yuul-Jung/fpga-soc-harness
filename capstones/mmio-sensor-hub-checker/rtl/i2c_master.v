// i2c_master.v — I2C 마스터 FSM (단일 레지스터 읽기)
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 100 MHz, 400 kHz = 250 cycles / 비트. half = 125 cycles
// 동작: START → ADDR(W)+ACK → REG_ADDR+ACK → RESTART → ADDR(R)+ACK → DATA+NACK → STOP

`timescale 1ns/1ps
module i2c_master #(
    parameter CLK_DIV = 125    // 100 MHz / 400 kHz / 2
)(
    input  wire       clk,
    input  wire       rst_n,
    // MMIO 제어
    input  wire       start,       // 1-cycle 펄스
    input  wire [6:0] dev_addr,    // 7비트 슬레이브 주소
    input  wire [7:0] reg_addr,    // 읽을 레지스터 주소
    // I2C 핀 (오픈 드레인: oe=1 → SDA/SCL = 0)
    output reg        scl_oe,
    output reg        sda_oe,
    input  wire       sda_in,
    // 결과
    output reg  [7:0] rdata,
    output reg        busy,
    output reg        done,
    output reg        error
);

    // SCL 반주기 카운터
    reg [7:0]  clk_cnt;
    reg        scl_phase;    // 0=low, 1=high

    // 비트 시프트 레지스터와 비트 카운터
    reg [7:0]  tx_byte;
    reg [2:0]  bit_cnt;
    reg        ack_bit;

    // FSM 상태
    localparam S_IDLE      = 5'd0,
               S_START1    = 5'd1,  // SDA low
               S_START2    = 5'd2,  // SCL low
               S_ADDR_W    = 5'd3,  // ADDR(W) 8비트 (addr<<1 | 0)
               S_ACK1      = 5'd4,
               S_REG       = 5'd5,  // REG_ADDR 8비트
               S_ACK2      = 5'd6,
               S_RESTART1  = 5'd7,  // SCL high
               S_RESTART2  = 5'd8,  // SDA high
               S_RESTART3  = 5'd9,  // SDA low (START)
               S_RESTART4  = 5'd10, // SCL low
               S_ADDR_R    = 5'd11, // ADDR(R) 8비트 (addr<<1 | 1)
               S_ACK3      = 5'd12,
               S_DATA      = 5'd13, // DATA 8비트 읽기
               S_NACK      = 5'd14, // 마스터 NACK
               S_STOP1     = 5'd15, // SCL high
               S_STOP2     = 5'd16, // SDA high
               S_DONE      = 5'd17,
               S_ERROR     = 5'd18;

    reg [4:0] state;

    // SCL 토글 도우미: clk_cnt가 CLK_DIV에 도달하면 1 반주기 완료
    wire half_done = (clk_cnt == CLK_DIV - 1);

    task next_bit;
        input [4:0] next_state;
        begin
            bit_cnt <= bit_cnt - 1'b1;
            if (bit_cnt == 3'd0)
                state <= next_state;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            scl_oe    <= 1'b0;  // SCL high (open drain released)
            sda_oe    <= 1'b0;  // SDA high
            busy      <= 1'b0;
            done      <= 1'b0;
            error     <= 1'b0;
            rdata     <= 8'd0;
            clk_cnt   <= 8'd0;
            scl_phase <= 1'b0;
            bit_cnt   <= 3'd7;
            tx_byte   <= 8'd0;
            ack_bit   <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    scl_oe <= 1'b0; sda_oe <= 1'b0;
                    busy   <= 1'b0;
                    if (start) begin
                        busy    <= 1'b1;
                        error   <= 1'b0;
                        clk_cnt <= 8'd0;
                        state   <= S_START1;
                    end
                end

                // START: SDA low while SCL high
                S_START1: begin
                    sda_oe <= 1'b1;  // SDA = 0
                    if (half_done) begin clk_cnt <= 8'd0; state <= S_START2; end
                    else clk_cnt <= clk_cnt + 1'b1;
                end
                S_START2: begin
                    scl_oe <= 1'b1;  // SCL = 0
                    if (half_done) begin
                        clk_cnt <= 8'd0;
                        tx_byte <= {dev_addr, 1'b0};  // WRITE
                        bit_cnt <= 3'd7;
                        state   <= S_ADDR_W;
                    end else clk_cnt <= clk_cnt + 1'b1;
                end

                // 8비트 전송 (MSB first): SCL low→high→low 1 cycle = 2 half_done
                S_ADDR_W, S_REG, S_ADDR_R: begin
                    if (!scl_phase) begin
                        // SCL low 구간: SDA 세팅
                        sda_oe <= ~tx_byte[7];
                        if (half_done) begin
                            scl_oe    <= 1'b0;  // SCL high
                            scl_phase <= 1'b1;
                            clk_cnt   <= 8'd0;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        // SCL high 구간: SDA 유지
                        if (half_done) begin
                            scl_oe    <= 1'b1;  // SCL low
                            scl_phase <= 1'b0;
                            tx_byte   <= {tx_byte[6:0], 1'b0};
                            if (bit_cnt == 3'd0) begin
                                sda_oe  <= 1'b0;  // SDA 해제 (ACK 수신용)
                                bit_cnt <= 3'd7;
                                state   <= (state == S_ADDR_W) ? S_ACK1 :
                                           (state == S_REG   ) ? S_ACK2 : S_ACK3;
                            end else
                                bit_cnt <= bit_cnt - 1'b1;
                            clk_cnt <= 8'd0;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // ACK 수신: SCL high 중에 SDA 읽기
                S_ACK1, S_ACK2, S_ACK3: begin
                    if (!scl_phase) begin
                        if (half_done) begin
                            scl_oe    <= 1'b0;
                            scl_phase <= 1'b1;
                            clk_cnt   <= 8'd0;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        ack_bit <= sda_in;  // 0=ACK, 1=NACK
                        if (half_done) begin
                            scl_oe    <= 1'b1;
                            scl_phase <= 1'b0;
                            clk_cnt   <= 8'd0;
                            if (sda_in) begin
                                state <= S_ERROR;  // NACK
                            end else begin
                                case (state)
                                    S_ACK1: begin
                                        tx_byte <= reg_addr;
                                        state   <= S_REG;
                                    end
                                    S_ACK2: state <= S_RESTART1;
                                    S_ACK3: begin
                                        rdata   <= 8'd0;
                                        bit_cnt <= 3'd7;
                                        sda_oe  <= 1'b0;  // 입력 모드
                                        state   <= S_DATA;
                                    end
                                    default: state <= S_ERROR;
                                endcase
                            end
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // RESTART: SCL high → SDA high → SDA low → SCL low
                S_RESTART1: begin
                    scl_oe <= 1'b0;
                    if (half_done) begin clk_cnt <= 8'd0; state <= S_RESTART2; end
                    else clk_cnt <= clk_cnt + 1'b1;
                end
                S_RESTART2: begin
                    sda_oe <= 1'b0;
                    if (half_done) begin clk_cnt <= 8'd0; state <= S_RESTART3; end
                    else clk_cnt <= clk_cnt + 1'b1;
                end
                S_RESTART3: begin
                    sda_oe <= 1'b1;  // SDA low
                    if (half_done) begin clk_cnt <= 8'd0; state <= S_RESTART4; end
                    else clk_cnt <= clk_cnt + 1'b1;
                end
                S_RESTART4: begin
                    scl_oe <= 1'b1;  // SCL low
                    if (half_done) begin
                        clk_cnt <= 8'd0;
                        tx_byte <= {dev_addr, 1'b1};  // READ
                        bit_cnt <= 3'd7;
                        state   <= S_ADDR_R;
                    end else clk_cnt <= clk_cnt + 1'b1;
                end

                // DATA 읽기 8비트 MSB first
                S_DATA: begin
                    if (!scl_phase) begin
                        if (half_done) begin
                            scl_oe    <= 1'b0;
                            scl_phase <= 1'b1;
                            clk_cnt   <= 8'd0;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        rdata <= {rdata[6:0], sda_in};  // MSB first shift
                        if (half_done) begin
                            scl_oe    <= 1'b1;
                            scl_phase <= 1'b0;
                            clk_cnt   <= 8'd0;
                            if (bit_cnt == 3'd0) begin
                                sda_oe  <= 1'b1;  // NACK: SDA high
                                state   <= S_NACK;
                            end else
                                bit_cnt <= bit_cnt - 1'b1;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // NACK: SCL high 한 사이클
                S_NACK: begin
                    if (!scl_phase) begin
                        if (half_done) begin
                            scl_oe    <= 1'b0;
                            scl_phase <= 1'b1;
                            clk_cnt   <= 8'd0;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        if (half_done) begin
                            scl_oe    <= 1'b1;
                            scl_phase <= 1'b0;
                            sda_oe    <= 1'b1;  // SDA low for STOP prep
                            clk_cnt   <= 8'd0;
                            state     <= S_STOP1;
                        end else clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // STOP: SCL high → SDA high
                S_STOP1: begin
                    scl_oe <= 1'b0;  // SCL high
                    if (half_done) begin clk_cnt <= 8'd0; state <= S_STOP2; end
                    else clk_cnt <= clk_cnt + 1'b1;
                end
                S_STOP2: begin
                    sda_oe <= 1'b0;  // SDA high
                    if (half_done) begin clk_cnt <= 8'd0; state <= S_DONE; end
                    else clk_cnt <= clk_cnt + 1'b1;
                end

                S_DONE: begin
                    done  <= 1'b1;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end

                S_ERROR: begin
                    // STOP 시도 후 오류 반환
                    scl_oe <= 1'b0;
                    sda_oe <= 1'b0;
                    error  <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    state  <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
