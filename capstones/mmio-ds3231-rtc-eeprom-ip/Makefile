# Makefile — mmio-ds3231-rtc-eeprom-ip
# Targets: lint | sim | synth | all | clean

RTL  = rtl/axil_i2c_rtc_log.v rtl/basys3_top_ds3231.v
TB   = tb/tb_i2c_rtc_log.v
SIM_OUT = build/sim.out

.PHONY: all lint sim synth clean

all: lint sim synth

lint:
	@mkdir -p build
	verilator --lint-only -Wall $(RTL) 2>&1 | tee build/lint.log
	@echo "lint done"

sim:
	@mkdir -p build
	iverilog -g2001 -o $(SIM_OUT) $(TB) $(RTL)
	vvp $(SIM_OUT) | tee build/sim.log
	@grep -q "^PASS" build/sim.log || (echo "FAIL: sim log has no PASS line" && exit 1)

synth:
	@mkdir -p build
	yosys -p "read_verilog $(RTL); \
	          synth_xilinx -top basys3_top_ds3231 -flatten; \
	          stat; \
	          write_json build/synth.json" \
	      2>&1 | tee build/synth.log
	@echo "synth done"

clean:
	rm -rf build/
