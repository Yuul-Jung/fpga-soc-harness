// 톤 생성기: 32비트 위상 누산기(DDS)의 최상위 비트가 사각파 음높이, 8비트 캐리어 비교로 음량(PWM 듀티)을 만든다.
// 0x00 INC(RW)  주파수 = INC * CLK_HZ / 2^32     0x04 CTRL(RW) bit0=enable
// 0x08 VOL(RW)  하위 8비트, 캐리어 256 중 high 개수  0x0C STATUS(RO) bit0=현재 톤 비트
module pwm_tone (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [7:0]  off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        pwm,
    output wire        amp_sd_n,
    output wire        tone
);
    reg [31:0] inc;
    reg        en;
    reg [7:0]  vol;
    reg [31:0] acc;
    reg [7:0]  car;

    assign tone     = acc[31];
    assign pwm      = en && acc[31] && (car < vol);
    assign amp_sd_n = en;

    always @(posedge clk) begin
        if (rst) begin
            inc <= 32'h0000_0000;
            en  <= 1'b0;
            vol <= 8'h00;
            acc <= 32'h0000_0000;
            car <= 8'h00;
        end else begin
            car <= car + 8'd1;
            acc <= en ? acc + inc : 32'h0000_0000;
            if (sel && we) begin
                case (off)
                    8'h00: inc <= wdata;
                    8'h04: en  <= wdata[0];
                    8'h08: vol <= wdata[7:0];
                    default: ;
                endcase
            end
        end
    end

    always @* begin
        case (off)
            8'h00:   rdata = inc;
            8'h04:   rdata = {31'h0, en};
            8'h08:   rdata = {24'h0, vol};
            8'h0C:   rdata = {31'h0, acc[31]};
            default: rdata = 32'h0000_0000;
        endcase
    end
endmodule
