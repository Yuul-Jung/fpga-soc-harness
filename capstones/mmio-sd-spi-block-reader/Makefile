# 단계: lint(verilator) → sim(iverilog, 테스트벤치 2개) → synth(yosys, 자원 추정). Vivado 빌드는 capstone.json의 howto를 따른다.
RTL_ALL = rtl/spi_byte.v rtl/sd_spi.v rtl/mmio_bus.v rtl/gpio.v rtl/uart_tx.v rtl/soc_top.v rtl/demo_master.v rtl/basys3_top.v
RTL_SOC = rtl/spi_byte.v rtl/sd_spi.v rtl/mmio_bus.v rtl/gpio.v rtl/uart_tx.v rtl/soc_top.v
MODEL   = tb/sd_card_model.v

.PHONY: lint sim synth clean build
build:
	mkdir -p build

lint: build
	verilator --lint-only -Wall -Wno-fatal --top-module basys3_top $(RTL_ALL) 2>&1 | tee build/lint.log
	@! grep -q "%Error" build/lint.log

sim: build
	iverilog -g2005 -o build/sim_sd.vvp tb/tb_sd.v $(MODEL) $(RTL_SOC)
	iverilog -g2005 -o build/sim_demo.vvp tb/tb_demo.v $(MODEL) $(RTL_SOC) rtl/demo_master.v
	vvp build/sim_sd.vvp | tee build/sim.log
	vvp build/sim_demo.vvp | tee -a build/sim.log
	@test "$$(grep -c '^PASS' build/sim.log)" = "2" && ! grep -q "^FAIL" build/sim.log

synth: build
	yosys -q -l build/synth.log -p "read_verilog $(RTL_ALL); synth_xilinx -top basys3_top -family xc7; stat"
	@grep -E "LUT|FDRE|FDCE|FDPE|RAM|Number of cells" build/synth.log | tail -12

clean:
	rm -rf build
