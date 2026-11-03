---
name: digikey-forum-jstk2-pmod-controller-vhdl
url: https://forum.digikey.com/t/joystick-jstk2-pmod-controller-vhdl/28986
source_type: article
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [unverified]
bus: none
peripherals: [comm-spi, sensor, joystick]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://forum.digikey.com/t/joystick-jstk2-pmod-controller-vhdl/28986]
unverified: 포트 폭과 Pmod 핀 매핑 표(본문에서 이미지), 7바이트 패킷의 바이트별 의미, 라이선스, Basys3 시험 여부
---

## 요약
Digilent Pmod JSTK2 조이스틱을 SPI로 읽어 X·Y 위치와 버튼 두 개를 병렬 출력으로 내놓는 VHDL 컨트롤러 설명(포럼 글, 2023-02-24 작성으로 표시). SPI 마스터 파일이 함께 필요하다.

## 구조
- 제네릭 clk_freq. 입력 clk, reset_n(액티브 로우 비동기). 출력 x_position, y_position, trigger_button, center_button.
- SPI 모드 0(CPOL=0, CPHA=0), 1 MHz. 칩 셀렉트는 컨트롤러가 직접 제어, 바이트마다 8비트 트랜잭션. 칩 셀렉트 후 첫 바이트까지 15 µs, 바이트 사이 10 µs.
- 한 번 읽을 때 7바이트 패킷. 시작 시 100 ms 대기 후 읽기마다 1 ms 대기.

## 검증·재현성
- 테스트벤치, 시뮬레이션 결과 언급 없음. 파일 두 개(pmod_joystick.vhd, spi_master.vhd) 제공.

## 한계·위험
- clk_freq를 시스템 클럭과 맞추지 않으면 SPI 타이밍이 틀어진다. reset_n이 낮으면 진행 중 전송이 중단되고 출력이 지워진다.
- 라이선스 미기재 → 코드 미반입, 프로토콜 사양만 기록. 포트 폭·핀 표가 이미지라 확인하지 못함.

## 재사용 메모
- 내 판단: 조이스틱 → 서보 조합의 입력 쪽 근거. 위치 값을 서보 위치 레지스터로 매핑하는 소프트웨어 루프가 가장 단순한 응용이다.
- 개조: 자체 SPI 마스터(모드 0, 1 MHz 분주, 바이트 간격 파라미터)를 IP 표준 레지스터(최신 X/Y, 버튼, 상태 비트)로 노출. 7바이트 프레임의 의미는 Digilent 공식 매뉴얼로 확인 후 devices/spi에 정리. Pmod 전원은 3.3 V.
