---
name: li-2019-ernn-gru-lstm
url: https://arxiv.org/abs/1812.07106
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(가속기)
language: HLS(C++)
tools: [Vivado HLS]
bus: none
peripherals: [GRU-cell, LSTM-cell, block-circulant-MAC]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2018-12-19}
doc_language: en
verification: L3
checked_at: 2026-11-07
sources: [https://arxiv.org/abs/1812.07106]
---

## 요약 (3줄 이내, 내 표현으로)

Li et al. (보스턴 대학 외 다기관, 2018/HPCA 2019)이 제안한 E-RNN: 블록-순환(Block-Circulant) 행렬로 LSTM과 GRU의 가중치를 압축, Virtex-7과 Kintex UltraScale FPGA에서 고처리량 추론. GRU가 LSTM보다 행렬-벡터 곱셈(MVM) 수가 적어(순환 형식에서 3 vs 4 MVM) ~23% 낮은 지연시간을 달성. 12비트 고정소수점, 정확도 하락 0.1% 미만.

## 구조

- 보드: Alpha Data ADM-PCIE-7V3 (Virtex-7 XC7VX690T, DDR3 16GB), Xilinx KU060 (Kintex UltraScale)
- 클럭: 200 MHz (두 보드 동일)
- 압축: 블록-순환 행렬로 가중치 저장·곱셈. 블록 크기(FFT 크기) 8 또는 16.
- MVM 수: LSTM 4회(순환 형식), GRU 3회 → GRU가 약 25% 적은 연산량
- 고정소수점: 12비트 (ESE, C-LSTM과 동일 비교 조건). 정확도 하락 0.1% 미만.
- 활성화 함수: LUT 또는 PWL(구체적 방법은 본문 미열람)

### 자원 사용 (Table III, 논문 직접 발췌)

| 모델 | 블록크기 | 보드 | DSP(%) | BRAM(%) | LUT(%) | FF(%) | 지연(µs) | FPS |
|---|---|---|---|---|---|---|---|---|
| LSTM | FFT8  | KU060 | 95.4 | 88.1 | 77.6 | 61.2 | 13.7 | 231,514 |
| LSTM | FFT8  | 7V3   | 85.6 | 78.5 | 74.0 | 52.3 | 12.9 | 240,389 |
| GRU  | FFT8  | KU060 | 79.0 | 90.8 | 81.2 | 72.4 | 10.5 | 284,540 |
| GRU  | FFT8  | 7V3   | 62.1 | 88.2 | 78.8 | 73.2 | 10.5 | 284,463 |
| LSTM | FFT16 | KU060 | 96.4 | 90.3 | 76.5 | 65.1 |  7.4 | 429,327 |
| LSTM | FFT16 | 7V3   | 79.6 | 65.2 | 59.4 | 55.3 |  8.3 | 382,510 |
| GRU  | FFT16 | KU060 | 79.5 | 81.2 | 72.5 | 65.2 |  6.7 | 445,167 |
| GRU  | FFT16 | 7V3   | 64.3 | 79.5 | 67.4 | 60.3 |  6.5 | 464,582 |

(전력·FPS/W는 7V3만 측정: GRU FFT8 22W/12,930 FPS/W, GRU FFT16 29W/16,020 FPS/W)

## 검증·재현성

- Virtex-7과 Kintex UltraScale에서 Vivado HLS로 합성 및 보드 테스트 완료(논문 보고)
- 소스 코드: footnote에서 github.com/lz1313/BlockCIrculantRNN 언급. 직접 열람 차단됨(PROVENANCE_REQUIRED)으로 라이선스·내용 미확인
- unverified: 실제 소스 파일 구성·라이선스 (소스 열람 불가)

## 한계·위험

- 타깃 보드가 Virtex-7·Kintex UltraScale: 고급 디바이스로 Basys3(XC7A35T, 20,800 LUT6) 직접 이식 불가
- Vivado HLS(C++) 기반: Verilog-2001 환경으로 직접 사용 불가, 구조 참고용
- 블록-순환 압축 구현에 FFT 하드웨어(DSP 집약) 필요 → Basys3의 90개 DSP48E1로는 대형 모델 구현 어려움
- 소스 코드 열람 차단으로 실제 구현 세부 불명확
- 2019년 논문으로 Vivado 2024.2와 호환성 미확인

## 재사용 메모

핵심 발견: GRU는 LSTM보다 행렬-벡터 곱셈 수가 25% 적어 동일 하드웨어에서 더 빠른 추론이 가능. 이 비율은 블록-순환 압축 없이도 성립하므로 Basys3 소형 구현에 직접 적용 가능.

개조: (내 판단)
① MVM 수 비교 원리(LSTM 4→GRU 3)를 Verilog-2001 셀 구현에 직접 반영: GRU 셀은 forget/output 게이트를 제거하고 update/reset 2개 게이트로만 구성 → 동일 고정소수점 MAC 모듈을 더 적게 인스턴스화
② 블록-순환 압축 자체는 DSP 집약이므로 Basys3에서는 단순 행렬-벡터 MAC + BRAM 가중치 적재로 대체
③ AXI4-Lite 슬레이브 래퍼로 MicroBlaze V가 타임스텝당 입력 벡터를 쓰고 출력을 읽는 구조(free_slots 1슬롯)
④ 옮길 수 없는 것: 블록-순환 FFT 하드웨어(DSP 과다), HLS 기반 C++ 소스, DDR 인터페이스(BRAM 가중치 적재로 대체 필요)
