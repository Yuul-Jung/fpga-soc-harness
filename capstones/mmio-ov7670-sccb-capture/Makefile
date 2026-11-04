# Makefile — mmio-ov7670-sccb-capture 캡스톤
# 타깃: lint, sim_sccb, sim_capture, sim, synth, all, clean
# 도구: iverilog, vvp, yosys (선택)
# Verilog-2001

SLUG   := mmio-ov7670-sccb-capture
RTL    := rtl/sccb_tx.v rtl/ov7670_capture.v rtl/sync_pulse.v rtl/ov7670_sccb_top.v
TB_SCCB    := tb/tb_sccb_tx.v
TB_CAPTURE := tb/tb_ov7670_capture.v

# iverilog 플래그
IVFLAGS := -g2001 -Wall -Wno-timescale

# yosys 합성 (Basys3 / XC7A35T → yosys synth_xilinx)
YOSYS_SCRIPT := read_verilog $(RTL); \
                synth_xilinx -flatten -top ov7670_sccb_top; \
                stat

.PHONY: all lint sim sim_sccb sim_capture synth clean

all: lint sim

## ---- 린트 (iverilog -tnull) ----
lint:
	@echo "=== LINT: $(SLUG) ==="
	iverilog $(IVFLAGS) -tnull $(RTL)
	@echo "LINT OK"

## ---- 시뮬레이션: sccb_tx ----
sim_sccb: build/sim_sccb.vvp
	@echo "=== SIM: tb_sccb_tx ==="
	vvp build/sim_sccb.vvp
	@echo ""

build/sim_sccb.vvp: $(RTL) $(TB_SCCB)
	@mkdir -p build
	iverilog $(IVFLAGS) -o $@ $(RTL) $(TB_SCCB)

## ---- 시뮬레이션: ov7670_capture ----
sim_capture: build/sim_capture.vvp
	@echo "=== SIM: tb_ov7670_capture ==="
	vvp build/sim_capture.vvp
	@echo ""

build/sim_capture.vvp: $(RTL) $(TB_CAPTURE)
	@mkdir -p build
	iverilog $(IVFLAGS) -o $@ rtl/ov7670_capture.v $(TB_CAPTURE)

## ---- 전체 시뮬레이션 ----
sim: sim_sccb sim_capture
	@echo "=== SIM DONE: $(SLUG) ==="

## ---- 합성 (yosys, 자원 추정) ----
synth: $(RTL)
	@echo "=== SYNTH: $(SLUG) (yosys) ==="
	@mkdir -p build
	yosys -p "$(YOSYS_SCRIPT)" 2>&1 | tee build/synth.log
	@echo "합성 로그: build/synth.log"

## ---- 정리 ----
clean:
	rm -rf build/
	rm -f *.vcd tb_sccb_tx.vcd tb_ov7670_capture.vcd
