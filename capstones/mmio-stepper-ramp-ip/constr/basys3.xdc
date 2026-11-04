## basys3.xdc — Basys3 XC7A35T 핀 제약
## axil_stepper IP 보드 테스트용 (스텝모터 사다리꼴 가감속 IP)

## 클럭 100 MHz
set_property PACKAGE_PIN W5    [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## 리셋: btnC
set_property PACKAGE_PIN U18   [get_ports btnC]
set_property IOSTANDARD  LVCMOS33 [get_ports btnC]

## 슬라이드 스위치 SW[1:0]
set_property PACKAGE_PIN V17   [get_ports {sw[0]}]
set_property PACKAGE_PIN V16   [get_ports {sw[1]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {sw[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {sw[1]}]

## LED[3:0] (coil 패턴 표시)
set_property PACKAGE_PIN U16   [get_ports {led[0]}]
set_property PACKAGE_PIN E19   [get_ports {led[1]}]
set_property PACKAGE_PIN U19   [get_ports {led[2]}]
set_property PACKAGE_PIN V19   [get_ports {led[3]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led[3]}]

## LED[14] busy, LED[15] IRQ
set_property PACKAGE_PIN U14   [get_ports led_busy]
set_property PACKAGE_PIN V14   [get_ports led_irq]
set_property IOSTANDARD  LVCMOS33 [get_ports led_busy]
set_property IOSTANDARD  LVCMOS33 [get_ports led_irq]

## Pmod JA — ULN2003 IN1~IN4 (4선 모드) 또는 STEP/DIR (STEP/DIR 모드)
## JA[0]~JA[3] = coil[0]~coil[3] = ULN2003 IN1~IN4
set_property PACKAGE_PIN J1    [get_ports {jaMon[0]}]
set_property PACKAGE_PIN L2    [get_ports {jaMon[1]}]
set_property PACKAGE_PIN J2    [get_ports {jaMon[2]}]
set_property PACKAGE_PIN G2    [get_ports {jaMon[3]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {jaMon[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {jaMon[1]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {jaMon[2]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {jaMon[3]}]

## JA[4]=STEP, JA[5]=DIR (STEP/DIR 모드)
set_property PACKAGE_PIN H1    [get_ports jaStep]
set_property PACKAGE_PIN K2    [get_ports jaDir]
set_property IOSTANDARD  LVCMOS33 [get_ports jaStep]
set_property IOSTANDARD  LVCMOS33 [get_ports jaDir]
