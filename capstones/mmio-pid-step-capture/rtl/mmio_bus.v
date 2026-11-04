// mmio_bus.v — MMIO-lite 주소 디코더 (mmio-pid-step-capture)
// addr[31:16] 기준 3개 슬레이브 선택. ready=1 사이클 고정.
// 슬레이브:
//   0x1000_xxxx : GPIO (LED/SW)
//   0x1001_xxxx : UART TX
//   0x1002_xxxx : PID_CAP IP
// Verilog-2001
`default_nettype none

module mmio_bus (
    input  wire        clk,
    input  wire        rst,
    // 마스터 포트
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output reg  [31:0] m_rdata,
    output wire        m_ready,
    // 보드 I/O (GPIO)
    input  wire [15:0] sw,
    output wire [15:0] led,
    // PID_CAP I/O
    input  wire        enc_a,
    input  wire        enc_b,
    output wire        pwm_out,
    // UART
    output wire        uart_txd
);

    // 슬레이브 선택 (상위 16비트 비교)
    wire sel_gpio    = m_valid && (m_addr[31:16] == 16'h1000);
    wire sel_uart    = m_valid && (m_addr[31:16] == 16'h1001);
    wire sel_pid_cap = m_valid && (m_addr[31:16] == 16'h1002);

    // 슬레이브별 버스 신호
    wire [31:0] gpio_rdata;
    wire [31:0] uart_rdata;
    wire [31:0] pid_cap_rdata;

    // GPIO 슬레이브
    gpio u_gpio (
        .clk   (clk),
        .rst   (rst),
        .valid (sel_gpio),
        .we    (m_we),
        .addr  (m_addr[3:0]),
        .wdata (m_wdata),
        .rdata (gpio_rdata),
        .sw    (sw),
        .led   (led)
    );

    // UART TX 슬레이브
    uart_tx u_uart (
        .clk   (clk),
        .rst   (rst),
        .valid (sel_uart),
        .we    (m_we),
        .addr  (m_addr[3:0]),
        .wdata (m_wdata),
        .rdata (uart_rdata),
        .txd   (uart_txd)
    );

    // PID_CAP 슬레이브
    pid_cap_ip u_pid_cap (
        .clk   (clk),
        .rst   (rst),
        .valid (sel_pid_cap),
        .we    (m_we),
        .addr  (m_addr[15:0]),
        .wdata (m_wdata),
        .rdata (pid_cap_rdata),
        .enc_a (enc_a),
        .enc_b (enc_b),
        .pwm   (pwm_out)
    );

    // 읽기 데이터 MUX
    always @(*) begin
        if (sel_gpio)
            m_rdata = gpio_rdata;
        else if (sel_uart)
            m_rdata = uart_rdata;
        else if (sel_pid_cap)
            m_rdata = pid_cap_rdata;
        else
            m_rdata = 32'hDEAD_BEEF;
    end

    // ready는 항상 1 (1사이클 응답)
    assign m_ready = 1'b1;

endmodule
`default_nettype wire
