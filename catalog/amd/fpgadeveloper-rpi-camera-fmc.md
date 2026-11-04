---
name: fpgadeveloper-rpi-camera-fmc
url: https://github.com/fpgadeveloper/rpi-camera-fmc
source_type: repo
vendor: amd
board: [ZCU104, VCK190, PYNQ-ZU, Opsero AUBoard 15P]
fit_basys3: no
cpu: none(FSM)
language: Verilog
tools: [Vivado 2025.2, PetaLinux, Yocto]
bus: AXI4-Stream
peripherals: [camera, video-vga]
stage: T4
license: MIT
stats: {stars: 미확인, commits: 미확인, last_update: 2026-10}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
unverified_source_rev: 루트 README 열람; 커밋 SHA 미확인
sources: [https://github.com/fpgadeveloper/rpi-camera-fmc]
---

## 요약

Opsero RPi Camera FMC(OP068) 보드로 최대 4개의 RPi Camera Module 2(IMX219) 또는 Pcam 5C를 Zynq UltraScale+/Versal에 연결하는 오픈소스 디자인. MIPI CSI-2 → ISP Pipeline IP → Video Mixer → DisplayPort/HDMI/DVI 완성 파이프라인. MIT 라이선스.

## 구조

- 카메라 최대 4채널, FMC 커넥터를 통한 MIPI CSI-2 수신.
- IP 체인: MIPI CSI-2 Rx Subsystem(Xilinx 상용 IP) → ISP Pipeline IP → Video Mixer → 출력(DisplayPort 또는 HDMI/DVI).
- 소프트웨어 스택: PetaLinux/Yocto 기반 Linux + V4L2 드라이버.
- 베어메탈 버전: AUBoard 15P에서 Linux 없이 동작(README 서술, 세부 미확인).
- 빌드: `python3 build.py` 스크립트로 Vivado/PetaLinux 프로젝트 생성.

## 검증·재현성

- 지원 보드 목록에서 각 조합별 CI 상태 뱃지 제공(문서 직접 서술).
- Vivado 2025.2 필요.
- FMC 커넥터와 Opsero OP068 하드웨어 모듈이 필수.

## 한계·위험

- Basys3 적용 불가: FMC 커넥터 없음, Xilinx MIPI CSI-2 Rx Subsystem(상용 유료 IP) 필요, Zynq US+/Versal의 MPSoC에 종속.
- 1-lane 모드에서 대역폭 제한(README 서술).
- 라이선스: MIT이나 Xilinx MIPI CSI-2 Rx Subsystem IP는 Xilinx 상용 IP 라이선스 별도.
- PetaLinux 버전 의존성 높음.
- unverified: 베어메탈 AUBoard 15P 세부 절차 미열람.

## 재사용 메모

- Basys3 직접 포팅 불가(FMC·MPSoC 필수). 개조: MIPI CSI-2 → ISP → Video Mixer의 IP 체인 구조와 V4L2 소프트웨어 드라이버 연결 패턴은 Artix-7(Basys3) 계열 CSI-2 수신 설계(D-PHY 없는 ISERDES 방식, chili-chips-ba-openeye-camsi 카드 참고)에서 ISP 처리 단계를 나누는 방식의 참고로 쓸 수 있다. 상용 MIPI IP 없이 ISERDES만으로 CSI-2를 받는 접근의 대조 사례로 가치가 있다(내 판단). 코드 반입 금지(Xilinx 상용 IP 혼재).
