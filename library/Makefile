# 재사용 라이브러리 점검: lint(verilator) → sim(iverilog). 캡스톤이 복사해 쓰는 원본이므로 CI가 매번 돌린다.
.PHONY: lint sim clean
build:
	mkdir -p build

lint: build
	verilator --lint-only -Wall -Wno-fatal --top-module axil_regs rtl/axil_regs.v 2>&1 | tee build/lint.log
	@! grep -q "%Error" build/lint.log

sim: build
	iverilog -g2005 -o build/axil.vvp tb/tb_axil_regs.v rtl/axil_regs.v
	vvp build/axil.vvp | tee build/sim.log
	@grep -q "^PASS" build/sim.log && ! grep -q "^FAIL" build/sim.log

clean:
	rm -rf build
