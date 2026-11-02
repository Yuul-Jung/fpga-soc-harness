# Pmod NIC100 (ENC424J600)

갱신: 2026-11-03 · 근거: digilent-pmod-nic100-reference-manual (L3, 공식 문서 열람)

- 컨트롤러: Microchip ENC424J600, 10/100 MAC+PHY. TCP/IP 스택은 사용자가 구현한다.
- 인터페이스: SPI(기본) 또는 PSP. INT/SPISEL 풀업이면 SPI.
- 커넥터: 12핀 Pmod Type 2A. 1 CS, 2 MOSI, 3 MISO, 4 SCLK, 7 ~INT/SPISEL, 5·11 GND, 6·12 VCC.
- 전압: 3.3V (허용 3.0~3.6V). Basys3 I/O 정책과 일치.
- 주의: 단종. SPI 최대 클럭은 문서에 없음(unverified).
- 구현 사례: digilent-forum-basys3-ethernet-ipv4-udp (대안으로 언급), wiznet-makers-gavinchang-w5500-udp-loopback (W5500 대안 구조)
