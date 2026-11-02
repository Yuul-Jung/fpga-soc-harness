---
name: digilent-forum-pmodamp3-basys3-i2s
url: https://forum.digilent.com/topic/1390-pmodamp3-in-verilog-with-basys-3/
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog, VHDL
tools: [Vivado]
bus: none
peripherals: [audio-i2s, Pmod-AMP3-SSM2518, MMCM-clocking]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://forum.digilent.com/topic/1390-pmodamp3-in-verilog-with-basys-3/]
---

## 요약
Basys3에서 Pmod AMP3(SSM2518)로 I2S 톱니파를 내보내려던 사용자가 겪은 실패와 해결 과정을 담은 포럼 스레드. 핵심은 샘플레이트와 MCLK/BCLK 비율을 데이터시트 제약에 맞추는 것이다.

## 구조
- 목표: standalone 모드, 0 dB 이득, BCLK=64×fs, MCLK=256×fs, fs≈39 kHz. 결과는 잡음 섞인 반전 톱니파.
- 원인 진단(스레드 답변 기준): MCLK 없이 standalone이면 BCLK가 LRCLK의 256배여야 하고 2.048~6.144 MHz 범위여서 fs가 약 8 kHz 또는 24 kHz로 제한된다. 39 kHz는 데이터시트 표에 없다.
- 해결: MMCM으로 약 12.28 MHz MCLK를 만들고 BCLK(약 1.535 MHz), LRCLK(약 47.97 kHz)를 파생. 발진기와 `i2s_tx`를 MCLK 도메인으로 옮기고 LRCLK/BCLK는 클럭이 아니라 에지 검출로 사용. 32비트 프레임에 채널당 상위 16비트 전송. MCLK/BCLK 점퍼를 MCLK 위치로 변경. MCLK 외부 출력은 DDR 출력 레지스터 권장.
- 측정 주의: 3.5 mm 잭의 슬리브는 접지가 아니라 푸시풀 출력의 반대쪽이므로 두 스피커 단자의 차이로 봐야 한다.

## 검증·재현성
- 스레드 작성자가 동작을 보고함. 코드는 작성자 GitHub 저장소(jcloiacon/synth)에 있다고 언급됨. 저장소는 이번 사이클에 열람하지 못함(blocked: 열람 권한 요청 미응답).
- 자원 사용, 타이밍, 테스트벤치: unverified: 스레드에 수치 없음.

## 한계·위험
- `i2s_tx`의 비트 카운터가 초기 조건에 의존하고 LRCLK에 동기되지 않는다고 스레드에서 지적됨.
- +12 dB 이득(JP6)에서 풀스케일 샘플은 클리핑.
- 스피커 연결 시 소리 끊김은 비전원 스피커 드라이버로 바꾸자 사라졌다고 보고됨.
- 라이선스: unverified: 스레드에 명시 없음. 코드 재사용 시 라이선스 확인 필요.

## 재사용 메모
- 내 판단: Basys3 오디오 출력 모듈의 클럭 설계 체크리스트로 유용하다(MMCM→MCLK→분주, 에지 검출). 클럭 비율을 먼저 고르고 시작해야 하는 교훈은 T2 단계 I2S 주변장치에 그대로 적용된다.
- 내 판단: 스레드 자체는 코드가 아니므로 우리 SoC에서는 `i2s_tx`를 직접 작성하고 이 카드를 근거로 쓴다.
