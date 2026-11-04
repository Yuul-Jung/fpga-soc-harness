---
name: vhdplus-spectrum-analyzer-max7219
url: https://vhdplus.com/docs/community/spectrum
source_type: article
vendor: intel
board: [VHDPlus Core MAX10]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL(VHDPlus)
tools: [unverified]
bus: none
peripherals: [audio-i2s, accelerator, display-dot-matrix]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://vhdplus.com/docs/community/spectrum]
unverified: 자원 사용(LUT/메모리), 도구 버전, 예제 저장소의 라이선스와 커밋 SHA(페이지는 leonbeier의 라이브러리 저장소를 가리키나 열람하지 않음)
---

## 요약
MEMS 마이크(I2S)의 소리를 FFT로 16개 주파수 대역으로 나누어 MAX7219 4개짜리 8x32 LED 매트릭스에 막대로 그리는 소리 시각화기 튜토리얼이다. 입력(I2S) → 분석 → SPI 출력이 한 줄로 이어지는 "마이크+매트릭스" 조합의 가장 작은 형태다.

## 구조
- 클럭 12 MHz, 샘플링 10 kHz, 대역 16개(페이지 서술).
- 모듈: I2S_IN(좌·우 채널 읽기), Spectrum_Analyzer(FFT), MAX7219_Interface, SPI. 최상위 Main이 스펙트럼 값을 매트릭스 열 비트맵으로 바꾸고 갱신을 트리거한다.
- 볼륨 나눗셈과 오프셋으로 감도를 조정한다. 매트릭스는 5V라서 레벨 변환기를 두었다고 적혀 있다.
- 문제 해결 절에 매트릭스가 어두움, 마지막 열이 계속 켜짐, 감도 낮음 사례가 있다.

## 검증·재현성
- 시뮬레이션이나 테스트벤치 언급은 확인하지 못함(unverified). 보드에서 눈으로 확인하는 튜토리얼 형태.

## 한계·위험
- 라이선스 미기재. 페이지의 코드는 VHDPlus 전용 문법·라이브러리 의존이라 그대로는 Vivado에 못 넣는다(내 판단).
- FFT의 구현 방식(자체 IP인지 외부 코어인지)은 페이지에서 설명하지 않았다.

## 재사용 메모
- 내 판단: Basys3 이식 시 Pmod I2S2 대신 단일 I2S 마이크 모듈(3.3V)과 MAX7219(5V, 레벨 변환) 조합이 같은 구조다. 16대역 FFT는 BRAM이 아닌 작은 DSP 파이프라인이면 충분해 보이나 자원은 측정 전 모름.
- 라이선스 확인 필요. 코드는 가져오지 않고 구조(입력→분석→열 비트맵→SPI)만 참고한다.
- 개조: MAX7219 인터페이스는 레지스터(열 데이터 버퍼, 밝기, 갱신 트리거)로 두고, 스펙트럼 값 쓰기는 MicroBlaze V C 또는 별도 FSM이 하도록 IP 표준 AXI4-Lite 래퍼로 옮긴다. 아키텍처가 CPU 비종속이라 옮기기 쉽다(내 판단).
