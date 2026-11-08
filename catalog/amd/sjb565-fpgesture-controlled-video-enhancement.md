---
name: sjb565-fpgesture-controlled-video-enhancement
url: https://github.com/sjb565/Fpgesture-controlled-video-enhancement
source_type: repo
vendor: amd
board: [Spartan-7-XC7S50]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified
tools: [Vivado]
bus: SPI
peripherals: [camera-ov7670, video-hdmi, debug-7seg, debug-led]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: 2023}
doc_language: en
verification: L3
checked_at: 2026-11-08
source_rev:
sources: [https://fpga.mit.edu/videos/2023/team37/report.pdf]
---

## 요약

MIT 6.2050 과목(2023년)의 2인 1조 프로젝트. AMD Spartan-7(XC7S50) FPGA 2개를 SPI로 연결해 하나는 OV7670 카메라로 손 제스처를 인식하고, 다른 하나는 별도 OV7670에서 받은 비디오를 제스처 명령대로 B-스플라인 4× 업스케일 → HDMI 출력한다. 블롭 개수와 위치로 5가지 명령을 인코딩하는 방식으로, CNN 없이 색상 임계치+연결 성분 분석만 사용한다.

## 구조

- **보드**: FPGA 2개(제스처 보드, 영상 보드) — 보드 명칭 미기재, Spartan-7 XC7S50-CSG324A
- **카메라**: OV7670 각 1개(총 2개), 320×240 @30fps, 16비트 컬러
- **제스처 인식 파이프라인**: 빨강 채널 임계치 → 5×5 다운샘플 → 3상태 FSM(WAITING→COUNTING→DIVIDING) 연결 성분 블롭 라벨링 → 무게중심 계산 → 블롭 수·상대 위치로 명령 결정
- **통신**: SPI 3바이트(명령 패킷), Pmod 포트 사용
- **영상 처리**: B-스플라인 계수 기반 4× 업스케일, 60fps HDMI/TMDS 출력
- **자원**: LUT 21%, DSP48E1 2/120, BRAM 약 67%
- **타이밍**: 클럭 74.25 MHz, 데이터 경로 8.839 ns (슬랙 여유 있음)
- **검증**: PSNR 25.63 dB (35,000 ImageNet 샘플), OpenCV bicubic 25.79 dB에 근접

## 검증·재현성

- MIT 최종 보고서(PDF) 직접 열람으로 L3 확정
- GitHub URL은 보고서에서 확인: https://github.com/sjb565/Fpgesture-controlled-video-enhancement
- GitHub README 본문은 PROVENANCE_REQUIRED로 열람 불가: `unverified: 빌드 방법·라이선스 미확인`
- 보고서의 PSNR 수치와 자원 사용량은 L3 출처(내 판단: 신뢰 가능)

## 한계·위험

- 블롭 라벨 병합 미완성: 대각선이나 계단형 모양에서 레이블이 과다 계산됨
- 장갑 기울기 45° 초과 시 하나의 손가락 블롭이 2개로 분리됨
- 조명 변화(색온도, 밝기)에 따라 임계치 재조정 필요
- 지원 명령 5개만(블롭 수 기반 인코딩이 주)
- SPI 2-FPGA 구성이므로 Basys3 단일 보드 포팅 시 1보드에 압축 필요
- 라이선스 미확인: 코드 복사 금지

## 재사용 메모

제스처+영상처리 2단 파이프라인을 2개의 Spartan-7 보드로 나눠 구현한 참고 구조. Basys3(Artix-7)로 옮기려면 ① HDMI → VGA(25 MHz), ② 2-FPGA SPI → 단일 보드 내부 버스, ③ XC7S50 → XC7A35T(LUT 약 절반, BRAM 차이 확인 필요) 조정이 필요하다.
개조: 블롭 수+위치 기반 명령 디코더 FSM은 MicroBlaze V SoC의 AXI4-Lite 슬레이브로 감싸면 소프트웨어에서 동적으로 임계치를 조정할 수 있다. 영상 업스케일 블록은 AXI4-Stream 인터페이스로 감싸면 MicroBlaze V 가속기 패턴과 호환된다(내 판단).
