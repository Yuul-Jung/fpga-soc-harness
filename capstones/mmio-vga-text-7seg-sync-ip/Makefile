# Makefile — mmio-vga-text-7seg-sync-ip
# 타깃: lint, sim, synth, all, clean
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)

RTL_DIR  = rtl
TB_DIR   = tb
TOP_IP   = axil_vga_text_7seg_ip
TOP_BOARD= basys3_top_vga_text_7seg
TB_TOP   = tb_axil_vga_text_7seg

RTL_SRCS = $(RTL_DIR)/$(TOP_IP).v
TB_SRCS  = $(TB_DIR)/$(TB_TOP).v $(RTL_SRCS)

BUILD_DIR = build
STATUS_JSON = $(BUILD_DIR)/status.json

.PHONY: all lint sim synth clean

all: lint sim synth

# ─────────────────────────────────────────────
# lint (verilator)
# ─────────────────────────────────────────────
lint:
	@mkdir -p $(BUILD_DIR)
	verilator --lint-only -Wall --top-module $(TOP_IP) $(RTL_SRCS) 2>&1 | tee $(BUILD_DIR)/lint.log
	@echo "lint done"

# ─────────────────────────────────────────────
# sim (iverilog + vvp)
# ─────────────────────────────────────────────
sim: $(BUILD_DIR)/sim.vvp
	vvp $(BUILD_DIR)/sim.vvp 2>&1 | tee $(BUILD_DIR)/sim.log
	@grep -E "^(PASS|FAIL)" $(BUILD_DIR)/sim.log || (echo "FAIL: no PASS/FAIL marker found"; exit 1)
	@grep "^FAIL" $(BUILD_DIR)/sim.log && exit 1 || true

$(BUILD_DIR)/sim.vvp: $(TB_SRCS)
	@mkdir -p $(BUILD_DIR)
	iverilog -o $@ -g2001 -Wall $(TB_SRCS) -s $(TB_TOP)

# ─────────────────────────────────────────────
# synth (yosys — Xilinx 7 시리즈 추정)
# ─────────────────────────────────────────────
synth:
	@mkdir -p $(BUILD_DIR)
	yosys -p "read_verilog $(RTL_SRCS); synth_xilinx -top $(TOP_IP); stat" \
	      2>&1 | tee $(BUILD_DIR)/synth.log
	@echo "synth done"

# ─────────────────────────────────────────────
# clean
# ─────────────────────────────────────────────
clean:
	rm -rf $(BUILD_DIR)
