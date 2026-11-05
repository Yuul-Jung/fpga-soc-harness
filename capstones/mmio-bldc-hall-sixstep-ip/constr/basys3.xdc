# basys3.xdc — mmio-bldc-hall-sixstep-ip
# Minimal pin assignments for Basys3 (XC7A35T-1CPG236C)
# AXI4-Lite driven by MicroBlaze V CPU — no pin assignments needed for bus signals.
# External pins: hall inputs (Pmod JA), gate outputs (Pmod JB), 100 MHz clock, reset.

# -----------------------------------------------------------------------
# System clock (100 MHz on-board oscillator)
# -----------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# -----------------------------------------------------------------------
# Active-low reset (BTN0 center pushbutton)
# -----------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports rst_n]

# -----------------------------------------------------------------------
# Hall sensor inputs — Pmod JA (3-pin, {H_C, H_B, H_A})
# JA[1]=H_A (hall_in[0]), JA[2]=H_B (hall_in[1]), JA[3]=H_C (hall_in[2])
# -----------------------------------------------------------------------
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports {hall_in[0]}]
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports {hall_in[1]}]
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports {hall_in[2]}]

# -----------------------------------------------------------------------
# Gate drive outputs — Pmod JB
# High-side: JB[1]=HIN_A (hin[0]), JB[2]=HIN_B (hin[1]), JB[3]=HIN_C (hin[2])
# Low-side:  JB[4]=LIN_A (lin[0]), JB[5]=LIN_B (lin[1]), JB[6]=LIN_C (lin[2])
# Note: 3.3V logic only. Level-shift to gate driver logic level externally.
# -----------------------------------------------------------------------
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33 } [get_ports {hin[0]}]
set_property -dict { PACKAGE_PIN A16  IOSTANDARD LVCMOS33 } [get_ports {hin[1]}]
set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS33 } [get_ports {hin[2]}]
set_property -dict { PACKAGE_PIN B16  IOSTANDARD LVCMOS33 } [get_ports {lin[0]}]
set_property -dict { PACKAGE_PIN A17  IOSTANDARD LVCMOS33 } [get_ports {lin[1]}]
set_property -dict { PACKAGE_PIN C15  IOSTANDARD LVCMOS33 } [get_ports {lin[2]}]

# -----------------------------------------------------------------------
# ADC sample trigger — Pmod JB[7]
# -----------------------------------------------------------------------
set_property -dict { PACKAGE_PIN C16  IOSTANDARD LVCMOS33 } [get_ports sample_trig]

# -----------------------------------------------------------------------
# IRQ — Pmod JB[8] or connect to MicroBlaze V interrupt port
# -----------------------------------------------------------------------
set_property -dict { PACKAGE_PIN D17  IOSTANDARD LVCMOS33 } [get_ports irq]
