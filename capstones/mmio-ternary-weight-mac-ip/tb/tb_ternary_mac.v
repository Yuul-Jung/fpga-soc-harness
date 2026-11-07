// tb_ternary_mac.v — 자체 검증 테스트벤치
// 통과: stdout에 "PASS" 로 시작하는 줄 출력
// 실패: stdout에 "FAIL" 로 시작하는 줄 출력 후 fail_cnt 증가
// iverilog -g2001 -Wall -Wno-timescale -o tb_ternary_mac tb/tb_ternary_mac.v rtl/*.v && vvp tb_ternary_mac

`timescale 1ns/1ps

module tb_ternary_mac;

// ── 파라미터 ───────────────────────────────────────────────
localparam CLK_PERIOD = 10;  // 10ns = 100 MHz

// ── 신호 선언 ──────────────────────────────────────────────
reg clk, rst_n;

reg  [7:0]  m_awaddr;
reg         m_awvalid;
wire        m_awready;
reg  [31:0] m_wdata;
reg  [3:0]  m_wstrb;
reg         m_wvalid;
wire        m_wready;
wire [1:0]  m_bresp;
wire        m_bvalid;
reg         m_bready;
reg  [7:0]  m_araddr;
reg         m_arvalid;
wire        m_arready;
wire [31:0] m_rdata;
wire [1:0]  m_rresp;
wire        m_rvalid;
reg         m_rready;

// ── DUT 인스턴스 ───────────────────────────────────────────
soc_top dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .m_awaddr (m_awaddr), .m_awvalid (m_awvalid), .m_awready (m_awready),
    .m_wdata  (m_wdata),  .m_wstrb   (m_wstrb),   .m_wvalid  (m_wvalid),
    .m_wready (m_wready), .m_bresp   (m_bresp),   .m_bvalid  (m_bvalid),
    .m_bready (m_bready),
    .m_araddr (m_araddr), .m_arvalid (m_arvalid), .m_arready (m_arready),
    .m_rdata  (m_rdata),  .m_rresp   (m_rresp),   .m_rvalid  (m_rvalid),
    .m_rready (m_rready)
);

// ── 클럭 ──────────────────────────────────────────────────
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// ── 실패 카운터 ───────────────────────────────────────────
integer fail_cnt;
initial fail_cnt = 0;

// ── 태스크: AXI4-Lite 쓰기 ────────────────────────────────
task axi_write;
    input [7:0]  addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        m_awaddr  = addr;  m_awvalid = 1'b1;
        m_wdata   = data;  m_wstrb   = 4'b1111; m_wvalid = 1'b1;
        // AW 핸드셰이크
        wait(m_awready); @(posedge clk); #1;
        m_awvalid = 1'b0;
        // W 핸드셰이크
        wait(m_wready); @(posedge clk); #1;
        m_wvalid = 1'b0;
        // B 채널
        m_bready = 1'b1;
        wait(m_bvalid); @(posedge clk); #1;
        m_bready = 1'b0;
    end
endtask

// ── 태스크: AXI4-Lite 읽기 ────────────────────────────────
task axi_read;
    input  [7:0]  addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        m_araddr  = addr; m_arvalid = 1'b1;
        wait(m_arready); @(posedge clk); #1; m_arvalid = 1'b0;
        m_rready = 1'b1;
        wait(m_rvalid); data = m_rdata; @(posedge clk); #1;
        m_rready = 1'b0;
    end
endtask

// ── 태스크: 활성화 벡터 1바이트 쓰기 ────────────────────
task write_act;
    input [3:0]  idx;
    input [7:0]  val;
    begin
        axi_write(8'h10, {28'd0, idx});   // V_ADDR
        axi_write(8'h14, {24'd0, val});   // V_DATA
    end
endtask

// ── 태스크: MAC 실행 후 완료 대기 ────────────────────────
reg [31:0] rd_tmp;
integer    wait_mac;

task run_mac_wait;
    input [3:0] veclen;  // 0=1요소, N-1=N요소
    begin
        // CTRL: START=1, CLR_DONE=1(이전 결과 클리어), VECLEN
        axi_write(8'h04, {24'd0, veclen, 2'b00, 1'b1, 1'b1});
        // DONE 대기 (최대 200클럭: veclen≤16 → MAC≤16사이클 + AXI오버헤드)
        wait_mac = 0;
        begin : mac_wait
            forever begin
                @(posedge clk);
                axi_read(8'h00, rd_tmp);
                if (rd_tmp[0]) disable mac_wait;  // DONE
                wait_mac = wait_mac + 1;
                if (wait_mac > 200) begin
                    $display("FAIL: MAC DONE 타임아웃 (200클럭)");
                    fail_cnt = fail_cnt + 1;
                    disable mac_wait;
                end
            end
        end
    end
endtask

// ── 타임아웃 ─────────────────────────────────────────────
initial begin
    #500_000;
    $display("FAIL timeout: 시뮬레이션이 500us 안에 끝나지 않았다");
    $finish;
end

// ── 메인 테스트 ───────────────────────────────────────────
reg [31:0] rd;

initial begin
    // 초기화
    rst_n     = 1'b0;
    m_awaddr  = 8'd0; m_awvalid = 1'b0;
    m_wdata   = 32'd0; m_wstrb = 4'd0; m_wvalid = 1'b0;
    m_bready  = 1'b0;
    m_araddr  = 8'd0; m_arvalid = 1'b0;
    m_rready  = 1'b0;
    fail_cnt  = 0;

    repeat(10) @(posedge clk);
    rst_n = 1'b1;
    repeat(5)  @(posedge clk);

    // ══════════════════════════════════════════════════════
    // 테스트 1: veclen=4, weights={+1,−1,+1,0}, acts={10,20,30,40}
    // 기대값: 10×(+1) + 20×(−1) + 30×(+1) + 40×0 = 10−20+30 = 20
    // 가중치 패킹: w[0]=2'b01(+1), w[1]=2'b10(-1), w[2]=2'b01(+1), w[3]=2'b00(0)
    //   bits: [1:0]=01, [3:2]=10, [5:4]=01, [7:6]=00 → 32'h00000019
    // ══════════════════════════════════════════════════════
    axi_write(8'h08, 32'h00000019);  // W_DATA
    write_act(0, 8'd10);
    write_act(1, 8'd20);
    write_act(2, 8'd30);
    write_act(3, 8'd40);
    run_mac_wait(4'd3);  // veclen=3 → 4요소 (인덱스 0~3)

    axi_read(8'h18, rd);
    if (rd !== 32'd20) begin
        $display("FAIL T1: RESULT=%0d (expected 20)", $signed(rd));
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T1: 삼진 MAC 결과 = %0d (expected 20)", $signed(rd));
    end

    // ══════════════════════════════════════════════════════
    // 테스트 2: veclen=1, 모든 가중치 0 → 결과 = 0
    // ══════════════════════════════════════════════════════
    axi_write(8'h08, 32'h00000000);  // 모든 가중치 00(zero)
    write_act(0, 8'd127);
    run_mac_wait(4'd0);  // veclen=0 → 1요소

    axi_read(8'h18, rd);
    if (rd !== 32'd0) begin
        $display("FAIL T2: 가중치=0, RESULT=%0d (expected 0)", $signed(rd));
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T2: 모든 가중치 0 → 결과 = 0");
    end

    // ══════════════════════════════════════════════════════
    // 테스트 3: 음수 활성화 — veclen=2, weights={+1,+1}, acts={−5,−3}
    // 기대값: (−5)+(−3) = −8
    // W_DATA: w[0]=01, w[1]=01 → bits[1:0]=01, bits[3:2]=01 → 32'h00000005
    // acts: −5=0xFB, −3=0xFD
    // ══════════════════════════════════════════════════════
    axi_write(8'h08, 32'h00000005);
    write_act(0, 8'hFB);  // −5 (2보수)
    write_act(1, 8'hFD);  // −3
    run_mac_wait(4'd1);   // veclen=1 → 2요소

    axi_read(8'h18, rd);
    if ($signed(rd) !== -8) begin
        $display("FAIL T3: 음수 활성화 RESULT=%0d (expected -8)", $signed(rd));
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T3: 음수 활성화 → 결과 = %0d (expected -8)", $signed(rd));
    end

    // ══════════════════════════════════════════════════════
    // 테스트 4: veclen=4, weights={−1,−1,−1,−1}, acts={1,2,3,4}
    // 기대값: −(1+2+3+4) = −10
    // W_DATA: w[0..3]=10 → bits: 10|10|10|10 → 32'h000000AA
    // ══════════════════════════════════════════════════════
    axi_write(8'h08, 32'h000000AA);
    write_act(0, 8'd1);
    write_act(1, 8'd2);
    write_act(2, 8'd3);
    write_act(3, 8'd4);
    run_mac_wait(4'd3);

    axi_read(8'h18, rd);
    if ($signed(rd) !== -10) begin
        $display("FAIL T4: 모두 −1 가중치 RESULT=%0d (expected -10)", $signed(rd));
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("PASS T4: 모두 −1 가중치 → 결과 = %0d (expected -10)", $signed(rd));
    end

    // ── 최종 결과 ─────────────────────────────────────────
    if (fail_cnt == 0) begin
        $display("PASS: 모든 테스트 통과 (4/4)");
    end else begin
        $display("FAIL: %0d건 실패", fail_cnt);
    end

    #100;
    $finish;
end

endmodule
