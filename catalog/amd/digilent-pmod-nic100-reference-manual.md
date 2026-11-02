---
name: digilent-pmod-nic100-reference-manual
url: https://reference.digilentinc.com/pmod/pmodnic100/reference-manual
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: needs-port
cpu: none
language: unverified
tools: []
bus: SPI
peripherals: [comm-eth, ENC424J600, Pmod]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
status: 제품 단종(Digilent 문서 서술)
sources: [https://reference.digilentinc.com/pmod/pmodnic100/reference-manual, https://github.com/carljohnsen/Pmod-NIC100]
unverified: SPI 최대 클럭(문서에 없음, 데이터시트 참조), Basys3 핀 배정, 지원 라이브러리 내용(약관 동의 필요해 받지 않음)
---

## 요약
Digilent Pmod NIC100 공식 참조 문서. Microchip ENC424J600 10/100 이더넷 MAC+PHY를 12핀 Pmod(Type 2A)로 내놓고 SPI(기본)나 병렬 슬레이브 포트(PSP)로 접근한다.

## 구조
- 핀: CS, MOSI, MISO, SCLK, ~INT/SPISEL, GND, VCC(3.3V). INT/SPISEL 풀업이면 SPI 모드, 풀다운이면 PSP(문서 서술).
- 전원 3.0~3.6V, 3.3V 권장. MAC과 PHY만 제공하므로 TCP/IP 스택은 사용자가 만든다.
- 보조 출처(carljohnsen/Pmod-NIC100, README 열람): VHDL SPI 인터페이스, BRAM 패킷 버퍼와 busy/tx/rx/length 신호, 이를 4개 레지스터로 매핑한 AXI 인터페이스, SPI fmax 14 MHz, 패킷 1500바이트 제한. 저자도 구현이 설명과 다르다고 적었고, 라이선스·빌드 방법은 페이지에 없었다.

## 검증·재현성
- 문서는 사양이며 Basys3 예제는 확인하지 못했다. Digilent 예제는 읽기 정보 확인 수준(문서 서술).

## 한계·위험
- 단종품이라 구입 어렵다. 지원 라이브러리는 Microchip 약관 동의가 필요해 열람·반입하지 않았다.
- 3.3V 전용이라 Basys3 전기 규칙과 맞는 점은 장점.

## 재사용 메모
- 내 판단: 이더넷을 외부 MAC/PHY로 붙이는 가장 단순한 경로는 SPI 모듈이다. 단종이므로 ENC28J60·W5500 계열 모듈 사례와 함께 본다.
- 개조: 보조 출처의 "BRAM 버퍼 + busy/tx/rx/length" 구조를 동결 맵의 빈 슬롯 하나에 AXI4-Lite 레지스터(STATUS, LEN, FIFO 창)로 옮기는 설계를 착안한다. 자체 RTL로 새로 쓴다(코드 비반입, 라이선스 확인 필요).
