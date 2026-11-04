## basys3_ps2_mouse_cursor.xdc
## Basys3 핀 배정 — PS/2 마우스 + VGA 커서 오버레이
## 원작자: 하네스 자체 작성 (2026-11-04)

## ─── 클럭 ────────────────────────────────────────────────────
set_property PACKAGE_PIN W5   [get_ports CLK_100]
set_property IOSTANDARD LVCMOS33 [get_ports CLK_100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK_100]

## ─── 리셋 버튼 (BTNC) ───────────────────────────────────────
set_property PACKAGE_PIN U18  [get_ports BTNC]
set_property IOSTANDARD LVCMOS33 [get_ports BTNC]

## ─── PS/2 (오픈드레인 양방향) ───────────────────────────────
## Basys3의 USB HID 커넥터가 PS/2 프로토콜을 에뮬레이션
set_property PACKAGE_PIN C17  [get_ports PS2_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
set_property PULLUP true [get_ports PS2_CLK]

set_property PACKAGE_PIN B17  [get_ports PS2_DATA]
set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]
set_property PULLUP true [get_ports PS2_DATA]

## ─── VGA ────────────────────────────────────────────────────
set_property PACKAGE_PIN P19  [get_ports VGA_HS]
set_property IOSTANDARD LVCMOS33 [get_ports VGA_HS]
set_property PACKAGE_PIN R19  [get_ports VGA_VS]
set_property IOSTANDARD LVCMOS33 [get_ports VGA_VS]

## VGA Red (4비트)
set_property PACKAGE_PIN N19  [get_ports {VGA_R[0]}]
set_property PACKAGE_PIN J19  [get_ports {VGA_R[1]}]
set_property PACKAGE_PIN H19  [get_ports {VGA_R[2]}]
set_property PACKAGE_PIN N18  [get_ports {VGA_R[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[*]}]

## VGA Green (4비트)
set_property PACKAGE_PIN J17  [get_ports {VGA_G[0]}]
set_property PACKAGE_PIN H17  [get_ports {VGA_G[1]}]
set_property PACKAGE_PIN G17  [get_ports {VGA_G[2]}]
set_property PACKAGE_PIN D17  [get_ports {VGA_G[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[*]}]

## VGA Blue (4비트)
set_property PACKAGE_PIN N17  [get_ports {VGA_B[0]}]
set_property PACKAGE_PIN P14  [get_ports {VGA_B[1]}]
set_property PACKAGE_PIN R18  [get_ports {VGA_B[2]}]
set_property PACKAGE_PIN P15  [get_ports {VGA_B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[*]}]

## ─── LED ─────────────────────────────────────────────────────
## LED[0]=L_BTN, LED[1]=R_BTN, LED[2]=M_BTN, LED[3]=IRQ
set_property PACKAGE_PIN U16  [get_ports {LED[0]}]
set_property PACKAGE_PIN E19  [get_ports {LED[1]}]
set_property PACKAGE_PIN U19  [get_ports {LED[2]}]
set_property PACKAGE_PIN V19  [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]
