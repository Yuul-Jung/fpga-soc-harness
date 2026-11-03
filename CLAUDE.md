@HARNESS.md

## v0.7.2 운영 원칙 (2026-11-03)

### 다중 도메인 확장
이 하네스는 FPGA·SoC 외에 아래 도메인을 추가로 수집한다.

| 도메인 | 우선순위 | 비고 |
|--------|---------|------|
| FPGA·SoC | 1 | Basys3 기준, 기존 HARNESS.md 규칙 전체 적용 |
| Arduino | 2 | 아두이노 생태계 모듈, SoC 주변장치 연동 사례 우선 |
| STM32 | 3 | HAL/LL 드라이버, RTOS, 모터 제어 |
| ESP32 | 4 | Wi-Fi·BLE 통신, FreeRTOS, 센서 허브 |
| Raspberry Pi | 5 | Linux, GPIO 하드웨어 인터페이스, 카메라 파이프라인 |
| 임베디드 공통 | 6 | RTOS 비교, 프로토콜(UART/SPI/I2C/CAN), 디버그 기법 |
| 전자기술 | 7 | 전력전자, 인버터, 모터 드라이버 회로 (캡스톤 보조) |

### 수집 스케줄
- 수집(`/harvest`) 1시간마다, 검증(`/verify`) 3시간마다, 캡스톤 과제화(`/capstone`) 6시간마다. 실행 주체와 세부는 HARNESS.md §15를 따른다. (이전의 "홀수/짝수 사이클" 표현은 같은 순서를 뜻하는 말로, 주기는 위와 같다.)
- 도메인은 `inbox/topics.md`의 `[ ]` 항목에서 위부터 소비한다.
  도메인이 달라도 주제를 건너뛰지 않는다(HARNESS.md §12.2).

### 카드 도메인 경로
`catalog/` 하위에 기존 `amd/`, `intel/`, `lattice/`, `papers/` 외에:
- `arduino/` — Arduino 및 아두이노 호환 모듈 사례
- `stm32/` — STM32 시리즈 구현 사례
- `esp32/` — ESP32/ESP8266 사례
- `rpi/` — Raspberry Pi 사례
- `embedded/` — 임베디드 공통(RTOS, 프로토콜)
- `electronics/` — 전자회로·전력전자

### 자동 배포 (GitHub Pages)
- 소스: GitHub Actions (`pages.yml`의 `actions/deploy-pages@v4`, main 푸시마다)
- 빌드 도구: MkDocs Material (`mkdocs build --strict`)
- 배포 URL: https://yuul-jung.github.io/fpga-soc-harness/
- 배포는 main에 푸시될 때 자동 수행됨

### 사람이 할 일 (최초 1회)
1. GitHub → Settings → Pages → **Source: GitHub Actions** 로 변경
2. GitHub → Settings → Actions → General → **Workflow permissions: Read and write** 설정
3. (선택) Actions의 `harvest.yml`·`capstone.yml`을 다시 켤 때만 **ANTHROPIC_API_KEY** 추가 — 현재는 꺼져 있고 Claude 예약 작업이 대신한다
