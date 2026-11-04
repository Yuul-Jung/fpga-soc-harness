/* tb_i2c_master.v — I2C Master IP 자체 점검 테스트벤치
 * Origin: capstones/mmio-i2c-master-ip/tb/tb_i2c_master.v
 * Verilog-2001.
 *
 * 시나리오:
 *   1. CTRL = {addr=0x68, rnw=0, go=1, stop=1}, DATA = 0x75
 *      → I2C: START + 0xD0(addr+W) + ACK + 0x75(reg) + ACK + STOP
 *   2. CTRL = {addr=0x68, rnw=1, go=1, stop=1}
 *      → I2C: START + 0xD1(addr+R) + ACK + 0x68(data) + NAK + STOP
 *   3. DATA[7:0] 읽기 → 0x68 여야 PASS
 *
 * 가짜 MPU-6050 슬레이브: 주소 0x68, registers[0x75] = 0x68
 * CLK_DIV = 20 (빠른 시뮬레이션; 위상: q1=5, h=10, q3=15, end=19)
 */
`timescale 1ns/1ps

module tb_i2c_master;

localparam CLK_DIV  = 20;
localparam CLK_HALF = 5;  /* 10 ns 주기 클럭 */

/* --- DUT 신호 --- */
reg         clk, rst_n;
reg  [15:0] mmio_addr;
reg  [31:0] mmio_wdata;
wire [31:0] mmio_rdata;
reg         mmio_we, mmio_cs;
wire        scl_o, sda_o;
wire        irq;

/* --- I2C 버스 (오픈드레인 와이어-AND) --- */
reg  sda_slave;        /* 슬레이브 SDA 구동: 0=로우, 1=릴리즈 */
wire SDA = sda_o & sda_slave;  /* 와이어드-AND */
wire SCL = scl_o;

/* --- DUT 인스턴스 --- */
i2c_master_ip #(.CLK_DIV(CLK_DIV)) dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .mmio_addr  (mmio_addr),
    .mmio_wdata (mmio_wdata),
    .mmio_rdata (mmio_rdata),
    .mmio_we    (mmio_we),
    .mmio_cs    (mmio_cs),
    .scl_o      (scl_o),
    .sda_o      (sda_o),
    .sda_i      (SDA),
    .irq        (irq)
);

/* ============================================================
 * 가짜 I2C 슬레이브 — MPU-6050 (주소 0x68)
 * ============================================================ */
localparam SLAVE_ADDR = 7'h68;
integer slave_state;
integer slave_bit;
reg [7:0] slave_rx;
reg [7:0] slave_tx;
integer slave_tx_bit;
integer slave_reg_ptr;
reg [7:0] slave_regs [0:255];

localparam SS_IDLE           = 0,
           SS_RX_ADDR        = 1,
           SS_ACK_ADDR       = 2,
           SS_RX_DATA        = 3,
           SS_ACK_DATA       = 4,
           SS_TX_DATA        = 5,
           SS_RX_NAK         = 6,
           SS_ACK_ADDR_DONE  = 7; /* posedge(ACK) 를 지나고 나서 상태 전환 */

integer k;
initial begin
    for (k = 0; k < 256; k = k + 1) slave_regs[k] = 8'h00;
    slave_regs[8'h75] = 8'h68;  /* WHO_AM_I */
    sda_slave    = 1'b1;
    slave_state  = SS_IDLE;
    slave_bit    = 7;
    slave_rx     = 8'h00;
    slave_tx     = 8'h00;
    slave_tx_bit = 7;
    slave_reg_ptr = 0;
end

/* START 감지: SDA 하강 중 SCL=1 */
always @(negedge SDA) begin
    if (SCL) begin
        slave_state = SS_RX_ADDR;
        slave_bit   = 7;
        slave_rx    = 8'h00;
        sda_slave   = 1'b1;
    end
end

/* STOP 감지: SDA 상승 중 SCL=1 */
always @(posedge SDA) begin
    if (SCL) begin
        slave_state = SS_IDLE;
        sda_slave   = 1'b1;
    end
end

/* 비트 샘플: posedge SCL */
always @(posedge SCL) begin
    case (slave_state)
        SS_RX_ADDR: begin
            slave_rx[slave_bit] = SDA;
            if (slave_bit == 0) begin
                slave_state = SS_ACK_ADDR;
                slave_bit   = 7;
            end else
                slave_bit = slave_bit - 1;
        end
        SS_RX_DATA: begin
            slave_rx[slave_bit] = SDA;
            if (slave_bit == 0) begin
                slave_state = SS_ACK_DATA;
                slave_bit   = 7;
            end else
                slave_bit = slave_bit - 1;
        end
        SS_RX_NAK: begin
            /* 마스터 NAK 수신 → IDLE (SDA 릴리즈는 negedge default에서 처리) */
            slave_state = SS_IDLE;
        end
        default: ;
    endcase
end

/* SDA 구동: negedge SCL */
always @(negedge SCL) begin
    #1; /* 경쟁 조건 방지 */
    case (slave_state)
        SS_ACK_ADDR: begin
            if (slave_rx[7:1] == SLAVE_ADDR) begin
                sda_slave   = 1'b0;             /* ACK */
                slave_state = SS_ACK_ADDR_DONE; /* ACK posedge 를 지나고 나서 전환 */
            end else begin
                sda_slave   = 1'b1; /* NAK */
                slave_state = SS_IDLE;
            end
        end
        SS_ACK_ADDR_DONE: begin
            /* ACK posedge 이후 negedge: 이제 데이터 단계로 전환 */
            if (slave_rx[0] == 1'b0) begin
                /* 쓰기 모드: SDA 릴리즈 후 SS_RX_DATA */
                sda_slave   = 1'b1;
                slave_state = SS_RX_DATA;
            end else begin
                /* 읽기 모드: 첫 비트(bit7)를 지금 구동해 마스터가 p_h에서 샘플 */
                slave_tx     = slave_regs[slave_reg_ptr];
                sda_slave    = slave_regs[slave_reg_ptr][7]; /* bit 7 */
                slave_tx_bit = 6;            /* 이후 bit 6..0은 SS_TX_DATA 에서 */
                slave_state  = SS_TX_DATA;
            end
        end
        SS_ACK_DATA: begin
            slave_reg_ptr = slave_rx; /* 레지스터 포인터 저장 */
            sda_slave     = 1'b0;    /* ACK */
            slave_state   = SS_IDLE; /* STOP 또는 반복 START 대기 */
        end
        SS_TX_DATA: begin
            sda_slave = slave_tx[slave_tx_bit]; /* 데이터 비트 송신 */
            if (slave_tx_bit == 0)
                slave_state = SS_RX_NAK;        /* 마지막 비트 후 NAK 대기 */
            else
                slave_tx_bit = slave_tx_bit - 1;
        end
        default: sda_slave = 1'b1; /* ACK 해제 / 릴리즈 */
    endcase
end

/* ============================================================
 * 클럭 생성
 * ============================================================ */
initial clk = 1'b0;
always #CLK_HALF clk = ~clk;

/* ============================================================
 * MMIO 쓰기 태스크
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

/* MMIO 읽기 태스크 */
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
    integer timeout;
    begin
        timeout = 0;
        ctrl_val = 32'h0000_0400; /* BUSY 비트 세팅 상태 */
        while (ctrl_val[10] == 1'b1 && timeout < 50000) begin
            mmio_read(16'h0000, ctrl_val);
            timeout = timeout + 1;
        end
        if (timeout >= 50000)
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

    /* --- IP_ID 확인 --- */
    mmio_read(16'hFFF0, rd_val);
    if (rd_val !== 32'h4932_434D) begin
        $display("FAIL: IP_ID 기대값 0x4932434D, 실제값 0x%08H", rd_val);
        fail_count = fail_count + 1;
    end

    /* ---- 트랜잭션 1: 레지스터 주소 쓰기 (0x75) ---- */
    /* DATA = 0x75 */
    mmio_write(16'h0004, 32'h0000_0075);
    /* CTRL = {stop=1, go=1, rnw=0, addr=0x68} = 0x0000_0368 */
    mmio_write(16'h0000, 32'h0000_0368);

    wait_not_busy;

    /* NAK 확인 (트랜잭션 1은 ACK 기대) */
    mmio_read(16'h0000, rd_val);
    if (rd_val[11] !== 1'b0) begin
        $display("FAIL: 트랜잭션1 NAK 비트 세팅됨 (ACK 기대)");
        fail_count = fail_count + 1;
    end

    /* ---- 트랜잭션 2: WHO_AM_I 읽기 ---- */
    /* CTRL = {stop=1, go=1, rnw=1, addr=0x68} = 0x0000_03E8 */
    mmio_write(16'h0000, 32'h0000_03E8);

    wait_not_busy;

    /* DATA[7:0] = 0x68 여야 PASS */
    mmio_read(16'h0004, rd_val);
    if (rd_val[7:0] !== 8'h68) begin
        $display("FAIL: WHO_AM_I 기대값 0x68, 실제값 0x%02H", rd_val[7:0]);
        fail_count = fail_count + 1;
    end

    /* IRQ 확인 (IRQ_ENABLE = 1 설정 후 IRQ_STATUS 확인) */
    mmio_write(16'hFFFC, 32'h0000_0001);    /* done_en = 1 */
    /* IRQ_STATUS는 직전 트랜잭션에서 세팅됨 */
    mmio_read(16'hFFF8, rd_val);
    if (rd_val[0] !== 1'b1) begin
        $display("FAIL: IRQ_STATUS done 비트 미세팅");
        fail_count = fail_count + 1;
    end

    /* --- 최종 판정 --- */
    if (fail_count == 0)
        $display("PASS: I2C Master IP 검증 완료 (WHO_AM_I=0x68 확인)");
    else
        $display("FAIL: %0d 항목 실패", fail_count);

    $finish;
end

/* 최대 실행 시간 보호 */
initial begin
    #(CLK_DIV * 300 * 10 * 2); /* 넉넉한 타임아웃 */
    $display("FAIL: 시뮬레이션 타임아웃");
    $finish;
end

endmodule
