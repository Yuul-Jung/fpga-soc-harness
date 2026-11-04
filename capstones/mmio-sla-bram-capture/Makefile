# Makefile — mmio-sla-bram-capture (I-067, T2)
# 타깃: lint, sim, synth
# iverilog / verilator / yosys 사용
# HARNESS.md §13.3: 순수 Verilog-2001, CI에서 S1(시뮬)/S2(합성)

RTL_SRCS := rtl/sla_core.v rtl/axil_sla_wrap.v
TB_SRCS  := tb/tb_axil_sla_wrap.v
TOP      := axil_sla_wrap

.PHONY: all lint sim synth clean

all: lint sim synth

## ── 린트: iverilog 컴파일만 (실행 없음) ──────────────────────
lint:
	iverilog -g2001 -Wall -o /dev/null $(RTL_SRCS) $(TB_SRCS)
	@echo "lint: PASS"

## ── 시뮬레이션: iverilog + vvp ───────────────────────────────
sim:
	@mkdir -p build
	iverilog -g2001 -Wall -o build/sim.vvp $(TB_SRCS) $(RTL_SRCS)
	vvp build/sim.vvp | tee build/sim.out
	@if grep -q '^FAIL' build/sim.out; then \
	    echo "SIMULATION FAILED"; exit 1; \
	else \
	    echo "SIMULATION PASSED"; \
	fi

build/sim.vvp: $(TB_SRCS) $(RTL_SRCS)
	@mkdir -p build
	iverilog -g2001 -Wall -o build/sim.vvp $(TB_SRCS) $(RTL_SRCS)

## ── 합성: yosys (자원 추정) ──────────────────────────────────
synth:
	@mkdir -p build
	yosys -q -p 'read_verilog -sv $(RTL_SRCS); \
	    synth_xilinx -top $(TOP) -flatten; \
	    stat' \
	    2>&1 | tee build/synth.log
	@echo "synth: 위 stat 참조 (yosys 추정, Vivado와 다를 수 있음)"

## ── 정리 ─────────────────────────────────────────────────────
clean:
	rm -rf build/

## ── 디렉터리 생성 ─────────────────────────────────────────────
build/:
	mkdir -p build
