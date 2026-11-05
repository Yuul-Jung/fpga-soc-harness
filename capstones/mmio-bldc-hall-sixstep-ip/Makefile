# Makefile — mmio-bldc-hall-sixstep-ip
# Targets: lint, sim, synth, all, clean
# Tools: iverilog (sim), verilator (lint), yosys (synth)

SLUG    := mmio-bldc-hall-sixstep-ip
TOP     := bldc_hall_sixstep_ip
TB      := tb_bldc_hall_sixstep_ip

RTL_SRC := rtl/$(TOP).v
TB_SRC  := tb/$(TB).v

BUILD   := build
VLOG    := iverilog
VVP     := vvp
VLOG_FLAGS := -g2001 -Wall -Wno-timescale

VERILATOR := verilator
VER_FLAGS := --lint-only -Wall --Wno-UNUSEDSIGNAL --Wno-MULTITOP -sv

YOSYS   := yosys
SYNTH_SCRIPT := $(BUILD)/synth.ys

.PHONY: all lint sim synth clean

all: lint sim synth

# -----------------------------------------------------------------------
# Lint (verilator)
# -----------------------------------------------------------------------
lint: $(RTL_SRC)
	@mkdir -p $(BUILD)
	$(VERILATOR) $(VER_FLAGS) $(RTL_SRC) 2>&1 | tee $(BUILD)/lint.log
	@echo "--- LINT DONE ---"

# -----------------------------------------------------------------------
# Simulation (iverilog + vvp)
# -----------------------------------------------------------------------
sim: $(RTL_SRC) $(TB_SRC)
	@mkdir -p $(BUILD)
	$(VLOG) $(VLOG_FLAGS) -o $(BUILD)/$(TB).vvp $(TB_SRC) $(RTL_SRC)
	$(VVP) $(BUILD)/$(TB).vvp | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log && echo "--- SIM PASS ---" || (echo "--- SIM FAIL ---"; exit 1)

# -----------------------------------------------------------------------
# Synthesis (yosys, resource estimate only)
# -----------------------------------------------------------------------
synth: $(RTL_SRC)
	@mkdir -p $(BUILD)
	@printf 'read_verilog -sv %s\nsynth -top %s\nstat\n' $(RTL_SRC) $(TOP) > $(SYNTH_SCRIPT)
	$(YOSYS) -q -s $(SYNTH_SCRIPT) 2>&1 | tee $(BUILD)/synth.log
	@echo "--- SYNTH DONE ---"

# -----------------------------------------------------------------------
# Clean
# -----------------------------------------------------------------------
clean:
	rm -rf $(BUILD)
