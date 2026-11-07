# Makefile — mmio-axil-irq-timer-ip
# 타깃: lint, sim, synth
# 도구: verilator (lint), iverilog+vvp (sim), yosys (synth)

RTL_DIR  := rtl
TB_DIR   := tb
SYNTH_DIR := build/synth

RTL_SRCS := $(RTL_DIR)/axil_irq_timer.v
TOP_SRC  := $(RTL_DIR)/basys3_top_irq_timer.v
TB_SRC   := $(TB_DIR)/tb_axil_irq_timer.v

SIM_BIN  := build/sim_irq_timer
SYNTH_LOG := $(SYNTH_DIR)/synth.log

.PHONY: all lint sim synth clean

all: lint sim synth

## --- Lint (verilator) ---
lint:
	@mkdir -p build
	verilator --lint-only -g2012 --Wall \
	    $(RTL_SRCS) $(TOP_SRC) \
	    --top-module basys3_top_irq_timer 2>&1 | tee build/lint.log
	@echo "lint done"

## --- Simulation (iverilog + vvp) ---
sim: build
	iverilog -g2001 -Wall \
	    $(RTL_SRCS) \
	    $(TB_SRC) \
	    -o $(SIM_BIN) 2>&1 | tee build/iverilog.log
	vvp $(SIM_BIN) | tee build/sim.log
	@grep -E "^(PASS|FAIL)" build/sim.log || true
	@grep -q "^FAIL" build/sim.log && exit 1 || true

## --- Synthesis (yosys, Artix-7 추정) ---
synth:
	@mkdir -p $(SYNTH_DIR)
	yosys -p " \
	    read_verilog -sv $(RTL_SRCS) $(TOP_SRC); \
	    synth_xilinx -top basys3_top_irq_timer -flatten; \
	    stat; \
	" 2>&1 | tee $(SYNTH_LOG)
	@echo "synth done (yosys 추정 — Vivado 수치와 다를 수 있음)"

build:
	@mkdir -p build

clean:
	rm -rf build
