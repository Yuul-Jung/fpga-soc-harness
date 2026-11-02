---
name: stnolting-neorv32
url: https://github.com/stnolting/neorv32
source_type: repo
vendor: neutral
board: [범용 (Basys3 사용 사례는 unipi-cds105-neorv32-basys3-lab 카드 참고)]
fit_basys3: needs-port
cpu: NEORV32
language: VHDL
tools: [unverified: 버전별 상이]
bus: 내부 버스 + 외부 Wishbone b4 호환 (AXI4-Lite 변환 래퍼 존재)
peripherals: [comm-uart, comm-spi, comm-i2c, GPIO, PWM, timer, WDT, 1-wire, NeoPixel, TRNG]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-03
sources: [https://gitea.auro.re/higepi/Projet_SETI_RISC-V/src/branch/main/neorv32/docs/datasheet/soc.adoc, https://gitea.auro.re/higepi/Projet_SETI_RISC-V/src/branch/main/neorv32/docs/datasheet/soc_twi.adoc, https://gitea.auro.re/higepi/Projet_SETI_RISC-V/raw/branch/main/neorv32/docs/datasheet/soc_wishbone.adoc, https://deepwiki.com/stnolting/neorv32/4-peripherals, https://github.com/stnolting/neorv32/releases]
unverified: 라이선스(열람한 페이지에 언급 없음), 원본 저장소 README·LICENSE, 미러 문서의 버전(학생 프로젝트 포크, 버전 미표기), 주변장치 기준 주소(미러와 위키가 서로 다름), Basys3 자원 사용량
---

## 요약
VHDL로 쓴 RISC-V 소프트코어와 주변장치 모음. 주변장치는 대부분 CTRL/DATA 두 레지스터 형태이고, 합성 시 `IO_*_EN` 제네릭으로 켜고 끈다. 외부 버스는 Wishbone b4 호환이며 Vivado용 AXI4-Lite 변환 래퍼가 문서에 언급된다.

## 구조
- 주소 공간(미러 문서, 기본 구성): 명령 공간 0x00000000, 데이터 공간 0x80000000, 부트로더 ROM 0xFFFF0000, I/O 영역은 0xFFFFFE00부터 512바이트에 모여 있다. 주변장치는 32비트 쓰기만 받는다(바이트·하프워드 쓰기는 접근 오류). [soc.adoc]
- 인터럽트: 표준 기계 인터럽트 외에 빠른 인터럽트(FIRQ) 16채널(상승 엣지, `mip` 비트에 0을 써서 해제). 채널 배정(미러 기준): UART0 RX/TX 2·3, SPI 6, TWI 7, GPTMR 12, ONEWIRE 13 등. 외부 인터럽트 32개는 한 채널을 공유하므로 소프트웨어가 구분한다. [soc.adoc]
- TWI(I2C 마스터) 사양(미러 기준): 레지스터 2개 CTRL(0x00)·DATA(0x04). CTRL에 EN, START, STOP, MACK, 클럭 스트레칭 허용, 3비트 PRSC, 4비트 CDIV, 읽기 전용 ACK·BUSY. SCL = f_main / (4 × 분주 × (1+CDIV)), 최대 f_main/8. 바이트 전송이 끝날 때마다 인터럽트 1개. 컨트롤러 전용이며 FIFO 없음. [soc_twi.adoc]
- 외부 버스: 위 영역에 안 걸리는 접근이 전부 외부로 나간다. 한 번에 전송 하나, 버스트·STALL 없음. 클래식/파이프라인 모드, 타임아웃 설정 가능(0이면 끔). 입출력 레지스터 때문에 기본 2사이클 추가. [soc_wishbone.adoc]
- AXI4-Lite: Vivado용 Wishbone→AXI4-Lite 래퍼가 있고, AXI는 전송 중단이 불가능하므로 이 래퍼는 타임아웃을 0으로 둔다고 문서에 적혀 있다. [soc_wishbone.adoc]
- 최신 릴리스 페이지(열람일 기준)는 v1.13.3, 직렬 메모리 컨트롤러 모듈 추가를 언급. [releases]

## 검증·재현성
- 직접 빌드하거나 실행하지 않았다(§7). 자원 사용량은 열람한 페이지에 없다. unverified.
- 변경: 같은 TWI가 미러 문서에서는 0xffffffb0 기준 CTRL/DATA, 제3자 위키에서는 0xFFF90000 기준 CTRL/DCMD로 서술된다. 문서 버전이 다르다고 보이나 확인하지 못했다(내 판단). 위키는 TRNG와 ONEWIRE 기준 주소가 같게 적혀 있어 오기 가능성이 있다(위키가 직접 밝힘).

## 한계·위험
- 주변장치 주소는 버전마다 다를 수 있으니 원본 데이터시트로 다시 확인해야 한다.
- 라이선스를 확인하지 못했다. 코드는 가져오지 않는다(G0). 라이선스 확인 필요.
- 열람 경로가 학생 포크 미러와 제3자 위키라 원본과 다를 수 있다.

## 재사용 메모
- 내 판단: CTRL/DATA 두 레지스터로 I2C·SPI·UART를 다루는 배치는 소프트웨어 드라이버가 짧아지는 구조라서, IP 표준 래퍼의 레지스터 배치 참고로 쓸 만하다. 단 레지스터 이름·비트는 IP 표준(`config/ip_standard.json`)을 따라야 한다.
- 개조: TWI의 CTRL/DATA 사양(분주식, START/STOP/ACK/BUSY 의미)을 사양으로만 참고해 AXI4-Lite I2C 마스터 IP를 자체 RTL로 새로 쓰고, "바이트 완료 인터럽트"를 INTC 입력 `intc_free`(13, 14)로 연결한다. 옮기지 못하는 것: NEORV32 CPU와 FIRQ·`mip` 방식(MicroBlaze V는 INTC 사용). 해당 부분은 `cpu_irq_<cpu>.c` 한 파일로 격리. Wishbone→AXI4-Lite 래퍼 존재 사실은 "CPU 버스를 AXI4-Lite로 통일하는 방식"의 선례로 본다.
