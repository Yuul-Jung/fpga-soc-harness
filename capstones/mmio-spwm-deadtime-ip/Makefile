# Makefile — mmio-spwm-deadtime-ip
# 타깃: lint sim synth
# 도구: verilator(lint), iverilog+vvp(시뮬), yosys(합성)

RTL_SRC   = rtl/spwm_ip.v
TOP_SIM   = tb/tb_spwm_ip.v
TB_TOP    = tb_spwm_ip
SIM_OUT   = build/sim.vvp
SIM_LOG   = build/sim.log
SYNTH_LOG = build/synth.log
STATUS_JSON = build/status.json

.PHONY: all lint sim synth clean

all: lint sim synth

# --- 린트 (verilator) ---
lint:
	@mkdir -p build
	verilator --lint-only -Wall --no-timing \
		$(RTL_SRC) \
		--top-module spwm_ip \
		2>&1 | tee build/lint.log
	@echo "lint done"

# --- 시뮬레이션 (iverilog + vvp) ---
sim: $(SIM_OUT)
	@mkdir -p build
	vvp $(SIM_OUT) | tee $(SIM_LOG)
	@grep -q "^PASS: ALL" $(SIM_LOG) && echo "sim PASS" || (echo "sim FAIL"; exit 1)

$(SIM_OUT): $(RTL_SRC) $(TOP_SIM)
	@mkdir -p build
	iverilog -g2001 -Wall -o $(SIM_OUT) $(TOP_SIM) $(RTL_SRC)

# --- 합성 (yosys) ---
synth:
	@mkdir -p build
	yosys -p "read_verilog $(RTL_SRC); \
		synth_xilinx -top spwm_ip -flatten; \
		stat; \
		write_json build/synth.json" \
		2>&1 | tee $(SYNTH_LOG)
	@echo "synth done"

clean:
	rm -rf build/
