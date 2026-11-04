---
name: chili-chips-ba-openeye-camsi
url: https://github.com/chili-chips-ba/openeye-CamSI
source_type: repo
vendor: amd
board: [Trenz TE0711-01 SoM (Artix-7 XC7A35T)]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado, openXC7]
bus: AXI4-Stream
peripherals: [camera, comm-eth]
stage: T4
license: BSD-3-Clause
stats: {stars: 미확인, commits: 미확인, last_update: 2026-10}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
unverified_source_rev: 루트 README 열람; 커밋 SHA 미확인
sources: [https://github.com/chili-chips-ba/openeye-CamSI]
---

## 요약

Artix-7 XC7A35T(Trenz TE0711-01 SoM)에서 D-PHY 칩 없이 IBUFDS/IDELAY/ISERDES 프리미티브만으로 MIPI CSI-2를 수신하는 오픈소스 카메라 파이프라인. 카메라: IMX219(RPi V2.1, 2-lane, 720p@60Hz), IMX283(4-lane, 1080p@30Hz), OV2740(2-lane). ISP: 디베이어 + 데드픽셀 보정 + 수동 노출. UDP 1GbE 스트리밍. BSD-3-Clause.

## 구조

- **핵심 혁신**: D-PHY 외부 칩 없이 Artix-7 IBUFDS(차동 입력) + IDELAY2(지연 보정) + ISERDES2(1:4 직렬→병렬 변환)으로 CSI-2 DPHY 레인을 직접 수신. 클럭 복원도 ISERDES 기반.
- 라인 버퍼 스트리밍: 프레임 버퍼 없이 AXI-Stream 라인 단위로 ISP까지 스트리밍(no-DRAM 제약을 역이용한 S4 설계).
- CDC: AsyncFIFO로 카메라 클럭 도메인 → 처리 클럭 도메인 교차.
- ISP 단계: Debayer(Bayer → RGB) + Dead Pixel Correction + 수동 노출 제어.
- 출력: UDP 1GbE 스트리밍(이더넷 MAC 포함).
- 보드: Trenz TE0711-01 SoM은 XC7A35T 기반으로 Basys3와 동일 FPGA 계열.

## 검증·재현성

- Vivado 프로젝트 포함(README 서술). openXC7 오픈소스 툴체인도 지원.
- 한계: Artix-7 토글 속도로 FHD@60Hz 불안정; IMX283 4-lane은 센서 비닝(binning)이 필요(README 서술).
- openXC7 툴체인에서 타이밍 클로저 문제 보고(README 서술).
- CI 없음(자체 확인).

## 한계·위험

- Basys3 직접 빌드 불가: Trenz TE0711-01 SoM 전용 핀맵, 1GbE PHY 없음(Basys3는 이더넷 없음), MIPI CSI-2 카메라 커넥터 없음.
- Artix-7 ISERDES 최대 토글 속도 한계로 FHD@60Hz(600 Mbps/레인) 불안정(README 직접 서술).
- IMX283 4-lane 완전 동작 미검증(README 서술).
- openXC7 타이밍 클로저 미달 보고 있음.

## 재사용 메모

- Basys3 포팅 가능성: 같은 XC7A35T이므로 IBUFDS/IDELAY2/ISERDES2 프리미티브 코드는 직접 사용 가능. 단, Basys3에 CSI-2 카메라 커넥터가 없으므로 Pmod 핀으로 단일 레인 CSI-2 또는 병렬 카메라(OV7670 등)로 대체하거나, IMX219를 플렉스 케이블 직결 Pmod 어댑터로 연결하는 방안이 필요(내 판단, 하드웨어 미확인). 라인 버퍼 스트리밍과 AsyncFIFO 패턴, ISP 단계 분리(Debayer → Dead Pixel → AXI-Stream)는 반입 조건을 갖추면(BSD-3-Clause, 사용자 승인) 그대로 가져올 수 있다. 개조: 1GbE UDP 출력을 Basys3 VGA(25MHz 픽셀 클럭) 출력으로 대체하고, CSI-2 D-PHY 수신 레인을 OV7670 병렬 픽셀 버스(8비트 + PCLK/HSYNC/VSYNC)로 교체하면 Artix-7 ISERDES 없이도 카메라 ISP 사다리의 T2→T4 패키지로 이어진다(I-051 아이디어). 1GbE 대신 VGA 출력으로 교체할 수 없는 부분: UDP/MAC 계층은 완전 별도 설계 필요.
