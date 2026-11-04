# 단계: lint(verilator) → sim(iverilog) → synth(yosys, 자원 추정). Vivado 빌드는 howto 참고.
RTL_ALL = rtl/loop_jitter_mon.v rtl/basys3_jitter_mon_top.v
RTL_IP  = rtl/loop_jitter_mon.v
TB      = tb/tb_loop_jitter_mon.v

.PHONY: lint sim synth clean
build:
	mkdir -p build

lint: build
	verilator --lint-only -Wall -Wno-fatal --top-module basys3_jitter_mon_top $(RTL_ALL) 2>&1 | tee build/lint.log
	@! grep -q "%Error" build/lint.log

sim: build
	iverilog -g2005 -o build/sim.vvp $(TB) $(RTL_IP)
	vvp build/sim.vvp | tee build/sim.log
	@grep -q "^PASS" build/sim.log && ! grep -q "^FAIL" build/sim.log

synth: build
	yosys -q -l build/synth.log -p "read_verilog $(RTL_ALL); synth_xilinx -top basys3_jitter_mon_top -family xc7; stat"
	@grep -E "LUT|FDRE|FDCE|FDPE|Number of cells" build/synth.log | tail -12

clean:
	rm -rf build
