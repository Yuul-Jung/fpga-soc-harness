# Makefile — mmio-xadc-pwr-mon
# 타깃: lint, sim, synth
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)

RTL_DIR = rtl
TB_DIR  = tb

TOP     = basys3_top
SIM_TOP = tb_xadc_pwr_mon

RTL_SRCS = \
    $(RTL_DIR)/xadc_pwr_mon_ip.v \
    $(RTL_DIR)/basys3_top.v

SIM_SRCS = \
    $(RTL_DIR)/xadc_pwr_mon_ip.v \
    $(TB_DIR)/tb_xadc_pwr_mon.v

.PHONY: all lint sim synth clean build

all: lint sim synth

# ============================================================
# lint: verilator --lint-only
# XADC 프리미티브 블랙박스로 처리 (-DSIMULATION 없이)
# ============================================================
lint: build
	@echo "=== Lint: verilator ==="
	verilator --lint-only -Wall \
	    --top-module xadc_pwr_mon_ip \
	    $(RTL_DIR)/xadc_pwr_mon_ip.v \
	    && echo "Lint PASS" || echo "Lint FAIL"

# ============================================================
# sim: iverilog + vvp (모의 DRP 모델 포함)
# ============================================================
sim: build
	@echo "=== Sim: $(SIM_TOP) ==="
	iverilog -g2001 -Wall \
	    -DSIMULATION \
	    -o build/$(SIM_TOP).vvp \
	    $(SIM_SRCS) \
	    && vvp build/$(SIM_TOP).vvp \
	    && echo "Sim PASS" || echo "Sim FAIL"

# ============================================================
# synth: yosys (Xilinx 대상, XADC 프리미티브 블랙박스)
# ============================================================
synth: build
	@echo "=== Synth: yosys ==="
	yosys -q -p " \
	    read_verilog $(RTL_DIR)/xadc_pwr_mon_ip.v; \
	    synth_xilinx -top xadc_pwr_mon_ip -flatten; \
	    stat" \
	    && echo "Synth PASS" || echo "Synth FAIL"

# ============================================================
# clean / build
# ============================================================
clean:
	rm -f build/*.vvp build/*.vcd

build:
	mkdir -p build
