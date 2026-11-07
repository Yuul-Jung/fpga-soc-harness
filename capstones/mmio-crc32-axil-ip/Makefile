# Makefile — CRC-32 AXI4-Lite IP (mmio-crc32-axil-ip)
# 타깃: lint, sim, synth
# 도구: iverilog(lint/sim), vvp, yosys(synth)

SLUG    := mmio-crc32-axil-ip
RTL_DIR := rtl
TB_DIR  := tb

RTL_SRCS := $(RTL_DIR)/crc32_core.v \
            $(RTL_DIR)/crc32_axil.v

TB_SRCS  := $(TB_DIR)/tb_crc32_axil.v

SIM_TOP  := tb_crc32_axil
SIM_OUT  := build/$(SIM_TOP).vvp

.PHONY: all lint sim synth clean

all: lint sim synth

## ----------------------------------------------------------------
## 린트 (iverilog -t null)
## ----------------------------------------------------------------
lint:
	@echo "=== LINT: $(SLUG) ==="
	iverilog -g2001 -Wall -t null $(RTL_SRCS) $(TB_SRCS)
	@echo "LINT OK"

## ----------------------------------------------------------------
## 시뮬레이션
## ----------------------------------------------------------------
$(SIM_OUT): $(RTL_SRCS) $(TB_SRCS)
	@mkdir -p build
	iverilog -g2001 -Wall -o $@ $(RTL_SRCS) $(TB_SRCS)

sim: $(SIM_OUT)
	@echo "=== SIM: $(SLUG) ==="
	vvp $(SIM_OUT) | tee build/sim.log
	@grep -q "^PASS:" build/sim.log && echo "SIM OK" || (echo "SIM FAIL"; exit 1)

## ----------------------------------------------------------------
## 합성 (yosys, 자원 추정)
## ----------------------------------------------------------------
synth:
	@echo "=== SYNTH: $(SLUG) ==="
	@mkdir -p build
	yosys -p "read_verilog -sv $(RTL_SRCS); \
	           synth -top crc32_axil; \
	           stat" \
	      2>&1 | tee build/synth.log
	@echo "SYNTH OK"

## ----------------------------------------------------------------
## 정리
## ----------------------------------------------------------------
clean:
	rm -rf build
