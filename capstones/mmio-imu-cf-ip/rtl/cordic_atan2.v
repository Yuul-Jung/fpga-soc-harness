// cordic_atan2.v — CORDIC 벡터링 모드 atan2 (16반복, 순차 처리)
// 입력 : xi, yi — 16비트 부호 (Q2.14: 16384 = 1.0 = 1g)
// 출력 : angle  — 18비트 부호, degrees*512 (Q7.9), 범위 ±180°*512=±92160
// 쿼드런트 보정: xi<=0 → 초기 90° 회전으로 1·4사분면으로 가져온다
// 반복당 1 클럭, 완료까지 18 클럭 (16반복 + 로드 + 완료 출력)
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
module cordic_atan2 (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire signed [15:0] xi,
    input  wire signed [15:0] yi,
    output reg  signed [17:0] angle,
    output reg         done
);
// ─── CORDIC atan 테이블 (degrees * 512 = Q7.9, i번째 = atan(2^-i)도) ─────
function signed [17:0] atan_lut;
    input [3:0] i;
    begin
        case (i)
            4'd0:  atan_lut = 18'd23040; // atan(1.0)   = 45.0000°
            4'd1:  atan_lut = 18'd13601; // atan(0.5)   = 26.5651°
            4'd2:  atan_lut = 18'd7187;  // atan(0.25)  = 14.0362°
            4'd3:  atan_lut = 18'd3648;  // atan(0.125) =  7.1250°
            4'd4:  atan_lut = 18'd1831;  //              =  3.5763°
            4'd5:  atan_lut = 18'd916;   //              =  1.7899°
            4'd6:  atan_lut = 18'd458;   //              =  0.8952°
            4'd7:  atan_lut = 18'd229;   //              =  0.4476°
            4'd8:  atan_lut = 18'd115;   //              =  0.2238°
            4'd9:  atan_lut = 18'd57;    //              =  0.1119°
            4'd10: atan_lut = 18'd29;    //              =  0.0560°
            4'd11: atan_lut = 18'd14;    //              =  0.0280°
            4'd12: atan_lut = 18'd7;     //              =  0.0140°
            4'd13: atan_lut = 18'd4;     //              =  0.0070°
            4'd14: atan_lut = 18'd2;     //              =  0.0035°
            4'd15: atan_lut = 18'd1;     //              =  0.0018°
            default: atan_lut = 18'd0;
        endcase
    end
endfunction

// ─── 상태 ───────────────────────────────────────────────────────────────────
localparam ST_IDLE  = 2'd0;
localparam ST_INIT  = 2'd1; // 쿼드런트 보정 + 로드
localparam ST_ITER  = 2'd2; // 반복 (iter 0..15)
localparam ST_DONE  = 2'd3;

reg [1:0]  state;
reg [3:0]  iter;
reg signed [31:0] xr, yr, zr; // 32비트 내부 (충분한 정밀도)

// ─── 순차 로직 ──────────────────────────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= ST_IDLE;
        done  <= 1'b0;
        angle <= 18'sd0;
        iter  <= 4'd0;
        xr <= 32'sd0; yr <= 32'sd0; zr <= 32'sd0;
    end else begin
        done <= 1'b0; // 기본 클리어
        case (state)
        // ── 대기 ──────────────────────────────────────────────────────────
        ST_IDLE: begin
            if (start) state <= ST_INIT;
        end
        // ── 초기화: 쿼드런트 보정 ─────────────────────────────────────────
        // xi <= 0 이면 (xi, yi)를 90° 회전: (xi,yi)→(yi,−xi), z_init=+90°*512
        //                 또는 −90° 회전: (xi,yi)→(−yi,xi), z_init=−90°*512
        ST_INIT: begin
            if (xi <= 16'sh0000) begin
                // 2·3사분면: x를 양수로 만드는 90°/-90° 회전
                if (yi >= 16'sh0000) begin
                    // 2사분면(x<0, y≥0): +90° → (x,y)→(y,−x)
                    xr <= {{16{yi[15]}}, yi};        // sign-extend
                    yr <= -{{16{xi[15]}}, xi};
                    zr <= 18'sd46080;                // +90°*512
                end else begin
                    // 3사분면(x<0, y<0): −90° → (x,y)→(−y,x)
                    xr <= -{{16{yi[15]}}, yi};
                    yr <= {{16{xi[15]}}, xi};
                    zr <= -18'sd46080;               // −90°*512
                end
            end else begin
                // 1·4사분면: 그대로
                xr <= {{16{xi[15]}}, xi};
                yr <= {{16{yi[15]}}, yi};
                zr <= 18'sd0;
            end
            iter  <= 4'd0;
            state <= ST_ITER;
        end
        // ── CORDIC 반복 ───────────────────────────────────────────────────
        // 벡터링 모드: yr→0 방향으로 회전, zr에 각도 누산
        // σ = (yr>=0) ? -1 : +1
        // x' = xr - σ*(yr >> iter)
        // y' = yr + σ*(xr >> iter)
        // z' = zr - σ*atan_lut[iter]
        ST_ITER: begin
            if (yr >= 32'sd0) begin
                // σ = -1: x' = xr + (yr>>i), y' = yr - (xr>>i), z' = zr + lut
                xr <= xr + (yr >>> iter);
                yr <= yr - (xr >>> iter);
                zr <= zr + {{14{1'b0}}, atan_lut(iter)};
            end else begin
                // σ = +1: x' = xr - (yr>>i), y' = yr + (xr>>i), z' = zr - lut
                xr <= xr - (yr >>> iter);
                yr <= yr + (xr >>> iter);
                zr <= zr - {{14{1'b0}}, atan_lut(iter)};
            end
            if (iter == 4'd15) begin
                state <= ST_DONE;
            end else begin
                iter <= iter + 4'd1;
            end
        end
        // ── 완료 ──────────────────────────────────────────────────────────
        ST_DONE: begin
            angle <= zr[17:0]; // 하위 18비트 취함 (±92160 범위 내)
            done  <= 1'b1;
            state <= ST_IDLE;
        end
        endcase
    end
end

endmodule
`default_nettype wire
