// axil_can_fd_rx.v — AXI4-Lite 슬레이브 + CAN 2.0A 수신 FSM
// CAN 500 kbit/s, 100 MHz 클럭 → 200 클럭/비트, 샘플점 150번째 클럭(75%)
// CAN FD FDF 비트 감지(STATUS[2]) 포함. 데이터 완전 파싱은 CAN 2.0A(8바이트 이하).
//
// 레지스터 맵 (로컬 오프셋, 베이스 0x4017_0000은 인터커넥트가 처리):
//   0x00  STATUS    RO  bit0=VALID, bit1=ERR, bit2=FD_FRAME, bit3=BRS
//   0x04  CTRL      WO  bit0=CLR_VALID (VALID·ERR 클리어)
//   0x08  FILTER_ID RW  수신 허용 ID[10:0]
//   0x0C  FILTER_MSK RW 마스크[10:0] (1=비교, 0=무시)
//   0x10  FRAME_ID  RO  수신 ID[10:0]
//   0x14  FRAME_DLC RO  DLC[3:0]
//   0x18  DATA0..DATA7  RO  데이터 바이트 0~7 (오프셋 0x18~0x34)

`timescale 1ns/1ps

module axil_can_fd_rx #(
    parameter DATA_W      = 32,
    parameter ADDR_W      = 6,
    parameter CLK_PER_BIT = 200,   // 100 MHz / 500 kbit/s = 200
    parameter SAMPLE_PT   = 150    // 샘플 포인트 카운터값 (0부터 셈)
) (
    input  wire                s_axi_aclk,
    input  wire                s_axi_aresetn,
    // Write address
    input  wire [ADDR_W-1:0]   s_axi_awaddr,
    input  wire                s_axi_awvalid,
    output reg                 s_axi_awready,
    // Write data
    input  wire [DATA_W-1:0]   s_axi_wdata,
    input  wire [DATA_W/8-1:0] s_axi_wstrb,
    input  wire                s_axi_wvalid,
    output reg                 s_axi_wready,
    // Write response
    output reg  [1:0]          s_axi_bresp,
    output reg                 s_axi_bvalid,
    input  wire                s_axi_bready,
    // Read address
    input  wire [ADDR_W-1:0]   s_axi_araddr,
    input  wire                s_axi_arvalid,
    output reg                 s_axi_arready,
    // Read data
    output reg  [DATA_W-1:0]   s_axi_rdata,
    output reg  [1:0]          s_axi_rresp,
    output reg                 s_axi_rvalid,
    input  wire                s_axi_rready,
    // CAN 수신 (트랜시버 RXD, 도미넌트=0 리세시브=1)
    input  wire                can_rx
);

    localparam [14:0] CRC_POLY = 15'h4599;

    // FSM 상태
    localparam [3:0]
        S_IDLE = 4'd0, S_ID   = 4'd1, S_CTRL = 4'd2,
        S_DATA = 4'd3, S_CRC  = 4'd4, S_CDELIM = 4'd5,
        S_ACK  = 4'd6, S_EOF  = 4'd7, S_IFS  = 4'd8,
        S_SOF  = 4'd9;  // SOF 샘플 흡수 상태 (첫 vb는 SOF 비트 샘플)

    // ------------------------------------------------------------------
    // CAN RX 2단 FF 동기화
    // ------------------------------------------------------------------
    reg can_s1, can_s2, can_prev;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            can_s1 <= 1'b1; can_s2 <= 1'b1; can_prev <= 1'b1;
        end else begin
            can_s1 <= can_rx; can_s2 <= can_s1; can_prev <= can_s2;
        end
    end
    wire sof_edge = can_prev & ~can_s2;

    // ------------------------------------------------------------------
    // 비트 타이밍
    // ------------------------------------------------------------------
    reg [7:0] bclk;
    reg       synced;
    reg       bit_samp;  // 샘플 포인트 1클럭 펄스
    reg       bit_endd;  // 비트 끝 1클럭 펄스 (unused signal 억제용)

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            bclk <= 8'd0; synced <= 1'b0;
            bit_samp <= 1'b0; bit_endd <= 1'b0;
        end else begin
            bit_samp <= 1'b0; bit_endd <= 1'b0;
            if (!synced) begin
                if (sof_edge) begin bclk <= 8'd1; synced <= 1'b1; end
            end else if (sync_clr) begin
                synced <= 1'b0; bclk <= 8'd0;
            end else begin
                if (bclk == CLK_PER_BIT[7:0] - 8'd1) begin
                    bclk <= 8'd0; bit_endd <= 1'b1;
                end else begin
                    bclk <= bclk + 8'd1;
                end
                if (bclk == SAMPLE_PT[7:0] - 8'd1) bit_samp <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // 스터프 비트 감지
    // ------------------------------------------------------------------
    reg [2:0] scnt;
    reg       slast;
    reg       is_stuff;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            scnt <= 3'd1; slast <= 1'b1; is_stuff <= 1'b0;
        end else begin
            is_stuff <= 1'b0;
            if (bit_samp && synced) begin
                if (can_s2 == slast) begin
                    if (scnt == 3'd4) begin
                        is_stuff <= 1'b1; scnt <= 3'd1;
                    end else scnt <= scnt + 3'd1;
                end else begin
                    slast <= can_s2; scnt <= 3'd1;
                end
            end
        end
    end

    wire vb = bit_samp & ~is_stuff & synced;  // 유효 비트 펄스

    // ------------------------------------------------------------------
    // CAN 15비트 CRC (순차 로직)
    // ------------------------------------------------------------------
    reg [14:0] crc_r;
    wire       crc_b   = can_s2 ^ crc_r[14];
    wire [14:0] crc_nx = {crc_r[13:0], 1'b0} ^ (crc_b ? CRC_POLY : 15'd0);

    // ------------------------------------------------------------------
    // CAN FSM
    // ------------------------------------------------------------------
    reg [3:0]  fst;
    reg [3:0]  fidx;
    reg [10:0] rx_id;
    reg [3:0]  rx_dlc;
    reg [6:0]  rx_dbit;      // 현재 데이터 비트 인덱스
    reg [6:0]  rx_dmax;      // 총 데이터 비트 수 = DLC*8
    reg [63:0] rx_dshift;    // 데이터 직접 배치 레지스터
    reg [14:0] rx_crc;       // 수신된 CRC 필드값
    reg        rx_fdf;       // FDF 비트
    reg [2:0]  eof_c;
    reg [1:0]  ifs_c;
    reg [2:0]  rx_byte_i;    // 현재 수신 중인 바이트 인덱스 (0=첫 바이트)
    reg [2:0]  rx_bit_i;     // 현재 바이트 내 비트 인덱스 (0=MSB)

    // FSM→레지스터 완료 신호 (1클럭 펄스)
    reg pls_ok;    // 프레임 수신 완료 (필터 통과 후 래치 필요)
    reg pls_err;   // 오류

    // DLC → 바이트 수 (최대 8)
    function [3:0] d2b;
        input [3:0] d;
        begin d2b = (d > 4'd8) ? 4'd8 : d; end
    endfunction

    // 필터 레지스터 (AXI에서 구동, FSM이 읽음)
    reg [10:0] filt_id;
    reg [10:0] filt_msk;
    wire filter_pass = (filt_msk == 11'd0) ||
                       ((rx_id & filt_msk) == (filt_id & filt_msk));

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            fst <= S_IDLE; fidx <= 4'd0;
            rx_id <= 11'd0; rx_dlc <= 4'd0;
            rx_dbit <= 7'd0; rx_dmax <= 7'd0;
            rx_dshift <= 64'd0; rx_crc <= 15'd0;
            rx_fdf <= 1'b0; eof_c <= 3'd0; ifs_c <= 2'd0;
            rx_byte_i <= 3'd0; rx_bit_i <= 3'd0;
            pls_ok <= 1'b0; pls_err <= 1'b0;
            crc_r <= 15'd0;
        end else begin
            pls_ok <= 1'b0; pls_err <= 1'b0;

            case (fst)
                S_IDLE: begin
                    if (sof_edge) begin
                        // SOF 비트=0을 CRC에 반영
                        crc_r <= crc_nx;
                        rx_id <= 11'd0; rx_dlc <= 4'd0;
                        rx_dshift <= 64'd0; rx_fdf <= 1'b0;
                        fst <= S_SOF; fidx <= 4'd0;
                    end
                end

                S_ID: begin
                    if (vb) begin
                        rx_id <= {rx_id[9:0], can_s2};
                        crc_r <= crc_nx;
                        if (fidx == 4'd10) begin
                            fst <= S_CTRL; fidx <= 4'd0;
                        end else fidx <= fidx + 4'd1;
                    end
                end

                S_CTRL: begin
                    // fidx0=IDE, fidx1=r0/FDF, fidx2..5=DLC
                    if (vb) begin
                        crc_r <= crc_nx;
                        if (fidx == 4'd0) begin
                            if (can_s2) begin  // 확장 프레임 → 미지원
                                pls_err <= 1'b1; fst <= S_IFS; ifs_c <= 2'd0;
                            end
                        end else if (fidx == 4'd1) begin
                            rx_fdf <= can_s2;
                        end else begin
                            rx_dlc <= {rx_dlc[2:0], can_s2};
                            if (fidx == 4'd5) begin
                                rx_dmax <= {3'd0, d2b({rx_dlc[2:0], can_s2})} * 7'd8;
                                rx_dbit <= 7'd0;
                                rx_byte_i <= 3'd0; rx_bit_i <= 3'd0;
                                fst <= (d2b({rx_dlc[2:0], can_s2}) == 4'd0) ? S_CRC : S_DATA;
                                fidx <= 4'd0;
                            end
                        end
                        if (fst == S_CTRL && fidx != 4'd5) fidx <= fidx + 4'd1;
                    end
                end

                S_DATA: begin
                    if (vb) begin
                        // 직접 비트 배치: byte_i번째 바이트의 (7-bit_i) 위치에 저장
                        // CAN은 MSB first이므로 rx_bit_i=0이 bit7(MSB)
                        rx_dshift[{rx_byte_i, (3'd7 - rx_bit_i)}] <= can_s2;
                        if (rx_bit_i == 3'd7) begin
                            rx_bit_i  <= 3'd0;
                            rx_byte_i <= rx_byte_i + 3'd1;
                        end else begin
                            rx_bit_i <= rx_bit_i + 3'd1;
                        end
                        crc_r <= crc_nx;
                        if (rx_dbit == rx_dmax - 7'd1) begin
                            fst <= S_CRC; fidx <= 4'd0; rx_crc <= 15'd0;
                        end else begin
                            rx_dbit <= rx_dbit + 7'd1;
                        end
                    end
                end

                S_CRC: begin
                    if (vb) begin
                        rx_crc <= {rx_crc[13:0], can_s2};
                        if (fidx == 4'd14) fst <= S_CDELIM;
                        else fidx <= fidx + 4'd1;
                    end
                end

                S_CDELIM: begin
                    if (vb) begin
                        if (!can_s2 || (rx_crc != crc_r)) begin
                            pls_err <= 1'b1; fst <= S_IFS; ifs_c <= 2'd0;
                        end else begin
                            fst <= S_ACK; fidx <= 4'd0;
                        end
                    end
                end

                S_ACK: begin
                    // ACK 슬롯 + ACK 구분자 = 2비트
                    if (vb) begin
                        if (fidx == 4'd1) begin
                            fst <= S_EOF; eof_c <= 3'd0;
                        end else fidx <= fidx + 4'd1;
                    end
                end

                S_EOF: begin
                    if (vb) begin
                        if (!can_s2) begin
                            pls_err <= 1'b1; fst <= S_IFS; ifs_c <= 2'd0;
                        end else if (eof_c == 3'd6) begin
                            pls_ok <= 1'b1;  // 완료
                            fst <= S_IFS; ifs_c <= 2'd0;
                        end else eof_c <= eof_c + 3'd1;
                    end
                end

                S_IFS: begin
                    if (vb) begin
                        if (ifs_c == 2'd2) fst <= S_IDLE;
                        else ifs_c <= ifs_c + 2'd1;
                    end
                end

                S_SOF: begin
                    if (vb) begin
                        // SOF 비트 샘플 흡수 (CRC는 sof_edge 시점에 이미 반영됨)
                        fst <= S_ID; fidx <= 4'd0;
                    end
                end

                default: fst <= S_IDLE;
            endcase
        end
    end

    // IFS 완료 시 비트 타이밍 동기화 해제: FSM이 sync_clr를 1클럭 올리고
    // 비트 타이밍 always (위)가 받아서 synced를 클리어한다.
    reg sync_clr;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) sync_clr <= 1'b0;
        else sync_clr <= (fst == S_IFS) && vb && (ifs_c == 2'd2);
    end

    // ===================================================================
    // 상태·래치 레지스터 (단일 always 구동)
    // ===================================================================
    reg [3:0]  status_r;
    reg [10:0] latch_id;
    reg [3:0]  latch_dlc;
    reg [63:0] latch_data;

    // AXI 쓰기 CLR 신호
    reg do_clr;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            status_r   <= 4'd0;
            latch_id   <= 11'd0;
            latch_dlc  <= 4'd0;
            latch_data <= 64'd0;
        end else begin
            if (do_clr) begin
                status_r[0] <= 1'b0;
                status_r[1] <= 1'b0;
            end
            if (pls_err) status_r[1] <= 1'b1;
            if (pls_ok && filter_pass) begin
                status_r[0] <= 1'b1;
                status_r[1] <= 1'b0;
                status_r[2] <= rx_fdf;
                status_r[3] <= 1'b0;
                latch_id    <= rx_id;
                latch_dlc   <= rx_dlc;
                // rx_dshift: MSB-first 누적, DLC*8비트가 최하위에 정렬됨
                // DLC=2: rx_dshift[15:0] = byte0·byte1
                // latch_data[63:0]에서 사용 시 최상위 바이트가 byte0
                // rx_dshift: 직접 배치 방식 — byte0→[7:0], byte1→[15:8], ...
                latch_data  <= rx_dshift;
            end
        end
    end

    // ===================================================================
    // AXI4-Lite 쓰기 채널
    // ===================================================================
    reg [ADDR_W-1:0] aw_lat;
    reg              aw_vld;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_lat        <= {ADDR_W{1'b0}};
            aw_vld        <= 1'b0;
            filt_id       <= 11'd0;
            filt_msk      <= 11'd0;
            do_clr        <= 1'b0;
        end else begin
            do_clr <= 1'b0;
            if (s_axi_awvalid && !s_axi_awready) begin
                s_axi_awready <= 1'b1;
                aw_lat        <= s_axi_awaddr;
                aw_vld        <= 1'b1;
            end else s_axi_awready <= 1'b0;
            if (s_axi_wvalid && !s_axi_wready) s_axi_wready <= 1'b1;
            else s_axi_wready <= 1'b0;
            if (aw_vld && s_axi_wvalid) begin
                aw_vld <= 1'b0;
                case (aw_lat[5:2])
                    4'd1: begin  // CTRL
                        if (s_axi_wstrb[0] && s_axi_wdata[0]) do_clr <= 1'b1;
                    end
                    4'd2: begin  // FILTER_ID
                        if (s_axi_wstrb[0]) filt_id[7:0]  <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) filt_id[10:8] <= s_axi_wdata[10:8];
                    end
                    4'd3: begin  // FILTER_MSK
                        if (s_axi_wstrb[0]) filt_msk[7:0]  <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) filt_msk[10:8] <= s_axi_wdata[10:8];
                    end
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 1'b0;
        end
    end

    // ===================================================================
    // AXI4-Lite 읽기 채널
    // ===================================================================
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_W{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_arready) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[5:2])
                    4'd0: s_axi_rdata <= {{(DATA_W-4){1'b0}}, status_r};
                    4'd4: s_axi_rdata <= {{(DATA_W-11){1'b0}}, latch_id};
                    4'd5: s_axi_rdata <= {{(DATA_W-4){1'b0}}, latch_dlc};
                    4'd6: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[7:0]};
                    4'd7: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[15:8]};
                    4'd8: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[23:16]};
                    4'd9: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[31:24]};
                    4'd10: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[39:32]};
                    4'd11: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[47:40]};
                    4'd12: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[55:48]};
                    4'd13: s_axi_rdata <= {{(DATA_W-8){1'b0}}, latch_data[63:56]};
                    default: s_axi_rdata <= {DATA_W{1'b0}};
                endcase
            end else s_axi_arready <= 1'b0;
            if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 1'b0;
        end
    end

    // ===================================================================
    // 미사용 신호 억제 (Verilator -Wall)
    // ===================================================================
    // s_axi_wdata[31:11]: 필터 쓰기에서 bit10:0만 사용
    // s_axi_wstrb[3:2]: 바이트 레인 2·3 미사용 (11비트 필터는 최대 wstrb[1:0])
    // s_axi_araddr[1:0], aw_lat[1:0]: 워드 정렬, 디코드는 [5:2]만 사용
    // bit_endd: 비트 타이밍 블록에서 세팅되지만 FSM은 bit_samp만 쓴다
    // ADDR_W=6이므로 awaddr/araddr 전체([5:0])가 디코드에 사용 → 상위 미사용 비트 없음
    wire _unused_ok = &{1'b0,
        s_axi_wdata[DATA_W-1:11],
        s_axi_wstrb[DATA_W/8-1:2],
        s_axi_araddr[1:0],
        aw_lat[1:0],
        bit_endd,
        1'b0
    };

endmodule
