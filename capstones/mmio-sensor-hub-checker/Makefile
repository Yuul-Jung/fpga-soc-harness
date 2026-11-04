# Makefile — mmio-sensor-hub-checker 캡스톤 린트·시뮬·합성
# 출처: 자체 작성 (Verilog-2001)
# 도구: iverilog, vvp, yosys (verilator lint은 선택)

SLUG = mmio-sensor-hub-checker

RTL = rtl/hcsr04_ctrl.v \
      rtl/dht11_ctrl.v \
      rtl/i2c_master.v \
      rtl/sensor_hub_top.v \
      rtl/gpio.v \
      rtl/uart_tx.v \
      rtl/mmio_bus.v \
      rtl/demo_master.v \
      rtl/soc_top.v \
      rtl/basys3_top.v

TBS = tb/tb_hcsr04.v \
      tb/tb_dht11.v \
      tb/tb_i2c_master.v \
      tb/tb_sensor_hub.v

BUILD = build
$(shell mkdir -p $(BUILD))

.PHONY: all lint sim synth clean

all: lint sim

# --- 린트 ---
lint:
	@echo "=== LINT ==="
	iverilog -g2001 -Wall -o $(BUILD)/lint_top.out \
	    $(RTL) tb/tb_sensor_hub.v && echo "LINT PASS" || echo "LINT FAIL"

# --- 시뮬레이션 ---
sim: sim_hcsr04 sim_dht11 sim_i2c sim_hub

sim_hcsr04:
	@echo "--- sim: tb_hcsr04 ---"
	iverilog -g2001 -o $(BUILD)/tb_hcsr04.vvp rtl/hcsr04_ctrl.v tb/tb_hcsr04.v && \
	    vvp $(BUILD)/tb_hcsr04.vvp 2>&1 | tee $(BUILD)/tb_hcsr04.log | grep -E "^(PASS|FAIL)"

sim_dht11:
	@echo "--- sim: tb_dht11 ---"
	iverilog -g2001 -o $(BUILD)/tb_dht11.vvp rtl/dht11_ctrl.v tb/tb_dht11.v && \
	    vvp $(BUILD)/tb_dht11.vvp 2>&1 | tee $(BUILD)/tb_dht11.log | grep -E "^(PASS|FAIL)"

sim_i2c:
	@echo "--- sim: tb_i2c_master ---"
	iverilog -g2001 -o $(BUILD)/tb_i2c.vvp rtl/i2c_master.v tb/tb_i2c_master.v && \
	    vvp $(BUILD)/tb_i2c.vvp 2>&1 | tee $(BUILD)/tb_i2c.log | grep -E "^(PASS|FAIL)"

sim_hub:
	@echo "--- sim: tb_sensor_hub ---"
	iverilog -g2001 -o $(BUILD)/tb_sensor_hub.vvp \
	    rtl/hcsr04_ctrl.v rtl/dht11_ctrl.v rtl/i2c_master.v \
	    rtl/sensor_hub_top.v tb/tb_sensor_hub.v && \
	    vvp $(BUILD)/tb_sensor_hub.vvp 2>&1 | tee $(BUILD)/tb_sensor_hub.log | grep -E "^(PASS|FAIL)"

# --- 합성 (yosys 추정) ---
synth:
	@echo "=== SYNTH (yosys, Xilinx 타겟) ==="
	yosys -q -p "synth_xilinx -flatten -top basys3_top" \
	    $(RTL) 2>&1 | tee $(BUILD)/synth.log
	@grep -E "Number of (cells|wires|nets)" $(BUILD)/synth.log || true
	@echo "SYNTH done. 자원은 yosys 추정 (Vivado 기준 아님)"

clean:
	rm -rf $(BUILD)

help:
	@echo "make lint   — iverilog -g2001 lint"
	@echo "make sim    — 테스트벤치 4개 시뮬레이션"
	@echo "make synth  — yosys 합성 (추정)"
	@echo "make clean  — build/ 삭제"
