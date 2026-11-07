// tb_ir_nec.v — NEC IR 디코더 자체 점검 테스트벤치
// 테스트 케이스 4종:
//   TC1: 정상 프레임 (ADDR=0xA5, CMD=0x3C)
//   TC2: 반전 검사 오류 (CMD 반전 불일치)
//   TC3: 반복 코드
//   TC4: 잘림 프레임 (데이터 중간에 종료)
// 통과: "PASS: <설명>", 실패: "FAIL: <설명>" (단위 테스트마다)
// 최종: "=== ALL PASS ===" 또는 "=== FAIL: N 케이스 실패 ==="
// 클럭: 100 MHz (10 ns 주기)
// 주의: 타이밍 단위가 길어 `timescale 1ns/1ps 로 10,000 사이클 단위를 쓴다

`timescale 1ns/1ps

module tb_ir_nec;

    // ---------------------------------------------------------------
    // 시뮬레이션 파라미터
    // ---------------------------------------------------------------
    localparam CLK_PERIOD = 10;  // 10 ns → 100 MHz

    // NEC 타이밍 (클럭 수, ±20% 허용 중앙값 사용)
    localparam LD_BURST  = 900_000;   // 9.0 ms
    localparam LD_SPC    = 450_000;   // 4.5 ms
    localparam RP_SPC    = 225_000;   // 2.25 ms
    localparam DB_BURST  = 56_250;    // 562.5 µs
    localparam B0_SPC    = 56_250;    // bit-0 space
    localparam B1_SPC    = 168_750;   // bit-1 space (3×562.5)
    localparam STOP_BURST= 56_250;    // 종료 버스트

    // ---------------------------------------------------------------
    // DUT 신호
    // ---------------------------------------------------------------
    reg  clk;
    reg  rst;
    reg  ir_in;  // 액티브 로우: 0 = 버스트, 1 = 스페이스

    wire decoded_valid;
    wire decoded_repeat;
    wire decoded_err;
    wire [7:0] decoded_addr;
    wire [7:0] decoded_cmd;

    // ---------------------------------------------------------------
    // DUT 인스턴스
    // ---------------------------------------------------------------
    ir_nec_decode uut (
        .clk            (clk),
        .rst            (rst),
        .ir_in          (ir_in),
        .decoded_valid  (decoded_valid),
        .decoded_repeat (decoded_repeat),
        .decoded_err    (decoded_err),
        .decoded_addr   (decoded_addr),
        .decoded_cmd    (decoded_cmd)
    );

    // ---------------------------------------------------------------
    // 클럭
    // ---------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------------------------------------------------------
    // 테스트 카운터
    // ---------------------------------------------------------------
    integer fail_count;

    // ---------------------------------------------------------------
    // 태스크: 버스트(burst=1 → ir_in=0) N 클럭
    // ---------------------------------------------------------------
    task burst_clk;
        input integer n;
        integer i;
        begin
            ir_in = 1'b0;  // 액티브 로우: 버스트 시작
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // ---------------------------------------------------------------
    // 태스크: 스페이스(burst=0 → ir_in=1) N 클럭
    // ---------------------------------------------------------------
    task space_clk;
        input integer n;
        integer i;
        begin
            ir_in = 1'b1;  // 액티브 로우: 스페이스
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // ---------------------------------------------------------------
    // 태스크: 32비트 NEC 데이터 전송 (LSB first)
    //         data = {~CMD, CMD, ~ADDR, ADDR} 순서 (NEC 표준)
    //         전송 비트 순서: ADDR[7:0] ADDR_INV[7:0] CMD[7:0] CMD_INV[7:0]
    // ---------------------------------------------------------------
    task send_32bit;
        input [31:0] data;
        integer b;
        begin
            for (b = 0; b < 32; b = b + 1) begin
                burst_clk(DB_BURST);
                if (data[b])
                    space_clk(B1_SPC);
                else
                    space_clk(B0_SPC);
            end
        end
    endtask

    // ---------------------------------------------------------------
    // 태스크: 완전한 NEC 프레임 전송
    // ---------------------------------------------------------------
    task send_nec_frame;
        input [7:0] addr;
        input [7:0] cmd;
        reg [31:0] frame;
        begin
            frame = {~cmd, cmd, ~addr, addr};
            // 리더 버스트
            burst_clk(LD_BURST);
            // 리더 스페이스
            space_clk(LD_SPC);
            // 32비트 데이터
            send_32bit(frame);
            // 종료 버스트
            burst_clk(STOP_BURST);
            // 최소 스페이스 (다음 프레임 전에)
            space_clk(10);
        end
    endtask

    // ---------------------------------------------------------------
    // 태스크: 반복 코드 전송 (리더 버스트 + 2.25ms 스페이스 + 종료 버스트)
    // ---------------------------------------------------------------
    task send_repeat_code;
        begin
            burst_clk(LD_BURST);
            space_clk(RP_SPC);
            burst_clk(STOP_BURST);
            space_clk(10);
        end
    endtask

    // ---------------------------------------------------------------
    // 태스크: N 비트 후 잘림 (스페이스 없이 종료)
    // ---------------------------------------------------------------
    task send_truncated_frame;
        input [7:0] addr;
        input [7:0] cmd;
        input integer cut_after_bit;
        reg [31:0] frame;
        integer b;
        begin
            frame = {~cmd, cmd, ~addr, addr};
            burst_clk(LD_BURST);
            space_clk(LD_SPC);
            for (b = 0; b < cut_after_bit; b = b + 1) begin
                burst_clk(DB_BURST);
                if (frame[b])
                    space_clk(B1_SPC);
                else
                    space_clk(B0_SPC);
            end
            // 비정상적으로 긴 스페이스 → FSM이 타임아웃하고 IDLE로 복귀
            space_clk(1_000_000);
        end
    endtask

    // ---------------------------------------------------------------
    // 태스크: 출력 대기 (최대 N 클럭)
    // ---------------------------------------------------------------
    task wait_output;
        input integer max_clk;
        input integer check_valid;
        input integer check_repeat;
        input integer check_err;
        output integer got_it;
        integer w;
        begin
            got_it = 0;
            for (w = 0; w < max_clk && !got_it; w = w + 1) begin
                @(posedge clk); #1;
                if (check_valid  && decoded_valid)  got_it = 1;
                if (check_repeat && decoded_repeat) got_it = 1;
                if (check_err    && decoded_err)    got_it = 1;
            end
        end
    endtask

    // ---------------------------------------------------------------
    // 메인 테스트
    // ---------------------------------------------------------------
    integer got_pulse;
    reg [7:0] exp_addr, exp_cmd;

    initial begin
        // 초기화
        fail_count = 0;
        ir_in = 1'b1;  // 스페이스(신호 없음)
        rst   = 1'b1;
        repeat (10) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        $display("=== NEC IR 디코더 테스트 시작 ===");

        // ============================================================
        // TC1: 정상 프레임 (ADDR=0xA5, CMD=0x3C)
        // ============================================================
        $display("--- TC1: 정상 프레임 (ADDR=0xA5, CMD=0x3C) ---");
        exp_addr = 8'hA5;
        exp_cmd  = 8'h3C;
        fork
            begin
                // 프레임 전송 (별도 쓰레드)
                repeat (5) @(posedge clk);
                send_nec_frame(exp_addr, exp_cmd);
            end
            begin
                // 출력 감시
                wait_output(1_200_000, 1, 0, 0, got_pulse);
                if (!got_pulse) begin
                    $display("FAIL: TC1 - decoded_valid 펄스 없음");
                    fail_count = fail_count + 1;
                end else if (decoded_addr !== exp_addr) begin
                    $display("FAIL: TC1 - ADDR 불일치 (기대 0x%02X, 실제 0x%02X)", exp_addr, decoded_addr);
                    fail_count = fail_count + 1;
                end else if (decoded_cmd !== exp_cmd) begin
                    $display("FAIL: TC1 - CMD 불일치 (기대 0x%02X, 실제 0x%02X)", exp_cmd, decoded_cmd);
                    fail_count = fail_count + 1;
                end else begin
                    $display("PASS: TC1 - ADDR=0x%02X CMD=0x%02X", decoded_addr, decoded_cmd);
                end
            end
        join

        // 사이 간격
        space_clk(50_000);

        // ============================================================
        // TC2: 반전 검사 오류 (CMD 반전 불일치)
        //      frame = {~cmd_wrong, cmd, ~addr, addr} — 여기서 ~cmd_wrong != cmd
        // ============================================================
        $display("--- TC2: 반전 오류 프레임 ---");
        begin : tc2_block
            reg [31:0] bad_frame;
            bad_frame = {8'hFF, 8'h3C, ~8'hA5, 8'hA5};  // CMD_INV=0xFF (불일치)
            rst = 1'b1; repeat(5) @(posedge clk); rst = 1'b0; @(posedge clk);
            fork
                begin
                    repeat (5) @(posedge clk);
                    // 리더 버스트 + 스페이스
                    burst_clk(LD_BURST);
                    space_clk(LD_SPC);
                    // 32비트 데이터 (불량 프레임)
                    send_32bit(bad_frame);
                    // 종료 버스트
                    burst_clk(STOP_BURST);
                    space_clk(10);
                end
                begin
                    wait_output(1_200_000, 0, 0, 1, got_pulse);
                    if (!got_pulse) begin
                        $display("FAIL: TC2 - decoded_err 펄스 없음");
                        fail_count = fail_count + 1;
                    end else begin
                        $display("PASS: TC2 - 반전 오류 감지됨");
                    end
                end
            join
        end

        space_clk(50_000);

        // ============================================================
        // TC3: 반복 코드 (TC1 직후 전송)
        // ============================================================
        $display("--- TC3: 반복 코드 ---");
        rst = 1'b1; repeat(5) @(posedge clk); rst = 1'b0; @(posedge clk);
        // 먼저 TC1 정상 프레임으로 addr/cmd를 세팅
        fork
            begin
                repeat(5) @(posedge clk);
                send_nec_frame(8'hA5, 8'h3C);
                space_clk(1000);  // 짧은 간격 후 반복 코드
                send_repeat_code();
            end
            begin
                // decoded_valid 무시하고 decoded_repeat 대기
                // (전체 프레임 전송 시간 + 반복 코드 전송 시간)
                wait_output(2_000_000, 0, 1, 0, got_pulse);
                if (!got_pulse) begin
                    $display("FAIL: TC3 - decoded_repeat 펄스 없음");
                    fail_count = fail_count + 1;
                end else begin
                    $display("PASS: TC3 - 반복 코드 감지됨");
                end
            end
        join

        space_clk(50_000);

        // ============================================================
        // TC4: 잘림 프레임 (16비트 후 종료)
        //      valid, repeat, err 모두 없어야 함 → 최대 대기 후 없으면 PASS
        // ============================================================
        $display("--- TC4: 잘림 프레임 (16비트 후 종료) ---");
        rst = 1'b1; repeat(5) @(posedge clk); rst = 1'b0; @(posedge clk);
        begin : tc4_block
            integer v4, r4, e4;
            v4 = 0; r4 = 0; e4 = 0;
            fork
                begin
                    repeat(5) @(posedge clk);
                    send_truncated_frame(8'hA5, 8'h3C, 16);
                end
                begin : tc4_wait
                    integer w4;
                    for (w4 = 0; w4 < 1_200_000; w4 = w4 + 1) begin
                        @(posedge clk); #1;
                        if (decoded_valid)  v4 = 1;
                        if (decoded_repeat) r4 = 1;
                        if (decoded_err)    e4 = 1;
                    end
                    if (v4 || r4 || e4) begin
                        $display("FAIL: TC4 - 잘림 프레임에서 출력 발생 (valid=%0d repeat=%0d err=%0d)", v4, r4, e4);
                        fail_count = fail_count + 1;
                    end else begin
                        $display("PASS: TC4 - 잘림 프레임 출력 없음 (FSM 복귀)");
                    end
                end
            join
        end

        // ============================================================
        // 최종 보고
        // ============================================================
        $display("");
        if (fail_count == 0) begin
            $display("=== ALL PASS ===");
        end else begin
            $display("=== FAIL: %0d 케이스 실패 ===", fail_count);
        end

        $finish;
    end

    // 타임아웃 보호 (3초 시뮬레이션 시간 = 300M ns)
    initial begin
        #300_000_000;
        $display("FAIL: 테스트 타임아웃 (300ms 초과)");
        $finish;
    end

endmodule
