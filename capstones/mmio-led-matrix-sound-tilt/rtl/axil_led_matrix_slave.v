// axil_led_matrix_slave.v
// AXI4-Lite 슬레이브 레지스터 파일
// 4+8 = 12개 레지스터 (CTRL/STATUS/MODE/BRIGHT + TILT_X/TILT_Y + ENERGY0~7)
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module axil_led_matrix_slave #(
    parameter ADDR_W = 12,
    parameter DATA_W = 32
)(
    input  wire            clk,
    input  wire            rst_n,
    // AXI4-Lite 버스
    // Write address
    input  wire [ADDR_W-1:0] s_awaddr,
    input  wire              s_awvalid,
    output reg               s_awready,
    // Write data
    input  wire [DATA_W-1:0] s_wdata,
    input  wire [3:0]        s_wstrb,
    input  wire              s_wvalid,
    output reg               s_wready,
    // Write response
    output reg  [1:0]        s_bresp,
    output reg               s_bvalid,
    input  wire              s_bready,
    // Read address
    input  wire [ADDR_W-1:0] s_araddr,
    input  wire              s_arvalid,
    output reg               s_arready,
    // Read data
    output reg  [DATA_W-1:0] s_rdata,
    output reg  [1:0]        s_rresp,
    output reg               s_rvalid,
    input  wire              s_rready,

    // 내부 제어 출력
    output reg  [1:0]  ctrl_mode,
    output reg  [3:0]  ctrl_bright,
    output reg         ctrl_en,
    output reg         ctrl_soft_rst,
    output reg         ctrl_pdm_clk_en,
    output reg         ctrl_adxl_en,

    // 상태 입력 (스탬프되어 STATUS 레지스터에 반영)
    input  wire        pdm_valid,
    input  wire        adxl_valid_in,
    input  wire        iir_busy,

    // 에너지·기울기 (읽기 전용 레지스터에 연결)
    input  wire [7:0][31:0] energy,  // SystemVerilog 형태 — Verilog-2001 호환으로 아래에서 개별 선언
    input  wire [31:0] energy0, energy1, energy2, energy3,
    input  wire [31:0] energy4, energy5, energy6, energy7,
    input  wire signed [9:0] x_tilt_in,
    input  wire signed [9:0] y_tilt_in
);
    // 쓰기 주소 래치
    reg [ADDR_W-1:0] aw_addr_latch;
    reg              aw_pending;

    // 읽기
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_awready <= 0; s_wready <= 0;
            s_bvalid  <= 0; s_bresp  <= 0;
            s_arready <= 0; s_rvalid <= 0;
            s_rdata   <= 0; s_rresp  <= 0;
            aw_pending <= 0; aw_addr_latch <= 0;
            ctrl_mode       <= 2'b00;
            ctrl_bright     <= 4'h8;
            ctrl_en         <= 1;
            ctrl_soft_rst   <= 0;
            ctrl_pdm_clk_en <= 1;
            ctrl_adxl_en    <= 1;
        end else begin
            // soft_rst 자동 클리어
            ctrl_soft_rst <= 0;

            // ---- 쓰기 채널 ----
            if (s_awvalid && !aw_pending) begin
                s_awready    <= 1;
                aw_addr_latch <= s_awaddr;
                aw_pending   <= 1;
            end else
                s_awready <= 0;

            if (s_wvalid && aw_pending) begin
                s_wready <= 1;
                aw_pending <= 0;
                // 레지스터 쓰기
                case (aw_addr_latch[5:2])  // 32비트 단어 오프셋
                    4'h0: begin  // CTRL 0x00
                        ctrl_en         <= s_wdata[0];
                        ctrl_soft_rst   <= s_wdata[1];
                        ctrl_pdm_clk_en <= s_wdata[2];
                        ctrl_adxl_en    <= s_wdata[3];
                    end
                    4'h2: ctrl_mode   <= s_wdata[1:0];  // MODE 0x08
                    4'h3: ctrl_bright <= s_wdata[3:0];  // BRIGHT 0x0C
                    default: ;
                endcase
                // 쓰기 응답
                s_bvalid <= 1;
                s_bresp  <= 2'b00;  // OKAY
            end else
                s_wready <= 0;

            if (s_bvalid && s_bready) s_bvalid <= 0;

            // ---- 읽기 채널 ----
            if (s_arvalid && !s_rvalid) begin
                s_arready <= 1;
                s_rvalid  <= 1;
                s_rresp   <= 2'b00;
                case (s_araddr[5:2])
                    4'h0: s_rdata <= {28'b0, ctrl_adxl_en, ctrl_pdm_clk_en, 1'b0, ctrl_en};
                    4'h1: s_rdata <= {24'b0, iir_busy, 6'b0, adxl_valid_in, pdm_valid}; // STATUS
                    4'h2: s_rdata <= {30'b0, ctrl_mode};
                    4'h3: s_rdata <= {28'b0, ctrl_bright};
                    4'h4: s_rdata <= {{22{x_tilt_in[9]}}, x_tilt_in};
                    4'h5: s_rdata <= {{22{y_tilt_in[9]}}, y_tilt_in};
                    4'h6: s_rdata <= energy0;
                    4'h7: s_rdata <= energy1;
                    4'h8: s_rdata <= energy2;
                    4'h9: s_rdata <= energy3;
                    4'hA: s_rdata <= energy4;
                    4'hB: s_rdata <= energy5;
                    4'hC: s_rdata <= energy6;
                    4'hD: s_rdata <= energy7;
                    default: s_rdata <= 32'hDEAD_BEEF;
                endcase
            end else
                s_arready <= 0;

            if (s_rvalid && s_rready) s_rvalid <= 0;
        end
    end

endmodule
`default_nettype wire
