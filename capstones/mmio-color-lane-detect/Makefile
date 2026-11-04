# Makefile — mmio-color-lane-detect 캡스톤
# 타깃: lint, sim, synth, all, clean
# 도구: iverilog, vvp, yosys (선택)
# Verilog-2001

SLUG   := mmio-color-lane-detect
RTL    := rtl/basys3_color_lane_top.v \
          rtl/color_lane_top.v \
          rtl/ov7670_capture_stub.v \
          rtl/green_thresh.v \
          rtl/grid9_counter.v \
          rtl/lane_decode.v
TB     := tb/tb_color_lane.v

IVFLAGS := -g2001 -Wall -Wno-timescale

YOSYS_SCRIPT := read_verilog $(RTL); \
                synth_xilinx -flatten -top basys3_color_lane_top; \
                stat

.PHONY: all lint sim synth clean

all: lint sim

## ---- 린트 ----
lint:
	@echo "=== LINT: $(SLUG) ==="
	iverilog $(IVFLAGS) -tnull $(RTL)
	@echo "LINT OK"

## ---- 시뮬레이션 ----
sim: build/sim.vvp
	@echo "=== SIM: tb_color_lane ==="
	vvp build/sim.vvp
	@echo ""

build/sim.vvp: $(RTL) $(TB)
	@mkdir -p build
	iverilog $(IVFLAGS) -o $@ $(RTL) $(TB)

## ---- 합성 (yosys) ----
synth: $(RTL)
	@echo "=== SYNTH: $(SLUG) (yosys) ==="
	@mkdir -p build
	yosys -p "$(YOSYS_SCRIPT)" 2>&1 | tee build/synth.log
	@echo "합성 로그: build/synth.log"

## ---- 정리 ----
clean:
	rm -rf build/
	rm -f *.vcd tb_color_lane.vcd
