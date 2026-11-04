# basys3_sensor_hub.xdc — Pin constraints for sensor_hub_top on Basys3 (XC7A35T)
# I2C Pmod: JA[0]=SCL, JA[1]=SDA (open-drain with 4.7kΩ pull-ups to 3.3V)
# UART Pmod: JB[0]=RX (GPS NEO-6M TX → Basys3 RX)
# IRQ: internal signal only (connect to intc input 13 in block design)
# Clock: 100 MHz onboard oscillator

# ─── Clock ───────────────────────────────────────────────────────────────────
set_property PACKAGE_PIN W5 [get_ports aclk]
set_property IOSTANDARD LVCMOS33 [get_ports aclk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports aclk]

# ─── Reset (active-low; tie to SW[0] via NOT for convenience) ────────────────
set_property PACKAGE_PIN V17 [get_ports aresetn]
set_property IOSTANDARD LVCMOS33 [get_ports aresetn]

# ─── I2C Pmod JA ─────────────────────────────────────────────────────────────
# JA[0] = SCL output (drive)
set_property PACKAGE_PIN J1 [get_ports i2c_scl_o]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_scl_o]
# JA[1] = SCL tristate enable (1=hi-z, 0=drive) — tie to open-drain buffer OE
set_property PACKAGE_PIN L2 [get_ports i2c_scl_t]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_scl_t]
# JA[2] = SDA output (drive value)
set_property PACKAGE_PIN J2 [get_ports i2c_sda_o]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_o]
# JA[3] = SDA tristate enable (1=hi-z, 0=drive)
set_property PACKAGE_PIN G2 [get_ports i2c_sda_t]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_t]
# JA[4] = SDA input (read from bus)
set_property PACKAGE_PIN H1 [get_ports i2c_sda_i]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_i]

# ─── UART Pmod JB ────────────────────────────────────────────────────────────
# JB[0] = UART RX (GPS TX → Basys3)
set_property PACKAGE_PIN A14 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# ─── IRQ output (optional: connect to LED[0] for debug) ──────────────────────
# In a full SoC integration, irq connects to intc port 13.
# For standalone bitstream test, wire to LED[0].
set_property PACKAGE_PIN U16 [get_ports irq]
set_property IOSTANDARD LVCMOS33 [get_ports irq]

# ─── Timing constraints ───────────────────────────────────────────────────────
# AXI bus is fully synchronous to aclk; no false paths to external I2C/UART
# (I2C and UART are slow interfaces; relax output delay)
set_output_delay -clock sys_clk_pin -max 5.0 [get_ports {i2c_scl_o i2c_scl_t i2c_sda_o i2c_sda_t irq}]
set_output_delay -clock sys_clk_pin -min -1.0 [get_ports {i2c_scl_o i2c_scl_t i2c_sda_o i2c_sda_t irq}]
set_input_delay  -clock sys_clk_pin -max 5.0 [get_ports {i2c_sda_i uart_rx}]
set_input_delay  -clock sys_clk_pin -min 0.0 [get_ports {i2c_sda_i uart_rx}]

# Note: In full block design integration, AXI ports connect to MicroBlaze V
# master. aresetn connects to proc_sys_reset active_low_peripheral_aresetn.
# The standalone constraints above are for direct bitstream testing only.
