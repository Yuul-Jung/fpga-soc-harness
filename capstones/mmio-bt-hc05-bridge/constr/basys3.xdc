## basys3.xdc — HC-05 블루투스 텔레메트리 브리지 IP
## Basys3 (XC7A35T) 핀 배정
## AXI4-Lite 버스 신호(s_axi_*)는 MicroBlaze V 인터커넥트에 연결되므로 여기서 제약하지 않는다.

## ── 클럭 ────────────────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports s_axi_aclk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} \
    [get_ports s_axi_aclk]

## ── 리셋 (BTNC, active-high → 인버터로 active-low rst_n 생성) ─────
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports s_axi_aresetn]

## ── Pmod JA — HC-05 블루투스 모듈 연결 ────────────────────────────
## JA1 → bt_tx : FPGA TX → HC-05 RX
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports bt_tx]
## JA2 → bt_rx : HC-05 TX → FPGA RX
set_property -dict {PACKAGE_PIN L2  IOSTANDARD LVCMOS33} [get_ports bt_rx]
## JA7 → bt_state : HC-05 STATE (High=연결됨)
set_property -dict {PACKAGE_PIN H1  IOSTANDARD LVCMOS33} [get_ports bt_state]
## JA8 → bt_en   : HC-05 EN   (High=AT 모드 진입)
set_property -dict {PACKAGE_PIN K2  IOSTANDARD LVCMOS33} [get_ports bt_en]

## ── IRQ ─────────────────────────────────────────────────────────────
## irq는 MicroBlaze V 인터럽트 컨트롤러(intc 10)에 연결된다.
## Vivado IP 패키징 시 포트 매핑으로 처리한다.
