// demo_master.v — 합성용 데모 마스터 FSM
// 보드 초기화 시퀀스:
//   1. SPEED_PI: PERIOD=4000, KP=0x0080, KI=0x0010, TARGET=10, MIN_DUTY=100, CTRL=enable
// 테스트벤치는 이 모듈 없이 soc_top 마스터 포트를 직접 구동한다.
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
    localparam S_IDLE  = 2'd0;
    localparam S_WRITE = 2'd1;
    localparam S_DONE  = 2'd2;

    localparam STEP_PERIOD   = 4'd0;
    localparam STEP_KP       = 4'd1;
    localparam STEP_KI       = 4'd2;
    localparam STEP_TARGET   = 4'd3;
    localparam STEP_MIN_DUTY = 4'd4;
    localparam STEP_ENABLE   = 4'd5;
    localparam STEP_FINISH   = 4'd6;

    reg [1:0] state;
    reg [3:0] step;

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
                            STEP_PERIOD:   begin addr <= 32'h1002_0014; wdata <= 32'd4000;  end
                            STEP_KP:       begin addr <= 32'h1002_0008; wdata <= 32'h0080;  end
                            STEP_KI:       begin addr <= 32'h1002_000C; wdata <= 32'h0010;  end
                            STEP_TARGET:   begin addr <= 32'h1002_0004; wdata <= 32'd10;    end
                            STEP_MIN_DUTY: begin addr <= 32'h1002_001C; wdata <= 32'd100;   end
                            STEP_ENABLE:   begin addr <= 32'h1002_0000; wdata <= 32'd1;     end
                            default: ;
                        endcase
                        state <= S_WRITE;
                    end
                end
                S_WRITE: begin
                    if (ready) begin
                        valid <= 1'b0;
                        we    <= 1'b0;
                        step  <= step + 4'd1;
                        state <= S_IDLE;
                    end
                end
                S_DONE: begin
                    valid <= 1'b0;
                    we    <= 1'b0;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
