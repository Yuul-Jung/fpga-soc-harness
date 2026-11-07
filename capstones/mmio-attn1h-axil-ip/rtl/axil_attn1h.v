// axil_attn1h.v — Single-head Self-Attention AXI4-Lite IP
// d_model=8, seq_len=1..4 (cfg), INT8 weights, INT8 input, INT32 accum
// Slot [31] = 0x4031_0000, mbv-frozen-v2
// Verilog-2001. No external IP.
// Copyright (c) 2026 jungbw92@gmail.com — original source for mmio-attn1h-axil-ip

`default_nettype none
`timescale 1ns/1ps

module axil_attn1h #(
    parameter D = 8,   // d_model (fixed)
    parameter S = 4    // max seq_len
) (
    input  wire        clk,
    input  wire        rst,
    // AXI4-Lite slave
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,  // ignored
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    output wire [1:0]  s_axil_bresp,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    input  wire [7:0]  s_axil_araddr,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,
    output reg  [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    // Status LED
    output wire        busy_led,
    output wire        done_led
);

assign s_axil_bresp = 2'b00;
assign s_axil_rresp = 2'b00;

// ---- Registers ----
reg [7:0]  reg_ctrl;    // 0x00 W: [0]=start [1]=load_w [2]=clear_done [7:4]=target
reg [5:0]  reg_widx;    // 0x0C R/W: auto-increment write index
reg [4:0]  reg_out_idx; // 0x14 R/W
reg [2:0]  reg_cfg;     // 0x18 R/W: seq_len-1

// ---- Weight/Input arrays ----
reg signed [7:0] wq [0:63]; // Q weights 8x8
reg signed [7:0] wk [0:63]; // K weights 8x8
reg signed [7:0] wv [0:63]; // V weights 8x8
reg signed [7:0] x_buf [0:31]; // tokens: s*8, max 4*8=32

// ---- Intermediate buffers ----
reg signed [15:0] q_buf [0:31]; // Q=X*WQ
reg signed [15:0] k_buf [0:31]; // K=X*WK
reg signed [15:0] v_buf [0:31]; // V=X*WV
reg signed [31:0] score [0:15]; // scores s*s
reg signed [15:0] aw [0:15];    // attention weights (softmax approx)
reg signed [31:0] out_buf [0:31]; // output s*8

// ---- FSM ----
localparam [2:0] ST_IDLE=3'd0, ST_PROJ=3'd1, ST_SCORE=3'd2,
                 ST_SOFTMAX=3'd3, ST_OUT=3'd4, ST_DONE=3'd5;
reg [2:0]  state;
reg [4:0]  ctr_i, ctr_j, ctr_k; // loop counters (max D=8, S=4)
reg [2:0]  proj_phase;           // 0=Q 1=K 2=V
reg [2:0]  seq_len;              // actual seq len
reg        sm_phase;             // 0=find_max 1=subtract

// ---- Softmax temporaries (registered for timing) ----
reg signed [31:0] row_max [0:3]; // max score per row
reg signed [31:0] row_sum [0:3]; // sum of approx exp per row
reg signed [31:0] diff_tmp;
reg signed [31:0] aw_val_tmp;

// ---- AXI write latch ----
reg [7:0] aw_addr_lat;
reg       aw_pend;

// ---- Busy/Done ----
wire busy = (state != ST_IDLE && state != ST_DONE);
wire done_w = (state == ST_DONE);
assign busy_led = busy;
assign done_led = done_w;

// ---- accumulator shared ----
reg signed [31:0] acc;

// integer for init loop
integer ii;

// ---- AXI write channel ----
always @(posedge clk) begin
    if (rst) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        aw_pend        <= 1'b0;
    end else begin
        if (s_axil_awvalid && !s_axil_awready) begin
            s_axil_awready <= 1'b1;
            aw_addr_lat    <= s_axil_awaddr;
            aw_pend        <= 1'b1;
        end else
            s_axil_awready <= 1'b0;

        if (s_axil_wvalid && !s_axil_wready)
            s_axil_wready <= 1'b1;
        else
            s_axil_wready <= 1'b0;

        if (s_axil_wvalid && s_axil_wready)
            s_axil_bvalid <= 1'b1;
        else if (s_axil_bvalid && s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
            aw_pend       <= 1'b0;
        end
    end
end

// ---- Register write ----
always @(posedge clk) begin
    if (rst) begin
        reg_ctrl    <= 8'd0;
        reg_widx    <= 6'd0;
        reg_out_idx <= 5'd0;
        reg_cfg     <= 3'd3;
        state       <= ST_IDLE;
        seq_len     <= 3'd4;
        proj_phase  <= 3'd0;
        ctr_i <= 5'd0; ctr_j <= 5'd0; ctr_k <= 5'd0;
        acc   <= 32'sd0;
        sm_phase <= 1'b0;
        for (ii=0; ii<32; ii=ii+1) out_buf[ii] <= 32'sd0;
        for (ii=0; ii<64; ii=ii+1) begin wq[ii]<=8'sd0; wk[ii]<=8'sd0; wv[ii]<=8'sd0; end
        for (ii=0; ii<32; ii=ii+1) x_buf[ii] <= 8'sd0;
    end else begin
        // Clear start bit after one cycle
        if (reg_ctrl[0]) reg_ctrl[0] <= 1'b0;

        // AXI write to registers
        if (s_axil_wvalid && s_axil_wready && aw_pend) begin
            case (aw_addr_lat[4:2])
                3'd0: begin
                    reg_ctrl <= s_axil_wdata[7:0];
                end
                3'd2: begin // WDATA — write to target array
                    case (reg_ctrl[7:4])
                        4'd0: wq[reg_widx] <= s_axil_wdata[7:0];
                        4'd1: wk[reg_widx] <= s_axil_wdata[7:0];
                        4'd2: wv[reg_widx] <= s_axil_wdata[7:0];
                        4'd3: x_buf[reg_widx[4:0]] <= s_axil_wdata[7:0];
                        default: ;
                    endcase
                    reg_widx <= reg_widx + 6'd1;
                end
                3'd3: reg_widx    <= s_axil_wdata[5:0];
                3'd5: reg_out_idx <= s_axil_wdata[4:0];
                3'd6: begin
                    reg_cfg  <= s_axil_wdata[2:0];
                    seq_len  <= s_axil_wdata[2:0] + 3'd1;
                end
                default: ;
            endcase
        end

        // FSM start
        if (reg_ctrl[0] && state == ST_IDLE) begin
            seq_len    <= reg_cfg + 3'd1;
            state      <= ST_PROJ;
            proj_phase <= 3'd0;
            ctr_i <= 5'd0; ctr_j <= 5'd0; ctr_k <= 5'd0;
            acc   <= 32'sd0;
            for (ii=0; ii<32; ii=ii+1) out_buf[ii] <= 32'sd0;
        end

        // Clear done
        if (reg_ctrl[2] && state == ST_DONE) begin
            state      <= ST_IDLE;
            reg_ctrl[2]<= 1'b0;
        end

        // ---- FSM execution ----
        case (state)
        ST_IDLE: ; // FSM start is handled above; default must not override state <= ST_PROJ
        ST_PROJ: begin
            // Q=X*WQ, K=X*WK, V=X*WV sequentially
            // acc += x_buf[i*D+k] * w?[k*D+j]
            case (proj_phase)
                3'd0: acc <= acc + $signed(x_buf[ctr_i*D+ctr_k]) * $signed(wq[ctr_k*D+ctr_j]);
                3'd1: acc <= acc + $signed(x_buf[ctr_i*D+ctr_k]) * $signed(wk[ctr_k*D+ctr_j]);
                3'd2: acc <= acc + $signed(x_buf[ctr_i*D+ctr_k]) * $signed(wv[ctr_k*D+ctr_j]);
                default: ;
            endcase
            if (ctr_k == D-1) begin
                // Store result, advance
                case (proj_phase)
                    // Include final product (matches ST_SCORE/ST_OUT pattern)
                    // q_buf is [15:0] so 32-bit RHS truncates automatically
                    3'd0: q_buf[ctr_i*D+ctr_j] <= acc + $signed(x_buf[ctr_i*D+ctr_k]) * $signed(wq[ctr_k*D+ctr_j]);
                    3'd1: k_buf[ctr_i*D+ctr_j] <= acc + $signed(x_buf[ctr_i*D+ctr_k]) * $signed(wk[ctr_k*D+ctr_j]);
                    3'd2: v_buf[ctr_i*D+ctr_j] <= acc + $signed(x_buf[ctr_i*D+ctr_k]) * $signed(wv[ctr_k*D+ctr_j]);
                    default: ;
                endcase
                acc   <= 32'sd0;
                ctr_k <= 5'd0;
                if (ctr_j == D-1) begin
                    ctr_j <= 5'd0;
                    if (ctr_i == seq_len-1) begin
                        ctr_i <= 5'd0;
                        if (proj_phase == 3'd2) begin
                            proj_phase <= 3'd0;
                            state      <= ST_SCORE;
                        end else
                            proj_phase <= proj_phase + 3'd1;
                    end else
                        ctr_i <= ctr_i + 5'd1;
                end else
                    ctr_j <= ctr_j + 5'd1;
            end else begin
                ctr_k <= ctr_k + 5'd1;
            end
        end

        ST_SCORE: begin
            // score[i*S+j] = sum_k(Q[i*D+k] * K[j*D+k]) >> 1
            acc <= acc + $signed(q_buf[ctr_i*D+ctr_k]) * $signed(k_buf[ctr_j*D+ctr_k]);
            if (ctr_k == D-1) begin
                score[ctr_i*S+ctr_j] <= (acc + $signed(q_buf[ctr_i*D+ctr_k]) * $signed(k_buf[ctr_j*D+ctr_k])) >>> 1;
                acc   <= 32'sd0;
                ctr_k <= 5'd0;
                if (ctr_j == seq_len-1) begin
                    ctr_j <= 5'd0;
                    if (ctr_i == seq_len-1) begin
                        ctr_i    <= 5'd0;
                        sm_phase <= 1'b0;
                        // init row_max to first score of each row
                        row_max[0] <= score[0*S+0];
                        row_max[1] <= score[1*S+0];
                        row_max[2] <= score[2*S+0];
                        row_max[3] <= score[3*S+0];
                        row_sum[0] <= 32'sd0;
                        row_sum[1] <= 32'sd0;
                        row_sum[2] <= 32'sd0;
                        row_sum[3] <= 32'sd0;
                        state <= ST_SOFTMAX;
                    end else
                        ctr_i <= ctr_i + 5'd1;
                end else
                    ctr_j <= ctr_j + 5'd1;
            end else
                ctr_k <= ctr_k + 5'd1;
        end

        ST_SOFTMAX: begin
            // Phase 0: find max per row (ctr_i=row, ctr_j=col)
            // Phase 1: subtract max, compute linear approx
            if (!sm_phase) begin
                // Find max
                if ($signed(score[ctr_i*S+ctr_j]) > $signed(row_max[ctr_i]))
                    row_max[ctr_i] <= score[ctr_i*S+ctr_j];
                if (ctr_j == seq_len-1) begin
                    ctr_j <= 5'd0;
                    if (ctr_i == seq_len-1) begin
                        ctr_i    <= 5'd0;
                        sm_phase <= 1'b1;
                    end else
                        ctr_i <= ctr_i + 5'd1;
                end else
                    ctr_j <= ctr_j + 5'd1;
            end else begin
                // Subtract max, linear approximation
                // diff = max - score[i][j]; aw = max(0, 127 - diff*4)
                diff_tmp = row_max[ctr_i] - score[ctr_i*S+ctr_j];
                if ($signed(diff_tmp) > 32)
                    aw_val_tmp = 32'sd0;
                else
                    aw_val_tmp = 127 - diff_tmp * 4;
                aw[ctr_i*S+ctr_j] <= aw_val_tmp[15:0];
                row_sum[ctr_i]     <= row_sum[ctr_i] + aw_val_tmp;
                if (ctr_j == seq_len-1) begin
                    ctr_j <= 5'd0;
                    if (ctr_i == seq_len-1) begin
                        ctr_i <= 5'd0;
                        ctr_j <= 5'd0;
                        ctr_k <= 5'd0;
                        acc   <= 32'sd0;
                        state <= ST_OUT;
                    end else
                        ctr_i <= ctr_i + 5'd1;
                end else
                    ctr_j <= ctr_j + 5'd1;
            end
        end

        ST_OUT: begin
            // out_buf[i*D+k] += aw[i*S+j] * v_buf[j*D+k]
            acc <= acc + $signed(aw[ctr_i*S+ctr_j]) * $signed(v_buf[ctr_j*D+ctr_k]);
            if (ctr_j == seq_len-1) begin
                out_buf[ctr_i*D+ctr_k] <= acc + $signed(aw[ctr_i*S+ctr_j]) * $signed(v_buf[ctr_j*D+ctr_k]);
                acc   <= 32'sd0;
                ctr_j <= 5'd0;
                if (ctr_k == D-1) begin
                    ctr_k <= 5'd0;
                    if (ctr_i == seq_len-1) begin
                        ctr_i <= 5'd0;
                        state <= ST_DONE;
                    end else
                        ctr_i <= ctr_i + 5'd1;
                end else
                    ctr_k <= ctr_k + 5'd1;
            end else
                ctr_j <= ctr_j + 5'd1;
        end

        ST_DONE: ; // wait for clear_done

        default: state <= ST_IDLE;
        endcase
    end
end

// ---- AXI read channel ----
always @(posedge clk) begin
    if (rst) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= 32'd0;
    end else begin
        if (s_axil_arvalid && !s_axil_arready) begin
            s_axil_arready <= 1'b1;
        end else
            s_axil_arready <= 1'b0;

        if (s_axil_arvalid && s_axil_arready) begin
            s_axil_rvalid <= 1'b1;
            case (s_axil_araddr[4:2])
                3'd0: s_axil_rdata <= {24'd0, reg_ctrl};
                3'd1: s_axil_rdata <= {30'd0, done_w, busy};
                3'd2: s_axil_rdata <= 32'd0;        // WDATA write-only
                3'd3: s_axil_rdata <= {26'd0, reg_widx};
                3'd4: s_axil_rdata <= out_buf[reg_out_idx]; // OUT_DATA
                3'd5: s_axil_rdata <= {27'd0, reg_out_idx};
                3'd6: s_axil_rdata <= {29'd0, reg_cfg};
                3'd7: s_axil_rdata <= 32'h00010001; // VERSION
                default: s_axil_rdata <= 32'd0;
            endcase
        end else if (s_axil_rvalid && s_axil_rready)
            s_axil_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire
