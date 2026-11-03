// demo_master.v — 합성용 데모 마스터 FSM
// 보드에서 동작하는 간단한 시퀀스:
//   1. PWM PERIOD=50000, DUTY0=25000(50%), DUTY1=37500(75%), enable=1
//   2. 버튼 입력(btn)으로 DUTY0을 증가시켜 LED 밝기 조절 데모
// 테스트벤치는 이 모듈을 쓰지 않고 soc_top 마스터 포트를 직접 구동한다.
`timescale 1ns/1ps
module demo_master (
    input  wire        clk,
    input  wire        rst,
    // MMIO 마스터 포트
    output reg         valid,
    output reg         we,
    output reg  [31:0] addr,
    output reg  [31:0] wdata,
    input  wire [31:0] rdata,
    input  wire        ready
);
    localparam S_IDLE  = 3'd0;
    localparam S_WRITE = 3'd1;
    localparam S_DONE  = 3'd2;

    // 초기화 단계
    localparam STEP_PERIOD  = 3'd0;
    localparam STEP_DUTY0   = 3'd1;
    localparam STEP_DUTY1   = 3'd2;
    localparam STEP_ENABLE  = 3'd3;
    localparam STEP_FINISH  = 3'd4;

    reg [2:0] state;
    reg [2:0] step;

    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
            we    <= 1'b0;
            addr  <= 32'd0;
            wdata <= 32'd0;
            state <= S_IDLE;
            step  <= STEP_PERIOD;
        end else begin
            case (state)
                S_IDLE: begin
                    if (step == STEP_FINISH) begin
                        state <= S_DONE;
                    end else begin
                        we    <= 1'b1;
                        valid <= 1'b1;
                        case (step)
                            STEP_PERIOD: begin
                                addr  <= 32'h1003_0004; // PWM PERIOD
                                wdata <= 32'd50000;
                            end
                            STEP_DUTY0: begin
                                addr  <= 32'h1003_0008; // PWM DUTY0 = 50%
                                wdata <= 32'd25000;
                            end
                            STEP_DUTY1: begin
                                addr  <= 32'h1003_000C; // PWM DUTY1 = 75%
                                wdata <= 32'd37500;
                            end
                            STEP_ENABLE: begin
                                addr  <= 32'h1003_0000; // PWM CTRL enable
                                wdata <= 32'd1;
                            end
                            default: ;
                        endcase
                        state <= S_WRITE;
                    end
                end
                S_WRITE: begin
                    if (ready) begin
                        valid <= 1'b0;
                        we    <= 1'b0;
                        step  <= step + 3'd1;
                        state <= S_IDLE;
                    end
                end
                S_DONE: begin
                    // 초기화 완료. 버스를 놓아둔다.
                    valid <= 1'b0;
                    we    <= 1'b0;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
