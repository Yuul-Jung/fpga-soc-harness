SLUG     := mmio-hc05-bt-tel-ip
RTL      := rtl/uart_tx.v rtl/uart_rx.v rtl/axil_hc05_bt.v rtl/basys3_hc05_top.v
TB       := tb/tb_axil_hc05_bt.v
SYNTH_TOP := axil_hc05_bt

.PHONY: all sim lint synth clean

all: sim lint synth

sim: $(RTL) $(TB)
	@mkdir -p build
	iverilog -g2001 -Wall -Wno-timescale -o build/$(SLUG)_tb.vvp $(RTL) $(TB)
	vvp build/$(SLUG)_tb.vvp | tee build/sim_$(SLUG).log
	@grep -q "^PASS" build/sim_$(SLUG).log && echo "SIM PASS" || (echo "SIM FAIL"; exit 1)

lint: $(RTL)
	verilator --lint-only -Wall --timing \
		--Wno-WIDTHEXPAND --Wno-WIDTHTRUNC \
		$(RTL)

synth: $(RTL)
	@mkdir -p build
	yosys -p "read_verilog $(RTL); synth -top $(SYNTH_TOP); stat" 2>&1 | tee build/synth_$(SLUG).log

clean:
	rm -rf build/
