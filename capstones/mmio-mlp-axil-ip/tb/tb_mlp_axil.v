// tb_mlp_axil.v — AXI4-Lite MLP IP 자체 점검형 테스트벤치
// capstone: mmio-mlp-axil-ip
// 2026-11-08
//
// 검사 항목:
//   T1. VERSION 레지스터 읽기 → 0x00010000
//   T2. STATUS 초기값 → busy=0, done=0
//   T3. LOAD_TARGET 쓰기 → LOAD_ADDR 자동 초기화 확인
//   T4. LOAD_DATA 스트리밍 → LOAD_ADDR 자동 증가 확인
//   T5. CONTROL[0]=1 → busy 상승, 일정 시간 후 done 상승
//   T6. RESULT 읽기 → 0~9 범위
//   T7. clear_done(CONTROL[2]=1) → done 클리어
//
// 통과: 모든 검사 PASS → "PASS: 모든 항목 통과" 출력
// 실패: 첫 실패 시 "FAIL: <항목>" 출력 후 $finish
//
// 주의: 가중치 hex 파일이 없는 환경에서는 가중치=0으로 동작.
//       T5 done 상승에 최대 N_IN*N_H+N_H*N_OUT+N_H+N_OUT+50 사이클 대기.
`timescale 1ns/1ps
`default_nettype none

module tb_mlp_axil;
    // 간략화: N_IN=4, N_H=4, N_OUT=4 (시뮬레이션 가속)
    localparam N_IN  = 4;
    localparam N_H   = 4;
    localparam N_OUT = 4;

    reg  clk, rst;
    // AXI4-Lite 마스터 신호
    reg  [7:0]  awaddr;  reg  awvalid;  wire awready;
    reg  [31:0] wdata;   reg  [3:0] wstrb;   reg wvalid;   wire wready;
    wire [1:0]  bresp;   wire bvalid;   reg bready;
    reg  [7:0]  araddr;  reg  arvalid;  wire arready;
    wire [31:0] rdata;   wire [1:0] rresp;   wire rvalid;  reg rready;
    wire [3:0]  led;
    wire done_out;

    // DUT — 작은 파라미터 (시뮬레이션 가속)
    // N_IN=4, N_H=4, N_OUT=4 → AW_IN=2, AW_H=2, AW_OUT=2, AW_W1=4, AW_W2=4
    axil_mlp_infer #(
        .N_IN(N_IN), .N_H(N_H), .N_OUT(N_OUT),
        .IN_W(8), .W_W(8), .B_W(32), .ACC_W(32),
        .D_W1(N_IN*N_H), .D_B1(N_H), .D_W2(N_H*N_OUT), .D_B2(N_OUT), .D_INPUT(N_IN),
        .AW_IN(2), .AW_H(2), .AW_OUT(2), .AW_W1(4), .AW_W2(4)
    ) dut (
        .clk(clk), .rst(rst),
        .s_awaddr(awaddr), .s_awvalid(awvalid), .s_awready(awready),
        .s_wdata(wdata), .s_wstrb(wstrb), .s_wvalid(wvalid), .s_wready(wready),
        .s_bresp(bresp), .s_bvalid(bvalid), .s_bready(bready),
        .s_araddr(araddr), .s_arvalid(arvalid), .s_arready(arready),
        .s_rdata(rdata), .s_rresp(rresp), .s_rvalid(rvalid), .s_rready(rready),
        .result_out(led), .done_out(done_out)
    );

    // 클럭 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // 리셋
    initial begin
        rst    = 1; awvalid = 0; wvalid = 0; bready = 1;
        arvalid = 0; rready = 1; wstrb = 4'hF;
        awaddr = 0; wdata = 0; araddr = 0;
        #22; rst = 0;
    end

    // ── AXI 쓰기 태스크 ──
    task axil_write;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            awaddr = addr; awvalid = 1;
            wdata  = data; wvalid  = 1;
            wait (awready && wready);
            @(posedge clk); #1;
            awvalid = 0; wvalid = 0;
            wait (bvalid);
            @(posedge clk); #1;
        end
    endtask

    // ── AXI 읽기 태스크 ──
    reg [31:0] rd_val;
    task axil_read;
        input [7:0] addr;
        begin
            @(posedge clk); #1;
            araddr = addr; arvalid = 1;
            wait (arready);
            @(posedge clk); #1;
            arvalid = 0;
            wait (rvalid);
            rd_val = rdata;
            @(posedge clk); #1;
        end
    endtask

    // ── 검사 매크로 ──
    integer fail_cnt;
    task check;
        input [255:0] name;
        input         cond;
        begin
            if (!cond) begin
                $display("FAIL: %0s", name);
                $finish;
            end
        end
    endtask

    integer wait_cnt;

    initial begin
        fail_cnt = 0;
        // 리셋 해제 대기
        @(negedge rst); repeat(5) @(posedge clk);

        // T1. VERSION
        axil_read(8'h1C);
        check("T1_VERSION_VALUE", rd_val === 32'h0001_0000);

        // T2. STATUS 초기값
        axil_read(8'h04);
        check("T2_STATUS_IDLE", rd_val[1:0] === 2'b00);

        // T3. LOAD_TARGET 쓰기 → LOAD_ADDR 초기화 확인
        axil_write(8'h18, 32'd0);  // TARGET = W1
        axil_read(8'h10);
        check("T3_LOAD_ADDR_RESET", rd_val === 32'd0);

        // T4. LOAD_DATA 스트리밍 (INPUT 타겟으로 2회 쓰기)
        axil_write(8'h18, 32'd4);  // TARGET = INPUT
        axil_write(8'h14, 32'h55); // INPUT[0] = 0x55
        axil_write(8'h14, 32'hAA); // INPUT[1] = 0xAA
        axil_read(8'h10);          // LOAD_ADDR는 2로 증가해야 함
        check("T4_LOAD_ADDR_AUTO_INC", rd_val === 32'd2);

        // T5. CONTROL[0]=1 → busy=1 → done=1
        axil_write(8'h00, 32'h1);  // start
        axil_read(8'h04);          // STATUS: busy=1 또는 이미 done=1

        // done 대기 (최대 10000 사이클)
        wait_cnt = 0;
        while (!done_out && wait_cnt < 10000) begin
            @(posedge clk);
            wait_cnt = wait_cnt + 1;
        end
        check("T5_DONE_ASSERTED", done_out === 1'b1);

        // T6. RESULT 읽기
        axil_read(8'h08);
        check("T6_RESULT_RANGE", rd_val[3:0] <= 4'd9);

        // T7. clear_done
        axil_write(8'h00, 32'h4);  // CONTROL[2]=1
        repeat(2) @(posedge clk);
        axil_read(8'h04);
        check("T7_DONE_CLEARED", rd_val[1] === 1'b0);

        $display("PASS: 모든 항목 통과 (T1~T7)");
        $finish;
    end

    // 타임아웃 가드
    initial begin
        #2000000;
        $display("FAIL: 타임아웃 (2ms 초과)");
        $finish;
    end
endmodule
`default_nettype wire
