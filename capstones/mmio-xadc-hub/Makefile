## capstones/mmio-xadc-hub/Makefile
## lint/sim: axil_xadc_hub.v만 대상 (basys3_xadc_top.v는 XADC 프리미티브 미지원)
## synth: yosys로 axil_xadc_hub.v 자원 추정

lint:
	iverilog -g2001 -Wall -Wno-timescale -t null \
		rtl/axil_xadc_hub.v tb/tb_axil_xadc_hub.v

sim: build/
	iverilog -g2001 -Wall -Wno-timescale \
		-o build/sim.vvp \
		rtl/axil_xadc_hub.v tb/tb_axil_xadc_hub.v
	vvp build/sim.vvp

synth: build/
	yosys -p "synth_xilinx -flatten -top axil_xadc_hub; write_json build/synth.json" \
		rtl/axil_xadc_hub.v

build/:
	mkdir -p build

.PHONY: lint sim synth
