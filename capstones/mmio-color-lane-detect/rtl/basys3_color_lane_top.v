// basys3_color_lane_top.v — Basys3 보드 래퍼
// 핀 배치: OV7670은 JA/JB Pmod, 상태 표시는 LED/세그먼트.
// XDC 파일: constr/basys3_color_lane.xdc
// Verilog-2001.

`default_nettype none
module basys3_color_lane_top (
    // 보드 클럭 / 리셋
    input  wire        clk,         // 100 MHz 보드 클럭
    input  wire        btnC,        // 중앙 버튼: 리셋 (active high)
    // OV7670 Pmod JA (PCLK 도메인)
    input  wire        cam_pclk,    // JA[1] — 카메라 픽셀 클럭
    input  wire        cam_vsync,   // JA[2]
    input  wire        cam_href,    // JA[3]
    input  wire [7:0]  cam_d,       // JB[7:0] — 픽셀 데이터
    // 상태 표시
    output wire [15:0] led,         // led[1:0]=LANE, led[2]=JUMP, led[15]=ENABLE
    // 세그먼트 (레인 표시 — 간략)
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    // 리셋 동기화 (SYS 도메인)
    reg rst_s1, rst_s2;
    always @(posedge clk) begin
        rst_s1 <= btnC;
        rst_s2 <= rst_s1;
    end
    wire sys_rst = rst_s2;

    // PCLK 도메인 리셋 동기화
    reg prst_s1, prst_s2;
    always @(posedge cam_pclk) begin
        prst_s1 <= btnC;
        prst_s2 <= prst_s1;
    end
    wire pclk_rst = prst_s2;

    // MMIO 더미 — 보드에서는 MicroBlaze 연결 예정.
    // 시뮬에서는 tb가 직접 mmio-lite 버스를 구동한다.
    wire [31:0] mmio_addr  = 32'h1005_0000; // 더미: STATUS 읽기
    wire [31:0] mmio_wdata = 32'd0;
    wire        mmio_wen   = 1'b0;
    wire        mmio_ren   = 1'b0;
    wire [31:0] mmio_rdata;
    wire        irq_out;

    // SoC 코어
    wire [1:0] lane_out;
    wire       jump_out;

    color_lane_top #(.BASE_ADDR(32'h1005_0000)) u_core (
        .clk    (clk),
        .rst    (sys_rst),
        .addr   (mmio_addr),
        .wdata  (mmio_wdata),
        .wen    (mmio_wen),
        .ren    (mmio_ren),
        .rdata  (mmio_rdata),
        .irq    (irq_out),
        .pclk   (cam_pclk),
        .prst   (pclk_rst),
        .vsync  (cam_vsync),
        .href   (cam_href),
        .cam_d  (cam_d),
        .o_lane (lane_out),
        .o_jump (jump_out)
    );

    // LED
    assign led[1:0]  = lane_out;
    assign led[2]    = jump_out;
    assign led[15:3] = 13'd0;

    // 세그먼트: 레인 번호(1=L,2=C,3=R) 표시
    reg [6:0] seg_r;
    always @(*) begin
        case (lane_out)
            2'd0: seg_r = 7'b1111111; // 소등
            2'd1: seg_r = 7'b1111001; // 1(L)
            2'd2: seg_r = 7'b0100100; // 2(C)
            2'd3: seg_r = 7'b0110000; // 3(R)
        endcase
    end
    assign seg = seg_r;
    assign an  = 4'b1110; // AN0만 활성

endmodule
`default_nettype wire
