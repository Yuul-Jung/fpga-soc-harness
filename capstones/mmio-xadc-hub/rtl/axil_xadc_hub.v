// axil_xadc_hub.v
// XADC 4채널 AXI4-Lite 허브 IP (DRP FSM + 레지스터 파일)
// Verilog-2001. iverilog/verilator/yosys 호환.
// XADC 프리미티브는 basys3_xadc_top.v가 담당하며 이 파일은 DRP 인터페이스만 사용.
// 출처: capstones/mmio-xadc-hub/capstone.json
`default_nettype none
`timescale 1ns/1ps

module axil_xadc_hub #(
    parameter BASE_ADDR = 32'h4009_0000
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // AW
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // W
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // B
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // AR
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // R
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // DRP interface (to XADC primitive)
    output reg         drp_den,
    output reg         drp_dwe,
    output reg  [6:0]  drp_daddr,
    output reg  [15:0] drp_di,
    input  wire [15:0] drp_do,
    input  wire        drp_drdy,
    // Interrupt
    output wire        irq
);

    // -----------------------------------------------------------------------
    // XADC 채널 주소 (Artix-7 JXADC 핀 매핑)
    // -----------------------------------------------------------------------
    localparam [6:0] VAUX0 = 7'h10;  // JXADC 핀 1(P)/7(N)
    localparam [6:0] VAUX1 = 7'h11;  // JXADC 핀 2(P)/8(N)
    localparam [6:0] VAUX8 = 7'h18;  // JXADC 핀 3(P)/9(N)
    localparam [6:0] VAUX9 = 7'h19;  // JXADC 핀 4(P)/10(N)

    // -----------------------------------------------------------------------
    // DRP FSM 상태
    // -----------------------------------------------------------------------
    localparam [2:0] S_IDLE    = 3'd0,
                     S_REQ     = 3'd1,
                     S_WAIT    = 3'd2,
                     S_ACCUM   = 3'd3,
                     S_NEXT    = 3'd4,
                     S_COMPUTE = 3'd5,
                     S_DONE    = 3'd6;

    // -----------------------------------------------------------------------
    // 레지스터 오프셋 (기저 주소 0x4009_0000 기준)
    // -----------------------------------------------------------------------
    localparam [7:0] REG_CH0    = 8'h00,  // VAUX0 평균값 RO
                     REG_CH1    = 8'h04,  // VAUX1 평균값 RO
                     REG_CH2    = 8'h08,  // VAUX8 평균값 RO
                     REG_CH3    = 8'h0C,  // VAUX9 평균값 RO
                     REG_STATUS = 8'h10,  // [7:4]=ch_valid [0]=busy RO
                     REG_CTRL   = 8'h14,  // [4:2]=avg_sel [0]=en RW
                     REG_IRQ_EN = 8'h18,  // [0]=irq_en RW
                     REG_IRQ_ST = 8'h1C,  // [0]=irq_stat W1C
                     REG_IDVER  = 8'hFC;  // 0x0032_0100 RO

    // -----------------------------------------------------------------------
    // 채널 주소 선택 함수
    // -----------------------------------------------------------------------
    function [6:0] ch_addr;
        input [1:0] ch;
        begin
            case (ch)
                2'd0: ch_addr = VAUX0;
                2'd1: ch_addr = VAUX1;
                2'd2: ch_addr = VAUX8;
                2'd3: ch_addr = VAUX9;
                default: ch_addr = VAUX0;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // 이동 평균 계산 함수 (accum >> sel의 하위 12비트)
    // -----------------------------------------------------------------------
    function [11:0] avg12;
        input [19:0] sum;
        input [2:0]  sel;
        reg [19:0] tmp;
        begin
            tmp   = sum >> sel;
            avg12 = tmp[11:0];
        end
    endfunction

    // -----------------------------------------------------------------------
    // 내부 레지스터
    // -----------------------------------------------------------------------
    // AXI 쓰기 래치
    reg        aw_ok;
    reg  [7:0] aw_a;
    reg        wd_ok;
    reg [31:0] wd_d;
    reg        do_wr;

    // 제어·상태 레지스터
    reg        ctrl_en;
    reg  [2:0] ctrl_avg;
    reg        irq_en;
    reg        irq_stat;
    reg        scan_done;   // 1클럭 펄스, Block 4→Block 2 전달

    // 채널 결과
    reg [11:0] ch_avg_r [0:3];
    reg  [3:0] ch_valid_r;
    reg        fsm_busy;

    // DRP FSM
    reg  [2:0] state;
    reg  [1:0] ch_ptr;
    reg  [4:0] scan_cnt;
    reg [19:0] accum [0:3];

    wire [4:0] avg_len = 5'd1 << ctrl_avg;

    // -----------------------------------------------------------------------
    // Block 1: AXI 쓰기 채널 래치 (aw_ok / wd_ok 패턴)
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_ok  <= 1'b0;
            aw_a   <= 8'h00;
            wd_ok  <= 1'b0;
            wd_d   <= 32'h0;
            do_wr  <= 1'b0;
        end else begin
            do_wr         <= 1'b0;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            if (s_axi_awvalid && !aw_ok) begin
                s_axi_awready <= 1'b1;
                aw_ok         <= 1'b1;
                aw_a          <= s_axi_awaddr[7:0];
            end

            if (s_axi_wvalid && !wd_ok) begin
                s_axi_wready <= 1'b1;
                wd_ok        <= 1'b1;
                wd_d         <= s_axi_wdata;
            end

            if (aw_ok && wd_ok) begin
                do_wr        <= 1'b1;
                aw_ok        <= 1'b0;
                wd_ok        <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // -----------------------------------------------------------------------
    // Block 2: 레지스터 파일 (단일 드라이버)
    // W1C 클리어 먼저, scan_done 세트가 같은 클럭에 오면 세트가 이긴다
    // (비차단 대입 순서: 클리어 먼저 ← scan_done 뒤에)
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            ctrl_en  <= 1'b0;
            ctrl_avg <= 3'd0;
            irq_en   <= 1'b0;
            irq_stat <= 1'b0;
        end else begin
            // W1C 클리어 (먼저)
            if (do_wr && (aw_a == REG_IRQ_ST))
                irq_stat <= irq_stat & ~wd_d[0];

            // scan_done 세트 (나중 → 같은 클럭이면 덮어씀)
            if (scan_done)
                irq_stat <= 1'b1;

            // CTRL 쓰기
            if (do_wr && (aw_a == REG_CTRL)) begin
                ctrl_en  <= wd_d[0];
                ctrl_avg <= wd_d[4:2];
            end

            // IRQ_EN 쓰기
            if (do_wr && (aw_a == REG_IRQ_EN))
                irq_en <= wd_d[0];
        end
    end

    // -----------------------------------------------------------------------
    // Block 3: AXI 읽기 채널
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
            s_axi_rresp   <= 2'b00;
        end else begin
            s_axi_arready <= 1'b0;

            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[7:0])
                    REG_CH0:    s_axi_rdata <= {20'h0, ch_avg_r[0]};
                    REG_CH1:    s_axi_rdata <= {20'h0, ch_avg_r[1]};
                    REG_CH2:    s_axi_rdata <= {20'h0, ch_avg_r[2]};
                    REG_CH3:    s_axi_rdata <= {20'h0, ch_avg_r[3]};
                    REG_STATUS: s_axi_rdata <= {24'h0, ch_valid_r, 3'b000, fsm_busy};
                    REG_CTRL:   s_axi_rdata <= {27'h0, ctrl_avg, 1'b0, ctrl_en};
                    REG_IRQ_EN: s_axi_rdata <= {31'h0, irq_en};
                    REG_IRQ_ST: s_axi_rdata <= {31'h0, irq_stat};
                    REG_IDVER:  s_axi_rdata <= 32'h0032_0100;
                    default:    s_axi_rdata <= 32'h0;
                endcase
            end

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end

    // -----------------------------------------------------------------------
    // Block 4: DRP FSM (순환 스캔 + 이동 평균)
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            state       <= S_IDLE;
            ch_ptr      <= 2'd0;
            scan_cnt    <= 5'd0;
            drp_den     <= 1'b0;
            drp_dwe     <= 1'b0;
            drp_daddr   <= 7'h0;
            drp_di      <= 16'h0;
            fsm_busy    <= 1'b0;
            ch_valid_r  <= 4'h0;
            scan_done   <= 1'b0;
            accum[0]    <= 20'h0;
            accum[1]    <= 20'h0;
            accum[2]    <= 20'h0;
            accum[3]    <= 20'h0;
            ch_avg_r[0] <= 12'h0;
            ch_avg_r[1] <= 12'h0;
            ch_avg_r[2] <= 12'h0;
            ch_avg_r[3] <= 12'h0;
        end else begin
            scan_done <= 1'b0;  // 기본: 펄스 없음

            case (state)
                S_IDLE: begin
                    fsm_busy <= 1'b0;
                    if (ctrl_en) begin
                        ch_ptr   <= 2'd0;
                        scan_cnt <= 5'd0;
                        accum[0] <= 20'h0;
                        accum[1] <= 20'h0;
                        accum[2] <= 20'h0;
                        accum[3] <= 20'h0;
                        fsm_busy <= 1'b1;
                        state    <= S_REQ;
                    end
                end

                S_REQ: begin
                    drp_den   <= 1'b1;
                    drp_dwe   <= 1'b0;
                    drp_daddr <= ch_addr(ch_ptr);
                    drp_di    <= 16'h0;
                    state     <= S_WAIT;
                end

                S_WAIT: begin
                    drp_den <= 1'b0;
                    if (drp_drdy)
                        state <= S_ACCUM;
                end

                S_ACCUM: begin
                    // ADC 결과는 DRP DO[15:4]에 12비트로 정렬됨
                    accum[ch_ptr] <= accum[ch_ptr] + {8'd0, drp_do[15:4]};
                    state         <= S_NEXT;
                end

                S_NEXT: begin
                    if (ch_ptr == 2'd3) begin
                        // 4채널 한 패스 완료
                        scan_cnt <= scan_cnt + 5'd1;
                        ch_ptr   <= 2'd0;
                        if (scan_cnt + 5'd1 >= avg_len)
                            state <= S_COMPUTE;
                        else
                            state <= S_REQ;  // accum 초기화 없이 계속 누적
                    end else begin
                        ch_ptr <= ch_ptr + 2'd1;
                        state  <= S_REQ;
                    end
                end

                S_COMPUTE: begin
                    ch_avg_r[0] <= avg12(accum[0], ctrl_avg);
                    ch_avg_r[1] <= avg12(accum[1], ctrl_avg);
                    ch_avg_r[2] <= avg12(accum[2], ctrl_avg);
                    ch_avg_r[3] <= avg12(accum[3], ctrl_avg);
                    ch_valid_r  <= 4'hF;
                    state       <= S_DONE;
                end

                S_DONE: begin
                    scan_done <= 1'b1;  // 1클럭 펄스 → Block 2로 전달
                    state     <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // 인터럽트 출력
    // -----------------------------------------------------------------------
    assign irq = irq_en & irq_stat;

endmodule
`default_nettype wire
