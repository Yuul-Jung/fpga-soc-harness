---
name: zipcpu-sdspi
url: https://github.com/ZipCPU/sdspi
source_type: repo
vendor: neutral
board: [XuLA2, "unverified: SDIO 컨트롤러는 eth10g·videozip 프로젝트 보드"]
fit_basys3: needs-port
cpu: none(주변장치 IP, Wishbone 슬레이브)
language: Verilog
tools: [Verilator, "unverified: 형식 검증 도구명 미확인"]
bus: Wishbone (SPI 컨트롤러는 Wishbone 전용, SDIO는 Wishbone+AXI)
peripherals: [storage-sd, comm-spi]
stage: T2
license: GPL-3.0 (README: 별도 상용 라이선스 판매 언급)
stats: {stars: 417, commits: 357}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-02
sources: [https://github.com/ZipCPU/sdspi]
---

## 요약
SD 카드용 Verilog 컨트롤러 모음. SPI 방식(`rtl/sdspi`), SDIO/eMMC 방식(`rtl/sdio`), FPGA가 카드 역할을 하는 슬레이브(`rtl/sdslave`) 세 가지가 한 저장소에 있다. FATFS 라이브러리용 C 드라이버(`sw/`)가 함께 있다.

## 구조
- 디렉터리: `rtl/`(컨트롤러 3종, 논리 사용량 기록 `usage.txt`), `sw/`(sdspidrv.c, sdiodrv.c, emmcdrvr.c 등), `bench/`(Verilog 모델, Verilator C++), `doc/`(SPI·SDIO 사용자 안내).
- 버스: SPI 컨트롤러는 Wishbone 슬레이브만, AXI-Lite는 RTL을 조금 고치면 된다고 README가 적음. SDIO는 Wishbone·AXI와 선택적 DMA.
- SPI 컨트롤러는 XuLA2 보드용으로 처음 작성됨(README 기준). README는 SPI 코어가 실리콘 검증을 거쳤고 더 이상 적극 개발되지 않는다고 적음(재열람).

## 검증·재현성
- 많은 구성요소에 형식 검증, SDIO·eMMC용 Verilog 모델과 Verilator 모델(파일 기반 메모리) 제공. SDIO 프런트엔드는 형식 증명 없이 통합 시뮬레이션에 의존(README).
- SPI 컨트롤러용 전체 Verilog 테스트벤치는 없다고 README가 명시.
- 자원 사용량: unverified: README 본문에서 수치를 읽지 못함(`rtl/usage.txt`는 열람하지 않음).

## 한계·위험
- 라이선스 GPL-3.0 → 코드 복사 금지(§13.3), 구조·레지스터 설계 개념만 참고. 라이선스 확인 필요.
- SPI 컨트롤러는 다중 블록 명령을 쓸 수 없음(README).
- 레지스터 맵: unverified: 이번 열람 범위에서 확인하지 못함(`doc/` 미열람).
- Basys3 xdc·프로젝트 근거는 열람하지 못함.

## 재사용 메모
- 내 판단: 우리 SoC의 SD 주변장치(T2)를 직접 설계할 때 "컨트롤러(RTL) + FATFS 드라이버(sw)" 분리 구조와 SPI 대비 SDIO 확장 경로의 참고가 된다. Basys3는 Pmod SD(SPI 핀)가 있어 SPI 쪽이 현실적이다.
- 내 판단: 코드는 GPL이므로 자체 RTL을 새로 쓰고, 이 카드는 근거 카드로만 참조한다.
