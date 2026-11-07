# basys3_ds3231.xdc
# Basys3 constraints for mmio-ds3231-rtc-eeprom-ip capstone
# Board: Digilent Basys3 (XC7A35T-1CPG236C)
# Top module: basys3_top_ds3231

# ----------------------------------------------------------------
# Clock
# ----------------------------------------------------------------
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk [get_ports clk_100mhz]

# ----------------------------------------------------------------
# Reset (active-low, CPU_RESET button)
# ----------------------------------------------------------------
set_property PACKAGE_PIN U18 [get_ports cpu_resetn]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_resetn]

# ----------------------------------------------------------------
# Pmod JA — I2C bus
# Pin 1 (top-left)  = JA[0] = J1  → SCL
# Pin 2             = JA[1] = J2  → SDA
# Pin 7 (bottom-left) = GND (Pmod GND)
# Pin 6             = VCC 3.3 V  (Pmod VCC)
# ----------------------------------------------------------------
set_property PACKAGE_PIN J1 [get_ports pmod_ja1_scl]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_ja1_scl]
set_property DRIVE 4 [get_ports pmod_ja1_scl]
set_property SLEW SLOW [get_ports pmod_ja1_scl]

set_property PACKAGE_PIN L2 [get_ports pmod_ja2_sda]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_ja2_sda]
set_property DRIVE 4 [get_ports pmod_ja2_sda]
set_property SLEW SLOW [get_ports pmod_ja2_sda]

# ----------------------------------------------------------------
# Status LEDs
# ----------------------------------------------------------------
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# ----------------------------------------------------------------
# Timing exceptions — AXI master ports are for simulation/IP integration
# (False paths acceptable for top-level integration ports not used on board)
# ----------------------------------------------------------------
set_false_path -from [get_ports cpu_resetn]
