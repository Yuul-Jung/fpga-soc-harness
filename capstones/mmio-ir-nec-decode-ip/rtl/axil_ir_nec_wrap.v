// axil_ir_nec_wrap.v — AXI4-Lite 슬레이브 래퍼 (NEC IR 디코더 IP)
// 레지스터 맵 (로컬 주소, 베이스 0x402C_0000은 인터커넥트가 처리):
//   0x00  STATUS  R/W1C  bit0=VALID, bit1=REPEAT, bit2=ERR
//   0x04  ADDR    R      수신 NEC 주소 [7:0]
//   0x08  CMD     R      수신 NEC 명령 [7:0]
//   0x0C  IRQ_CLR W      임의 값 → 인터럽트 클리어 (STATUS[0] 동일)
// 인터럽트: irq_o = STATUS[0] (레벨, 액티브 하이)

`timescale 1ns/1ps

module axil_ir_nec_wrap #(
    parameter DATA_W = 32,
    parameter ADDR_W = 4
) (
    // AXI4-Lite 클럭·리셋
    input  wire                  s_axi_aclk,
    input  wire                  s_axi_aresetn,  // 액티브 로우

    // Write address channel
    input  wire [ADDR_W-1:0]     s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    // Write data channel
    input  wire [DATA_W-1:0]     s_axi_wdata,
    input  wire [DATA_W/8-1:0]   s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    // Write response channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // Read address channel
    input  wire [ADDR_W-1:0]     s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // Read data channel
    output reg  [DATA_W-1:0]     s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // 외부 핀
    input  wire                  ir_in,   // IR 수신 모듈 출력 (액티브 로우)

    // 인터럽트 출력 (레벨, 액티브 하이)
    output wire                  irq_o
);

    // ---------------------------------------------------------------
    // 내부 신호
    // ---------------------------------------------------------------
    wire       dv, dr, de;
    wire [7:0] da, dc;

    // 래치 레지스터
    reg  [2:0] status_reg;   // bit0=VALID, bit1=REPEAT, bit2=ERR
    reg  [7:0] addr_reg;
    reg  [7:0] cmd_reg;

    // AXI 내부 상태
    reg  [ADDR_W-1:0] aw_addr_lat;
    reg                aw_valid_lat;

    // ---------------------------------------------------------------
    // ir_nec_decode 인스턴스
    // ---------------------------------------------------------------
    ir_nec_decode u_core (
        .clk            (s_axi_aclk),
        .rst            (~s_axi_aresetn),
        .ir_in          (ir_in),
        .decoded_valid  (dv),
        .decoded_repeat (dr),
        .decoded_err    (de),
        .decoded_addr   (da),
        .decoded_cmd    (dc)
    );

    // ---------------------------------------------------------------
    // 래치 로직: 코어 출력 → 상태 레지스터
    // ---------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            status_reg <= 3'b000;
            addr_reg   <= 8'h00;
            cmd_reg    <= 8'h00;
        end else begin
            // 코어 이벤트 처리 (W1C 클리어보다 먼저 평가 — 같은 사이클이면 세트 우선)
            if (dv) begin
                status_reg[0] <= 1'b1;
                addr_reg      <= da;
                cmd_reg       <= dc;
            end
            if (dr) begin
                status_reg[1] <= 1'b1;
                // addr/cmd는 이전 값 유지 (유지를 명시적으로 쓰지 않아도 되지만 명확성을 위해)
            end
            if (de) begin
                status_reg[2] <= 1'b1;
            end

            // W1C 클리어 (AXI 쓰기에서 처리)
            // → 아래 쓰기 처리 블록에서 status_reg를 AND-clear
        end
    end

    // 인터럽트 = STATUS[0] (VALID 비트)
    assign irq_o = status_reg[0];

    // ---------------------------------------------------------------
    // AXI4-Lite 쓰기 채널
    // aw 주소와 w 데이터를 각각 받아 둘 다 도착하면 처리 후 B 반환
    // ---------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_addr_lat    <= {ADDR_W{1'b0}};
            aw_valid_lat   <= 1'b0;
        end else begin

            // AWREADY: 주소를 받으면 1사이클 펄스
            if (s_axi_awvalid && !s_axi_awready) begin
                s_axi_awready <= 1'b1;
                aw_addr_lat   <= s_axi_awaddr;
                aw_valid_lat  <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // WREADY: 데이터를 받으면 1사이클 펄스
            if (s_axi_wvalid && !s_axi_wready) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // 쓰기 실행: AW와 W 모두 도착했을 때
            if (aw_valid_lat && s_axi_wvalid) begin
                aw_valid_lat <= 1'b0;

                case (aw_addr_lat[3:2])
                    2'b00: begin   // 0x00 STATUS — W1C
                        // 쓴 비트가 1이면 클리어, IRQ도 함께 클리어
                        if (s_axi_wstrb[0]) begin
                            status_reg[0] <= status_reg[0] & ~s_axi_wdata[0];
                            status_reg[1] <= status_reg[1] & ~s_axi_wdata[1];
                            status_reg[2] <= status_reg[2] & ~s_axi_wdata[2];
                        end
                    end
                    2'b11: begin   // 0x0C IRQ_CLR — 임의 쓰기 → STATUS[0] 클리어
                        status_reg[0] <= 1'b0;
                    end
                    default: ;  // 0x04, 0x08은 읽기 전용, 쓰기 무시
                endcase

                // B 채널
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;  // OKAY
            end

            // BVALID 클리어
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ---------------------------------------------------------------
    // AXI4-Lite 읽기 채널
    // ---------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_W{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin

            if (s_axi_arvalid && !s_axi_arready) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;

                case (s_axi_araddr[3:2])
                    2'b00:   s_axi_rdata <= {{(DATA_W-3){1'b0}}, status_reg};
                    2'b01:   s_axi_rdata <= {{(DATA_W-8){1'b0}}, addr_reg};
                    2'b10:   s_axi_rdata <= {{(DATA_W-8){1'b0}}, cmd_reg};
                    default: s_axi_rdata <= {DATA_W{1'b0}};
                endcase
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
