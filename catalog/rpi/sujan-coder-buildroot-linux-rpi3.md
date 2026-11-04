---
name: sujan-coder-buildroot-linux-rpi3
url: https://github.com/sujan-coder/Buildroot-Linux-for-Raspberry-Pi-3
source_type: repo
vendor: neutral
board: [Raspberry Pi 3 Model B]
fit_basys3: needs-port
cpu: none(Linux ARM Cortex-A53)
language: Shell
tools: [Buildroot, BusyBox v1.37.0, Linux 6.12.41, GCC arm-none-linux-gnueabihf 10.3]
bus: none
peripherals: [SSH, 네트워크(기본)]
stage: T0
license: MIT
stats: {stars: 0, commits: 86, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://github.com/sujan-coder/Buildroot-Linux-for-Raspberry-Pi-3]
---

## 요약

Buildroot를 이용해 Raspberry Pi 3용 최소 Linux 이미지를 처음부터 만드는 학습용 저장소.
BusyBox, rootfs, 부트로더 등 Linux 구성 요소를 직접 실험하며 익히는 것이 목표다.
SSH·기본 네트워크만 포함한 최소 구성이며, GCC 크로스 컴파일 절차도 함께 기록되어 있다.

## 구조

- 보드: Raspberry Pi 3 Model B Rev 1.2 (`raspberrypi3_defconfig`)
- 부팅 흐름: 부트로더 → 커널(Linux 6.12.41) → rootfs 마운트(ext4) → BusyBox init → 셸
- 파일시스템: ext4, 이미지 `output/images/sdcard.img`를 `dd`로 SD 카드에 기록
- 크로스 컴파일: `arm-none-linux-gnueabihf-g++ -static` 으로 프로그램 빌드 후 SCP 전송
- 커스터마이징: `make menuconfig`, `make linux-menuconfig`, `make busybox-menuconfig`

## 검증·재현성

- 빌드: 호스트 패키지 설치 → `make raspberrypi3_defconfig` → `make` → `dd` 기록 → SSH 접속
- 별·CI 없음(stars 0, CI 미확인); README의 출력 예시는 Linux 6.12.41/BusyBox 1.37.0 기준
- README에 `dd bc=4M` 오탈자 발견(내 판단: 올바른 옵션은 `bs=4M`)

## 한계·위험

- stars 0, CI 없음; 커밋 86개이나 갱신일 미확인(last_update unverified)
- 초보 학습용으로 최소 구성에 집중, 실시간 커널·부트 최적화는 없음
- BusyBox 버전과 커널 버전이 README 출력 예시 기준이므로 현재 Buildroot defconfig에 따라 달라질 수 있음

## 재사용 메모

- Basys3 SoC 검증용 호스트 측 최소 Linux를 RPi로 구성할 때 이 절차를 참고할 수 있다.
- 개조: FPGA는 아니므로 CPU 코어는 옮길 수 없다. BusyBox 초기화 절차(sysfs/proc 마운트 → 모듈 로드 → 앱 실행)는 FPGA SoC 위의 소프트코어 Linux에서 initramfs 구성 시 같은 순서로 적용 가능하다. `make linux-menuconfig`를 통한 커널 최소화 접근법은 MicroBlaze V 위의 커널 구성 참고 자료로 쓸 수 있다.
