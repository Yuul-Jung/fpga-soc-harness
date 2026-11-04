// tb_dht11.v — DHT11 FSM 자체 점검 테스트벤치
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 테스트:
//   T1: 정상 40비트 수신 (습도 60%, 온도 25°C, 올바른 체크섬) → chk_ok=1
//   T2: 체크섬 오류 → chk_ok=0

`timescale 1ns/1ps
module tb_dht11;

    reg clk, rst_n, start;
    wire dht_oe;
    reg  dht_model;   // 모델이 DHT11을 흉내 냄
    wire dht_in = dht_oe ? 1'b0 : dht_model;  // oe=1이면 DUT가 low 구동

    wire [7:0] humidity, temperature;
    wire busy, done, chk_ok;

    dht11_ctrl #(
        .START_CYC   (1_800_000),
        .RELEASE_CYC (    50_000),
        .BIT_THRESH  (     4_000)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .dht_oe     (dht_oe),
        .dht_in     (dht_in),
        .humidity   (humidity),
        .temperature(temperature),
        .busy       (busy),
        .done       (done),
        .chk_ok     (chk_ok)
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

    // DHT11 프로토콜 모델: 40비트를 보낸다
    // bit_data[39:0]: MSB first
    task send_dht11_bits;
        input [39:0] bit_data;
        integer i;
        begin
            // 응답 Low 80 μs = 8000 cycles
            dht_model = 0;
            repeat(8000) @(posedge clk);
            // 응답 High 80 μs
            dht_model = 1;
            repeat(8000) @(posedge clk);

            for (i = 39; i >= 0; i = i - 1) begin
                // 비트 Low 50 μs = 5000 cycles
                dht_model = 0;
                repeat(5000) @(posedge clk);
                // 비트 High: 0 → 28 μs = 2800 cycles, 1 → 70 μs = 7000 cycles
                dht_model = 1;
                if (bit_data[i])
                    repeat(7000) @(posedge clk);
                else
                    repeat(2800) @(posedge clk);
            end
            dht_model = 0;
        end
    endtask

    // ---- T1: 올바른 데이터 ----
    // humid_int=60, humid_dec=0, temp_int=25, temp_dec=0, chk=85 (60+0+25+0=85)
    initial begin
        dht_model = 1;  // 풀업 상태
        rst_n = 0; start = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;

        // --- T1 ---
        @(posedge clk);
        start = 1; @(posedge clk); start = 0;

        // START_LOW(1,800,000) + RELEASE(50,000) 대기
        // DUT가 LOW를 내리는 동안 dht_model=1 유지
        wait(dht_oe === 1'b0);  // DUT가 release
        // 짧게 대기 후 응답 시작
        repeat(100) @(posedge clk);

        fork
            send_dht11_bits(40'h3C_00_19_00_55);
            // 60=0x3C, 0=0x00, 25=0x19, 0=0x00, chk=0x3C+0x00+0x19+0x00=0x55
        join

        wait(done === 1'b1);
        @(posedge clk);

        check_eq(humidity,    60, "T1_humidity");
        check_eq(temperature, 25, "T1_temperature");
        check_eq(chk_ok,       1, "T1_chk_ok");

        // --- T2: 체크섬 오류 ---
        dht_model = 1;
        @(posedge clk); @(posedge clk);
        start = 1; @(posedge clk); start = 0;

        wait(dht_oe === 1'b0);
        repeat(100) @(posedge clk);

        fork
            send_dht11_bits(40'h3C_00_19_00_AA); // chk 오류: 0xAA ≠ 0x55
        join

        wait(done === 1'b1);
        @(posedge clk);

        check_eq(chk_ok, 0, "T2_chk_error");

        if (fail == 0)
            $display("PASS tb_dht11: T1(normal) T2(checksum_err) all checks OK");
        else
            $display("FAIL tb_dht11: %0d check(s) failed", fail);

        $finish;
    end

    initial begin
        #600_000_000;
        $display("FAIL tb_dht11: simulation timeout");
        $finish;
    end

endmodule
