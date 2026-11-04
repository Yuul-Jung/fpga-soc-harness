## Basys3 XDC for mmio-i2c-nmea-sensor-hub
## 100 MHz clock, I2C on JA Pmod, UART RX on JB Pmod pin 1

## Clock
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN W5 [get_ports clk]

## Reset (active-low, btnC)
set_property PACKAGE_PIN U18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## I2C on JA Pmod (open-drain with external 4.7kΩ pull-ups to 3.3V)
## JA pin 1: SCL output enable (drives low when scl_oe=1)
## JA pin 2: SDA output enable (drives low when sda_oe=1)
## JA pin 3: SDA input
# i2c_scl_oe → JA pin 1 → J1 (direct drive low; pull-up external)
set_property PACKAGE_PIN J1  [get_ports i2c_scl_oe]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_scl_oe]
# i2c_sda_oe → JA pin 2 → L2
set_property PACKAGE_PIN L2  [get_ports i2c_sda_oe]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_oe]
# i2c_sda_i ← JA pin 3 → J2
set_property PACKAGE_PIN J2  [get_ports i2c_sda_i]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_i]

## UART RX on JB Pmod pin 1 (GPS module TX, 9600 baud, 3.3V)
set_property PACKAGE_PIN A14 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## IRQ → LED[0] for debug visibility
set_property PACKAGE_PIN U16 [get_ports irq]
set_property IOSTANDARD LVCMOS33 [get_ports irq]

## Timing exceptions for open-drain I2C outputs (not speed-critical)
set_output_delay -clock sys_clk_pin -max 2.0 [get_ports i2c_scl_oe]
set_output_delay -clock sys_clk_pin -min 0.5 [get_ports i2c_scl_oe]
set_output_delay -clock sys_clk_pin -max 2.0 [get_ports i2c_sda_oe]
set_output_delay -clock sys_clk_pin -min 0.5 [get_ports i2c_sda_oe]
set_input_delay  -clock sys_clk_pin -max 3.0 [get_ports i2c_sda_i]
set_input_delay  -clock sys_clk_pin -min 0.5 [get_ports i2c_sda_i]
set_input_delay  -clock sys_clk_pin -max 5.0 [get_ports uart_rx]
set_input_delay  -clock sys_clk_pin -min 0.5 [get_ports uart_rx]
