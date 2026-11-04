---
name: codeproject-de10-nano-self-balancing-robot
url: https://api.codeproject.com/Articles/1274595/Self-Balancing-Robot-Based-on-the-Terasic-DE10-Nan
source_type: article
vendor: intel
board: [DE10-Nano]
fit_basys3: needs-port
cpu: Nios II (기본), ARM HPS (대안)
language: Verilog 또는 VHDL (소프트 IP, 글 서술)
tools: [Quartus]
bus: unverified: 글에 Qsys/Avalon 상세 없음
peripherals: [sensor, actuator-servo, comm-bt]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://api.codeproject.com/Articles/1274595/Self-Balancing-Robot-Based-on-the-Terasic-DE10-Nan]
---

## 요약
CodeProject 글. Terasic DE10-Nano(Cyclone V SoC)로 2륜 자가 균형 로봇을 만든다. IMU, 홀 엔코더, 초음파, 블루투스 센서 인터페이스는 FPGA 소프트 IP, 균형·이동 알고리즘은 기본적으로 Nios II에서 돌고 ARM HPS(Linux)에서 돌리는 대안 모드가 있다. 모터 제어 사다리의 고급 단계 사례.

## 구조
- 구동: 별도 보드의 Toshiba TB6612FNG 모터 드라이버, FPGA가 제어 신호를 보내고 센서·블루투스도 그 보드에 있다.
- 센서: MPU-6500(가속도+자이로+DMP, 버스 종류는 글에 없음), 각 모터 축의 홀 센서 엔코더(위상차로 방향, 일정 시간 펄스 수로 속도, 회전당 펄스 수 미기재), 초음파(10 cm 이내 정지, 10~20 cm 이동체 추종), 블루투스 모듈(스마트폰 앱 제어), 선택 사양 8 MP 카메라.
- 제어: 균형은 기울기 각도 PD(칼만 필터로 각도 잡음 감소), 속도는 홀 엔코더 PI, 회전은 엔코더+자이로 PD.

## 검증·재현성
- 이득값, 필터 파라미터, 제어 주기, 자원 사용, 저장소 링크: unverified: 글에 없음.

## 한계·위험
- 글에 라이선스 표기 없음 → unknown, 저자에게 문의하라고만 안내(글 서술). 코드 반입 금지.
- 소스·하드웨어 설계 파일 접근 경로를 확인하지 못해 구조는 글 서술 범위로 제한.
- 모터 보드가 별도 맞춤 보드라 부품 구성을 그대로 재현하기 어렵다.

## 재사용 메모
- 내 판단: 제어 구조(각도 PD + 속도 PI + 회전 PD의 3루프)와 센서 구성(IMU+엔코더+초음파)은 A 트랙 고급 단계 설계 근거로 쓸 수 있다. 균형 로봇은 TB6612(H-브리지), MPU, 엔코더 IP가 모두 있어야 하므로 앞 단계 IP가 선행된다(S7 사다리 연결).
- 개조: Nios II 전용 Qsys 연결은 못 옮긴다. 센서 IP(엔코더 계수, I2C/SPI IMU 읽기)의 레지스터와 FSM만 IP 표준 래퍼로 옮기고, 알고리즘은 MicroBlaze V 소프트웨어(고정소수점)로 옮기는 것을 검토(내 판단). 5V 모듈이 섞이면 레벨 변환 필요.
