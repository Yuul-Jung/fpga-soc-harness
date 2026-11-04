# Makefile — VGA 타일맵 계기판 IP
# 타깃: lint (verilator), sim (iverilog), synth (yosys)
# 사용: make lint | make sim | make synth | make all | make clean

SHELL   := /bin/bash
TOP     := basys3_top
TB      := tb_tilemap
RTL_DIR := rtl
TB_DIR  := tb
BUILD   := build

RTL_SRCS := $(RTL_DIR)/vga_timing.v \
            $(RTL_DIR)/tilemap_axil.v \
            $(RTL_DIR)/basys3_top.v

TB_SRCS  := $(TB_DIR)/tb_tilemap.v \
            $(RTL_DIR)/vga_timing.v \
            $(RTL_DIR)/tilemap_axil.v

.PHONY: all lint sim synth clean

all: lint sim synth

## ── lint: Verilator 문법 검사 ─────────────────────────────────────
lint: $(RTL_SRCS)
	@mkdir -p $(BUILD)
	verilator --lint-only -Wall --Wno-UNUSEDSIGNAL --Wno-UNUSEDPARAM \
	    -Wno-INITIALDLY \
	    $(RTL_SRCS) --top-module $(TOP) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

## ── sim: iverilog + vvp ───────────────────────────────────────────
sim: $(TB_SRCS)
	@mkdir -p $(BUILD)
	iverilog -g2005 -o $(BUILD)/$(TB).vvp $(TB_SRCS) 2>&1 | tee $(BUILD)/sim_compile.log
	vvp $(BUILD)/$(TB).vvp 2>&1 | tee $(BUILD)/sim.log
	@grep -E "^(PASS|FAIL)" $(BUILD)/sim.log || true
	@if grep -q "^PASS" $(BUILD)/sim.log; then \
	    echo "sim: PASS"; \
	else \
	    echo "sim: FAIL — see $(BUILD)/sim.log"; exit 1; \
	fi

## ── synth: Yosys synth_xilinx 자원 추정 ──────────────────────────
synth: $(RTL_SRCS)
	@mkdir -p $(BUILD)
	yosys -p "read_verilog $(RTL_SRCS); \
	          synth_xilinx -top $(TOP) -flatten; \
	          stat" \
	    2>&1 | tee $(BUILD)/synth.log
	@echo "synth done — see $(BUILD)/synth.log for LUT/FF/BRAM counts"

## ── clean ─────────────────────────────────────────────────────────
clean:
	rm -rf $(BUILD)
