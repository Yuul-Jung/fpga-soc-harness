// bldc_hall_fsm.v
// BLDC 6-step Hall sensor decoder and commutation table
// Inputs:  hall[2:0] (synchronized), en, dir
// Outputs: ph_hi[2:0] (upper arm request), ph_lo[2:0] (lower arm request)
//          step[2:0] (current commutation step, 0-5)
//          hall_err  (1 when hall=000 or hall=111, invalid states)
// Bit mapping: [2]=Phase C(W), [1]=Phase B(V), [0]=Phase A(U)
// Forward 6-step commutation table (IEC standard):
//   Hall  Step  Hi(upper)  Lo(lower)
//   001   0     A(U)       B(V)
//   011   1     A(U)       C(W)
//   010   2     B(V)       C(W)
//   110   3     B(V)       A(U)
//   100   4     C(W)       A(U)
//   101   5     C(W)       B(V)
// Reverse: swap ph_hi and ph_lo
// Verilog-2001

`timescale 1ns/1ps

module bldc_hall_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       dir,       // 0=forward, 1=reverse
    input  wire [2:0] hall,      // 2-stage synchronized hall sensor inputs
    output reg  [2:0] ph_hi,     // upper arm enable (Phase C,B,A = [2:1:0])
    output reg  [2:0] ph_lo,     // lower arm enable (Phase C,B,A = [2:1:0])
    output reg  [2:0] step,      // current commutation step (0-5)
    output reg        hall_err   // invalid hall state (000 or 111)
);

    // Commutation lookup for forward direction
    // Output encoding: ph_hi/ph_lo bits: [2]=C [1]=B [0]=A
    reg [2:0] fwd_hi [0:7]; // indexed by hall value (only 1-6 valid)
    reg [2:0] fwd_lo [0:7];
    reg [2:0] fwd_step [0:7];

    integer j;
    initial begin
        for (j = 0; j < 8; j = j + 1) begin
            fwd_hi[j]   = 3'd0;
            fwd_lo[j]   = 3'd0;
            fwd_step[j] = 3'd0;
        end
        // hall=001 → step 0: A hi, B lo
        fwd_hi[3'b001]   = 3'b001; // A
        fwd_lo[3'b001]   = 3'b010; // B
        fwd_step[3'b001] = 3'd0;
        // hall=011 → step 1: A hi, C lo
        fwd_hi[3'b011]   = 3'b001; // A
        fwd_lo[3'b011]   = 3'b100; // C
        fwd_step[3'b011] = 3'd1;
        // hall=010 → step 2: B hi, C lo
        fwd_hi[3'b010]   = 3'b010; // B
        fwd_lo[3'b010]   = 3'b100; // C
        fwd_step[3'b010] = 3'd2;
        // hall=110 → step 3: B hi, A lo
        fwd_hi[3'b110]   = 3'b010; // B
        fwd_lo[3'b110]   = 3'b001; // A
        fwd_step[3'b110] = 3'd3;
        // hall=100 → step 4: C hi, A lo
        fwd_hi[3'b100]   = 3'b100; // C
        fwd_lo[3'b100]   = 3'b001; // A
        fwd_step[3'b100] = 3'd4;
        // hall=101 → step 5: C hi, B lo
        fwd_hi[3'b101]   = 3'b100; // C
        fwd_lo[3'b101]   = 3'b010; // B
        fwd_step[3'b101] = 3'd5;
    end

    always @(posedge clk) begin
        if (!rst_n || !en) begin
            ph_hi    <= 3'd0;
            ph_lo    <= 3'd0;
            step     <= 3'd0;
            hall_err <= 1'b0;
        end else begin
            if (hall == 3'b000 || hall == 3'b111) begin
                // Invalid hall state: all phases off, assert error
                ph_hi    <= 3'd0;
                ph_lo    <= 3'd0;
                step     <= 3'd0;
                hall_err <= 1'b1;
            end else begin
                hall_err <= 1'b0;
                step     <= fwd_step[hall];
                if (!dir) begin
                    // Forward: use table directly
                    ph_hi <= fwd_hi[hall];
                    ph_lo <= fwd_lo[hall];
                end else begin
                    // Reverse: swap hi and lo (reverses current direction)
                    ph_hi <= fwd_lo[hall];
                    ph_lo <= fwd_hi[hall];
                end
            end
        end
    end

endmodule
