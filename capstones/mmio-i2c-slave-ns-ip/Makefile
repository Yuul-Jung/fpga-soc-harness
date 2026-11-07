# Makefile — I2C 슬레이브 무클럭스트레칭 AXI4-Lite IP
# 타깃: lint, sim, synth, clean
# 도구: iverilog, vvp, yosys (경로에 있어야 함)

SLUG    := mmio-i2c-slave-ns-ip
BUILD   := build
RTL_SRC := rtl/i2c_slave_ns.v rtl/axil_i2c_slave_ns.v rtl/basys3_top.v
TB_SRC  := tb/tb_i2c_slave_ns.v
TOP_TB  := tb_i2c_slave_ns

.PHONY: all lint sim synth clean

all: lint sim

# ─── 린트 (iverilog -g2001, 컴파일만) ───
lint: $(BUILD)/.lint_ok

$(BUILD)/.lint_ok: $(RTL_SRC) $(TB_SRC)
	mkdir -p $(BUILD)
	iverilog -g2001 -Wall -Wno-timescale \
	    -o $(BUILD)/tb_$(SLUG) \
	    $(RTL_SRC) $(TB_SRC)
	touch $(BUILD)/.lint_ok
	@echo "[lint] OK"

# ─── 시뮬레이션 ───
sim: $(BUILD)/.lint_ok
	vvp $(BUILD)/tb_$(SLUG)

# ─── 합성 (yosys, 자원 추정용) ───
synth: $(RTL_SRC)
	mkdir -p $(BUILD)
	yosys -p " \
	    read_verilog -sv $(RTL_SRC); \
	    synth_xilinx -top basys3_top -flatten -nowidelut; \
	    stat; \
	    write_json $(BUILD)/$(SLUG)_synth.json \
	" 2>&1 | tee $(BUILD)/$(SLUG)_synth.log
	@echo "[synth] 완료. 자원: $(BUILD)/$(SLUG)_synth.log"

# ─── 정리 ───
clean:
	rm -rf $(BUILD)
