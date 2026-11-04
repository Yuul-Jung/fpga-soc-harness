// demo_master.v — 합성용 데모 마스터 FSM (mmio-pid-step-capture)
// MMIO 버스에 초기화 시퀀스를 발행하고 PID 제어를 시작한다.
// 시뮬레이션에서는 테스트벤치가 버스를 직접 구동하므로
// 이 모듈은 합성용 래퍼로만 쓰인다.
// Verilog-2001
`default_nettype none

module demo_master (
    input  wire        clk,
    input  wire        rst,
    // MMIO-lite 마스터 포트
    output reg         valid,
    output reg         we,
    output reg  [31:0] addr,
    output reg  [31:0] wdata,
    input  wire [31:0] rdata,
    input  wire        ready
);

    // PID_CAP 슬레이브 베이스 주소
    localparam BASE_PID = 32'h1002_0000;

    // 초기화 FSM
    localparam [4:0]
        S_RESET     = 5'd0,
        S_SET_KP    = 5'd1,
        S_SET_KI    = 5'd2,
        S_SET_KD    = 5'd3,
        S_SET_PRD   = 5'd4,
        S_SET_MIN   = 5'd5,
        S_SET_TGT   = 5'd6,
        S_SET_CAP   = 5'd7,
        S_SET_EN    = 5'd8,
        S_RUNNING   = 5'd9;

    reg [4:0] state;
    reg [19:0] wait_cnt;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_RESET;
            valid    <= 1'b0;
            we       <= 1'b0;
            addr     <= 32'h0;
            wdata    <= 32'h0;
            wait_cnt <= 20'd0;
        end else begin
            valid <= 1'b0; // 기본: 트랜잭션 없음

            case (state)
                S_RESET: begin
                    // 짧은 대기 후 초기화 시작
                    if (wait_cnt == 20'd10) begin
                        wait_cnt <= 20'd0;
                        state    <= S_SET_KP;
                    end else begin
                        wait_cnt <= wait_cnt + 20'd1;
                    end
                end
                S_SET_KP: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h08;
                    wdata <= 32'h0180;  // KP = 1.5 (8.8)
                    if (ready) state <= S_SET_KI;
                end
                S_SET_KI: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h0C;
                    wdata <= 32'h0020;  // KI = 0.125 (8.8)
                    if (ready) state <= S_SET_KD;
                end
                S_SET_KD: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h10;
                    wdata <= 32'h0010;  // KD = 0.0625 (8.8)
                    if (ready) state <= S_SET_PRD;
                end
                S_SET_PRD: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h18;
                    wdata <= 32'd1000;  // PWM 주기 1000 클럭
                    if (ready) state <= S_SET_MIN;
                end
                S_SET_MIN: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h20;
                    wdata <= 32'd50;    // 최소 듀티 50
                    if (ready) state <= S_SET_TGT;
                end
                S_SET_TGT: begin
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h04;
                    wdata <= 32'd100;   // 목표 속도 100 카운트/창
                    if (ready) state <= S_SET_CAP;
                end
                S_SET_CAP: begin
                    // CTRL: enable=1, cap_start=1
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h00;
                    wdata <= 32'h5;     // bit2=cap_start, bit0=enable
                    if (ready) state <= S_SET_EN;
                end
                S_SET_EN: begin
                    // CTRL: enable=1 (cap_start 클리어)
                    valid <= 1'b1;
                    we    <= 1'b1;
                    addr  <= BASE_PID + 32'h00;
                    wdata <= 32'h1;     // bit0=enable
                    if (ready) state <= S_RUNNING;
                end
                S_RUNNING: begin
                    // 동작 중 — 버스 조용히 유지
                    valid <= 1'b0;
                end
                default: state <= S_RESET;
            endcase
        end
    end

endmodule
`default_nettype wire
