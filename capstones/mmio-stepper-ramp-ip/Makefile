## Makefile — mmio-stepper-ramp-ip
## 사용법: make lint | sim | synth | all
## 도구: iverilog, yosys (Ubuntu: sudo apt install iverilog yosys)

SLUG    := mmio-stepper-ramp-ip
BUILD   := ../../build/$(SLUG)
RTL     := rtl/axil_stepper.v rtl/step_ramp_core.v rtl/seq_4wire.v rtl/basys3_top.v
TB      := tb/tb_axil_stepper.v
SIM_TOP := tb_axil_stepper

.PHONY: all lint sim synth clean

all: lint sim synth

## ── 린트 (iverilog -Wall -g2001 -tnull) ─────────────────────────
lint:
	@mkdir -p $(BUILD)
	iverilog -Wall -Wno-timescale -g2001 -tnull \
	    $(RTL) $(TB) 2>&1 | tee $(BUILD)/lint.log
	@echo "--- lint done ---"

## ── 시뮬레이션 ────────────────────────────────────────────────
sim:
	@mkdir -p $(BUILD)
	iverilog -g2001 -o $(BUILD)/sim.vvp \
	    $(RTL) $(TB) 2>&1 | tee $(BUILD)/sim_compile.log
	vvp $(BUILD)/sim.vvp 2>&1 | tee $(BUILD)/sim.log
	@grep -E "^(PASS|FAIL)" $(BUILD)/sim.log || \
	    (echo "FAIL: PASS/FAIL not found in sim output" && exit 1)

## ── yosys 합성 (자원 추정) ────────────────────────────────────
synth:
	@mkdir -p $(BUILD)
	yosys -p "read_verilog $(RTL); \
	          synth_xilinx -top basys3_top -flatten; \
	          stat" \
	    2>&1 | tee $(BUILD)/synth.log
	@echo "--- synth done ---"

clean:
	rm -rf $(BUILD)
