## basys3.xdc — mmio-multi-axis-motion-ctrl Basys3 제약
## Pmod JA: 채널 A 엔코더(핀1-2) + PWM+DIR(핀3-4)
## Pmod JB: 채널 B 엔코더(핀1-2) + PWM+DIR(핀3-4)
## 주의: 5V 엔코더 사용 시 레벨 변환 필수

## 클럭
set_property PACKAGE_PIN W5   [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]

## 리셋 (센터 버튼)
set_property PACKAGE_PIN U18  [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## Pmod JA — 채널 A 엔코더 입력 (핀 1=JA1, 핀 2=JA2)
set_property PACKAGE_PIN J1   [get_ports {ja_enc[0]}]
set_property PACKAGE_PIN L2   [get_ports {ja_enc[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_enc[*]}]
set_property PULLDOWN true       [get_ports {ja_enc[*]}]

## Pmod JA — 채널 A PWM+DIR 출력 (핀 3=JA3, 핀 4=JA4)
set_property PACKAGE_PIN J2   [get_ports {ja_pwm[0]}]
set_property PACKAGE_PIN G2   [get_ports {ja_pwm[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pwm[*]}]

## Pmod JB — 채널 B 엔코더 입력 (핀 1=JB1, 핀 2=JB2)
set_property PACKAGE_PIN A14  [get_ports {jb_enc[0]}]
set_property PACKAGE_PIN A16  [get_ports {jb_enc[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb_enc[*]}]
set_property PULLDOWN true       [get_ports {jb_enc[*]}]

## Pmod JB — 채널 B PWM+DIR 출력 (핀 3=JB3, 핀 4=JB4)
set_property PACKAGE_PIN B15  [get_ports {jb_pwm[0]}]
set_property PACKAGE_PIN B16  [get_ports {jb_pwm[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {jb_pwm[*]}]

## LED (상태 표시)
set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
