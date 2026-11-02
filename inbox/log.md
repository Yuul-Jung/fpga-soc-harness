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
