# Makefile — INMP441 I2S RX AXI4-Lite IP
# 타깃: lint, sim, synth, clean
# 도구: iverilog, vvp, yosys (경로에 있으면 자동 사용)

SLUG    := mmio-inmp441-i2s-rx-ip
RTL_SRC := rtl/i2s_rx_axil.v rtl/basys3_i2s_rx_top.v
TB_SRC  := tb/tb_i2s_rx_axil.v
SIM_TOP := tb_i2s_rx_axil
SYNTH_TOP := basys3_i2s_rx_top

BUILD   := build
SIM_OUT := $(BUILD)/$(SIM_TOP)
LOG_SIM := $(BUILD)/sim.log
LOG_SYNTH := $(BUILD)/synth.log

.PHONY: all lint sim synth clean

all: lint sim synth

## ─── 디렉터리 ────────────────────────────────────────────
$(BUILD):
	mkdir -p $@

## ─── 린트 (iverilog -Wall) ───────────────────────────────
lint: $(BUILD)
	iverilog -g2001 -Wall -tnull $(RTL_SRC) 2>&1 | tee $(BUILD)/lint.log
	@echo "--- lint done ---"

## ─── 시뮬레이션 ──────────────────────────────────────────
sim: $(BUILD)
	iverilog -g2001 -Wall \
	    -o $(SIM_OUT) \
	    $(RTL_SRC) $(TB_SRC)
	vvp $(SIM_OUT) | tee $(LOG_SIM)
	@grep -q "^PASS" $(LOG_SIM) && echo "SIM PASS" || (echo "SIM FAIL"; exit 1)

## ─── 합성 (yosys 추정) ───────────────────────────────────
synth: $(BUILD)
	yosys -p \
	    'synth_xilinx -top $(SYNTH_TOP) -flatten; stat' \
	    $(RTL_SRC) 2>&1 | tee $(LOG_SYNTH)
	@echo "--- synth done (yosys 추정, Vivado 기준 아님) ---"

## ─── 정리 ───────────────────────────────────────────────
clean:
	rm -rf $(BUILD)
