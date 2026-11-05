# Makefile — mmio-onewire-ds18b20-ip
# 타깃: lint, sim, synth, clean
# 도구: iverilog(lint/sim), yosys(synth)
# 타임스케일: 1ns/1ps

RTL_SRCS  := rtl/axil_onewire_bm.v rtl/basys3_top_onewire.v
TB_SRCS   := tb/tb_onewire_bm.v

SIM_TOP   := tb_onewire_bm
SIM_OUT   := build/sim.vvp
LINT_ARGS := -tnull -Wall -Wno-timescale

YOSYS_SCRIPT := build/synth.ys
SYNTH_LOG    := build/synth.log

.PHONY: all lint sim synth clean

all: lint sim synth

## ── 린트 ──────────────────────────────────────────────────
lint:
	@mkdir -p build
	iverilog $(LINT_ARGS) $(RTL_SRCS) $(TB_SRCS) 2>&1 | tee build/lint.log
	@echo "[lint] 완료: build/lint.log 확인"

## ── 시뮬레이션 ────────────────────────────────────────────
sim: lint
	@mkdir -p build
	iverilog -g2001 -o $(SIM_OUT) \
	    $(RTL_SRCS) $(TB_SRCS)
	vvp $(SIM_OUT) | tee build/sim.log
	@grep -E "^(PASS|FAIL)" build/sim.log || true
	@if grep -q "^FAIL" build/sim.log; then \
	    echo "[sim] 실패 항목이 있습니다. build/sim.log를 확인하세요."; \
	    exit 1; \
	else \
	    echo "[sim] 모든 항목 통과"; \
	fi

## ── 합성 (yosys 추정) ─────────────────────────────────────
synth:
	@mkdir -p build
	@echo "read_verilog $(RTL_SRCS)"                         >  $(YOSYS_SCRIPT)
	@echo "synth_xilinx -top basys3_top_onewire -flatten"   >> $(YOSYS_SCRIPT)
	@echo "stat"                                             >> $(YOSYS_SCRIPT)
	yosys -l $(SYNTH_LOG) $(YOSYS_SCRIPT) 2>&1
	@echo "[synth] 완료: $(SYNTH_LOG) 확인"
	@grep -E "Number of (cells|wires|LUT|FF|BRAM)|Chip area" $(SYNTH_LOG) || true

## ── 정리 ──────────────────────────────────────────────────
clean:
	rm -rf build/

## ── 도움말 ────────────────────────────────────────────────
help:
	@echo "make lint   — RTL 문법 검사 (iverilog -tnull)"
	@echo "make sim    — DS18B20 행동 모델과 T1~T6 시뮬레이션"
	@echo "make synth  — yosys XC7A35T 자원 추정 (Vivado 아님)"
	@echo "make clean  — 빌드 산출물 삭제"
