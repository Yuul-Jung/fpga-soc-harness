# ML 추론 가속기: 고정소수점 연산·MAC 행렬·MLP·CNN·GRU/LSTM

갱신: 2026-11-07 (/verify 32차). 카드 31건 기반 (Q포맷 4건, MAC/행렬 4건, MLP 뉴런 5건, 활성화 함수 4건, CNN 엔진 3건, BN/LN 정규화 3건, RNN/LSTM 가속기 3건, GRU/LSTM 비교 3건, 논문 2건).
고정소수점 Q포맷 산술, MAC 배열 가속기, MLP/CNN 추론 IP, BN/LN 정규화 하드웨어, RNN/LSTM 가속기의 Basys3 적용 가능성을 정리한다.
MicroBlaze V SoC의 `free_slots`에서 AXI4-Lite 가속기 IP로 연결하는 경로를 중심으로 분석한다.

---

## 1. 고정소수점 Q포맷 산술 라이브러리

| 항목 | wangxuan95-fpga-fixedpoint | wangxuan95-verilog-fixedpoint | opencores-verilog-fixed-point-math | pyadav1992-rtl-fixedpoint-arithmetics |
|---|---|---|---|---|
| 카드 | [wangxuan95-fpga-fixedpoint](../catalog/vendor-neutral/wangxuan95-fpga-fixedpoint.md) | [wangxuan95-verilog-fixedpoint](../catalog/vendor-neutral/wangxuan95-verilog-fixedpoint.md) | [opencores-verilog-fixed-point-math](../catalog/vendor-neutral/opencores-verilog-fixed-point-math.md) | [pyadav1992-rtl-fixedpoint-arithmetics](../catalog/vendor-neutral/pyadav1992-rtl-fixedpoint-arithmetics.md) |
| Q포맷 | WOI/WOF 파라미터 임의 지정 | 임의 비트폭 | Qm.n 파라미터 | 임의 비트폭 |
| 포화 | upflow/underflow 플래그 | 미확인 | 미확인 | 미확인 |
| 파이프라인 | 단일 사이클 + 파이프라인 버전 | 미확인 | 미확인 | 미확인 |
| float 변환 | 있음 | 미확인 | 미확인 | 미확인 |
| 라이선스 | GPL-3.0 | 미확인 | LGPL | MIT |
| 등급 | L3 | L2 | L2 | L2 |
| Basys3 적합성 | needs-port | needs-port | needs-port | needs-port |

**Q4.4 특이사항 (내 판단):** libfpga-fpga-neuron 카드가 쓰는 Q4.4(8비트: sign+3정수+4소수)는 위 범용 라이브러리와 다른 특수화된 포맷이다. Q4.4는 단일 뉴런 단위에서 832 LUT4(조합), 18비트 누산기(포화 포함)로 동작한다. 범용 라이브러리는 임의 비트폭 처리가 목표이고, Q4.4는 최소 면적에서 ML 연산 정밀도를 맞추는 선택이다.

**참고 논문:** gisselquist-zipcpu-bit-growth (비트 성장 분석, L3), lay007-zynq-sdr-course-block04 (Zynq SDR 과정 Q포맷 실습, L3).

---

## 2. MAC 배열 / 행렬 가속기

| 항목 | antoinelecalvez05-ml-dot-product-accelerator | ethanflorendo-fpga-systolic-array-matrix-multiplier | sivakumarchakarapalli-systolic-array-accelerator | arxiv-2304.03974-bramac |
|---|---|---|---|---|
| 카드 | [antoinelecalvez05-ml-dot-product-accelerator](../catalog/vendor-neutral/antoinelecalvez05-ml-dot-product-accelerator.md) | [ethanflorendo-fpga-systolic-array-matrix-multiplier](../catalog/vendor-neutral/ethanflorendo-fpga-systolic-array-matrix-multiplier.md) | [sivakumarchakarapalli-systolic-array-accelerator](../catalog/vendor-neutral/sivakumarchakarapalli-systolic-array-accelerator.md) | [arxiv-2304.03974-bramac](../catalog/papers/arxiv-2304.03974-bramac.md) |
| 보드 | Basys3 | 중립 | Basys3 | 중립(needs-port) |
| 버스 | none(FSM) | none(FSM) | AXI4-Lite | none |
| 아키텍처 | 순차 1-MAC / 4-MAC 병렬 | 시스톨릭 배열 | AXI-Lite 시스톨릭 배열 | BRAM 내장 MAC |
| 라이선스 | unknown | unknown | MIT | unknown |
| 등급 | L2 | L2 | L3 | L2 |
| 단계 | T4 | T4 | T2 | T4 |
| Basys3 직접 | yes | needs-port | yes | needs-port |

**패턴 (내 판단):** antoinelecalvez05는 Basys3 직접 동작이 확인된 유일한 도트 프로덕트 가속기이나 L2(소스 미열람)이다. sivakumarchakarapalli는 MIT 라이선스 + AXI4-Lite 버스 + Basys3 직접이라는 세 조건을 동시에 만족하는 L3 카드로, 하네스에서 가장 활용하기 좋은 출발점이다. BRAMAC 논문은 BRAM에 가중치를 저장하고 Read Port를 통해 직접 MAC를 수행하는 구조가 Basys3 no-DRAM 환경에 이론적으로 적합하나 소스 공개 여부가 미확인이다.

---

## 3. MLP 뉴런 / 추론 IP

| 항목 | libfpga-fpga-neuron | erwanregy-neural-network-fpga | unlv-si-harris-drelu-fpga-mlp | itskannapi-fpga-mlp-accelerator | adityapusalkar-fpga-neural-network |
|---|---|---|---|---|---|
| 카드 | [libfpga-fpga-neuron](../catalog/vendor-neutral/libfpga-fpga-neuron.md) | [erwanregy-neural-network-fpga](../catalog/vendor-neutral/erwanregy-neural-network-fpga.md) | [unlv-si-harris-drelu-fpga-mlp](../catalog/papers/unlv-si-harris-drelu-fpga-mlp.md) | [itskannapi-fpga-mlp-accelerator](../catalog/vendor-neutral/itskannapi-fpga-mlp-accelerator.md) | [adityapusalkar-fpga-neural-network](../catalog/amd/adityapusalkar-fpga-neural-network.md) |
| 포맷 | Q4.4 (8비트) | 파라메트릭 SV | INT8 | 미확인 | 미확인(고정소수점) |
| 활성화 | 없음(단일 뉴런) | sigmoid/ReLU 선택 | D-ReLU(이산 ReLU) | 미확인 | ReLU |
| 단일 뉴런 자원 | 832 LUT4, 0 FF (조합) | 미확인 | D-ReLU: Sigmoid 대비 24-41% 면적 절감 | 미확인 | 미확인 |
| 테스트벤치 | 293 패턴 셀프체킹 | 미확인 | 없음(논문) | 미확인 | 없음(README) |
| 버스 | none(단일 뉴런) | none | none | AXI4-Lite | none |
| 라이선스 | MIT | Apache-2.0 | unknown(논문) | unknown | unknown |
| 등급 | L3 | L3 | L3 | L3 | L3 |
| Basys3 적합성 | needs-port | needs-port | needs-port | yes | yes |

**D-ReLU 핵심 발견 (내 판단):** unlv-si-harris 논문의 Discrete ReLU(D-ReLU)는 부호 비트 검사 + 비트 시프트만으로 활성화를 구현해 Sigmoid보다 24-41% 면적을 절감한다. I-135(D-ReLU vs Sigmoid 비교 패키지)와 I-136(단일 뉴런 AXI4-Lite 슬레이브 IP)에 직접 적용 가능하다. libfpga-fpga-neuron의 293 테스트 벡터는 D-ReLU 적용 후에도 재사용하기 좋은 회귀 기준이다.

**MicroBlaze V 개조 경로 (내 판단):**
- I-136 (T1 기초): libfpga Q4.4 단일 뉴런 + AXI4-Lite 슬레이브 래퍼 → `free_slots` 배정.
- I-134 (T4 MLP): 2층 MLP(256×1 입력→64→16→10 출력) + BRAM 가중치 저장 + AXI4-Lite 슬레이브. erwanregy 파라미터 패턴 참조.
- itskannapi는 Basys3 AXI-Lite 연결 사례이나 라이선스 미확인 → 패턴만 참조, 코드 반입 불가.

---

## 3.5 활성화 함수 하드웨어 (신규 2026-11-06)

| 항목 | adityapusalkar-fpga-neural-network | xie-2020-tvlsi-twofold-lut-tanh | arxiv-1810-08650-activation-dse | unlv-si-harris-drelu-fpga-mlp |
|---|---|---|---|---|
| 카드 | [adityapusalkar-fpga-neural-network](../catalog/amd/adityapusalkar-fpga-neural-network.md) | [xie-2020-tvlsi-twofold-lut-tanh](../catalog/papers/xie-2020-tvlsi-twofold-lut-tanh.md) | [arxiv-1810-08650-activation-dse](../catalog/papers/arxiv-1810-08650-activation-dse.md) | [unlv-si-harris-drelu-fpga-mlp](../catalog/papers/unlv-si-harris-drelu-fpga-mlp.md) |
| 활성화 종류 | ReLU | tanh, sigmoid | ReLU/sigmoid/tanh/ELU/SELU 비교 | D-ReLU(이산 ReLU) |
| 구현 방식 | 조합(LUT) | Twofold LUT (d-LUT + e-LUT) | ROM/CORDIC/Taylor/조합 비교 | 부호 비트 + 비트 시프트 |
| 면적 절감 | 미확인 | 단일 대형 LUT 대비 94.44% 절감 | CORDIC < Taylor < ROM 순 | Sigmoid 대비 24-41% 절감 |
| 지연 | 미확인 | 39.721 ns (파이프라인 가능) | 미확인(논문 비교표) | 비트 연산 → 단일 사이클 추정 |
| BRAM 소비 | 없음 | d-LUT 256×8b+e-LUT 256×4b ≈ 3 KB | ROM 방식 1~2 BRAM | 없음 |
| 등급 | L3 | L2 | L2 | L3 |
| Basys3 적합성 | yes | needs-port | needs-port | needs-port |
| 출처 | GitHub (Basys3) | IEEE TVLSI 2020 | arXiv 1810.08650 | UNLV 논문 |

**활성화 함수 선택 가이드 (내 판단):**
- **자원 최소**: D-ReLU(부호 비트+시프트, LUT < 10) → 가중치 추론 IP의 기본 선택. unlv-si-harris 근거.
- **정밀도 최대 (소 BRAM)**: Twofold LUT tanh(d-LUT+e-LUT ≈ 3 KB, 94.44% 면적 절감) → sigmoid/tanh 필요 시. xie-2020-tvlsi 근거.
- **교육·비교용**: arxiv-1810-08650이 5가지 방식을 고정소수점 8비트 기준으로 비교한 최상의 출발점.
- **LUT-only 조합(최소 지연)**: adityapusalkar의 Basys3 ReLU MLP가 직접 구동 가능한 유일한 L3 사례. 소스 코드 구조 참고 가능이나 라이선스 미확인.

**I-140~I-142 연결 (내 판단):**
- I-140 (LUT-only 조합 활성화 함수 모듈): D-ReLU(unlv-si-harris) + LUT SOP tanh 조합 — 카탈로그 없는 조합, 근거 보강 필요(vetted 6점)
- I-141 (Twofold LUT tanh/sigmoid 모듈): xie-2020-tvlsi Twofold LUT 아키텍처 Basys3 포팅 — 근거 명확, 적합성 높음(vetted 7점)
- I-142 (3단계 비교 TB 묶음): ReLU→sigmoid→tanh 단계별 TB 묶음 — S7 난이도 사다리 완성, 근거 보강 필요(vetted 7점)

---

## 4. CNN 컨볼루션 엔진

| 항목 | abhi-raval-1910-basys3-cnn-2layer | mo-ah-al11505-cnn-convolution-accelerator | kang-yang-2023-aocstream-sensors |
|---|---|---|---|
| 카드 | [abhi-raval-1910-basys3-cnn-2layer](../catalog/amd/abhi-raval-1910-basys3-cnn-2layer.md) | [mo-ah-al11505-cnn-convolution-accelerator](../catalog/amd/mo-ah-al11505-cnn-convolution-accelerator.md) | [kang-yang-2023-aocstream-sensors](../catalog/papers/kang-yang-2023-aocstream-sensors.md) |
| 보드 | Basys3 (XC7A35T) | PYNQ-Z2 (needs-port) | XCKU5P / XC7K325T |
| 아키텍처 | 순차 2레이어 CNN MNIST | 3×3 슬라이딩 윈도우 + 9-MAC | AoCStream 스트리밍 (no-DRAM) |
| 입출력 | UART 직렬 입력 → 7세그 | AXI4-Stream | 외부 메모리 없음 (라인 버퍼) |
| 라이선스 | MIT | MIT | unknown(논문) |
| 등급 | L3 | L3 | L3 |
| 단계 | T4 | T4 | T4 |
| Basys3 직접 | yes | needs-port | needs-port(87.5% 가중치 가지치기 필요) |

**패턴 (내 판단):**
- abhi-raval: Basys3에서 XC7A35T로 MNIST 추론을 UART 입출력으로 완성한 유일한 L3 카드. 단, AXI4-Lite 버스가 없어 MicroBlaze V 연동은 UART 경유 또는 AXI4-Lite 래퍼 추가 필요(I-137 아이디어).
- mo-ah-al11505: 2개 FIFO 라인 버퍼 + 슬라이딩 3×3 윈도우 + 9-MAC 병렬 구조가 AXI4-Stream 인터페이스로 추상화된 최소 단위 컨볼루션 프리미티브다. Basys3 이식 시 Artix-7 패브릭 호환이 근거 있으나 PYNQ DDR 의존성 제거 필요(I-138 아이디어).
- AoCStream 논문: 가중치 가지치기 없이 Basys3에서 완전 구동은 불가(87.5% 가지치기 필요). 채널 ≤8 소형화 버전(I-139 아이디어)이 현실적 대안이나 추가 연구 필요.

**T4 CNN 사다리 (내 판단):**
1. T2: 단일 뉴런 AXI-Lite IP (I-136, libfpga 기반)
2. T3: MLP 2층 BRAM 가중치 추론 (I-134, erwanregy 패턴)
3. T4: 2레이어 CNN MNIST AXI-Lite 버전 (I-137, abhi-raval 포팅)

---

## 조합 아이디어 요약

| 아이디어 | 설명 | 단계 | 상태 |
|---|---|---|---|
| I-134 Basys3 2층 MLP MNIST 추론 IP | Q4.4 2층 MLP + BRAM 가중치 + AXI4-Lite | T4 | vetted (6점) |
| I-135 D-ReLU vs Sigmoid 면적 비교 | RTL 작성 + yosys 비교 TB | T2 | vetted (6점) |
| I-136 Q4.4 단일 뉴런 AXI4-Lite 슬레이브 | libfpga 기반 T1 기초 | T1 | vetted (7점) |
| I-137 Basys3 2층 CNN MNIST AXI-Lite 버전 | abhi-raval UART → AXI4-Lite 래퍼 이식 | T4 | vetted (6점) |
| I-138 라인 버퍼 스트리밍 3×3 Conv IP | mo-ah-al11505 AXI-Stream 프리미티브 | T2 | vetted (6점) |
| I-139 AoCStream Basys3 채널≤8 소형화 | AoCStream 논문 소형화 재현 | T4 | vetted (5점) |
| I-140 LUT-only 조합 활성화 함수 모듈 | D-ReLU + tanh_7_4 SOP 조합, Basys3 | T4 | vetted (6점) |
| I-141 Twofold LUT tanh/sigmoid 모듈 | xie-2020-tvlsi 아키텍처 Basys3 포팅 | T4 | vetted (7점) |
| I-142 활성화 함수 3단계 비교 TB 묶음 | ReLU→sigmoid→tanh S7 사다리 | T4 | vetted (7점) |
| I-101 Basys3 MLP 가속기 AXI4-Lite SoC 통합 | MLP 추론 IP + AXI4-Lite 슬레이브 완전 통합 | T4 | **ready** |
| I-103 Basys3 고정소수점 비트 성장 분석 패키지 | 비트 폭 선택 근거 RTL+TB | T2 | **ready** |
| I-143 BN Fold 사전 계산 AXI4-Lite IP | scale·shift BRAM 적재, MAC 출력단 직렬 | T4 | vetted (6점) |
| I-144 뉴턴-랍슨 역제곱근 LUT 모듈 | Q4.12 16비트, 반복 2회, BRAM 1개 | T4 | vetted (6점) |
| I-145 RMS-Norm 하드웨어 모듈 | LLaMA 호환, 평균 제거 불필요 | T4 | vetted (6점) |
| I-146 단순 RNN 셀 타임스텝 루프 | 최소 순환 네트워크, S7 사다리 1단계 | T3 | vetted (6점) |
| I-147 LSTM 셀 단일 타임스텝 가속기 | 4+1 병렬 ALU, Q8.8, AXI4-Lite 슬레이브 | T4 | vetted (6점) |
| I-148 타임스텝 루프 LSTM 시퀀스 추론 | 멀티 스텝 시계열, S7 사다리 3단계 | T4 | vetted (6점) |

---

## 5. BN/LN 정규화 하드웨어 (신규 2026-11-07)

| 항목 | mcdanel-2019-full-stack-cnn-bn-folding | khan-2024-bn-hls4ml-uw | kim-2025-layernorm-fpga |
|---|---|---|---|
| 카드 | [mcdanel-2019-full-stack-cnn-bn-folding](../catalog/papers/mcdanel-2019-full-stack-cnn-bn-folding.md) | [khan-2024-bn-hls4ml-uw](../catalog/papers/khan-2024-bn-hls4ml-uw.md) | [kim-2025-layernorm-fpga](../catalog/papers/kim-2025-layernorm-fpga.md) |
| 기법 | BN Fold (scale+shift 사전 계산) | BN 3방식 비교 (역제곱근 LUT / fold / 시프트) | LayerNorm 뉴턴-랍슨 1/σ 근사 |
| 고정소수점 | INT8/Q포맷 (추정) | 4~22비트 실험 (Q4.4 등) | Q5.26 (Basys3 이식 시 Q4.12 권장) |
| 핵심 발견 | 추론 시 BN → 1 MAC으로 대체 | 방법 2(fold)가 LUT 90% 절감, 오차 0 | 뉴턴-랍슨 반복 2~3회로 1/σ 수렴 |
| 소스 | unknown (논문) | GitHub (Verilog RTL + TB) | unknown (논문) |
| 대상 보드 | 일반 (CPU 중립) | Xilinx VC709 | Xilinx VU37P |
| 등급 | L2 | L2 | L2 |
| Basys3 적합성 | needs-port | needs-port | needs-port |

**BN Fold 패턴 (내 판단):**
배치 정규화(BN)의 추론 시 최적화는 BN Fold(방법 2)가 가장 효과적이다. `scale=γ/√(σ²+ε)`, `shift=β−γμ/√(σ²+ε)`을 모델 적재 시 MicroBlaze V CPU가 한 번만 계산해 BRAM에 저장하면, 추론 단계에서 각 채널에 MAC 1회만 추가된다. khan-2024가 Q4.4 기준으로 `LUT ~90% 절감, 레이턴시 1 사이클`을 실험으로 확인하므로 Basys3 MLP·CNN 가속기에 직접 적용 가능하다.

**LayerNorm (LN) 이식 경로 (내 판단):**
kim-2025의 Q5.26 → Basys3용은 Q4.12(16비트 총폭)로 비트 폭을 줄이고 뉴턴-랍슨 반복 2회로 고정한다. 초기 추정값 LUT는 BRAM 1개(256~512 엔트리). `FC → LN → FC` 구조에서 LN 블록을 별도 AXI4-Lite 슬레이브로 분리하거나, MAC 어레이 출력단에 인라인 삽입한다. γ·β 파라미터는 슬롯 내 레지스터에 사전 적재한다.

**I-143~I-145 연결 (내 판단):**
- I-143 (BN Fold AXI4-Lite IP): khan-2024 방법 2 → `free_slots` 슬레이브 IP. MicroBlaze V에서 사전 계산 후 BRAM 적재.
- I-144 (뉴턴-랍슨 역제곱근 LUT): kim-2025 → Q4.12 비트 폭 축소 버전. BRAM 1개 LUT.
- I-145 (RMSNorm): kim-2025 LayerNorm 에서 평균 제거 → LLaMA 호환 최소 버전.

---

## 6. RNN/LSTM 순환 가속기 (신규 2026-11-07)

| 항목 | chang-2015-rnn-fpga | qian-2023-lstm-spartan7 | ahirsharan-lstm |
|---|---|---|---|
| 카드 | [chang-2015-rnn-fpga](../catalog/papers/chang-2015-rnn-fpga.md) | [qian-2023-lstm-spartan7](../catalog/papers/qian-2023-lstm-spartan7.md) | [ahirsharan-lstm](../catalog/vendor-neutral/ahirsharan-lstm.md) |
| 보드 | ZedBoard (Zynq-7020) | Spartan-7 XC7S15 | 중립 (Verilog) |
| 아키텍처 | 단일 LSTM 셀, ARM PS + AXI4 DMA | 4+1 병렬 ALU, 860 클럭/타임스텝 | 단일 LSTM 셀 (Verilog) |
| 활성화 함수 | 13-구간 PLA sigmoid/tanh | LUT 테이블 (BRAM 또는 분산 RAM) | 미확인 |
| 고정소수점 | Q8.8 (16비트) | Q8 (16비트 소수부 8비트) | 미확인 |
| 자원 (원문) | LUT 7,852 / FF 4,328 / DSP 24 / BRAM 1 (소형 셀) | LUT ~400 / BRAM 1~2 / DSP 없음 | 미확인 |
| 소스 | 없음 (논문 전용) | elastic-ai.creator 도구 출력물 | MIT (GitHub) |
| 등급 | L3 | L3 | L2 |
| Basys3 적합성 | needs-port | needs-port | needs-port |

**아키텍처 비교 (내 판단):**
두 논문 모두 단일 LSTM 셀 추론을 대상으로 하지만 활성화 함수와 병렬화 접근이 다르다. Chang 2015는 13-구간 PLA(구분선형 근사)로 sigmoid/tanh를 LUT 없이 조합 논리로 구현해 BRAM 소비를 최소화한다. Qian 2023은 4+1 병렬 ALU(게이트별 독립 MAC+활성화)로 860 클럭/타임스텝을 달성하며, XC7S15(1,296 LUT 초소형)에서도 LUT 400개로 동작한다. Basys3(20,800 LUT)는 두 방식 모두 여유 있다.

**Basys3 이식 경로 (내 판단):**
- Chang 2015: ARM PS → MicroBlaze V로 교체. 가중치 적재는 AXI4-Lite 슬레이브. PLA sigmoid/tanh는 범용 조합 모듈로 분리해 `library/rtl/`에 추가 가능. AXI4 DMA(PS 전용)는 소프트웨어 DMA 루틴으로 대체.
- Qian 2023: VHDL → Verilog-2001 재작성(구조는 동일). elastic-ai.creator 의존성 제거, 직접 RTL 작성 필요. 가중치 적재는 MicroBlaze V에서 AXI4-Lite write.
- ahirsharan: MIT 라이선스이나 L2(소스 미열람). 사용자 승인 후 소스 반입 검토 가능.

**S7 난이도 사다리 (내 판단):**
1. T3 단계 (I-146): 단순 RNN 셀 — MAC 1개 + LUT tanh + 상태 레지스터
2. T4 단계 (I-147): LSTM 셀 AXI4-Lite — 4+1 ALU + Q8.8 + PLA sigmoid/tanh
3. T4 단계 (I-148): 타임스텝 루프 — 루프 FSM + BRAM 입력 버퍼 + 멀티 스텝 추론

---

## 7. GRU vs LSTM 비교 (신규 2026-11-07)

| 항목 | li-2019-ernn-gru-lstm | khoda-2023-hls4ml-gru-lstm | chae-2022-gru-de1soc |
|---|---|---|---|
| 카드 | [li-2019-ernn-gru-lstm](../catalog/papers/li-2019-ernn-gru-lstm.md) | [khoda-2023-hls4ml-gru-lstm](../catalog/papers/khoda-2023-hls4ml-gru-lstm.md) | [chae-2022-gru-de1soc](../catalog/papers/chae-2022-gru-de1soc.md) |
| 보드 | Virtex-7 XC7VX690T / Kintex UltraScale KU060 | Kintex UltraScale xcku115 / Alveo U250 | Intel DE1-SoC (Cyclone V) |
| GRU MVM 수 | 3회 (블록-순환) | 3회 (hls4ml, Reuse factor) | unverified (구조적 가지치기) |
| LSTM MVM 수 | 4회 (블록-순환) | 4회 (hls4ml) | — |
| GRU 지연 (최소) | 6.5 µs (FFT8, Virtex-7) | 1.7 µs (latency 전략) | — (GOPs 기준) |
| LSTM 대비 GRU 절감 | ~23% 낮은 지연 / ~25% 적은 자원(MVM 수 비율) | LUT/DSP ~25% 절감 | 57× CPU / 에너지 300× CPU |
| 고정소수점 | 12비트 (Q 포맷 미상) | PTQ, 소수부 ≥10비트 | unverified |
| 압축 기법 | 블록-순환 행렬 (FFT8/FFT16) | Reuse factor (직렬화) | Top-k 가지치기 + 하이브리드 양자화 |
| 소스 | github.com/lz1313/BlockCIrculantRNN (열람 차단) | github.com/fastmachinelearning/hls4ml (Apache-2.0) | 미공개 (학술 논문) |
| 등급 | L3 | L3 | L2 |
| Basys3 적합성 | needs-port | needs-port | needs-port |

**GRU vs LSTM 핵심 비교 (내 판단):**
세 카드 모두 "GRU가 LSTM보다 행렬-벡터 곱셈(MVM) 수가 25% 적다(3 vs 4)"는 사실에서 출발한다. 이 비율은 블록-순환 압축(E-RNN)이나 Reuse factor(hls4ml) 같은 압축 기법과 무관하게 성립하므로, 압축 없이 순수 Verilog-2001로 GRU 셀을 구현해도 같은 절감을 얻는다.

**Basys3 소형 GRU 이식 경로 (내 판단):**
- li-2019 블록-순환 압축은 FFT 하드웨어(DSP 집약)가 필요해 Basys3(90 DSP48)에서 대형 모델 구현이 어렵다. 단, MVM 3회 원리는 그대로 쓸 수 있다.
- khoda-2023 hls4ml의 Reuse factor를 높이면 직렬 처리로 DSP 사용량을 줄일 수 있다. 단, Artix-7 타깃 HLS 프로젝트 생성이 필요하다.
- chae-2022의 Top-k 가지치기는 추론 전 훈련 단계에서 처리하고, MicroBlaze V에서 가중치 적재 시 0-패딩 희소 행렬로 압축해 AXI4-Lite write 포트로 올리는 패턴이 Basys3에 가장 적합하다.
- 세 카드 모두 고성능 보드(Kintex UltraScale, Cyclone V) 타깃이므로 Basys3(XC7A35T, 20,800 LUT, 90 DSP48, 225KB BRAM)에서 소형 모델(은닉 8~16 노드, 12비트 Q포맷)로 축소가 필수다.

**아이디어 연결:**
- I-149: GRU 셀 AXI4-Lite 가속기 IP (vetted, T4, 5점)
- I-150: GRU·LSTM 비교 테스트벤치 모듈 (vetted, T3, 7점)
- I-151: 초소형 GRU 추론 엔진 — 은닉 8노드 (vetted, T4, 7점)

---

## 교훈

- **내 판단: no-DRAM 제약이 아키텍처 선택을 결정한다.** Basys3는 외부 DRAM이 없으므로 프레임 버퍼·대형 가중치 테이블은 BRAM으로만 가능하다. BRAM은 36kb × 50개 = 1.8Mb(225KB)이 한도이며, 2층 MLP(IrisNet급 소형)의 가중치를 겨우 담는 수준이다. CNN 가중치를 모두 BRAM에 올리면 T4 추론 정밀도를 위해 반드시 양자화(Q4.4~Q8.8)와 가지치기가 필요하다.
- **내 판단: D-ReLU와 Q4.4의 조합.** unlv-si-harris의 D-ReLU(부호 비트 체크 + 비트 시프트)를 libfpga Q4.4에 적용하면 전체 MLP IP의 면적을 24-41% 추가 절감할 수 있다. yosys 합성 비교(I-135)로 CI 수준에서 재현 가능하다.
- **내 판단: MIT 라이선스 카드 우선 적용.** sivakumarchakarapalli(MIT, AXI-Lite, Basys3 직접), libfpga(MIT), abhi-raval(MIT)이 코드 반입 허용 범위. erwanregy(Apache-2.0)도 반입 가능. wangxuan95(GPL-3.0)은 소스 열람만 허용, 하네스 IP로 복사 불가.
- **내 판단: CNN → UART 입출력 경로의 가치.** abhi-raval처럼 UART로 픽셀을 받아 추론 결과를 7세그에 표시하는 방식은 MicroBlaze 없이 순수 RTL에서 완결된다. MicroBlaze V 연동이 필요한 경우에는 AXI4-Lite 래퍼를 추가해 I-137 방식으로 이식한다.
