`timescale 1ns/1ps
// 자체 점검 테스트벤치(시스템 수준): 버튼 한 번에 8음이 순서대로 INC·NOTE·LED로 기록되고, 끝나면 소리가 꺼지는지 확인한다.
module tb_demo;
    localparam NOTE_CLKS = 4000;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg         btn = 1'b0;
    wire        m_valid, m_we, m_ready;
    wire [31:0] m_addr, m_wdata, m_rdata;
    wire [15:0] led;
    wire        pwm, amp_sd_n, tone, hsync, vsync;
    wire [3:0]  vr, vg, vb;
    integer     errors = 0;
    integer     k = 0;
    integer     n_note = 0;
    integer     n_off = 0;
    integer     n_vol_bad = 0;
    integer     j;
    reg [31:0]  exp_inc [0:7];
    reg [31:0]  got_inc [0:7];

    always #5 clk = ~clk;

    demo_master #(.NOTE_CLKS(NOTE_CLKS)) u_master (
        .clk(clk), .rst(rst), .btn(btn),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready)
    );
    soc_top dut (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(16'h0000), .led(led), .pwm(pwm), .amp_sd_n(amp_sd_n), .tone(tone),
        .hsync(hsync), .vsync(vsync), .vga_r(vr), .vga_g(vg), .vga_b(vb)
    );

    // 버스 쓰기 감시
    always @(posedge clk) begin
        if (!rst && m_valid && m_we) begin
            if (m_addr == 32'h1000_3000) begin
                if (k < 8) got_inc[k] = m_wdata;
                k = k + 1;
            end
            if (m_addr == 32'h1000_4000) begin
                if (m_wdata !== n_note) begin
                    $display("FAIL: NOTE 쓰기 %0d (기대 %0d)", m_wdata, n_note); errors = errors + 1;
                end
                n_note = n_note + 1;
            end
            if (m_addr == 32'h1000_3004 && m_wdata == 32'd0) n_off = n_off + 1;
            if (m_addr == 32'h1000_3008 && m_wdata !== 32'd64) n_vol_bad = n_vol_bad + 1;   // SW=0이면 기본 음량 64
        end
    end

    initial begin
        exp_inc[0] = 11237; exp_inc[1] = 12613; exp_inc[2] = 14158; exp_inc[3] = 14999;
        exp_inc[4] = 16836; exp_inc[5] = 18898; exp_inc[6] = 21212; exp_inc[7] = 22473;
        repeat (8) @(posedge clk);
        rst = 1'b0;
        repeat (20) @(posedge clk);
        if (k != 0 || m_valid !== 1'b0) begin
            $display("FAIL: 버튼 전에 쓰기 발생"); errors = errors + 1;
        end
        // 버튼 누름(마스터 내부 동기화에 맞춰 충분히 유지)
        btn = 1'b1; repeat (20) @(posedge clk); btn = 1'b0;
        // 8음 × NOTE_CLKS + 여유
        repeat (8 * NOTE_CLKS + 400) @(posedge clk);
        if (k != 8) begin $display("FAIL: INC 쓰기 %0d회 (기대 8)", k); errors = errors + 1; end
        for (j = 0; j < 8; j = j + 1)
            if (got_inc[j] !== exp_inc[j]) begin
                $display("FAIL: %0d번째 INC %0d (기대 %0d)", j, got_inc[j], exp_inc[j]); errors = errors + 1;
            end
        if (n_note != 8) begin $display("FAIL: NOTE 쓰기 %0d회", n_note); errors = errors + 1; end
        if (n_off != 1)  begin $display("FAIL: 끄기 쓰기 %0d회 (기대 1)", n_off); errors = errors + 1; end
        if (n_vol_bad != 0) begin $display("FAIL: 기본 음량 불일치 %0d회", n_vol_bad); errors = errors + 1; end
        if (amp_sd_n !== 1'b0) begin $display("FAIL: 재생 끝났는데 amp_sd_n=1"); errors = errors + 1; end
        if (led !== 16'h0080) begin $display("FAIL: LED 0x%04h (기대 0x0080)", led); errors = errors + 1; end
        if (errors == 0) $display("PASS: tb_demo 8음 재생");
        else             $display("FAIL: tb_demo 오류 %0d건", errors);
        $finish;
    end
endmodule
