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
