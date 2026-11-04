# 주변장치 종합: 오디오 (audio-i2s, audio-pwm)

갱신: 2026-11-02 (/verify, 카드 3건 기준. 포럼 카드는 이번 사이클 재대조 실패 → 표에 표시)

| 항목 | 카드 | 보드 | CPU/버스 | 주변장치 | 한계 |
|---|---|---|---|---|---|
| Pmod AMP3 I2S 포럼 | digilent-forum-pmodamp3-basys3-i2s | Basys3 | none(FSM) / none | I2S 송신, MMCM MCLK | 이번 사이클 재열람 실패(status 참조), 코드 저장소 미열람, 라이선스 unknown |
| Pmod AMP2 PWM 사다리 | zipcpu-pmodamp2-project-ladder | iCE40 계열 (Basys3 needs-port) | none(FSM) → 12단계에서 CPU / none | 1비트 PWM, BRAM 재생 | 인라인 코드 오류 다수, 라이선스 unknown |
| Columbia 오디오 시각화 | columbia-4840-audio-visualizer | DE1-SoC | ARM HPS / Avalon | WM8731 코덱 I2C+I2S, VGA | 하드웨어 FFT 미완성, 문서 내 수치 불일치 |

## 패턴
- 사실: PWM 경로는 직렬 버스가 없고(AMP2 카드), I2S 경로는 MCLK/BCLK/LRCLK 비율 제약이 있다(포럼 카드의 스레드 서술).
- 사실: Columbia 사례는 FPGA가 캡처·필터, CPU가 FFT를 맡는 분할이었고 FFT를 하드웨어로 옮기는 데 실패했다.
- 내 판단: 난이도 순서는 PWM(클럭 제약 없음) → I2S(클럭 설계 필요) → 샘플 처리/FFT(BRAM과 고정소수점 설계 필요)이다.

## 교훈
- 내 판단: I2S는 클럭 비율을 먼저 고르고 시작한다(포럼 카드). 단, 포럼 카드는 이번 사이클 재대조를 못 했으므로 이 교훈의 수치는 L3 확정이 아니라 "수집 세션 기록 기준"이다.
- 내 판단: Columbia 보고서처럼 문서 안 수치가 어긋날 수 있으므로(5.185 Hz vs 계산값 5.859 Hz) 테스트벤치가 수치를 직접 검사하게 만든다.
