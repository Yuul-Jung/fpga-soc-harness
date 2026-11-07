# Makefile — mmio-can-fd-rx-ip 빌드 타깃
# 의존: iverilog, vvp, verilator, yosys

RTL_DIR  = rtl
TB_DIR   = tb
SIM_OUT  = sim.out

RTL_SRCS = $(RTL_DIR)/axil_can_fd_rx.v $(RTL_DIR)/basys3_top_can_fd.v
TB_SRC   = $(TB_DIR)/tb_can_fd_rx.v

.PHONY: all sim lint synth clean

all: sim lint synth

## ── 시뮬레이션 ────────────────────────────────────────────────────────────
# iverilog: tb + DUT만 컴파일 (top 래퍼는 IBUFG 프리미티브 때문에 제외)
sim: $(TB_SRC) $(RTL_DIR)/axil_can_fd_rx.v
	iverilog -g2001 -Wall \
	    -o $(SIM_OUT) \
	    $(TB_SRC) $(RTL_DIR)/axil_can_fd_rx.v
	vvp $(SIM_OUT)

## ── 린트 ─────────────────────────────────────────────────────────────────
lint: $(RTL_SRCS)
	verilator --lint-only -Wall \
	    --top-module basys3_top_can_fd \
	    $(RTL_SRCS)

## ── 합성 (Yosys, 자원 추정) ───────────────────────────────────────────────
synth: $(RTL_SRCS)
	yosys -p 'read_verilog $(RTL_SRCS); synth_xilinx -top basys3_top_can_fd; stat'

## ── 정리 ─────────────────────────────────────────────────────────────────
clean:
	rm -f $(SIM_OUT)
