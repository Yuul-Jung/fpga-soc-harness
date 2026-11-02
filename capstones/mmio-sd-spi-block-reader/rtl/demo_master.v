// 데모 마스터(CPU 슬롯 대체용 FSM): 버튼 상승 에지마다 SD 초기화 → 블록 0 읽기 → 첫 16바이트를 UART로 출력.
// LED: 초기화 뒤 {12'h0, STATUS}, 읽기 뒤 {8'h01, 4'h0, STATUS}. STATUS의 err(bit2)가 서면 거기서 멈춘다.
module demo_master (
    input  wire        clk,
    input  wire        rst,
    input  wire        btn,
    output reg         m_valid,
    output reg         m_we,
    output reg  [31:0] m_addr,
    output reg  [31:0] m_wdata,
    input  wire [31:0] m_rdata,
    input  wire        m_ready
);
    localparam [3:0] WAIT = 4'd0, W_INIT = 4'd1, P_INIT = 4'd2, W_LED1 = 4'd3, W_LBA = 4'd4, W_RD = 4'd5,
                     P_RD = 4'd6, W_LED2 = 4'd7, W_IDX = 4'd8, R_DAT = 4'd9, R_UST = 4'd10, W_TX = 4'd11;
    localparam [31:0] A_LED = 32'h1000_0000, A_UTX = 32'h1000_1000, A_UST = 32'h1000_1004,
                      A_SCTL = 32'h1000_2000, A_SST = 32'h1000_2004, A_SLBA = 32'h1000_2008,
                      A_SIDX = 32'h1000_200C, A_SDAT = 32'h1000_2010;

    reg [3:0] st;
    reg [3:0] n;
    reg [3:0] stat;
    reg [7:0] byte_q;
    reg       pend, b1, b2, b3;

    always @(posedge clk) begin
        if (rst) begin
            st <= WAIT; n <= 4'd0; stat <= 4'd0; byte_q <= 8'h00; pend <= 1'b0; b1 <= 1'b0; b2 <= 1'b0; b3 <= 1'b0;
        end else begin
            b1 <= btn; b2 <= b1; b3 <= b2;
            if (b2 && !b3) pend <= 1'b1;
            if (m_ready) case (st)
                WAIT:   if (pend) begin pend <= 1'b0; st <= W_INIT; end
                W_INIT: st <= P_INIT;
                P_INIT: if (!m_rdata[0]) begin stat <= m_rdata[3:0]; st <= W_LED1; end
                W_LED1: st <= stat[2] ? WAIT : W_LBA;
                W_LBA:  st <= W_RD;
                W_RD:   st <= P_RD;
                P_RD:   if (!m_rdata[0]) begin stat <= m_rdata[3:0]; st <= W_LED2; end
                W_LED2: begin n <= 4'd0; st <= stat[2] ? WAIT : W_IDX; end
                W_IDX:  st <= R_DAT;
                R_DAT:  begin byte_q <= m_rdata[7:0]; st <= R_UST; end
                R_UST:  if (!m_rdata[0]) st <= W_TX;
                W_TX:   begin n <= n + 4'd1; st <= (n == 4'd15) ? WAIT : W_IDX; end
                default: st <= WAIT;
            endcase
        end
    end

    always @* begin
        m_valid = 1'b0; m_we = 1'b0; m_addr = 32'h0; m_wdata = 32'h0;
        case (st)
            W_INIT: begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_SCTL; m_wdata = 32'h1; end
            P_INIT: begin m_valid = 1'b1; m_addr = A_SST; end
            W_LED1: begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_LED; m_wdata = {28'h0, stat}; end
            W_LBA:  begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_SLBA; m_wdata = 32'h0; end
            W_RD:   begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_SCTL; m_wdata = 32'h2; end
            P_RD:   begin m_valid = 1'b1; m_addr = A_SST; end
            W_LED2: begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_LED; m_wdata = {16'h0, 8'h01, 4'h0, stat}; end
            W_IDX:  begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_SIDX; m_wdata = {28'h0, n}; end
            R_DAT:  begin m_valid = 1'b1; m_addr = A_SDAT; end
            R_UST:  begin m_valid = 1'b1; m_addr = A_UST; end
            W_TX:   begin m_valid = 1'b1; m_we = 1'b1; m_addr = A_UTX; m_wdata = {24'h0, byte_q}; end
            default: ;
        endcase
    end
endmodule
