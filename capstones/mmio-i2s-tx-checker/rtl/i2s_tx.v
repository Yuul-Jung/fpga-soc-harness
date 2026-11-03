// i2s_tx.v — I2S 송신기 + MMIO 레지스터 (ip_standard rev 1 준수)
// Left-Justified 포맷: LRCLK 변환 직후 첫 번째 BCLK 하강 에지에서 MSB 출력
// MMIO 오프셋 맵 (64KB 창, 0x1002_0000 기준):
//   0x0000 CTRL      RW  bit[0]=TX_EN
//   0x0004 STATUS    RO  bit[0]=active(=TX_EN)
//   0x0008 L_DATA    WO  [15:0] 왼쪽 채널 샘플 (다음 LRCLK 하강부터 반영)
//   0x000C R_DATA    WO  [15:0] 오른쪽 채널 샘플
//   0xFFF0 ID        RO  0x49325354 ('I2ST')
//   0xFFF4 VER       RO  0x01000001
//   0xFFF8 IRQ_STATUS W1C bit[0]=frame_done
//   0xFFFC IRQ_ENABLE RW  bit[0]=frame_done 인터럽트 활성화
`timescale 1ns/1ps
module i2s_tx (
    input  wire        clk,
    input  wire        rst,
    // mmio-lite 슬레이브 포트
    input  wire        sel,
    input  wire        we,
    input  wire [15:0] off,     // 창 내 바이트 오프셋 (addr[15:0])
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // I2S 클럭 (i2s_clk_gen에서 공급, sys_clk 동기)
    input  wire        mclk,
    input  wire        bclk,
    input  wire        lrclk,
    // I2S 출력
    output wire        sdin,   // 직렬 데이터 (Pmod I2S2 SDIN 핀)
    // 인터럽트
    output wire        irq
);
    // -------------------------------------------------------
    // MMIO 레지스터
    // -------------------------------------------------------
    reg        tx_en;
    reg [15:0] l_reg, r_reg;      // 호스트가 쓴 샘플 버퍼
    reg        irq_status;        // frame_done 래치
    reg        irq_enable;

    // 쓰기
    always @(posedge clk) begin
        if (rst) begin
            tx_en      <= 1'b0;
            l_reg      <= 16'h0000;
            r_reg      <= 16'h0000;
            irq_enable <= 1'b0;
        end else if (sel && we) begin
            case (off)
                16'h0000: tx_en      <= wdata[0];
                16'h0008: l_reg      <= wdata[15:0];
                16'h000C: r_reg      <= wdata[15:0];
                16'hFFFC: irq_enable <= wdata[0];
                default: ;
            endcase
        end
    end

    // IRQ_STATUS: W1C
    always @(posedge clk) begin
        if (rst) begin
            irq_status <= 1'b0;
        end else begin
            if (frame_done_pulse)                 irq_status <= 1'b1;
            if (sel && we && off == 16'hFFF8)     irq_status <= irq_status & ~wdata[0];
        end
    end

    // 읽기 (조합)
    always @* begin
        case (off)
            16'h0000: rdata = {31'd0, tx_en};
            16'h0004: rdata = {31'd0, tx_en};
            16'hFFF0: rdata = 32'h4932_5354; // 'I2ST'
            16'hFFF4: rdata = 32'h0100_0001; // std_rev=1, minor=1
            16'hFFF8: rdata = {31'd0, irq_status};
            16'hFFFC: rdata = {31'd0, irq_enable};
            default:  rdata = 32'h0000_0000;
        endcase
    end

    assign irq = irq_status & irq_enable;

    // -------------------------------------------------------
    // 에지 검출 (1사이클 지연, sys_clk 동기)
    // -------------------------------------------------------
    reg bclk_d, lrclk_d;
    wire bclk_fall   = !bclk   && bclk_d;
    wire lrclk_fall  = !lrclk  && lrclk_d;
    wire lrclk_rise  =  lrclk  && !lrclk_d;

    always @(posedge clk) begin
        if (rst) begin
            bclk_d  <= 1'b0;
            lrclk_d <= 1'b0;
        end else begin
            bclk_d  <= bclk;
            lrclk_d <= lrclk;
        end
    end

    // -------------------------------------------------------
    // I2S 직렬화 (Left-Justified 포맷)
    // - LRCLK 하강: L 채널 샘플 로드, 비트 카운터 초기화
    // - LRCLK 상승: R 채널 샘플 로드, 비트 카운터 초기화
    // - BCLK 하강: 현재 채널의 다음 비트를 SDIN에 출력 (MSB 우선)
    // -------------------------------------------------------
    reg [15:0] l_shift, r_shift;  // 현재 프레임 직렬화 버퍼
    reg [4:0]  bit_cnt;           // 0..15: 유효 비트, 16+: 패딩 0
    reg        sdin_r;
    reg        frame_done_r;

    wire frame_done_pulse = frame_done_r;

    always @(posedge clk) begin
        if (rst) begin
            l_shift      <= 16'h0000;
            r_shift      <= 16'h0000;
            bit_cnt      <= 5'd0;
            sdin_r       <= 1'b0;
            frame_done_r <= 1'b0;
        end else begin
            frame_done_r <= 1'b0; // 1사이클 펄스

            if (lrclk_fall) begin
                // L 채널 시작: l_reg 래치, 카운터 초기화
                l_shift <= l_reg;
                bit_cnt <= 5'd0;
                sdin_r  <= 1'b0;
            end else if (lrclk_rise) begin
                // R 채널 시작: r_reg 래치, 카운터 초기화, frame_done 펄스
                r_shift      <= r_reg;
                bit_cnt      <= 5'd0;
                sdin_r       <= 1'b0;
                frame_done_r <= 1'b1; // 한 프레임 완료 (L+R 한 쌍)
            end else if (bclk_fall && tx_en) begin
                if (bit_cnt <= 5'd15) begin
                    // MSB 우선 출력 후 왼쪽 시프트
                    if (!lrclk) begin
                        sdin_r  <= l_shift[15];
                        l_shift <= {l_shift[14:0], 1'b0};
                    end else begin
                        sdin_r  <= r_shift[15];
                        r_shift <= {r_shift[14:0], 1'b0};
                    end
                    bit_cnt <= bit_cnt + 5'd1;
                end else begin
                    sdin_r <= 1'b0; // 비트 16 이후: 패딩 0
                end
            end else if (!tx_en) begin
                sdin_r <= 1'b0;
            end
        end
    end

    assign sdin = sdin_r;

    // mclk는 basys3_top에서 Pmod JA4로 직접 연결한다 (여기서는 무시)
    // verilator lint_off UNUSED
    wire _unused_mclk = mclk;
    // verilator lint_on UNUSED

endmodule
