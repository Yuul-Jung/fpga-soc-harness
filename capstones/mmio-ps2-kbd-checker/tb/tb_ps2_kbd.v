// tb_ps2_kbd.v — PS/2 키보드 수신기 자체 점검 테스트벤치 (Verilog-2001)
// 하네스 직접 작성 원본.
//
// 테스트 항목:
//   T1  make  'H' (스캔코드 0x33, ASCII 0x68)
//   T2  break 'H' (F0+0x33, key_up=1)
//   T3  make  'I' (스캔코드 0x43, ASCII 0x69)
//   T4  패리티 오류 프레임 → rx_err=1, kbd_ready는 올라오지 않아야 함
//   T5  MMIO 읽기: STATUS/DATA 레지스터 값 확인
//
// PS/2 Set 2: 하강 에지에서 데이터를 샘플링한다 (11-bit 프레임).
// 클럭: 100MHz 시스템 / PS/2 CLK 주기 = 40us (25kHz)
`timescale 1ns/1ps

module tb_ps2_kbd;
    // ----------------------------------------------------------------
    // 파라미터
    // ----------------------------------------------------------------
    localparam CLK_PERIOD  = 10;        // 100MHz = 10ns
    localparam PS2_HALF    = 20_000;    // PS/2 CLK 반주기 20us (50ns × 400 = 20us)
    // PS2_HALF를 짧게 해 시뮬 속도 확보: 실제 20us 대신 2us (200클럭)
    // 200클럭 반주기 → 하강 에지에서 수신, 3-사이클 동기화 후 샘플

    // ----------------------------------------------------------------
    // DUT 신호
    // ----------------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         ps2_clk_in;
    reg         ps2_data_in;
    wire [15:0] led;
    wire        txd;

    // MMIO 직접 접근용
    wire        sel_kbd;
    wire [31:0] rdata_kbd;
    reg         tb_sel;
    reg         tb_we;
    reg  [7:0]  tb_off;
    reg  [31:0] tb_wdata;

    // ----------------------------------------------------------------
    // DUT 인스턴스 (테스트 편의를 위해 soc_top 대신 하위 모듈 직접)
    // ----------------------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_err;

    ps2_rx u_rx (
        .clk         (clk),
        .rst         (rst),
        .ps2_clk_in  (ps2_clk_in),
        .ps2_data_in (ps2_data_in),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .rx_err      (rx_err)
    );

    wire kbd_irq;
    wire [31:0] rdata_out;

    ps2_kbd u_kbd (
        .clk      (clk),
        .rst      (rst),
        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .rx_err   (rx_err),
        .sel      (tb_sel),
        .we       (tb_we),
        .off      (tb_off),
        .wdata    (tb_wdata),
        .rdata    (rdata_out),
        .irq      (kbd_irq)
    );

    // ----------------------------------------------------------------
    // 클럭 생성
    // ----------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ----------------------------------------------------------------
    // 카운터와 결과
    // ----------------------------------------------------------------
    integer fail_cnt;
    integer test_num;

    // ----------------------------------------------------------------
    // PS/2 프레임 송신 태스크 (DUT에서는 수신)
    //   PS/2 장치가 호스트로 보내는 방향: CLK은 장치가 생성
    //   Start=0, D0..D7 (LSB first), Parity(odd), Stop=1
    //   하강 에지에서 호스트가 샘플링한다
    // ----------------------------------------------------------------
    task send_ps2_byte;
        input [7:0] data;
        input       bad_parity; // 1이면 패리티를 반전해 오류 유도
        integer i;
        reg parity;
        reg [10:0] frame;
        begin
            // 홀수 패리티: 1의 개수가 홀수
            parity = ^data; // data 비트의 XOR → 짝수면 1, 홀수면 0
            if (!parity) parity = 1'b1; else parity = 1'b0;
            // 오류 유도 시 반전
            if (bad_parity) parity = ~parity;
            // 프레임: [0]=start, [1..8]=data LSB→MSB, [9]=parity, [10]=stop
            frame = {1'b1, parity, data, 1'b0};

            // 라인 초기 상태: CLK=1, DATA=1
            ps2_clk_in  = 1'b1;
            ps2_data_in = 1'b1;
            #(PS2_HALF * CLK_PERIOD);

            for (i = 0; i <= 10; i = i + 1) begin
                // DATA 세팅 (CLK 하이 중)
                ps2_data_in = frame[i];
                #(PS2_HALF * CLK_PERIOD / 2);
                // CLK 하강 에지
                ps2_clk_in = 1'b0;
                #(PS2_HALF * CLK_PERIOD);
                // CLK 상승 에지
                ps2_clk_in = 1'b1;
                #(PS2_HALF * CLK_PERIOD / 2);
            end

            // 프레임 후 라인 복귀
            ps2_data_in = 1'b1;
            ps2_clk_in  = 1'b1;
            #(PS2_HALF * CLK_PERIOD * 2);
        end
    endtask

    // ----------------------------------------------------------------
    // MMIO 읽기 헬퍼
    // ----------------------------------------------------------------
    task mmio_read;
        input [7:0] offset;
        output [31:0] data;
        begin
            @(negedge clk);
            tb_sel  = 1'b1;
            tb_we   = 1'b0;
            tb_off  = offset;
            tb_wdata= 32'h0;
            @(negedge clk);
            data = rdata_out;
            tb_sel  = 1'b0;
            @(posedge clk); // 1사이클 여유
        end
    endtask

    // ----------------------------------------------------------------
    // 검증 헬퍼
    // ----------------------------------------------------------------
    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [63:0] label; // 최대 8글자 ASCII 태그
        begin
            if (got !== exp) begin
                $display("FAIL T%0d [%s]: got=0x%08X exp=0x%08X",
                         test_num, label, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // 메인
    // ----------------------------------------------------------------
    reg [31:0] rd;

    initial begin
        // 초기화
        fail_cnt    = 0;
        test_num    = 0;
        rst         = 1'b1;
        ps2_clk_in  = 1'b1;
        ps2_data_in = 1'b1;
        tb_sel      = 1'b0;
        tb_we       = 1'b0;
        tb_off      = 8'h0;
        tb_wdata    = 32'h0;

        repeat(10) @(posedge clk);
        rst = 1'b0;
        repeat(5) @(posedge clk);

        // ============================================================
        // T1: make 'H' (스캔코드 0x33, ASCII 0x68)
        // ============================================================
        test_num = 1;
        send_ps2_byte(8'h33, 1'b0); // make H

        // kbd_ready가 올라올 때까지 최대 50사이클 대기
        begin : wait_t1
            integer w;
            for (w = 0; w < 50; w = w + 1) begin
                @(posedge clk);
                if (kbd_irq) disable wait_t1;
            end
        end

        // STATUS 읽기: kbd_ready=1 기대
        mmio_read(8'h00, rd);
        check_eq(rd, 32'h0000_0001, "T1-STAT");

        // DATA 읽기: key_up=0, valid=1, ascii=0x68
        mmio_read(8'h04, rd);
        check_eq(rd[9],   1'b0,       "T1-KUP "); // key_up=0
        check_eq(rd[8],   1'b1,       "T1-VLD "); // valid=1
        check_eq(rd[7:0], 8'h68,      "T1-ASCII"); // 'h'

        // DATA 읽기 후 kbd_ready가 클리어됐는지 확인
        mmio_read(8'h00, rd);
        check_eq(rd, 32'h0000_0000, "T1-CLR ");

        // ============================================================
        // T2: break 'H' (F0 + 0x33, key_up=1)
        // ============================================================
        test_num = 2;
        send_ps2_byte(8'hF0, 1'b0); // break prefix
        // F0은 ASCII=0이므로 kbd_ready는 올라오지 않음; 다음 바이트를 기다림
        repeat(5) @(posedge clk);

        send_ps2_byte(8'h33, 1'b0); // break 'H'
        begin : wait_t2
            integer w;
            for (w = 0; w < 50; w = w + 1) begin
                @(posedge clk);
                if (kbd_irq) disable wait_t2;
            end
        end

        mmio_read(8'h00, rd);
        check_eq(rd, 32'h0000_0001, "T2-STAT");

        mmio_read(8'h04, rd);
        check_eq(rd[9],   1'b1,  "T2-KUP "); // key_up=1
        check_eq(rd[8],   1'b1,  "T2-VLD "); // valid=1
        check_eq(rd[7:0], 8'h68, "T2-ASCII"); // 'h'

        // ============================================================
        // T3: make 'I' (스캔코드 0x43, ASCII 0x69)
        // ============================================================
        test_num = 3;
        send_ps2_byte(8'h43, 1'b0); // make I

        begin : wait_t3
            integer w;
            for (w = 0; w < 50; w = w + 1) begin
                @(posedge clk);
                if (kbd_irq) disable wait_t3;
            end
        end

        mmio_read(8'h04, rd);
        check_eq(rd[9],   1'b0,  "T3-KUP "); // key_up=0
        check_eq(rd[8],   1'b1,  "T3-VLD "); // valid=1
        check_eq(rd[7:0], 8'h69, "T3-ASCII"); // 'i'

        // ============================================================
        // T4: 패리티 오류 프레임 → rx_err=1, kbd_ready 올라오지 않음
        // ============================================================
        test_num = 4;
        // 먼저 kbd_ready 클리어 확인 (DATA 이미 읽음)
        mmio_read(8'h00, rd);
        check_eq(rd, 32'h0000_0000, "T4-PRE ");

        // 오류 프레임 전송
        send_ps2_byte(8'h1C, 1'b1); // 'A' but bad parity

        // rx_err 펄스 후 kbd_ready는 여전히 0이어야 함
        repeat(10) @(posedge clk);
        // rx_err is a 1-cycle pulse, check irq (=kbd_ready) stayed low
        mmio_read(8'h00, rd);
        check_eq(rd, 32'h0000_0000, "T4-ERR ");

        // ============================================================
        // T5: E0 확장 코드 무시 확인 (E0 + 임의 바이트)
        // ============================================================
        test_num = 5;
        send_ps2_byte(8'hE0, 1'b0); // extended prefix
        repeat(5) @(posedge clk);
        send_ps2_byte(8'h75, 1'b0); // Up arrow (extended, 0x75)
        repeat(10) @(posedge clk);
        // kbd_ready는 올라오지 않아야 함
        mmio_read(8'h00, rd);
        check_eq(rd, 32'h0000_0000, "T5-EXT ");

        // ============================================================
        // 결과
        // ============================================================
        if (fail_cnt == 0)
            $display("PASS: 모든 테스트 통과 (%0d개)", test_num);
        else
            $display("FAIL: %0d개 실패", fail_cnt);

        $finish;
    end

    // 타임아웃
    initial begin
        #(50_000_000); // 50ms (100MHz 기준 5백만 클럭)
        $display("FAIL: 타임아웃");
        $finish;
    end

endmodule
