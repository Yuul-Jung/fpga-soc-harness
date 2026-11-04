---
name: doceme-py-spidev
url: https://github.com/doceme/py-spidev
source_type: repo
vendor: neutral
board: [RPi]
fit_basys3: needs-port
cpu: none(Linux 호스트 소프트웨어)
language: C, Python
tools: []
bus: SPI(spidev 커널 드라이버)
peripherals: [comm-spi]
stage: T2
license: MIT
stats: {stars: 482, commits: 127, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev: 
sources: [https://github.com/doceme/py-spidev]
---

## 요약

Linux 커널 spidev 드라이버를 Python으로 감싼 C 확장 모듈. `/dev/spidev<버스>.<디바이스>` 노드를 통해 SPI 버스를 직접 제어한다. Raspberry Pi의 하드웨어 SPI를 Python에서 쓸 때 가장 널리 쓰이는 방법이며, MIT 라이선스. ★482, 127 커밋.

## 구조

- 단일 C 확장(`spidev.c`) + Python 래퍼로 구성
- 디바이스 노드 접근: `/dev/spidev<버스>.<CE번호>` (예: `/dev/spidev0.0` = SPI bus 0, CE0)
- 주요 메서드: `open(bus, device)`, `open_path(path)`, `close()`, `readbytes(n)`, `writebytes(list)`, `writebytes2(list)`, `xfer(list)`, `xfer2(list)`, `xfer3(list)`
- 주요 속성: `max_speed_hz`, `mode`(0~3), `bits_per_word`, `lsbfirst`, `cshigh`, `loop`, `no_cs`
- `xfer3()`: 대용량 전송을 커널 버퍼 한계(일반 4096 바이트) 단위로 나눠 여러 번 호출하는 고수준 래퍼

## 검증·재현성

- PyPI에서 `pip install spidev`로 설치 가능 (소스 build)
- 커널 모듈 `spidev`가 로드되고 `/dev/spidev*` 노드가 존재해야 동작
- 단위 테스트나 CI 기록은 README에서 확인하지 못함 (unverified)

## 한계·위험

- RPi(Linux) 전용: spidev 커널 모듈이 있는 Linux SBC에서만 동작
- `/dev/spidev*` 노드 권한: 기본 root 소유, `gpio` 그룹 추가 또는 `udev` 규칙 필요
- `xfer()`는 CS를 각 바이트 사이에 토글하는 반면 `xfer2()`는 전체 전송 동안 유지 — 혼동 주의 (출처: 열람한 README)
- Basys3 미적용: Basys3은 Linux 없음, spidev 커널 드라이버 없음

## 재사용 메모

- SPI 버스 접근 패턴 참고: `open → 속성 설정(speed_hz, mode, bits_per_word) → xfer2 → close` 시퀀스는 MicroBlaze V에서 AXI SPI IP를 초기화하는 순서와 1:1 대응 (내 판단).
- `개조:` spidev API의 레지스터 추상화(speed_hz, mode 0~3, bits_per_word, CS 극성)를 AXI4-Lite SPI master IP의 제어 레지스터 설계 기준으로 활용 가능. `xfer3()`의 청크 분할 방식은 AXI Burst 또는 DMA 연동 설계 참조로 쓸 수 있다. CPU 코어·OS 종속 부분(spidev ioctl, /dev 경로)은 그대로 옮길 수 없고, 프로토콜 타이밍과 CS 제어 의미론만 RTL 설계 참조로 삼는다 (내 판단).
