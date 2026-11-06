## Makefile — mmio-uart-framing-ip
## 대상: lint, sim, synth
## 도구: iverilog, vvp, yosys (경로 수정 불필요 — 시스템 PATH에 있다고 가정)

SLUG   = mmio-uart-framing-ip
TOP    = basys3_top
TB_TOP = tb_uart_framing
RTL    = rtl/basys3_top.v rtl/soc_top.v rtl/axil_uart_framing.v rtl/uart_rx.v rtl/crc16_xor.v
TB     = tb/tb_uart_framing.v
SYNTH_TOP = basys3_top

IVLOG_FLAGS = -g2001 -Wall -Wno-timescale

.PHONY: all lint sim synth clean

all: lint sim

## ── 린트 ─────────────────────────────────────────────────
lint:
	iverilog $(IVLOG_FLAGS) -o /dev/null $(RTL)
	@echo "[lint] PASS"

## ── 시뮬레이션 ───────────────────────────────────────────
sim: $(RTL) $(TB)
	iverilog $(IVLOG_FLAGS) -o build/$(TB_TOP) $(RTL) $(TB)
	vvp build/$(TB_TOP) | tee build/sim.log
	@grep -q "^PASS" build/sim.log && echo "[sim] PASS" || (echo "[sim] FAIL — build/sim.log 참고" && exit 1)

## ── 합성 (Yosys, 자원 추정) ──────────────────────────────
synth: $(RTL)
	mkdir -p build
	yosys -p "read_verilog $(RTL); synth_xilinx -top $(SYNTH_TOP) -flatten; stat" \
	      2>&1 | tee build/synth.log
	@echo "[synth] done — build/synth.log 참고"

## ── 정리 ────────────────────────────────────────────────
clean:
	rm -rf build/

## ── build 디렉토리 보장 ──────────────────────────────────
build/:
	mkdir -p build

build/$(TB_TOP): $(RTL) $(TB) | build/
	iverilog $(IVLOG_FLAGS) -o $@ $(RTL) $(TB)
