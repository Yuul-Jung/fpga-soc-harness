// demo_master.v — CPU 없이 사이클 카운터로 세 센서를 순차 트리거
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
//
// 순서: HC-SR04 트리거 → 완료 대기 → LED 갱신/UART 출력
//       DHT11 트리거 → 완료 대기 → LED 갱신/UART 출력
//       I2C 트리거   → 완료 대기 → LED 갱신/UART 출력
//       100 ms 대기  → 반복
//
// UART 출력은 단순히 1바이트(결과 하위 8비트)를 보낸다.

`timescale 1ns/1ps
module demo_master (
    input  wire        clk,
    input  wire        rst_n,
    // MMIO 마스터 포트
    output reg  [31:0] addr,
    output reg  [31:0] wdata,
    output reg         we,
    input  wire [31:0] rdata
);

    // 주소 상수
    localparam A_LED      = 32'h1000_0000,
               A_SW       = 32'h1000_0004,
               A_UART_D   = 32'h1001_0000,
               A_UART_ST  = 32'h1001_0004,
               A_HC_CTRL  = 32'h1002_0000,
               A_HC_STAT  = 32'h1002_0004,
               A_HC_DIST  = 32'h1002_0008,
               A_DHT_CTRL = 32'h1002_0010,
               A_DHT_STAT = 32'h1002_0014,
               A_DHT_HUM  = 32'h1002_0018,
               A_I2C_CMD  = 32'h1002_0020,
               A_I2C_STAT = 32'h1002_0024,
               A_I2C_DATA = 32'h1002_0028;

    // MPU-6050: dev_addr=0x68, reg_addr=0x3B (ACCEL_XOUT_H)
    localparam I2C_CMD_VAL = 32'h3B_D1; // [15:8]=reg 0x3B, [7:1]=0x68<<1=0xD0, [0]=1(start)

    // 100 ms = 10,000,000 cycles
    localparam WAIT_CYC = 10_000_000;

    reg [23:0] wait_cnt;

    // FSM
    localparam S_HC_START  = 4'd0,
               S_HC_WAIT   = 4'd1,
               S_HC_READ   = 4'd2,
               S_DHT_START = 4'd3,
               S_DHT_WAIT  = 4'd4,
               S_DHT_READ  = 4'd5,
               S_I2C_START = 4'd6,
               S_I2C_WAIT  = 4'd7,
               S_I2C_READ  = 4'd8,
               S_UART_BUSY = 4'd9,
               S_PAUSE     = 4'd10;

    reg [3:0] state;
    reg [7:0] uart_byte;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_HC_START;
            addr     <= A_HC_CTRL;
            wdata    <= 32'd1;
            we       <= 1'b0;
            wait_cnt <= 24'd0;
            uart_byte<= 8'd0;
        end else begin
            we <= 1'b0;  // 기본: 읽기

            case (state)
                // ---- HC-SR04 ----
                S_HC_START: begin
                    addr  <= A_HC_CTRL;
                    wdata <= 32'd1;
                    we    <= 1'b1;
                    state <= S_HC_WAIT;
                end
                S_HC_WAIT: begin
                    addr  <= A_HC_STAT;
                    we    <= 1'b0;
                    // rdata[1]=done
                    if (rdata[1]) state <= S_HC_READ;
                end
                S_HC_READ: begin
                    addr  <= A_HC_DIST;
                    we    <= 1'b0;
                    // 다음 사이클에 rdata에 거리 값 옴
                    // LED[7:0] = 거리 하위 8비트
                    state <= S_DHT_START;
                    // LED 갱신은 DHT START 전에
                    addr  <= A_LED;
                    wdata <= {24'd0, rdata[7:0]};
                    we    <= 1'b1;
                end

                // ---- DHT11 ----
                S_DHT_START: begin
                    addr  <= A_DHT_CTRL;
                    wdata <= 32'd1;
                    we    <= 1'b1;
                    state <= S_DHT_WAIT;
                end
                S_DHT_WAIT: begin
                    addr  <= A_DHT_STAT;
                    we    <= 1'b0;
                    if (rdata[1]) state <= S_DHT_READ;
                end
                S_DHT_READ: begin
                    addr  <= A_DHT_HUM;
                    we    <= 1'b0;
                    uart_byte <= rdata[7:0]; // 습도 출력
                    state <= S_I2C_START;
                end

                // ---- I2C ----
                S_I2C_START: begin
                    addr  <= A_I2C_CMD;
                    wdata <= I2C_CMD_VAL;
                    we    <= 1'b1;
                    state <= S_I2C_WAIT;
                end
                S_I2C_WAIT: begin
                    addr  <= A_I2C_STAT;
                    we    <= 1'b0;
                    if (rdata[1]) state <= S_I2C_READ;
                end
                S_I2C_READ: begin
                    addr      <= A_I2C_DATA;
                    we        <= 1'b0;
                    uart_byte <= rdata[7:0];
                    // UART 전송
                    state <= S_UART_BUSY;
                end

                S_UART_BUSY: begin
                    addr  <= A_UART_D;
                    wdata <= {24'd0, uart_byte};
                    we    <= 1'b1;
                    state <= S_PAUSE;
                end

                S_PAUSE: begin
                    we <= 1'b0;
                    if (wait_cnt == WAIT_CYC - 1) begin
                        wait_cnt <= 24'd0;
                        state    <= S_HC_START;
                    end else
                        wait_cnt <= wait_cnt + 1'b1;
                end

                default: state <= S_HC_START;
            endcase
        end
    end

endmodule
