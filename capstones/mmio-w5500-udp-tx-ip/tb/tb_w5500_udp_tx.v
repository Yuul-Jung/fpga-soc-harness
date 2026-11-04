/* tb_w5500_udp_tx.v — W5500 UDP TX IP 자체 점검 테스트벤치
 * Origin: capstones/mmio-w5500-udp-tx-ip/tb/tb_w5500_udp_tx.v
 * Verilog-2001.
 *
 * 시나리오:
 *   1. IP_ID 확인 (0xFFF0 == 0x5735_5544)
 *   2. TX_LEN = 4, TX_DATA 4바이트 적재 (0xDE, 0xAD, 0xBE, 0xEF)
 *   3. TX_PTR 확인 == 4 (go 전에 읽어야 함 — go가 ptr 초기화)
 *   4. CTRL bit1(init) → wait_not_busy → init_done(bit13) 확인
 *   5. CTRL bit0(go)  → wait_not_busy → err(bit11)==0
 *   6. IRQ_STATUS[0]==1 확인
 *   7. IRQ_ENABLE=1 → irq 선 == 1 확인
 *   8. IRQ_STATUS W1C → bit0==0 확인
 *
 * 가짜 W5500 SPI 슬레이브:
 *   - 모든 쓰기 프레임 수용
 *   - Sn_CR(addr=0x0001) SEND(0x20) 감지 → send_received=1
 *   - Sn_IR 폴(addr=0x0002, ctrl=0x08 read) → 0x10(SENDOK) 반환
 *   - 그 외 읽기 → 0x00 반환
 *
 * CLK_DIV = 20 (빠른 시뮬레이션; 실제 IP는 CLK_DIV=500)
 */
`timescale 1ns/1ps

module tb_w5500_udp_tx;

localparam CLK_DIV  = 20;
localparam CLK_HALF = 5;  /* 10 ns 주기 클럭 */

/* --- DUT 신호 --- */
reg         clk, rst_n;
reg  [15:0] mmio_addr;
reg  [31:0] mmio_wdata;
wire [31:0] mmio_rdata;
reg         mmio_we, mmio_cs;
wire        spi_sck, spi_mosi, spi_csn;
wire        irq;

/* --- SPI MISO (슬레이브 → 마스터) --- */
reg  spi_miso;

/* --- DUT 인스턴스 --- */
w5500_udp_tx_ip #(.CLK_DIV(CLK_DIV)) dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .mmio_addr  (mmio_addr),
    .mmio_wdata (mmio_wdata),
    .mmio_rdata (mmio_rdata),
    .mmio_we    (mmio_we),
    .mmio_cs    (mmio_cs),
    .spi_sck    (spi_sck),
    .spi_mosi   (spi_mosi),
    .spi_csn    (spi_csn),
    .spi_miso   (spi_miso),
    .irq        (irq)
);

/* ============================================================
 * 가짜 W5500 SPI 슬레이브
 * 프레임: [addr_hi][addr_lo][ctrl_byte][data...]
 * ctrl_byte[2]=1: 쓰기, ctrl_byte[2]=0: 읽기
 * ============================================================ */
integer    slave_bit;
reg  [7:0] slave_rx;
integer    frame_byte;
reg [15:0] frame_addr;
reg  [7:0] frame_ctrl;
reg        send_received;       /* SEND 커맨드 수신 플래그 */
reg  [7:0] slave_tx_byte;      /* 읽기 응답 바이트 */
integer    slave_tx_bit;
reg        slave_tx_active;
reg        slave_tx_first_negedge; /* ctrl 바이트 마지막 negedge 건너뜀 */

initial begin
    spi_miso               = 1'b1;
    slave_bit              = 7;
    slave_rx               = 8'h00;
    frame_byte             = 0;
    frame_addr             = 16'h0000;
    frame_ctrl             = 8'h00;
    send_received          = 1'b0;
    slave_tx_byte          = 8'h00;
    slave_tx_bit           = 6;
    slave_tx_active        = 1'b0;
    slave_tx_first_negedge = 1'b0;
end

/* CSn 하강: 프레임 초기화 (send_received는 프레임 간 유지) */
always @(negedge spi_csn) begin
    slave_bit              = 7;
    slave_rx               = 8'h00;
    frame_byte             = 0;
    frame_addr             = 16'h0000;
    frame_ctrl             = 8'h00;
    slave_tx_active        = 1'b0;
    slave_tx_first_negedge = 1'b0;
    spi_miso               = 1'b1;
end

/* CSn 상승: 슬레이브 릴리즈 */
always @(posedge spi_csn) begin
    slave_tx_active = 1'b0;
    spi_miso        = 1'b1;
end

/* posedge SCK: MOSI 비트 샘플 */
always @(posedge spi_sck) begin
    if (!spi_csn) begin
        slave_rx[slave_bit] = spi_mosi;
        if (slave_bit == 0) begin
            /* 바이트 완성 처리 */
            case (frame_byte)
                0: begin
                    frame_addr[15:8] = slave_rx;
                end
                1: begin
                    frame_addr[7:0]  = slave_rx;
                end
                2: begin
                    /* ctrl 바이트 */
                    frame_ctrl = slave_rx;
                    if (!slave_rx[2]) begin
                        /* 읽기 모드: 응답 바이트 결정 */
                        if (frame_addr == 16'h0002 && slave_rx == 8'h08)
                            slave_tx_byte = send_received ? 8'h10 : 8'h00;
                        else
                            slave_tx_byte = 8'h00;
                        /* bit7을 지금 출력. 첫 번째 negedge(ctrl 마지막)는 건너뜀 */
                        spi_miso               = slave_tx_byte[7];
                        slave_tx_bit           = 6;
                        slave_tx_first_negedge = 1'b1;
                        slave_tx_active        = 1'b1;
                    end
                end
                default: begin
                    /* 데이터 바이트 (frame_byte >= 3) */
                    if (frame_ctrl[2]) begin
                        /* 쓰기: SEND 커맨드 감지 */
                        if (frame_ctrl == 8'h0C &&
                            frame_addr  == 16'h0001 &&
                            slave_rx    == 8'h20)
                            send_received = 1'b1;
                        frame_addr = frame_addr + 1'b1;
                    end
                    /* 읽기: 마스터가 dummy 송신, 슬레이브는 slave_tx_byte 송신 중 */
                end
            endcase
            frame_byte = frame_byte + 1;
            slave_bit  = 7;
        end else begin
            slave_bit = slave_bit - 1;
        end
    end
end

/* negedge SCK: MISO 비트 출력 (읽기 응답) */
always @(negedge spi_sck) begin
    #1; /* 경쟁 조건 방지 */
    if (!spi_csn && slave_tx_active) begin
        if (slave_tx_first_negedge) begin
            /* ctrl 바이트 마지막 negedge: bit7은 이미 세팅됨, 플래그만 해제 */
            slave_tx_first_negedge = 1'b0;
        end else begin
            spi_miso = slave_tx_byte[slave_tx_bit];
            if (slave_tx_bit == 0)
                slave_tx_active = 1'b0;
            else
                slave_tx_bit = slave_tx_bit - 1;
        end
    end
end

/* ============================================================
 * 클럭 생성
 * ============================================================ */
initial clk = 1'b0;
always #CLK_HALF clk = ~clk;

/* ============================================================
 * MMIO 태스크
 * ============================================================ */
task mmio_write;
    input [15:0] addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        mmio_addr  = addr;
        mmio_wdata = data;
        mmio_we    = 1'b1;
        mmio_cs    = 1'b1;
        @(posedge clk); #1;
        mmio_we    = 1'b0;
        mmio_cs    = 1'b0;
    end
endtask

task mmio_read;
    input  [15:0] addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        mmio_addr  = addr;
        mmio_we    = 1'b0;
        mmio_cs    = 1'b1;
        @(posedge clk); #1;
        data       = mmio_rdata;
        mmio_cs    = 1'b0;
    end
endtask

/* BUSY 폴링 태스크 */
task wait_not_busy;
    reg [31:0] ctrl_val;
    integer    timeout;
    begin
        timeout  = 0;
        ctrl_val = 32'h0000_0400; /* BUSY 비트 세팅 상태로 초기화 */
        while (ctrl_val[10] == 1'b1 && timeout < 200000) begin
            mmio_read(16'h0000, ctrl_val);
            timeout = timeout + 1;
        end
        if (timeout >= 200000)
            $display("FAIL: BUSY 타임아웃");
    end
endtask

/* ============================================================
 * 메인 테스트
 * ============================================================ */
integer fail_count;
reg [31:0] rd_val;

initial begin
    fail_count = 0;
    rst_n      = 1'b0;
    mmio_addr  = 16'h0000;
    mmio_wdata = 32'd0;
    mmio_we    = 1'b0;
    mmio_cs    = 1'b0;

    repeat(4) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);

    /* --- 1. IP_ID 확인 --- */
    mmio_read(16'hFFF0, rd_val);
    if (rd_val !== 32'h5735_5544) begin
        $display("FAIL: IP_ID 기대값 0x57355544, 실제값 0x%08H", rd_val);
        fail_count = fail_count + 1;
    end

    /* --- 2. TX_LEN = 4 --- */
    mmio_write(16'h0004, 32'h0000_0004);

    /* --- 3. TX_DATA 4바이트 적재 --- */
    mmio_write(16'h0008, 32'h0000_00DE);
    mmio_write(16'h0008, 32'h0000_00AD);
    mmio_write(16'h0008, 32'h0000_00BE);
    mmio_write(16'h0008, 32'h0000_00EF);

    /* --- 4. TX_PTR 확인 (go 전에 읽어야 함 — go가 ptr 초기화) --- */
    mmio_read(16'h000C, rd_val);
    if (rd_val[5:0] !== 6'd4) begin
        $display("FAIL: TX_PTR 기대값 4, 실제값 %0d", rd_val[5:0]);
        fail_count = fail_count + 1;
    end

    /* --- 5. 초기화 (bit1=init) --- */
    mmio_write(16'h0000, 32'h0000_0002);
    wait_not_busy;

    /* --- 6. init_done 확인 (bit13) --- */
    mmio_read(16'h0000, rd_val);
    if (rd_val[13] !== 1'b1) begin
        $display("FAIL: init_done 비트 미세팅 (CTRL=0x%08H)", rd_val);
        fail_count = fail_count + 1;
    end

    /* --- 7. UDP TX 시작 (bit0=go) --- */
    mmio_write(16'h0000, 32'h0000_0001);
    wait_not_busy;

    /* --- 8. err 확인 (bit11 == 0) --- */
    mmio_read(16'h0000, rd_val);
    if (rd_val[11] !== 1'b0) begin
        $display("FAIL: err 비트 세팅됨 (CTRL=0x%08H)", rd_val);
        fail_count = fail_count + 1;
    end

    /* --- 9. IRQ_STATUS 확인 (bit0 == 1) --- */
    mmio_read(16'hFFF8, rd_val);
    if (rd_val[0] !== 1'b1) begin
        $display("FAIL: IRQ_STATUS done 비트 미세팅");
        fail_count = fail_count + 1;
    end

    /* --- 10. IRQ_ENABLE=1 → irq 선 확인 --- */
    mmio_write(16'hFFFC, 32'h0000_0001);
    @(posedge clk); #1;
    if (irq !== 1'b1) begin
        $display("FAIL: irq 선 Low (IRQ_ENABLE=1 후)");
        fail_count = fail_count + 1;
    end

    /* --- 11. IRQ_STATUS W1C → bit0==0 확인 --- */
    mmio_write(16'hFFF8, 32'h0000_0001);
    mmio_read(16'hFFF8, rd_val);
    if (rd_val[0] !== 1'b0) begin
        $display("FAIL: IRQ_STATUS W1C 실패 (bit0 여전히 1)");
        fail_count = fail_count + 1;
    end

    /* --- 최종 판정 --- */
    if (fail_count == 0)
        $display("PASS: W5500 UDP TX IP 검증 완료 (SENDOK 수신, IRQ 동작)");
    else
        $display("FAIL: %0d 항목 실패", fail_count);

    $finish;
end

/* 최대 실행 시간 보호 (CLK_DIV * 2000 프레임 여유) */
initial begin
    #(CLK_DIV * 2000 * 10 * 2);
    $display("FAIL: 시뮬레이션 타임아웃");
    $finish;
end

endmodule
