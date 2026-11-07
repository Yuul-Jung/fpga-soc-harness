# Makefile — mmio-mlp-axil-ip capstone
# capstone: mmio-mlp-axil-ip
# 2026-11-08
#
# 타깃:
#   make sim      — iverilog + vvp 시뮬레이션 (PASS/FAIL 출력)
#   make lint     — iverilog -Wall 린트
#   make synth    — yosys 합성 (자원 추정)
#   make clean    — 빌드 파일 삭제

RTL_DIR   := rtl
TB_DIR    := tb
BUILD_DIR := build

RTL_SRCS  := $(RTL_DIR)/relu_int32.v \
             $(RTL_DIR)/argmax_10.v \
             $(RTL_DIR)/mlp_mac_fsm.v \
             $(RTL_DIR)/axil_mlp_infer.v
TB_SRC    := $(TB_DIR)/tb_mlp_axil.v

SIM_TOP   := tb_mlp_axil
SIM_BIN   := $(BUILD_DIR)/sim_mlp_axil

IVERILOG  := iverilog
VVP       := vvp
YOSYS     := yosys

.PHONY: all sim lint synth clean

all: sim

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

lint: $(BUILD_DIR)
	$(IVERILOG) -Wall -g2001 -o /dev/null $(RTL_SRCS) $(TB_SRC) \
	  -I$(TB_DIR) && echo "LINT OK"

sim: $(BUILD_DIR)
	$(IVERILOG) -g2001 -Wall \
	  -I$(TB_DIR) \
	  -o $(SIM_BIN) \
	  $(RTL_SRCS) $(TB_SRC)
	$(VVP) $(SIM_BIN)

synth: $(BUILD_DIR)
	$(YOSYS) -p " \
	  read_verilog $(RTL_SRCS); \
	  synth -top axil_mlp_infer -flatten; \
	  stat; \
	  " 2>&1 | tee $(BUILD_DIR)/synth_log.txt
	@grep -E "^(Number of|   wire|   module|   FDRE|   LUT|   DSP)" $(BUILD_DIR)/synth_log.txt || true

clean:
	rm -rf $(BUILD_DIR)
