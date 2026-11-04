# Makefile — mmio-motor-safety-wrapper
# 타깃: lint, sim, synth, all, clean
# iverilog, verilator, yosys 필요

SLUG    := mmio-motor-safety-wrapper
RTL_DIR := rtl
TB_DIR  := tb
BUILD   := build

RTL_SRCS := $(RTL_DIR)/gpio.v \
             $(RTL_DIR)/uart_tx.v \
             $(RTL_DIR)/motor_safety_ip.v \
             $(RTL_DIR)/mmio_bus.v \
             $(RTL_DIR)/soc_top.v \
             $(RTL_DIR)/demo_master.v

TB_SRCS  := $(TB_DIR)/tb_motor_safety.v \
             $(RTL_DIR)/motor_safety_ip.v

TOP      := motor_safety_ip
TB_TOP   := tb_motor_safety

.PHONY: all lint sim synth clean

all: lint sim synth

$(BUILD):
	mkdir -p $(BUILD)

# ---- 린트 (verilator --lint-only) ------------------------------------
lint: $(BUILD)
	verilator --lint-only -Wall --top-module $(TOP) $(RTL_SRCS) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

# ---- 시뮬레이션 (iverilog + vvp) -------------------------------------
sim: $(BUILD)
	iverilog -g2001 -Wall -o $(BUILD)/sim.vvp \
	    $(TB_SRCS) 2>&1 | tee $(BUILD)/sim_compile.log
	vvp $(BUILD)/sim.vvp 2>&1 | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log && echo "SIM: PASS" || (echo "SIM: FAIL"; exit 1)

# ---- 합성 (yosys 추정) -----------------------------------------------
synth: $(BUILD)
	yosys -p "read_verilog $(RTL_SRCS); \
	           synth -top $(TOP) -flatten; \
	           stat -tech xilinx; \
	           write_json $(BUILD)/synth.json" \
	    2>&1 | tee $(BUILD)/synth.log
	@echo "synth done (yosys 추정 — Vivado와 다를 수 있음)"

clean:
	rm -rf $(BUILD)
