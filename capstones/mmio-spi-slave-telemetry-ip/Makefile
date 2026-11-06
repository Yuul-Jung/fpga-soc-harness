## Makefile — mmio-spi-slave-telemetry-ip
## 대상: lint, sim, synth
## 도구: iverilog(lint/sim), yosys(synth)

RTL_FILES = rtl/basys3_top.v rtl/soc_top.v rtl/axil_spi_slave.v
TB_FILES  = tb/tb_axil_spi_slave.v

.PHONY: all lint sim synth clean

all: lint sim synth

## 린트: iverilog -Wall -Wno-timescale
lint:
	iverilog -Wall -Wno-timescale -g2001 -o /dev/null $(RTL_FILES)

## 시뮬레이션: 테스트벤치 실행 (PASS/FAIL 출력 확인)
sim:
	iverilog -Wall -Wno-timescale -g2001 -o /tmp/tb_axil_spi_slave $(TB_FILES) $(RTL_FILES)
	vvp /tmp/tb_axil_spi_slave
	@echo "--- sim done ---"

## 합성: yosys (Xilinx 대상, 자원 추정)
synth:
	yosys -p "read_verilog -sv $(RTL_FILES); \
	          synth_xilinx -top basys3_top -flatten; \
	          stat" 2>&1 | tee /tmp/synth_spi_slave.log
	@grep -E "Number of|LUT|Flip-Flop|BRAM" /tmp/synth_spi_slave.log || true

clean:
	rm -f /tmp/tb_axil_spi_slave /tmp/synth_spi_slave.log
