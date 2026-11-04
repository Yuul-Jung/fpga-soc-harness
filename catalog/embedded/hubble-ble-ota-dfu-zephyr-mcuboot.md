---
name: hubble-ble-ota-dfu-zephyr-mcuboot
url: https://hubble.com/community/guides/how-to-add-ble-over-the-air-dfu-to-a-zephyr-project-with-mcuboot/
source_type: article
vendor: neutral
board: [nRF52840-DK]
fit_basys3: needs-port
cpu: Cortex-M4(nRF52840)
language: C
tools: [Zephyr RTOS v3.7, MCUboot, mcumgr CLI]
bus: none
peripherals: [comm-bt, comm-uart]
stage: T3
license: unknown
stats: {stars: N/A, commits: N/A, last_update: 2024-12-19}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://hubble.com/community/guides/how-to-add-ble-over-the-air-dfu-to-a-zephyr-project-with-mcuboot/]
unverified: 본문 Architecture 다이어그램 이후 내용 미열람(페이지 잘림). Kconfig 상세·슬롯 크기 계산·서명 키 관리 절차는 직접 확인 안 됨.
---

## 요약

Hubble Network 커뮤니티 가이드(2024-12-19). Nordic NCS가 아닌 순수 Zephyr 업스트림 LTS v3.7에서 MCUboot + mcumgr CLI + SMP over BLE를 조합해 nRF52840 DK에서 BLE OTA DFU를 구성하는 방법. 공식 샘플이 생략하는 "프로덕션 하드닝" 단계를 명시적으로 다룬다고 밝힘.

## 구조

- **스택**: Zephyr(업스트림 LTS v3.7) + MCUboot + mcumgr SMP 서버 + 호스트 측 mcumgr CLI.
- **전송**: SMP over BLE (BLE GATT 채널을 통한 Simple Management Protocol).
- **슬롯**: 1차(실행) + 2차(스테이징) + 스왑/스크래치 모드 사용.
- **롤백**: 소프트웨어 롤백 — confirm/revert 라이프사이클. 하드웨어 Anti-Rollback(eFuse/모노토닉 카운터)은 범위 밖.
- **문서 구성**: Architecture → 파티션 레이아웃·서명 키 → MCUboot 빌드 → SMP 서버 → OTA 수행 → 하드닝 체크리스트 → 대규모 배포(1→10,000 대).
- unverified: Kconfig 세부 설정·슬롯 크기 계산·키 관리 절차.

## 검증·재현성

- Hubble Network이 직접 작성한 가이드, 2024-12-19 발행.
- Zephyr 구 버전에서 Kconfig 이름이 바뀐 것에 대한 주의 사항 명시.
- unverified: CI 여부·실제 테스트 절차는 본문 미열람으로 확인 안 됨.

## 한계·위험

- 문서가 세 프로젝트(MCUboot·mcumgr·Zephyr)에 흩어져 있어 통합 복잡.
- Kconfig 옵션명이 최근 1년 사이 대거 변경됨 — 버전 호환 주의.
- 하드웨어 Anti-Rollback 미포함 — 보안 강화 필요 시 별도 구현.

## 재사용 메모

Basys3 SoC에 BLE OTA DFU를 직접 옮기는 것은 불가(BLE SoC 없음). `개조:` SMP over UART 패턴을 활용해 MicroBlaze V의 UART AXI IP를 통해 호스트 PC mcumgr로 이미지 전달 가능. 2차 슬롯에 쓴 후 SHA256 검증·부팅 전환 로직을 MicroBlaze V 펌웨어로 구현. BLE 수신 대신 UART 수신으로 대체하면 Basys3 T3 단계에서 "펌웨어 업데이트 채널" 완성 가능 — 내 판단.
