---
name: memfault-interrupt-mcuboot-overview
url: https://interrupt.memfault.com/blog/mcuboot-overview
source_type: article
vendor: neutral
board: [nRF52840-DK]
fit_basys3: needs-port
cpu: Cortex-M4F(nRF52840)
language: C
tools: [GCC, Make, imgtool.py]
bus: none
peripherals: [comm-uart, storage-spi-flash]
stage: T3
license: unknown
stats: {stars: N/A, commits: N/A, last_update: 2020-11-04}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://interrupt.memfault.com/blog/mcuboot-overview, https://github.com/mcu-tools/mcuboot, https://github.com/mcu-tools/MCUboot/blob/master/docs/design.md]
---

## 요약

Chris Coleman(Memfault CTO)이 쓴 MCUboot 포팅 가이드. nRF52840-DK를 대상으로 듀얼 슬롯 OTA 부트로더를 처음부터 구성하는 전 과정을 다룬다. 플래시 레이아웃 설계, 슬롯 스왑 메커니즘, SHA256·ECDSA 서명 검증, 이미지 트레일러 구조까지 한 글에서 완결된다.

## 구조

- **이미지 슬롯**: 1차(실행) + 2차(스테이징). 슬롯 경계는 플래시 섹터 단위로 고정해야 하며, 출하 후 변경 불가.
- **업그레이드 모드 3가지** (내 판단: 이해하고 선택해야 함):
  - `MCUBOOT_OVERWRITE_ONLY`: 2차→1차 복사 후 2차 삭제. 롤백 없음. 구현 단순.
  - `MCUBOOT_SWAP_USING_MOVE`: 1차 슬롯 앞에 여분 섹터 1개 필요. 플래시 쓰기 비교적 적음.
  - `MCUBOOT_SWAP_USING_SCRATCH`: 별도 스크래치 영역. 소섹터 플래시에서 쓰기 집중.
- **이미지 헤더/트레일러**: 헤더 magic `0x96f3b83d`, 32B 고정. 트레일러에 swap_state·image_ok·copy_done·magic 4필드.
- **서명 검증**: TLV 방식. SHA256(무결성), RSA-2048/3072-PSS·ECDSA-224/256·ED25519(인증). 크립토 백엔드: Tinycrypt, Mbed TLS, nRF CC310.
- **플래시 레이아웃 예시**: 부트로더 0x0–0x8000(32 kB), 1차 0x8000(128 kB), 2차 0x28000(128 kB), 데이터 0x48000~.
- **imgtool.py** 옵션: `--header-size 0x200 --align 4 --slot-size 0x20000 --version 1.0.0 --key rsa.pem`.
- **확인·복구 흐름**: 앱이 `boot_set_confirmed()` 호출 안 하면 다음 부팅 때 1차로 복구.
- **부트로더 크기**: 예시 `.text+.data` ≈ 20 kB (32 kB로 예산).

## 검증·재현성

- 직접 nRF52840-DK에 포팅한 예시. 빌드: GCC + Make. CI는 별도 언급 없음.
- `MCUBOOT_VALIDATE_PRIMARY_SLOT`: 매 부팅마다 1차 슬롯 검증. 느린 MCU에서 부팅 시간 영향 있음.
- 예시에서는 SHA256 전용(서명 없음)으로 시작, 나중에 RSA 추가 권장.

## 한계·위험

- `malloc` 사용 중. 부트로더에서 heap 최소화 권장(정적 할당 선호).
- 멀티 이미지 지원은 2020년 기준 초기 단계.
- 플래시 레이아웃은 출하 전에 확정해야 함(변경 불가).
- Kconfig 문서가 흩어져 있어 Zephyr Kconfig 래퍼를 대신 참고 권장.

## 재사용 메모

Basys3 SoC에서 MCUboot 패턴 적용 가능성: SPI Flash(W25Q64 등) 2분할(1차=BRAM/XIP, 2차=SPI Flash 상위 절반)로 OTA를 구현하면 MCUboot의 overwrite-only 모드가 가장 단순하다. `개조:` AXI SPI Master → SPI Flash 읽기/쓰기, SHA256 소프트웨어 검증 모듈(MicroBlaze V에서 C 코드)이 필요. 스왑 모드는 BRAM 크기 제약(Basys3 450 kbit BRAM = 50 kB 가용)으로 현실적으로 어렵고 overwrite-only가 적합. 서명 검증(ECDSA)은 MicroBlaze V에서 Mbed TLS로 가능하나 부팅 시간 10 s 이상 예상—내 판단.
