# Makefile — mmio-fir-q1p15-mac-ip
# capstone: Basys3 Q1.15 FIR MAC IP (stage T4)
# 타깃: lint, sim, synth

RTL_FILES  = rtl/fir_core.v rtl/axil_fir_wrap.v
TB_FILES   = tb/tb_fir.v
TOP_SIM    = tb_fir
TOP_SYNTH  = basys3_top

BUILD_DIR  = build
SIM_OUT    = $(BUILD_DIR)/sim_fir
SYNTH_LOG  = $(BUILD_DIR)/synth.log
STATUS_JSON= $(BUILD_DIR)/status.json

.PHONY: all lint sim synth clean

all: lint sim synth

# ── 디렉터리 생성 ──────────────────────────────
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ── 린트 (verilator) ──────────────────────────
lint: $(BUILD_DIR)
	verilator --lint-only -Wall --Wno-UNUSED --Wno-DECLFILENAME \
	  -DVERILATOR $(RTL_FILES) 2>&1 | tee $(BUILD_DIR)/lint.log
	@echo "lint done"

# ── 시뮬레이션 (iverilog + vvp) ───────────────
sim: $(BUILD_DIR)
	iverilog -g2001 -o $(SIM_OUT) $(TB_FILES) $(RTL_FILES)
	vvp $(SIM_OUT) | tee $(BUILD_DIR)/sim.log
	@grep -q "^PASS" $(BUILD_DIR)/sim.log && \
	  echo "sim: PASS" || (echo "sim: FAIL" && exit 1)

# ── 합성 (yosys xilinx) ───────────────────────
synth: $(BUILD_DIR)
	yosys -p "read_verilog $(RTL_FILES); \
	  synth_xilinx -top $(TOP_SYNTH) -flatten; \
	  stat" \
	  2>&1 | tee $(SYNTH_LOG)
	@grep -q "Number of cells" $(SYNTH_LOG) && \
	  echo "synth: OK" || (echo "synth: FAIL" && exit 1)

# ── 상태 JSON 생성 (run_verify.py 호환) ────────
status: $(BUILD_DIR)
	python3 ../../tools/run_verify.py \
	  --capstone mmio-fir-q1p15-mac-ip \
	  --build-dir $(BUILD_DIR) 2>&1 || true

# ── 정리 ───────────────────────────────────────
clean:
	rm -rf $(BUILD_DIR) *.vcd *.fst
