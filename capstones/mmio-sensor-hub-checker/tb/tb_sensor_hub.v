// tb_sensor_hub.v — sensor_hub_top 통합 자체 점검 테스트벤치
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 테스트:
//   T1: HC-SR04 start → 에코 모델 → dist_cm 레지스터 확인
//   T2: DHT11 start → 40비트 모델 → humid/temp 레지스터 확인
//   T3: I2C start → ACK 모델 → rdata 레지스터 확인

`timescale 1ns/1ps
module tb_sensor_hub;

    reg clk, rst_n;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg        we, sel;
    wire [31:0] rdata;

    wire trig_o, dht_oe, scl_oe, sda_oe;

    // 에코/DHT/SDA 모델 신호
    reg echo_model, dht_model, sda_model;
    wire echo_i  = echo_model;
    wire dht_in  = dht_oe ? 1'b0 : dht_model;  // oe=1 → DUT forces low
    wire sda_in  = (~sda_oe) & sda_model;

    sensor_hub_top dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .addr    (addr),
        .wdata   (wdata),
        .we      (we),
        .sel     (sel),
        .rdata   (rdata),
        .trig_o  (trig_o),
        .echo_i  (echo_i),
        .dht_oe  (dht_oe),
        .dht_in  (dht_in),
        .scl_oe  (scl_oe),
        .sda_oe  (sda_oe),
        .sda_in  (sda_in)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    // MMIO 쓰기
    task mmio_write;
        input [31:0] a, d;
        begin
            @(posedge clk);
            addr = a; wdata = d; we = 1'b1; sel = 1'b1;
            @(posedge clk);
            we = 1'b0; sel = 1'b0;
        end
    endtask

    // MMIO 읽기
    task mmio_read;
        input [31:0] a;
        output [31:0] d;
        begin
            @(posedge clk);
            addr = a; we = 1'b0; sel = 1'b1;
            @(posedge clk);
            d = rdata;
            sel = 1'b0;
        end
    endtask

    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] tag;
        begin
            if (got !== exp) begin
                $display("FAIL %s: got=0x%08X exp=0x%08X", tag, got, exp);
                fail = fail + 1;
            end
        end
    endtask

    reg [31:0] rdval;

    // ---- HC-SR04 모델 ----
    // start 직후 trig_o 상승 감지, 1200 cycles 뒤 에코 2000 cycles 보냄
    // dist = 2000000/5800 ≈ 344 (10 μs 트리거 후 20 ms 에코 = 344 cm)
    // 단, TRIG_CYC=1000이므로 trig_o 뒤 1200 cycles 대기 후 echo_i=1
    // 실제: 2000 cycles echo → dist = 2000/5800 = 0 (너무 짧음)
    // 의미 있는 테스트: echo 175000 cycles → 30 cm
    task hcsr04_model;
        begin
            wait(trig_o === 1'b1);
            wait(trig_o === 1'b0);
            repeat(50) @(posedge clk);  // 대기
            echo_model = 1'b1;
            repeat(175000) @(posedge clk);
            echo_model = 1'b0;
        end
    endtask

    // ---- DHT11 모델 ----
    // humid=60(0x3C), temp=25(0x19), chk=0x55
    task dht11_model;
        reg [39:0] data;
        integer i;
        begin
            data = 40'h3C_00_19_00_55;
            wait(dht_oe === 1'b0);  // DUT가 release
            repeat(100) @(posedge clk);
            dht_model = 1'b0;
            repeat(8000) @(posedge clk);  // 응답 Low 80 μs
            dht_model = 1'b1;
            repeat(8000) @(posedge clk);  // 응답 High 80 μs
            for (i = 39; i >= 0; i = i - 1) begin
                dht_model = 1'b0;
                repeat(5000) @(posedge clk);
                dht_model = 1'b1;
                if (data[i])
                    repeat(7000) @(posedge clk);
                else
                    repeat(2800) @(posedge clk);
            end
            dht_model = 1'b0;
        end
    endtask

    // ---- I2C 슬레이브 모델 (간단 ACK + 0xAB) ----
    reg prev_scl_b;
    reg [3:0] bit_b;
    reg [1:0] bphase_b;
    reg       in_data_b;

    wire scl_bus = ~scl_oe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_scl_b <= 1'b1; bit_b <= 0; bphase_b <= 0;
            sda_model  <= 1'b1; in_data_b <= 0;
        end else begin
            prev_scl_b <= scl_bus;
            if (!prev_scl_b && scl_bus) begin
                if (bit_b == 4'd8) begin
                    if (in_data_b) sda_model <= 1'b1;
                    else           sda_model <= 1'b0;
                    bit_b <= 0;
                    if (!in_data_b) bphase_b <= bphase_b + 1'b1;
                    if (bphase_b == 2'd2) in_data_b <= 1'b1;
                end else begin
                    if (in_data_b)
                        sda_model <= (8'hAB >> (7 - bit_b)) & 1'b1;
                    else
                        sda_model <= 1'b1;
                    bit_b <= bit_b + 1'b1;
                end
            end else if (prev_scl_b && !scl_bus) begin
                if (bit_b == 0 && !in_data_b) sda_model <= 1'b1;
            end
        end
    end

    // ---- 메인 테스트 ----
    initial begin
        rst_n      = 0; we = 0; sel = 0;
        addr       = 0; wdata = 0;
        echo_model = 0; dht_model = 1; sda_model = 1;
        @(posedge clk); @(posedge clk);
        rst_n = 1;

        // ---- T1: HC-SR04 ----
        fork
            hcsr04_model;
            mmio_write(32'h1002_0000, 32'h1); // HCSR04_CTRL start
        join

        // 완료 대기
        begin : wait_hc
            integer i;
            for (i = 0; i < 50; i = i + 1) begin
                mmio_read(32'h1002_0004, rdval);
                if (rdval[1]) disable wait_hc;
                repeat(100) @(posedge clk);
            end
        end

        mmio_read(32'h1002_0008, rdval);
        check_eq(rdval[15:0], 16'd30, "T1_hcsr04_30cm");

        // ---- T2: DHT11 ----
        fork
            dht11_model;
            mmio_write(32'h1002_0010, 32'h1); // DHT11_CTRL start
        join

        begin : wait_dht
            integer j;
            for (j = 0; j < 100; j = j + 1) begin
                mmio_read(32'h1002_0014, rdval);
                if (rdval[1]) disable wait_dht;
                repeat(10000) @(posedge clk);
            end
        end

        mmio_read(32'h1002_0018, rdval);
        check_eq(rdval[7:0], 8'd60, "T2_dht11_humid");
        mmio_read(32'h1002_001C, rdval);
        check_eq(rdval[7:0], 8'd25, "T2_dht11_temp");
        mmio_read(32'h1002_0014, rdval);
        check_eq(rdval[2], 1'b1,   "T2_dht11_chk_ok");

        // ---- T3: I2C ----
        // I2C_CMD: [0]=start, [7:1]=0x68=0b110_1000 → wdata[7:1]=0x68
        // wdata = {reg_addr(0x3B)[15:8], dev_addr(0x68)[7:1], start[0]}
        //       = 0x00_3B_D1 → wdata = 32'h003B_D1
        // 실제: wdata[7:1] = 7'h68, wdata[0]=1, wdata[15:8]=8'h3B
        mmio_write(32'h1002_0020, 32'h003B_D1); // I2C_CMD

        begin : wait_i2c
            integer k;
            for (k = 0; k < 200; k = k + 1) begin
                mmio_read(32'h1002_0024, rdval);
                if (rdval[1]) disable wait_i2c;
                repeat(1000) @(posedge clk);
            end
        end

        mmio_read(32'h1002_0028, rdval);
        check_eq(rdval[7:0], 8'hAB, "T3_i2c_rdata");
        mmio_read(32'h1002_0024, rdval);
        check_eq(rdval[2], 1'b0,   "T3_i2c_no_error");

        if (fail == 0)
            $display("PASS tb_sensor_hub: T1(HC-SR04) T2(DHT11) T3(I2C) all checks OK");
        else
            $display("FAIL tb_sensor_hub: %0d check(s) failed", fail);

        $finish;
    end

    initial begin
        #800_000_000;
        $display("FAIL tb_sensor_hub: simulation timeout");
        $finish;
    end

endmodule
