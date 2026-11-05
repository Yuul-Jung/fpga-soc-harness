## Makefile — mmio-jstk2-servo-ip
## 타깃: lint, sim, synth

IVERILOG  ?= iverilog
VVP       ?= vvp
VERILATOR ?= verilator
YOSYS     ?= yosys

RTL  = rtl/jstk2_spi.v rtl/servo_pwm.v rtl/jstk2_servo_ip.v rtl/basys3_top.v
TB   = tb/tb_jstk2_servo.v
SIM_TOP = tb_jstk2_servo

.PHONY: all lint sim synth clean

all: lint sim

## ── 린트 (verilator) ─────────────────────────────────────────────
lint:
	$(VERILATOR) --lint-only -Wall --top-module basys3_jstk2_servo_top \
	    $(RTL) 2>&1 | tee build/lint.log
	@echo "lint done"

## ── 시뮬레이션 (iverilog + vvp) ─────────────────────────────────
sim: build/sim.vvp
	$(VVP) build/sim.vvp | tee build/sim.log
	@grep -q "^PASS" build/sim.log && echo "sim: PASS" || (echo "sim: FAIL"; exit 1)

build/sim.vvp: $(RTL) $(TB)
	@mkdir -p build
	$(IVERILOG) -g2001 -Wall -o $@ $(RTL) $(TB) -s $(SIM_TOP)

## ── 합성 (yosys) ─────────────────────────────────────────────────
synth: build/synth.json

build/synth.json: $(RTL)
	@mkdir -p build
	$(YOSYS) -p "read_verilog -sv $(RTL); \
	    synth -top basys3_jstk2_servo_top; \
	    stat; \
	    write_json $@" 2>&1 | tee build/synth.log
	@echo "synth done"

clean:
	rm -rf build/
