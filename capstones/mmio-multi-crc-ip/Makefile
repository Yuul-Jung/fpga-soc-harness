# Makefile — mmio-multi-crc-ip
# 타깃: lint, sim, synth
# 도구: iverilog(시뮬), yosys(합성 추정)
# 출력: build/ 폴더

RTL_SRCS = rtl/crc8_core.v rtl/crc16_core.v rtl/crc32_core.v rtl/multi_crc_axil.v
TB_SRCS  = tb/tb_multi_crc_axil.v
BUILD    = build

.PHONY: all lint sim synth clean

all: lint sim synth

$(BUILD):
	mkdir -p $(BUILD)

# ----------------------------------------------------------------
# Lint: iverilog -t null (파싱 + 미결 참조 검사)
# ----------------------------------------------------------------
lint: $(BUILD)
	iverilog -g2001 -Wall -t null $(RTL_SRCS)
	@echo "LINT PASS"

# ----------------------------------------------------------------
# Simulation: iverilog + vvp
# ----------------------------------------------------------------
sim: $(BUILD)
	iverilog -g2001 -Wall -o $(BUILD)/tb_multi_crc_axil.vvp $(RTL_SRCS) $(TB_SRCS)
	vvp $(BUILD)/tb_multi_crc_axil.vvp | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log && echo "SIM PASS" || (echo "SIM FAIL"; exit 1)

# ----------------------------------------------------------------
# Synthesis estimate: yosys (resource count only, not for timing)
# ----------------------------------------------------------------
synth: $(BUILD)
	yosys -p "read_verilog -sv $(RTL_SRCS); \
		synth -top multi_crc_axil -flatten; \
		stat" 2>&1 | tee $(BUILD)/synth.log
	@echo "SYNTH DONE (see $(BUILD)/synth.log for resource estimate)"

clean:
	rm -rf $(BUILD)
