# Makefile — mmio-xadc-hub-checker
# 타깃: lint, sim, synth
# 도구: verilator(lint), iverilog+vvp(sim), yosys(synth)

RTL_DIR = rtl
TB_DIR  = tb

TOP     = basys3_xadc_hub_top
SIM_TOP_DRP = tb_xadc_drp_ctrl
SIM_TOP_HUB = tb_xadc_hub

RTL_SRCS = \
    $(RTL_DIR)/xadc_drp_ctrl.v \
    $(RTL_DIR)/xadc_avg.v \
    $(RTL_DIR)/xadc_regs.v \
    $(RTL_DIR)/xadc_hub.v \
    $(RTL_DIR)/xadc_hub_soc.v \
    $(RTL_DIR)/basys3_xadc_hub_top.v \
    $(RTL_DIR)/demo_master.v

# 시뮬레이션에서 XADC 모의 모델 포함 (tb 내 또는 tb_drp에 선언)
SIM_SRCS_DRP = \
    $(RTL_DIR)/xadc_drp_ctrl.v \
    $(TB_DIR)/tb_xadc_drp_ctrl.v

SIM_SRCS_HUB = \
    $(RTL_DIR)/xadc_drp_ctrl.v \
    $(RTL_DIR)/xadc_avg.v \
    $(RTL_DIR)/xadc_regs.v \
    $(RTL_DIR)/xadc_hub.v \
    $(TB_DIR)/tb_xadc_hub.v

.PHONY: all lint sim synth clean

all: lint sim synth

# ============================================================
# lint: verilator --lint-only
# XADC 프리미티브는 시뮬레이션 플래그로 대체
# ============================================================
lint:
	@echo "=== Lint: verilator ==="
	verilator --lint-only -Wall \
	    --top-module $(RTL_DIR)/xadc_hub_soc \
	    -DSIMULATION \
	    $(RTL_DIR)/xadc_drp_ctrl.v \
	    $(RTL_DIR)/xadc_avg.v \
	    $(RTL_DIR)/xadc_regs.v \
	    $(RTL_DIR)/xadc_hub.v \
	    $(RTL_DIR)/xadc_hub_soc.v \
	    $(RTL_DIR)/demo_master.v \
	    && echo "Lint PASS" || echo "Lint FAIL"

# ============================================================
# sim: iverilog + vvp
# ============================================================
sim: sim_drp sim_hub

sim_drp:
	@echo "=== Sim: tb_xadc_drp_ctrl ==="
	iverilog -g2001 -Wall \
	    -DSIMULATION \
	    -o build/$(SIM_TOP_DRP).vvp \
	    $(SIM_SRCS_DRP) \
	    && vvp build/$(SIM_TOP_DRP).vvp \
	    && echo "Sim drp_ctrl PASS" || echo "Sim drp_ctrl FAIL"

sim_hub:
	@echo "=== Sim: tb_xadc_hub ==="
	iverilog -g2001 -Wall \
	    -DSIMULATION \
	    -o build/$(SIM_TOP_HUB).vvp \
	    $(SIM_SRCS_HUB) \
	    && vvp build/$(SIM_TOP_HUB).vvp \
	    && echo "Sim hub PASS" || echo "Sim hub FAIL"

# ============================================================
# synth: yosys (Xilinx 대상, XADC는 블랙박스)
# ============================================================
synth:
	@echo "=== Synth: yosys ==="
	yosys -p "read_verilog $(RTL_DIR)/xadc_drp_ctrl.v \
	    $(RTL_DIR)/xadc_avg.v \
	    $(RTL_DIR)/xadc_regs.v \
	    $(RTL_DIR)/xadc_hub.v \
	    $(RTL_DIR)/xadc_hub_soc.v \
	    $(RTL_DIR)/basys3_xadc_hub_top.v \
	    $(RTL_DIR)/demo_master.v; \
	    synth_xilinx -top $(TOP) -flatten; \
	    stat" \
	    && echo "Synth PASS" || echo "Synth FAIL"

# ============================================================
# clean
# ============================================================
clean:
	rm -f build/*.vvp build/*.vcd
	mkdir -p build

build:
	mkdir -p build
