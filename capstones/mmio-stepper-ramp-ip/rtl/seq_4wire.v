// seq_4wire.v — 4선식 스텝모터 시퀀서 (28BYJ-48 / ULN2003)
// 출처: 하네스 직접 작성 Verilog-2001 원본
// 전상(full-step, 4단계): 0001 → 0010 → 0100 → 1000 → ...
// 반상(half-step, 8단계): 0001 → 0011 → 0010 → 0110 → 0100 → 1100 → 1000 → 1001 → ...
// dir=1: CW(전진), dir=0: CCW(후진)
`default_nettype none
`timescale 1ns/1ps

module seq_4wire (
    input  wire       clk,
    input  wire       rst,
    input  wire       step_pulse, // 1클럭 펄스 → 1스텝 전진
    input  wire       dir,        // 1=CW, 0=CCW
    input  wire       half_step,  // 0=전상(4), 1=반상(8)
    output reg  [3:0] coil        // ULN2003 IN1~IN4
);
    // 전상 테이블 (4단계)
    reg [3:0] full_tbl [0:3];
    // 반상 테이블 (8단계)
    reg [3:0] half_tbl [0:7];

    initial begin
        full_tbl[0] = 4'b0001;
        full_tbl[1] = 4'b0010;
        full_tbl[2] = 4'b0100;
        full_tbl[3] = 4'b1000;

        half_tbl[0] = 4'b0001;
        half_tbl[1] = 4'b0011;
        half_tbl[2] = 4'b0010;
        half_tbl[3] = 4'b0110;
        half_tbl[4] = 4'b0100;
        half_tbl[5] = 4'b1100;
        half_tbl[6] = 4'b1000;
        half_tbl[7] = 4'b1001;
    end

    reg [2:0] idx; // 0~7 (반상), 0~3 (전상)

    always @(posedge clk) begin
        if (rst) begin
            idx  <= 3'd0;
            coil <= 4'b0001;
        end else if (step_pulse) begin
            if (half_step) begin
                // 반상: 8단계
                if (dir)
                    idx <= (idx == 3'd7) ? 3'd0 : idx + 3'd1;
                else
                    idx <= (idx == 3'd0) ? 3'd7 : idx - 3'd1;
                coil <= half_tbl[(dir) ? ((idx == 3'd7) ? 3'd0 : idx + 3'd1)
                                       : ((idx == 3'd0) ? 3'd7 : idx - 3'd1)];
            end else begin
                // 전상: 4단계 (idx[1:0] 사용)
                if (dir)
                    idx[1:0] <= (idx[1:0] == 2'd3) ? 2'd0 : idx[1:0] + 2'd1;
                else
                    idx[1:0] <= (idx[1:0] == 2'd0) ? 2'd3 : idx[1:0] - 2'd1;
                coil <= full_tbl[(dir) ? ((idx[1:0] == 2'd3) ? 2'd0 : idx[1:0] + 2'd1)
                                       : ((idx[1:0] == 2'd0) ? 2'd3 : idx[1:0] - 2'd1)];
            end
        end
    end

endmodule
`default_nettype wire
