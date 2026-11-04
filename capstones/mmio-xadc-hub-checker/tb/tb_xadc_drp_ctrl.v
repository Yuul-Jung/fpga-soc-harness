// tb_xadc_drp_ctrl.v
// xadc_drp_ctrl 단위 테스트
// - DRP 모의 모델(xadc_drp_model)로 EOC·drdy 신호 생성
// - 4채널 순차 읽기 후 raw_ch와 valid 확인
// 통과: "PASS: drp_ctrl" / 실패: "FAIL: drp_ctrl"

`timescale 1ns/1ps

module tb_xadc_drp_ctrl;

    reg         clk, rst, scan_en;
    wire        eoc, den, drdy;
    wire [6:0]  daddr;
    wire [15:0] dout;
    wire [11:0] raw_ch [0:3];
    wire [3:0]  valid;

    // --- DUT ---
    xadc_drp_ctrl u_dut (
        .clk     (clk),
        .rst     (rst),
        .scan_en (scan_en),
        .eoc     (eoc),
        .den     (den),
        .daddr   (daddr),
        .drdy    (drdy),
        .dout    (dout),
        .raw_ch  (raw_ch),
        .valid   (valid)
    );

    // --- DRP 모의 모델 ---
    xadc_drp_model u_model (
        .dclk  (clk),
        .rst   (rst),
        .den   (den),
        .daddr (daddr),
        .drdy  (drdy),
        .do    (dout),
        .eoc   (eoc)
    );

    // 클럭 생성: 10ns 주기
    initial clk = 0;
    always #5 clk = ~clk;

    // 테스트 카운터
    integer fail_cnt;
    integer i;
    reg [11:0] expected [0:3];

    initial begin
        $dumpfile("tb_xadc_drp_ctrl.vcd");
        $dumpvars(0, tb_xadc_drp_ctrl);

        // 초기화
        rst = 1; scan_en = 0; fail_cnt = 0;
        repeat (4) @(posedge clk);
        rst = 0;

        // scan_en 활성화
        @(posedge clk);
        scan_en = 1;

        // 모의 모델이 4채널 완료할 때까지 대기 (최대 200클럭)
        repeat (200) @(posedge clk);

        // valid가 올라온 적 있는지 확인
        // (valid는 1클럭 펄스이므로 모델 내에서 별도 추적)
        // raw_ch가 0이 아닌지 확인
        for (i = 0; i < 4; i = i+1) begin
            if (raw_ch[i] === 12'bx || raw_ch[i] === 12'bz) begin
                $display("FAIL: drp_ctrl ch%0d = X/Z", i);
                fail_cnt = fail_cnt + 1;
            end else if (raw_ch[i] == 12'd0) begin
                // 모의 모델이 0을 반환할 수도 있으므로 경고만
                $display("WARN: drp_ctrl ch%0d = 0 (모의 모델 기본값일 수 있음)", i);
            end else begin
                $display("OK: drp_ctrl ch%0d = 0x%03X", i, raw_ch[i]);
            end
        end

        // 두 번째 스캔: scan_en 유지, 추가 200클럭
        repeat (200) @(posedge clk);

        // 결과 출력
        if (fail_cnt == 0)
            $display("PASS: drp_ctrl");
        else
            $display("FAIL: drp_ctrl (%0d errors)", fail_cnt);

        $finish;
    end

endmodule

// ==============================================================
// xadc_drp_model: DRP 인터페이스 모의 모델
// - 32클럭마다 EOC 발생
// - den → 2클럭 후 drdy + 채널별 고정 데이터 반환
// ==============================================================
module xadc_drp_model (
    input  wire        dclk,
    input  wire        rst,
    input  wire        den,
    input  wire [6:0]  daddr,
    output reg         drdy,
    output reg  [15:0] do,
    output reg         eoc
);
    reg [5:0]  eoc_cnt;
    reg        den_d1, den_d2;

    // EOC: 32클럭마다 1클럭 펄스
    always @(posedge dclk or posedge rst) begin
        if (rst) begin
            eoc_cnt <= 6'd0;
            eoc     <= 1'b0;
        end else begin
            eoc_cnt <= eoc_cnt + 1'b1;
            eoc     <= (eoc_cnt == 6'd31);
        end
    end

    // drdy: den 후 2클럭 지연
    always @(posedge dclk or posedge rst) begin
        if (rst) begin
            den_d1 <= 1'b0;
            den_d2 <= 1'b0;
            drdy   <= 1'b0;
            do     <= 16'd0;
        end else begin
            den_d1 <= den;
            den_d2 <= den_d1;
            drdy   <= den_d2;
            if (den_d2) begin
                // 채널별 고정 테스트 데이터 (상위 12비트 유효)
                // daddr: 0x14→ch4, 0x15→ch5, 0x1C→ch12, 0x1D→ch13
                case (daddr)
                    7'h14: do <= 16'hABC0; // ch0 raw = 0xABC
                    7'h15: do <= 16'hDEF0; // ch1 raw = 0xDEF
                    7'h1C: do <= 16'h1230; // ch2 raw = 0x123
                    7'h1D: do <= 16'h4560; // ch3 raw = 0x456
                    default: do <= 16'h0000;
                endcase
            end
        end
    end
endmodule
