// deadtime_pwm.v
// 10-bit symmetric PWM generator with per-arm dead-time insertion
// 3 half-bridge phases (A/B/C). Upper arm PWM'd, lower arm DC when active.
// Dead-time: when any arm transitions OFF->ON, it is held OFF for dead_cycles
//            clock periods before turning ON. This prevents shoot-through.
// Fault: if ph_hi_req[n] AND ph_lo_req[n] both asserted for same phase,
//        fault is raised and all gates are forced OFF until cleared.
// PWM period: 1024 clock cycles (97.7 kHz @ 100 MHz)
// Verilog-2001

`timescale 1ns/1ps

module deadtime_pwm #(
    parameter DT_W = 8  // dead-time counter width; max 255 cycles
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        fault_clr,     // 1-cycle pulse to clear latched fault

    input  wire [9:0]  duty,          // PWM duty cycle (0-1023)
    input  wire [DT_W-1:0] dead_cycles, // dead-time in clock cycles

    input  wire [2:0]  ph_hi_req,     // upper arm request from hall FSM [C,B,A]
    input  wire [2:0]  ph_lo_req,     // lower arm request from hall FSM [C,B,A]

    output reg  [2:0]  pwm_hi,        // upper arm gate signals
    output reg  [2:0]  pwm_lo,        // lower arm gate signals
    output reg         fault          // latched shoot-through or request fault
);

    // -----------------------------------------------------------------------
    // 10-bit PWM counter
    // -----------------------------------------------------------------------
    reg [9:0] pwm_cnt;
    wire pwm_active = (pwm_cnt < duty);

    always @(posedge clk) begin
        if (!rst_n || !en) pwm_cnt <= 10'd0;
        else               pwm_cnt <= pwm_cnt + 1'b1;
    end

    // -----------------------------------------------------------------------
    // Raw gate requests (before dead-time)
    // Upper arm: gated by PWM; lower arm: DC (continuous when assigned)
    // -----------------------------------------------------------------------
    wire [2:0] raw_hi = ph_hi_req & {3{pwm_active}};
    wire [2:0] raw_lo = ph_lo_req;

    // -----------------------------------------------------------------------
    // Per-arm dead-time insertion (3 upper + 3 lower arms = 6 arms total)
    // State: when raw signal rises, hold output OFF for dead_cycles
    // -----------------------------------------------------------------------
    reg [DT_W-1:0] dt_cnt [0:5]; // dead-time down-counters [0..2]=hi, [3..5]=lo
    reg [5:0]      dt_active;    // dead-time in progress
    reg [5:0]      gate_prev;    // previous raw gate values
    reg [5:0]      gate_out;     // delayed gate outputs
    wire [5:0]     raw_gate;     // combined raw for all 6 arms

    assign raw_gate = {raw_lo, raw_hi}; // [5:3]=lo_CBA, [2:0]=hi_CBA

    integer i;
    always @(posedge clk) begin
        if (!rst_n || !en) begin
            gate_out  <= 6'd0;
            gate_prev <= 6'd0;
            dt_active <= 6'd0;
            for (i = 0; i < 6; i = i + 1) dt_cnt[i] <= {DT_W{1'b0}};
        end else begin
            gate_prev <= raw_gate;
            for (i = 0; i < 6; i = i + 1) begin
                if (raw_gate[i] && !gate_prev[i]) begin
                    // Rising edge: start dead-time counter
                    dt_cnt[i]    <= dead_cycles;
                    dt_active[i] <= 1'b1;
                    gate_out[i]  <= 1'b0;
                end else if (dt_active[i]) begin
                    // Dead-time in progress
                    if (dt_cnt[i] == {DT_W{1'b0}}) begin
                        dt_active[i] <= 1'b0;
                        gate_out[i]  <= raw_gate[i];
                    end else begin
                        dt_cnt[i]   <= dt_cnt[i] - 1'b1;
                        gate_out[i] <= 1'b0;
                    end
                end else begin
                    gate_out[i] <= raw_gate[i];
                end
            end
        end
    end

    // -----------------------------------------------------------------------
    // Fault detection and latching
    // Fault: simultaneous request on hi AND lo for same phase
    // -----------------------------------------------------------------------
    wire fault_now = |(ph_hi_req & ph_lo_req); // any phase with both arms

    always @(posedge clk) begin
        if (!rst_n || !en) begin
            fault <= 1'b0;
        end else begin
            if (fault_clr) fault <= 1'b0;
            else if (fault_now) fault <= 1'b1;
        end
    end

    // -----------------------------------------------------------------------
    // Output gates: all OFF on fault or !en
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n || !en || fault) begin
            pwm_hi <= 3'd0;
            pwm_lo <= 3'd0;
        end else begin
            pwm_hi <= gate_out[2:0];
            pwm_lo <= gate_out[5:3];
        end
    end

endmodule
