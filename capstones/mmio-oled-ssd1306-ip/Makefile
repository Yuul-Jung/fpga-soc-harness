# Makefile — mmio-oled-ssd1306-ip
# 타깃: sim, lint, synth
# 도구: iverilog, verilator, yosys

SLUG   := mmio-oled-ssd1306-ip
RTL    := rtl/spi_master_8b.v rtl/axil_oled_ssd1306.v rtl/basys3_oled_top.v
TB     := tb/tb_axil_oled_ssd1306.v
SYNTH_TOP := axil_oled_ssd1306

.PHONY: all sim lint synth clean

all: sim

# ── 시뮬레이션 (iverilog + vvp) ──────────────────────────
sim: $(RTL) $(TB)
	iverilog -g2001 -Wall -Wno-timescale \
	    -o build/$(SLUG)_tb.vvp \
	    $(RTL) $(TB)
	vvp build/$(SLUG)_tb.vvp
	@echo "--- sim done ---"

# ── 린트 (verilator --lint-only) ─────────────────────────
lint: $(RTL)
	verilator --lint-only -Wall --timing \
	    $(RTL)
	@echo "--- lint done ---"

# ── 합성 추정 (yosys) ────────────────────────────────────
synth: $(RTL)
	yosys -p "read_verilog $(RTL); \
	          synth -top $(SYNTH_TOP); \
	          stat" 2>&1 | tee build/synth_$(SLUG).log
	@echo "--- synth done ---"

# ── 빌드 디렉터리 ────────────────────────────────────────
build:
	mkdir -p build

sim lint synth: build

# ── 정리 ─────────────────────────────────────────────────
clean:
	rm -rf build/
