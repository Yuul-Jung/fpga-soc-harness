---
name: obuda-preempt-rt-latency-tutorial
url: https://www.aut.uni-obuda.hu/es/Linux%20in%20Embedded%20Systems/Tutorials/preempt-rt-latency
source_type: course
vendor: neutral
board: [RaspberryPi4]
fit_basys3: needs-port
cpu: none(Linux RT)
language: C
tools: [rt-tests, stress-ng, trace-cmd]
bus: none
peripherals: [gpio]
stage: T1
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.aut.uni-obuda.hu/es/Linux%20in%20Embedded%20Systems/Tutorials/preempt-rt-latency]
---

## 요약

부다페스트 오부다 대학 임베디드 시스템 강의(Linux in Embedded Systems)의 PREEMPT_RT 지연 측정 튜토리얼. cyclictest로 표준 커널 대비 RT 커널 지연을 측정하고, trace-cmd·ftrace로 지연 원인을 추적하는 실습 절차를 제공한다.

## 구조

- **대상**: PREEMPT_RT 적용 Linux 커널 (6.12 버전부터 메인라인에 완전 통합)
- **RT 패키지 설치**: `sudo apt install linux-image-rt-arm64` (Raspberry Pi OS 기준)
- **검증**: `uname -a`에서 `PREEMPT_RT` 또는 `PREEMPT RT` 문자열 확인
- **cyclictest 측정 명령**:
  - 기본: `sudo cyclictest -m -Sp90 -i200 -l10000`
    - `-m` 메모리 잠금, `-S` SCHED_FIFO, `-p90` 우선순위 90, `-i200` 간격 200µs, `-l10000` 반복 10000회
  - 부하 조건: `stress-ng --cpu 4 &` 병렬 실행 후 동일 측정
  - 히스토그램: `sudo cyclictest -m -Sp90 -i200 -l100000 -h100 > histogram.txt`
- **측정 결과 (페이지 예시값, 부하 조건)**:

| 쓰레드 | Min (µs) | Act (µs) | Avg (µs) | Max (µs) |
|--------|----------|----------|----------|----------|
| T0 | 6 | 12 | 11 | 87 |
| T1 | 5 | 10 | 10 | 73 |
| T2 | 6 | 11 | 11 | 91 |
| T3 | 5 | 9 | 10 | 68 |

- **기대값**: 표준 커널 최대 50–500µs → PREEMPT_RT 커널 최대 50µs 미만
- **trace-cmd 추적**: `sudo trace-cmd record -e sched_switch -e sched_wakeup sleep 10` → `sudo trace-cmd report --cpu 0 | head -80`
- **ftrace 활성화**: `function_graph`를 `current_tracer`에 쓰기, `sched_switch`·`sched_wakeup` 이벤트 활성화, `tracing_on` 토글

## 검증·재현성

- Raspberry Pi OS에서 apt로 RT 커널 설치 가능 (소스 빌드 불필요)
- rt-tests 패키지 설치: `sudo apt-get install -y rt-tests`
- 1kHz 모터 제어 루프(1000µs 주기): 표준 커널 최대 약 500µs → PREEMPT_RT 50µs 미만으로 개선

## 한계·위험

- 특정 Raspberry Pi 모델 번호 미명시 (RPi OS 기준)
- isolcpus 설정 절차 없음 (기본 cyclictest 실습만 다룸)
- C 코드 예제 없음; 측정·트레이싱 명령 중심
- 튜토리얼 갱신일 미명시, 라이선스 없음

## 재사용 메모

- **S7 사다리 위치**: "입문" 단계 — cyclictest를 처음 실행해 보는 출발점. 다음 단계는 isolcpus + chrt/taskset 설정(applied-ee 가이드), 그 다음은 실제 모터 제어(ppisa/rpi-rt-control).
- 개조: FPGA SoC(Basys3 MicroBlaze V) 관점에서 "RT 커널의 지연 하한"은 FPGA 하드웨어 직접 처리(PWM, 엔코더)와 Linux 소프트웨어 처리 경계를 결정하는 근거가 된다. PREEMPT_RT로 50µs 미만 보장 → 20kHz 미만 루프는 FPGA에서, 1kHz 이하 외부 루프는 RPi에서 처리하는 이중 도메인 아키텍처의 타당성을 뒷받침한다.
- MicroBlaze V로 직접 옮길 부분 없음 (Linux RT 개념); 시스템 분리 근거로 활용.
