# Makefile — mmio-led-matrix-sound-tilt 캡스톤
# 타깃: lint, sim, synth, clean
# 도구: iverilog/vvp (린트·시뮬), yosys (합성)
# 사용 방법:
#   make lint    — iverilog 문법 검사
#   make sim     — 시뮬레이션 (PASS/FAIL 출력)
#   make synth   — yosys LUT 추정 합성
#   make clean   — 생성 파일 제거
#   make all     — lint + sim + synth

SLUG     := mmio-led-matrix-sound-tilt
TOP      := basys3_led_matrix_sound_tilt_top
SIM_TOP  := tb_led_matrix_sound_tilt

RTL_DIR  := rtl
TB_DIR   := tb
BUILD    := build/$(SLUG)

RTL_SRCS := \
	$(RTL_DIR)/basys3_top.v \
	$(RTL_DIR)/soc_top.v \
	$(RTL_DIR)/axil_led_matrix_slave.v \
	$(RTL_DIR)/pdm_cic_decimator.v \
	$(RTL_DIR)/iir_band_energy.v \
	$(RTL_DIR)/adxl345_spi_reader.v \
	$(RTL_DIR)/frame_buf.v \
	$(RTL_DIR)/max7219_chain_driver.v

TB_SRCS := \
	$(TB_DIR)/tb_led_matrix_sound_tilt.v \
	$(RTL_DIR)/soc_top.v \
	$(RTL_DIR)/axil_led_matrix_slave.v \
	$(RTL_DIR)/pdm_cic_decimator.v \
	$(RTL_DIR)/iir_band_energy.v \
	$(RTL_DIR)/adxl345_spi_reader.v \
	$(RTL_DIR)/frame_buf.v \
	$(RTL_DIR)/max7219_chain_driver.v

IVERILOG := iverilog
VVP      := vvp
YOSYS    := yosys

IVFLAGS  := -g2001 -Wall -Wno-timescale

.PHONY: all lint sim synth clean

all: lint sim synth

# ----------------------------------------------------------------
# 린트: iverilog 문법 검사 (-tnull = 출력 없이 파싱만)
# ----------------------------------------------------------------
lint: $(BUILD)/.lint_ok

$(BUILD)/.lint_ok: $(RTL_SRCS) | $(BUILD)
	@echo "[lint] iverilog 문법 검사..."
	$(IVERILOG) $(IVFLAGS) -tnull -s $(TOP) $(RTL_SRCS)
	@touch $@
	@echo "[lint] PASS"

# ----------------------------------------------------------------
# 시뮬레이션: 테스트벤치 컴파일 및 실행
# ----------------------------------------------------------------
sim: $(BUILD)/sim.vvp
	@echo "[sim] 실행..."
	@$(VVP) $(BUILD)/sim.vvp | tee $(BUILD)/sim.log
	@grep -q "^PASS" $(BUILD)/sim.log || (echo "[sim] FAIL — sim.log 참조" && exit 1)
	@echo "[sim] PASS"

$(BUILD)/sim.vvp: $(TB_SRCS) | $(BUILD)
	@echo "[sim] 컴파일..."
	$(IVERILOG) $(IVFLAGS) -o $@ $(TB_SRCS)

# ----------------------------------------------------------------
# 합성: yosys LUT/FF 추정 (Artix-7 셀 라이브러리 없이 추정만)
# ----------------------------------------------------------------
synth: $(BUILD)/synth.log

$(BUILD)/synth.log: $(RTL_SRCS) | $(BUILD)
	@echo "[synth] yosys 추정 합성..."
	@$(YOSYS) -p " \
		read_verilog -sv $(RTL_SRCS); \
		synth -top $(TOP) -flatten; \
		stat; \
	" 2>&1 | tee $@
	@grep -q "Number of cells" $@ || (echo "[synth] FAIL" && exit 1)
	@echo "[synth] PASS (yosys 추정 — Vivado 수치와 다를 수 있음)"

# ----------------------------------------------------------------
# 디렉토리 생성
# ----------------------------------------------------------------
$(BUILD):
	mkdir -p $(BUILD)

# ----------------------------------------------------------------
# 정리
# ----------------------------------------------------------------
clean:
	rm -rf build/$(SLUG)
	@echo "[clean] 완료"
