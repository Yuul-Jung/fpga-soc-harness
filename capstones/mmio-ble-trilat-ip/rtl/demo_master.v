`timescale 1ns/1ps
// demo_master.v — 시뮬레이션 전용 AXI4-Lite 마스터 FSM
// 테스트벤치에서 ble_trilat_ip에 쓰기/읽기 트랜잭션을 주입한다.
// 합성에서는 basys3_top에서 연결하지 않으므로 경고 없이 소거된다.
`default_nettype none
module demo_master (
    input  wire        clk,
    input  wire        rst_n,
    // AXI4-Lite 마스터 포트
    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,
    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wvalid,
    input  wire        m_wready,
    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output reg         m_bready,
    output reg  [31:0] m_araddr,
    output reg         m_arvalid,
    input  wire        m_arready,
    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rvalid,
    output reg         m_rready,
    // 태스크 인터페이스 (TB에서 task로 호출)
    input  wire [31:0] req_addr,
    input  wire [31:0] req_wdata,
    input  wire        req_wr,     // 1=쓰기, 0=읽기
    input  wire        req_valid,
    output reg  [31:0] rsp_rdata,
    output reg         rsp_done
);
    localparam [1:0] MS_IDLE=0, MS_WR=1, MS_RD=2, MS_BRESP=3;
    reg [1:0] ms_st;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ms_st <= MS_IDLE;
            m_awvalid<=0; m_wvalid<=0; m_bready<=1;
            m_arvalid<=0; m_rready<=1; rsp_done<=0;
            m_awaddr<=0; m_wdata<=0; m_wstrb<=4'hF;
            m_araddr<=0; rsp_rdata<=0;
        end else begin
            rsp_done <= 0;
            case (ms_st)
                MS_IDLE: begin
                    if (req_valid) begin
                        if (req_wr) begin
                            m_awaddr  <= req_addr;
                            m_awvalid <= 1;
                            m_wdata   <= req_wdata;
                            m_wstrb   <= 4'hF;
                            m_wvalid  <= 1;
                            ms_st     <= MS_WR;
                        end else begin
                            m_araddr  <= req_addr;
                            m_arvalid <= 1;
                            ms_st     <= MS_RD;
                        end
                    end
                end
                MS_WR: begin
                    if (m_awready) m_awvalid <= 0;
                    if (m_wready)  m_wvalid  <= 0;
                    if (m_bvalid)  begin
                        rsp_done <= 1;
                        ms_st    <= MS_IDLE;
                    end
                end
                MS_RD: begin
                    if (m_arready) m_arvalid <= 0;
                    if (m_rvalid)  begin
                        rsp_rdata <= m_rdata;
                        rsp_done  <= 1;
                        ms_st     <= MS_IDLE;
                    end
                end
                default: ms_st <= MS_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
