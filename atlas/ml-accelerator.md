# ML 추론 가속기: 고정소수점 연산·MAC 행렬·MLP·CNN

갱신: 2026-11-06 (/verify 29차). 카드 15건 기반 (Q포맷 4건, MAC/행렬 4건, MLP 뉴런 3건, CNN 엔진 3건, 논문 1건).
고정소수점 Q포맷 산술, MAC 배열 가속기, MLP/CNN 추론 IP의 Basys3 적용 가능성을 정리한다.
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

| 항목 | libfpga-fpga-neuron | erwanregy-neural-network-fpga | unlv-si-harris-drelu-fpga-mlp | itskannapi-fpga-mlp-accelerator |
|---|---|---|---|---|
| 카드 | [libfpga-fpga-neuron](../catalog/vendor-neutral/libfpga-fpga-neuron.md) | [erwanregy-neural-network-fpga](../catalog/vendor-neutral/erwanregy-neural-network-fpga.md) | [unlv-si-harris-drelu-fpga-mlp](../catalog/papers/unlv-si-harris-drelu-fpga-mlp.md) | [itskannapi-fpga-mlp-accelerator](../catalog/vendor-neutral/itskannapi-fpga-mlp-accelerator.md) |
| 포맷 | Q4.4 (8비트) | 파라메트릭 SV | INT8 | 미확인 |
| 활성화 | 없음(단일 뉴런) | sigmoid/ReLU 선택 | D-ReLU(이산 ReLU) | 미확인 |
| 단일 뉴런 자원 | 832 LUT4, 0 FF (조합) | 미확인 | D-ReLU: Sigmoid 대비 24-41% 면적 절감 | 미확인 |
| 테스트벤치 | 293 패턴 셀프체킹 | 미확인 | 없음(논문) | 미확인 |
| 버스 | none(단일 뉴런) | none | none | AXI4-Lite |
| 라이선스 | MIT | Apache-2.0 | unknown(논문) | unknown |
| 등급 | L3 | L3 | L3 | L3 |
| Basys3 적합성 | needs-port | needs-port | needs-port | yes |

**D-ReLU 핵심 발견 (내 판단):** unlv-si-harris 논문의 Discrete ReLU(D-ReLU)는 부호 비트 검사 + 비트 시프트만으로 활성화를 구현해 Sigmoid보다 24-41% 면적을 절감한다. I-135(D-ReLU vs Sigmoid 비교 패키지)와 I-136(단일 뉴런 AXI4-Lite 슬레이브 IP)에 직접 적용 가능하다. libfpga-fpga-neuron의 293 테스트 벡터는 D-ReLU 적용 후에도 재사용하기 좋은 회귀 기준이다.

**MicroBlaze V 개조 경로 (내 판단):**
- I-136 (T1 기초): libfpga Q4.4 단일 뉴런 + AXI4-Lite 슬레이브 래퍼 → `free_slots` 배정.
- I-134 (T4 MLP): 2층 MLP(256×1 입력→64→16→10 출력) + BRAM 가중치 저장 + AXI4-Lite 슬레이브. erwanregy 파라미터 패턴 참조.
- itskannapi는 Basys3 AXI-Lite 연결 사례이나 라이선스 미확인 → 패턴만 참조, 코드 반입 불가.

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

---

## 교훈

- **내 판단: no-DRAM 제약이 아키텍처 선택을 결정한다.** Basys3는 외부 DRAM이 없으므로 프레임 버퍼·대형 가중치 테이블은 BRAM으로만 가능하다. BRAM은 36kb × 50개 = 1.8Mb(225KB)이 한도이며, 2층 MLP(IrisNet급 소형)의 가중치를 겨우 담는 수준이다. CNN 가중치를 모두 BRAM에 올리면 T4 추론 정밀도를 위해 반드시 양자화(Q4.4~Q8.8)와 가지치기가 필요하다.
- **내 판단: D-ReLU와 Q4.4의 조합.** unlv-si-harris의 D-ReLU(부호 비트 체크 + 비트 시프트)를 libfpga Q4.4에 적용하면 전체 MLP IP의 면적을 24-41% 추가 절감할 수 있다. yosys 합성 비교(I-135)로 CI 수준에서 재현 가능하다.
- **내 판단: MIT 라이선스 카드 우선 적용.** sivakumarchakarapalli(MIT, AXI-Lite, Basys3 직접), libfpga(MIT), abhi-raval(MIT)이 코드 반입 허용 범위. erwanregy(Apache-2.0)도 반입 가능. wangxuan95(GPL-3.0)은 소스 열람만 허용, 하네스 IP로 복사 불가.
- **내 판단: CNN → UART 입출력 경로의 가치.** abhi-raval처럼 UART로 픽셀을 받아 추론 결과를 7세그에 표시하는 방식은 MicroBlaze 없이 순수 RTL에서 완결된다. MicroBlaze V 연동이 필요한 경우에는 AXI4-Lite 래퍼를 추가해 I-137 방식으로 이식한다.
