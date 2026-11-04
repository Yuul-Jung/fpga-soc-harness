# Makefile — mmio-i2c-master-ip
# 타깃: lint (verilator), sim (iverilog+vvp), synth (yosys)

RTL_DIR  := rtl
TB_DIR   := tb
BUILD    := build

RTL_IP   := $(RTL_DIR)/i2c_master_ip.v
RTL_SOC  := $(RTL_DIR)/mmio_bus.v \
             $(RTL_DIR)/demo_master.v \
             $(RTL_DIR)/soc_top.v \
             $(RTL_DIR)/basys3_top.v
TB_SRC   := $(TB_DIR)/tb_i2c_master.v

TOP_SIM  := tb_i2c_master
TOP_SYNTH := i2c_master_ip

.PHONY: all lint sim synth clean

all: lint sim synth

$(BUILD):
	mkdir -p $(BUILD)

## Verilator 린트 (Verilog-2001, 경고=오류)
lint: $(BUILD)
	verilator --lint-only -Wall --Wno-UNUSEDSIGNAL --Wno-UNUSEDPARAM \
	    -Wno-STMTDLY \
	    $(RTL_IP) $(RTL_SOC) 2>&1 | tee $(BUILD)/lint.log
	@if grep -q '%Error' $(BUILD)/lint.log; then \
	    echo "LINT FAIL"; exit 1; \
	else \
	    echo "LINT PASS"; \
	fi

## iverilog 시뮬레이션 (Verilog-2001)
sim: $(BUILD)
	iverilog -g2001 -Wall -o $(BUILD)/sim.vvp \
	    $(RTL_IP) $(TB_SRC) 2>&1 | tee $(BUILD)/sim_compile.log
	vvp $(BUILD)/sim.vvp 2>&1 | tee $(BUILD)/sim.log
	@if grep -q '^PASS' $(BUILD)/sim.log; then \
	    echo "SIM PASS"; \
	elif grep -q '^FAIL' $(BUILD)/sim.log; then \
	    echo "SIM FAIL"; exit 1; \
	else \
	    echo "SIM FAIL (no PASS/FAIL marker)"; exit 1; \
	fi

## Yosys 합성 (자원 추정)
synth: $(BUILD)
	yosys -p " \
	    read_verilog -sv $(RTL_IP); \
	    synth_xilinx -top $(TOP_SYNTH) -flatten; \
	    stat; \
	" 2>&1 | tee $(BUILD)/synth.log
	@echo "SYNTH done — 자원은 yosys 추정 (Vivado와 다를 수 있음)"

clean:
	rm -rf $(BUILD)
