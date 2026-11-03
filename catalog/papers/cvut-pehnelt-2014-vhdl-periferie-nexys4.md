---
name: cvut-pehnelt-2014-vhdl-periferie-nexys4
url: https://dspace.cvut.cz/bitstream/handle/10467/23765/F3-BP-2014-Pehnelt-Tomas-prace.pdf
source_type: paper
vendor: amd
board: [Nexys4]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Xilinx ISE, ModelSim/iSim(실패), ASIX Sigma 로직 분석기]
bus: none
peripherals: [sensor, comm-uart, comm-i2c, 1-wire(DS18B20), single-wire(DHT11), seven-segment]
stage: T2
license: unknown (CTU 학위논문, 코드 공개 여부 unverified)
stats: {published: 2014}
doc_language: en
status: 본문은 체코어(doc_language 허용값에 없어 en으로 표기)
verification: L3
checked_at: 2026-11-03
sources: [https://dspace.cvut.cz/bitstream/handle/10467/23765/F3-BP-2014-Pehnelt-Tomas-prace.pdf]
unverified: DHT11 FSM의 상세 타이밍 수치와 DS18B20 외 회로(풀업 저항값·Pmod 핀 배정)는 요약 열람 범위에서 확인하지 못함. LUT/FF 등 자원 수치는 논문에 없음.
---

## 요약
프라하 공과대(CTU) 2014 학사 논문(체코어). Nexys 4(Artix-7)에서 VHDL만으로 온도·습도 센서 세 종(ADT7420 I2C, DS18B20 1-Wire, DHT11 단선)을 읽어 7세그먼트와 UART(9600 baud)로 내보내는 소형 기상대를 만들었다. 압력 센서는 비용 때문에 제외했다.

## 구조
- 보드는 Digilent Nexys 4, 외부 센서 DS18B20·DHT11은 Pmod 커넥터에 연결, 출력은 7세그먼트 8자리와 온보드 FTDI UART 브리지(논문 서술).
- DS18B20 컴포넌트 `dsb`: 100 MHz 클럭에서 1 µs 틱을 만들어 FSM을 박자 맞춘다. 상태는 시작 → 리셋 펄스(버스 Low 500 µs) → 100 µs 대기 → 프레즌스 판독 → 400 µs 대기 순이고, 프레즌스가 없으면 처음 상태로 돌아간다.
- 명령 단계에서 Skip ROM(0xCC)과 Convert T(0x44)를 LSB부터 보낸다. 쓰기 슬롯은 비트 값에 따라 1 µs 뒤 해제(1) 또는 80 µs 뒤 해제(0)로 나뉜다.
- 변환 대기는 750 ms 고정 대기(12비트 해상도). 이후 다시 리셋 → Skip ROM → Read Scratchpad(0xBE)로 16비트(온도 2바이트)만 읽고, 읽기 슬롯 시작 12 µs 뒤에 샘플한다.

## 검증·재현성
- 주 검증은 실기 동작이다. 시뮬레이터(ModelSim, iSim)가 저자의 Windows 8/8.1에서 동작하지 않아 로직 분석기로 디버깅했다고 한다. 논문에 제시된 분석기 파형은 I2C 경로 것이고 DS18B20 파형은 없다.
- 장시간 동작 후 ADT7420이 DS18B20보다 최대 5 °C 높게 읽혔고, 저자는 주변 칩 발열로 설명한다(저자 서술, 원인 미검증).
- 자원 사용 수치는 논문에 없다.

## 한계·위험
- Skip ROM을 쓰므로 버스에 DS18B20이 한 개일 때만 동작한다(여러 개면 충돌).
- 스크래치패드 앞 16비트만 읽고 CRC 검사는 하지 않는다(요약 열람 기준으로 CRC 언급 없음).
- 변환을 750 ms 고정 대기로 처리해 완료를 폴링하지 않는다(응답 지연이 느림).
- 체코어 본문, 라이선스 불명. 코드를 가져오려면 라이선스 확인 필요. 저자 개인정보는 기록하지 않음.
- 도구가 ISE이므로 Vivado로 옮기려면 프로젝트를 새로 만들어야 한다.

## 재사용 메모
- 내 판단: 1 µs 틱을 기준으로 한 FSM 구조는 클럭 분주 하나와 상태 열거만으로 끝나서 Basys3(100 MHz)에 그대로 맞는다. Nexys 4와 같은 Artix-7이라 Pmod 핀 매핑과 xdc만 바꾸면 되는 needs-port 사례다.
- 내 판단: Basys3에 DS18B20을 붙이려면 Pmod 1핀이 양방향(오픈드레인, 외부 풀업 약 4.7 kΩ 권장, 근거: [analog-maxim-interfacing-ds18x20](analog-maxim-interfacing-ds18x20.md))이어야 하고, 3.3 V 급전이 가능하다.
- 개조: 이 설계는 CPU가 없는 FSM이라 CPU 종속이 없다. IP 표준 AXI4-Lite 래퍼로 감싸 (제어: 변환 시작, 상태: busy/presence/crc_ok, 온도 16비트 레지스터, 변환 완료 인터럽트) 형태로 옮길 수 있다. 고정 750 ms 대기는 소프트웨어 폴링 또는 타이머 인터럽트 방식으로 바꾸고, Skip ROM 대신 Match ROM 선택을 레지스터화하는 것이 개선점이다(내 판단).
