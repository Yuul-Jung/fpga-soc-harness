// tb_ps2_mouse_cursor.v
// ps2_mouse_host 자체 점검 테스트벤치
// PASS / FAIL 접두어 줄 출력 (!==/X/Z 감지)
// Verilog-2001. iverilog 호환.
// 원작자: 하네스 자체 작성 (2026-11-04)

`timescale 1ns / 1ps
`default_nettype none

module tb_ps2_mouse_cursor;

// ─── 파라미터 ────────────────────────────────────────────
parameter INHIBIT = 200;     // 인히빗 2μs: ps2_send(0x00) 복귀(~700ns) 보다 충분히 김 (200×10ns=2000ns)
parameter CLK_HALF = 5;      // 100 MHz 클럭 반주기 (5ns)
parameter PS2_HALF = 100;    // PS/2 CLK 반주기 (100ns = 10MHz, 시뮬용)

// ─── DUT 신호 ─────────────────────────────────────────────
reg  clk, rst;
reg  [15:0] offset;
reg  [31:0] wdata;
reg  sel, we;
wire [31:0] rdata;
wire [9:0]  cursor_x, cursor_y;
wire [2:0]  mouse_btn;
wire        irq_out;
wire        ps2_clk_oe, ps2_data_oe;

// ─── 오픈드레인 시뮬레이션 ───────────────────────────────
// TB와 DUT가 각각 선을 로우로 당길 수 있음
// tb_ps2_clk/data: TB 쪽 오픈드레인 드라이버 (0 → 로우, 1 → Hi-Z)
reg tb_ps2_clk_drive;   // 1=TB가 CLK을 로우로
reg tb_ps2_data_drive;  // 1=TB가 DATA를 로우로

// 선 전압: 어느 한쪽이 로우(oe=1)이면 로우
wire ps2_clk_line  = !(tb_ps2_clk_drive  || ps2_clk_oe);
wire ps2_data_line = !(tb_ps2_data_drive || ps2_data_oe);

// ─── DUT 인스턴스 ─────────────────────────────────────────
ps2_mouse_host #(.INHIBIT_CNT(INHIBIT)) dut (
    .clk         (clk),
    .rst         (rst),
    .sel         (sel),
    .we          (we),
    .offset      (offset),
    .wdata       (wdata),
    .rdata       (rdata),
    .cursor_x    (cursor_x),
    .cursor_y    (cursor_y),
    .mouse_btn   (mouse_btn),
    .irq_out     (irq_out),
    .ps2_clk_in  (ps2_clk_line),
    .ps2_data_in (ps2_data_line),
    .ps2_clk_oe  (ps2_clk_oe),
    .ps2_data_oe (ps2_data_oe)
);

// ─── 클럭 ────────────────────────────────────────────────
initial clk = 0;
always #CLK_HALF clk = ~clk;

// ─── MMIO 쓰기 태스크 ────────────────────────────────────
task mmio_write;
    input [15:0] addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        sel    = 1'b1;
        we     = 1'b1;
        offset = addr;
        wdata  = data;
        @(posedge clk); #1;
        sel = 1'b0; we = 1'b0;
    end
endtask

// ─── MMIO 읽기 함수 대용 태스크 ──────────────────────────
task mmio_read;
    input  [15:0] addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        sel    = 1'b1;
        we     = 1'b0;
        offset = addr;
        @(posedge clk); #1;
        data = rdata;
        sel = 1'b0;
    end
endtask

// ─── PS/2 바이트 송신 태스크 (TB → DUT) ──────────────────
// PS/2 프로토콜: start=0, D0..D7, parity(홀수), stop=1
// TB가 CLK을 생성 (장치 역할)
task ps2_send;
    input [7:0] data;
    reg parity;
    integer i;
    reg [10:0] frame;
    begin
        parity = ^data; // 짝수 XOR → 홀수 패리티 비트 = ~^data
        // parity bit = 1이면 data의 1의 개수가 짝수 → 1을 더해 홀수
        parity = ~(^data);
        frame = {1'b1, parity, data, 1'b0}; // [10]=stop [9]=par [8:1]=D7..D0 [0]=start

        // 스타트 비트 (DATA=0)
        tb_ps2_data_drive = 1'b1; // DATA 로우
        #PS2_HALF;
        tb_ps2_clk_drive = 1'b1;  // CLK 로우
        #PS2_HALF;
        tb_ps2_clk_drive = 1'b0;  // CLK 하이 (상승 에지 — DUT가 여기서 읽음)
        #PS2_HALF;

        // D0 ~ D7, parity, stop (10 비트)
        for (i = 1; i <= 10; i = i + 1) begin
            tb_ps2_data_drive = ~frame[i]; // frame[i]=1 → DATA=Hi-Z=1; frame[i]=0 → DATA=로우
            #PS2_HALF;
            tb_ps2_clk_drive = 1'b1;  // CLK 로우 (하강 에지 — DUT가 여기서 샘플)
            #PS2_HALF;
            tb_ps2_clk_drive = 1'b0;  // CLK 하이
            #PS2_HALF;
        end

        // 종료 간격
        tb_ps2_data_drive = 1'b0; // DATA 릴리즈
        #(PS2_HALF * 4);
    end
endtask

// ─── DUT가 보낸 바이트 수신 태스크 (DUT → TB) ────────────
// DUT가 CLK 인히빗 → DATA 로우 (스타트) → CLK 릴리즈 → TB가 CLK 생성
task ps2_recv_host_tx;
    output [7:0] data;
    integer i;
    reg bit_val;
    reg [7:0] recv_byte;
    integer timeout;
    begin
        recv_byte = 8'h00;

        // DUT가 CLK 인히빗(ps2_clk_oe=1) 대기
        timeout = 0;
        while (!ps2_clk_oe && timeout < 100000) begin
            @(posedge clk); timeout = timeout + 1;
        end
        if (timeout >= 100000) begin
            $display("FAIL tb_recv: timeout waiting for CLK inhibit");
            $finish;
        end

        // 인히빗 완료 대기 (DUT가 DATA 로우 → CLK 릴리즈)
        @(negedge ps2_clk_oe); // CLK 개방 시까지 대기
        #(PS2_HALF * 2);

        // 스타트 비트는 이미 세팅됨 (DATA=0). CLK 1사이클 생성
        tb_ps2_clk_drive = 1'b1; #PS2_HALF;
        tb_ps2_clk_drive = 1'b0; #PS2_HALF;

        // D0 ~ D7, parity, stop = 10 CLK 사이클
        for (i = 0; i < 10; i = i + 1) begin
            #(PS2_HALF/2);
            if (i < 8) recv_byte[i] = ps2_data_line; // 데이터 샘플
            tb_ps2_clk_drive = 1'b1; #PS2_HALF;
            tb_ps2_clk_drive = 1'b0; #PS2_HALF;
        end

        // 0xFA ACK 전송
        // 주의: 하드웨어 ACK 펄스(DATA 로우 1 CLK)는 생략한다.
        // ACK 펄스를 보내면 DUT 수신기의 bit_cnt가 0→1로 증가한 채로
        // ps2_send(0xFA)가 시작되어 11비트 프레임이 오정렬된다.
        // DUT S_WAIT_ACK는 rx_byte==0xFA 전체 프레임만 확인하므로 문제없다.
        #(PS2_HALF * 4);
        ps2_send(8'hFA);

        data = recv_byte;
    end
endtask

// ─── 메인 테스트 시퀀스 ──────────────────────────────────
integer fail_cnt;
reg [31:0] rd;
reg [7:0]  rx_byte_host;

initial begin
    // 초기화
    fail_cnt = 0;
    clk = 0; rst = 1;
    sel = 0; we = 0; offset = 0; wdata = 0;
    tb_ps2_clk_drive = 0; tb_ps2_data_drive = 0;
    repeat(5) @(posedge clk);
    rst = 0;
    repeat(3) @(posedge clk);

    // ── T1: IP ID 확인 ───────────────────────────────────
    mmio_read(16'hFFF0, rd);
    if (rd !== 32'h5053_324D) begin
        $display("FAIL T1: ID expected 0x5053324D got 0x%08X", rd); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T1: IP ID = 0x%08X", rd);
    end

    // ── T2: BAT 시퀀스 ───────────────────────────────────
    ps2_send(8'hAA);  // BAT 완료
    ps2_send(8'h00);  // 장치 ID
    // DUT가 TX 준비 → TB가 수신
    ps2_recv_host_tx(rx_byte_host);
    if (rx_byte_host !== 8'hF4) begin
        $display("FAIL T2: host TX expected 0xF4 got 0x%02X", rx_byte_host);
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T2: host TX = 0xF4");
    end

    // ACK(0xFA)는 ps2_recv_host_tx 내부에서 전송됨

    // init_done 대기
    begin : wait_init
        integer t;
        t = 0;
        repeat(200) @(posedge clk);
        mmio_read(16'h0010, rd);
        if (rd[0] !== 1'b1) begin
            $display("FAIL T2b: STATUS init_done=0"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS T2b: init_done=1");
        end
    end

    // ── T3: CTRL 쓰기 (enable + cursor_en) ───────────────
    mmio_write(16'h0000, 32'h0000_0003);
    mmio_read(16'h0000, rd);
    if (rd[1:0] !== 2'b11) begin
        $display("FAIL T3: CTRL expected 3 got %0d", rd[1:0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T3: CTRL = 0x%08X", rd);
    end

    // ── T4: 이동 패킷 (dx=+20, dy=0, L_BTN) ─────────────
    // pkt0=0x09: bit3=always1, bit0=L_BTN, X_OVF=0, Y_OVF=0
    // pkt1=0x14: dx=20
    // pkt2=0x00: dy=0
    ps2_send(8'h09);
    ps2_send(8'h14);
    ps2_send(8'h00);

    // cursor_x 갱신 대기 (pkt_ready_d 2클럭 후)
    repeat(50) @(posedge clk);

    mmio_read(16'h0004, rd);
    if (rd[9:0] !== 10'd340) begin
        $display("FAIL T4: MOUSE_X expected 340 got %0d", rd[9:0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T4: MOUSE_X=%0d (320+20=340)", rd[9:0]);
    end

    mmio_read(16'h0008, rd);
    if (rd[9:0] !== 10'd240) begin
        $display("FAIL T4b: MOUSE_Y expected 240 got %0d", rd[9:0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T4b: MOUSE_Y=%0d (unchanged)", rd[9:0]);
    end

    mmio_read(16'h000C, rd);
    if (rd[0] !== 1'b1) begin
        $display("FAIL T4c: L_BTN expected 1 got %0d", rd[0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T4c: L_BTN=1");
    end

    // ── T5: 위로 이동 패킷 (dy=+10 → cursor_y 감소) ──────
    // pkt0=0x08: bit3=always1, Y_SGN=0, X_SGN=0, 버튼 없음
    // pkt1=0x00: dx=0
    // pkt2=0x0A: dy=+10 (양수 = 위로 = cursor_y 감소)
    ps2_send(8'h08);
    ps2_send(8'h00);
    ps2_send(8'h0A);

    repeat(50) @(posedge clk);

    mmio_read(16'h0008, rd);
    if (rd[9:0] !== 10'd230) begin
        $display("FAIL T5: MOUSE_Y expected 230 got %0d", rd[9:0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T5: MOUSE_Y=%0d (240-10=230)", rd[9:0]);
    end

    // ── T6: IRQ 확인 ─────────────────────────────────────
    mmio_read(16'hFFF8, rd);
    if (rd[0] !== 1'b1) begin
        $display("FAIL T6: IRQ_STATUS expected 1 got %0d", rd[0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T6: IRQ_STATUS[0]=1 (packet IRQ)");
    end

    // W1C 클리어
    mmio_write(16'hFFF8, 32'h0000_0001);
    mmio_read(16'hFFF8, rd);
    if (rd[0] !== 1'b0) begin
        $display("FAIL T6b: IRQ_STATUS W1C failed, got %0d", rd[0]); fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T6b: IRQ_STATUS W1C cleared");
    end

    // ── 최종 결과 ────────────────────────────────────────
    if (fail_cnt === 0)
        $display("PASS all tests (%0d failures)", fail_cnt);
    else
        $display("FAIL %0d test(s) failed", fail_cnt);

    #(PS2_HALF * 10);
    $finish;
end

// 타임아웃 보호
initial begin
    #20000000; // 20ms
    $display("FAIL timeout: simulation exceeded 20ms");
    $finish;
end

endmodule
`default_nettype wire
