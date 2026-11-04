---
name: altium-ldo-vs-switching-regulator
url: https://resources.altium.com/p/using-ldo-vs-switching-regulator-your-pcb
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none
language: none
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://resources.altium.com/p/using-ldo-vs-switching-regulator-your-pcb]
---

## 요약

Altium Resources의 LDO vs 스위칭 레귤레이터 비교 기술 기고문(Zachariah Peterson, 2021-05 작성, 2026-01 갱신). 열 손실 계산, PSRR 특성, FPGA 복합 전원 설계 전략을 다룬다.

## 구조

- **LDO 열 손실 공식**: P_heat = (Vin - Vout) × Iout. 예: 12V→3.3V, 3A → LDO 손실 26.1W, 방열 필요.
- **스위칭 레귤레이터(벅) 손실**: 동일 조건에서 약 1W (효율 ~97% 가정).
- **PSRR(Power Supply Rejection Ratio)**: LDO의 주요 장점 중 하나. 일반 LDO는 ~-60dB @ 1kHz, 고주파에서 감소. 스위칭 레귤레이터는 스위칭 주파수 고조파가 출력 리플에 나타남.
- **복합 전원 설계 (FPGA 추천)**: DC-DC 1단(12V→중간 전압)으로 대전류 변환 → LDO 2단(중간→3.3V/1.8V 등)으로 노이즈 억제. 중간 전압을 최종 전압보다 약간 높게 설정해 LDO 압차(dropout)를 최소화.
- **LDO 선택 기준**: 저압차 필요 시, 저전류 보조 레일, 아날로그/RF/클럭 노이즈 민감 회로 근처.
- **스위칭 선택 기준**: 대전류(수백 mA 이상), Vin/Vout 비 큰 경우, 열 여유 없을 때.

## 검증·재현성

- 웹 기고문이므로 CI/테스트벤치 없음.
- 공식과 수치는 열람한 본문에서 직접 확인(L3).
- 2026-01 갱신으로 최신 정보 반영.

## 한계·위험

- 특정 IC나 보드 미지정 — 설계 원칙 수준의 가이드.
- 계산 예시는 12V→3.3V를 기준으로 하여 Basys3 USB 5V 환경과 다름.
- 스위칭 주파수 선택, EMI 필터 설계는 다루지 않음.

## 재사용 메모

Basys3의 USB 5V 입력(또는 외부 5V 어댑터) 환경에서 모터 드라이버, 센서 허브, 외부 모듈을 추가할 때 LDO와 DC-DC를 혼합하는 의사결정 근거로 활용 가능. SoC 주변장치 주도부 3.3V 레일은 LDO, 모터 전원(5~12V)은 별도 DC-DC로 분리하는 패턴을 뒷받침한다.
개조: Basys3 I/O는 3.3V이므로 열 손실 계산 시 Vin=5V, Vout=3.3V, Iout=1A(보드 전류 여유) 기준으로 LDO 손실 1.7W → 소형 SOT-223 패키지로 충분. 모터 전원이 12V일 경우 반드시 DC-DC 먼저 사용.
