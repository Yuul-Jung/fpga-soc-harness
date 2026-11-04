## basys3_7seg.xdc
## Basys3 XDC constraints for mmio-7seg-adv-ip
## Target: Digilent Basys3 (XC7A35TCPG236-1), Vivado 2024.2
## HARNESS: mmio-7seg-adv-ip (I-072)

## Clock (100 MHz on-board oscillator)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset (Center button, active-HIGH)
set_property PACKAGE_PIN T17 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## 7-Segment Display — Anodes (active-LOW, common-anode)
## an[0]..an[3] = rightmost to leftmost digit
set_property PACKAGE_PIN U2  [get_ports {an[0]}]
set_property PACKAGE_PIN U4  [get_ports {an[1]}]
set_property PACKAGE_PIN V4  [get_ports {an[2]}]
set_property PACKAGE_PIN W4  [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[*]}]

## 7-Segment Display — Cathodes (active-LOW)
## Segment order: {g, f, e, d, c, b, a} → seg[6]..seg[0]
set_property PACKAGE_PIN W7  [get_ports {seg[6]}]
set_property PACKAGE_PIN W6  [get_ports {seg[5]}]
set_property PACKAGE_PIN U8  [get_ports {seg[4]}]
set_property PACKAGE_PIN V8  [get_ports {seg[3]}]
set_property PACKAGE_PIN U5  [get_ports {seg[2]}]
set_property PACKAGE_PIN V5  [get_ports {seg[1]}]
set_property PACKAGE_PIN U7  [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

## Decimal Point (active-LOW)
set_property PACKAGE_PIN V7  [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]
