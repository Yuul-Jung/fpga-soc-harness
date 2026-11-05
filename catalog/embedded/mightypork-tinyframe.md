---
name: mightypork-tinyframe
url: https://github.com/MightyPork/TinyFrame
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(임베디드 C 라이브러리, FPGA 직접 미적용)
language: C
tools: []
bus: none(직렬 바이트 스트림)
peripherals: [UART-framing, SLIP-detect]
stage: T1
license: MIT
stats: {stars: 1200, commits: 150+, last_update: 2023}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/MightyPork/TinyFrame, https://git.ondrovo.com/MightyPork/TinyFrame/raw/commit/788930eca436b4233d2945d6e12e84682b20aea5/README.md]
---

## 요약 (3줄 이내, 내 표현으로)
임베디드 C용 직렬 프레이밍 프레임워크로 헤더(타입·ID), 길이, 페이로드, 체크섬(CRC-16/CRC-32) 형식을 정의한다. SLIP 이스케이프로 프레임 경계를 처리하며 MCU 양쪽 멀티플렉싱 통신을 지원한다. FPGA RTL 구현이 아닌 C 라이브러리지만, 프레임 형식과 체크섬 방식의 참고 설계로 활용 가능하다.

## 구조
- 검색 요약 기준: 프레임 형식: SOF(1B)+ID(2B)+LEN(2B)+TYPE(1B)+PAYLOAD+CKSUM
- SLIP 감지: SOF 바이트가 페이로드에 나타날 때 이스케이프 처리
- 체크섬: CRC-32 또는 XOR 선택 가능
- unverified: 실제 소스 코드 세부 — 직접 열람하지 않음

## 검증·재현성
- 검색 요약 기준: MCU 커뮤니티에서 활발히 사용되는 성숙한 라이브러리
- FPGA/Verilog 직접 구현 없음: C 프로토타입을 RTL로 변환하려면 별도 설계 필요

## 한계·위험
- FPGA 직접 사례 없음: C 라이브러리로 RTL 개조 비용 큼
- Basys3 AXI 연결성 미확인

## 재사용 메모
- 프레임 형식을 참고해 FPGA 하드웨어 프레이밍 IP 설계 가능(내 판단)
- TinyFrame의 SOF+LEN+TYPE+CRC 구조는 AXI4-Lite 레지스터 맵과 연결하는 FSM 설계의 참고가 됨
- 개조: SLIP 감지 FSM과 CRC-16 병렬 계산기를 Verilog-2001로 새로 구현하면 MicroBlaze V에 직접 연결 가능. C 코드는 복사 금지(라이선스 MIT이나 하네스 원칙 §6, §16.3 적용)
