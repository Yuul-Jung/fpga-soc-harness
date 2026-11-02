# SoC 기술 트리 (단계별 카드 연결)

갱신: 2026-11-02 (/verify). 카드 6건 기준이며 대부분 주변장치 단위 자료다.

| 단계 | 카드 | 비고 |
|---|---|---|
| T0 | zipcpu-pmodamp2-project-ladder (T0-T2) | 핀 확인과 단음 단계 |
| T1 | wangxuan95-fpga-sdcard-file, element14-security-camera-2-sd-card-interfacing | CPU 없이 FSM으로 SD 접근 |
| T2 | digilent-forum-pmodamp3-basys3-i2s, zipcpu-sdspi, zipcpu-pmodamp2-project-ladder | I2S 송신, Wishbone 주변장치, 사다리의 CPU 단계 |
| T3 | (카드 없음) | gap: 프레임워크 기반 SoC에 SD·오디오 주변장치를 붙인 Basys3 사례 |
| T4 | columbia-4840-audio-visualizer | DE1-SoC HPS 기반, Basys3 직접 이식 불가 |
| T5 | (카드 없음) | gap: 이번 카드 범위 밖 |

- gap: T1(FSM) → T2(MMIO 주변장치) 사이에, 오디오·SD를 레지스터 맵으로 감싼 Basys3 사례가 카탈로그에 없다(내 판단).
- gap: T2 → T4 사이에 FPGA 내부 FFT(BRAM 제약) 사례가 없다. Columbia는 하드웨어 FFT를 포기했다.
