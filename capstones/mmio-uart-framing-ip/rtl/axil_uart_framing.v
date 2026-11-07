// axil_uart_framing.v — AXI4-Lite 슬레이브 + UART 프레이밍 FSM
// 주소 베이스: 0x402A_0000 (동결 맵 free_slots[2A])
// 로컬 주소 오프셋 (상위 비트 디코더 외부):
//   0x00 STATUS  RO  [0]=PKT_DONE [1]=CRC_OK [2]=RX_ACTIVE [7]=OVERFLOW
//   0x04 CTRL    RW  [0]=IRQ_EN   [1]=CLR_DONE(자동 클리어)
//   0x08 BAUD_DIV RW  115200@100MHz→54
//   0x0C PKT_TYPE RO
//   0x10 PKT_LEN  RO
//   0x14 DATA_0  RO  페이로드 바이트 0
//   0x15 DATA_1  RO
//   0x16 DATA_2  RO
//   0x17 DATA_3  RO
//   0x18 PKT_CRC      RO  수신된 CRC (상위 바이트 먼저)
//   0x1C PKT_CRC_CALC RO  계산된 CRC

`timescale 1ns/1ps
module axil_uart_framing (
    // AXI4-Lite 슬레이브 포트
    input  wire        ACLK,
    input  wire        ARESETn,
    // Write address
    input  wire [7:0]  AWADDR,
    input  wire        AWVALID,
    output reg         AWREADY,
    // Write data
    input  wire [31:0] WDATA,
    input  wire [3:0]  WSTRB,
    input  wire        WVALID,
    output reg         WREADY,
    // Write response
    output reg  [1:0]  BRESP,
    output reg         BVALID,
    input  wire        BREADY,
    // Read address
    input  wire [7:0]  ARADDR,
    input  wire        ARVALID,
    output reg         ARREADY,
    // Read data
    output reg  [31:0] RDATA,
    output reg  [1:0]  RRESP,
    output reg         RVALID,
    input  wire        RREADY,
    // 외부 UART RX
    input  wire        uart_rx,
    // 인터럽트 출력
    output reg         irq
);

// ── 레지스터 ────────────────────────────────────────────────
reg  [15:0] baud_div_reg;   // 초기값 54 (115200 @ 100MHz)
reg         irq_en;

reg         pkt_done;
reg         crc_ok;
reg         rx_active;
reg         overflow;

reg  [7:0]  pkt_type_r;
reg  [7:0]  pkt_len_r;
reg  [7:0]  data_buf [0:3];
reg  [15:0] pkt_crc_r;
reg  [15:0] pkt_crc_calc_r;

// ── UART RX 인스턴스 ────────────────────────────────────────
wire [7:0]  rx_data;
wire        rx_valid;

uart_rx u_rx (
    .clk      (ACLK),
    .rst_n    (ARESETn),
    .baud_div (baud_div_reg),
    .rx       (uart_rx),
    .rx_data  (rx_data),
    .rx_valid (rx_valid)
);

// ── CRC 인스턴스 ─────────────────────────────────────────────
reg         crc_rst_r;
reg  [7:0]  crc_data_r;
reg         crc_valid_r;
wire [15:0] crc_out;

crc16_xor u_crc (
    .clk        (ACLK),
    .rst_n      (ARESETn),
    .crc_rst    (crc_rst_r),
    .data_in    (crc_data_r),
    .data_valid (crc_valid_r),
    .crc_out    (crc_out)
);

// ── 프레임 FSM ───────────────────────────────────────────────
// 프레임 형식: [LEN][TYPE][PAYLOAD × LEN][CRC_HI][CRC_LO]
localparam F_IDLE    = 3'd0;
localparam F_LEN     = 3'd1;   // LEN 바이트 대기
localparam F_TYPE    = 3'd2;   // TYPE 바이트 수신 완료 직후
localparam F_PAYLOAD = 3'd3;   // 페이로드 바이트 수신
localparam F_CRC_HI  = 3'd4;   // CRC 상위 바이트 수신
localparam F_CRC_LO  = 3'd5;   // CRC 하위 바이트, 패킷 완료

reg [2:0] fstate;
reg [7:0] byte_cnt;    // 수신한 페이로드 바이트 수
reg [7:0] len_latch;   // 수신한 LEN 값

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        fstate        <= F_IDLE;
        byte_cnt      <= 8'd0;
        len_latch     <= 8'd0;
        pkt_done      <= 1'b0;
        crc_ok        <= 1'b0;
        rx_active     <= 1'b0;
        overflow      <= 1'b0;
        pkt_type_r    <= 8'd0;
        pkt_len_r     <= 8'd0;
        data_buf[0]   <= 8'd0;
        data_buf[1]   <= 8'd0;
        data_buf[2]   <= 8'd0;
        data_buf[3]   <= 8'd0;
        pkt_crc_r     <= 16'd0;
        pkt_crc_calc_r<= 16'd0;
        crc_rst_r     <= 1'b0;
        crc_data_r    <= 8'd0;
        crc_valid_r   <= 1'b0;
        irq           <= 1'b0;
    end else begin
        // 기본 strobe 클리어
        crc_rst_r   <= 1'b0;
        crc_valid_r <= 1'b0;
        irq         <= 1'b0;

        case (fstate)
        F_IDLE: begin
            rx_active <= 1'b0;
            if (rx_valid) begin
                // 첫 바이트 = LEN
                len_latch   <= rx_data;
                pkt_len_r   <= rx_data;
                byte_cnt    <= 8'd0;
                rx_active   <= 1'b1;
                // CRC 리셋 → LEN 포함해서 계산 시작
                crc_rst_r   <= 1'b1;
                // CRC는 다음 클럭부터 반영되므로 LEN 바이트를 한 클럭 뒤에 넣는다
                fstate      <= F_LEN;
            end
        end

        F_LEN: begin
            // CRC 리셋이 완료된 첫 클럭: LEN 바이트를 CRC에 투입
            crc_data_r  <= len_latch;
            crc_valid_r <= 1'b1;
            fstate      <= F_TYPE;
        end

        F_TYPE: begin
            if (rx_valid) begin
                pkt_type_r  <= rx_data;
                // TYPE 바이트 CRC에 투입
                crc_data_r  <= rx_data;
                crc_valid_r <= 1'b1;
                if (len_latch == 8'd0) begin
                    fstate  <= F_CRC_HI;  // 페이로드 없음
                end else begin
                    fstate  <= F_PAYLOAD;
                end
            end
        end

        F_PAYLOAD: begin
            if (rx_valid) begin
                // CRC에 페이로드 바이트 투입
                crc_data_r  <= rx_data;
                crc_valid_r <= 1'b1;
                // 처음 4바이트만 버퍼에 저장
                if (byte_cnt < 8'd4) begin
                    data_buf[byte_cnt[1:0]] <= rx_data;
                end else begin
                    overflow <= 1'b1;  // 5바이트 이상: 오버플로 플래그 (버림)
                end
                byte_cnt <= byte_cnt + 8'd1;
                if (byte_cnt == len_latch - 1) begin
                    fstate <= F_CRC_HI;
                end
            end
        end

        F_CRC_HI: begin
            if (rx_valid) begin
                pkt_crc_r[15:8] <= rx_data;  // CRC 상위 바이트
                fstate           <= F_CRC_LO;
            end
        end

        F_CRC_LO: begin
            if (rx_valid) begin
                pkt_crc_r[7:0]  <= rx_data;  // CRC 하위 바이트
                pkt_crc_calc_r   <= crc_out;  // 누적된 CRC 캡처
                pkt_done         <= 1'b1;
                rx_active        <= 1'b0;
                // CRC 비교: 수신 CRC = {pkt_crc_r[15:8], rx_data}
                crc_ok           <= (crc_out == {pkt_crc_r[15:8], rx_data});
                irq              <= irq_en;
                fstate           <= F_IDLE;
            end
        end

        default: fstate <= F_IDLE;
        endcase
    end
end

// ── AXI4-Lite 쓰기 채널 ─────────────────────────────────────
reg [7:0] aw_addr_lat;
reg       aw_done;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        AWREADY       <= 1'b0;
        WREADY        <= 1'b0;
        BVALID        <= 1'b0;
        BRESP         <= 2'b00;
        aw_done       <= 1'b0;
        aw_addr_lat   <= 8'd0;
        baud_div_reg  <= 16'd54;
        irq_en        <= 1'b0;
    end else begin
        AWREADY <= 1'b0;
        WREADY  <= 1'b0;

        if (AWVALID && !aw_done) begin
            AWREADY     <= 1'b1;
            aw_addr_lat <= AWADDR;
            aw_done     <= 1'b1;
        end

        if (WVALID && aw_done) begin
            WREADY  <= 1'b1;
            aw_done <= 1'b0;
            BVALID  <= 1'b1;
            BRESP   <= 2'b00; // OKAY

            case (aw_addr_lat[4:0])
            5'h04: begin  // CTRL
                irq_en  <= WDATA[0];
                // CLR_DONE: 비트1이 1이면 pkt_done 클리어
                if (WDATA[1]) begin
                    // pkt_done 클리어는 FSM 도메인 외부에서 직접 처리
                    // (같은 클럭 도메인이므로 안전)
                end
            end
            5'h08: baud_div_reg <= WDATA[15:0];  // BAUD_DIV
            default: ;  // RO 레지스터 쓰기는 무시
            endcase

            // CLR_DONE 처리
            if (aw_addr_lat[4:0] == 5'h04 && WDATA[1])
                pkt_done <= 1'b0;
        end

        if (BVALID && BREADY) BVALID <= 1'b0;
    end
end

// ── AXI4-Lite 읽기 채널 ─────────────────────────────────────
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        ARREADY <= 1'b0;
        RVALID  <= 1'b0;
        RDATA   <= 32'd0;
        RRESP   <= 2'b00;
    end else begin
        ARREADY <= 1'b0;

        if (ARVALID && !RVALID) begin
            ARREADY <= 1'b1;
            RVALID  <= 1'b1;
            RRESP   <= 2'b00;
            case (ARADDR[4:0])
            5'h00: RDATA <= {24'd0, overflow, 4'd0, rx_active, crc_ok, pkt_done};
            5'h04: RDATA <= {30'd0, irq_en};
            5'h08: RDATA <= {16'd0, baud_div_reg};
            5'h0C: RDATA <= {24'd0, pkt_type_r};
            5'h10: RDATA <= {24'd0, pkt_len_r};
            5'h14: RDATA <= {24'd0, data_buf[0]};
            5'h15: RDATA <= {24'd0, data_buf[1]};
            5'h16: RDATA <= {24'd0, data_buf[2]};
            5'h17: RDATA <= {24'd0, data_buf[3]};
            5'h18: RDATA <= {16'd0, pkt_crc_r};
            5'h1C: RDATA <= {16'd0, pkt_crc_calc_r};
            default: RDATA <= 32'hDEAD_BEEF;
            endcase
        end

        if (RVALID && RREADY) RVALID <= 1'b0;
    end
end

endmodule
