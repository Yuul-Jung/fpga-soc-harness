// SPI 모드 0 바이트 송수신기: start 펄스로 1바이트(MSB 먼저) 교환. div = SCLK 반주기 클럭 수.
module spi_byte (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  tx,
    input  wire [15:0] div,
    output reg         busy,
    output reg         done,
    output reg  [7:0]  rx,
    output wire        sclk,
    output wire        mosi,
    input  wire        miso
);
    reg        sclk_r;
    reg [7:0]  tsh, rsh;
    reg [2:0]  bn;
    reg [15:0] cnt;
    assign sclk = sclk_r;
    assign mosi = busy ? tsh[7] : 1'b1;

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0; sclk_r <= 1'b0; cnt <= 16'd0; bn <= 3'd0;
            tsh <= 8'hFF; rsh <= 8'h00; rx <= 8'h00;
        end else if (!busy) begin
            if (start) begin
                busy <= 1'b1; tsh <= tx; bn <= 3'd0; cnt <= div - 16'd1; sclk_r <= 1'b0;
            end
        end else if (cnt != 16'd0) begin
            cnt <= cnt - 16'd1;
        end else begin
            cnt <= div - 16'd1;
            if (!sclk_r) begin                       // 상승 에지: MISO 표본
                sclk_r <= 1'b1;
                rsh    <= {rsh[6:0], miso};
            end else begin                           // 하강 에지: 다음 비트로 이동
                sclk_r <= 1'b0;
                if (bn == 3'd7) begin
                    busy <= 1'b0; done <= 1'b1; rx <= rsh;
                end else begin
                    bn  <= bn + 3'd1;
                    tsh <= {tsh[6:0], 1'b0};
                end
            end
        end
    end
endmodule
