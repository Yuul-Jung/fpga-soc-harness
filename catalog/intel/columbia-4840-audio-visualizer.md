---
name: columbia-4840-audio-visualizer
url: https://www1.cs.columbia.edu/~sedwards/classes/2024/4840-spring/reports/Audio-Visualizer-report.pdf
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: ARM HPS (Linux)
language: SystemVerilog, C
tools: [unverified: 보고서 요약에서 도구 버전 확인 못함]
bus: Avalon
peripherals: [audio-i2s, video-vga, WM8731-codec, accelerator]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-07
sources: [https://www1.cs.columbia.edu/~sedwards/classes/2024/4840-spring/reports/Audio-Visualizer-report.pdf]
---

## 요약
Columbia CSEE 4840(2024 봄) 학생 프로젝트 보고서. DE1-SoC에서 마이크 입력을 WM8731 코덱으로 받아 FPGA가 캡처·필터링하고, ARM(HPS)이 FFT로 음높이를 찾아 VGA 스프라이트 게임 화면으로 보여준다.

## 구조
- 코덱: FPGA가 I2C로 레지스터 11개(R0~R9, R15)를 설정. 마스터 모드, 48 kHz, 마이크 입력. AUD_XCK 12.288 MHz 생성. 샘플은 16비트, Avalon 읽기 레지스터로 전달.
- FPGA: 코덱 제어, 샘플 캡처, 약 11~4200 Hz 대역통과 필터, VGA 스프라이트 렌더링(ROM에 숫자·문자·음표 블록).
- HPS: 인터럽트 기반 샘플 수집, 8192점 FFT(보고서는 빈 간격 5.185 Hz로 적음), 최고점 검출 후 음표 매핑
  - 변경: 이전 카드는 "5.185 Hz = 48000/8192"로 썼으나 산술이 맞지 않음. 48000/8192 ≈ 5.859 Hz(내 계산). 보고서 값 5.185 Hz는 보고서 내 불일치로 취급(2026-11-02 재열람)., 스프라이트 위치 전송.
- 메모리: 온칩 512 KB 중 약 384 KB로 48 kHz 2초 분량 버퍼. 정식 메모리맵은 없고 Avalon 읽기 0x0000만 서술.

## 검증·재현성
- 종단 간(알려진 샘플 → Avalon → 소프트웨어) 데이터 검증이 디버깅에 핵심이었다고 서술.
- 자원(LUT 등)과 타이밍: unverified: 보고서 요약에 없음.

## 한계·위험
- 하드웨어 FFT는 미완성(버터플라이/트위들 주소 지정과 고정소수점 정밀도 문제), 소프트웨어로 후퇴.
- 문서 내 불일치: 샘플 크기 4바이트 표기 vs 드라이버 16비트 전송, 테스트 코드의 샘플레이트 정의(30000) vs 계산의 48 kHz. 피크 탐색은 앞 700빈만 대상(5.859 Hz/빈이면 약 4.1 kHz, 내 계산; 이전 카드의 "약 3.6 kHz"는 5.185 Hz 기준).
- 추가 불일치(재열람): 마일스톤은 좌우 채널 혼합, 예산은 모노, 제어 코드는 오른쪽 ADC 채널만 전달. 하드웨어 대역통과 하한 11 Hz가 소프트웨어 피크 탐색에는 적용되지 않음(탐색이 bin 0부터).
- 라이선스: unknown. 학생 보고서이므로 코드 복사 금지.

## 재사용 메모
- 내 판단(S6 실패 사례): Basys3에는 HPS가 없으므로 FFT를 FPGA 안에서 해야 한다. 이 보고서는 "하드웨어 FFT는 메모리 주소와 고정소수점 설계를 먼저 계획해야 한다"는 근거가 된다. 작은 FFT(예: 64~256점)와 BRAM 용량 제약으로 범위를 줄이는 쪽이 현실적이다.
- 내 판단: Basys3 대응물은 코덱 대신 Pmod I2S2(라인 입력) + VGA 막대 스펙트럼이다(내 판단, 해당 Pmod 사양은 미확인).
