// xadc_avg.v
// 채널별 이동 평균 누산기 (최대 16샘플)
// avg_len[1:0]: 0=1샘플(bypass), 1=4샘플, 2=8샘플, 3=16샘플
// 각 채널: 16슬롯 순환 버퍼 + 16비트 합산기 (12bit × 16 = 192 최대)
// 버퍼 초기값 0 → warmup 동안 평균이 수렴함 (정상 동작)

module xadc_avg (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  avg_len,        // 0=1, 1=4, 2=8, 3=16

    input  wire [3:0]  sample_valid,   // 채널별 1클럭 갱신 펄스
    input  wire [11:0] sample_data_0,
    input  wire [11:0] sample_data_1,
    input  wire [11:0] sample_data_2,
    input  wire [11:0] sample_data_3,

    output reg  [11:0] avg_out_0,
    output reg  [11:0] avg_out_1,
    output reg  [11:0] avg_out_2,
    output reg  [11:0] avg_out_3
);

    // ptr wrap: depth=4→p==3→0, depth=8→p==7→0, depth=16→자연 오버플로
    function [3:0] nxt;
        input [3:0] p;
        input [1:0] al;
        reg [3:0] n;
        begin
            n = p + 4'd1; // 기본: 자연 오버플로(depth=16)
            if (al == 2'd1 && p == 4'd3) n = 4'd0; // depth=4
            if (al == 2'd2 && p == 4'd7) n = 4'd0; // depth=8
            nxt = n;
        end
    endfunction

    // 나누기 → 오른쪽 시프트 비트 수
    function [3:0] sh;
        input [1:0] al;
        case (al)
            2'd0: sh = 4'd0; // ÷1
            2'd1: sh = 4'd2; // ÷4
            2'd2: sh = 4'd3; // ÷8
            2'd3: sh = 4'd4; // ÷16
            default: sh = 4'd0;
        endcase
    endfunction

    // 채널별 순환 버퍼 (16슬롯 × 12비트)
    reg [11:0] buf0 [0:15];
    reg [11:0] buf1 [0:15];
    reg [11:0] buf2 [0:15];
    reg [11:0] buf3 [0:15];

    reg  [3:0]  ptr0, ptr1, ptr2, ptr3;
    reg  [15:0] sum0, sum1, sum2, sum3;

    integer j;

    // 새 합산 (조합): 현재 사이클에서 계산
    wire [15:0] nsum0 = sum0 + {4'd0, sample_data_0} - {4'd0, buf0[ptr0]};
    wire [15:0] nsum1 = sum1 + {4'd0, sample_data_1} - {4'd0, buf1[ptr1]};
    wire [15:0] nsum2 = sum2 + {4'd0, sample_data_2} - {4'd0, buf2[ptr2]};
    wire [15:0] nsum3 = sum3 + {4'd0, sample_data_3} - {4'd0, buf3[ptr3]};

    // === 채널 0 ===
    always @(posedge clk or posedge rst) begin : CH0
        if (rst) begin
            ptr0 <= 4'd0; sum0 <= 16'd0; avg_out_0 <= 12'd0;
            for (j = 0; j < 16; j = j+1) buf0[j] <= 12'd0;
        end else if (sample_valid[0]) begin
            if (avg_len == 2'd0) begin
                avg_out_0 <= sample_data_0;
            end else begin
                sum0      <= nsum0;
                buf0[ptr0]<= sample_data_0;
                ptr0      <= nxt(ptr0, avg_len);
                avg_out_0 <= nsum0 >> sh(avg_len);
            end
        end
    end

    // === 채널 1 ===
    always @(posedge clk or posedge rst) begin : CH1
        if (rst) begin
            ptr1 <= 4'd0; sum1 <= 16'd0; avg_out_1 <= 12'd0;
            for (j = 0; j < 16; j = j+1) buf1[j] <= 12'd0;
        end else if (sample_valid[1]) begin
            if (avg_len == 2'd0) begin
                avg_out_1 <= sample_data_1;
            end else begin
                sum1      <= nsum1;
                buf1[ptr1]<= sample_data_1;
                ptr1      <= nxt(ptr1, avg_len);
                avg_out_1 <= nsum1 >> sh(avg_len);
            end
        end
    end

    // === 채널 2 ===
    always @(posedge clk or posedge rst) begin : CH2
        if (rst) begin
            ptr2 <= 4'd0; sum2 <= 16'd0; avg_out_2 <= 12'd0;
            for (j = 0; j < 16; j = j+1) buf2[j] <= 12'd0;
        end else if (sample_valid[2]) begin
            if (avg_len == 2'd0) begin
                avg_out_2 <= sample_data_2;
            end else begin
                sum2      <= nsum2;
                buf2[ptr2]<= sample_data_2;
                ptr2      <= nxt(ptr2, avg_len);
                avg_out_2 <= nsum2 >> sh(avg_len);
            end
        end
    end

    // === 채널 3 ===
    always @(posedge clk or posedge rst) begin : CH3
        if (rst) begin
            ptr3 <= 4'd0; sum3 <= 16'd0; avg_out_3 <= 12'd0;
            for (j = 0; j < 16; j = j+1) buf3[j] <= 12'd0;
        end else if (sample_valid[3]) begin
            if (avg_len == 2'd0) begin
                avg_out_3 <= sample_data_3;
            end else begin
                sum3      <= nsum3;
                buf3[ptr3]<= sample_data_3;
                ptr3      <= nxt(ptr3, avg_len);
                avg_out_3 <= nsum3 >> sh(avg_len);
            end
        end
    end

endmodule
