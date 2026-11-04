# Makefile — W5500 UDP TX IP (mmio-w5500-udp-tx-ip)
# 타깃: lint, sim, synth
# 도구: iverilog, vvp, yosys
# Origin: capstones/mmio-w5500-udp-tx-ip/Makefile

RTL_TOP  = rtl/w5500_udp_tx_ip.v
TB       = tb/tb_w5500_udp_tx.v
SIM_OUT  = build/sim_w5500_udp_tx
SYNTH_LOG = build/synth_w5500_udp_tx.log

.PHONY: all lint sim synth clean

all: lint sim

## lint — RTL 문법 검사 (iverilog -tnull)
lint:
	@mkdir -p build
	iverilog -tnull -Wall -Wno-timescale -g2001 $(RTL_TOP)
	@echo "LINT OK: $(RTL_TOP)"

## sim — 가짜 W5500 슬레이브와 UDP TX 검증
sim:
	@mkdir -p build
	iverilog -g2001 -o $(SIM_OUT) $(TB) $(RTL_TOP)
	vvp $(SIM_OUT)

## synth — yosys로 자원 추정 (XC7A35T 기준)
synth:
	@mkdir -p build
	yosys -p "read_verilog -sv $(RTL_TOP); \
	           synth_xilinx -top w5500_udp_tx_ip -flatten; \
	           stat" 2>&1 | tee $(SYNTH_LOG)
	@echo "SYNTH LOG: $(SYNTH_LOG)"

clean:
	rm -rf build/
