// pwm_ip.v — 2채널 PWM IP (IP 표준 Rev.1 관리 레지스터 포함)
// 레지스터 맵:
//   0x0000  CTRL    [0]=enable
//   0x0004  PERIOD  [15:0] 클럭 사이클 수 (0이면 출력 OFF)
//   0x0008  DUTY0   [15:0] 채널0 비교값 (0 ≤ DUTY < PERIOD이면 HIGH)
//   0x000C  DUTY1   [15:0] 채널1 비교값
//   0xFFF0  ID      RO = 0x50574D31 ("PWM1")
//   0xFFF4  VER     RO = {8'h01,8'h00,8'h00,8'h01}
//   0xFFF8  IRQ_STATUS  [0]=period_end W1C
//   0xFFFC  IRQ_ENABLE  [0]=period_end IRQ 허용
// pwm0, pwm1: cnt < duty이면 HIGH
// IRQ: 카운터가 0으로 돌아올 때 period_end 펄스 발생
`timescale 1ns/1ps
module pwm_ip (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        pwm0,
    output wire        pwm1,
    output wire        irq
);
    // 제어 레지스터
    reg         enable;
    reg  [15:0] period;
    reg  [15:0] duty0;
    reg  [15:0] duty1;
    reg         irq_status;
    reg         irq_enable;

    // 카운터
    reg  [15:0] cnt;

    // 쓰기
    wire wr = sel && we;

    always @(posedge clk) begin
        if (rst) begin
            enable     <= 1'b0;
            period     <= 16'd0;
            duty0      <= 16'd0;
            duty1      <= 16'd0;
            irq_enable <= 1'b0;
            irq_status <= 1'b0;
            cnt        <= 16'd0;
        end else begin
            // IRQ_STATUS W1C 클리어
            if (wr && (off == 16'hFFF8))
                irq_status <= irq_status & ~wdata[0];

            // 일반 레지스터 쓰기
            if (wr) begin
                case (off)
                    16'h0000: enable     <= wdata[0];
                    16'h0004: period     <= wdata[15:0];
                    16'h0008: duty0      <= wdata[15:0];
                    16'h000C: duty1      <= wdata[15:0];
                    16'hFFFC: irq_enable <= wdata[0];
                    default: ;
                endcase
            end

            // 카운터 동작
            if (enable && (period != 16'd0)) begin
                if (cnt >= period - 16'd1) begin
                    cnt        <= 16'd0;
                    irq_status <= irq_status | 1'b1; // period_end 펄스
                end else begin
                    cnt <= cnt + 16'd1;
                end
            end else begin
                cnt <= 16'd0;
            end
        end
    end

    // PWM 출력: cnt < duty이면 HIGH (duty=0이면 항상 LOW)
    assign pwm0 = enable && (period != 16'd0) && (duty0 != 16'd0) && (cnt < duty0);
    assign pwm1 = enable && (period != 16'd0) && (duty1 != 16'd0) && (cnt < duty1);
    assign irq  = irq_status & irq_enable;

    // 읽기
    always @* begin
        case (off)
            16'h0000: rdata = {31'd0, enable};
            16'h0004: rdata = {16'd0, period};
            16'h0008: rdata = {16'd0, duty0};
            16'h000C: rdata = {16'd0, duty1};
            16'hFFF0: rdata = 32'h5057_4D31; // "PWM1"
            16'hFFF4: rdata = 32'h0100_0001; // rev=1, major=0, minor=1
            16'hFFF8: rdata = {31'd0, irq_status};
            16'hFFFC: rdata = {31'd0, irq_enable};
            default:  rdata = 32'h0000_0000;
        endcase
    end
endmodule
