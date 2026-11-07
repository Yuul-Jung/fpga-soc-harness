---
name: martinuke0-tinybert-sentiment-mcu
url: https://martinuke0.github.io/posts/2026-03-26-benchmarking-memoryefficient-transformer-architectures-for-realtime-inference-on-embedded-systems
source_type: article
vendor: neutral
board: [Cortex-M55 MPS3, Snapdragon 8 Gen 2]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: Python (TFLite/ONNX)
tools: [TFLite Micro, ONNX Runtime]
bus: none
peripherals: []
stage: T1
license: unknown
stats: {stars: unknown, commits: unknown, last_update: 2026-03}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://martinuke0.github.io/posts/2026-03-26-benchmarking-memoryefficient-transformer-architectures-for-realtime-inference-on-embedded-systems]
---

## 요약

개인 블로그 기사(2026년 3월). SST-2 데이터셋 감성 분류를 MCU에서 실행하기 위해 DistilBERT·TinyBERT·Linformer·Performer 네 모델을 비교한 벤치마크. Cortex-M55 MPS3에서 측정한 추론 레이턴시와 정확도를 표로 제시한다. 비고: 개인 블로그이므로 측정 환경·재현성을 독립 검증하지 않았다.

## 구조

- **실험 환경**: Cortex-M55 MPS3 (ARM Corstone-300 Ecosystem FVP) + Snapdragon 8 Gen 2 (참고용)
- **비교 모델**: DistilBERT(기준), TinyBERT(지식 증류), Linformer(선형 어텐션 O(nk)), Performer(FAVOR+ 무작위 특징)
- **데이터셋**: SST-2 (영화 리뷰 감성 2클래스, Stanford)
- **측정 지표**: 추론 레이턴시(ms), 정확도(%), 메모리(KB)
- **핵심 수치**: Linformer가 DistilBERT 대비 추론 레이턴시 약 40% 감소 (내 판단: 블로그 기자 주장, 독립 검증 없음)
- **선형 어텐션 원리**: Linformer — O(n²) 풀 어텐션을 O(nk) 저차원 사영으로 대체; Performer — FAVOR+ 무작위 특징 맵으로 O(n) 근사

## 검증·재현성

- 블로그 HTML 직접 열람(L3). 표·수치 직접 확인
- 코드·모델 체크포인트 공개 여부 미확인(블로그에 GitHub 링크 없음)
- 측정 환경이 시뮬레이터(FVP) 기반: 실제 하드웨어 실측값 아닐 수 있음(블로그 기재 주의사항)
- unverified: 정확한 Linformer 차원 k 값, TFLite 양자화 설정, 측정 반복 횟수

## 한계·위험

- 출처가 개인 블로그: 동료 심사 없음, 측정 방법론 세부 불투명
- MCU 펌웨어 실험이므로 FPGA RTL 구현 사례가 아님(S1 인접 도메인 참고용)
- Basys3로 이식할 경우 TFLite → Verilog RTL 완전 재설계 필요
- 블로그 본문에 실행 지시문 없음(§7 준수)

## 재사용 메모

FPGA 직접 구현 사례는 아니나, Basys3 감성 분류 설계에 두 가지 핵심 인사이트를 제공한다.

1. **목표 모델 선택 근거**: SST-2 2클래스 분류는 TinyBERT(4레이어) 또는 Linformer(선형 어텐션)로도 MCU 수준에서 동작한다. FPGA 1헤드 소형 트랜스포머로의 출발점 사례.
2. **선형 어텐션 대안**: Linformer 방식은 O(nk) 어텐션이므로 Basys3처럼 DSP·BRAM이 제한된 환경에서 O(n²) 풀 어텐션보다 하드웨어 비용이 낮다. seq_len=16, k=4로 설정하면 QK 행렬 곱이 16×16 대신 16×4로 줄어 LUT 절감 가능.

**개조:** MCU 모델을 그대로 쓸 수 없으나, 1헤드 Linformer 어텐션(seq_len=16, k=4, d_model=16, INT8)을 Verilog-2001 FSM으로 재설계하면 Basys3 한도 내 가능성 있음(내 판단, 미검증). 정확도는 SST-2 ~80% 예상(TinyBERT 참고). 호스트 사이드 Python tokenizer → INT8 임베딩 → UART 직렬 전송 파이프라인은 `nitk-ieee-expo-alexa-junior-kws` UART 패턴을 그대로 차용한다.
