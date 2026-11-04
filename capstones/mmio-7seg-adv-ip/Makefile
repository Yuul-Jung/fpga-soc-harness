# Makefile — mmio-7seg-adv-ip (I-072)
# HARNESS: AXI4-Lite 7-Segment Advanced IP
# Targets: lint, sim, synth
# Tools: iverilog/vvp, verilator, yosys

SLUG   := mmio-7seg-adv-ip
RTL    := rtl/axil_7seg_ip.v rtl/basys3_top_7seg.v
TB     := tb/tb_axil_7seg_ip.v
TOP    := basys3_top_7seg
BUILD  := build

.PHONY: all lint sim synth clean

all: lint sim synth

## ----------------------------------------------------------------
## lint — Verilator syntax and style check
## ----------------------------------------------------------------
lint:
	@mkdir -p $(BUILD)
	verilator --lint-only -Wall $(RTL) --top-module $(TOP) 2>&1 | tee $(BUILD)/lint.log
	@echo "--- lint done ---"

## ----------------------------------------------------------------
## sim — iverilog + vvp self-checking testbench
## ----------------------------------------------------------------
sim:
	@mkdir -p $(BUILD)
	iverilog -o $(BUILD)/tb_$(SLUG) $(TB) $(RTL) -DSIMULATION 2>&1 | tee $(BUILD)/sim_compile.log
	vvp $(BUILD)/tb_$(SLUG) 2>&1 | tee $(BUILD)/sim_run.log
	@grep -E "^(PASS|FAIL)" $(BUILD)/sim_run.log || echo "FAIL: no PASS/FAIL line found"

## ----------------------------------------------------------------
## synth — Yosys logic synthesis (Xilinx Artix-7 target, estimate)
## ----------------------------------------------------------------
synth:
	@mkdir -p $(BUILD)
	yosys -p 'read_verilog $(RTL); \
	          synth_xilinx -top $(TOP); \
	          stat' \
	      > $(BUILD)/synth.log 2>&1
	@echo "--- synth done (see $(BUILD)/synth.log) ---"
	@tail -20 $(BUILD)/synth.log

## ----------------------------------------------------------------
## clean
## ----------------------------------------------------------------
clean:
	rm -rf $(BUILD)
