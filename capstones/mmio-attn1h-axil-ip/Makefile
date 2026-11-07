# Makefile for mmio-attn1h-axil-ip
# Targets: lint, sim, synth

RTL  := rtl/axil_attn1h.v rtl/basys3_top_attn1h.v
TB   := tb/tb_axil_attn1h.v
TOP  := basys3_top_attn1h
TOP_IP := axil_attn1h

.PHONY: all lint sim synth clean

all: lint sim

lint:
	iverilog -g2001 -Wall -t null $(RTL) $(TB)

sim:
	iverilog -g2001 -o /tmp/attn1h_sim $(TB) $(RTL)
	vvp /tmp/attn1h_sim | tee /tmp/attn1h_sim.log
	@grep -q "^PASS" /tmp/attn1h_sim.log || (echo "SIMULATION FAILED" && exit 1)

synth:
	yosys -p "read_verilog $(RTL); synth -top $(TOP_IP); stat" 2>&1 | tee /tmp/attn1h_synth.log

clean:
	rm -f /tmp/attn1h_sim /tmp/attn1h_sim.log /tmp/attn1h_synth.log
