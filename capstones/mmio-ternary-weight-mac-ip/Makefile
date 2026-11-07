# Makefile — mmio-ternary-weight-mac-ip
# 타깃: lint, sim, synth, clean

SLUG    := mmio-ternary-weight-mac-ip
RTL     := rtl/soc_top.v rtl/axil_ternary_mac.v rtl/ternary_mac_core.v
TB      := tb/tb_ternary_mac.v
SIM_TOP := tb_ternary_mac
YOSYS_SCRIPT := synth_xilinx -top soc_top -flatten

.PHONY: all lint sim synth clean

all: lint sim

lint:
	iverilog -g2001 -Wall -Wno-timescale -tnull $(RTL) $(TB)

sim:
	iverilog -g2001 -Wall -Wno-timescale -o $(SIM_TOP) $(TB) $(RTL)
	vvp $(SIM_TOP) | tee /dev/stderr | grep -E "^(PASS|FAIL)" ; \
	    ret=$$?; \
	    if grep -q "^FAIL" < <(vvp $(SIM_TOP) 2>/dev/null); then exit 1; else exit 0; fi

sim_simple:
	iverilog -g2001 -Wall -Wno-timescale -o $(SIM_TOP) $(TB) $(RTL)
	vvp $(SIM_TOP)

synth:
	yosys -p "read_verilog $(RTL); $(YOSYS_SCRIPT); stat" 2>&1 | tee build_synth.log
	@grep -E "Number of (cells|wires|LUTs)|SFFs" build_synth.log || true

clean:
	rm -f $(SIM_TOP) build_synth.log
