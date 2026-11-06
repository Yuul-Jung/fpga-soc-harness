## Makefile — mmio-vga-doublebuf-ip
## 타깃: lint | sim | synth | all | clean

BUILD   := build
TOP_SIM := tb_vga_doublebuf
TOP_SYN := vga_doublebuf

RTL_SRC := rtl/vga_timing.v rtl/vga_doublebuf.v rtl/basys3_top.v
TB_SRC  := tb/tb_vga_doublebuf.v

.PHONY: all lint sim synth clean

all: lint sim synth

## 1) 린트 (verilator)
lint:
	@mkdir -p $(BUILD)
	verilator --lint-only -Wall -Wno-UNUSED -Wno-DECLFILENAME \
	    --top-module vga_doublebuf $(RTL_SRC) 2>&1 | tee $(BUILD)/lint.log
	@echo "--- lint done ---"

## 2) 시뮬레이션 (iverilog + vvp)
sim:
	@mkdir -p $(BUILD)
	iverilog -g2005 -Wall -o $(BUILD)/sim.vvp \
	    $(TB_SRC) $(RTL_SRC) 2>&1 | tee $(BUILD)/iverilog.log
	vvp $(BUILD)/sim.vvp 2>&1 | tee $(BUILD)/sim.log
	@grep -E "^(PASS|FAIL)" $(BUILD)/sim.log || \
	    (echo "FAIL: 시뮬레이션 출력에서 PASS/FAIL을 찾을 수 없음" && exit 1)

## 3) 합성 (yosys — Xilinx 추정 자원)
synth:
	@mkdir -p $(BUILD)
	yosys -p "read_verilog $(RTL_SRC); \
	           synth_xilinx -top $(TOP_SYN); \
	           stat" \
	    2>&1 | tee $(BUILD)/synth.log
	@echo "--- synth done (yosys 추정; Vivado 수치와 다를 수 있음) ---"

clean:
	rm -rf $(BUILD)
