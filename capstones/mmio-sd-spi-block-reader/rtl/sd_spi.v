// SD 카드 SPI 모드 컨트롤러(원본 작성): 초기화(CMD0/8/55+41/58)와 CMD17 단일 블록 읽기.
// 레지스터: 00 CTRL(WO, bit0=초기화, bit1=읽기) 04 STATUS(RO, {sdhc,err,init_done,busy})
//           08 LBA(RW) 0C IDX(RW, 9bit) 10 DATA(RO, 버퍼[IDX]). v2 카드(SDHC/SDXC)만 대상.
module sd_spi #(
    parameter CLK_HZ  = 100_000_000,
    parameter SLOW_HZ = 400_000,
    parameter FAST_HZ = 12_500_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [7:0]  off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output reg         sd_cs_n,
    output wire        sd_sclk,
    output wire        sd_mosi,
    input  wire        sd_miso
);
    localparam [15:0] SLOW_DIV = CLK_HZ / (2 * SLOW_HZ);
    localparam [15:0] FAST_DIV = CLK_HZ / (2 * FAST_HZ);
    localparam [3:0] ST_IDLE = 4'd0, ST_DUMMY = 4'd1, ST_PREP = 4'd2, ST_CMD = 4'd3, ST_R1 = 4'd4,
                     ST_EXT = 4'd5, ST_EVAL = 4'd6, ST_GAP = 4'd7, ST_TOKEN = 4'd8, ST_DATA = 4'd9, ST_CRC = 4'd10;
    localparam [2:0] S_CMD0 = 3'd0, S_CMD8 = 3'd1, S_CMD55 = 3'd2, S_ACMD41 = 3'd3, S_CMD58 = 3'd4, S_RD = 3'd5;

    reg [3:0]  st;
    reg [2:0]  step, bidx, ecnt;
    reg [3:0]  dcnt, pcnt;
    reg [9:0]  retry;
    reg [15:0] tcnt;
    reg [8:0]  bcnt, idx;
    reg        iss, busy, init_done, err, sdhc, fast, fin, ext, sp_start;
    reg [5:0]  cmd;
    reg [7:0]  crc, r1, sp_tx;
    reg [31:0] arg, r32, lba;
    reg [7:0]  mem [0:511];

    wire       sp_busy, sp_done;
    wire [7:0] mem_q = mem[idx];
    wire [7:0] sp_rx;
    wire       can_issue = !iss && !sp_busy;
    wire       wr_ctrl   = sel && we && (off == 8'h00) && !busy;
    reg  [7:0] cmd_byte;

    spi_byte u_spi (
        .clk(clk), .rst(rst), .start(sp_start), .tx(sp_tx), .div(fast ? FAST_DIV : SLOW_DIV),
        .busy(sp_busy), .done(sp_done), .rx(sp_rx), .sclk(sd_sclk), .mosi(sd_mosi), .miso(sd_miso)
    );

    always @* begin
        case (bidx)
            3'd0:    cmd_byte = {2'b01, cmd};
            3'd1:    cmd_byte = arg[31:24];
            3'd2:    cmd_byte = arg[23:16];
            3'd3:    cmd_byte = arg[15:8];
            3'd4:    cmd_byte = arg[7:0];
            default: cmd_byte = crc;
        endcase
    end

    always @(posedge clk) begin
        sp_start <= 1'b0;
        if (rst) begin
            st <= ST_IDLE; busy <= 1'b0; init_done <= 1'b0; err <= 1'b0; sdhc <= 1'b0; fast <= 1'b0;
            sd_cs_n <= 1'b1; iss <= 1'b0; lba <= 32'd0; idx <= 9'd0; fin <= 1'b0; step <= S_CMD0;
            bidx <= 3'd0; ecnt <= 3'd0; dcnt <= 4'd0; pcnt <= 4'd0; retry <= 10'd0; tcnt <= 16'd0;
            bcnt <= 9'd0; cmd <= 6'd0; crc <= 8'hFF; r1 <= 8'hFF; sp_tx <= 8'hFF; arg <= 32'd0; r32 <= 32'd0; ext <= 1'b0;
        end else begin
            if (sel && we && off == 8'h08) lba <= wdata;
            if (sel && we && off == 8'h0C) idx <= wdata[8:0];
            if (can_issue && st != ST_IDLE && st != ST_PREP && st != ST_EVAL) begin
                sp_start <= 1'b1; iss <= 1'b1;
                sp_tx <= (st == ST_CMD) ? cmd_byte : 8'hFF;
            end
            case (st)
                ST_IDLE: if (wr_ctrl) begin
                    if (wdata[0]) begin
                        busy <= 1'b1; init_done <= 1'b0; err <= 1'b0; sdhc <= 1'b0; fast <= 1'b0;
                        step <= S_CMD0; retry <= 10'd0; fin <= 1'b0; dcnt <= 4'd0; sd_cs_n <= 1'b1; st <= ST_DUMMY;
                    end else if (wdata[1]) begin
                        if (init_done) begin busy <= 1'b1; err <= 1'b0; fin <= 1'b0; step <= S_RD; st <= ST_PREP; end
                        else err <= 1'b1;
                    end
                end
                ST_DUMMY: if (iss && sp_done) begin               // CS=1에서 80클럭
                    iss <= 1'b0;
                    if (dcnt == 4'd9) st <= ST_PREP; else dcnt <= dcnt + 4'd1;
                end
                ST_PREP: begin
                    sd_cs_n <= 1'b0; bidx <= 3'd0; pcnt <= 4'd0; ecnt <= 3'd0; ext <= 1'b0; st <= ST_CMD;
                    case (step)
                        S_CMD0:   begin cmd <= 6'd0;  arg <= 32'h0;                crc <= 8'h95; end
                        S_CMD8:   begin cmd <= 6'd8;  arg <= 32'h0000_01AA;        crc <= 8'h87; ext <= 1'b1; end
                        S_CMD55:  begin cmd <= 6'd55; arg <= 32'h0;                crc <= 8'h65; end
                        S_ACMD41: begin cmd <= 6'd41; arg <= 32'h4000_0000;        crc <= 8'h77; end
                        S_CMD58:  begin cmd <= 6'd58; arg <= 32'h0;                crc <= 8'hFD; ext <= 1'b1; end
                        default:  begin cmd <= 6'd17; arg <= sdhc ? lba : {lba[22:0], 9'd0}; crc <= 8'hFF; end
                    endcase
                end
                ST_CMD: if (iss && sp_done) begin
                    iss <= 1'b0;
                    if (bidx == 3'd5) st <= ST_R1; else bidx <= bidx + 3'd1;
                end
                ST_R1: if (iss && sp_done) begin                  // R1 응답: 최상위 비트가 0인 첫 바이트
                    iss <= 1'b0;
                    if (!sp_rx[7]) begin r1 <= sp_rx; st <= ext ? ST_EXT : ST_EVAL; end
                    else if (pcnt == 4'd7) begin err <= 1'b1; sd_cs_n <= 1'b1; st <= ST_GAP; end
                    else pcnt <= pcnt + 4'd1;
                end
                ST_EXT: if (iss && sp_done) begin                 // R7/R3 뒤의 4바이트
                    iss <= 1'b0; r32 <= {r32[23:0], sp_rx};
                    if (ecnt == 3'd3) st <= ST_EVAL; else ecnt <= ecnt + 3'd1;
                end
                ST_EVAL: if (step == S_RD && r1 == 8'h00) begin   // CS를 올렸다 내리는 글리치를 피해 분기로 나눈다
                    tcnt <= 16'd0; st <= ST_TOKEN;
                end else begin
                    st <= ST_GAP; sd_cs_n <= 1'b1;
                    case (step)
                        S_CMD0:   if (r1 == 8'h01) step <= S_CMD8; else err <= 1'b1;
                        S_CMD8:   if (r1 == 8'h01 && r32[11:0] == 12'h1AA) step <= S_CMD55; else err <= 1'b1;
                        S_CMD55:  if ((r1 & 8'hFE) == 8'h00) step <= S_ACMD41; else err <= 1'b1;
                        S_ACMD41: if (r1 == 8'h00) step <= S_CMD58;
                                  else if (r1 == 8'h01 && retry != 10'h3FF) begin retry <= retry + 10'd1; step <= S_CMD55; end
                                  else err <= 1'b1;
                        S_CMD58:  if (r1 == 8'h00) begin sdhc <= r32[30]; init_done <= 1'b1; fast <= 1'b1; fin <= 1'b1; end
                                  else err <= 1'b1;
                        default:  err <= 1'b1;
                    endcase
                end
                ST_GAP: if (iss && sp_done) begin                 // CS=1에서 추가 8클럭
                    iss <= 1'b0;
                    if (fin || err) begin busy <= 1'b0; st <= ST_IDLE; end else st <= ST_PREP;
                end
                ST_TOKEN: if (iss && sp_done) begin               // 시작 토큰 0xFE 대기
                    iss <= 1'b0;
                    if (sp_rx == 8'hFE) begin bcnt <= 9'd0; st <= ST_DATA; end
                    else if (sp_rx == 8'hFF && tcnt != 16'hFFFF) tcnt <= tcnt + 16'd1;
                    else begin err <= 1'b1; sd_cs_n <= 1'b1; st <= ST_GAP; end
                end
                ST_DATA: if (iss && sp_done) begin                // 512바이트를 버퍼에 저장
                    iss <= 1'b0; mem[bcnt] <= sp_rx; bcnt <= bcnt + 9'd1;
                    if (bcnt == 9'd511) begin ecnt <= 3'd0; st <= ST_CRC; end
                end
                ST_CRC: if (iss && sp_done) begin                 // CRC16 2바이트는 버린다
                    iss <= 1'b0;
                    if (ecnt == 3'd1) begin fin <= 1'b1; sd_cs_n <= 1'b1; st <= ST_GAP; end
                    else ecnt <= ecnt + 3'd1;
                end
                default: st <= ST_IDLE;
            endcase
        end
    end

    always @* begin
        case (off)
            8'h04:   rdata = {28'd0, sdhc, err, init_done, busy};
            8'h08:   rdata = lba;
            8'h0C:   rdata = {23'd0, idx};
            8'h10:   rdata = {24'd0, mem_q};
            default: rdata = 32'h0000_0000;
        endcase
    end
endmodule
