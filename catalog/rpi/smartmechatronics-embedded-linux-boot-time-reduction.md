---
name: smartmechatronics-embedded-linux-boot-time-reduction
url: https://medium.com/smartmechatronics/embedded-linux-boot-time-reduction-eda5f5b4c014
source_type: article
vendor: neutral
board: [Raspberry Pi 4]
fit_basys3: needs-port
cpu: none(Linux ARM Cortex-A72)
language: Shell
tools: [Yocto/BitBake, U-Boot, systemd-analyze, Grabserial, bootgraph.pl]
bus: none
peripherals: [GUI 애플리케이션, 터치 디스플레이(추정)]
stage: T1
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-09-11}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://medium.com/smartmechatronics/embedded-linux-boot-time-reduction-eda5f5b4c014]
---

## 요약

Raspberry Pi 4에서 Yocto 기반 임베디드 Linux의 부팅 시간을 약 6.71초 단축한 사례 기사.
사용자 공간·커널·부트로더 세 단계를 각각 최적화하고 측정 도구로 검증했다.
약 3일간의 작업으로 전체 부팅 시간을 의미 있게 줄인 실용적 사례다.

## 구조

| 단계 | 최적화 기법 | 단축량 |
|---|---|---|
| 사용자 공간 | systemd 제거 → 최소 init 스크립트, GUI 서비스 조기 시작, 메시징 버스 의존성 제거 | 3.56 s → 0.55 s (약 3.01 s) |
| 커널 | 비필수 드라이버를 모듈로 전환(지연 로드), 콘솔 출력 제거 | 1.9 s → 0.6 s (약 1.3 s) |
| 부트로더 | U-Boot 딜레이 제거, SD 직접 로드 스크립트, USB·네트워크 부팅 모듈 제거 | 약 2.39 s |
| 합계 | — | 약 6.71 s 단축 (약 3일 작업) |

- 측정 도구: Grabserial(시리얼 로그), systemd-analyze, bootgraph.pl(`CONFIG_PRINTK_TIME`+`initcall_debug`), dmesg
- 한계로 남긴 것: 커널 크기 축소(향후 과제로 명시)

## 검증·재현성

- 수치는 저자가 직접 측정해 본문에 명시; 측정 도구(Grabserial·bootgraph.pl)와 방법론을 함께 기술함(L3)
- 소스 코드·저장소 링크는 없음; 절차는 기사 본문으로만 확인

## 한계·위험

- Medium 기사로 라이선스 불명확; 절차 참고는 가능하나 코드 반입 대상 없음
- Yocto 기반(BitBake BSP)으로 Buildroot와 다른 빌드 시스템 사용; 직접 이식 시 레이어 구조 차이 있음
- RPi4 전용 사례로 다른 보드에서는 측정치가 다를 수 있음

## 재사용 메모

- FPGA SoC 위의 소프트코어 Linux에서 부팅 시간을 줄이는 방법론으로 직접 활용 가능하다.
- 개조: MicroBlaze V 위의 Linux(LiteX)에서 ① U-Boot 딜레이 제거·SD 직접 로드 스크립트 ② 비필수 드라이버 모듈화 ③ systemd 대신 최소 init 스크립트 접근법을 순서대로 적용할 수 있다. Grabserial과 bootgraph.pl은 FPGA SoC 보드에서도 같은 방식으로 부팅 타임라인을 측정하는 데 쓸 수 있다. 커널 크기 축소(미완성 과제)는 BRAM이 제한된 Basys3 SoC에서 특히 중요한 항목이다.
