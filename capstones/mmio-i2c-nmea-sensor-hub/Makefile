## Makefile for mmio-i2c-nmea-sensor-hub
## Targets: lint, sim, synth

RTL_FILES = rtl/axil_i2c_nmea_hub.v rtl/i2c_cycle_fsm.v rtl/nmea_uart_rx.v rtl/ts_fifo.v
TB_FILES  = tb/tb_i2c_nmea_hub.v
TOP_SIM   = tb_i2c_nmea_hub
TOP_SYNTH = axil_i2c_nmea_hub
BUILD_DIR = build

.PHONY: all lint sim synth clean

all: lint sim synth

lint:
	@mkdir -p $(BUILD_DIR)
	verilator --lint-only -Wall --Wno-UNUSEDSIGNAL --top-module $(TOP_SYNTH) $(RTL_FILES) 2>&1 | tee $(BUILD_DIR)/lint.log
	@grep -E "^%Error" $(BUILD_DIR)/lint.log && exit 1 || true

sim:
	@mkdir -p $(BUILD_DIR)
	iverilog -g2001 -o $(BUILD_DIR)/sim_$(TOP_SIM).vvp \
		$(RTL_FILES) $(TB_FILES) -s $(TOP_SIM) 2>&1 | tee $(BUILD_DIR)/sim_compile.log
	vvp $(BUILD_DIR)/sim_$(TOP_SIM).vvp | tee $(BUILD_DIR)/sim_output.log
	@grep -q "^PASS" $(BUILD_DIR)/sim_output.log || (echo "SIMULATION FAILED" && exit 1)

synth:
	@mkdir -p $(BUILD_DIR)
	@echo "read_verilog $(RTL_FILES)" > $(BUILD_DIR)/synth.ys
	@echo "synth -top $(TOP_SYNTH) -flatten" >> $(BUILD_DIR)/synth.ys
	@echo "stat" >> $(BUILD_DIR)/synth.ys
	yosys -Q -l $(BUILD_DIR)/synth.log $(BUILD_DIR)/synth.ys
	@echo "Synth complete. See $(BUILD_DIR)/synth.log for resource usage."

clean:
	rm -rf $(BUILD_DIR)
