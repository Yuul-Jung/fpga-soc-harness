---
name: renesas-forgefpga-fg015-running-string
url: https://www.renesas.com/us/en/document/apn/fg-015-forgefpga-running-string-example
source_type: article
vendor: neutral
board: [ForgeFPGA SLG47910V]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Go Configure Software Hub]
bus: none
peripherals: [comm-spi, display-dot-matrix]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.renesas.com/us/en/document/apn/fg-015-forgefpga-running-string-example]
unverified: SPI 타이밍 수치(파형 그림만), MAX7219 초기화 순서 상세, 자원(LUT) 수치, 예제 파일의 라이선스
---

## 요약
Renesas ForgeFPGA 앱노트. FPGA가 SPI로 MAX7219 기반 도트 매트릭스에 글자를 보내고 한 열씩 밀어 문자열이 흐르게 한다. 글꼴 데이터는 외부 SPI 플래시에서 BRAM으로 옮겨 쓴다.

## 구조
- 내부 50 MHz 오실레이터를 PLL 기준으로 10 MHz 클럭을 만든다(문서 서술: fbdiv 20, refdiv 2, postdiv 7/7).
- 하위 모듈 10개: input_reset_buf, init_data_mux, init_bram, fsm_buffer, segment_bram, fsm_prepare_bram, indicator, pause_between_shift, spi_master, spi_io_buf. FSM은 3개(버퍼 준비, 전송 제어, 플래시→BRAM 적재).
- init_data_mux가 64개 기호를 바이트당 2개로 제공. 플래시는 AT25FF041A.
- 전압: FPGA I/O 2.8V, 별도 GreenPAK이 5V 레벨 변환기 역할로 매트릭스와 연결.

## 검증·재현성
- 문서는 파형과 상태도를 그림으로만 제시해 텍스트로는 세부를 확인하지 못했다. 테스트벤치 언급 없음(unverified).

## 한계·위험
- 라이선스 미기재(파일은 Renesas 사이트 내려받기). Renesas 도구 의존 설계라 Basys3에 그대로 못 쓴다.
- 플래시 핀을 저전압 디지털 입력으로 설정해야 하는 등 장치 종속 주의사항이 있다.

## 재사용 메모
- 내 판단: "SPI 마스터 + 초기화 FSM + 열 버퍼 + 이동 타이머" 분해는 Basys3에서 MAX7219 IP를 만들 때 그대로 쓸 구조다. 글꼴은 플래시 대신 BRAM 초기값(.mem)으로 충분해 보인다.
- 라이선스 확인 필요. 코드 없이 구조만 참고.
- 개조: 열 버퍼를 레지스터 창(64비트 2개 등)으로, 이동 주기와 밝기는 제어 레지스터로 올려 AXI4-Lite IP 표준 래퍼를 만든다(내 판단). 5V 매트릭스는 Basys3 3.3V Pmod에서 레벨 변환 필요.
