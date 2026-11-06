# Makefile — mmio-ble-trilat-ip
# 타깃: lint, sim, synth
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)

SLUG   := mmio-ble-trilat-ip
RTL    := rtl/basys3_top.v rtl/soc_top.v rtl/ble_trilat_ip.v rtl/div32.v rtl/demo_master.v
TB     := tb/tb_ble_trilat_ip.v
SIM_TOP:= tb_ble_trilat_ip
BUILD  := build

.PHONY: all lint sim synth clean

all: lint sim

# ── 린트 (verilator) ────────────────────────────────────────────
lint:
	@mkdir -p $(BUILD)
	verilator --lint-only -Wall --top-module basys3_top $(RTL) 2>&1 | tee $(BUILD)/lint.log
	@echo "lint done"

# ── 시뮬레이션 (iverilog + vvp) ─────────────────────────────────
sim:
	@mkdir -p $(BUILD)
	iverilog -g2001 -Wall -o $(BUILD)/$(SIM_TOP).vvp \
	    rtl/ble_trilat_ip.v rtl/div32.v $(TB)
	vvp $(BUILD)/$(SIM_TOP).vvp | tee $(BUILD)/sim.log
	@grep -E "^(PASS|FAIL)" $(BUILD)/sim.log || true
	@grep -q "^PASS" $(BUILD)/sim.log && echo "sim: PASS" || (echo "sim: FAIL"; exit 1)

# ── 합성 (yosys, 자원 추정) ─────────────────────────────────────
synth:
	@mkdir -p $(BUILD)
	yosys -p "read_verilog -sv $(RTL); \
	          synth_xilinx -top basys3_top -flatten; \
	          stat; \
	          write_json $(BUILD)/$(SLUG).json" \
	      2>&1 | tee $(BUILD)/synth.log
	@echo "synth done (yosys 추정, Vivado 결과와 다를 수 있음)"

clean:
	rm -rf $(BUILD)
