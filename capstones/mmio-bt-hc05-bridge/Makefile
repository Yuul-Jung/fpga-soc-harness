# Makefile — mmio-bt-hc05-bridge
# 타깃: lint, sim, synth, clean
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)
# CI: .github/workflows/verify.yml 에서 호출한다

RTL_DIR  := rtl
TB_DIR   := tb
BUILD    := build

RTL_SRCS := $(RTL_DIR)/uart_tx.v \
            $(RTL_DIR)/uart_rx.v \
            $(RTL_DIR)/axil_bt_bridge.v

TB_SRC   := $(TB_DIR)/tb_bt_bridge.v
TOP_MOD  := axil_bt_bridge

# ── 린트 (verilator) ────────────────────────────────────────────────
.PHONY: lint
lint:
	@echo "=== lint ==="
	verilator --lint-only -Wall --Wno-UNUSEDSIGNAL \
	    $(RTL_SRCS)
	@echo "lint OK"

# ── 시뮬레이션 (iverilog + vvp) ─────────────────────────────────────
# CLKS_PER_BIT=20 오버라이드: 테스트벤치가 직접 처리 (localparam CPB=20)
# iverilog는 tb의 파라미터 오버라이드를 그대로 쓴다.
.PHONY: sim
sim: $(BUILD)/.sim_stamp

$(BUILD)/.sim_stamp: $(RTL_SRCS) $(TB_SRC) | $(BUILD)
	@echo "=== sim ==="
	iverilog -g2001 -Wall -o $(BUILD)/sim_bt_bridge \
	    $(RTL_SRCS) $(TB_SRC)
	vvp $(BUILD)/sim_bt_bridge | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log || \
	    (echo "FAIL: 시뮬레이션 출력에 PASS: 가 없음"; exit 1)
	@touch $@
	@echo "sim OK"

# ── 합성 자원 추정 (yosys) ──────────────────────────────────────────
.PHONY: synth
synth: $(BUILD)/synth.log

$(BUILD)/synth.log: $(RTL_SRCS) | $(BUILD)
	@echo "=== synth ==="
	yosys -Q -p " \
	    read_verilog $(RTL_SRCS); \
	    synth_xilinx -top $(TOP_MOD) -flatten; \
	    stat" \
	    > $@ 2>&1 || (cat $@; exit 1)
	@grep -E "(Cells|LUT|FF|BRAM|DSP)" $(BUILD)/synth.log || true
	@echo "synth OK — 자세한 내용: $(BUILD)/synth.log"

# ── 빌드 디렉토리 ───────────────────────────────────────────────────
$(BUILD):
	mkdir -p $@

# ── 정리 ────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	rm -rf $(BUILD)

# ── 기본 타깃 ────────────────────────────────────────────────────────
.PHONY: all
all: lint sim synth
