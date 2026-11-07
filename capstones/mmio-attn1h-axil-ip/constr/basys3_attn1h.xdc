# Basys3 constraints for mmio-attn1h-axil-ip
# Board: Digilent Basys3 (XC7A35T-1CPG236C)
# Note: AXI4-Lite signals connect through MicroBlaze V interconnect in full SoC.
#       This XDC is for standalone synthesis check only.

# System clock (W5, 100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

# Centre button (reset)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# LEDs: LD0=busy, LD1=done
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
