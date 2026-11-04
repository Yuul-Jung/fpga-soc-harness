# Makefile — mmio-wdt-tier1 빌드 규칙
# I-070 AXI4-Lite 워치독 IP (T1)
# 타깃: lint, sim, synth, clean

RTL_DIR := rtl
TB_DIR  := tb
SIM_TOP := tb_axil_wdt_wrap

RTL_SRCS := $(RTL_DIR)/wdt_core.v \
             $(RTL_DIR)/axil_wdt_wrap.v
TB_SRCS  := $(TB_DIR)/tb_axil_wdt_wrap.v

.PHONY: all lint sim synth clean

all: lint sim

# ── 린트 (iverilog -Wall -g2001) ──────────────────────
lint:
	@echo "=== Lint ==="
	iverilog -Wall -g2001 -t null $(RTL_SRCS)
	iverilog -Wall -g2001 -t null $(RTL_SRCS) $(TB_SRCS)
	@echo "Lint OK"

# ── 시뮬레이션 (iverilog + vvp) ──────────────────────
sim:
	@echo "=== Simulation ==="
	iverilog -g2001 -o /tmp/tb_wdt $(RTL_SRCS) $(TB_SRCS)
	vvp /tmp/tb_wdt | tee /tmp/tb_wdt.log
	@if grep -q "^FAIL" /tmp/tb_wdt.log; then \
		echo "SIMULATION FAILED"; exit 1; \
	elif grep -q "^PASS" /tmp/tb_wdt.log; then \
		echo "SIMULATION PASSED"; \
	else \
		echo "SIMULATION: no PASS/FAIL found"; exit 1; \
	fi

# ── 합성 (yosys, 자원 추정) ───────────────────────────
synth:
	@echo "=== Synthesis (yosys, Xilinx 7-series 추정) ==="
	yosys -p "synth_xilinx -flatten -top axil_wdt_wrap; stat" \
	      $(RTL_SRCS) 2>&1 | tee /tmp/synth_wdt.log
	@echo "Synthesis done (see /tmp/synth_wdt.log)"

# ── 정리 ─────────────────────────────────────────────
clean:
	rm -f /tmp/tb_wdt /tmp/tb_wdt.log /tmp/synth_wdt.log
