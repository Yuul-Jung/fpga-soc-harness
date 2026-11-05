---
name: byu-ecen423-lab10-riscv-vga-7seg
url: https://byu-cpe.github.io/ecen423/labs/lab-10
source_type: course
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: RISC-V(custom forwarding pipeline)
language: SystemVerilog
tools: [Vivado]
bus: MMIO(custom)
peripherals: [video-vga, 7seg-mux, hid-btn, hid-sw]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://byu-cpe.github.io/ecen423/labs/lab-10]
---

## 요약

BYU ECEN 423(컴퓨터 아키텍처) 고급 과정 Lab 10. 포워딩 RISC-V 파이프라인 프로세서 위에 메모리 맵 VGA 텍스트 컨트롤러(80×30 chars, 640×480, 12비트 RGB 전·배경색)와 7세그먼트 카운터를 동시에 구동한다. 소프트웨어(RISC-V 어셈블리)로 두 디스플레이를 제어하는 완전한 SoC 사례이다.

## 구조

- CPU: 포워딩 RISC-V 파이프라인 (5단계, Basys3 구현)
- VGA: 메모리 맵 텍스트 컨트롤러, 80×30 문자, 12비트 RGB 전경·배경색, 640×480@60Hz
- 7세그먼트: 메모리 맵 카운터 (유효 버튼 이동 시 증가, 시작 시 0으로 초기화)
- 소프트웨어: RISC-V 어셈블리(`move_char.s`) — 이동 가능한 스마일 캐릭터 + netID 표시, VGA+7세그 동시 제어
- 버스: 커스텀 MMIO 주소맵(AXI-Lite 아님, 과목 전용)
- 도구: SystemVerilog + Vivado + Makefile + Vivado Tcl 스크립트
- 완료 시간 기준(2022): 평균 4.8시간 (복잡도 중상)

## 검증·재현성

- 과목 과제이므로 공개 GitHub 레포 없음 (스켈레톤 제공 추정)
- 과목 단위 테스트·시뮬레이션 존재 (강의 자료에서 언급, 세부 미열람)
- CI: 없음(과목 환경)
- unverified: 정확한 MMIO 주소맵, 소스 파일 구조, 라이선스

## 한계·위험

- 공개 소스 아님 (과목 과제 스켈레톤) — 직접 복사 불가
- MMIO 버스가 AXI4-Lite 아닌 과목 전용 프로토콜 — MicroBlaze V에 그대로 이식 불가
- T4~T5 복잡도: 파이프라인 CPU + VGA 텍스트 + 7세그먼트를 동시에 다루는 고급 사례

## 재사용 메모

- VGA 텍스트 컨트롤러(80×30, MMIO)와 7세그먼트를 소프트웨어(어셈블리)로 함께 제어하는 패턴 — MicroBlaze V 소프트웨어 드라이버 설계에 직접 참고 가능
- 개조: ① VGA 텍스트 컨트롤러의 레지스터 구조(문자 버퍼 주소, 색상 레지스터)를 AXI4-Lite 슬레이브로 재구현 → 동결 맵의 VIDEO 슬롯 배정; ② 7세그먼트는 `mmio-7seg-adv-ip`로 대체; ③ 어셈블리 드라이버 로직 → C 드라이버 + xparameters.h로 이식. CPU 코어는 옮길 수 없고, MMIO 버스 프로토콜만 AXI4-Lite로 교체하면 대부분의 구조적 아이디어를 가져올 수 있음
