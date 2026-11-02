`timescale 1ns/1ps
// 테스트벤치용 간이 SD 카드 모델(SPI 모드 0, SDHC/SDSC 선택). 명령 순서·클럭 속도·주소를 스스로 점검한다.
// 응답: 명령 CRC 바이트 다음 바이트는 0xFF(Ncr 지연), 그다음 R1. ACMD41은 처음 3번 idle(0x01)로 답한다.
module sd_card_model #(
    parameter SDHC = 1
) (
    input  wire cs_n,
    input  wire sclk,
    input  wire mosi,
    output wire miso
);
    reg        present   = 1'b1;     // 0이면 카드 없음(MISO 항상 1)
    reg        ready     = 1'b0;
    reg        app       = 1'b0;
    reg        order_err = 1'b0;     // 명령 순서·인자·더미 클럭 위반
    reg        slow_viol = 1'b0;     // 초기화 중 SCLK가 400 kHz를 넘음
    reg        fast_seen = 1'b0;     // 초기화 뒤 1 MHz 이상 클럭을 봄
    integer    n17       = 0;
    reg [31:0] last17    = 32'h0;
    reg [31:0] dummy_clks = 0;
    reg [1:0]  stage     = 2'd0;
    integer    polls     = 0;

    reg [7:0]  out_sh = 8'hFF, in_sh = 8'h00;
    reg [2:0]  bitc = 3'd0;
    reg        col = 1'b0;
    integer    ncol = 0;
    reg [5:0]  cmd = 6'd0;
    reg [31:0] arg = 32'h0;
    reg [7:0]  q [0:599];
    integer    qlen = 0, qpos = 0, i;
    realtime   t_prev = 0.0;
    realtime   dt = 0.0;
    reg        have_prev = 1'b0;

    assign miso = (cs_n || !present) ? 1'b1 : out_sh[7];

    function [7:0] exp_byte(input [31:0] blk, input [8:0] k);
        begin
            exp_byte = blk[7:0] * 7 + blk[15:8] * 11 + k[7:0] * 5 + (k[8] ? 85 : 0);
        end
    endfunction

    task push(input [7:0] b);
        begin q[qlen] = b; qlen = qlen + 1; end
    endtask

    task process_cmd;
        reg [31:0] blk;
        begin
            qlen = 0; qpos = 0;
            push(8'hFF);
            case (cmd)
                0: begin
                    if (dummy_clks < 74) order_err = 1'b1;
                    ready = 1'b0; app = 1'b0; stage = 2'd1; push(8'h01);
                end
                8: begin
                    if (stage != 2'd1 || arg != 32'h0000_01AA) begin order_err = 1'b1; push(8'h05); end
                    else begin stage = 2'd2; push(8'h01); push(8'h00); push(8'h00); push(8'h01); push(8'hAA); end
                end
                55: begin
                    if (stage < 2'd2) begin order_err = 1'b1; push(8'h05); end
                    else begin app = 1'b1; push(ready ? 8'h00 : 8'h01); end
                end
                41: begin
                    if (!app || arg != 32'h4000_0000) begin order_err = 1'b1; push(8'h05); end
                    else begin
                        app = 1'b0;
                        if (polls < 3) begin polls = polls + 1; push(8'h01); end
                        else begin ready = 1'b1; stage = 2'd3; push(8'h00); end
                    end
                end
                58: begin
                    if (!ready) begin order_err = 1'b1; push(8'h05); end
                    else begin push(8'h00); push(SDHC ? 8'hC0 : 8'h80); push(8'hFF); push(8'h80); push(8'h00); end
                end
                17: begin
                    if (!ready) begin order_err = 1'b1; push(8'h05); end
                    else begin
                        n17 = n17 + 1; last17 = arg;
                        blk = SDHC ? arg : (arg >> 9);
                        push(8'h00); push(8'hFF); push(8'hFF); push(8'hFE);
                        for (i = 0; i < 512; i = i + 1) push(exp_byte(blk, i));
                        push(8'hAB); push(8'hCD);
                    end
                end
                default: begin order_err = 1'b1; push(8'h05); end
            endcase
        end
    endtask

    task handle_byte(input [7:0] b);
        begin
            if (col) begin
                case (ncol)
                    0: arg[31:24] = b;
                    1: arg[23:16] = b;
                    2: arg[15:8]  = b;
                    3: arg[7:0]   = b;
                    default: begin col = 1'b0; process_cmd; end
                endcase
                ncol = ncol + 1;
            end else if (qpos >= qlen && b[7:6] == 2'b01) begin
                col = 1'b1; ncol = 0; cmd = b[5:0];
            end
            if (qpos < qlen) begin out_sh = q[qpos]; qpos = qpos + 1; end
            else out_sh = 8'hFF;
        end
    endtask

    always @(posedge sclk) begin
        if (cs_n) dummy_clks = dummy_clks + 1;
        else begin
            in_sh = {in_sh[6:0], mosi};
            dt = $realtime - t_prev;
            if (have_prev) begin
                if (!ready && dt < 2400.0) slow_viol = 1'b1;
                if (ready && dt < 1000.0) fast_seen = 1'b1;
            end
            t_prev = $realtime; have_prev = 1'b1;
        end
    end

    always @(negedge sclk) begin
        if (!cs_n) begin
            if (bitc == 3'd7) begin bitc = 3'd0; handle_byte(in_sh); end
            else begin bitc = bitc + 3'd1; out_sh = {out_sh[6:0], 1'b1}; end
        end
    end

    always @(posedge cs_n) begin
        bitc = 3'd0; col = 1'b0; ncol = 0; qlen = 0; qpos = 0; out_sh = 8'hFF; have_prev = 1'b0;
    end
endmodule
