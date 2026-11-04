## basys3.xdc — VGA 타일맵 계기판 핀 제약
## 보드: Digilent Basys3 (XC7A35TCPG236-1)
## 클럭: 100 MHz (W5), 2비트 분주기로 25 MHz 생성
## VGA: Basys3 내장 저항 DAC (R-2R), 외부 부품 없음

## ── 클럭 ──────────────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk100]

## ── 리셋 (활성 로우) ────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports cpu_resetn]

## ── VGA 수평/수직 동기 ─────────────────────────────────────────────
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports vga_hs]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports vga_vs]

## ── VGA 적색 (4비트) ────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {vga_r[0]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {vga_r[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {vga_r[2]}]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports {vga_r[3]}]

## ── VGA 녹색 (4비트) ────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {vga_g[0]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {vga_g[1]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {vga_g[2]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {vga_g[3]}]

## ── VGA 청색 (4비트) ────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {vga_b[0]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {vga_b[1]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {vga_b[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {vga_b[3]}]

## ── AXI4-Lite 슬레이브 — 합성 테스트용 더미 포트 ──────────────────────
## (실제 SoC 연결 시 IP 인티그레이터에서 연결; 여기서는 타이밍 분석용)
## awaddr[15:0]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[0]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[1]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[2]}]
set_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[3]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[4]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[5]}]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[6]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[7]}]
set_property -dict {PACKAGE_PIN V2  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[8]}]
set_property -dict {PACKAGE_PIN T3  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[9]}]
set_property -dict {PACKAGE_PIN T2  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[10]}]
set_property -dict {PACKAGE_PIN R3  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[11]}]
set_property -dict {PACKAGE_PIN W2  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[12]}]
set_property -dict {PACKAGE_PIN U1  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[13]}]
set_property -dict {PACKAGE_PIN T1  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[14]}]
set_property -dict {PACKAGE_PIN R2  IOSTANDARD LVCMOS33} [get_ports {s_axil_awaddr[15]}]

## awvalid/awready
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports s_axil_awvalid]
## NOTE: awvalid reuses resetn pin slot only as placeholder; real design uses IP integrator

## wdata[31:0] — 스위치·LED 핀 활용 (16핀 한계로 wdata[15:0]만 XDC에 등록, 나머지 tie-off)
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[0]}]
set_property -dict {PACKAGE_PIN V3  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[1]}]
set_property -dict {PACKAGE_PIN W3  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[2]}]
set_property -dict {PACKAGE_PIN U3  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[3]}]
set_property -dict {PACKAGE_PIN P3  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[4]}]
set_property -dict {PACKAGE_PIN N3  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[5]}]
set_property -dict {PACKAGE_PIN P1  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[6]}]
set_property -dict {PACKAGE_PIN L1  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[7]}]
set_property -dict {PACKAGE_PIN L2  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[8]}]
set_property -dict {PACKAGE_PIN M1  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[9]}]
set_property -dict {PACKAGE_PIN N1  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[10]}]
set_property -dict {PACKAGE_PIN P2  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[11]}]
set_property -dict {PACKAGE_PIN M3  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[12]}]
set_property -dict {PACKAGE_PIN M4  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[13]}]
set_property -dict {PACKAGE_PIN M5  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[14]}]
set_property -dict {PACKAGE_PIN M6  IOSTANDARD LVCMOS33} [get_ports {s_axil_wdata[15]}]

## IRQ 출력 — LED[15] (U11)
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports irq]

## ── 타이밍 예외 ──────────────────────────────────────────────────────
## clk_div 출력(clk_25m)은 BUFG 없이 FF Q 신호로 사용 중. 가짜 경로로 처리.
## 프로덕션에서는 MMCM으로 교체하고 이 set_false_path를 제거한다.
set_false_path -from [get_pins */clk_div_reg*/C] -to [all_outputs]
