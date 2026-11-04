// demo_master.v — 합성용 데모 마스터 FSM
// MMIO 버스를 통해 motor_safety_ip 초기화 및 PWM 패턴 출력
// 테스트벤치에서는 사용하지 않고, 보드 데모 용도.

`default_nettype none

module demo_master (
    input  wire        clk,
    input  wire        rst,

    // MMIO-lite 마스터 포트
    output reg         m_valid,
    output reg         m_we,
    output reg  [31:0] m_addr,
    output reg  [31:0] m_wdata,
    input  wire [31:0] m_rdata,
    input  wire        m_ready
);

    // 슬레이브 베이스 주소
    localparam BASE_SAFETY = 32'h1002_0000;

    // 레지스터 오프셋
    localparam OFF_CTRL      = 32'h00;
    localparam OFF_DT_CYCLES = 32'h04;
    localparam OFF_PWM_IN    = 32'h0C;

    // 상태
    localparam S_WR_DT   = 4'd0;   // DT_CYCLES=10 설정
    localparam S_WR_EN   = 4'd1;   // enable=1
    localparam S_WAIT1   = 4'd2;   // 간격
    localparam S_WR_AH   = 4'd3;   // AH=1
    localparam S_WAIT2   = 4'd4;
    localparam S_WR_AL   = 4'd5;   // AH→0, AL=1 (데드타임 발생)
    localparam S_WAIT3   = 4'd6;
    localparam S_WR_OFF  = 4'd7;   // 모두 0
    localparam S_WAIT4   = 4'd8;
    localparam S_IDLE    = 4'd9;

    reg [3:0]  state;
    reg [19:0] wait_cnt;

    localparam WAIT_CYCLES = 20'd200;

    task do_write;
        input [31:0] a;
        input [31:0] d;
        begin
            m_valid <= 1'b1;
            m_we    <= 1'b1;
            m_addr  <= a;
            m_wdata <= d;
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_WR_DT;
            m_valid  <= 1'b0;
            m_we     <= 1'b0;
            m_addr   <= 32'd0;
            m_wdata  <= 32'd0;
            wait_cnt <= 20'd0;
        end else begin
            m_valid <= 1'b0;

            case (state)
                S_WR_DT: begin
                    do_write(BASE_SAFETY + OFF_DT_CYCLES, 32'd10);
                    state <= S_WR_EN;
                end
                S_WR_EN: begin
                    do_write(BASE_SAFETY + OFF_CTRL, 32'h1);  // enable
                    state <= S_WAIT1;
                    wait_cnt <= WAIT_CYCLES;
                end
                S_WAIT1: begin
                    if (wait_cnt == 0) state <= S_WR_AH;
                    else wait_cnt <= wait_cnt - 20'd1;
                end
                S_WR_AH: begin
                    do_write(BASE_SAFETY + OFF_PWM_IN, 32'h1); // AH=1
                    state <= S_WAIT2;
                    wait_cnt <= WAIT_CYCLES;
                end
                S_WAIT2: begin
                    if (wait_cnt == 0) state <= S_WR_AL;
                    else wait_cnt <= wait_cnt - 20'd1;
                end
                S_WR_AL: begin
                    // AH→0, AL=1 : 데드타임이 걸려 AL_out은 10사이클 뒤에 올라간다
                    do_write(BASE_SAFETY + OFF_PWM_IN, 32'h2); // AL=1
                    state <= S_WAIT3;
                    wait_cnt <= WAIT_CYCLES;
                end
                S_WAIT3: begin
                    if (wait_cnt == 0) state <= S_WR_OFF;
                    else wait_cnt <= wait_cnt - 20'd1;
                end
                S_WR_OFF: begin
                    do_write(BASE_SAFETY + OFF_PWM_IN, 32'h0);
                    state <= S_WAIT4;
                    wait_cnt <= WAIT_CYCLES;
                end
                S_WAIT4: begin
                    if (wait_cnt == 0) state <= S_WR_AH; // 반복
                    else wait_cnt <= wait_cnt - 20'd1;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
