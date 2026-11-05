# Makefile — mmio-rc-car-arb-ip
# 타깃: lint, sim, synth, clean
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)
# CI: .github/workflows/verify.yml 에서 호출한다

RTL_DIR  := rtl
TB_DIR   := tb
BUILD    := build

RTL_SRCS := $(RTL_DIR)/hcsr04_drv.v \
            $(RTL_DIR)/servo_pwm.v \
            $(RTL_DIR)/scan_fsm.v \
            $(RTL_DIR)/arb_fsm.v \
            $(RTL_DIR)/motor_ctrl.v \
            $(RTL_DIR)/axil_rc_arb.v

TB_SRC   := $(TB_DIR)/tb_rc_car_arb.v
TOP_MOD  := axil_rc_arb

# ── 린트 (verilator) ────────────────────────────────────────────────
.PHONY: lint
lint:
	@echo "=== lint ==="
	verilator --lint-only -Wall --Wno-UNUSEDSIGNAL --Wno-WIDTH \
	    -g2001 $(RTL_SRCS)
	@echo "lint OK"

# ── 시뮬레이션 (iverilog + vvp) ─────────────────────────────────────
.PHONY: sim
sim: $(BUILD)/.sim_stamp

$(BUILD)/.sim_stamp: $(RTL_SRCS) $(TB_SRC) | $(BUILD)
	@echo "=== sim ==="
	iverilog -g2001 -Wall -o $(BUILD)/sim_tb \
	    $(RTL_SRCS) $(TB_SRC)
	vvp $(BUILD)/sim_tb | tee $(BUILD)/sim.log
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
	    read_verilog -sv $(RTL_SRCS); \
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
