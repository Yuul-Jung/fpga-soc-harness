// i2c_slave_ns.v — I2C 슬레이브 FSM (클럭 스트레칭 없음)
// RPi BCM I2C 호환: SCL 스트레칭 없이 단일 SCL 사이클 이내에 ACK/데이터 준비.
// 7비트 슬레이브 주소(기본 0x20), 최대 8개 8비트 레지스터 R/W.
// Verilog-2001 / iverilog / verilator / yosys 호환.
// SPDX-License-Identifier: MIT
// 하네스 원본 (capstones/mmio-i2c-slave-ns-ip)

`timescale 1ns/1ps

module i2c_slave_ns #(
    parameter SLAVE_ADDR = 7'h20   // 7비트 슬레이브 주소
) (
    input  wire       clk,          // 100 MHz 시스템 클럭
    input  wire       rst,          // active-high 동기 리셋

    // I2C 핀 (동기화 후)
    input  wire       scl_in,       // 동기화된 SCL 입력
    input  wire       sda_in,       // 동기화된 SDA 입력
    output reg        sda_oe,       // SDA 출력 인에이블 (1=pull-down, 0=Hi-Z)

    // 레지스터 인터페이스 (axil_i2c_slave_ns 연결)
    input  wire [7:0] reg_wdata,    // AXI→레지스터 쓰기 데이터
    input  wire [2:0] reg_waddr,    // AXI→레지스터 쓰기 주소
    input  wire       reg_we,       // AXI 쓰기 인에이블
    output reg  [7:0] reg_rdata,    // I2C 읽기 데이터 출력 (등록)
    input  wire [2:0] reg_raddr,    // AXI 레지스터 읽기 주소 (레지스터 파일 프록시)
    output wire [7:0] reg_proxy,    // AXI 읽기용 레지스터 값

    // 상태 플래그
    output reg        busy,
    output reg        start_det,
    output reg        stop_det,
    input  wire       clr_status    // 1펄스: start_det/stop_det 클리어
);

// ─── 에지 검출 (3단 동기화기는 상위 모듈에서 수행. 여기서는 등록된 값만 사용) ───
reg scl_r, scl_r2;
reg sda_r, sda_r2;

always @(posedge clk) begin
    scl_r  <= scl_in;  scl_r2 <= scl_r;
    sda_r  <= sda_in;  sda_r2 <= sda_r;
end

wire scl_rise = ( scl_r && !scl_r2);
wire scl_fall = (!scl_r &&  scl_r2);
wire sda_fall = (!sda_r &&  sda_r2);
wire sda_rise = ( sda_r && !sda_r2);

// ─── 레지스터 파일 (8×8비트) ───
reg [7:0] regfile [0:7];
integer i_init;

assign reg_proxy = regfile[reg_raddr];

// AXI 쪽에서 레지스터 파일 쓰기 (우선: AXI > I2C, 클럭 사이클 충돌 없음 가정)
always @(posedge clk) begin
    if (rst) begin
        for (i_init = 0; i_init < 8; i_init = i_init + 1)
            regfile[i_init] <= 8'h00;
    end else if (reg_we) begin
        regfile[reg_waddr] <= reg_wdata;
    end
end

// ─── I2C 슬레이브 FSM ───
localparam S_IDLE      = 4'd0;
localparam S_ADDR      = 4'd1;   // 7비트 주소 수신
localparam S_RW        = 4'd2;   // R/W 비트
localparam S_ADDR_ACK  = 4'd3;   // 주소 ACK
localparam S_REG_ADDR  = 4'd4;   // 레지스터 주소 바이트
localparam S_REG_ACK   = 4'd5;   // 레지스터 주소 ACK
localparam S_WRITE     = 4'd6;   // 데이터 바이트 수신
localparam S_WACK      = 4'd7;   // 데이터 쓰기 ACK
localparam S_READ      = 4'd8;   // 데이터 바이트 송신
localparam S_RACK      = 4'd9;   // 마스터 ACK/NACK 수신

reg [3:0] state;
reg [2:0] bit_cnt;    // 비트 카운터 (7→0)
reg [7:0] shift_reg;  // 수신/송신 시프트 레지스터
reg [2:0] i2c_reg;    // 접근할 레지스터 주소[2:0]
reg       rw_bit;     // 1=Read, 0=Write
reg       addr_match; // 주소 일치 플래그

always @(posedge clk) begin
    if (rst) begin
        state      <= S_IDLE;
        bit_cnt    <= 3'd7;
        shift_reg  <= 8'h00;
        i2c_reg    <= 3'd0;
        rw_bit     <= 1'b0;
        addr_match <= 1'b0;
        sda_oe     <= 1'b0;
        busy       <= 1'b0;
        start_det  <= 1'b0;
        stop_det   <= 1'b0;
        reg_rdata  <= 8'h00;
    end else begin

        // clr_status 펄스 처리
        if (clr_status) begin
            start_det <= 1'b0;
            stop_det  <= 1'b0;
        end

        // ─── START 조건: SCL HIGH 상태에서 SDA 하강 ───
        if (scl_r2 && sda_fall) begin
            state     <= S_ADDR;
            bit_cnt   <= 3'd6;
            shift_reg <= 8'h00;
            sda_oe    <= 1'b0;
            busy      <= 1'b1;
            start_det <= 1'b1;
        end

        // ─── STOP 조건: SCL HIGH 상태에서 SDA 상승 ───
        else if (scl_r2 && sda_rise && state != S_IDLE) begin
            state    <= S_IDLE;
            sda_oe   <= 1'b0;
            busy     <= 1'b0;
            stop_det <= 1'b1;
        end

        // ─── SCL 상승 에지: 데이터 샘플링 ───
        else if (scl_rise) begin
            case (state)
                S_ADDR: begin
                    shift_reg[bit_cnt] <= sda_r;
                    if (bit_cnt == 3'd0) begin
                        state   <= S_RW;
                        bit_cnt <= 3'd0;
                    end else begin
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                end

                S_RW: begin
                    rw_bit     <= sda_r;
                    addr_match <= (shift_reg[6:0] == SLAVE_ADDR[6:0]);
                    state      <= S_ADDR_ACK;
                end

                S_ADDR_ACK: begin
                    // 슬레이브가 ACK를 출력 중(sda_oe=1). 다음 상태로.
                    if (addr_match) begin
                        if (rw_bit) begin
                            // READ: 레지스터 데이터를 준비
                            reg_rdata <= regfile[i2c_reg];
                            state     <= S_READ;
                            bit_cnt   <= 3'd7;
                        end else begin
                            state   <= S_REG_ADDR;
                            bit_cnt <= 3'd7;
                        end
                    end else begin
                        state  <= S_IDLE;
                        busy   <= 1'b0;
                    end
                end

                S_REG_ADDR: begin
                    shift_reg <= {shift_reg[6:0], sda_r};
                    if (bit_cnt == 3'd0) begin
                        i2c_reg <= shift_reg[2:0]; // 하위 3비트만 사용
                        state   <= S_REG_ACK;
                    end else begin
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                end

                S_REG_ACK: begin
                    // 슬레이브 ACK 출력 중. 다음 상태 전환.
                    state   <= S_WRITE;
                    bit_cnt <= 3'd7;
                end

                S_WRITE: begin
                    shift_reg <= {shift_reg[6:0], sda_r};
                    if (bit_cnt == 3'd0) begin
                        state <= S_WACK;
                    end else begin
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                end

                S_WACK: begin
                    // ACK 출력 중. 레지스터 파일에 쓴다.
                    regfile[i2c_reg] <= shift_reg;
                    i2c_reg          <= i2c_reg + 3'd1; // 순차 쓰기
                    state            <= S_WRITE;
                    bit_cnt          <= 3'd7;
                end

                S_READ: begin
                    // MSB부터 출력 중. SCL 상승에서 비트 카운터만 감소.
                    if (bit_cnt == 3'd0)
                        state <= S_RACK;
                    else
                        bit_cnt <= bit_cnt - 3'd1;
                end

                S_RACK: begin
                    // 마스터 ACK(0)=계속, NACK(1)=종료
                    if (sda_r == 1'b0) begin
                        // ACK: 다음 바이트 전송
                        i2c_reg   <= i2c_reg + 3'd1;
                        reg_rdata <= regfile[i2c_reg + 3'd1];
                        state     <= S_READ;
                        bit_cnt   <= 3'd7;
                    end else begin
                        // NACK: 대기 (STOP이 올 것)
                        state  <= S_IDLE;
                        sda_oe <= 1'b0;
                        busy   <= 1'b0;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end // scl_rise

        // ─── SCL 하강 에지: SDA 출력 전환 ───
        else if (scl_fall) begin
            case (state)
                S_ADDR_ACK: begin
                    // 주소가 일치하면 ACK(SDA 풀다운)
                    sda_oe <= addr_match ? 1'b1 : 1'b0;
                end

                S_REG_ACK: begin
                    // 레지스터 주소 ACK
                    sda_oe <= 1'b1;
                end

                S_WACK: begin
                    // 데이터 쓰기 ACK
                    sda_oe <= 1'b1;
                end

                S_READ: begin
                    // MSB부터 비트 출력: sda_oe=1이면 SDA=0, sda_oe=0이면 SDA=Hi-Z(1)
                    // reg_rdata[bit_cnt]가 0이면 풀다운, 1이면 Hi-Z
                    sda_oe <= ~reg_rdata[bit_cnt];
                end

                S_RACK: begin
                    // 마스터 ACK 수신 대기: SDA 릴리즈
                    sda_oe <= 1'b0;
                end

                default: begin
                    // ACK 단계가 아니면 SDA 릴리즈
                    if (state == S_ADDR || state == S_RW ||
                        state == S_REG_ADDR || state == S_WRITE)
                        sda_oe <= 1'b0;
                end
            endcase
        end // scl_fall

    end // not rst
end // always

endmodule
