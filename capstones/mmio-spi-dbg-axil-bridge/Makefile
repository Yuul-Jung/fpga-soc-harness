# Makefile — mmio-spi-dbg-axil-bridge
# Targets: lint, sim, synth
# Tools:   iverilog, vvp, verilator, yosys

RTL_DIR  := rtl
TB_DIR   := tb
SIM_OUT  := build/sim

SOURCES  := $(RTL_DIR)/axil_spi_dbg_bridge.v \
            $(RTL_DIR)/soc_top.v \
            $(RTL_DIR)/basys3_top.v

TB_SRC   := $(TB_DIR)/tb_spi_dbg_axil_bridge.v

.PHONY: all lint sim synth clean

all: lint sim

# --- Lint: iverilog syntax check (no simulation) ---
lint:
	@mkdir -p build
	iverilog -g2001 -Wall -t null $(SOURCES) $(TB_SRC)
	@echo "lint: OK"

# --- Simulation: iverilog + vvp ---
sim:
	@mkdir -p $(SIM_OUT)
	iverilog -g2001 -Wall \
	    -o $(SIM_OUT)/tb_spi_dbg.vvp \
	    $(TB_SRC) \
	    $(RTL_DIR)/axil_spi_dbg_bridge.v
	vvp $(SIM_OUT)/tb_spi_dbg.vvp | tee $(SIM_OUT)/sim.log
	@grep -q "^PASS" $(SIM_OUT)/sim.log || (echo "FAIL: simulation did not PASS"; exit 1)
	@echo "sim: PASS"

# --- Synthesis: yosys (resource estimate, XC7A35T) ---
synth:
	@mkdir -p build/synth
	yosys -p " \
	    read_verilog -sv $(SOURCES); \
	    synth_xilinx -top basys3_top -flatten; \
	    stat; \
	    write_json build/synth/basys3_top.json" \
	    > build/synth/yosys.log 2>&1 || (cat build/synth/yosys.log; exit 1)
	@echo "synth: OK (see build/synth/yosys.log for resource estimate)"

clean:
	rm -rf build/
