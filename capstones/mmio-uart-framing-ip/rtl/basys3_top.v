// basys3_top.v — Basys3 보드 래퍼
// 핀: CLK100MHZ(W5), RESET_BTN(U18), Pmod JA 핀1(J1 = UART RX)
// 7세그 상태 출력: 패킷 카운터 하위 4비트를 AN0에 표시

`timescale 1ns/1ps
module basys3_top (
    input  wire        CLK100MHZ,
    input  wire        btnC,        // 중앙 버튼 = 리셋
    input  wire        JA1,         // Pmod JA 핀1 = UART RX
    // 7세그: 상태 표시 (선택)
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp
);

// 리셋 동기화 (버튼은 High Active, 내부는 Low Active)
reg [1:0] rst_sync;
wire rst_n = !rst_sync[1];
always @(posedge CLK100MHZ) begin
    rst_sync <= {rst_sync[0], btnC};
end

// IRQ 카운터 (상태 표시용)
wire irq_out;
reg [3:0] pkt_cnt;
always @(posedge CLK100MHZ or negedge rst_n) begin
    if (!rst_n)       pkt_cnt <= 4'd0;
    else if (irq_out) pkt_cnt <= pkt_cnt + 4'd1;
end

// SoC 인스턴스 (테스트벤치가 AXI 포트를 직접 구동하지 않으므로
// AXI 마스터 포트를 타이오프)
soc_top u_soc (
    .clk       (CLK100MHZ),
    .rst_n     (rst_n),
    .uart_rx   (JA1),
    .irq_out   (irq_out),
    // AXI 마스터 포트 타이오프 (보드에서는 CPU가 연결)
    .m_awaddr  (8'd0),
    .m_awvalid (1'b0),
    .m_awready (),
    .m_wdata   (32'd0),
    .m_wstrb   (4'b0000),
    .m_wvalid  (1'b0),
    .m_wready  (),
    .m_bresp   (),
    .m_bvalid  (),
    .m_bready  (1'b1),
    .m_araddr  (8'd0),
    .m_arvalid (1'b0),
    .m_arready (),
    .m_rdata   (),
    .m_rresp   (),
    .m_rvalid  (),
    .m_rready  (1'b1)
);

// 7세그 디코더 (패킷 카운터 AN0에 표시)
reg [6:0] seg_r;
always @(*) begin
    case (pkt_cnt)
    4'h0: seg_r = 7'b1000000;
    4'h1: seg_r = 7'b1111001;
    4'h2: seg_r = 7'b0100100;
    4'h3: seg_r = 7'b0110000;
    4'h4: seg_r = 7'b0011001;
    4'h5: seg_r = 7'b0010010;
    4'h6: seg_r = 7'b0000010;
    4'h7: seg_r = 7'b1111000;
    4'h8: seg_r = 7'b0000000;
    4'h9: seg_r = 7'b0010000;
    4'hA: seg_r = 7'b0001000;
    4'hB: seg_r = 7'b0000011;
    4'hC: seg_r = 7'b1000110;
    4'hD: seg_r = 7'b0100001;
    4'hE: seg_r = 7'b0000110;
    4'hF: seg_r = 7'b0001110;
    endcase
end
assign seg = seg_r;
assign an  = 4'b1110;   // AN0만 활성
assign dp  = 1'b1;      // DP 꺼짐

endmodule
