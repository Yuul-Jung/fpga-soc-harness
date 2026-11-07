// tb_can_fd_rx.v — axil_can_fd_rx 비트-레벨 주입 테스트벤치
// 자체 점검형: PASS/FAIL로 시작하는 줄 출력
// 프레임: ID=0x555(10101010101b), DLC=4(0100b, DUT계산=2바이트)
//   DATA0=0x55(01010101), DATA1[7:1]=1010101 + DATA1[0]=tb_crc[14]
//   스터프 비트 없음 (DLC[2]=1이 연속 0 런을 끊음)
//   CRC는 Verilog 함수로 동적 계산
// CLK_PER_BIT=20, SAMPLE_PT=15 으로 빠른 시뮬레이션
`timescale 1ns/1ps

module tb_can_fd_rx;

    localparam CLK_PER_BIT = 20;
    localparam SAMPLE_PT   = 15;
    localparam DATA_W      = 32;
    localparam ADDR_W      = 6;

    // ---------------------------------------------------------------
    // 클럭·신호
    // ---------------------------------------------------------------
    reg         clk;
    reg         aresetn;
    reg         can_rx;

    // AXI4-Lite 슬레이브 포트 (TB가 마스터)
    reg  [5:0]  s_araddr;
    reg         s_arvalid;
    wire        s_arready;
    wire [31:0] s_rdata;
    wire [1:0]  s_rresp;
    wire        s_rvalid;
    reg         s_rready;

    reg  [5:0]  s_awaddr;
    reg         s_awvalid;
    wire        s_awready;
    reg  [31:0] s_wdata;
    reg  [3:0]  s_wstrb;
    reg         s_wvalid;
    wire        s_wready;
    wire [1:0]  s_bresp;
    wire        s_bvalid;
    reg         s_bready;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    axil_can_fd_rx #(
        .DATA_W      (DATA_W),
        .ADDR_W      (ADDR_W),
        .CLK_PER_BIT (CLK_PER_BIT),
        .SAMPLE_PT   (SAMPLE_PT)
    ) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (aresetn),
        .s_axi_awaddr  (s_awaddr),
        .s_axi_awvalid (s_awvalid),
        .s_axi_awready (s_awready),
        .s_axi_wdata   (s_wdata),
        .s_axi_wstrb   (s_wstrb),
        .s_axi_wvalid  (s_wvalid),
        .s_axi_wready  (s_wready),
        .s_axi_bresp   (s_bresp),
        .s_axi_bvalid  (s_bvalid),
        .s_axi_bready  (s_bready),
        .s_axi_araddr  (s_araddr),
        .s_axi_arvalid (s_arvalid),
        .s_axi_arready (s_arready),
        .s_axi_rdata   (s_rdata),
        .s_axi_rresp   (s_rresp),
        .s_axi_rvalid  (s_rvalid),
        .s_axi_rready  (s_rready),
        .can_rx        (can_rx)
    );

    // ---------------------------------------------------------------
    // 클럭 생성 (2ns 주기 = 500 MHz; CLK_PER_BIT=20이면 비트당 40ns)
    // ---------------------------------------------------------------
    initial clk = 0;
    always #1 clk = ~clk;

    // ---------------------------------------------------------------
    // CRC-15 계산 함수 (다항식 0x4599)
    // ---------------------------------------------------------------
    reg [14:0] tb_crc;

    function [14:0] crc_next;
        input [14:0] crc_in;
        input        bit_in;
        reg crc_b;
        begin
            crc_b    = bit_in ^ crc_in[14];
            crc_next = {crc_in[13:0], 1'b0} ^ (crc_b ? 15'h4599 : 15'd0);
        end
    endfunction

    // ---------------------------------------------------------------
    // 비트 송신 태스크
    //   val    : 보낼 비트값 (0=도미넌트, 1=리세시브)
    //   do_crc : 1이면 tb_crc 갱신
    // ---------------------------------------------------------------
    task send_bit;
        input val;
        input do_crc;
        begin
            can_rx = val;
            if (do_crc) tb_crc = crc_next(tb_crc, val);
            repeat(CLK_PER_BIT) @(posedge clk);
        end
    endtask

    // ---------------------------------------------------------------
    // AXI4-Lite 읽기 태스크
    // ---------------------------------------------------------------
    task axi_read;
        input  [5:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk);
            s_araddr  = addr;
            s_arvalid = 1'b1;
            @(posedge clk);
            while (!s_arready) @(posedge clk);
            s_arvalid = 1'b0;
            s_rready  = 1'b1;
            while (!s_rvalid) @(posedge clk);
            rdata    = s_rdata;
            @(posedge clk);
            s_rready = 1'b0;
        end
    endtask

    // ---------------------------------------------------------------
    // 메인 시나리오
    // ---------------------------------------------------------------
    integer i;
    integer errors;
    reg [31:0] rd_val;
    reg        dlc0_bit;   // DATA1[0] = tb_crc[14] (S_CRC fidx=0)

    initial begin
        // 초기값
        clk      = 0;
        aresetn  = 0;
        can_rx   = 1'b1;   // 아이들 (리세시브)
        tb_crc   = 15'd0;
        errors   = 0;
        s_arvalid = 0; s_rready  = 0;
        s_awaddr  = 0; s_awvalid = 0;
        s_wdata   = 0; s_wstrb   = 4'hF; s_wvalid = 0;
        s_bready  = 1; s_araddr  = 0;

        // ── 리셋 해제 ──────────────────────────────────────────
        repeat(10) @(posedge clk);
        aresetn = 1;
        repeat(15) @(posedge clk);

        // ── CAN 프레임 전송 ─────────────────────────────────────
        // 아이들 유지 (DUT가 S_IDLE/재동기화 완료 대기)
        repeat(5) @(posedge clk);

        // ★ SOF (도미넌트=0 → 하강 에지)
        send_bit(0, 1);     // SOF

        // ★ ID[10:0] = 10101010101b (대체 비트, 스터프 없음)
        send_bit(1, 1);     // ID[10]
        send_bit(0, 1);     // ID[9]
        send_bit(1, 1);     // ID[8]
        send_bit(0, 1);     // ID[7]
        send_bit(1, 1);     // ID[6]
        send_bit(0, 1);     // ID[5]
        send_bit(1, 1);     // ID[4]
        send_bit(0, 1);     // ID[3]
        send_bit(1, 1);     // ID[2]
        send_bit(0, 1);     // ID[1]
        send_bit(1, 1);     // ID[0]

        // ★ CTRL: RTR=0, IDE=0, r0=0, DLC[3:1]=010
        //   DLC=0100b → DLC[2]=1이 4연속 0 런(RTR+IDE+r0+DLC[3])을 끊음
        //   DUT의 d2b({r0=0,DLC[3]=0,DLC[2]=1,DLC[1]=0})=d2b(2)=2바이트
        send_bit(0, 1);     // RTR
        send_bit(0, 1);     // IDE
        send_bit(0, 1);     // r0
        send_bit(0, 1);     // DLC[3]
        send_bit(1, 1);     // DLC[2]  ← 연속 0 런 차단
        send_bit(0, 1);     // DLC[1]  → S_DATA 진입 (rx_dmax=16)

        // ★ S_DATA (16비트): DLC[0] + DATA0[7:0] + DATA1[7:1]
        //   DLC[0]=0, DATA0=0x55(01010101), DATA1[7:1]=1010101 (0xAA 상위7비트)
        //   최대 연속 동일 비트 = 3 (스터프 없음)
        send_bit(0, 1);     // DLC[0]  = S_DATA bit0
        // DATA0 = 0x55 (MSB 먼저)
        send_bit(0, 1);     // DATA0[7]
        send_bit(1, 1);     // DATA0[6]
        send_bit(0, 1);     // DATA0[5]
        send_bit(1, 1);     // DATA0[4]
        send_bit(0, 1);     // DATA0[3]
        send_bit(1, 1);     // DATA0[2]
        send_bit(0, 1);     // DATA0[1]
        send_bit(1, 1);     // DATA0[0]
        // DATA1[7:1] (0xAA = 10101010b 상위 7비트 = 1010101)
        send_bit(1, 1);     // DATA1[7]
        send_bit(0, 1);     // DATA1[6]
        send_bit(1, 1);     // DATA1[5]
        send_bit(0, 1);     // DATA1[4]
        send_bit(1, 1);     // DATA1[3]
        send_bit(0, 1);     // DATA1[2]
        send_bit(1, 1);     // DATA1[1]
        // S_DATA 종료 (16번째 비트). 이제 tb_crc = CRC over 34비트

        // ★ S_CRC fidx=0: DATA1[0] = tb_crc[14]
        //   (rx_crc[14] must == crc_r[14])
        dlc0_bit = tb_crc[14];
        send_bit(dlc0_bit, 0);   // S_CRC fidx=0

        // ★ S_CRC fidx=1..14: CRC 필드 [14:1] = tb_crc[13:0]
        for (i = 13; i >= 0; i = i - 1)
            send_bit(tb_crc[i], 0);

        // ★ S_CDELIM: CRC_wire[0] = 1 (리세시브, CRC 구분자)
        send_bit(1, 0);

        // ★ ACK: 도미넌트 슬롯 + 리세시브 구분자
        send_bit(0, 0);     // ACK 슬롯
        send_bit(1, 0);     // ACK 구분자

        // ★ EOF + IFS: 15개 리세시브 비트
        //   EOF 7비트 + IFS 3비트 → 스터프 처리로 추가 비트 필요.
        //   ACK 구분자 이후 연속 1 런: 비트4(5번째)가 스터프됨.
        //   15비트면 DUT가 EOF(eof_c=6)와 IFS(ifs_c=2) 완료에 충분.
        repeat(15) send_bit(1, 0);

        // 아이들 복귀 후 충분히 대기
        can_rx = 1'b1;
        repeat(60) @(posedge clk);

        // ── AXI STATUS 읽기 ─────────────────────────────────────
        axi_read(6'h00, rd_val);
        if (rd_val[0] !== 1'b1) begin
            $display("FAIL: STATUS=0x%08h, VALID(bit0) expected 1", rd_val);
            errors = errors + 1;
        end

        // ── FRAME_ID 확인 (0x10 = 11'h555 → {21'h0, 11'h555})
        axi_read(6'h10, rd_val);
        if (rd_val[10:0] !== 11'h555) begin
            $display("FAIL: FRAME_ID=0x%03h, expected 0x555", rd_val[10:0]);
            errors = errors + 1;
        end

        // ── 최종 결과 ─────────────────────────────────────────
        if (errors === 0)
            $display("PASS: STATUS=VALID, FRAME_ID=0x555");
        else
            $display("FAIL: %0d error(s)", errors);

        $finish;
    end

    // ── 타임아웃 ──────────────────────────────────────────────────
    initial begin
        // SOF + 11ID + 6CTRL + 16DATA + 1+15CRC + 1CDELIM + 2ACK + 15EOF_IFS
        // = ~70 비트 × CLK_PER_BIT + 오버헤드 여유
        #(CLK_PER_BIT * 200 * 2 + 1000);
        $display("FAIL: timeout");
        $finish;
    end

endmodule
