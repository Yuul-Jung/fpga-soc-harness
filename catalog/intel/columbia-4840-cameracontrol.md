---
name: columbia-4840-cameracontrol
url: https://www.cs.columbia.edu/~sedwards/classes/2022/4840-spring/reports/CameraControl-report.pdf
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: ARM HPS (Linux)
language: SystemVerilog, C
tools: [Quartus]
bus: Avalon
peripherals: [camera, video-vga, accelerator]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2026-11-02 /verify 재열람 시도 실패(WebFetch 권한 요청 미응답) — 이번 사이클 미대조, rechecked_at 미기록
sources: [https://www.cs.columbia.edu/~sedwards/classes/2022/4840-spring/reports/CameraControl-report.pdf]
---

## 요약
Columbia CSEE 4840(2022 봄) 학생 보고서. DE1-SoC에서 OV7670 영상을 받아 Sobel 필터 유무를 HPS 사용자 프로그램으로 전환하며 VGA로 보여준다. 클럭 도메인 4개의 동기화 어려움 때문에 범위를 줄였다고 적었다.

## 구조
- 카메라: OV7670, 640x480 최대 30 fps, YUV 4:2:2(픽셀당 2바이트), SCCB(SIOC/SIOD)로 설정. 설정 모듈이 끝나면 done 신호로 캡처 FSM을 연다.
- 버퍼: 듀얼포트 BRAM에 640x480 깊이 8비트 워드(보고서 서술). 쓰기는 카메라 PCLK, 읽기는 VGA 픽셀 클럭. Sobel용 라인 버퍼 2개(3x3 윈도, 길이 800 서술, 코드 기본값 798/800 불일치).
- PLL 클럭: 본문은 100/50/25/12.5/130 MHz, 코드에는 150 MHz 출력도 있음. 레지스터: Avalon 주소 0x00, 0x01이 필터 모드 비트, 나머지는 0. HPS 쪽은 ioctl 기반 `get_filter()`·`set_filter()`.
- VGA 타이밍: 640x480, 수평 FP16/SYNC96/BP48, 수직 FP4/SYNC2/BP35.

## 검증·재현성
- 시험 절차·결과, 프레임률, 자원 사용: unverified: 보고서에 없음.

## 한계·위험
- 보고서가 밝힌 교훈: 클럭 도메인 4개(FPGA, VGA, 카메라, SCCB) 동기화와 다단 파이프라인 타이밍이 어려웠고 범위를 축소함(S6 실패 사례).
- 보고서 내부 불일치: 라인 버퍼 길이 800 대 798, 클럭 목록. 소스 저장소 링크 미확인 → 코드 열람 불가.
- 라이선스 정보 없음 → unknown.

## 재사용 메모
- 내 판단: 카메라 → BRAM → VGA의 2클럭 경계(PCLK/픽셀 클럭)를 듀얼포트 BRAM으로 분리하는 구조는 Basys3에서도 같다. 단 640x480x8비트(약 2.4 Mbit, 내 계산)는 Basys3 BRAM 용량(unverified: 공식 자료 미열람)을 넘을 가능성이 있어 해상도 축소(예: 320x240 이하)가 전제다. Basys3 BRAM 용량은 별도 카드로 확인해야 한다.
- 내 판단: 도메인 수를 줄이는 설계(SCCB를 저속 클럭 enable로 처리)가 실패 요인을 직접 겨냥한 개선점이다.
