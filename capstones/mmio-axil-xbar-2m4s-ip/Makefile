# Makefile — axil_xbar_2m4s 캡스톤 빌드
# 타깃: lint (verilator), sim (iverilog+vvp), synth (yosys)
# 작성: fpga-soc-harness 하네스 직접 작성 (2026-11-06)

TOP      = axil_xbar_2m4s
TOP_FILE = rtl/axil_xbar_2m4s.v
ERR_FILE = rtl/axil_error_slave.v
WRAP_FILE= rtl/basys3_top_xbar.v
TB_FILE  = tb/tb_axil_xbar_2m4s.v

SIM_OUT  = sim.vvp

.PHONY: all lint sim synth clean

all: lint sim

## ─── Lint ─────────────────────────────────────────────────────────────────
lint:
	verilator --lint-only -g2012 -DSIMULATION \
	  $(ERR_FILE) $(TOP_FILE)
	@echo "lint: OK"

## ─── Simulation ───────────────────────────────────────────────────────────
sim:
	iverilog -g2012 -DSIMULATION \
	  -o $(SIM_OUT) \
	  $(ERR_FILE) $(TOP_FILE) $(TB_FILE)
	vvp $(SIM_OUT)

## ─── Synthesis (yosys, Artix-7 추정) ─────────────────────────────────────
synth:
	yosys -p " \
	  read_verilog -sv $(ERR_FILE); \
	  read_verilog -sv $(TOP_FILE); \
	  synth_xilinx -top $(TOP) -family xc7; \
	  stat -top $(TOP)"

## ─── Clean ────────────────────────────────────────────────────────────────
clean:
	rm -f $(SIM_OUT) *.jou *.log
