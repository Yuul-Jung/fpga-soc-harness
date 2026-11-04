---
name: espressif-ota-updates-framework
url: https://developer.espressif.com/blog/ota-updates-framework/
source_type: article
vendor: neutral
board: [ESP32 계열 (예시는 4 MiB 플래시)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa/RISC-V 계열 일반)
language: C (ESP-IDF)
tools: [ESP-IDF app_update, esp_https_ota]
bus: none
peripherals: [debug]
stage: T3
license: unknown (글에 라이선스 표기 없음, 코드 반입 대상 아님)
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://developer.espressif.com/blog/ota-updates-framework/]
---
unverified: source_rev — 공식 블로그 글이라 해당 없음. unverified: 게시일·ESP-IDF 버전(글에서 확인 못 함)

## 요약
ESP-IDF의 OTA 구조를 설명한 Espressif 개발자 글이다. 앱 슬롯 두 개(ota_0, ota_1)와 상태 저장 영역(otadata)으로 "새 펌웨어를 쓰고, 확인되기 전까지는 되돌릴 수 있게" 만드는 것이 핵심이다. 롤백·보안 부팅·플래시 암호화·안티 롤백 옵션도 함께 다룬다.

## 구조
- 예시 파티션(4 MiB 플래시): nvs 0x4000, otadata 0x2000, phy_init 0x1000, ota_0 1M, ota_1 1M. 파티션 테이블은 기본 오프셋 0x9000에서 4 KiB를 차지하고, 앞 32 KiB는 부트로더용이다.
- ota_0/ota_1은 플래시 캐시 매핑 단위인 64 KiB로 정렬된다. otadata는 8 KiB(섹터 2개)로, 부팅할 이미지를 고르는 순번을 저장하며 섹터 두 개로 정전에도 안전하게 갱신된다.
- 롤백 상태: OTA 기록 직후 `ESP_OTA_IMG_NEW` → 다음 리셋에서 부트로더가 `ESP_IMAGE_PENDING_VERIFY`로 바꿈 → 앱이 유효 표시를 하지 않으면 이후 리셋에서 `ESP_OTA_IMG_ABORTED` 처리 후 이전 펌웨어로 복귀.
- 확인 시점 제안: 초기화 성공, Wi-Fi 연결, OTA 서버 연결 중 OTA 서버 연결이 가장 좋다고 글이 평가. API: `esp_ota_mark_app_valid_cancel_rollback()`, `esp_ota_mark_app_invalid_rollback_and_reboot()`.
- `esp_https_ota()`: 필수 인자는 HTTPS URL과 서버 인증서. 성공(`ESP_OK`) 시 앱이 `esp_restart()`. `esp_https_ota_get_img_desc()`로 내려받기 전에 버전을 비교해 불필요한 쓰기를 피한다.
- 보안: 보안 부팅 v1은 ECDSA NIST256p, v2는 RSA-3072(이미지 SHA256에 서명). 플래시 암호화는 하드웨어 AES와 eFuse 키. 안티 롤백은 이미지의 `secure_version`을 eFuse 값과 비교하며 최대 32비트까지 할당 가능, 새 펌웨어가 확인된 뒤에만 eFuse 갱신.
- 설정 키: `CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE`, `CONFIG_BOOTLOADER_APP_ANTI_ROLLBACK`, `CONFIG_BOOTLOADER_APP_SECURE_VERSION`, `CONFIG_BOOTLOADER_APP_SEC_VER_SIZE_EFUSE_FIELD`, `CONFIG_BOOTLOADER_EFUSE_SECURE_VERSION_EMULATE`(시험용만).

## 검증·재현성
- 이 글만으로는 빌드·시험 결과를 확인할 수 없다(unverified: 실제 기기 시험). 글이 말하는 롤백이 완전 복구를 보장하지는 않는다고 스스로 밝힌다.

## 한계·위험
- 롤백·안티 롤백은 출하 전에 켜야 한다(부트로더 경로는 현장에서 못 바꿈). factory 파티션은 안티 롤백과 함께 지원되지 않는다.
- 안티 롤백 비교가 "초과"인지 "이상"인지 글 안에서 표현이 엇갈린다 → 정확한 조건은 unverified.
- OTA 중 Wi-Fi 절전을 끄는 것이 처리량에 좋고, 플래시 쓰기·삭제 중에는 캐시가 꺼져 IRAM 안전 인터럽트 핸들러가 필요하다고 서술.
- 라이선스 확인 필요: 글에 라이선스 미표기 → 코드 반입 없음.

## 재사용 메모
- 내 판단: "슬롯 2개 + 상태 저장소 + 확인 전까지 되돌리기" 계약은 FPGA 비트스트림 이중 슬롯(황금 이미지 + 갱신 이미지) 설계의 소프트웨어 쪽 모델로 쓸 만하다. 단 Artix-7의 실제 멀티부트 절차는 이 글에 없으므로 별도 자료가 필요(unverified).
- 개조: 옮길 부분은 상태기계(`NEW → PENDING_VERIFY → VALID | ABORTED`)와 순번 두 섹터 갱신 규칙을 AXI4-Lite 레지스터(`SLOT_SEL`, `IMG_STATE`, `CONFIRM`)와 테스트벤치 시나리오(확인 없이 리셋 2회 → 이전 슬롯 복귀)로 만드는 것이다. 못 옮길 부분은 ESP-IDF API, eFuse, 보안 부팅 하드웨어. 이 카드는 아직 어떤 아이디어의 근거가 아님.
- 관련: [[espressif-faq-mqtt]].
