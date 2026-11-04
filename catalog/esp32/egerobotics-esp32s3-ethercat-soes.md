---
name: egerobotics-esp32s3-ethercat-soes
url: https://hackaday.io/project/205376-esp32s3-w5500-ethercat-soes
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32-S3)
language: C
tools: [ESP-IDF]
bus: EtherCAT(소프트웨어 ESC)
peripherals: [comm-eth]
stage: T3
license: unknown
stats: {stars: null, commits: null, last_update: 2026-03}
doc_language: en
verification: L2
checked_at: 2026-11-04
unverified: GitHub 저장소(egerobotics/ESP32S3_W5500_SOES) 열람 불가(PROVENANCE_REQUIRED 오류). Hackaday 프로젝트 페이지만 열람.
sources: [https://hackaday.io/project/205376-esp32s3-w5500-ethercat-soes]
---

## 요약

검색 요약 기준. ESP32-S3 + W5500 SPI 이더넷으로 전용 EtherCAT Slave Controller(ESC) IC 없이 소프트웨어 ESC를 구현한 개념증명 프로젝트. SOES(Simple Open EtherCAT Slave) 오픈소스 스택 사용.

## 구조

- **하드웨어**: ESP32-S3 + W5500(SPI 이더넷)
- **소프트웨어 ESC**: W5500으로 EtherType 0x88A4 원시 프레임 처리; 16 KB ESC 레지스터 공간을 RAM에 유지
- **FMMU 처리**: 논리 주소 매핑 소프트웨어 구현
- **EtherCAT 스택**: SOES — 상태 기계(Init→PreOp→SafeOp→Op), CoE, PDO 지원
- **I/O**: 디지털 입력 3, 디지털 출력 3 (개념증명 최소 구성)
- **검증**: Beckhoff TwinCAT 3와 연동 테스트. ESI XML 포함.
- 프로젝트 완료 태그, 2026-03-22 생성.

## 검증·재현성

Hackaday 프로젝트 페이지 직접 열람(L2). GitHub 코드 미열람. TwinCAT 3 연동 성공은 프로젝트 페이지 기재 사항(원문: "tested with Beckhoff TwinCAT 3"). 성능·사이클타임 수치 없음.

## 한계·위험

- 라이선스 미확인 (GitHub 미열람).
- 성능(사이클 주기, 지연 시간) 미측정.
- I/O 3+3 포인트 개념증명 수준. 추가 I/O 확장 사례 없음.
- 소프트웨어 ESC는 하드웨어 ESC 대비 실시간성 불확실.

## 재사용 메모

- EtherCAT 슬레이브 아키텍처 이해용 참고 사례. 소프트 ESC(레지스터 메모리 에뮬레이션 + FMMU)의 원리를 Verilog로 구현하면 FPGA EtherCAT 슬레이브 IP로 이식 가능.
- Basys3로의 개념 이식: W5500 Pmod를 Basys3 SPI로 연결하고 MicroBlaze V 소프트코어로 SOES 구동하는 경로 가능(내 판단). 단, TwinCAT 사이클 타임(100 μs 이하) 충족 여부는 MicroBlaze 성능·인터럽트 레이턴시 측정 필요.
- 개조: MicroBlaze V SoC에 EtherCAT 슬레이브를 붙이려면 ① SPI-W5500 AXI 마스터 IP(기존 `wiznet-makers-gavinchang-w5500-udp-loopback` 카드 참고) ② RAM 기반 ESC 레지스터 공간(0x88A4 필터링 포함) ③ SOES 포팅(ESP-IDF→FreeRTOS on MicroBlaze) 순서. 가장 복잡한 산업 프로토콜 캡스톤 후보(내 판단).
