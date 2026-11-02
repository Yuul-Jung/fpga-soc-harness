// Basys3 최상위: 100MHz 클럭, btnC=리셋, btnU=UART 송신, sw→led 루프, RsTx로 SW[7:0] 송신.
module basys3_top (
    input  wire        clk,
    input  wire        btnC,
    input  wire        btnU,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire        RsTx
);
    reg r1 = 1'b0, r2 = 1'b0;
    always @(posedge clk) begin
        r1 <= btnC;
        r2 <= r1;
    end
    wire rst = r2;

    wire        m_valid, m_we, m_ready;
    wire [31:0] m_addr, m_wdata, m_rdata;

    demo_master u_master (
        .clk(clk), .rst(rst), .btn(btnU),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready)
    );

    soc_top #(.CLK_HZ(100_000_000), .BAUD(115200)) u_soc (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(sw), .led(led), .uart_txd(RsTx)
    );
endmodule
