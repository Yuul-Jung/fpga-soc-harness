---
name: kurokishi592-ee2026
url: https://github.com/Kurokishi592/EE2026
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [camera-ov7670, video-vga, actuator-servo]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-08
source_rev:
sources: [https://kennethwongcunwi.pages.dev/projects/object-tracker-fpga]
---

## 요약

Basys3(Artix-7)에 OV7670 카메라를 Pmod 핀으로 연결해 색상 기반 블롭 탐지(UFDS 연결 성분 분석)로 물체를 추적하고, VGA로 바운딩 박스를 표시하며 팬-틸트 서보로 카메라를 물체 중심에 정렬하는 EE2026 과목 프로젝트. CNN 없이 순수 하드웨어 FSM으로 실시간 색상 추적을 구현한다.

## 구조

- 최상위 단일 비트스트림: OV7670 캡처(SCCB 설정 포함), 가우시안 블러·중앙값 필터, RGB 임계치 모듈, 에로드/딜레이트 형태학 처리(4개 Morphology_3x3 블록), UFDS_Detector(가중치 포함 union-find 연결 성분, 중심점·바운딩 박스 추출), BRAM 프레임 버퍼, VGA 출력(GUI 오버레이 포함), PD 제어기 2개(팬/틸트), 서보 PWM 생성기
- 카메라 프레임: 310×240 ROI로 디시메이션(BRAM 사용량 ~80% 절감)
- VGA 출력: 640×480, 바운딩 박스 오버레이, GUI(설정·드래그드롭 패널)
- BRAM 용량: Basys3 기준 약 1,800 Kbits 사용
- DSP: 90개 슬라이스 사용
- 서보: 팬-틸트 2축, 소프트웨어에서 각도 범위 클램프

## 검증·재현성

- 포트폴리오 페이지(kennethwongcunwi.pages.dev)에서 데모 영상과 포스터 링크 확인(L2)
- 실제 GitHub README 열람 미완료(PROVENANCE_REQUIRED 차단): `unverified: GitHub README 본문 확인 필요`
- 빌드 방법, CI, 자원 수치(LUT/FF)는 열람하지 못했음

## 한계·위험

- RGB 임계치 방식: 조명에 민감하며 HSV보다 색상 범위 조정이 어려움
- 외부 DRAM 없어 해상도를 310×240으로 낮춤
- UFDS는 래스터 순서로 입력이 일관적이어야 하며, 바운딩 박스는 프레임당 1회 래치
- 정량 정확도·레이턴시·프레임 속도 측정 수치 미기재
- 라이선스: 미확인 → 코드 복사 금지

## 재사용 메모

Basys3에 직접 OV7670을 연결한 완성형 사례. 블롭 탐지 → 바운딩 박스 → 서보 제어의 전체 파이프라인이 단일 Verilog 비트스트림에 들어가며, Pmod I/O 사용 패턴이 MicroBlaze V SoC로 그대로 이식 가능하다.
개조: RGB 임계치+UFDS 블록을 MicroBlaze V의 AXI4-Lite 슬레이브 IP로 감싸면(커스텀 AXI 주변장치) CNN 추론 단계 없이도 제스처 분류 FSM을 붙일 수 있다. 소형 CNN을 추가하려면 BRAM이 병목이므로 블롭 ROI를 32×32로 잘라 별도 BRAM MAC 가속기에 넘기는 2단 파이프라인 구조가 현실적이다(내 판단).
