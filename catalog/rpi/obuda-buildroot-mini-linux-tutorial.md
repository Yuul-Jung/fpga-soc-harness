---
name: obuda-buildroot-mini-linux-tutorial
url: https://www.aut.uni-obuda.hu/es/Linux%20in%20Embedded%20Systems/Tutorials/buildroot-mini-linux
source_type: course
vendor: neutral
board: [Raspberry Pi 4]
fit_basys3: needs-port
cpu: none(Linux ARM Cortex-A72)
language: Shell
tools: [Buildroot, raspberrypi4_64_defconfig, dropbear, systemd-analyze, dd]
bus: none
peripherals: [SSH(dropbear), 네트워크]
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.aut.uni-obuda.hu/es/Linux%20in%20Embedded%20Systems/Tutorials/buildroot-mini-linux]
---

## 요약

Óbuda 대학교 임베디드 Linux 강의의 Buildroot 실습 튜토리얼.
Raspberry Pi 4(AArch64)를 대상으로 최소 Linux 이미지를 만들고, stock RPi OS와 이미지 크기·부팅 시간·서비스 수를 직접 비교한다.
교육 목적의 단계별 절차서로, 측정·비교표 작성이 과제로 포함되어 있다.

## 구조

- 보드: Raspberry Pi 4, AArch64, `raspberrypi4_64_defconfig`
- 커스터마이징 항목: GUI 비활성화, ext4 루트FS, dropbear(경량 SSH) 활성화, 불필요한 라이브러리·문서 제거
- 빌드: `make -j4` (첫 빌드 약 30~90분), `output/images/sdcard.img` → `dd`로 기록
- 측정 도구: `systemd-analyze`, 프로세스 수, 패키지 수
- 기대 결과(학습자 비교용 기준치):

| 항목 | stock RPi OS | Buildroot 최소 이미지 |
|---|---|---|
| 이미지 크기 | ~4 GB | 30~100 MB |
| 부팅 시간 | 20~40 s | 3~10 s |
| 실행 서비스 수 | 100+ | 5~10 |
| 패키지 수 | ~1,500 | ~20 |

- 도전 과제: 읽기 전용 루트FS(overlayfs)·커스텀 Python 앱 추가

## 검증·재현성

- 강의용 실습 자료로 절차 단계별로 기술되어 있음; 실제 측정 결과는 학습자가 채워야 하는 빈 양식만 제공
- CI 없음; 측정 결과는 미공개

## 한계·위험

- 라이선스 불명확(대학 강의 자료로 외부 배포 조건 불명확); 코드 반입 시 확인 필요
- 측정 수치는 기대치이며 실측값이 아님; 하드웨어·버전에 따라 달라질 수 있음
- 실시간 커널 패치는 포함하지 않음

## 재사용 메모

- Basys3 SoC 검증을 위한 RPi 호스트 환경 구성 시 이미지 크기·부팅 시간 목표치로 활용할 수 있다.
- 개조: FPGA 직접 구현 사례는 아니다. 그러나 "최소 이미지로 필요한 IP만 활성화"하는 접근법은 MicroBlaze V 위의 임베디드 Linux(LiteX Linux)에서 커널 menuconfig 최적화 근거로 쓸 수 있다. dropbear 경량 SSH는 FPGA SoC 위 소프트코어 Linux에서도 같은 방식으로 적용 가능(메모리·플래시 절약).
