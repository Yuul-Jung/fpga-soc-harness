---
name: applied-ee-rpi-realtime-linux
url: https://applied-ee.github.io/embedded/docs/foundations/embedded-os-sbc/real-time-linux/
source_type: article
vendor: neutral
board: [RaspberryPi4, RaspberryPi5]
fit_basys3: needs-port
cpu: none(Linux RT)
language: C
tools: [cyclictest, stress-ng, taskset, chrt, trace-cmd]
bus: none
peripherals: [gpio, comm-uart, comm-spi]
stage: T2
license: unknown
stats: {stars: 0, commits: 0, last_update: 2025-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://applied-ee.github.io/embedded/docs/foundations/embedded-os-sbc/real-time-linux/]
---

## 요약

Applied Embedded Engineering 가이드의 "Real-Time Constraints on Linux SBC" 절. RPi4와 RPi5에서 PREEMPT_RT 커널의 실측 지연을 비교하고, isolcpus·chrt·taskset·threadirqs 조합 최적화 절차를 단계별로 설명한다. 모터 제어 1kHz 루프의 한계를 수치로 제시한다.

## 구조

- **RT 커널 옵션**: `sudo apt install linux-image-rt-arm64` (Raspbian/Pi OS 64-bit Bookworm 이상)
- **benchmarked kernels**: PREEMPT_RT 6.1 on Pi 4, PREEMPT_RT 6.6 on Pi 5
- **실측 latency (1시간, stress-ng cpu+io+vm 부하)**:

| 플랫폼 | 커널 | 평균 latency | 최대 latency (부하) |
|--------|------|-------------|---------------------|
| Pi 4 | Standard 6.1 | ~15 µs | 500–2000 µs |
| Pi 4 | PREEMPT_RT 6.1 | ~10 µs | 50–80 µs |
| Pi 5 | PREEMPT_RT 6.6 | ~8 µs | 40–70 µs |

- **cyclictest 명령**:
  `sudo cyclictest --mlockall --smp --priority=80 --interval=1000 --distance=0 --duration=3600 --histogram=200 --histfile=cyclictest_histogram.txt`
- **isolcpus 설정** (`/boot/cmdline.txt`에 추가):
  `isolcpus=2,3 nohz_full=2,3 rcu_nocbs=2,3 threadirqs nosoftlockup nowatchdog audit=0 loglevel=3 processor.max_cstate=0 idle=poll`
  - 검증: `cat /sys/devices/system/cpu/isolated` → `2-3` 확인
- **CPU 고정 실행**: `sudo taskset -c 2 chrt -f 80 ./rt_application`
- **IRQ 쓰레드 우선순위**: GPIO IRQ 쓰레드 90, RT 애플리케이션 80, 나머지 IRQ 50 권장
- **C API**: `sched_setaffinity`, `sched_setscheduler`, `mlockall` 조합
- **주파수 고정**: 각 CPU의 `scaling_governor`를 `performance`로 설정, `systemctl disable ondemand`
- **커널 config (소스 빌드 시)**:
  - 활성화: `CONFIG_PREEMPT_RT=y`, `CONFIG_HIGH_RES_TIMERS=y`, `CONFIG_NO_HZ_FULL=y`, `CONFIG_HZ_1000=y`, `CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y`
  - 비활성화(지연 감소): `CONFIG_DEBUG_PREEMPT`, `CONFIG_LOCK_STAT`, `CONFIG_FTRACE`, `CONFIG_KMEMLEAK`

## 검증·재현성

- 1시간 cyclictest + stress-ng 실측값 제공
- Pi4/Pi5 비교 표 제공
- 1kHz 제어 루프(1000µs 주기) 기준 PREEMPT_RT Pi4: 10–15µs 지터 → 모터 PID·위치 제어에 충분

## 한계·위험

- 모터 제어 애플리케이션 코드 없음 (아키텍처 가이드 수준)
- BLDC FOC 20kHz PWM은 RT Linux으로 불가 → 별도 MCU(STM32급) 또는 FPGA 필요 명시
- USB 디바이스 활동 시 200µs 이상 스파이크 가능
- SD 카드 쓰기 정지(wear-leveling)가 50–200ms 지연 유발 가능
- Pi5: 80°C 이상 시 클럭 감소로 지연 스파이크 발생 (` vcgencmd measure_temp`로 확인)
- Pi4에서 USB와 Ethernet이 IRQ를 공유해 USB 사용 시 latency 악화
- `idle=poll` 설정은 소비 전력·발열 증가

## 재사용 메모

- **S7 사다리 위치**: "중급-고급" — isolcpus·threadirqs·chrt 조합까지 다루는 완전 설정 가이드.
- 개조: 이 가이드의 핵심 결론 "BLDC 20kHz는 RT Linux에서 불가 → FPGA 또는 MCU 분리 필요"는 MicroBlaze V SoC 설계 근거다. RPi4 PREEMPT_RT가 1kHz 외부 PID 루프를, Basys3 MicroBlaze V AXI-PWM IP가 100kHz 내부 PWM/엔코더 루프를 담당하는 이중 도메인 구조(내 판단: I-054 아이디어와 직접 연결)를 AXI-UART Lite 또는 SPI로 연결할 수 있다.
- isolcpus 철학(핵심 코어 격리) → Basys3의 "주변장치 별 전용 AXI 슬레이브 영역(동결 주소맵)" 개념과 대응된다.
