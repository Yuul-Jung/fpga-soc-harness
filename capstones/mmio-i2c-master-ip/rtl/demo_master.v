/* demo_master.v — WHO_AM_I 읽기 시연 FSM
 * Origin: capstones/mmio-i2c-master-ip/rtl/demo_master.v
 * Verilog-2001.
 *
 * 전원 투입 후 MPU-6050(주소 0x68)의 WHO_AM_I(레지스터 0x75)를 읽어
 * LED[7:0]에 표시한다. BUSY 폴링으로 트랜잭션 완료 대기.
 *
 * 사용 순서:
 *   1. CTRL = {addr=0x68, rnw=0, go=1, stop=0}, DATA = 0x75  → 레지스터 주소 쓰기
 *   2. BUSY 폴링 (CTRL[10] = 0 까지 대기)
 *   3. CTRL = {addr=0x68, rnw=1, go=1, stop=1}               → 1바이트 읽기
 *   4. BUSY 폴링
 *   5. DATA[7:0] 읽어 LED 출력
 */
module demo_master (
    input  wire        clk,
    input  wire        rst_n,
    /* MMIO 마스터 포트 */
    output reg  [31:0] m_addr,
    output reg  [31:0] m_wdata,
    input  wire [31:0] m_rdata,
    output reg         m_we,
    output reg         m_valid,
    /* 결과 출력 */
    output reg  [7:0]  led
);

localparam [4:0]
    D_IDLE      = 5'd0,
    D_WR_DATA   = 5'd1,  /* DATA = 0x75 */
    D_WR_CTRL1  = 5'd2,  /* CTRL: go, addr=0x68, rnw=0, stop=0 */
    D_WAIT1_A   = 5'd3,  /* CTRL 읽기 */
    D_WAIT1_B   = 5'd4,  /* BUSY 확인 */
    D_WR_CTRL2  = 5'd5,  /* CTRL: go, addr=0x68, rnw=1, stop=1 */
    D_WAIT2_A   = 5'd6,  /* CTRL 읽기 */
    D_WAIT2_B   = 5'd7,  /* BUSY 확인 */
    D_RD_DATA   = 5'd8,  /* DATA 읽기 */
    D_DONE      = 5'd9;

reg [4:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state   <= D_IDLE;
        m_addr  <= 32'd0; m_wdata <= 32'd0;
        m_we    <= 1'b0;  m_valid <= 1'b0;
        led     <= 8'hFF; /* 초기: 전체 점등 */
    end else begin
        m_we    <= 1'b0;
        m_valid <= 1'b0;

        case (state)
            D_IDLE: begin
                state <= D_WR_DATA;
            end

            /* Step 1: DATA ← 0x75 (레지스터 주소) */
            D_WR_DATA: begin
                m_addr  <= 32'h0000_0004; /* DATA 오프셋 */
                m_wdata <= 32'h0000_0075;
                m_we    <= 1'b1;
                m_valid <= 1'b1;
                state   <= D_WR_CTRL1;
            end

            /* Step 2: CTRL ← {stop=1, go=1, rnw=0, addr=0x68} */
            D_WR_CTRL1: begin
                /* bit[6:0]=0x68, bit[7]=rnw=0, bit[8]=go=1, bit[9]=stop=1 */
                m_addr  <= 32'h0000_0000;
                m_wdata <= 32'h0000_0368; /* 0x68 | (1<<8) | (1<<9) */
                m_we    <= 1'b1;
                m_valid <= 1'b1;
                state   <= D_WAIT1_A;
            end

            /* Step 3: BUSY 폴링 (CTRL 읽기) */
            D_WAIT1_A: begin
                m_addr  <= 32'h0000_0000;
                m_we    <= 1'b0;
                m_valid <= 1'b1;
                state   <= D_WAIT1_B;
            end

            D_WAIT1_B: begin
                if (m_rdata[10] == 1'b0) /* BUSY = 0 */
                    state <= D_WR_CTRL2;
                else
                    state <= D_WAIT1_A; /* 계속 폴링 */
            end

            /* Step 4: CTRL ← {stop=1, go=1, rnw=1, addr=0x68} */
            D_WR_CTRL2: begin
                /* bit[6:0]=0x68, bit[7]=rnw=1, bit[8]=go=1, bit[9]=stop=1 */
                m_addr  <= 32'h0000_0000;
                m_wdata <= 32'h0000_03E8; /* 0x68|(1<<7)|(1<<8)|(1<<9) = 0x3E8 */
                m_we    <= 1'b1;
                m_valid <= 1'b1;
                state   <= D_WAIT2_A;
            end

            /* Step 5: BUSY 폴링 */
            D_WAIT2_A: begin
                m_addr  <= 32'h0000_0000;
                m_we    <= 1'b0;
                m_valid <= 1'b1;
                state   <= D_WAIT2_B;
            end

            D_WAIT2_B: begin
                if (m_rdata[10] == 1'b0)
                    state <= D_RD_DATA;
                else
                    state <= D_WAIT2_A;
            end

            /* Step 6: DATA 읽기 → LED */
            D_RD_DATA: begin
                m_addr  <= 32'h0000_0004;
                m_we    <= 1'b0;
                m_valid <= 1'b1;
                state   <= D_DONE;
            end

            D_DONE: begin
                led   <= m_rdata[7:0];
                state <= D_DONE; /* 완료: 유휴 */
            end

            default: state <= D_IDLE;
        endcase
    end
end

endmodule
