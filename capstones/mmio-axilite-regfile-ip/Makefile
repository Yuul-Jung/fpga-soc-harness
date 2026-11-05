# Makefile for mmio-axilite-regfile-ip
# Targets: sim  lint  synth  clean
# Tools: iverilog + vvp, verilator --lint-only, yosys

SIM    := iverilog
VVP    := vvp
LINT   := verilator --lint-only -g2012
YOSYS  := yosys

RTL    := rtl/axilite_regfile.v rtl/basys3_top_regfile.v
TB     := tb/tb_axilite_regfile.v
TOP    := basys3_top_regfile

BUILD  := build

.PHONY: all sim lint synth clean

all: sim lint synth

# ----------------------------------------------------------------
# Simulation: compile RTL + TB with iverilog, run with vvp
# PASS/FAIL is reported by the testbench itself.
# ----------------------------------------------------------------
sim: $(BUILD)/sim.vvp
	@echo "=== Simulation ==="
	$(VVP) $(BUILD)/sim.vvp | tee $(BUILD)/sim.log
	@grep -q '^PASS' $(BUILD)/sim.log && \
	    echo "sim: PASS" || \
	    (echo "sim: FAIL — check build/sim.log"; exit 1)

$(BUILD)/sim.vvp: $(RTL) $(TB) | $(BUILD)
	$(SIM) -g2001 -Wall -o $@ $(RTL) $(TB)

# ----------------------------------------------------------------
# Lint: verilator strict lint on the IP core only
# ----------------------------------------------------------------
lint: | $(BUILD)
	@echo "=== Lint ==="
	$(LINT) --top-module axilite_regfile $(RTL) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint: done (see $(BUILD)/lint.log)"

# ----------------------------------------------------------------
# Synthesis: yosys Artix-7 estimate (LUT/FF count)
# ----------------------------------------------------------------
synth: | $(BUILD)
	@echo "=== Synthesis (yosys) ==="
	$(YOSYS) -p " \
	    read_verilog -sv $(RTL); \
	    synth -top $(TOP); \
	    stat \
	" 2>&1 | tee $(BUILD)/synth.log
	@grep -q 'Number of cells' $(BUILD)/synth.log && \
	    echo "synth: PASS (see $(BUILD)/synth.log)" || \
	    (echo "synth: FAIL"; exit 1)

# ----------------------------------------------------------------
# Housekeeping
# ----------------------------------------------------------------
$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
