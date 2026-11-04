/* basys3_top.v — Basys3 보드 래퍼
 * Origin: capstones/mmio-i2c-master-ip/rtl/basys3_top.v
 * Verilog-2001.
 *
 * I2C 핀 배치 (오픈드레인):
 *   SCL → JA[1] (W2)   SDA → JA[2] (U2)
 * LED[7:0] → 읽은 WHO_AM_I 값 표시
 * BTNC → 동기 리셋
 */
module basys3_top (
    input  wire        clk,         /* 100 MHz XTAL */
    input  wire        btnc,        /* 리셋 버튼 (액티브 하이) */
    /* Pmod JA I2C 핀 (오픈드레인 버퍼) */
    inout  wire        ja1,         /* SCL */
    inout  wire        ja2,         /* SDA */
    /* LED */
    output wire [7:0]  led
);

/* --- 동기 리셋 (2단 플립플롭 디바운스) --- */
reg [1:0] rst_sr;
always @(posedge clk) rst_sr <= {rst_sr[0], btnc};
wire rst_n = ~rst_sr[1];

/* --- I2C 오픈드레인 버퍼 ---
 *   구동 모드: scl_drv=0 → 로우 출력,  scl_drv=1 → Hi-Z (풀업 의존)
 */
wire scl_drv, sda_drv, sda_in;

assign ja1   = scl_drv ? 1'bz : 1'b0;
assign ja2   = sda_drv ? 1'bz : 1'b0;
assign sda_in = ja2;

soc_top #(.CLK_DIV(1000)) u_soc (
    .clk   (clk),
    .rst_n (rst_n),
    .scl_o (scl_drv),
    .sda_o (sda_drv),
    .sda_i (sda_in),
    .led   (led)
);

endmodule
