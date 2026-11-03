## Makefile — mmio-speed-pi-checker
## 타깃: lint, sim, synth
## 도구: iverilog, verilator, yosys

SLUG   := mmio-speed-pi-checker
CAP    := capstones/$(SLUG)
BUILD  := $(CAP)/build

RTL    := $(CAP)/rtl/basys3_top.v \
          $(CAP)/rtl/soc_top.v \
          $(CAP)/rtl/mmio_bus.v \
          $(CAP)/rtl/gpio.v \
          $(CAP)/rtl/uart_tx.v \
          $(CAP)/rtl/speed_pi_ip.v \
          $(CAP)/rtl/demo_master.v

TB     := $(CAP)/tb/tb_speed_pi.v
TOP_TB := tb_speed_pi
TOP_SYN := basys3_top

.PHONY: all lint sim synth clean

all: lint sim synth

$(BUILD):
	mkdir -p $(BUILD)

# --- 린트 (verilator) ---
lint: $(BUILD)
	verilator --lint-only --Wall -Wno-UNUSED -Wno-DECLFILENAME \
	    --top-module $(TOP_SYN) $(RTL) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

# --- 시뮬레이션 (iverilog) ---
sim: $(BUILD)
	iverilog -g2001 -Wall -Wno-timescale \
	    -o $(BUILD)/sim_$(SLUG) \
	    $(RTL) $(TB) 2>&1 | tee $(BUILD)/iverilog.log
	$(BUILD)/sim_$(SLUG) 2>&1 | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log && echo "sim: PASS" || (echo "sim: FAIL" && exit 1)

# --- 합성 (yosys) ---
synth: $(BUILD)
	yosys -p "read_verilog $(RTL); \
	    synth_xilinx -top $(TOP_SYN) -flatten; \
	    stat; write_json $(BUILD)/synth_$(SLUG).json" \
	    2>&1 | tee $(BUILD)/synth.log
	@echo "synth done"

clean:
	rm -rf $(BUILD)
