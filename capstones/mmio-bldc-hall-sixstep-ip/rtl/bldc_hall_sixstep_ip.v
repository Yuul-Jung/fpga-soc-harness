// bldc_hall_sixstep_ip.v
// AXI4-Lite BLDC 6-step hall decoder + deadtime PWM IP
// Hall(3) → step decode → complementary PWM + commutation deadtime
// Outputs: HIN[2:0] (high-side gates), LIN[2:0] (low-side gates)
// Hall sequence (forward): 101→001→011→010→110→100→101
// Board: Basys3 (100 MHz), Verilog-2001
// Part of capstone mmio-bldc-hall-sixstep-ip (I-023)

`timescale 1ns/1ps

module bldc_hall_sixstep_ip #(
    parameter ADDR_W          = 8,
    parameter DATA_W          = 32,
    parameter DEFAULT_DUTY    = 10'd512,  // 50% default
    parameter DEFAULT_DEADTIME= 8'd50     // 50 cycles = 500 ns @ 100 MHz
) (
    input  wire        clk,
    input  wire        rst_n,   // active-low synchronous reset

    // AXI4-Lite write address channel
    input  wire [ADDR_W-1:0] s_awaddr,
    input  wire              s_awvalid,
    output reg               s_awready,

    // AXI4-Lite write data channel
    input  wire [DATA_W-1:0] s_wdata,
    input  wire [3:0]        s_wstrb,
    input  wire              s_wvalid,
    output reg               s_wready,

    // AXI4-Lite write response channel
    output reg  [1:0]        s_bresp,
    output reg               s_bvalid,
    input  wire              s_bready,

    // AXI4-Lite read address channel
    input  wire [ADDR_W-1:0] s_araddr,
    input  wire              s_arvalid,
    output reg               s_arready,

    // AXI4-Lite read data channel
    output reg  [DATA_W-1:0] s_rdata,
    output reg  [1:0]        s_rresp,
    output reg               s_rvalid,
    input  wire              s_rready,

    // Hall sensor inputs (raw, synchronized internally)
    input  wire [2:0]        hall_in,     // {H_C, H_B, H_A}

    // Gate drive outputs (3-phase bridge)
    output reg  [2:0]        hin,         // high-side: {H_C, H_B, H_A}
    output reg  [2:0]        lin,         // low-side:  {L_C, L_B, L_A}

    // ADC sample trigger (1-cycle pulse at end of commutation deadtime)
    output reg               sample_trig,

    // Level interrupt (active-high)
    output wire              irq
);

    // -----------------------------------------------------------------------
    // Register addresses
    // -----------------------------------------------------------------------
    localparam REG_ID        = 8'h00;  // 0x424C4443 'BLDC' (R)
    localparam REG_CTRL      = 8'h04;  // [0]=EN, [1]=IE, [2]=DIR (RW)
    localparam REG_DUTY      = 8'h08;  // [9:0] 10-bit duty 0..1023 (RW)
    localparam REG_DEADTIME  = 8'h0C;  // [7:0] deadtime clock cycles (RW)
    localparam REG_STATUS    = 8'h10;  // [2:0]=HALL, [5:3]=STEP, [6]=FAULT (R)
    localparam REG_IRQ_STAT  = 8'h14;  // [0]=STEP_CHANGE W1C (RW)

    localparam ID_VAL = 32'h424C4443; // 'BLDC'

    // -----------------------------------------------------------------------
    // 2-stage synchronizer for hall inputs
    // -----------------------------------------------------------------------
    reg [2:0] hall_s0, hall_s1, hall_s2;
    always @(posedge clk) begin
        if (!rst_n) begin
            hall_s0 <= 3'b101; hall_s1 <= 3'b101; hall_s2 <= 3'b101;
        end else begin
            hall_s0 <= hall_in;
            hall_s1 <= hall_s0;
            hall_s2 <= hall_s1;
        end
    end
    wire [2:0] hall = hall_s2; // synchronized

    // -----------------------------------------------------------------------
    // Hall → step decode function
    // Forward sequence: 101(0)→001(1)→011(2)→010(3)→110(4)→100(5)
    // Returns {fault, step[2:0]}
    // -----------------------------------------------------------------------
    function [3:0] hall2step;
        input [2:0] h;
        case (h)
            3'b101: hall2step = 4'b0_000; // step 0
            3'b001: hall2step = 4'b0_001; // step 1
            3'b011: hall2step = 4'b0_010; // step 2
            3'b010: hall2step = 4'b0_011; // step 3
            3'b110: hall2step = 4'b0_100; // step 4
            3'b100: hall2step = 4'b0_101; // step 5
            default: hall2step = 4'b1_000; // 000/111 = fault
        endcase
    endfunction

    // Step → {HIN[2:0], LIN[2:0]} gate pattern
    // Step 0: A+ B-   HIN=001  LIN=010
    // Step 1: A+ C-   HIN=001  LIN=100
    // Step 2: B+ C-   HIN=010  LIN=100
    // Step 3: B+ A-   HIN=010  LIN=001
    // Step 4: C+ A-   HIN=100  LIN=001
    // Step 5: C+ B-   HIN=100  LIN=010
    function [5:0] step2gate;
        input [2:0] s;
        case (s)
            3'd0: step2gate = 6'b001_010;
            3'd1: step2gate = 6'b001_100;
            3'd2: step2gate = 6'b010_100;
            3'd3: step2gate = 6'b010_001;
            3'd4: step2gate = 6'b100_001;
            3'd5: step2gate = 6'b100_010;
            default: step2gate = 6'b000_000;
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // Control registers
    // -----------------------------------------------------------------------
    reg         ctrl_en;
    reg         ctrl_ie;
    reg         ctrl_dir;       // 1 = reverse commutation
    reg [9:0]   r_duty;
    reg [7:0]   r_deadtime;
    reg [31:0]  irq_status;     // [0] = STEP_CHANGE (W1C)

    // Write address capture
    reg [ADDR_W-1:0] waddr_lat;
    reg              waddr_valid;

    // -----------------------------------------------------------------------
    // Hall decode and step tracking
    // -----------------------------------------------------------------------
    wire [3:0] decode     = hall2step(hall);
    wire       fault_raw  = decode[3];
    wire [2:0] step_fwd   = decode[2:0];

    // Apply direction: reverse maps step 0↔5, 1↔4, 2↔3
    // Equivalent to (5 - step_fwd) for 3-bit wrap
    wire [2:0] step = ctrl_dir ? (3'd5 - step_fwd) : step_fwd;

    reg [2:0] step_prev;
    reg       fault_lat;      // sticky fault (single driver below)
    reg       fault_raw_d;    // previous cycle fault_raw for edge detection

    wire fault_rise   = fault_raw & ~fault_raw_d;  // first cycle of invalid hall
    // Combinatorial: CTRL register write in progress this cycle
    wire ctrl_writing = s_wvalid & waddr_valid & (waddr_lat == REG_CTRL);

    wire step_change = (step != step_prev) && !fault_raw;

    // -----------------------------------------------------------------------
    // Single-driver fault_lat block (rising-edge trigger; CTRL write clears)
    // Setting fault_lat on rising edge only means a sustained invalid-hall
    // signal (fault_raw stays high) does NOT re-assert fault_lat after a
    // software clear via CTRL register write.
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            fault_lat   <= 1'b0;
            fault_raw_d <= 1'b0;
        end else begin
            fault_raw_d <= fault_raw;
            if (ctrl_writing)       // software clear wins
                fault_lat <= 1'b0;
            else if (fault_rise)    // set on first cycle of invalid hall only
                fault_lat <= 1'b1;
        end
    end

    // -----------------------------------------------------------------------
    // Commutation deadtime counter
    // -----------------------------------------------------------------------
    reg [7:0] dt_cnt;
    wire      deadtime_active = (dt_cnt != 8'd0);

    always @(posedge clk) begin
        if (!rst_n) begin
            dt_cnt    <= 8'd0;
            step_prev <= 3'd0;
            sample_trig <= 1'b0;
        end else begin
            sample_trig <= 1'b0;

            step_prev <= step;

            if (step_change && ctrl_en) begin
                dt_cnt <= r_deadtime;  // reload deadtime on commutation step
            end else if (dt_cnt != 8'd0) begin
                dt_cnt <= dt_cnt - 1'b1;
                if (dt_cnt == 8'd1)
                    sample_trig <= 1'b1;  // pulse at end of deadtime
            end
        end
    end

    // -----------------------------------------------------------------------
    // 10-bit PWM counter
    // -----------------------------------------------------------------------
    reg [9:0] pwm_cnt;
    always @(posedge clk) begin
        if (!rst_n || !ctrl_en) pwm_cnt <= 10'd0;
        else                     pwm_cnt <= pwm_cnt + 1'b1;
    end
    wire raw_pwm = (pwm_cnt < r_duty);

    // -----------------------------------------------------------------------
    // Gate output logic
    // High-side is PWM'd; low-side is DC ON in active step.
    // All outputs forced to 0 during deadtime or when disabled.
    // -----------------------------------------------------------------------
    wire [5:0] gate_pattern = step2gate(step);
    wire [2:0] hin_step = gate_pattern[5:3];
    wire [2:0] lin_step = gate_pattern[2:0];

    always @(posedge clk) begin
        if (!rst_n || !ctrl_en || fault_lat || deadtime_active) begin
            hin <= 3'd0;
            lin <= 3'd0;
        end else begin
            hin <= hin_step & {3{raw_pwm}};  // PWM on high-side
            lin <= lin_step;                   // DC on low-side (complementary phase)
        end
    end

    // -----------------------------------------------------------------------
    // IRQ
    // -----------------------------------------------------------------------
    assign irq = ctrl_ie & (|irq_status);

    // -----------------------------------------------------------------------
    // AXI4-Lite write channel
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            s_awready  <= 1'b0; s_wready  <= 1'b0;
            s_bvalid   <= 1'b0; s_bresp   <= 2'b00;
            waddr_lat  <= {ADDR_W{1'b0}}; waddr_valid <= 1'b0;
            ctrl_en    <= 1'b0; ctrl_ie   <= 1'b0; ctrl_dir <= 1'b0;
            r_duty     <= DEFAULT_DUTY;
            r_deadtime <= DEFAULT_DEADTIME;
            irq_status <= 32'd0;
        end else begin
            // latch write address
            s_awready <= 1'b0;
            if (s_awvalid && !waddr_valid) begin
                s_awready  <= 1'b1;
                waddr_lat  <= s_awaddr;
                waddr_valid<= 1'b1;
            end

            // latch write data + perform write
            s_wready <= 1'b0;
            if (s_wvalid && waddr_valid) begin
                s_wready    <= 1'b1;
                waddr_valid <= 1'b0;
                s_bvalid    <= 1'b1;
                s_bresp     <= 2'b00;
                case (waddr_lat)
                    REG_CTRL: begin
                        ctrl_en  <= s_wdata[0];
                        ctrl_ie  <= s_wdata[1];
                        ctrl_dir <= s_wdata[2];
                        // fault_lat cleared via ctrl_writing signal in its own always block
                    end
                    REG_DUTY:     r_duty     <= s_wdata[9:0];
                    REG_DEADTIME: r_deadtime <= s_wdata[7:0];
                    REG_IRQ_STAT: irq_status <= irq_status & ~s_wdata; // W1C
                    default: ;
                endcase
            end

            if (s_bvalid && s_bready) s_bvalid <= 1'b0;

            // hardware-set sticky IRQ bits
            if (step_change) irq_status[0] <= 1'b1;
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite read channel
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            s_arready <= 1'b0;
            s_rvalid  <= 1'b0;
            s_rdata   <= 32'd0;
            s_rresp   <= 2'b00;
        end else begin
            s_arready <= 1'b0;

            if (s_arvalid && !s_rvalid) begin
                s_arready <= 1'b1;
                s_rvalid  <= 1'b1;
                s_rresp   <= 2'b00;
                case (s_araddr)
                    REG_ID:       s_rdata <= ID_VAL;
                    REG_CTRL:     s_rdata <= {29'd0, ctrl_dir, ctrl_ie, ctrl_en};
                    REG_DUTY:     s_rdata <= {22'd0, r_duty};
                    REG_DEADTIME: s_rdata <= {24'd0, r_deadtime};
                    REG_STATUS:   s_rdata <= {25'd0, fault_lat, step, hall};
                    REG_IRQ_STAT: s_rdata <= irq_status;
                    default:      s_rdata <= 32'hDEAD_BEEF;
                endcase
            end

            if (s_rvalid && s_rready) s_rvalid <= 1'b0;
        end
    end

endmodule
