// AXI4-Lite 슬레이브 레지스터 블록 (하네스 직접 작성 원본, 외부 코드 없음)
// 용도: 동결 주소맵(0x4007_0000 이후 빈 슬롯 등)에 붙는 사용자 주변장치의 레지스터 창구.
//  - 32비트 데이터, 레지스터 NREGS개(RW 또는 RO), 워드 정렬 접근
//  - RW 레지스터는 내부에 저장되고 reg_o로 나간다. wstrb 바이트 단위 쓰기 지원
//  - RO 레지스터(RO_MASK 비트가 1)는 ro_i의 값을 읽어 준다. 쓰기는 OKAY로 응답하되 무시한다
//  - 범위를 벗어난 주소의 읽기/쓰기는 SLVERR(2'b10)로 응답한다
//  - AW와 W가 모두 유효할 때 한 번에 받는다. 쓰기 응답이 소비되기 전에는 다음 쓰기를 받지 않는다
// 순수 Verilog-2001. 리셋은 동기 active-high.
module axil_regs #(
    parameter ADDR_W  = 4,      // 바이트 주소 폭. 2^ADDR_W >= NREGS*4 이어야 한다
    parameter NREGS   = 4,      // 레지스터 수 (1..32)
    parameter RO_MASK = 0       // 비트 i가 1이면 레지스터 i는 읽기 전용
) (
    input  wire                 clk,
    input  wire                 rst,
    // 쓰기 주소 채널
    input  wire [ADDR_W-1:0]    s_awaddr,
    input  wire                 s_awvalid,
    output wire                 s_awready,
    // 쓰기 데이터 채널
    input  wire [31:0]          s_wdata,
    input  wire [3:0]           s_wstrb,
    input  wire                 s_wvalid,
    output wire                 s_wready,
    // 쓰기 응답 채널
    output wire [1:0]           s_bresp,
    output reg                  s_bvalid,
    input  wire                 s_bready,
    // 읽기 주소 채널
    input  wire [ADDR_W-1:0]    s_araddr,
    input  wire                 s_arvalid,
    output wire                 s_arready,
    // 읽기 데이터 채널
    output reg  [31:0]          s_rdata,
    output reg  [1:0]           s_rresp,
    output reg                  s_rvalid,
    input  wire                 s_rready,
    // 사용자 쪽
    output wire [32*NREGS-1:0]  reg_o,   // RW 레지스터 저장값 (레지스터 i = reg_o[32*i +: 32])
    input  wire [32*NREGS-1:0]  ro_i     // RO 레지스터 읽기 값
);
    wire [31:0] ro_mask_w = RO_MASK;
    reg  [31:0] mem [0:NREGS-1];
    reg         bresp_err;
    integer     i;

    wire [ADDR_W-3:0] widx = s_awaddr[ADDR_W-1:2];
    wire [ADDR_W-3:0] ridx = s_araddr[ADDR_W-1:2];

    wire wr_fire = s_awvalid && s_wvalid && !s_bvalid;
    wire rd_fire = s_arvalid && !s_rvalid;

    assign s_awready = wr_fire;
    assign s_wready  = wr_fire;
    assign s_arready = rd_fire;
    assign s_bresp   = bresp_err ? 2'b10 : 2'b00;

    genvar g;
    generate
        for (g = 0; g < NREGS; g = g + 1) begin : g_out
            assign reg_o[32*g +: 32] = mem[g];
        end
    endgenerate

    // 쓰기 경로
    always @(posedge clk) begin
        if (rst) begin
            s_bvalid  <= 1'b0;
            bresp_err <= 1'b0;
            for (i = 0; i < NREGS; i = i + 1)
                mem[i] <= 32'd0;
        end else begin
            if (s_bvalid && s_bready)
                s_bvalid <= 1'b0;
            if (wr_fire) begin
                s_bvalid <= 1'b1;
                if (widx < NREGS) begin
                    bresp_err <= 1'b0;
                    if (!ro_mask_w[widx]) begin
                        if (s_wstrb[0]) mem[widx][7:0]   <= s_wdata[7:0];
                        if (s_wstrb[1]) mem[widx][15:8]  <= s_wdata[15:8];
                        if (s_wstrb[2]) mem[widx][23:16] <= s_wdata[23:16];
                        if (s_wstrb[3]) mem[widx][31:24] <= s_wdata[31:24];
                    end
                end else begin
                    bresp_err <= 1'b1;
                end
            end
        end
    end

    // 읽기 경로
    always @(posedge clk) begin
        if (rst) begin
            s_rvalid <= 1'b0;
            s_rdata  <= 32'd0;
            s_rresp  <= 2'b00;
        end else begin
            if (s_rvalid && s_rready)
                s_rvalid <= 1'b0;
            if (rd_fire) begin
                s_rvalid <= 1'b1;
                if (ridx < NREGS) begin
                    s_rresp <= 2'b00;
                    s_rdata <= ro_mask_w[ridx] ? ro_i[32*ridx +: 32] : mem[ridx];
                end else begin
                    s_rresp <= 2'b10;
                    s_rdata <= 32'd0;
                end
            end
        end
    end
endmodule
