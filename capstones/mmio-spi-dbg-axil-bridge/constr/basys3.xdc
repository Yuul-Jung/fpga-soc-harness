# basys3.xdc — Basys3 XC7A35T constraints for mmio-spi-dbg-axil-bridge
# Pmod JA: SPI slave signals from RPi (3.3 V, no level shift needed)

# 100 MHz clock
set_property PACKAGE_PIN W5    [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# Reset (centre button)
set_property PACKAGE_PIN T17   [get_ports btnC]
set_property IOSTANDARD  LVCMOS33 [get_ports btnC]

# Pmod JA — SPI slave
# JA1 = SCK  (RPi GPIO 11)
set_property PACKAGE_PIN J1    [get_ports ja1]
set_property IOSTANDARD  LVCMOS33 [get_ports ja1]

# JA2 = MOSI (RPi GPIO 10)
set_property PACKAGE_PIN L2    [get_ports ja2]
set_property IOSTANDARD  LVCMOS33 [get_ports ja2]

# JA3 = MISO (RPi GPIO 9)
set_property PACKAGE_PIN J2    [get_ports ja3]
set_property IOSTANDARD  LVCMOS33 [get_ports ja3]

# JA4 = CSN  (RPi GPIO 8 / CE0)
set_property PACKAGE_PIN G2    [get_ports ja4]
set_property IOSTANDARD  LVCMOS33 [get_ports ja4]

# Status LED
set_property PACKAGE_PIN U16   [get_ports ld0]
set_property IOSTANDARD  LVCMOS33 [get_ports ld0]

# Timing: SPI signals are asynchronous inputs; relax input setup
set_input_delay -clock [get_clocks sys_clk] -min -add_delay 0.000 [get_ports {ja1 ja2 ja4}]
set_input_delay -clock [get_clocks sys_clk] -max -add_delay 5.000 [get_ports {ja1 ja2 ja4}]

# False path on asynchronous SPI inputs (2-stage synchronizer in RTL)
set_false_path -from [get_ports {ja1 ja2 ja4}]
