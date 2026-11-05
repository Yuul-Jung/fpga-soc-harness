## Makefile for mmio-bldc-sixstep-ip
## Targets: lint, sim, synth

RTL_FILES = rtl/axil_bldc_sixstep.v rtl/bldc_hall_fsm.v rtl/deadtime_pwm.v
TB_FILES  = tb/tb_bldc_sixstep.v
TOP_SIM   = tb_bldc_sixstep
TOP_SYNTH = axil_bldc_sixstep
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
