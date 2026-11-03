## Makefile — mmio-speed-pi-checker
## 타깃: lint, sim, synth, clean
## 의존 도구: verilator, iverilog/vvp, yosys
## ※ make -C capstones/mmio-speed-pi-checker 로 실행됨 (상대경로 기준)

RTL_DIR = rtl
TB_DIR  = tb
BUILD   = build

RTL_SRC = $(RTL_DIR)/mmio_bus.v \
          $(RTL_DIR)/gpio.v \
          $(RTL_DIR)/uart_tx.v \
          $(RTL_DIR)/speed_pi_ip.v \
          $(RTL_DIR)/soc_top.v \
          $(RTL_DIR)/demo_master.v \
          $(RTL_DIR)/basys3_top.v

TB_SRC  = $(RTL_DIR)/mmio_bus.v \
          $(RTL_DIR)/gpio.v \
          $(RTL_DIR)/uart_tx.v \
          $(RTL_DIR)/speed_pi_ip.v \
          $(RTL_DIR)/soc_top.v

TB_FILE = $(TB_DIR)/tb_speed_pi.v

.PHONY: all lint sim synth clean

all: lint sim synth

lint:
	mkdir -p $(BUILD)
	verilator --lint-only -Wall -Wno-fatal \
	  --top-module basys3_top $(RTL_SRC) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

sim:
	mkdir -p $(BUILD)
	iverilog -g2005 -Wall -Wno-timescale \
	  -o $(BUILD)/sim.vvp $(TB_FILE) $(TB_SRC)
	vvp $(BUILD)/sim.vvp | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log || \
	  (echo "ERROR: simulation did not output PASS"; exit 1)
	@echo "sim done"

synth:
	mkdir -p $(BUILD)
	yosys -q -p "read_verilog $(RTL_SRC); synth_xilinx -top basys3_top -family xc7; stat;" \
	  2>&1 | tee $(BUILD)/synth.log
	@echo "synth done"

clean:
	rm -rf $(BUILD)
