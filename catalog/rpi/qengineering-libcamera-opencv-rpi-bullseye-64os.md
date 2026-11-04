---
name: qengineering-libcamera-opencv-rpi-bullseye-64os
url: https://github.com/qengineering/libcamera-opencv-rpi-bullseye-64os
source_type: repo
vendor: neutral
board: [RPi4]
fit_basys3: needs-port
cpu: none(C++ 애플리케이션)
language: C++
tools: [libcamera, OpenCV, GStreamer]
bus: none
peripherals: [camera-csi]
stage: T3
license: BSD-3-Clause
stats: {stars: 13, commits: unknown, last_update: 2021-12-07}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://awesome.ecosyste.ms/projects/github.com%2Fqengineering%2Flibcamera-opencv-rpi-bullseye-64os]
unverified: 커밋 수·README 본문을 직접 열람하지 못함(PROVENANCE_REQUIRED), ecosyste.ms 목록 기준
---

## 요약

RPi4 + 64비트 Bullseye OS에서 libcamera와 OpenCV를 C++로 연결하는 시작점. GStreamer 1.18 파이프라인을 함께 지원한다. 검색 요약 기준; README 본문 직접 미열람.

## 구조

- libcamera(CSI 카메라 HAL) → GStreamer 파이프라인 → OpenCV Mat 변환 흐름으로 추정(내 판단, 미열람)
- RPi4 64-bit OS(Bullseye) 타깃; 32-bit 버전은 별도 저장소
- 주제 태그: libcamera, OpenCV, GStreamer, 카메라

## 검증·재현성

- unverified: 빌드·테스트 절차 미확인(PROVENANCE_REQUIRED)
- last_update 2021-12-07; 이후 libcamera 버전 변화로 빌드 깨질 가능성 있음

## 한계·위험

- 최신 Raspberry Pi OS(Bookworm)와 호환성 미확인
- 직접 열람하지 못해 정확한 API·파이프라인 흐름 불확실

## 재사용 메모

- Basys3 연결 경로: libcamera의 CSI-2 프레이밍 개념(라인 버퍼 스트리밍, Bayer → RGB)이 OV7670 SCCB 캡처 RTL 설계 참고 자료
- 개조: C++ 애플리케이션 레이어는 MicroBlaze V C 드라이버 API와 직접 연결 가능성 있으나, 별도 호스트 보드(RPi) 필요; AXI4-Lite 래퍼로 가져올 부분 없음(소프트웨어 전용)
