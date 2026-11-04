---
name: shillehtek-nano-mpu6050-neo6m-vehicle-logger
url: https://shillehtek.com/blogs/news/arduino-nano-mpu6050-neo6m-vehicle-data-logger
source_type: article
vendor: neutral
board: [Arduino Nano V3.0 (ATmega328P)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, Adafruit_MPU6050, TinyGPS++, SoftwareSerial, SD]
bus: I2C + UART + SPI
peripherals: [sensor, comm-uart, comm-i2c, comm-spi, storage-sd]
stage: T2
license: unknown (페이지에 라이선스 표기 없음 → 코드 반입 금지)
stats: {last_update: "unverified: 페이지에 최종 수정일 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://shillehtek.com/blogs/news/arduino-nano-mpu6050-neo6m-vehicle-data-logger]
---
## 요약
Arduino Nano에 MPU6050(I2C), NEO-6M GPS(UART), microSD(SPI)를 붙여 위치·속도와 가속도를 CSV로 기록하는 차량 로거 글이다. I2C·UART·SPI 세 인터페이스가 한 보드에 모이는 최소 "센서 허브" 예로 쓸 만하다.

## 구조
- GPS: GT-U7(NEO-6M) 모듈을 Nano 핀 4·3의 SoftwareSerial로 연결, 9600 baud, 약 1 Hz 갱신(글 서술).
- IMU: MPU6050을 I2C로 연결. I2C 주소는 unverified: 글에 없음.
- 저장: microSD 어댑터 SPI, CS는 핀 10. 카드는 32 GB 이하 FAT32(글 서술).
- 흐름: GPS 바이트를 TinyGPS++에 먹이고, 위치가 갱신될 때만 IMU를 읽어 CSV 한 줄을 쓰고 flush한다. 즉 IMU 표본 주기가 GPS 주기(약 1 Hz)에 종속된다.
- CSV 열: `time,lat,lng,speed_kmh,ax,ay,az,gz` (time은 부팅 후 밀리초). 자이로는 Z축만 기록.
- 전원: 12V→5V 강압 또는 차량용 USB 충전기. 3.3 V 레일·레벨 변환 언급 없음.

## 검증·재현성
- 테스트·측정 자료: unverified: 글에 없음. 빌드는 Arduino IDE 라이브러리 설치 방식이며 저장소 스크립트를 실행하지 않았다.

## 한계·위험
- 글에서 확인한 약점: 센서·SD 초기화 성공 여부를 검사하지 않음, 유효 위치 여부(fix) 검사 없음, 재부팅마다 헤더가 다시 쓰여 한 파일에 중복됨, `millis()` 시각이라 실제 시각 기준이 없음.
- 내 판단: IMU를 GPS 주기에 묶으면 제동·선회 같은 짧은 사건을 놓친다. 허브 설계에서는 센서별 독립 표본 주기와 타임스탬프 공유가 필요하다.
- 라이선스 표기 없음 → 코드를 가져오지 않는다. 라이선스 확인 필요.

## 재사용 메모
- 내 판단: "독립 주기 센서 여러 개를 하나의 타임스탬프로 묶어 기록"하는 구조가 이 글에서 빠져 있다는 점이 오히려 하드웨어 IP의 설계 동기가 된다(자유 실행 카운터 + 센서별 표본 FIFO).
- 개조: I2C(IMU)·UART(GPS) 마스터는 각각 AXI4-Lite 레지스터 IP(상태·데이터·인터럽트)로, 이를 묶는 로깅 루프와 NMEA 파싱은 MicroBlaze V 펌웨어로 옮긴다. SD는 기존 SPI 카드 자료를 쓴다. 옮길 수 없는 부분은 SoftwareSerial·TinyGPS++ 의존 코드(MCU 전용 라이브러리)이며 NMEA 상태기계만 사양으로 참고한다. 코드는 가져오지 않는다.
