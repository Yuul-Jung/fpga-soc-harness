# 수집 로그

형식:
- collect: `YYYY-MM-DD HH:MM | collect | <주제 · 전략> | 카드 +N | 아이디어 +I | 큐 잔여 K | blocked B`
- verify: `YYYY-MM-DD HH:MM | verify | 재열람 N | 수정 M | 불일치 K | 승격 L2→L3 P | ready +R`
- capstone: `YYYY-MM-DD HH:MM | capstone | <slug> | 등급 S0~S2` 또는 `... | skip: <사유>`

2026-11-02 11:12 | collect | Basys3 오디오·I2S · S7 난이도 사다리(주)+S6 실패 사례(보조) | 카드 +3 | 아이디어 +2 | 큐 잔여 8 | blocked 1
2026-11-02 12:08 | collect | Basys3 SD 카드 (SPI) · S5 비정형 출처(주)+S1 인접 도메인(보조) | 카드 +3 | 아이디어 +2 | 큐 잔여 13 | blocked 1
2026-11-02 12:48 | verify | 재열람 5(blocked 1) | 수정 5 | 불일치 2 | 승격 L2→L3 0 | ready +1
2026-11-02 13:05 | capstone | mmio-sd-spi-block-reader (I-003) | 등급 S2 (CI 3회차 통과: lint pass, sim PASS 2/2, synth LUT 497·FF 350 yosys 추정; 1·2회차 실패 원인=SD CS 글리치)
2026-11-02 13:13 | collect | Basys3 카메라 (OV7670, SCCB) · S4 제약 역전(주)+S6 실패 사례(보조) | 카드 +3 | 아이디어 +2 | 큐 잔여 23 | blocked 1
2026-11-02 14:07 | collect | Basys3 PS/2·USB HID · S2 조합 탐색(주)+S6 실패 사례(보조) | 카드 +3 | 아이디어 +2 | 큐 잔여 30 | blocked 0
2026-11-02 15:14 | collect | Basys3 UART/SPI/I2C 센서 허브 · S1 인접 도메인(주)+S3 빈틈 추적(보조) | 카드 +3 | 아이디어 +1 | 큐 잔여 35 | blocked 1
2026-11-02 15:41 | verify | 재열람 0(WebFetch 권한 미응답으로 10건 모두 blocked) | 수정 0(카드 status 기록 10건, 라이선스 메모 1건) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 없음)
2026-11-02 16:16 | collect | Basys3 이더넷·Bluetooth·CAN 통신 · S5 비정형 출처(주)+S7 난이도 사다리(보조), 이더넷은 검색 결과 부족으로 미착수 | 카드 +3 | 아이디어 +1 | 큐 잔여 43 | blocked 1
2026-11-02 17:31 | collect | MicroBlaze/MicroBlaze V Basys3 사용자 AXI 주변장치 · S7 난이도 사다리(주)+S3 빈틈 추적(보조) | 카드 +3 | 아이디어 +1 | 큐 잔여 50 | blocked 3
2026-11-02 18:13 | collect | PicoRV32 Basys3 SoC (PicoSoC 포팅 사례) · S4 제약 역전(주)+S6 실패 사례(보조: raw 열람 차단) | 카드 +3 | 아이디어 +1 | 큐 잔여 51 | blocked 2
2026-11-02 18:41 | verify | 재열람 0(WebFetch 권한 미응답, 신규 카드 9건 미검증) | 수정 0 | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 없음)
2026-11-02 18:51 | capstone | skip: ready 아이디어 없음(raw 9·vetted 3·used 1), 근거 카드 rechecked_at 부재로 심사 보류 상태. CI는 success
2026-11-02 19:13 | collect | Intel/Altera DE10-Nano·DE1-SoC 캡스톤 · S2 조합 탐색(주)+S7 난이도 사다리(보조) | 카드 +3 | 아이디어 +1 | 큐 잔여 59 | blocked 1
2026-11-02 20:03 | collect | Lattice iCE40/ECP5 주변장치 · S1 인접 도메인(주)+S6 실패 사례(보조) | 카드 +3 | 아이디어 +1 | 큐 잔여 64 | blocked 0
2026-11-02 20:03 | verify | 재열람 5 | 수정 2 | 불일치 2(wangxuan95-can 하드웨어 시험 서술 미확인, unipi PERIOD 추정→사실) | 승격 L2→L3 0(소스 본문 미열람) | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 3건 미만)
2026-11-02 20:06 | capstone | mmio-pwm-tune-vga-bars (I-001) · 사용자 지시('무조건 실행')로 게이트 3(ready·rechecked_at) 건너뜀 | 로컬 시뮬레이터 없음 S0, CI 대기 | check/audit 오류 0
2026-11-02 20:07 | capstone | CI 감사 오류 수정: tinredmc-ultralitebldc source_rev 형식(unverified 사유를 unverified_source_rev로 이동). mmio-pwm-tune-vga-bars는 lint/sim(2 PASS)/synth 통과(LUT 325, FF 253 yosys 추정)
2026-11-02 20:09 | collect | 한국어 FPGA 종합설계·캡스톤 보고서 · S5 비정형 출처(주)+S2 조합 탐색(보조): 한국어 직접 후보 부족으로 국내 학회 논문 2건+PID 저장소 | 카드 +3 | 아이디어 +1 | 큐 잔여 72 | blocked 1
2026-11-02 21:10 | collect | H-브리지 모듈(TB6612·DRV8833·L298N) 인터페이스 · S3 빈틈 추적(주)+S5 비정형 출처(보조): devices/ 비어 있어 부품 데이터시트 2건+Basys3 L298 위키 | 카드 +3 | 아이디어 +0(I-014 근거 보강) | 큐 잔여 75 | blocked 0
2026-11-02 21:50 | verify | 재열람 0(WebFetch 권한 요청 무응답 2회: TI DRV8833·Toshiba TB6612FNG, 원문 대조 불가로 blocked) | 수정 1(embeddedts 카드 라이선스 경고 해소, 원문 무관) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 3건 미만)
2026-11-02 22:45 | collect | 직교 엔코더 디코더 RTL · S4 제약 역전(주: 소형 FSM/BRAM 불필요 설계)+S7 난이도 사다리(보조) | 카드 +3 | 아이디어 +1 | 큐 잔여 79 | blocked 0
2026-11-02 23:53 | collect | FPGA 고정소수점 PID · S2 조합 탐색(주: 엔코더+PWM+응답 캡처)+S1 인접 도메인(보조: MCU 앱노트) | 카드 +3 | 아이디어 +1 | 큐 잔여 84 | blocked 1
2026-11-03 01:04 | collect | 스텝모터 가감속 FSM · S6 실패 사례(주: 스텝 손실 원인)+S1 인접 도메인(보조: MCU 프로파일 알고리즘) | 카드 +3 | 아이디어 +1 | 큐 잔여 83 | blocked 0
2026-11-03 01:12 | capstone | skip: ready 아이디어 없음(raw/vetted만 존재, 게이트 3 미충족). 게이트 1(최신 CI 성공)·2(broken 없음)는 충족
2026-11-03 01:30 | verify | 재열람 0(WebFetch 권한 요청 무응답: 1runxu·hakan-demirli·wdevore, 원문 대조 불가로 blocked, 우회 안 함) | 수정 0 | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(신규 모터 카드 rechecked_at 없음), check 통과·audit 오류 0
2026-11-03 02:09 | collect | IMU(MPU-6050) 자세 추정 · S5 비정형 출처(주: 강의 설계문서·학술지)+S3 빈틈 추적(보조: 고급 사다리) | 카드 +3 | 아이디어 +1 | 큐 잔여 87 | blocked 1
2026-11-03 02:36 | collect | 2륜 균형 로봇 FPGA · S7 난이도 사다리(주: 쉬움 PD → PID → EKF)+S4 제약 역전(보조: 1K 메모리 최소 분업) | 카드 +3 | 아이디어 +1 | 큐 잔여 90 | blocked 0
2026-11-03 03:25 | collect | 도립진자 LQR · S2 조합 탐색(주: 엔코더+스텝모터+상태 되먹임)+S1 인접 도메인(보조: 제어공학 교과 프로젝트) | 카드 +3 | 아이디어 +1 | 큐 잔여 93 | blocked 1
2026-11-03 03:41 | verify | 재열람 0(WebFetch 권한 요청 무응답 재발: andreicito2 원문 대조 불가로 blocked, 우회 안 함) | 수정 1(andreicito2 재사용 메모에 라이선스 확인 필요 문구, 감사 경고 해소; 원문 대조 아님) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 없음), check 통과·audit 오류 0
2026-11-03 04:08 | collect | 적응·자동 튜닝 PID · S6 실패 사례(주: 릴레이 한계·가정 위반 조건)+S5 비정형 출처(보조: 기사·학회 논문) | 카드 +3 | 아이디어 +1 | 큐 잔여 102 | blocked 0
2026-11-03 05:07 | collect | BLDC/PMSM FOC · S7 난이도 사다리(주: 6스텝 → FOC → 약계자)+S1 인접 도메인(보조: 짐벌·EV 모터 제어) | 카드 +3 | 아이디어 +1 | 큐 +7 | blocked 0
2026-11-03 06:08 | collect | 입출력 조합(마이크·가속도 + MAX7219·DFPlayer) · S2 조합 탐색(주: 마이크+가속도→매트릭스)+S1 인접 도메인(보조: Arduino 기울기 표시 이식) | 카드 +3 | 아이디어 +1 | 큐 +8 | blocked 0
2026-11-03 06:41 | verify | 재열람 0(WebFetch 권한 요청 무응답 재발, GitHub MCP는 범위 밖: 원문 대조 불가로 blocked, 우회 안 함) | 수정 1(wangxuan95-fpga-foc source_rev 형식 오류 해소: 값 없는 unverified 필드 제거, 본문에 unverified 사유 유지; 원문 대조 아님) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 없음), check 통과
2026-11-03 06:50 | capstone | skip: ready 아이디어 없음(raw 21·vetted 2건뿐, 게이트 3 미충족). 게이트 1(최신 CI 성공 afb680c)·2(broken 없음)는 충족
2026-11-03 07:10 | collect | CPU 중립화 개조(NEORV32·PicoRV32 → AXI4-Lite IP 표준) · S3 빈틈 추적(주: CPU 트랙 개조 gap)+S1 인접 도메인(보조: 소프트코어 주변장치 규약 이식) | 카드 +3 | 아이디어 +1 | 큐 +5 | blocked 0
2026-11-03 08:07 | collect | 이더넷 W5500·Pmod NIC100 · S7 난이도 사다리(주: 핀 직결 → Pmod MAC/PHY → 칩 내장 스택)+S5 비정형 출처(보조: 포럼·WIZnet Makers 글) | 카드 +3 | 아이디어 +1 | 큐 잔여 128 | blocked 1
2026-11-03 09:12 | collect | 프레임 버퍼 없는 VGA 타일·라인 렌더링 · S4 제약 역전(주: no-dram 우회)+S2 조합 탐색(보조: 제어 루프 값 + 타일 VGA 계기판) | 카드 +3 | 아이디어 +1 | 큐 잔여 136 | blocked 0
2026-11-03 09:45 | verify | 재열람 0(WebFetch 권한 요청 무응답 2회 연속: zipcpu-llvga, stnolting-neorv32; 원문 대조 불가로 blocked, 우회 안 함) | 수정 0 | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(rechecked_at 가진 근거 카드 부족, 재열람 없이 점수 부여 안 함) | audit 오류 0 경고 6, check 통과 | 미재열람 신규 카드 9건(neorv32, unipi-cds105, picorv32, digilent-forum-ethernet, nic100, wiznet-w5500, zipcpu-llvga, columbia-4840, raybox-zero)
2026-11-03 10:07 | collect | 서보 액추에이터 조합(조이스틱·XADC → 서보) · S6 실패 사례(주: 서보 구동 교훈·전원 분리)+S2 조합 탐색(보조: JSTK2+서보) | 카드 +3 | 아이디어 +1 | 큐 잔여 144 | blocked 0
2026-11-03 11:08 | collect | 디스플레이 사다리(LCD1602·SSD1306·ST7789) · S7 난이도 사다리(주: 병렬 → SPI 단색 → SPI 컬러)+S5 비정형 출처(보조: 포럼·위키·강의 소개) | 카드 +3 | 아이디어 +1 | 큐 잔여 153 | blocked 1
2026-11-03 12:13 | collect | 1-Wire DS18B20·DHT11 FSM · S1 인접 도메인 이식(주: Maxim MCU 문서 타이밍 → FPGA FSM)+S6 실패 사례(보조: 고정 대기·Skip ROM 한계) | 카드 +3 | 아이디어 +1 | 큐 잔여 162 | blocked 1
2026-11-03 12:40 | verify | 재열람 0(WebFetch 권한 요청 무응답 3회 연속, vhdlwhiz-rc-servo-controller 재시도도 PROVENANCE_REQUIRED; 우회 안 함) | 수정 0 | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(rechecked_at 근거 카드 부족) | audit 오류 0 경고 6, check 통과 | 미재열람 신규 카드 누적 18건(직전 9 + shashankr-basys3-fpga-robotic-arm, vhdlwhiz-rc-servo-controller, digikey-forum-jstk2-pmod-controller-vhdl, digilent-pmod-oled-reference-manual, lushaylabs-tang-nano-9k-ssd1306-oled, masterplayer-lcd-st7789-sv, cvut-pehnelt-2014-vhdl-periferie-nexys4, analog-maxim-interfacing-ds18x20, opencores-onewire-ds1820) | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 12:50 | capstone | skip: ready 아이디어 없음(vetted 2건, 나머지 raw; 게이트 3 미충족). 게이트 1(최신 CI 성공 a3699f2)·2(broken 없음)는 충족
2026-11-03 13:08 | collect | Bluetooth HC-05/HC-06 UART 브리지 · S1 인접 도메인 이식(주: Arduino AT 설정 라이브러리 → FPGA 절차)+S7 난이도 사다리(보조: 수신 전용 → 설정 → 텔레메트리) | 카드 +3 | 아이디어 +1 | 큐 잔여 168 | blocked 0
2026-11-03 14:08 | collect | Basys3 XADC 아날로그 센서 입력 · S3 빈틈 추적(주: sensor 태그·devices 빈 곳)+S5 비정형 출처(보조: 강의·개인 튜토리얼·포럼) | 카드 +3 | 아이디어 +1 | 큐 잔여 173 | blocked 0 | 부수: topics 비어 §12.2-3로 주제 3개 추가, add_repo/register_repo_root 도구 없음(기존 clone 사용)
2026-11-03 15:07 | collect | I2C 시계·메모리(DS3231·24LC) · S2 조합 탐색(주: RTC+EEPROM 로거)+S1 인접 도메인 이식(보조: MCU 드라이버 롤오버·ACK 폴링 → FSM) | 카드 +3 | 아이디어 +1 | 큐 잔여 183 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 15:41 | verify | 재열람 0(WebFetch 권한 요청 무응답/PROVENANCE_REQUIRED 4회 연속; 우회 안 함) | 수정 1(ndroid-hc06 source_rev 형식 오류 → audit 오류 0) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(rechecked_at 근거 카드 부족) | 미재열람 카드 누적 약 40건 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 16:08 | collect | IR 리모컨 NEC 디코더 · S2 조합 탐색(주: IR 입력 + 모터/서보 조종)+S6 실패 사례(보조: 반복 코드 미구현·NEC 미시험) | 카드 +3 | 아이디어 +1 | 큐 잔여 193 | blocked 1 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 17:07 | collect | Arduino 모터 제어(TB6612FNG 엔코더 PID) · S5 비정형 출처(주: 제조사·커뮤니티 튜토리얼·블로그)+S4 제약 역전(보조: MCU 1체배·100 ms 창 한계 → 하드웨어 4체배) | 카드 +3 | 아이디어 +0(I-013 근거 보강) | 큐 잔여 200 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; catalog/arduino/ 신설
2026-11-03 18:07 | collect | Arduino 통신 모듈(nRF24L01·LoRa SX1278) · S7 난이도 사다리(주: nRF24 SPI → LoRa 확장 단계)+S5 비정형 출처(보조: 위키·블로그 튜토리얼) | 카드 +3 | 아이디어 +1 | 큐 잔여 207 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 18:41 | verify | 재열람 0(WebFetch PROVENANCE_REQUIRED 재발; 우회 안 함) | 수정 4(source_rev 형식 오류 → audit 오류 0) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류 | 미재열람 누적 약 50건 | 부수: add_repo 도구 없음, 기존 clone 사용
2026-11-03 18:51 | capstone | skip: ready 아이디어 없음(vetted 2건, raw 33건; 게이트 3 미충족, rechecked_at 근거 카드 부족으로 심사 보류 중). 게이트 1·2는 미확인 갱신 없음 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 19:08 | collect | Arduino 센서 허브(MPU-6050·BMP280·NEO-6M) · S3 빈틈 추적(주: 센서 허브·I2C/UART 혼합 빈 곳)+S1 인접 도메인 이식(보조: Arduino 로거·HUD → 허브 IP·7세그) | 카드 +3 | 아이디어 +1 | 큐 잔여 212 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 20:08 | collect | Arduino 디스플레이(SSD1306·MAX7219) · S6 실패 사례(주: OLED 멈춤·쓰레기 픽셀 포럼 글)+S5 비정형 출처(보조: 튜토리얼 블로그) | 카드 +3 | 아이디어 +0(I-024·I-0xx 기존과 겹쳐 신규 없음) | 큐 잔여 216 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-03 21:20 | collect | Arduino 캡스톤급(RC카·로봇 팔) · S2 조합 탐색(주: IR 명령+초음파 회피+서보 스캔)+S7 난이도 사다리(보조: 반응형 차 → 가르치기 팔) | 카드 +3 | 아이디어 +1 | 큐 잔여 242 | blocked 1 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; WebFetch는 이번엔 동작
2026-11-03 21:42 | verify | 재열람 0(WebFetch PROVENANCE_REQUIRED 9/9 실패; 우회 안 함) | 수정 1(masher1-gogo-car source_rev 형식 오류 → audit 오류 0) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류 | 미재열람 누적 약 59건 | 부수: add_repo 도구 없음, 기존 clone 사용
2026-11-03 22:11 | collect | Arduino↔Basys3 인터페이스 변환(SPI 마스터·레벨 변환) · S1 인접 도메인 이식(주: Arduino 마스터 → FPGA SPI 슬레이브)+S4 제약 역전(보조: pmod-only 3.3V 제약 → 방향별 레벨 변환) | 카드 +3 | 아이디어 +1 | 큐 잔여 252 | blocked 1 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; 열람 13건 검색 7회
2026-11-03 23:08 | collect | STM32 모터 제어(타이머 엔코더 모드·PID) · S3 빈틈 추적(주: stm32 카드 0건 도메인 개설)+S1 인접 도메인 이식(보조: MCU 엔코더 타이머 → FPGA 엔코더 IP 레지스터) | 카드 +3 | 아이디어 +0(I-016에 근거 보강) | 큐 잔여 258 | blocked 1 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; 열람 4건 검색 4회
2026-11-04 00:15 | collect | ESP32 센서 허브(FreeRTOS·SPI 슬레이브·ICE-V Wireless) · S5 비정형 출처(주: 튜토리얼 블로그·README)+S2 조합 탐색(보조: ESP32 Wi-Fi 창구 + FPGA 주변장치) | 카드 +3 | 아이디어 +0 | 큐 잔여 266 | blocked 1 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; 검색 4회 열람 6건 중 SHA 2건 거부
2026-11-04 00:41 | verify | 재열람 0(WebFetch PROVENANCE_REQUIRED 2/2 실패, 권한 요청 무응답; 우회 안 함) | 수정 1(controllerstech 카드 라이선스 확인 필요 문구 추가, audit 경고 해소) | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류 | 미재열람 누적 약 68건 | 부수: add_repo 도구 없음, 기존 clone 사용
2026-11-04 00:51 | capstone | skip: 게이트 1·3 미충족 — ready 아이디어 없음(심사 보류), 최신 CI(verify) 실패: 'MkDocs 빌드' 단계가 mkdocs --strict에서 'docs/index.html이 index.md와 충돌' 경고로 중단(로컬 재현). docs/ 생성물(tools/build.py의 index.html)과 mkdocs docs_dir 겹침은 구조 결정이라 무인 사이클에서 고치지 않음 — 사람 확인 필요 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용
2026-11-04 01:08 | collect | STM32 HAL 기초(CubeMX 생성 코드·HAL vs LL) · S7 난이도 사다리(주: 생성 코드 구조 → HAL/LL 선택)+S5 비정형 출처(보조: 블로그·뉴스레터·포럼) | 카드 +3 | 아이디어 +0 | 큐 잔여 271 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; 검색 3회 열람 3건
2026-11-04 02:07 | collect | STM32 FreeRTOS(스택 오버플로·HAL 타임아웃·UART 설계) · S6 실패 사례(주: 포럼 실패·원인 추적)+S5 비정형 출처(보조: 포럼 스레드) | 카드 +3 | 아이디어 +0 | 큐 잔여 278 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; 검색 3회 열람 4건
2026-11-04 03:12 | collect | STM32 모터 제어(상보 PWM·데드타임·FOC 기초) · S1 인접 도메인 이식(주: MCU 상보 PWM/데드타임 → FPGA PWM IP 레지스터)+S5 비정형 출처(보조: 블로그·포럼) | 카드 +3 | 아이디어 +0 | 큐 잔여 285 | blocked 0 | 부수: add_repo/register_repo_root 도구 없음, 기존 clone 사용; 검색 3회 열람 4건
2026-11-04 03:42 | verify | 재열람 0(WebFetch PROVENANCE_REQUIRED 3/3 실패: 신규 stm32 카드 출처, 권한 요청 무응답; 우회 안 함) | 수정 0 | 불일치 0 | 승격 L2→L3 0 | ready +0 | 아이디어 심사 보류(근거 카드 rechecked_at 없음) | 미재열람 누적 약 77건 | check 통과, audit 오류 0 경고 6 | 부수: add_repo 도구 없음, 기존 clone 사용
