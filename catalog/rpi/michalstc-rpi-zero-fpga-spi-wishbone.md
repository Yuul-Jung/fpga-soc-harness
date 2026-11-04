---
name: michalstc-rpi-zero-fpga-spi-wishbone
url: https://hackster.io/MichalsTC/how-communicate-to-a-fpga-using-a-raspberry-pi-zero-via-spi-453651
source_type: article
vendor: amd
board: [Vivado 대상 FPGA (보드명 미명시, LED·RGB LED 보유)]
fit_basys3: needs-port
cpu: none(FPGA peripheral + RPi host)
language: Verilog
tools: [Vivado, Icarus Verilog]
bus: SPI → Wishbone
peripherals: [SPI-slave, Wishbone-bus, PWM-decoder, LED-control]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://hackster.io/MichalsTC/how-communicate-to-a-fpga-using-a-raspberry-pi-zero-via-spi-453651]
---

## 요약

RPi Zero를 Buildroot·PREEMPT_RT 커널로 구동하고, SPI를 통해 Verilog FPGA에 연결하는 비행 컴퓨터 프로젝트. RPi SPI0.1(`/dev/spidev0.1`)이 FPGA SPI 슬레이브를 거쳐 Wishbone 버스로 레지스터 R/W를 수행한다. 테스트벤치와 Icarus Verilog 워크플로 포함.

## 구조

- RPi 역할: Buildroot Linux + PREEMPT_RT 패치 커널, `spidev` 드라이버로 SPI 마스터
- SPI 연결: SPI0.1(MISO/MOSI/CLK/CE1) ↔ FPGA SPI 슬레이브
- SPI 프레임 (쓰기): 명령 `0xA2` + 32비트 주소 + 2바이트 길이 + 데이터(역바이트 순서)
- SPI 프레임 (읽기): 명령 `0xA1` → 응답 2바이트 junk + `0xA3` + 주소 + 길이 + 데이터
- Verilog 모듈: 타사 SPI 인터페이스 라이브러리 + 타사 Wishbone 라이브러리 + Python 생성 MUX + 글루 로직
- 테스트벤치: `tb_pwmdecoder_wb.v`(PWM 디코딩 100 MHz), `tb_spiwishbone.v`(SPI 레지스터 R/W)
- Wishbone 버스: 32비트 주소·데이터 폭

## 검증·재현성

- Icarus Verilog 시뮬레이션과 Vivado 빌드 과정을 hackster.io 본문에서 설명
- 실측: 3.2 MHz SPI 클럭으로 2.6 kHz 명령 처리율 달성(CPU 소프트웨어 한계)
- 소스 코드와 라이브러리 링크는 본문에 "here"로 존재하나 실제 URL은 열람 불가
- 라이선스 미명시 → 코드 복사 불가(§6, 사양 추출만 허용 §16.3 G0 위반)
- unverified: GitHub 저장소 URL, 라이선스, FPGA 보드 정확한 모델, 자원 사용 수치

## 한계·위험

- 라이선스 불명확: 소스 미공개 가능성, 직접 사용 불가
- 타사 Wishbone 라이브러리의 AXI-Stream 인터페이스가 복잡 → 저자 본인이 "다음엔 AXI-Lite가 나을 것"이라고 명시
- 2바이트 junk 프리앰블과 역바이트 순서 프로토콜: 호스트 소프트웨어 복잡도 증가 주의
- SPI 클럭 3.2 MHz → 명령 처리율 ~2.6 kHz 상한 (소프트웨어 루프, DMA 미사용)

## 재사용 메모

- SPI→레지스터맵 R/W 프레임 설계(명령·주소·길이·데이터)는 직접 참고 가능한 패턴
- RPi Buildroot + PREEMPT_RT + spidev 조합은 "RPi를 MicroBlaze V 디버그 콘솔로 활용" 아이디어의 실제 구현 근거
- 개조: Wishbone 대신 AXI4-Lite 슬레이브를 SPI 프레임 디코더에 직결하면 MicroBlaze V와 바로 연결 가능. SPI 프레임 명령 코드를 1바이트 opcode + 15비트 주소 + 데이터로 단순화하면 junk 프리앰블 제거 가능. DMA(`spi_ioc_transfer` 배열)로 처리율 개선 여지 있음. RPi 클럭 `gpio_set_function(10,ALT0)` 활성화와 Basys3 Pmod 연결 시 3.3V 직결 가능(레벨 변환 불필요).
