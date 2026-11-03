## mmio-i2s-tx-checker Makefile
## 타깃: lint (verilator), sim (iverilog+vvp), synth (yosys)
## CI는 이 파일을 사용하므로 경로·이름을 바꾸지 않는다.

RTL_DIR  = rtl
TB_DIR   = tb
BUILD    = build

## SoC 전체 RTL (합성·린트 대상)
RTL_ALL  = $(RTL_DIR)/i2s_clk_gen.v \
           $(RTL_DIR)/i2s_tx.v \
           $(RTL_DIR)/mmio_bus.v \
           $(RTL_DIR)/gpio.v \
           $(RTL_DIR)/uart_tx.v \
           $(RTL_DIR)/demo_master.v \
           $(RTL_DIR)/soc_top.v \
           $(RTL_DIR)/basys3_top.v

## 시뮬레이션에 필요한 RTL (tb가 직접 사용하는 모듈)
TB_SRC   = $(RTL_DIR)/i2s_clk_gen.v \
           $(RTL_DIR)/i2s_tx.v

TB_FILE  = $(TB_DIR)/tb_i2s.v

.PHONY: all lint sim synth clean

all: lint sim synth

## ---- 린트 (verilator) ----
lint:
	mkdir -p $(BUILD)
	verilator --lint-only -Wall -Wno-fatal \
	    --top-module basys3_top \
	    $(RTL_ALL) \
	    2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

## ---- 시뮬레이션 (iverilog + vvp) ----
sim:
	mkdir -p $(BUILD)
	iverilog -g2005 -Wall \
	    -o $(BUILD)/sim.vvp \
	    $(TB_FILE) $(TB_SRC) \
	    2>&1 | tee $(BUILD)/iverilog.log
	vvp $(BUILD)/sim.vvp 2>&1 | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log || \
	    (echo "FAIL: simulation did not print PASS"; exit 1)
	@echo "sim done"

## ---- 합성 (yosys, Xilinx xc7 흐름) ----
synth:
	mkdir -p $(BUILD)
	yosys -q -p " \
	    read_verilog $(RTL_ALL); \
	    synth_xilinx -top basys3_top -family xc7; \
	    stat; \
	    " 2>&1 | tee $(BUILD)/synth.log
	@echo "synth done"

clean:
	rm -rf $(BUILD)
