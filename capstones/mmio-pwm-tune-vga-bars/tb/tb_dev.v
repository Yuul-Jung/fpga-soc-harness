`timescale 1ns/1ps
// 자체 점검 테스트벤치(장치 수준): 톤 주파수, PWM 듀티, 끄기 동작, VGA 동기 타이밍, 켜진 화소 수, 프레임 카운터.
module tb_dev;
    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg         m_valid = 1'b0, m_we = 1'b0;
    reg  [31:0] m_addr = 32'd0, m_wdata = 32'd0;
    wire [31:0] m_rdata;
    wire        m_ready, pwm, amp_sd_n, tone, hsync, vsync;
    wire [15:0] led;
    wire [3:0]  vr, vg, vb;
    integer     errors = 0;
    integer     i, edges, tone_hi, pwm_hi, lit, bad_blank, f0, f1;
    reg         tone_q, hs_q, vs_q;
    time        t_a, t_b, t_c;

    always #5 clk = ~clk;

    soc_top dut (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(16'h00A5), .led(led), .pwm(pwm), .amp_sd_n(amp_sd_n), .tone(tone),
        .hsync(hsync), .vsync(vsync), .vga_r(vr), .vga_g(vg), .vga_b(vb)
    );

    task wr(input [31:0] a, input [31:0] d);
        begin
            @(negedge clk); m_valid = 1'b1; m_we = 1'b1; m_addr = a; m_wdata = d;
            @(negedge clk); m_valid = 1'b0; m_we = 1'b0;
        end
    endtask

    task chk(input [31:0] a, input [31:0] exp, input [8*16-1:0] name);
        begin
            @(negedge clk); m_valid = 1'b1; m_we = 1'b0; m_addr = a;
            #1;
            if (m_rdata !== exp) begin
                $display("FAIL: %0s 읽기 0x%08h 기대 0x%08h", name, m_rdata, exp);
                errors = errors + 1;
            end
            @(negedge clk); m_valid = 1'b0;
        end
    endtask

    // 한 구간(20 ms = 2,000,000 클럭) 동안 톤 상승 에지, 톤 high 클럭, PWM high 클럭을 센다
    task measure;
        begin
            edges = 0; tone_hi = 0; pwm_hi = 0; tone_q = tone;
            for (i = 0; i < 2000000; i = i + 1) begin
                @(posedge clk);
                if (tone && !tone_q) edges = edges + 1;
                tone_q = tone;
                if (tone) tone_hi = tone_hi + 1;
                if (pwm)  pwm_hi  = pwm_hi + 1;
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst = 1'b0;
        // 레지스터 읽기/쓰기
        wr(32'h1000_3000, 32'd42950);          // 약 1000 Hz
        wr(32'h1000_3008, 32'd64);
        chk(32'h1000_3000, 32'd42950, "INC");
        chk(32'h1000_3008, 32'd64, "VOL");
        chk(32'h1000_3004, 32'd0, "EN(리셋값)");
        if (amp_sd_n !== 1'b0 || pwm !== 1'b0) begin
            $display("FAIL: 꺼진 상태에서 amp_sd_n/pwm이 0이 아님"); errors = errors + 1;
        end
        // 켜고 1000 Hz, 음량 64/256 측정
        wr(32'h1000_3004, 32'd1);
        measure;
        if (edges < 19 || edges > 21) begin
            $display("FAIL: 20ms 동안 톤 에지 %0d (기대 20±1)", edges); errors = errors + 1;
        end
        if (tone_hi < 900000 || tone_hi > 1100000) begin
            $display("FAIL: 톤 high %0d클럭 (기대 약 1,000,000)", tone_hi); errors = errors + 1;
        end
        // PWM high / 톤 high ≈ 64/256 = 0.25 (허용 ±0.03)
        if (pwm_hi * 100 < tone_hi * 22 || pwm_hi * 100 > tone_hi * 28) begin
            $display("FAIL: PWM 듀티 %0d/%0d (기대 25%%±3)", pwm_hi, tone_hi); errors = errors + 1;
        end
        // 음량 0이면 PWM 항상 0
        wr(32'h1000_3008, 32'd0);
        pwm_hi = 0;
        for (i = 0; i < 200000; i = i + 1) begin @(posedge clk); if (pwm) pwm_hi = pwm_hi + 1; end
        if (pwm_hi != 0) begin $display("FAIL: VOL=0인데 PWM high %0d", pwm_hi); errors = errors + 1; end
        // 끄면 amp_sd_n=0, 톤 정지
        wr(32'h1000_3004, 32'd0);
        repeat (4) @(posedge clk);
        if (amp_sd_n !== 1'b0 || tone !== 1'b0) begin
            $display("FAIL: 끈 뒤에도 amp_sd_n/tone이 0이 아님"); errors = errors + 1;
        end
        // GPIO 스위치 읽기
        chk(32'h1000_0004, 32'h0000_00A5, "SW");

        // ---- VGA ----
        chk(32'h1000_4004, 32'h0000_00F0, "COLOR(리셋값)");
        wr(32'h1000_4000, 32'd3);                 // 막대 0..3 켜짐 = 4*80*480 화소
        wr(32'h1000_4004, 32'h0F0F);              // 하위 12비트 = 0xF0F
        chk(32'h1000_4000, 32'd3, "NOTE");
        // hsync 주기와 low 폭
        @(negedge hsync); t_a = $time;
        @(posedge hsync); t_b = $time;
        @(negedge hsync); t_c = $time;
        if (t_c - t_a != 32000) begin $display("FAIL: hsync 주기 %0d ns (기대 32000)", t_c - t_a); errors = errors + 1; end
        if (t_b - t_a != 3840)  begin $display("FAIL: hsync low 폭 %0d ns (기대 3840)", t_b - t_a); errors = errors + 1; end
        // vsync 주기와 low 폭, 프레임 카운터
        @(negedge vsync); t_a = $time;
        @(negedge clk); m_valid = 1'b1; m_we = 1'b0; m_addr = 32'h1000_4008; #1; f0 = m_rdata; @(negedge clk); m_valid = 1'b0;
        @(posedge vsync); t_b = $time;
        @(negedge vsync); t_c = $time;
        if (t_c - t_a != 16800000) begin $display("FAIL: vsync 주기 %0d ns (기대 16800000)", t_c - t_a); errors = errors + 1; end
        if (t_b - t_a != 64000)    begin $display("FAIL: vsync low 폭 %0d ns (기대 64000)", t_b - t_a); errors = errors + 1; end
        @(negedge clk); m_valid = 1'b1; m_we = 1'b0; m_addr = 32'h1000_4008; #1; f1 = m_rdata; @(negedge clk); m_valid = 1'b0;
        if (f1 - f0 != 1) begin $display("FAIL: 프레임 카운터 증가 %0d (기대 1)", f1 - f0); errors = errors + 1; end
        // 한 프레임 동안 켜진 화소 수와 블랭킹 구간 출력 확인
        lit = 0; bad_blank = 0;
        @(negedge vsync);
        for (i = 0; i < 1680000; i = i + 1) begin
            @(posedge clk);
            if (dut.u_vga.pe) begin
                if ({vr, vg, vb} !== 12'h000) begin
                    lit = lit + 1;
                    if ({vr, vg, vb} !== 12'hF0F) bad_blank = bad_blank + 1;
                end
                if (!dut.u_vga.de && {vr, vg, vb} !== 12'h000) bad_blank = bad_blank + 1;
            end
        end
        if (lit != 153600) begin $display("FAIL: 켜진 화소 %0d (기대 153600)", lit); errors = errors + 1; end
        if (bad_blank != 0) begin $display("FAIL: 색 불일치/블랭킹 위반 %0d", bad_blank); errors = errors + 1; end

        if (errors == 0) $display("PASS: tb_dev 톤 에지 %0d, VGA 켜진 화소 %0d", edges, lit);
        else             $display("FAIL: tb_dev 오류 %0d건", errors);
        $finish;
    end
endmodule
