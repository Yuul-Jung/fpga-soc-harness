---
name: espressif-esp32-camera
url: https://components.espressif.com/components/espressif/esp32-camera/versions/2.0.0/readme
source_type: article
vendor: neutral
board: [ESP32, ESP32-S2, ESP32-S3]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa LX6/LX7)
language: C (ESP-IDF component)
tools: [ESP-IDF v5.x, ESP-IDF Component Manager]
bus: I2S DMA (카메라 내부), SCCB/I2C (센서 설정)
peripherals: [camera, sensor]
stage: T2
license: Apache-2.0
stats: {version: "2.1.8 (latest)", checked_version: "2.0.0"}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://components.espressif.com/components/espressif/esp32-camera/versions/2.0.0/readme]
---

## 요약
Espressif 공식 ESP32 카메라 드라이버 컴포넌트. OV2640·OV3660·OV5640 등 10종 이상의 이미지 센서를 지원하며 JPEG·YUV422·RGB565 출력을 제공한다. Apache-2.0 라이선스.

## 구조
- **지원 센서 (OV2640 최대 해상도: 1600×1200)**: OV2640, OV3660, OV5640, OV7670, OV7725, NT99141, GC032A, GC0308, GC2145, BF3005
- **지원 SoC**: ESP32, ESP32-S2, ESP32-S3
- **출력 형식**: PIXFORMAT_JPEG, YUV422, GRAYSCALE, RGB565; 센서별 raw Bayer·RGB444·CCIR656도 가능
- **프레임 버퍼 모드**: 1-buffer (VSYNC 동기, 저속·안정), 2+buffer (I2S 연속 DMA, 약 2× 프레임율 — JPEG 전용 권장)
- **해상도 범위**: QQVGA~QXGA. 비-JPEG 포맷은 QVGA 이하 권장
- **PSRAM 요구**: CIF 이상 비-JPEG 사용 시 필수

## 검증·재현성
- Espressif 공식 컴포넌트 레지스트리(components.espressif.com) 배포; v2.0.0 ~ v2.1.8
- Component Manager로 의존성 추가: `idf_component.yml`에 `espressif/esp32-camera: "^2.0.0"` 기재
- JPEG HTTP 캡처·스트리밍·BMP 캡처 예제 내장

## 한계·위험
- YUV/RGB 포맷: Wi-Fi 동시 사용 시 PSRAM 쓰기 속도 부족으로 프레임 손실 발생 가능. 공식 권장: JPEG 캡처 후 변환
- ESP32-S2/S3 EDMA 16MHz XCLK 모드 실험적(experimental)
- PlatformIO + ESP-IDF 구버전(3.3/4.0.1) 빌드 불가 사례 보고; Kconfig 없이 컴파일하면 동작하지 않음
- Arduino 프레임워크 사용 시 메모리·플래시 소모 증가

## 재사용 메모
- OV2640 SCCB 레지스터 초기화 순서와 픽셀 클럭 설정은 FPGA 카메라 인터페이스 설계의 직접 참고 자료.
- 개조: Basys3 MicroBlaze V에서 OV2640을 쓰려면 (1) AXI-IIC로 SCCB 레지스터 설정, (2) PCLK·HSYNC·VSYNC·D[7:0] 8비트 병렬 픽셀 버스를 커스텀 AXI-Stream 캡처 IP로 수신, (3) BRAM 라인 버퍼로 저해상도(QQVGA 160×120) 프레임 저장. 압축(JPEG 디코더)은 BRAM 용량 한계로 MicroBlaze V SW 처리가 현실적. 이 드라이버의 I2S DMA 로직은 ESP32 하드웨어 전용이므로 옮길 수 없다. SCCB 주소 맵과 초기화 순서만 카드 §구조에서 추출해 RTL 설계에 적용한다(§16.3).
