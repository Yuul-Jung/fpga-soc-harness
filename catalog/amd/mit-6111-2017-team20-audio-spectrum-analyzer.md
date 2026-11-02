---
name: mit-6111-2017-team20-audio-spectrum-analyzer
url: https://fpga.mit.edu/videos/2017/team20/proposal.pdf
source_type: report
vendor: amd
board: [Nexys 4]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified
tools: [Xilinx FFT IP]
bus: AXI4-Stream (FFT 코어 경계)
peripherals: [audio-i2s, sensor, video-vga, accelerator]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://fpga.mit.edu/videos/2017/team20/proposal.pdf]
unverified: 실제 구현 결과(최종 보고서는 열람하지 않음, 이 카드는 제안서 기준), 코드 공개 여부, 자원 실측
---

## 요약
MIT 6.111(2017) 한 팀의 제안서. PDM 마이크(ADMP421)를 PCM으로 바꾸고 FFT로 주파수 성분을 구해 LED 뱅크(PWM 밝기), 색 LED 음압 표시, 7세그 최대 주파수, VGA 스펙트로그램으로 보여 주는 계획이다. 문서는 제안서이므로 구현 사실이 아니라 계획으로 읽어야 한다.

## 구조
- Nexys-4(Artix-7 XC7A100T). 입력은 PDM 마이크(약 2.4 MHz 클럭)와 스위치 16개(FFT 범위·해상도).
- 모듈 14개를 우선순위(핵심/희망/여유)로 색 구분: Audio Packager(PDM→PCM 필터·데시메이션, 표본화 40 kHz 이상), FFT IP(AXI4-Stream, 크기 계산), BRAM 프레임 저장, 스펙트로그램 생성, PWM, LED 뱅크, SPL 계산, 색 LED, VGA, 최대 주파수 탐색, 7세그.
- 자원 추정(제안서): FFT 코어 1,000~10,000 LUT/FF, DSP48 최대 50, 18Kb BRAM 최대 100. 이 값은 추정이지 측정이 아니다.
- 일정은 5주 마일스톤. 위험으로 FFT 코어의 AXI4-Stream 인터페이스를 지목.

## 검증·재현성
- 제안서라 시험 결과 없음. 모듈 결합이 느슨해 기능을 추가·삭제해도 다른 곳이 안 깨진다고 서술.

## 한계·위험
- 최종 결과 미확인. 제안서의 VGA 항목은 하드웨어 제약 시 삭제 가능으로 명시.
- 이름이 비슷한 Basys3 사례와 혼동하지 말 것: 보드는 Nexys 4.

## 재사용 메모
- 내 판단: PDM→PCM→FFT→표시 모듈 분해와 우선순위 색 구분은 Basys3의 스위치·LED·7세그·VGA 자원에 그대로 대응된다. 단 Basys3(XC7A35T)의 DSP 90개, BRAM 50개 한도로 FFT 크기를 줄여야 함(내 계산 아님, 데이터시트 값 미확인).
- 개조: 표시 쪽(LED PWM, 7세그, 매트릭스)을 레지스터 맵으로 분리하면 MicroBlaze V에서 스펙트럼 값을 쓰는 구조가 된다. FFT는 하드웨어 블록으로 남기고 결과 읽기를 AXI4-Lite 레지스터로 노출한다(내 판단).
