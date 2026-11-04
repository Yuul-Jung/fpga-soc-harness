# Makefile — mmio-i2c3-nmea-hub 빌드 규칙
# I-036 AXI4-Lite I2C 3장치 순회 + NMEA UART 허브 IP
# 타깃: lint, sim, synth, clean

RTL_DIR := rtl
TB_DIR  := tb
SIM_TOP := tb_axil_i2c3_nmea_hub

RTL_SRCS := $(RTL_DIR)/i2c_rd_byte.v \
             $(RTL_DIR)/axil_i2c3_nmea_hub.v
TB_SRCS  := $(TB_DIR)/tb_axil_i2c3_nmea_hub.v

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
	iverilog -g2001 -o /tmp/tb_hub $(RTL_SRCS) $(TB_SRCS)
	vvp /tmp/tb_hub | tee /tmp/tb_hub.log
	@if grep -q "^FAIL" /tmp/tb_hub.log; then \
		echo "SIMULATION FAILED"; exit 1; \
	elif grep -q "^PASS" /tmp/tb_hub.log; then \
		echo "SIMULATION PASSED"; \
	else \
		echo "SIMULATION: no PASS/FAIL found"; exit 1; \
	fi

# ── 합성 (yosys, 자원 추정) ───────────────────────────
synth:
	@echo "=== Synthesis (yosys, Xilinx 7-series 추정) ==="
	mkdir -p build
	yosys -p "synth_xilinx -flatten -top axil_i2c3_nmea_hub; stat" \
	      $(RTL_SRCS) 2>&1 | tee build/synth.log
	@echo "Synthesis done (see build/synth.log)"

# ── 정리 ─────────────────────────────────────────────
clean:
	rm -f /tmp/tb_hub /tmp/tb_hub.log
	rm -f build/synth.log
