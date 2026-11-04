# Makefile — mmio-relay-autotune-ip
# 타깃: lint, sim, synth
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)

RTL_DIR = rtl
TB_DIR  = tb

TOP     = relay_autotune_ip
SIM_TOP = tb_relay_autotune_ip

RTL_SRCS = \
    $(RTL_DIR)/relay_autotune_ip.v

SIM_SRCS = \
    $(RTL_DIR)/relay_autotune_ip.v \
    $(TB_DIR)/tb_relay_autotune_ip.v

.PHONY: all lint sim synth clean build

all: lint sim synth

# ============================================================
# lint: verilator --lint-only
# ============================================================
lint: build
	@echo "=== Lint: verilator ==="
	verilator --lint-only -Wall \
	    --top-module relay_autotune_ip \
	    $(RTL_DIR)/relay_autotune_ip.v \
	    && echo "Lint PASS" || echo "Lint FAIL"

# ============================================================
# sim: iverilog + vvp (1차+지연 모터 모델 포함)
# ============================================================
sim: build
	@echo "=== Sim: $(SIM_TOP) ==="
	iverilog -g2001 -Wall \
	    -o build/$(SIM_TOP).vvp \
	    $(SIM_SRCS) \
	    && vvp build/$(SIM_TOP).vvp \
	    && echo "Sim PASS" || echo "Sim FAIL"

# ============================================================
# synth: yosys (Xilinx 대상)
# ============================================================
synth: build
	@echo "=== Synth: yosys ==="
	yosys -q -p " \
	    read_verilog $(RTL_DIR)/relay_autotune_ip.v; \
	    synth_xilinx -top relay_autotune_ip -flatten; \
	    stat" \
	    && echo "Synth PASS" || echo "Synth FAIL"

# ============================================================
# clean / build
# ============================================================
clean:
	rm -f build/*.vvp build/*.vcd

build:
	mkdir -p build
