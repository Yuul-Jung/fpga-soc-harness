# Makefile — mmio-ps2-mouse-cursor
# lint, sim, synth 타깃
# 의존: iverilog, yosys (verilator는 선택)

SLUG    = mmio-ps2-mouse-cursor
TOP     = basys3_ps2_mouse_cursor_top
TB      = tb_ps2_mouse_cursor

RTL_SRC = rtl/ps2_mouse_host.v \
          rtl/vga_sync_cursor.v \
          rtl/basys3_ps2_mouse_cursor_top.v

TB_SRC  = tb/tb_ps2_mouse_cursor.v \
          rtl/ps2_mouse_host.v \
          rtl/vga_sync_cursor.v

BUILD   = build
SIM_OUT = $(BUILD)/$(TB).vvp
LINT_OK = $(BUILD)/lint.ok
SIM_LOG = $(BUILD)/sim.log
SYNTH_J = $(BUILD)/synth.json

.PHONY: all lint sim synth clean

all: lint sim synth

## ─── 린트 (iverilog -t null) ───────────────────────────────
lint: $(LINT_OK)

$(LINT_OK): $(RTL_SRC) $(TB_SRC)
	@mkdir -p $(BUILD)
	iverilog -g2001 -Wall -t null $(RTL_SRC) 2>&1 | tee $(BUILD)/lint_rtl.log
	iverilog -g2001 -Wall -t null $(TB_SRC) 2>&1 | tee $(BUILD)/lint_tb.log
	@echo "LINT PASS" > $@

## ─── 시뮬레이션 (iverilog + vvp) ──────────────────────────
sim: $(SIM_LOG)

$(SIM_LOG): $(TB_SRC) $(LINT_OK)
	@mkdir -p $(BUILD)
	iverilog -g2001 -o $(SIM_OUT) $(TB_SRC) -s $(TB)
	vvp $(SIM_OUT) | tee $(SIM_LOG)
	@if grep -q "^FAIL" $(SIM_LOG); then \
	    echo "=== SIMULATION FAILED ==="; exit 1; \
	else \
	    echo "=== SIMULATION PASSED ==="; \
	fi

## ─── 합성 (yosys 추정) ─────────────────────────────────────
synth: $(SYNTH_J)

$(SYNTH_J): $(RTL_SRC)
	@mkdir -p $(BUILD)
	yosys -p "read_verilog -sv $(RTL_SRC); \
	           synth_xilinx -top $(TOP) -flatten; \
	           stat -json -top $(TOP)" \
	      2>&1 | tee $(BUILD)/synth.log
	@if yosys -p "read_verilog -sv $(RTL_SRC); \
	               synth_xilinx -top $(TOP) -flatten; \
	               write_json $(SYNTH_J)" \
	          2>&1 | grep -q "ERROR"; then \
	    echo "SYNTH FAILED"; exit 1; \
	else \
	    echo "SYNTH PASS"; \
	fi

## ─── 정리 ────────────────────────────────────────────────────
clean:
	rm -rf $(BUILD)
