# Makefile — UART→AXI4-Lite 브리지 캡스톤
# 타깃: lint sim synth all clean
# 도구: verilator, iverilog/vvp, yosys

RTL_FILES  := rtl/uart_rx.v rtl/uart_tx.v rtl/uart_axilite_bridge.v rtl/basys3_top.v
TB_FILES   := tb/tb_uart_axilite_bridge.v $(RTL_FILES)
BUILD_DIR  := build
SIM_VVP    := $(BUILD_DIR)/sim.vvp
SIM_LOG    := $(BUILD_DIR)/sim.log

.PHONY: all lint sim synth clean

all: lint sim synth

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ── 린트 (verilator) ────────────────────────────────────────────────────────
lint: $(BUILD_DIR)
	verilator --lint-only -Wall -Wno-fatal \
	    --top-module basys3_top $(RTL_FILES) \
	    2>&1 | tee $(BUILD_DIR)/lint.log
	@echo "Lint done."

# ── 시뮬레이션 (iverilog + vvp) ─────────────────────────────────────────────
sim: $(BUILD_DIR)
	iverilog -g2005 -o $(SIM_VVP) $(TB_FILES)
	vvp $(SIM_VVP) | tee $(SIM_LOG)
	@grep -E '^(PASS|FAIL)' $(SIM_LOG) || true

# ── 합성 (yosys) ────────────────────────────────────────────────────────────
synth: $(BUILD_DIR)
	yosys -p " \
	    read_verilog $(RTL_FILES); \
	    synth_xilinx -top basys3_top -family xc7; \
	    stat \
	" 2>&1 | tee $(BUILD_DIR)/synth.log
	@echo "Synth done."

# ── 정리 ────────────────────────────────────────────────────────────────────
clean:
	rm -rf $(BUILD_DIR)
