// xadc_regs.v
// mmio-lite 레지스터 디코더
// 오프셋 맵 (capstone.json memory_map 기준):
//  0x00 CTRL     RW  bit[1:0]=avg_len bit2=irq_en bit3=scan_en
//  0x04 STATUS   RO  bit0=busy bit[5:2]=ch_valid[3:0]
//  0x08 CH0_RAW  RO  12비트 원시값
//  0x0C CH1_RAW  RO
//  0x10 CH2_RAW  RO
//  0x14 CH3_RAW  RO
//  0x18 CH0_AVG  RO  12비트 이동 평균
//  0x1C CH1_AVG  RO
//  0x20 CH2_AVG  RO
//  0x24 CH3_AVG  RO
//  0x28 IRQ_MASK RW  bit[3:0] 채널별 인터럽트 마스크
//  0x2C IRQ_FLAG RW  bit[3:0] write-1-to-clear

module xadc_regs (
    input  wire        clk,
    input  wire        rst,

    // mmio-lite 슬레이브
    input  wire [15:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    input  wire        req,
    output reg         ack,

    // CTRL 필드 출력
    output reg  [1:0]  avg_len,
    output reg         irq_en,
    output reg         scan_en,

    // STATUS 입력
    input  wire        busy,
    input  wire [3:0]  ch_valid,

    // 채널별 데이터 입력
    input  wire [11:0] ch_raw_0,
    input  wire [11:0] ch_raw_1,
    input  wire [11:0] ch_raw_2,
    input  wire [11:0] ch_raw_3,
    input  wire [11:0] ch_avg_0,
    input  wire [11:0] ch_avg_1,
    input  wire [11:0] ch_avg_2,
    input  wire [11:0] ch_avg_3,

    // IRQ
    output wire        irq
);

    // IRQ_MASK, IRQ_FLAG 레지스터
    reg [3:0] irq_mask;
    reg [3:0] irq_flag;

    // 인터럽트: 마스크 된 플래그가 있고 irq_en이면 올림
    assign irq = irq_en && |(irq_mask & irq_flag);

    // IRQ 플래그: ch_valid가 오면 세트
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            irq_flag <= 4'b0;
        end else begin
            // 채널 변환 완료 시 세트
            irq_flag <= irq_flag | ch_valid;
            // write-1-to-clear (동시 세트·클리어 가능: 세트 우선)
            if (we && req && addr[7:0] == 8'h2C)
                irq_flag <= (irq_flag | ch_valid) & ~wdata[3:0];
        end
    end

    // ack: req 다음 사이클
    always @(posedge clk or posedge rst) begin
        if (rst) ack <= 1'b0;
        else     ack <= req & ~ack; // 1클럭 ack
    end

    // 쓰기
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            avg_len  <= 2'd0;
            irq_en   <= 1'b0;
            scan_en  <= 1'b0;
            irq_mask <= 4'b0;
        end else if (we && req) begin
            case (addr[7:0])
                8'h00: begin
                    avg_len <= wdata[1:0];
                    irq_en  <= wdata[2];
                    scan_en <= wdata[3];
                end
                8'h28: irq_mask <= wdata[3:0];
                default: ;
            endcase
        end
    end

    // 읽기 (조합)
    always @(*) begin
        case (addr[7:0])
            8'h00: rdata = {28'd0, scan_en, irq_en, avg_len};
            8'h04: rdata = {26'd0, ch_valid, 1'b0, busy};
            8'h08: rdata = {20'd0, ch_raw_0};
            8'h0C: rdata = {20'd0, ch_raw_1};
            8'h10: rdata = {20'd0, ch_raw_2};
            8'h14: rdata = {20'd0, ch_raw_3};
            8'h18: rdata = {20'd0, ch_avg_0};
            8'h1C: rdata = {20'd0, ch_avg_1};
            8'h20: rdata = {20'd0, ch_avg_2};
            8'h24: rdata = {20'd0, ch_avg_3};
            8'h28: rdata = {28'd0, irq_mask};
            8'h2C: rdata = {28'd0, irq_flag};
            default: rdata = 32'hDEAD_BEEF;
        endcase
    end

endmodule
