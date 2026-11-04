// axil_regs 자체 점검 테스트벤치. 통과하면 "PASS", 실패하면 "FAIL"로 시작하는 줄을 출력한다.
// 구성: NREGS=3 (reg0, reg1 = RW, reg2 = RO), ADDR_W=4 → 주소 0x0, 0x4, 0x8 유효, 0xC는 범위 밖
`timescale 1ns/1ps
module tb_axil_regs;
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;

    reg  [3:0]  awaddr = 0;  reg awvalid = 0;  wire awready;
    reg  [31:0] wdata = 0;   reg [3:0] wstrb = 0;  reg wvalid = 0;  wire wready;
    wire [1:0]  bresp;       wire bvalid;      reg bready = 0;
    reg  [3:0]  araddr = 0;  reg arvalid = 0;  wire arready;
    wire [31:0] rdata;       wire [1:0] rresp; wire rvalid;  reg rready = 0;
    wire [95:0] reg_o;
    reg  [95:0] ro_i = 96'd0;

    axil_regs #(.ADDR_W(4), .NREGS(3), .RO_MASK(4)) dut (
        .clk(clk), .rst(rst),
        .s_awaddr(awaddr), .s_awvalid(awvalid), .s_awready(awready),
        .s_wdata(wdata), .s_wstrb(wstrb), .s_wvalid(wvalid), .s_wready(wready),
        .s_bresp(bresp), .s_bvalid(bvalid), .s_bready(bready),
        .s_araddr(araddr), .s_arvalid(arvalid), .s_arready(arready),
        .s_rdata(rdata), .s_rresp(rresp), .s_rvalid(rvalid), .s_rready(rready),
        .reg_o(reg_o), .ro_i(ro_i));

    integer errors = 0;
    integer checks = 0;
    reg [31:0] rd_data;
    reg [1:0]  rd_resp;
    reg [1:0]  wr_resp;

    task check(input cond, input [8*40-1:0] msg);
        begin
            checks = checks + 1;
            if (cond !== 1'b1) begin   // X/Z도 실패로 센다
                errors = errors + 1;
                $display("  불일치: %0s (t=%0t)", msg, $time);
            end
        end
    endtask

    // 쓰기: AW를 먼저 올리고 wdel 클럭 뒤에 W를 올린다. 응답은 bdel 클럭 뒤에 받는다.
    task wr_gen(input [3:0] a, input [31:0] d, input [3:0] st, input integer wdel, input integer bdel);
        integer k;
        begin
            @(negedge clk);
            awaddr = a; awvalid = 1; bready = 0;
            for (k = 0; k < wdel; k = k + 1) begin
                @(negedge clk);
                check(!awready, "W 전에는 awready가 낮아야 함");
                check(!bvalid,  "W 전에는 bvalid가 낮아야 함");
            end
            wdata = d; wstrb = st; wvalid = 1;
            @(posedge clk);
            while (!(awready && wready)) @(posedge clk);
            @(negedge clk);
            awvalid = 0; wvalid = 0;
            check(bvalid, "쓰기 뒤 bvalid가 올라야 함");
            wr_resp = bresp;
            for (k = 0; k < bdel; k = k + 1) begin
                @(negedge clk);
                check(bvalid, "bready 전까지 bvalid 유지");
            end
            bready = 1;
            @(posedge clk);
            @(negedge clk);
            bready = 0;
            check(!bvalid, "응답 소비 뒤 bvalid가 내려가야 함");
        end
    endtask

    task wr(input [3:0] a, input [31:0] d);
        begin wr_gen(a, d, 4'hF, 0, 0); end
    endtask

    // 읽기: rdel 클럭 동안 rready를 낮춰 두고 rdata가 유지되는지 본다.
    task rd_gen(input [3:0] a, input integer rdel);
        integer k;
        reg [31:0] first;
        begin
            @(negedge clk);
            araddr = a; arvalid = 1; rready = 0;
            @(posedge clk);
            while (!arready) @(posedge clk);
            @(negedge clk);
            arvalid = 0;
            check(rvalid, "읽기 뒤 rvalid가 올라야 함");
            first = rdata;
            for (k = 0; k < rdel; k = k + 1) begin
                @(negedge clk);
                check(rvalid && rdata == first, "rready 전까지 rdata 유지");
            end
            rd_data = rdata; rd_resp = rresp;
            rready = 1;
            @(posedge clk);
            @(negedge clk);
            rready = 0;
            check(!rvalid, "읽기 소비 뒤 rvalid가 내려가야 함");
        end
    endtask

    task rd(input [3:0] a);
        begin rd_gen(a, 0); end
    endtask

    initial begin
        #200000;
        $display("FAIL axil_regs: 시간 초과");
        $finish;
    end

    initial begin
        ro_i[63:32] = 32'h0;
        ro_i[95:64] = 32'hCAFE0002;
        repeat (3) @(negedge clk);
        rst = 0;
        repeat (2) @(negedge clk);

        // 1) 리셋 직후 RW는 0, RO는 ro_i
        rd(4'h0); check(rd_data == 32'h0 && rd_resp == 2'b00, "리셋 후 reg0 = 0");
        rd(4'h4); check(rd_data == 32'h0 && rd_resp == 2'b00, "리셋 후 reg1 = 0");
        rd(4'h8); check(rd_data == 32'hCAFE0002 && rd_resp == 2'b00, "RO reg2 = ro_i");

        // 2) 전체 바이트 쓰기와 읽기
        wr(4'h0, 32'hDEADBEEF); check(wr_resp == 2'b00, "쓰기 OKAY");
        rd(4'h0); check(rd_data == 32'hDEADBEEF, "reg0 쓰기 후 읽기");
        check(reg_o[31:0] == 32'hDEADBEEF, "reg_o[0]가 저장값과 같아야 함");

        // 3) 바이트 스트로브 (바이트 0, 2만 바뀜)
        wr_gen(4'h0, 32'h11223344, 4'b0101, 0, 0);
        rd(4'h0); check(rd_data == 32'hDE22BE44, "wstrb=0101 부분 쓰기");

        // 4) 다른 레지스터에 영향 없음
        wr(4'h4, 32'h00000001);
        rd(4'h0); check(rd_data == 32'hDE22BE44, "reg1 쓰기가 reg0을 바꾸지 않음");
        rd(4'h4); check(rd_data == 32'h00000001, "reg1 읽기");
        check(reg_o[63:32] == 32'h00000001, "reg_o[1]");

        // 5) RO 레지스터: 쓰기는 OKAY 후 무시, ro_i가 바뀌면 읽기 값도 바뀐다
        wr(4'h8, 32'hFFFFFFFF); check(wr_resp == 2'b00, "RO 쓰기도 OKAY");
        rd(4'h8); check(rd_data == 32'hCAFE0002, "RO 쓰기 무시");
        ro_i[95:64] = 32'h12345678;
        rd(4'h8); check(rd_data == 32'h12345678, "RO 값 갱신 반영");

        // 6) 범위 밖: SLVERR
        wr(4'hC, 32'h1); check(wr_resp == 2'b10, "범위 밖 쓰기는 SLVERR");
        rd(4'hC); check(rd_resp == 2'b10 && rd_data == 32'h0, "범위 밖 읽기는 SLVERR, 데이터 0");
        rd(4'h0); check(rd_data == 32'hDE22BE44, "범위 밖 접근이 상태를 바꾸지 않음");

        // 7) 지연된 W와 늦은 bready
        wr_gen(4'h4, 32'hA5A5A5A5, 4'hF, 3, 4);
        rd(4'h4); check(rd_data == 32'hA5A5A5A5, "지연 쓰기 반영");

        // 8) 늦은 rready에서도 rdata 유지
        rd_gen(4'h4, 3); check(rd_data == 32'hA5A5A5A5, "지연 읽기 값");

        // 9) 리셋이 저장값을 지운다
        @(negedge clk); rst = 1; @(negedge clk); @(negedge clk); rst = 0; @(negedge clk);
        rd(4'h0); check(rd_data == 32'h0, "리셋 후 reg0 = 0 (재확인)");
        rd(4'h4); check(rd_data == 32'h0, "리셋 후 reg1 = 0 (재확인)");

        if (errors == 0) $display("PASS axil_regs (%0d checks)", checks);
        else             $display("FAIL axil_regs (%0d errors / %0d checks)", errors, checks);
        $finish;
    end
endmodule
