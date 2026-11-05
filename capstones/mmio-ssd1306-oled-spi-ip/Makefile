# Makefile — mmio-ssd1306-oled-spi-ip
# 타깃: lint, sim, synth, clean
#
# 도구: iverilog, vvp, verilator, yosys
# 출력: build/

SLUG      := mmio-ssd1306-oled-spi-ip
RTL_TOP   := axil_ssd1306_spi
WRAP_TOP  := basys3_top_ssd1306
TB_TOP    := tb_ssd1306_spi

RTL_SRCS  := rtl/axil_ssd1306_spi.v rtl/basys3_top_ssd1306.v
TB_SRCS   := tb/tb_ssd1306_spi.v

BUILD_DIR := build

.PHONY: all lint sim synth clean

all: lint sim synth

## 린트 (verilator)
lint: $(BUILD_DIR)
	verilator --lint-only -Wall --no-timing \
	    $(RTL_SRCS)
	@echo "LINT: OK"

## 시뮬레이션 (iverilog + vvp)
sim: $(BUILD_DIR)
	iverilog -g2001 \
	    -o $(BUILD_DIR)/$(SLUG)_sim.vvp \
	    rtl/axil_ssd1306_spi.v \
	    $(TB_SRCS)
	vvp $(BUILD_DIR)/$(SLUG)_sim.vvp
	@echo "SIM: done"

## 합성 (yosys, 자원 추정)
synth: $(BUILD_DIR)
	yosys -q -p \
	    "read_verilog $(RTL_SRCS); \
	     synth_xilinx -flatten -top $(RTL_TOP); \
	     stat; \
	     write_json $(BUILD_DIR)/$(SLUG)_synth.json" \
	2>&1 | tee $(BUILD_DIR)/$(SLUG)_synth.log
	@echo "SYNTH: done — see $(BUILD_DIR)/$(SLUG)_synth.log"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
