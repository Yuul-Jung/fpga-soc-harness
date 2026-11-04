// 데모 마스터(CPU 슬롯 대체용 FSM): 버튼 상승 에지마다 도레미파솔라시도 8음을 NOTE_CLKS 클럭씩 재생한다.
// 음마다 SW[7:0]을 읽어 음량으로 쓰고(0이면 64), 음높이 INC·VGA 막대 수·LED(원-핫)를 갱신한다. 끝나면 소리를 끈다.
module demo_master #(
    parameter NOTE_CLKS = 25_000_000
) (
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
    localparam [3:0] IDLE = 4'd0, R_SW = 4'd1, W_VOL = 4'd2, W_INC = 4'd3, W_NOTE = 4'd4,
                     W_LED = 4'd5, W_EN = 4'd6, HOLD = 4'd7, W_OFF = 4'd8;
    localparam [31:0] A_LED = 32'h1000_0000, A_SW = 32'h1000_0004,
                      A_INC = 32'h1000_3000, A_EN = 32'h1000_3004, A_VOL = 32'h1000_3008,
                      A_NOTE = 32'h1000_4000;

    reg [3:0]  st;
    reg [2:0]  n;
    reg [7:0]  vol;
    reg [31:0] cnt;
    reg        b1, b2, b3;
    reg [31:0] inc_rom;

    always @* begin
        case (n)
            3'd0:    inc_rom = 32'd11237;
            3'd1:    inc_rom = 32'd12613;
            3'd2:    inc_rom = 32'd14158;
            3'd3:    inc_rom = 32'd14999;
            3'd4:    inc_rom = 32'd16836;
            3'd5:    inc_rom = 32'd18898;
            3'd6:    inc_rom = 32'd21212;
            default: inc_rom = 32'd22473;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            st <= IDLE; n <= 3'd0; vol <= 8'd64; cnt <= 32'd0; b1 <= 1'b0; b2 <= 1'b0; b3 <= 1'b0;
            m_valid <= 1'b0; m_we <= 1'b0; m_addr <= 32'd0; m_wdata <= 32'd0;
        end else begin
            b1 <= btn; b2 <= b1; b3 <= b2;
            m_valid <= 1'b0; m_we <= 1'b0;
            case (st)
                IDLE:   begin n <= 3'd0; if (b2 && !b3) st <= R_SW; end
                R_SW:   begin m_valid <= 1'b1; m_addr <= A_SW; st <= W_VOL; end
                W_VOL:  begin
                            vol <= (m_rdata[7:0] == 8'd0) ? 8'd64 : m_rdata[7:0];
                            m_valid <= 1'b1; m_we <= 1'b1; m_addr <= A_VOL;
                            m_wdata <= {24'd0, (m_rdata[7:0] == 8'd0) ? 8'd64 : m_rdata[7:0]};
                            st <= W_INC;
                        end
                W_INC:  begin m_valid <= 1'b1; m_we <= 1'b1; m_addr <= A_INC; m_wdata <= inc_rom; st <= W_NOTE; end
                W_NOTE: begin m_valid <= 1'b1; m_we <= 1'b1; m_addr <= A_NOTE; m_wdata <= {29'd0, n}; st <= W_LED; end
                W_LED:  begin m_valid <= 1'b1; m_we <= 1'b1; m_addr <= A_LED; m_wdata <= 32'd1 << n; st <= W_EN; end
                W_EN:   begin m_valid <= 1'b1; m_we <= 1'b1; m_addr <= A_EN; m_wdata <= 32'd1; cnt <= 32'd0; st <= HOLD; end
                HOLD:   begin
                            cnt <= cnt + 32'd1;
                            if (cnt == NOTE_CLKS - 1) begin
                                if (n == 3'd7) st <= W_OFF;
                                else begin n <= n + 3'd1; st <= R_SW; end
                            end
                        end
                W_OFF:  begin m_valid <= 1'b1; m_we <= 1'b1; m_addr <= A_EN; m_wdata <= 32'd0; st <= IDLE; end
                default: st <= IDLE;
            endcase
        end
    end
endmodule
