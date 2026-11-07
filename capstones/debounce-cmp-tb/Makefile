## Makefile — debounce-cmp-tb 캡스톤
## 디바운스 3방식 비교 테스트벤치 (lint / sim / synth)

RTL_ALL = rtl/debounce_counter.v rtl/debounce_fsm.v rtl/debounce_sr.v
TB      = tb/tb_debounce_cmp.v

.PHONY: build lint sim synth clean

build:
	mkdir -p build

lint: build
	verilator --lint-only -Wall -Wno-fatal --top-module debounce_counter $(RTL_ALL) 2>&1 | tee build/lint.log
	@! grep -q "%Error" build/lint.log

sim: build
	iverilog -g2005 -o build/sim.vvp $(TB) $(RTL_ALL)
	vvp build/sim.vvp | tee build/sim.log
	@grep -q "^PASS" build/sim.log && ! grep -q "^FAIL" build/sim.log

synth: build
	yosys -q -l build/synth.log -p "read_verilog $(RTL_ALL); synth_xilinx -top debounce_counter -family xc7; stat"
	@grep -E "LUT|FDRE|FDCE|FDPE|Number of cells" build/synth.log | tail -12

clean:
	rm -rf build
