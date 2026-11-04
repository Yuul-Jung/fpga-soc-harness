# Makefile — mmio-pid-step-capture
# 타깃: lint, sim, synth
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)

SLUG    := mmio-pid-step-capture
RTL_DIR := rtl
TB_DIR  := tb
BUILD   := build

RTL_SRC := $(RTL_DIR)/gpio.v \
           $(RTL_DIR)/uart_tx.v \
           $(RTL_DIR)/pid_cap_ip.v \
           $(RTL_DIR)/mmio_bus.v \
           $(RTL_DIR)/demo_master.v \
           $(RTL_DIR)/soc_top.v \
           $(RTL_DIR)/basys3_top.v

TB_SRC  := $(TB_DIR)/tb_pid_cap.v \
           $(RTL_DIR)/pid_cap_ip.v

.PHONY: all lint sim synth clean

all: lint sim synth

$(BUILD):
	mkdir -p $(BUILD)

## ── 린트 (verilator --lint-only) ──────────────────────────────────
lint: $(BUILD)
	verilator --lint-only -Wall --Wno-UNUSEDSIGNAL --Wno-UNUSEDPARAM \
	    $(RTL_SRC) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

## ── 시뮬레이션 (iverilog + vvp) ───────────────────────────────────
sim: $(BUILD)
	iverilog -g2001 -Wall -Wno-timescale \
	    -o $(BUILD)/sim.vvp \
	    $(TB_SRC) 2>&1 | tee $(BUILD)/iverilog.log
	vvp $(BUILD)/sim.vvp 2>&1 | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log && echo "sim: PASS" || \
	    (echo "sim: FAIL — see $(BUILD)/sim.log" && exit 1)

## ── 합성 (yosys, Artix-7 타깃) ────────────────────────────────────
synth: $(BUILD)
	yosys -p " \
	    read_verilog $(RTL_SRC); \
	    synth_xilinx -top basys3_top -flatten; \
	    stat; \
	    write_json $(BUILD)/synth.json \
	" 2>&1 | tee $(BUILD)/synth.log
	@grep -q "^End of script" $(BUILD)/synth.log && echo "synth: OK" || \
	    (echo "synth: FAIL — see $(BUILD)/synth.log" && exit 1)

## ── 정리 ────────────────────────────────────────────────────────────
clean:
	rm -rf $(BUILD)
