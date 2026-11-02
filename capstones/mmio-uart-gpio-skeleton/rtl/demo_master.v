// 데모 마스터(CPU 슬롯 대체용 FSM): SW를 읽어 LED에 쓰고, 버튼 상승 에지마다 SW[7:0]을 UART로 보낸다.
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
    localparam [2:0] RD_SW = 3'd0, WR_LED = 3'd1, CHK = 3'd2, RD_ST = 3'd3, WR_TX = 3'd4;

    reg [2:0]  st;
    reg [15:0] sw_q;
    reg        pend;
    reg        b1, b2, b3;

    always @(posedge clk) begin
        if (rst) begin
            st   <= RD_SW;
            sw_q <= 16'h0000;
            pend <= 1'b0;
            b1 <= 1'b0; b2 <= 1'b0; b3 <= 1'b0;
        end else begin
            b1 <= btn; b2 <= b1; b3 <= b2;
            if (b2 && !b3) pend <= 1'b1;
            case (st)
                RD_SW:   if (m_ready) begin sw_q <= m_rdata[15:0]; st <= WR_LED; end
                WR_LED:  if (m_ready) st <= CHK;
                CHK:     st <= pend ? RD_ST : RD_SW;
                RD_ST:   if (m_ready) st <= m_rdata[0] ? RD_SW : WR_TX;
                WR_TX:   if (m_ready) begin pend <= 1'b0; st <= RD_SW; end
                default: st <= RD_SW;
            endcase
        end
    end

    always @* begin
        m_valid = 1'b0;
        m_we    = 1'b0;
        m_addr  = 32'h0000_0000;
        m_wdata = 32'h0000_0000;
        case (st)
            RD_SW:  begin m_valid = 1'b1; m_addr = 32'h1000_0004; end
            WR_LED: begin m_valid = 1'b1; m_we = 1'b1; m_addr = 32'h1000_0000; m_wdata = {16'h0000, sw_q}; end
            RD_ST:  begin m_valid = 1'b1; m_addr = 32'h1000_1004; end
            WR_TX:  begin m_valid = 1'b1; m_we = 1'b1; m_addr = 32'h1000_1000; m_wdata = {24'h000000, sw_q[7:0]}; end
            default: ;
        endcase
    end
endmodule
