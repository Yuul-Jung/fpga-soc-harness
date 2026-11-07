# Makefile — NEC IR 디코더 AXI4-Lite IP (mmio-ir-nec-decode-ip)
# 대상: lint (verilator), sim (iverilog+vvp), synth (yosys)

RTL_DIR  = rtl
TB_DIR   = tb
SIM_DIR  = build/sim
SYNTH_DIR= build/synth

RTL_SRCS = $(RTL_DIR)/ir_nec_decode.v \
           $(RTL_DIR)/axil_ir_nec_wrap.v \
           $(RTL_DIR)/basys3_top_ir_nec.v
TB_SRCS  = $(TB_DIR)/tb_ir_nec.v
TOP_SIM  = tb_ir_nec
TOP_SYNTH= basys3_top_ir_nec

.PHONY: all lint sim synth clean

all: lint sim synth

## ---------------------------------------------------------------
## 린트 (Verilator, 오류만 표시)
## ---------------------------------------------------------------
lint:
	@echo "=== Lint: Verilator ==="
	verilator --lint-only -Wall \
	    --top-module ir_nec_decode \
	    $(RTL_DIR)/ir_nec_decode.v
	verilator --lint-only -Wall \
	    --top-module axil_ir_nec_wrap \
	    $(RTL_DIR)/ir_nec_decode.v \
	    $(RTL_DIR)/axil_ir_nec_wrap.v
	@echo "Lint OK"

## ---------------------------------------------------------------
## 시뮬레이션 (iverilog + vvp)
## ---------------------------------------------------------------
sim: $(SIM_DIR)/sim.vvp
	@echo "=== Sim: iverilog/vvp ==="
	vvp $(SIM_DIR)/sim.vvp | tee $(SIM_DIR)/sim.log
	@grep -q "ALL PASS" $(SIM_DIR)/sim.log && echo "SIM PASS" || (echo "SIM FAIL"; exit 1)

$(SIM_DIR)/sim.vvp: $(RTL_SRCS) $(TB_SRCS)
	@mkdir -p $(SIM_DIR)
	iverilog -g2001 -Wall -o $@ \
	    $(RTL_DIR)/ir_nec_decode.v \
	    $(RTL_DIR)/axil_ir_nec_wrap.v \
	    $(TB_DIR)/tb_ir_nec.v \
	    -s $(TOP_SIM)

## ---------------------------------------------------------------
## 합성 (Yosys, 자원 추정 — Vivado 수치와 다를 수 있음)
## ---------------------------------------------------------------
synth:
	@echo "=== Synth: Yosys (xc7 자원 추정) ==="
	@mkdir -p $(SYNTH_DIR)
	yosys -p " \
	    read_verilog -sv $(RTL_DIR)/ir_nec_decode.v; \
	    read_verilog -sv $(RTL_DIR)/axil_ir_nec_wrap.v; \
	    read_verilog -sv $(RTL_DIR)/basys3_top_ir_nec.v; \
	    synth_xilinx -top $(TOP_SYNTH) -flatten; \
	    stat -tech xilinx; \
	" 2>&1 | tee $(SYNTH_DIR)/synth.log
	@grep -q "Warnings: 0" $(SYNTH_DIR)/synth.log || true
	@echo "Synth done. 자원은 $(SYNTH_DIR)/synth.log 참조 (yosys 추정, Vivado 수치와 다를 수 있음)"

## ---------------------------------------------------------------
## 정리
## ---------------------------------------------------------------
clean:
	rm -rf build/
