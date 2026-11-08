# Makefile for mmio-btn5-debounce-ip
# Targets: lint, sim, synth

RTL    := rtl/axil_btn5.v rtl/basys3_top_btn5.v
TB     := tb/tb_axil_btn5.v
TOP    := basys3_top_btn5
TOP_IP := axil_btn5

.PHONY: all lint sim synth clean

all: lint sim

lint:
	iverilog -g2001 -Wall -t null $(RTL) $(TB)

sim:
	iverilog -g2001 -o /tmp/btn5_sim $(TB) $(RTL)
	vvp /tmp/btn5_sim | tee /tmp/btn5_sim.log
	@grep -q "^PASS" /tmp/btn5_sim.log || (echo "SIMULATION FAILED" && exit 1)

synth:
	yosys -p "read_verilog $(RTL); synth -top $(TOP_IP); stat" 2>&1 | tee /tmp/btn5_synth.log

clean:
	rm -f /tmp/btn5_sim /tmp/btn5_sim.log /tmp/btn5_synth.log
