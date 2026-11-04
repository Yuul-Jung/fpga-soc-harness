// uart_axilite_bridge.v — UART→AXI4-Lite 메모리 브리지
//
// UART 프레임 프로토콜:
//   쓰기: 0x57('W') + ADDR[31:0]BE + DATA[31:0]BE  (9바이트) → 응답 0x06
//   읽기: 0x52('R') + ADDR[31:0]BE                  (5바이트) → 응답 0x05 + DATA[31:0]BE
// 모든 주소는 32비트 정렬 가정. 오류 복구 없음(리셋으로 복구).
//
// 출처: 하네스 직접 작성 원본. 외부 코드 없음.

`timescale 1ns/1ps
module uart_axilite_bridge #(
    parameter BAUD_DIV = 868
) (
    input  wire        clk,
    input  wire        rst,

    // UART 핀
    input  wire        uart_rx_pin,
    output wire        uart_tx_pin,

    // AXI4-Lite 마스터 포트
    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,

    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wvalid,
    input  wire        m_wready,

    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output reg         m_bready,

    output reg  [31:0] m_araddr,
    output reg         m_arvalid,
    input  wire        m_arready,

    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rvalid,
    output reg         m_rready,

    // 상태 출력
    output reg         busy,
    output reg         err_flag
);

    // UART RX 인터페이스
    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx #(.BAUD_DIV(BAUD_DIV)) u_rx (
        .clk(clk), .rst(rst),
        .rx(uart_rx_pin),
        .data(rx_data), .valid(rx_valid)
    );

    // UART TX 인터페이스
    reg  [7:0] tx_data;
    reg        tx_valid;
    wire       tx_ready;

    uart_tx #(.BAUD_DIV(BAUD_DIV)) u_tx (
        .clk(clk), .rst(rst),
        .data(tx_data), .valid(tx_valid),
        .ready(tx_ready), .tx(uart_tx_pin)
    );

    // FSM 상태 인코딩
    localparam [3:0]
        S_IDLE   = 4'd0,
        S_ADDR0  = 4'd1,
        S_ADDR1  = 4'd2,
        S_ADDR2  = 4'd3,
        S_ADDR3  = 4'd4,
        S_WDAT0  = 4'd5,
        S_WDAT1  = 4'd6,
        S_WDAT2  = 4'd7,
        S_WDAT3  = 4'd8,
        S_AXI_AW = 4'd9,
        S_AXI_B  = 4'd10,
        S_AXI_AR = 4'd11,
        S_AXI_R  = 4'd12,
        S_TX     = 4'd13;

    reg [3:0]  state;
    reg        is_write;
    reg [31:0] addr_buf;
    reg [23:0] wdata_hi;   // wdata[31:8] (상위 3바이트 임시 저장)
    reg        aw_done, w_done;

    // TX 응답 버퍼: 최대 5바이트 (인덱스 0이 먼저 송신)
    reg [7:0]  tx_buf [0:4];
    reg [2:0]  tx_len;
    reg [2:0]  tx_idx;

    // --- 메인 FSM ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= S_IDLE;
            is_write  <= 1'b0;
            addr_buf  <= 32'h0;
            wdata_hi  <= 24'h0;
            aw_done   <= 1'b0;
            w_done    <= 1'b0;
            m_awvalid <= 1'b0;  m_awaddr <= 32'h0;
            m_wvalid  <= 1'b0;  m_wdata  <= 32'h0;  m_wstrb <= 4'hF;
            m_bready  <= 1'b0;
            m_arvalid <= 1'b0;  m_araddr <= 32'h0;
            m_rready  <= 1'b0;
            tx_valid  <= 1'b0;  tx_data  <= 8'h00;
            tx_len    <= 3'd0;  tx_idx   <= 3'd0;
            busy      <= 1'b0;  err_flag <= 1'b0;
        end else begin
            tx_valid <= 1'b0;  // 기본: 비활성 (S_TX에서 덮어씀)

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (rx_valid) begin
                        busy <= 1'b1;
                        if (rx_data == 8'h57) begin        // 'W'
                            is_write <= 1'b1;
                            state    <= S_ADDR0;
                        end else if (rx_data == 8'h52) begin  // 'R'
                            is_write <= 1'b0;
                            state    <= S_ADDR0;
                        end else begin
                            err_flag <= 1'b1;
                        end
                    end
                end

                // 주소 수신 (MSB first)
                S_ADDR0: if (rx_valid) begin addr_buf[31:24] <= rx_data; state <= S_ADDR1; end
                S_ADDR1: if (rx_valid) begin addr_buf[23:16] <= rx_data; state <= S_ADDR2; end
                S_ADDR2: if (rx_valid) begin addr_buf[15: 8] <= rx_data; state <= S_ADDR3; end
                S_ADDR3: if (rx_valid) begin
                    addr_buf[7:0] <= rx_data;
                    state <= is_write ? S_WDAT0 : S_AXI_AR;
                end

                // 쓰기 데이터 수신 (MSB first, 상위 3바이트 임시 보관)
                S_WDAT0: if (rx_valid) begin wdata_hi[23:16] <= rx_data; state <= S_WDAT1; end
                S_WDAT1: if (rx_valid) begin wdata_hi[15: 8] <= rx_data; state <= S_WDAT2; end
                S_WDAT2: if (rx_valid) begin wdata_hi[ 7: 0] <= rx_data; state <= S_WDAT3; end
                S_WDAT3: if (rx_valid) begin
                    // addr_buf 완전히 채워진 상태, rx_data = wdata[7:0]
                    m_awaddr  <= addr_buf;
                    m_awvalid <= 1'b1;
                    m_wdata   <= {wdata_hi, rx_data};
                    m_wstrb   <= 4'hF;
                    m_wvalid  <= 1'b1;
                    aw_done   <= 1'b0;
                    w_done    <= 1'b0;
                    state     <= S_AXI_AW;
                end

                // AXI4-Lite 쓰기 AW+W 채널 (동시 구동)
                S_AXI_AW: begin
                    if (m_awvalid && m_awready) begin
                        m_awvalid <= 1'b0;
                        aw_done   <= 1'b1;
                    end
                    if (m_wvalid && m_wready) begin
                        m_wvalid <= 1'b0;
                        w_done   <= 1'b1;
                    end
                    // 양쪽 채널 모두 완료 시 B 채널 대기
                    if ((aw_done || (m_awvalid && m_awready)) &&
                        (w_done  || (m_wvalid  && m_wready))) begin
                        m_awvalid <= 1'b0;
                        m_wvalid  <= 1'b0;
                        m_bready  <= 1'b1;
                        state     <= S_AXI_B;
                    end
                end

                // AXI4-Lite B 채널 대기
                S_AXI_B: begin
                    if (m_bvalid) begin
                        m_bready  <= 1'b0;
                        err_flag  <= (m_bresp != 2'b00) ? 1'b1 : err_flag;
                        tx_buf[0] <= 8'h06;   // 쓰기 ACK
                        tx_len    <= 3'd1;
                        tx_idx    <= 3'd0;
                        state     <= S_TX;
                    end
                end

                // AXI4-Lite AR 채널
                S_AXI_AR: begin
                    m_araddr  <= addr_buf;
                    m_arvalid <= 1'b1;
                    if (m_arvalid && m_arready) begin
                        m_arvalid <= 1'b0;
                        m_rready  <= 1'b1;
                        state     <= S_AXI_R;
                    end
                end

                // AXI4-Lite R 채널 대기
                S_AXI_R: begin
                    if (m_rvalid) begin
                        m_rready  <= 1'b0;
                        err_flag  <= (m_rresp != 2'b00) ? 1'b1 : err_flag;
                        tx_buf[0] <= 8'h05;             // 읽기 ACK
                        tx_buf[1] <= m_rdata[31:24];
                        tx_buf[2] <= m_rdata[23:16];
                        tx_buf[3] <= m_rdata[15: 8];
                        tx_buf[4] <= m_rdata[ 7: 0];
                        tx_len    <= 3'd5;
                        tx_idx    <= 3'd0;
                        state     <= S_TX;
                    end
                end

                // TX 응답 바이트 순차 송신
                S_TX: begin
                    if (tx_ready && !tx_valid) begin
                        if (tx_idx < tx_len) begin
                            tx_data  <= tx_buf[tx_idx];
                            tx_valid <= 1'b1;
                            tx_idx   <= tx_idx + 1;
                        end else begin
                            busy  <= 1'b0;
                            state <= S_IDLE;
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
