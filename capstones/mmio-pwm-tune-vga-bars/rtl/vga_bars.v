// VGA 640x480@60Hz 막대 표시(프레임 버퍼 없음, 카운터에서 바로 색 결정). 25 MHz 화소 enable은 100 MHz를 4분주.
// 0x00 NOTE(RW) 하위 3비트: 0..NOTE번 막대(80화소 폭)가 켜짐  0x04 COLOR(RW) 하위 12비트 {R,G,B}
// 0x08 FRAME(RO) 프레임 카운터(vsync마다 +1, 16비트)
module vga_bars (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [7:0]  off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        hsync,
    output wire        vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b
);
    reg [1:0]  div;
    reg [9:0]  hcnt;
    reg [9:0]  vcnt;
    reg [2:0]  note;
    reg [11:0] color;
    reg [15:0] frame;

    wire pe     = (div == 2'd3);
    wire hlast  = (hcnt == 10'd799);
    wire vlast  = (vcnt == 10'd524);
    wire de     = (hcnt < 10'd640) && (vcnt < 10'd480);
    wire [2:0] col = (hcnt < 10'd80)  ? 3'd0 : (hcnt < 10'd160) ? 3'd1 :
                     (hcnt < 10'd240) ? 3'd2 : (hcnt < 10'd320) ? 3'd3 :
                     (hcnt < 10'd400) ? 3'd4 : (hcnt < 10'd480) ? 3'd5 :
                     (hcnt < 10'd560) ? 3'd6 : 3'd7;
    wire lit    = de && (col <= note);

    assign hsync = ~((hcnt >= 10'd656) && (hcnt < 10'd752));
    assign vsync = ~((vcnt >= 10'd490) && (vcnt < 10'd492));
    assign vga_r = lit ? color[11:8] : 4'h0;
    assign vga_g = lit ? color[7:4]  : 4'h0;
    assign vga_b = lit ? color[3:0]  : 4'h0;

    always @(posedge clk) begin
        if (rst) begin
            div   <= 2'd0;
            hcnt  <= 10'd0;
            vcnt  <= 10'd0;
            note  <= 3'd0;
            color <= 12'h0F0;
            frame <= 16'h0000;
        end else begin
            div <= div + 2'd1;
            if (pe) begin
                if (hlast) begin
                    hcnt <= 10'd0;
                    if (vlast) begin
                        vcnt  <= 10'd0;
                        frame <= frame + 16'd1;
                    end else begin
                        vcnt <= vcnt + 10'd1;
                    end
                end else begin
                    hcnt <= hcnt + 10'd1;
                end
            end
            if (sel && we) begin
                case (off)
                    8'h00: note  <= wdata[2:0];
                    8'h04: color <= wdata[11:0];
                    default: ;
                endcase
            end
        end
    end

    always @* begin
        case (off)
            8'h00:   rdata = {29'h0, note};
            8'h04:   rdata = {20'h0, color};
            8'h08:   rdata = {16'h0, frame};
            default: rdata = 32'h0000_0000;
        endcase
    end
endmodule
