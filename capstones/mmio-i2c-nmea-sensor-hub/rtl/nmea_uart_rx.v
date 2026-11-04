// nmea_uart_rx.v
// UART receiver for NMEA sentences (terminated by '\n' = 0x0A)
// 9600 baud N-8-1, configurable baud divisor
// Signals one-cycle pulse line_done_pulse when '\n' received
// Verilog-2001

`timescale 1ns/1ps

module nmea_uart_rx #(
    parameter DEFAULT_BAUD_DIV = 16'd10417  // 9600 baud @ 100 MHz
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [15:0] baud_div,

    input  wire        rx,

    output reg         line_rdy,        // 1 when last line is complete
    output reg         line_done_pulse  // one-cycle pulse on '\n' detection
);

    // -----------------------------------------------------------------------
    // 2-stage synchronizer for RX input
    // -----------------------------------------------------------------------
    reg rx_s0, rx_s1, rx_s2;
    always @(posedge clk) begin
        if (!rst_n) begin
            rx_s0 <= 1'b1; rx_s1 <= 1'b1; rx_s2 <= 1'b1;
        end else begin
            rx_s0 <= rx;
            rx_s1 <= rx_s0;
            rx_s2 <= rx_s1;
        end
    end

    // -----------------------------------------------------------------------
    // Baud rate generator: half-bit and full-bit periods
    // -----------------------------------------------------------------------
    reg [15:0] baud_cnt;
    reg        baud_tick;       // full-bit tick
    reg        baud_half;       // half-bit tick (sample point)

    always @(posedge clk) begin
        if (!rst_n || !en) begin
            baud_cnt  <= 16'd0;
            baud_tick <= 1'b0;
            baud_half <= 1'b0;
        end else begin
            baud_tick <= 1'b0;
            baud_half <= 1'b0;
            if (baud_cnt >= baud_div) begin
                baud_cnt  <= 16'd0;
                baud_tick <= 1'b1;
            end else begin
                baud_cnt <= baud_cnt + 1'b1;
                if (baud_cnt == (baud_div >> 1))
                    baud_half <= 1'b1;
            end
        end
    end

    // -----------------------------------------------------------------------
    // UART receive FSM
    // -----------------------------------------------------------------------
    localparam [2:0]
        RS_IDLE  = 3'd0,
        RS_START = 3'd1,
        RS_DATA  = 3'd2,
        RS_STOP  = 3'd3;

    reg [2:0]  rx_state;
    reg [15:0] rx_baud_cnt;
    reg [3:0]  rx_bit_cnt;
    reg [7:0]  rx_shift;
    reg [7:0]  rx_byte;
    reg        rx_byte_valid;

    always @(posedge clk) begin
        if (!rst_n || !en) begin
            rx_state     <= RS_IDLE;
            rx_baud_cnt  <= 16'd0;
            rx_bit_cnt   <= 4'd0;
            rx_shift     <= 8'd0;
            rx_byte      <= 8'd0;
            rx_byte_valid<= 1'b0;
        end else begin
            rx_byte_valid <= 1'b0;

            case (rx_state)
                RS_IDLE: begin
                    // Detect falling edge (start bit)
                    if (!rx_s2) begin
                        rx_state    <= RS_START;
                        rx_baud_cnt <= 16'd0;
                        rx_bit_cnt  <= 4'd0;
                    end
                end

                RS_START: begin
                    // Wait half-bit to sample in center of start bit
                    rx_baud_cnt <= rx_baud_cnt + 1'b1;
                    if (rx_baud_cnt >= (baud_div >> 1)) begin
                        rx_baud_cnt <= 16'd0;
                        if (!rx_s2) begin
                            rx_state <= RS_DATA;
                        end else begin
                            rx_state <= RS_IDLE; // glitch
                        end
                    end
                end

                RS_DATA: begin
                    rx_baud_cnt <= rx_baud_cnt + 1'b1;
                    if (rx_baud_cnt >= baud_div) begin
                        rx_baud_cnt <= 16'd0;
                        rx_shift    <= {rx_s2, rx_shift[7:1]}; // LSB first
                        rx_bit_cnt  <= rx_bit_cnt + 1'b1;
                        if (rx_bit_cnt == 4'd7) begin
                            rx_state <= RS_STOP;
                        end
                    end
                end

                RS_STOP: begin
                    rx_baud_cnt <= rx_baud_cnt + 1'b1;
                    if (rx_baud_cnt >= baud_div) begin
                        rx_baud_cnt  <= 16'd0;
                        rx_state     <= RS_IDLE;
                        if (rx_s2) begin // valid stop bit
                            rx_byte       <= rx_shift;
                            rx_byte_valid <= 1'b1;
                        end
                    end
                end

                default: rx_state <= RS_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Line detection: pulse on '\n' (0x0A)
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n || !en) begin
            line_rdy        <= 1'b0;
            line_done_pulse <= 1'b0;
        end else begin
            line_done_pulse <= 1'b0;
            if (rx_byte_valid) begin
                if (rx_byte == 8'h0A) begin // '\n'
                    line_rdy        <= 1'b1;
                    line_done_pulse <= 1'b1;
                end
                // Reset line_rdy on next byte (new line starts)
                if (rx_byte == 8'h24) begin // '$' = NMEA sentence start
                    line_rdy <= 1'b0;
                end
            end
        end
    end

endmodule
