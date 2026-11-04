// sensor_hub_top.v — 센서 허브 최상위: HC-SR04 + DHT11 + I2C Master MMIO 통합
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
//
// 레지스터 맵 (base 0x1002_0000):
//   0x00: HCSR04_CTRL  WO [0]=start
//   0x04: HCSR04_STATUS RO [0]=busy [1]=done [2]=timeout
//   0x08: HCSR04_DIST   RO [15:0]=cm
//   0x10: DHT11_CTRL   WO [0]=start
//   0x14: DHT11_STATUS  RO [0]=busy [1]=done [2]=chk_ok
//   0x18: DHT11_HUMID   RO [7:0]
//   0x1C: DHT11_TEMP    RO [7:0]
//   0x20: I2C_CMD      WO [0]=start [7:1]=dev_addr [15:8]=reg_addr
//   0x24: I2C_STATUS    RO [0]=busy [1]=done [2]=error
//   0x28: I2C_RDATA     RO [7:0]

`timescale 1ns/1ps
module sensor_hub_top (
    input  wire        clk,
    input  wire        rst_n,
    // MMIO-lite 슬레이브 인터페이스
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        sel,
    output reg  [31:0] rdata,
    // HC-SR04
    output wire        trig_o,
    input  wire        echo_i,
    // DHT11
    output wire        dht_oe,
    input  wire        dht_in,
    // I2C
    output wire        scl_oe,
    output wire        sda_oe,
    input  wire        sda_in
);

    // ---- HC-SR04 신호 ----
    wire        hc_start = sel && we && (addr[7:0] == 8'h00) && wdata[0];
    wire [15:0] hc_dist;
    wire        hc_busy, hc_done, hc_timeout;
    reg         hc_done_lat, hc_timeout_lat;

    // ---- DHT11 신호 ----
    wire        dht_start = sel && we && (addr[7:0] == 8'h10) && wdata[0];
    wire [7:0]  dht_humid, dht_temp;
    wire        dht_busy, dht_done, dht_chk;
    reg         dht_done_lat, dht_chk_lat;

    // ---- I2C 신호 ----
    wire        i2c_start = sel && we && (addr[7:0] == 8'h20) && wdata[0];
    wire [6:0]  i2c_addr  = wdata[7:1];
    wire [7:0]  i2c_reg   = wdata[15:8];
    wire [7:0]  i2c_rdata;
    wire        i2c_busy, i2c_done, i2c_error;
    reg         i2c_done_lat, i2c_error_lat;
    reg  [7:0]  i2c_rdata_lat;
    reg  [6:0]  i2c_addr_lat;
    reg  [7:0]  i2c_reg_lat;

    // I2C CMD 래치 (start 시에 addr/reg 저장)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c_addr_lat <= 7'd0;
            i2c_reg_lat  <= 8'd0;
        end else if (i2c_start) begin
            i2c_addr_lat <= wdata[7:1];
            i2c_reg_lat  <= wdata[15:8];
        end
    end

    // 완료 플래그 래치 (done 1-cycle 펄스 → 레지스터 유지)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hc_done_lat  <= 1'b0; hc_timeout_lat <= 1'b0;
            dht_done_lat <= 1'b0; dht_chk_lat    <= 1'b0;
            i2c_done_lat <= 1'b0; i2c_error_lat  <= 1'b0;
            i2c_rdata_lat<= 8'd0;
        end else begin
            if (hc_done)  begin hc_done_lat  <= 1'b1; hc_timeout_lat <= hc_timeout; end
            if (hc_start) begin hc_done_lat  <= 1'b0; hc_timeout_lat <= 1'b0; end
            if (dht_done) begin dht_done_lat <= 1'b1; dht_chk_lat    <= dht_chk; end
            if (dht_start)begin dht_done_lat <= 1'b0; end
            if (i2c_done) begin
                i2c_done_lat  <= 1'b1;
                i2c_error_lat <= i2c_error;
                i2c_rdata_lat <= i2c_rdata;
            end
            if (i2c_start) begin i2c_done_lat <= 1'b0; i2c_error_lat <= 1'b0; end
        end
    end

    // ---- 읽기 멀티플렉서 ----
    always @(*) begin
        rdata = 32'd0;
        if (sel) begin
            case (addr[7:0])
                8'h00: rdata = 32'd0;
                8'h04: rdata = {29'd0, hc_timeout_lat, hc_done_lat, hc_busy};
                8'h08: rdata = {16'd0, hc_dist};
                8'h10: rdata = 32'd0;
                8'h14: rdata = {29'd0, dht_chk_lat, dht_done_lat, dht_busy};
                8'h18: rdata = {24'd0, dht_humid};
                8'h1C: rdata = {24'd0, dht_temp};
                8'h20: rdata = 32'd0;
                8'h24: rdata = {29'd0, i2c_error_lat, i2c_done_lat, i2c_busy};
                8'h28: rdata = {24'd0, i2c_rdata_lat};
                default: rdata = 32'd0;
            endcase
        end
    end

    // ---- 서브모듈 인스턴스 ----
    hcsr04_ctrl u_hcsr04 (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (hc_start),
        .trig_o  (trig_o),
        .echo_i  (echo_i),
        .dist_cm (hc_dist),
        .busy    (hc_busy),
        .done    (hc_done),
        .timeout (hc_timeout)
    );

    dht11_ctrl u_dht11 (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (dht_start),
        .dht_oe     (dht_oe),
        .dht_in     (dht_in),
        .humidity   (dht_humid),
        .temperature(dht_temp),
        .busy       (dht_busy),
        .done       (dht_done),
        .chk_ok     (dht_chk)
    );

    i2c_master u_i2c (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (i2c_start),
        .dev_addr (i2c_addr_lat),
        .reg_addr (i2c_reg_lat),
        .scl_oe   (scl_oe),
        .sda_oe   (sda_oe),
        .sda_in   (sda_in),
        .rdata    (i2c_rdata),
        .busy     (i2c_busy),
        .done     (i2c_done),
        .error    (i2c_error)
    );

endmodule
