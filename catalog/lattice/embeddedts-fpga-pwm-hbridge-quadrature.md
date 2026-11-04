---
name: embeddedts-fpga-pwm-hbridge-quadrature
url: https://support.embeddedts.com/support/solutions/articles/22000203294-fpga-pwm-h-bridge-motor-controller-with-quadrature
source_type: article
vendor: lattice
board: [Technologic Systems TS-75xx SBC 계열 (Lattice XP2)]
fit_basys3: needs-port
cpu: 호스트 SBC의 CPU가 소프트웨어 PID 실행 (FPGA 내부 CPU 없음)
language: unverified: 글에 소스 미게재 (헤더 주석만)
tools: [unverified: 글에 없음]
bus: Wishbone (16비트 레지스터 19개)
peripherals: [actuator-servo, sensor]
stage: T2
license: 제한적 (제작사 제품 전용 사용 허용, 오픈소스 아님)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://support.embeddedts.com/support/solutions/articles/22000203294-fpga-pwm-h-bridge-motor-controller-with-quadrature]
---

## 요약
Technologic Systems 지원 문서(2012 작성으로 표기). Lattice XP2 FPGA에 DC 모터 8채널 PWM, H-브리지 제어, 4채널 직교 엔코더 카운터를 넣은 코어를 설명하고, 호스트 리눅스의 소프트웨어 PID가 이를 레지스터로 읽고 쓴다. PWM+엔코더 IP의 레지스터 배치 사례로 가치가 크다.

## 구조
- PWM 8채널, 약 1.5 kHz, 듀티 8비트(본문은 0-255, 레지스터 표는 0-256으로 서술이 불일치).
- 채널별 H-브리지 활성화 비트와 과전류 보호: 전류 한계가 걸리면 활성화를 일시 해제.
- 직교 카운터 4개(16비트, 읽기 전용), 인덱스 펄스 카운터 4개(16비트). 직교를 끄면 자유 실행 업카운터/에지 카운터로 바뀜.
- 레지스터 맵(Wishbone, 16비트 폭): 0x00~0x0E PWM 듀티 0~7, 0x10~0x16 직교 카운트 0~3, 0x18~0x1E 인덱스 카운트 0~3, 0x20 설정(H-브리지 활성, 인덱스 활성·극성, 직교 활성), 0x22 GPIO 입력, 0x24 과전류 상태.

## 검증·재현성
- 자원: 133 LUT, 68 FF (Lattice XP2, 글 서술). 테스트벤치, 타이밍: unverified: 글에 없음. 소스는 제작사 FTP에 있다고 하며 열람하지 않음.

## 한계·위험
- 글에 적힌 한계: DC 모터 전용, 스테퍼·RC 서보(50 Hz)에는 부적합. 소프트웨어 PID 전제.
- 라이선스: GPL 등이 아니며 제작사 제품에서만 쓰도록 안내 → 코드 반입 불가, 레지스터 구성의 사실만 참고.

## 재사용 메모
- 내 판단: 133 LUT 수준의 작은 코어에 PWM·엔코더·과전류 상태를 한 레지스터 맵으로 묶은 구성은 A 트랙 모터 IP의 레지스터 설계 참고로 좋다. 다만 IP 표준 래퍼는 채널 묶음보다 IP 하나에 기능 하나를 권하므로(config/ip_standard.json 확인 필요) 분리해 설계하는 편이 맞다.
- 내 판단: 과전류 시 H-브리지 활성화를 끄고 상태 비트로 남기는 안전 구조는 전기 규칙(모터 전원 분리)과 잘 맞는 요소로 가져올 만하다.
- 라이선스 확인 필요: 제작사 제품 전용 사용 허용이며 오픈소스가 아니므로 코드는 가져오지 않고 레지스터 구성 같은 사양만 참고한다(§6.3, §16.3 G0).
- 개조: Wishbone 16비트 레지스터를 AXI4-Lite 32비트 레지스터로 옮기고 PWM 1.5 kHz는 모듈 선택에 맞게 분주값을 레지스터로 둔다. 호스트 CPU 연결부는 옮길 수 없다.
