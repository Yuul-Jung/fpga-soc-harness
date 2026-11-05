---
name: olivier-le-sage-camera-filters
url: https://github.com/olivier-le-sage/camera-filters
source_type: repo
vendor: neutral
board: [Spartan Edge Accelerator, XC7S50]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [camera-ov2640, video-hdmi, gamma-correction, yuv-conversion]
stage: T4
license: MIT
stats: {stars: 34, forks: 17, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/olivier-le-sage/camera-filters, https://github.com/olivier-le-sage/camera-filters/blob/master/README.md]
---

## 요약

Spartan-7(XC7S50) 기반 실시간 카메라 필터 파이프라인. OV2640에서 영상을 받아 감마 보정·Y'UV 색공간 변환을 하드웨어에서 처리해 HDMI로 출력. 곱셈기·LUT 없이 시프트 연산만으로 근사.

## 구조
- 보드: Spartan Edge Accelerator (Xilinx Spartan-7 XC7S50 탑재 아두이노 쉴드 형태).
- 카메라: OV2640, DVIO 인터페이스.
- 출력: HDMI (1080p 또는 보드 지원 해상도).
- 감마 보정: piecewise linear approximation 방식. 시프트 연산으로만 구현(곱셈기·BRAM LUT 없음). 감마 2.2 및 1.4를 타깃으로, Excel로 근사 계수를 사전 계산 후 RTL에 하드코딩.
- 색공간 변환: BT.601 기준 RGB→Y'UV. 행렬 계수를 "×32 반올림 ÷32" 형태 add/subtract+shift로 근사.
- 자원 추정: README 기준 약 500 LUTs, 약 100 FFs.
- open issue 1건(내용 미열람).

## 검증·재현성
- Vivado로 합성 성공, README에 LUT/FF 수치 보고.
- 보드 동작 확인 보고(README 스크린샷 제공).
- Basys3(XC7A35T)는 타겟 아님. BRAM LUT 없는 순수 시프트 근사이므로 Artix-7 합성 가능성은 높으나, Spartan Edge의 클럭·핀·카메라 인터페이스 xdc가 그대로 적용 안 됨.
unverified: 감마 근사 오차(최대 ΔL* 등)는 README에 미기재. OV2640 초기화 절차(I²C/SCCB) 소스 내용 미열람.

## 한계·위험
- Spartan Edge 보드 전용 xdc. Basys3 포팅 시 OV2640 Pmod 연결 및 HDMI 출력 핀 재설계 필요.
- 감마 근사를 Excel로 개발 → 계수 최적성 미검증.
- RGB→Y'UV 근사 오차 범위 미명시.
- HSV→RGB 변환 없음.
- 1 open issue 미열람.

## 재사용 메모
- 시프트 기반 piecewise-linear 감마 보정 패턴을 Basys3 AXI4-Lite RGB LED IP의 감마 경로에 직접 차용 가능.
- BT.601 행렬 근사 방식(add/subtract+shift)은 색공간 변환 블록을 LUT/DSP 없이 구성하는 최소 면적 사례로 참고 가능.
개조: MIT 라이선스. 카메라·HDMI 계층 제거 후 감마 보정(시프트 근사)과 Y'UV 변환 블록만 떼어 Basys3 AXI4-Lite 슬레이브로 감싸는 자체 RTL 재작성 가능. 클럭 도메인은 Basys3 100 MHz 단일 클럭으로 단순화. 감마 2.2 근사 계수는 소스를 참고해 조정하되, 직접 코드 복사 대신 계수 아이디어만 착용. 내 판단: 곱셈기/BRAM 없이 감마 보정 구현하는 근거 사례로 가치 있음. 직접 포팅보다 패턴 착안 재작성 권장.
