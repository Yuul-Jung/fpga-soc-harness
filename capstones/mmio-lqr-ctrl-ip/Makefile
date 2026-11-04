# Makefile — LQR 제어기 IP (mmio-lqr-ctrl-ip)
# 타깃: lint, sim, synth, clean
# 도구: verilator (lint), iverilog+vvp (sim), yosys (synth)

SLUG    = mmio-lqr-ctrl-ip
RTL_DIR = rtl
TB_DIR  = tb
BUILD   = build

RTL_SRCS = $(RTL_DIR)/lqr_ip.v \
           $(RTL_DIR)/axil_lqr.v \
           $(RTL_DIR)/basys3_lqr_top.v

TB_SRCS  = $(TB_DIR)/tb_lqr_ctrl.v

.PHONY: all lint sim synth clean

all: lint sim synth

## ── 린트 (verilator) ────────────────────────────────────────────────────────
lint:
	@mkdir -p $(BUILD)
	verilator --lint-only -g2001 --Wall -Wno-UNUSED -Wno-PINMISSING \
	    $(RTL_SRCS) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

## ── 시뮬레이션 (iverilog + vvp) ─────────────────────────────────────────────
sim: $(BUILD)/tb_$(SLUG)
	vvp $(BUILD)/tb_$(SLUG) | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log && echo "sim PASS" || (echo "sim FAIL" && exit 1)

$(BUILD)/tb_$(SLUG): $(RTL_SRCS) $(TB_SRCS)
	@mkdir -p $(BUILD)
	iverilog -g2001 -o $@ $(RTL_SRCS) $(TB_SRCS)

## ── 합성 (yosys, 자원 추정) ─────────────────────────────────────────────────
synth:
	@mkdir -p $(BUILD)
	yosys -p "read_verilog -sv $(RTL_SRCS); \
	          synth_xilinx -top basys3_lqr_top -flatten; \
	          stat" \
	    2>&1 | tee $(BUILD)/synth.log
	@echo "synth done (yosys 추정 — Vivado 수치와 다를 수 있음)"

## ── 정리 ────────────────────────────────────────────────────────────────────
clean:
	rm -rf $(BUILD)
