# Makefile — lint / sim / synth for mmio-sensor-hub-nmea-ip
# Tools required: iverilog + vvp, verilator, yosys
# Simulation uses small parameters for speed:
#   CLK_HZ=10_000, I2C_HZ=1_000, BAUD=1_000
#   => I2C_HALF=4 (5 clk/step), BAUD_CNT=9 (10 clk/bit)

RTL  = rtl/sensor_hub_top.v
TB   = tb/tb_sensor_hub_nmea.v
TOP  = sensor_hub_top
TBOP = tb_sensor_hub_nmea

.PHONY: all sim lint synth clean

all: sim

# ─── Simulation (iverilog + vvp) ─────────────────────────────────────────────
sim: $(RTL) $(TB)
	iverilog -g2001 -Wall \
		-o build/$(TBOP).vvp \
		$(TB) $(RTL) && \
	vvp build/$(TBOP).vvp | tee build/sim.log
	@grep -q "^PASS" build/sim.log && echo "sim: PASS" || \
		(echo "sim: FAIL — see build/sim.log" && exit 1)

# ─── Lint (verilator) ─────────────────────────────────────────────────────────
lint: $(RTL)
	verilator --lint-only -Wall --top-module $(TOP) $(RTL)

# ─── Synthesis resource estimate (yosys, not Vivado) ─────────────────────────
synth: $(RTL)
	yosys -p "read_verilog -sv $(RTL); \
		synth_xilinx -top $(TOP) -flatten; \
		stat" 2>&1 | tee build/synth.log
	@echo "synth: done — see build/synth.log (yosys estimate, not Vivado)"

# ─── Helpers ──────────────────────────────────────────────────────────────────
build:
	mkdir -p build

sim:   build
lint:
synth: build

clean:
	rm -rf build/
