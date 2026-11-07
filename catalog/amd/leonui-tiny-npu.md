---
name: leonui-tiny-npu
url: https://github.com/Leonui/tiny-npu
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(가속기)
language: Verilog
tools: []
bus: AXI4-Lite
peripherals: [NPU-MAC, 가중치-BRAM]
stage: T2
license: unknown
stats: {stars: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-07
unverified: 보드, 자원(LUT/FF/BRAM), 테스트벤치, 라이선스 — 검색 결과만 열람
sources: [https://github.com/Leonui/tiny-npu]
---

## 요약 (3줄 이내, 내 표현으로)
AXI4-Lite 인터페이스를 갖춘 소형 NPU 구현체. 가중치를 BRAM에 적재하고 추론 트리거 레지스터로 MAC 어레이를 구동하는 구조로 보인다. 검색 결과에서 이름만 확인했다(L2).

## 구조
- AXI4-Lite 슬레이브 레지스터로 가중치 로드·추론 제어·결과 읽기를 노출(추정, unverified).
- MAC 어레이와 BRAM 가중치 버퍼 조합(추정, unverified).

## 검증·재현성
- 미확인. 테스트벤치, 합성 대상 보드, CI 여부 모두 unverified.

## 한계·위험
- L2 열람: 소스 코드 미열람, 라이선스 미확인. 이후 L3로 승격 필요.

## 재사용 메모
- 내 판단: AXI4-Lite 가중치 로드 + 추론 트리거 패턴은 MicroBlaze V 슬롯에 그대로 연결 가능. 소스 열람 후 MAC 비트폭·BRAM 사용량 확인 필요.
- 개조: 레지스터 주소를 mbv-frozen-v2 free_slot에 맞추고, 활성화 함수(ReLU LUT)는 자체 RTL로 교체.
- 라이선스 확인 필요.
