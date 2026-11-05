// axil_onewire_bm.v — AXI4-Lite 1-Wire 비트 마스터 IP
// 슬롯 [0E] 0x400E_0000  intc=6  (동결 맵 mbv-frozen-v2 §[0E])
//
// 레지스터 맵 (AXI4-Lite 오프셋):
//   0x00 CTRL    RW  {IRQ_EN[16], WBIT[2], OP[1:0]}
//                      OP: 00=NOP 01=RST 10=WR_BIT 11=RD_BIT
//   0x04 STATUS  RO  {28'd0, IRQ[3], RBIT[2], PRESENCE[1], BUSY[0]}
//   0x08 START   WO  write bit[0]=1 → 한 번의 연산 시작 (self-clearing)
//   0x0C ICLR    WO  write bit[0]=1 → IRQ 클리어
//
// 1-Wire 타이밍 (100 MHz 기준, DS18B20 데이터시트):
//   RST:   DQ low 480 µs → release → sample presence at +70 µs → recovery 410 µs
//   WR0:   DQ low 71 µs → high 10 µs (recovery)
//   WR1:   DQ low  6 µs → high 64 µs (slot 완료)
//   READ:  DQ low  6 µs → release → sample at +3 µs → recovery 61 µs

`default_nettype none
`timescale 1ns/1ps

module axil_onewire_bm #(
    parameter CLK_MHZ = 100         // 클럭 주파수 (MHz)
) (
    input  wire        clk,
    input  wire        rst_n,       // active-low 동기 리셋

    // AXI4-Lite 슬레이브 포트
    input  wire [31:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire  [3:0] s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire  [1:0] s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [31:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire  [1:0] s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // 1-Wire 오픈드레인 버스
    output wire        ow_drive,    // 1 → DQ를 Low로 구동
    input  wire        ow_sense,    // DQ 현재 값 (외부 풀업 경유)

    // 인터럽트 (INTC 채널 6)
    output wire        irq
);

// ===========================================================
// 타이밍 상수 (단위: 클럭 사이클)
// ===========================================================
localparam integer TRSTL   = 480 * CLK_MHZ;   // reset low   480 µs
localparam integer TRSTW   =  70 * CLK_MHZ;   // presence 샘플 시점 +70 µs
localparam integer TRSTREC = 410 * CLK_MHZ;   // reset recovery 410 µs
localparam integer TWRL    =   6 * CLK_MHZ;   // write slot low  6 µs
localparam integer TWR0H   =  65 * CLK_MHZ;   // write-0 hold low 65 µs (총 71 µs)
localparam integer TWR0REC =  10 * CLK_MHZ;   // write-0 recovery 10 µs
localparam integer TWR1H   =  64 * CLK_MHZ;   // write-1 high 64 µs (총 70 µs)
localparam integer TRDL    =   6 * CLK_MHZ;   // read low  6 µs
localparam integer TRDW    =   3 * CLK_MHZ;   // read 대기 3 µs (sample 시점 9 µs)
localparam integer TRDREC  =  61 * CLK_MHZ;   // read recovery 61 µs (총 70 µs)

// ===========================================================
// AXI4-Lite 슬레이브 — 쓰기 채널
// ===========================================================
reg aw_done, w_done, bvalid_r;
reg [31:0] aw_addr_r, w_data_r;
reg [31:0] r_ctrl;      // 0x00 CTRL

assign s_axil_awready = !aw_done;
assign s_axil_wready  = !w_done;
assign s_axil_bresp   = 2'b00;
assign s_axil_bvalid  = bvalid_r;

// 쓰기 완료 조건 (combinational)
wire do_write = aw_done && w_done && !bvalid_r;

// START 펄스와 IRQ 클리어 (AXI 쓰기에서 도출)
wire start_trig = do_write && (aw_addr_r[3:2] == 2'b10) && w_data_r[0];
wire iclr_trig  = do_write && (aw_addr_r[3:2] == 2'b11) && w_data_r[0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_done   <= 1'b0; w_done  <= 1'b0;
        bvalid_r  <= 1'b0;
        aw_addr_r <= 32'd0; w_data_r <= 32'd0;
        r_ctrl    <= 32'd0;
    end else begin
        if (s_axil_awvalid && !aw_done) begin
            aw_done   <= 1'b1;
            aw_addr_r <= s_axil_awaddr;
        end
        if (s_axil_wvalid && !w_done) begin
            w_done   <= 1'b1;
            w_data_r <= s_axil_wdata;
        end
        if (do_write) begin
            bvalid_r <= 1'b1;
            if (aw_addr_r[3:2] == 2'b00)   // CTRL
                r_ctrl <= w_data_r;
        end
        if (bvalid_r && s_axil_bready) begin
            bvalid_r <= 1'b0;
            aw_done  <= 1'b0;
            w_done   <= 1'b0;
        end
    end
end

// ===========================================================
// AXI4-Lite 슬레이브 — 읽기 채널
// ===========================================================
reg ar_active;
reg [31:0] r_rdata;

assign s_axil_arready = !ar_active;
assign s_axil_rdata   = r_rdata;
assign s_axil_rresp   = 2'b00;
assign s_axil_rvalid  = ar_active;

// STATUS: {28'd0, irq_pend, rbit_r, presence_r, busy}
wire [31:0] status_rd = {28'd0, irq_pend, rbit_r, presence_r, busy};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ar_active <= 1'b0;
        r_rdata   <= 32'd0;
    end else begin
        if (s_axil_arvalid && !ar_active) begin
            ar_active <= 1'b1;
            case (s_axil_araddr[3:2])
                2'b00:   r_rdata <= r_ctrl;
                2'b01:   r_rdata <= status_rd;
                default: r_rdata <= 32'd0;
            endcase
        end
        if (ar_active && s_axil_rready)
            ar_active <= 1'b0;
    end
end

// ===========================================================
// 1-Wire 비트 마스터 FSM
// ===========================================================
localparam S_IDLE    = 4'd0;
localparam S_RSTL    = 4'd1;   // reset: DQ low 480 µs
localparam S_RSTSMP  = 4'd2;   // reset: release + 70 µs → sample presence
localparam S_RSTREC  = 4'd3;   // reset: recovery 410 µs
localparam S_WR0L    = 4'd4;   // write-0: low 6 µs
localparam S_WR0H    = 4'd5;   // write-0: low 65 µs (hold)
localparam S_WR0REC  = 4'd6;   // write-0: recovery 10 µs
localparam S_WR1L    = 4'd7;   // write-1: low 6 µs
localparam S_WR1H    = 4'd8;   // write-1: high 64 µs
localparam S_RDL     = 4'd9;   // read: low 6 µs
localparam S_RDW     = 4'd10;  // read: wait 3 µs
localparam S_RDSMPL  = 4'd11;  // read: sample DQ
localparam S_RDREC   = 4'd12;  // read: recovery 61 µs
localparam S_DONE    = 4'd13;  // 완료 → IRQ

reg  [3:0]  state;
reg [19:0]  cnt;         // 최대 48000 (17bit), 여유 20bit
reg         dq_drive;
reg         presence_r;
reg         rbit_r;
reg         busy;
reg         irq_pend;

wire [1:0] op   = r_ctrl[1:0];
wire       wbit = r_ctrl[2];
wire       irq_en = r_ctrl[16];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= S_IDLE;
        cnt       <= 20'd0;
        dq_drive  <= 1'b0;
        presence_r <= 1'b0;
        rbit_r    <= 1'b0;
        busy      <= 1'b0;
        irq_pend  <= 1'b0;
    end else begin
        // IRQ 클리어 (AXI 쓰기에서 도출, start_trig/iclr_trig는 1-cycle combinational)
        if (iclr_trig) irq_pend <= 1'b0;

        case (state)
        // ----- IDLE -----
        S_IDLE: begin
            busy     <= 1'b0;
            dq_drive <= 1'b0;
            if (start_trig && op != 2'b00) begin
                busy <= 1'b1;
                cnt  <= 20'd0;
                case (op)
                    2'b01: begin  // RST
                        state    <= S_RSTL;
                        dq_drive <= 1'b1;
                    end
                    2'b10: begin  // WR_BIT
                        state    <= wbit ? S_WR1L : S_WR0L;
                        dq_drive <= 1'b1;
                    end
                    2'b11: begin  // RD_BIT
                        state    <= S_RDL;
                        dq_drive <= 1'b1;
                    end
                    default: state <= S_IDLE;
                endcase
            end
        end

        // ----- RESET 시퀀스 -----
        S_RSTL: begin
            if (cnt >= TRSTL - 1) begin
                state    <= S_RSTSMP;
                cnt      <= 20'd0;
                dq_drive <= 1'b0;
            end else cnt <= cnt + 1'b1;
        end
        S_RSTSMP: begin
            if (cnt >= TRSTW - 1) begin
                presence_r <= !ow_sense;  // 장치가 DQ를 Low로 당기면 감지됨
                state      <= S_RSTREC;
                cnt        <= 20'd0;
            end else cnt <= cnt + 1'b1;
        end
        S_RSTREC: begin
            if (cnt >= TRSTREC - 1) begin state <= S_DONE; cnt <= 20'd0; end
            else cnt <= cnt + 1'b1;
        end

        // ----- WRITE 0 시퀀스 -----
        S_WR0L: begin
            if (cnt >= TWRL - 1) begin
                state <= S_WR0H; cnt <= 20'd0;
                // dq_drive는 계속 1 (hold low for WR0)
            end else cnt <= cnt + 1'b1;
        end
        S_WR0H: begin
            if (cnt >= TWR0H - 1) begin
                state    <= S_WR0REC;
                cnt      <= 20'd0;
                dq_drive <= 1'b0;
            end else cnt <= cnt + 1'b1;
        end
        S_WR0REC: begin
            if (cnt >= TWR0REC - 1) begin state <= S_DONE; cnt <= 20'd0; end
            else cnt <= cnt + 1'b1;
        end

        // ----- WRITE 1 시퀀스 -----
        S_WR1L: begin
            if (cnt >= TWRL - 1) begin
                state    <= S_WR1H;
                cnt      <= 20'd0;
                dq_drive <= 1'b0;
            end else cnt <= cnt + 1'b1;
        end
        S_WR1H: begin
            if (cnt >= TWR1H - 1) begin state <= S_DONE; cnt <= 20'd0; end
            else cnt <= cnt + 1'b1;
        end

        // ----- READ 시퀀스 -----
        S_RDL: begin
            if (cnt >= TRDL - 1) begin
                state    <= S_RDW;
                cnt      <= 20'd0;
                dq_drive <= 1'b0;
            end else cnt <= cnt + 1'b1;
        end
        S_RDW: begin
            if (cnt >= TRDW - 1) begin state <= S_RDSMPL; cnt <= 20'd0; end
            else cnt <= cnt + 1'b1;
        end
        S_RDSMPL: begin
            rbit_r <= ow_sense;
            state  <= S_RDREC;
            cnt    <= 20'd0;
        end
        S_RDREC: begin
            if (cnt >= TRDREC - 1) begin state <= S_DONE; cnt <= 20'd0; end
            else cnt <= cnt + 1'b1;
        end

        // ----- 완료 -----
        S_DONE: begin
            busy     <= 1'b0;
            dq_drive <= 1'b0;
            if (irq_en) irq_pend <= 1'b1;
            state    <= S_IDLE;
        end

        default: state <= S_IDLE;
        endcase
    end
end

// ===========================================================
// 출력 연결
// ===========================================================
assign ow_drive = dq_drive;
assign irq      = irq_pend & irq_en;

endmodule
`default_nettype wire
