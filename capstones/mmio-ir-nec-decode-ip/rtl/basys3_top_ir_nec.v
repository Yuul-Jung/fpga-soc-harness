// basys3_top_ir_nec.v — Basys3 최상위 래퍼 (NEC IR 디코더 AXI4-Lite IP)
// 클럭: 100 MHz (Basys3 W5)
// 리셋: CPU_RESET(T18, 액티브 하이) → 동기 액티브 하이 rst
// IR 입력: Pmod JA 핀 1 (J1, 液티브 로우, TSOP38238 출력)
// 인터럽트: irq_o → 외부 인터럽트 컨트롤러 연결용 (테스트 목적으로 LED[0]에 표시)
// AXI4-Lite 버스: 외부 MicroBlaze V 인터커넥트에서 연결

`timescale 1ns/1ps

module basys3_top_ir_nec (
    // 보드 클럭·리셋
    input  wire        clk100mhz,   // W5: 100 MHz 오실레이터
    input  wire        cpu_resetn,  // T18: CPU_RESET 버튼 (액티브 하이)

    // IR 수신 모듈 (Pmod JA, 핀 1 = J1)
    input  wire        ir_in,       // 액티브 로우 (TSOP38238 출력)

    // 상태 표시 (디버그)
    output wire [3:0]  led,         // led[0]=IRQ, led[1]=VALID, led[2]=ERR, led[3]=REPEAT

    // AXI4-Lite 슬레이브 버스 (MicroBlaze V 인터커넥트 연결)
    input  wire [3:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [3:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    // 인터럽트 출력
    output wire        irq_o
);

    // ---------------------------------------------------------------
    // 내부 신호
    // ---------------------------------------------------------------
    wire aresetn;

    // cpu_resetn은 액티브 하이(버튼 누르면 1) → AXI는 액티브 로우 리셋
    // 여기서는 단순히 반전해 aresetn으로 사용
    // 실제 MicroBlaze V 통합 시 Processor System Reset IP의 peripheral_aresetn을 연결한다
    assign aresetn = ~cpu_resetn;

    // ---------------------------------------------------------------
    // AXI4-Lite 래퍼 인스턴스
    // ---------------------------------------------------------------
    wire irq_internal;

    axil_ir_nec_wrap #(
        .DATA_W (32),
        .ADDR_W (4)
    ) u_wrap (
        .s_axi_aclk    (clk100mhz),
        .s_axi_aresetn (aresetn),

        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),

        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),

        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),

        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),

        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),

        .ir_in         (ir_in),
        .irq_o         (irq_internal)
    );

    assign irq_o = irq_internal;

    // ---------------------------------------------------------------
    // 디버그 LED
    // led[0] = 인터럽트(VALID)
    // led[1] = 직전 프레임 수신 표시 (IRQ와 같음, 별도 래치 가능하나 여기선 동일)
    // led[2] = 직전 오류
    // led[3] = 직전 반복 코드
    // 실사용에서는 AXI 읽기로 STATUS를 확인한다
    // ---------------------------------------------------------------
    // 간단히 IRQ 신호를 led[0]에 연결하고 나머지는 0
    assign led[0] = irq_internal;
    assign led[3:1] = 3'b000;

endmodule
