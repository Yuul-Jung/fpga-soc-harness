# 주변장치 종합: SD 카드 (storage-sd, SPI 모드)

갱신: 2026-11-02 (/verify, 카드 3건 모두 원문 재대조)

| 항목 | 카드 | 보드 | CPU/버스 | 주변장치 | 한계 |
|---|---|---|---|---|---|
| ZipCPU sdspi | zipcpu-sdspi | XuLA2 (Basys3 needs-port) | none / Wishbone 슬레이브 | SPI·SDIO·슬레이브 컨트롤러 | GPL-3.0, SPI는 단일 블록만, SPI용 Verilog 테스트벤치 없음 |
| WangXuan95 SDcard-File | wangxuan95-fpga-sdcard-file | Nexys4 (Basys3 needs-port) | none(FSM) / none | FAT16/32 파일 읽기 | GPL-3.0, 읽기 전용, 시뮬·자원 기록 없음 |
| element14 SD 인터페이싱 | element14-security-camera-2-sd-card-interfacing | CMOD S7 (태그) | none(FSM) / none | SPI 마스터, 초기화, 블록 쓰기 | 라이선스 unknown, 읽기 없음, 고속 분주 주석 불일치 |

## 패턴
- 사실: 세 사례 모두 SPI 모드이고, 초기화는 저속 클럭으로 시작해 고속으로 전환하는 구조이다(element14: 100 MHz/250 = 400 kHz; WangXuan95: `SPI_CLK_DIV` 기본 50, 50 MHz 클럭에서 500 kHz).
- 사실: 계층은 SPI 마스터 → 카드 초기화/블록 명령 → (선택) 파일 시스템 순이다.
- 내 판단: 읽기+쓰기+자체 점검 테스트벤치를 모두 갖춘 소형 사례가 카탈로그에 없다(gap).

## 교훈
- 내 판단: 두 카드가 GPL-3.0, 하나가 unknown이므로 RTL은 새로 쓰고 카드는 근거로만 쓴다(§13.3).
- 내 판단: Basys3는 Pmod 한 포트로 SPI 4신호를 낼 수 있다(Digilent Pmod MicroSD 매뉴얼 재열람: 1 ~CS, 2 MOSI, 3 MISO, 4 SCK, 9 CD, 전원 2.7~3.6 V). 최대 SPI 클럭은 매뉴얼에 없다.
