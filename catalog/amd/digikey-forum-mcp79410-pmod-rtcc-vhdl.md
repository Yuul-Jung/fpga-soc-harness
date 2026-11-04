---
name: digikey-forum-mcp79410-pmod-rtcc-vhdl
url: https://forum.digikey.com/t/real-time-clock-mcp79410-pmod-controller-vhdl/13136
source_type: article
vendor: neutral
board: [미명시 (Digilent Pmod RTCC 사용)]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: []
bus: none
peripherals: [comm-i2c, MCP79410-RTCC]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://forum.digikey.com/t/real-time-clock-mcp79410-pmod-controller-vhdl/13136, https://vhdlwhiz.com/?p=14073]
unverified: 레지스터 주소(문서에 없음), 포트 폭(표가 이미지), 라이선스, 대상 FPGA 보드, 테스트벤치
---

## 요약
DigiKey 기술 포럼의 VHDL 글. Pmod RTCC(MCP79410)에서 시·분·초·요일·날짜·월·년을 읽고, `set_clk_ena` 토글로 새 시각을 쓰는 컨트롤러와 그 아래의 `i2c_master.vhd`를 제공한다고 설명한다. 같은 칩을 다루는 유료 강의(VHDLwhiz, Arty S7-50, 공개 면은 소개문만)도 함께 확인했다.

## 구조
- 최상위 `pmod_real_time_clock.vhd`(16.0 KB), I2C 마스터 `i2c_master.vhd`(14.1 KB) 두 파일.
- 입력: `clk`, `reset_n`(active-low), `set_clk_ena`. 출력: seconds, minutes, hours, am_pm, weekday, day, month, year, `i2c_ack_err`. 제네릭 `sys_clk_freq`(Hz). 시작 후 100 ms 대기.
- 상태는 쓰기("set")와 읽기("read")로 나뉜다(글 서술).
- 강의 소개문: 명령 인터페이스와 AXI 스타일 ready/valid 핸드셰이크를 쓰는 I2C 마스터, 16강·약 3시간 6분, $69(소개문 서술).

## 검증·재현성
- 테스트벤치·자원 수치는 확인하지 못함. 강의의 본문 코드는 구매자 전용이라 열람하지 못함.

## 한계·위험
- Pmod에 I2C 풀업이 없어 외부 2.2 kΩ 풀업이 필요하다(글 서술).
- 처음 시각을 쓰기 전에는 출력이 모두 0이다. 발진기가 쓰기 상태에서 시작되기 때문이다(글 서술).
- reset은 칩의 시각을 지우지 않는다(글 서술). 라이선스가 적혀 있지 않다.

## 재사용 메모
- 내 판단: 풀업 부재, 최초 설정 전 0 출력, `i2c_ack_err` 노출은 RTC IP의 STATUS 레지스터 항목(ACK 오류 비트, 시각 유효 비트)으로 그대로 옮길 만한 교훈이다.
- 개조: 시각 필드 읽기와 설정 요청을 AXI4-Lite 레지스터로 노출하고 소스는 새로 쓴다. 라이선스 확인 필요.
