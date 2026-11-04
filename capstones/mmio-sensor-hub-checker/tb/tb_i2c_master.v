// tb_i2c_master.v — I2C 마스터 FSM 자체 점검 테스트벤치
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 테스트:
//   T1: MPU-6050(0x68) 레지스터 0x3B 읽기, 슬레이브가 0xAB로 응답 → rdata=0xAB, error=0
//   T2: 슬레이브 NACK → error=1

`timescale 1ns/1ps
module tb_i2c_master;

    reg clk, rst_n, start;
    reg [6:0] dev_addr;
    reg [7:0] reg_addr;
    wire       scl_oe, sda_oe;
    wire       scl = ~scl_oe;  // open-drain: oe=1→0, oe=0→1
    // SDA: DUT가 sda_oe=1이면 0, 슬레이브도 연결
    reg        slave_sda;      // 슬레이브 출력
    wire       sda_bus = (~sda_oe) & slave_sda;  // wired-AND
    wire       sda_in = sda_bus;

    wire [7:0] rdata;
    wire       busy, done, error;

    i2c_master #(
        .CLK_DIV(125)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .dev_addr (dev_addr),
        .reg_addr (reg_addr),
        .scl_oe   (scl_oe),
        .sda_oe   (sda_oe),
        .sda_in   (sda_in),
        .rdata    (rdata),
        .busy     (busy),
        .done     (done),
        .error    (error)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] tag;
        begin
            if (got !== exp) begin
                $display("FAIL %s: got=%0d exp=%0d", tag, got, exp);
                fail = fail + 1;
            end
        end
    endtask

    // 슬레이브 모델: I2C 비트 스트림을 ACK/NACK 패턴으로 처리
    // 간단 모델: SCL 상승 엣지를 세어 ACK 위치에서 SDA를 내린다
    // T1: 모든 ACK=0 (ACK), 데이터 바이트 0xAB
    // T2: 첫 번째 ACK=1 (NACK)
    reg [7:0]  slave_data;   // 슬레이브가 보낼 바이트
    reg        slave_nack;   // T2용

    integer scl_edge_cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            slave_sda     <= 1'b1;
            scl_edge_cnt  <= 0;
        end else begin
            // SCL 상승 엣지 감지 (DUT가 SCL 해제 = scl_oe=0)
        end
    end

    // 슬레이브 비트 스트림 모델
    // SCL high 구간마다 비트를 세어, ACK 위치(9번째 비트)에 반응
    reg prev_scl;
    reg [3:0] bit_in_byte;
    reg [1:0] byte_phase;   // 0=ADDR_W, 1=REG, 2=ADDR_R, 3=DATA
    reg [7:0] data_shift;
    reg       in_data_phase;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_scl     <= 1'b1;
            bit_in_byte  <= 4'd0;
            byte_phase   <= 2'd0;
            slave_sda    <= 1'b1;
            data_shift   <= 8'd0;
            in_data_phase<= 1'b0;
        end else begin
            prev_scl <= scl;

            if (!prev_scl && scl) begin
                // SCL 상승 엣지
                if (bit_in_byte == 4'd8) begin
                    // ACK 위치
                    if (slave_nack && byte_phase == 2'd0)
                        slave_sda <= 1'b1;  // NACK
                    else if (in_data_phase)
                        slave_sda <= 1'b1;  // 데이터 후 NACK(마스터가 보냄)이므로 여기서 high
                    else
                        slave_sda <= 1'b0;  // ACK
                    bit_in_byte <= 4'd0;
                    if (!in_data_phase) byte_phase <= byte_phase + 1'b1;
                    if (byte_phase == 2'd2) in_data_phase <= 1'b1;
                end else begin
                    if (in_data_phase) begin
                        // 데이터 출력: MSB first
                        slave_sda  <= slave_data[7 - bit_in_byte];
                    end else begin
                        slave_sda <= 1'b1;  // 입력 비트는 1(high-Z)
                    end
                    bit_in_byte <= bit_in_byte + 1'b1;
                end
            end else if (prev_scl && !scl) begin
                // SCL 하강 후 ACK 해제
                if (bit_in_byte == 4'd0 && !in_data_phase)
                    slave_sda <= 1'b1;
            end
        end
    end

    // ---- T1: ACK, 슬레이브 데이터 0xAB ----
    initial begin
        rst_n = 0; start = 0;
        dev_addr   = 7'h68;
        reg_addr   = 8'h3B;
        slave_data = 8'hAB;
        slave_nack = 1'b0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;

        @(posedge clk);
        start = 1; @(posedge clk); start = 0;

        wait(done === 1'b1);
        @(posedge clk);

        check_eq(rdata, 8'hAB, "T1_rdata");
        check_eq(error, 0,      "T1_no_error");

        // ---- T2: NACK ----
        rst_n = 0;
        @(posedge clk); @(posedge clk);
        rst_n      = 1;
        slave_nack = 1'b1;
        slave_sda  = 1'b1;
        bit_in_byte = 0; byte_phase = 0; in_data_phase = 0;

        @(posedge clk);
        start = 1; @(posedge clk); start = 0;

        wait(done === 1'b1);
        @(posedge clk);

        check_eq(error, 1, "T2_error_on_nack");

        if (fail == 0)
            $display("PASS tb_i2c_master: T1(ACK+data) T2(NACK) all checks OK");
        else
            $display("FAIL tb_i2c_master: %0d check(s) failed", fail);

        $finish;
    end

    initial begin
        #10_000_000;
        $display("FAIL tb_i2c_master: simulation timeout");
        $finish;
    end

endmodule
