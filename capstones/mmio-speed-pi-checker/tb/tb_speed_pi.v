// tb_speed_pi.v — 속도 PI 폐루프 자체 점검 테스트벤치
// WINDOW_CYCLES=1000 (시뮬레이션 단축, 10 ns 클럭)
//
// 검사 항목:
//   CHECK1: IP_ID = 0x53504931
//   CHECK2: IP_VER = 0x01000001
//   CHECK3: 창 계수 — 40 CW 에지 주입 → speed_reg == 40 (1창)
//   CHECK4: TARGET=20, 느린 엔코더(speed≈8) → duty 증가 확인 (PI 출력 양수)
//   CHECK5: CTRL.clear → speed_reg=0, duty_reg=0
`timescale 1ns/1ps
`define SP_BASE 32'h1002_0000

module tb_speed_pi;
    // 클럭/리셋
    reg clk, rst;
    initial clk = 0;
    always #5 clk = ~clk;

    // 마스터 포트
    reg         m_valid, m_we;
    reg  [31:0] m_addr, m_wdata;
    wire [31:0] m_rdata;
    wire        m_ready;
    wire [15:0] led;
    wire        uart_tx_pin;

    // 엔코더
    reg enc_a, enc_b;
    wire pwm_out;

    soc_top #(.WINDOW_CYCLES(1000)) dut (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we),
        .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .led(led), .sw(16'h0000),
        .uart_tx_pin(uart_tx_pin),
        .enc_a(enc_a), .enc_b(enc_b),
        .pwm_out(pwm_out)
    );

    // MMIO 태스크
    task mmio_write;
        input [31:0] a; input [31:0] d;
        begin
            @(posedge clk); #1;
            m_valid=1; m_we=1; m_addr=a; m_wdata=d;
            @(posedge clk); #1;
            m_valid=0; m_we=0;
        end
    endtask

    task mmio_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge clk); #1;
            m_valid=1; m_we=0; m_addr=a; m_wdata=0;
            @(posedge clk); #1;
            d = m_rdata;
            m_valid=0;
        end
    endtask

    // 4× CW 에지 N 개 주입 태스크 (A/B 위상 순환)
    integer enc_phase;
    task inject_cw_edges;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                case (enc_phase % 4)
                    0: begin enc_a=1; enc_b=0; end
                    1: begin enc_a=1; enc_b=1; end
                    2: begin enc_a=0; enc_b=1; end
                    3: begin enc_a=0; enc_b=0; end
                endcase
                enc_phase = enc_phase + 1;
                @(posedge clk); #1;
            end
        end
    endtask

    // 결과 집계
    integer pass_cnt, fail_cnt;
    reg [31:0] rd;
    integer i;

    initial begin
        rst=1; m_valid=0; m_we=0; m_addr=0; m_wdata=0;
        enc_a=0; enc_b=0; enc_phase=0;
        pass_cnt=0; fail_cnt=0;
        repeat(5) @(posedge clk);
        rst=0;
        repeat(3) @(posedge clk);

        // ---- CHECK1: IP_ID ----
        mmio_read(`SP_BASE + 32'hFFF0, rd);
        if (rd !== 32'h53504931) begin
            $display("FAIL CHECK1: IP_ID=0x%08X (exp 0x53504931)", rd);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS CHECK1: IP_ID=0x%08X", rd);
            pass_cnt = pass_cnt + 1;
        end

        // ---- CHECK2: IP_VER ----
        mmio_read(`SP_BASE + 32'hFFF4, rd);
        if (rd !== 32'h01000001) begin
            $display("FAIL CHECK2: IP_VER=0x%08X (exp 0x01000001)", rd);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS CHECK2: IP_VER=0x%08X", rd);
            pass_cnt = pass_cnt + 1;
        end

        // ---- CHECK3: 창 계수 ----
        // 설정: PERIOD=4000, TARGET=10, KP=0x0080, KI=0x0010, enable
        mmio_write(`SP_BASE + 32'h0014, 32'd4000);
        mmio_write(`SP_BASE + 32'h0008, 32'h0080);
        mmio_write(`SP_BASE + 32'h000C, 32'h0010);
        mmio_write(`SP_BASE + 32'h0004, 32'd10);
        mmio_write(`SP_BASE + 32'h001C, 32'd50);
        mmio_write(`SP_BASE + 32'h0000, 32'd1); // enable

        // 1창(1000클럭) 중 첫 40 클럭에 40 CW 에지 주입 → speed_reg=40
        inject_cw_edges(40);
        // 나머지 클럭 대기 (창 완료까지)
        repeat(960) @(posedge clk);
        // PI 파이프라인 대기 (2사이클)
        repeat(5) @(posedge clk);

        mmio_read(`SP_BASE + 32'h0010, rd);
        if (rd[15:0] !== 16'd40) begin
            $display("FAIL CHECK3: speed_reg=%0d (exp 40)", rd[15:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS CHECK3: speed_reg=%0d", rd[15:0]);
            pass_cnt = pass_cnt + 1;
        end

        // ---- CHECK4: 느린 엔코더 → duty 증가 ----
        // TARGET=20, 하지만 엔코더는 8 에지만 → error=12 → duty 양수여야
        // clear 후 재설정
        mmio_write(`SP_BASE + 32'h0000, 32'd3); // clear
        repeat(5) @(posedge clk);
        mmio_write(`SP_BASE + 32'h0004, 32'd20); // new target
        mmio_write(`SP_BASE + 32'h0000, 32'd1);  // enable

        inject_cw_edges(8);           // 8 에지만 주입
        repeat(992) @(posedge clk);   // 창 완료
        repeat(5)   @(posedge clk);   // 파이프라인 대기

        mmio_read(`SP_BASE + 32'h0018, rd);
        if (rd[15:0] == 16'd0) begin
            $display("FAIL CHECK4: duty=0 when speed<target (expected >0)");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS CHECK4: duty=%0d (speed=8, target=20)", rd[15:0]);
            pass_cnt = pass_cnt + 1;
        end

        // ---- CHECK5: clear 후 speed=0, duty=0 ----
        mmio_write(`SP_BASE + 32'h0000, 32'd3); // enable + clear
        repeat(5) @(posedge clk);
        mmio_read(`SP_BASE + 32'h0010, rd);
        if (rd[15:0] !== 16'd0) begin
            $display("FAIL CHECK5a: speed after clear=%0d (exp 0)", rd[15:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            mmio_read(`SP_BASE + 32'h0018, rd);
            if (rd[15:0] !== 16'd0) begin
                $display("FAIL CHECK5b: duty after clear=%0d (exp 0)", rd[15:0]);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("PASS CHECK5: speed=0 duty=0 after clear");
                pass_cnt = pass_cnt + 1;
            end
        end

        // 최종
        $display("--- RESULT: PASS %0d / FAIL %0d ---", pass_cnt, fail_cnt);
        if (fail_cnt !== 0)
            $display("FAIL: %0d check(s) failed", fail_cnt);
        else
            $display("PASS: all checks passed");
        $finish;
    end

    initial begin
        #5_000_000;
        $display("FAIL: simulation timeout");
        $finish;
    end
endmodule
