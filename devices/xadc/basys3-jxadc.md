# Basys3 JXADC 아날로그 입력 (XADC)

갱신: 2026-11-03 · 등급: L3 (아래 출처 열람, 숫자는 출처 표기 값) · 근거 카드: digilent-basys-3-xadc-demo, umd-phys495-basys3-xadc-voltmeter, unilim-vahid-xadc-basys3-vhdl

## 인터페이스
- Basys3는 JXADC 헤더에 차동 아날로그 4쌍(XA1~XA4)을 낸다. 채널 대응은 XA1=6, XA2=14, XA3=7, XA4=15 (출처: https://digilent.com/reference/programmable-logic/basys-3/demos/xadc).
- XADC는 12비트 1 MSPS ADC로, 단극성 입력 범위는 0~1 V이다. 핀 1·7 = 패키지 핀 J3·K3 = VAUXP6/VAUXN6 (출처: https://www.physics.umd.edu/hep/drew/495/xadc.html).
- DRP 주소: VAUX 채널은 0x10~0x1F, VAUX6 = 0x16. 단일 채널 모드는 레지스터 0x41의 시퀀서 비트 0011, 채널 선택은 0x40 (출처: UMD 페이지, https://docs.amd.com/r/en-US/ug480_7Series_XADC/Single-Channel-Mode).
- 12비트 결과는 16비트 워드의 상위에 정렬. 1 LSB 약 0.244 mV (UMD 페이지 표기).

## 전압과 보호 (주의)
- 3.3 V 신호나 5 V 센서 출력을 직접 연결하지 않는다. 0~1 V로 낮추는 분압·앞단이 필요하다 (내 판단: 범위 초과 입력은 최대 코드로 클리핑된다고 하지만 아래 한도를 넘으면 손상될 수 있음).
- UG480 인용 글 기준(Digilent 포럼 게시글에 옮겨진 내용, 원문 직접 열람은 못 함): 입력은 VCCADC(1.8 V)를 100 mV까지 넘거나 GND 아래로 100 mV까지 내려가도 손상이 없고, 직렬 저항 100 Ω 이상이면 전류가 1.0 mA로 제한된다 (출처: https://forum.digilent.com/topic/25249-basys-3-xadc-overvoltage-protection/). 이 값은 UG480 원문으로 재확인이 필요하다(unverified).
- 입력 임피던스 약 10 kΩ, 샘플링 커패시턴스 약 3 pF, 충분한 정밀도까지 충전 약 270 ns (UMD 입출력 페이지 표기: https://physics.umd.edu/hep/drew/495/basys3io.html).

## 타이밍 주의
- 연속 모드는 느린 DC에 적합. 빠르게 변하는 신호는 이벤트 모드 또는 앞단 증폭이 필요 (UMD 표기).
- 클럭 분주 설정은 문서마다 불일치하므로 UG480의 ADCCLK 상한으로 직접 계산한다 (umd-phys495-basys3-xadc-voltmeter 한계 항목 참고).

## 구현 카드
- digilent-basys-3-xadc-demo (공식 데모), umd-phys495-basys3-xadc-voltmeter (Verilog 단일 채널), unilim-vahid-xadc-basys3-vhdl (VHDL 이벤트·두 채널), shashankr-basys3-fpga-robotic-arm (가변저항 → 서보)
