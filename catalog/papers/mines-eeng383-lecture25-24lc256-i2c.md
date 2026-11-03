---
name: mines-eeng383-lecture25-24lc256-i2c
url: https://inside.mines.edu/~coulston/courses/EENG383/lecture/lecture25.html
source_type: course
vendor: neutral
board: [없음 (PIC 마이크로컨트롤러)]
fit_basys3: needs-port
cpu: none(FSM)
language: C
tools: []
bus: none
peripherals: [comm-i2c, 24LC256-EEPROM]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://inside.mines.edu/~coulston/courses/EENG383/lecture/lecture25.html]
unverified: FPGA 구현 아님(MCU 강의), 라이선스, 쓰기 사이클 시간 수치(페이지에 값 없음)
---

## 요약
콜로라도 광업대 EENG383 강의 25. PIC에서 24LC256 I2C EEPROM(32 KB, 64바이트 페이지)을 읽고 쓰는 절차를 설명한다. FPGA 자료는 아니지만 EEPROM 접근 순서를 FSM으로 옮길 때의 근거가 된다.

## 구조
- 7비트 장치 주소 0b1010000. 제어 바이트는 라이브러리가 붙인다.
- 페이지 쓰기: 주소 상위·하위 바이트 + 최대 64바이트 데이터를 보낸 뒤, 칩이 내부에서 비휘발 영역에 기록한다(전송보다 훨씬 오래 걸림).
- 읽기: 데이터 없이 주소 2바이트만 쓰는 "가짜 쓰기"로 내부 포인터를 맞추고 이어서 읽는다. 포인터는 바이트마다 증가하며 페이지 경계를 넘어도 계속된다.
- 쓰기 완료 확인: NACK이 오면 부재 또는 기록 중이므로 길이 0 쓰기를 ACK가 올 때까지 반복(ACK 폴링).

## 검증·재현성
- 해당 없음(MCU 코드 해설).

## 한계·위험
- 쓰기 사이클 시간 값이 페이지에 없다. 칩 데이터시트 열람 필요(unverified).

## 재사용 메모
- 내 판단: EEPROM IP는 주소 포인터 쓰기 → 연속 읽기, 페이지 쓰기 → ACK 폴링의 두 시퀀스만 지원하면 되고, 페이지 경계 감김(쓰기 때 64바이트 안에서 감김)은 소프트웨어 규칙으로 두는 편이 단순하다(쓰기 경계 감김은 이 페이지에 없어 unverified).
- 개조: MicroBlaze V가 바이트열을 FIFO 레지스터로 넣고 STATUS의 BUSY/NACK 비트를 보는 구조로 옮긴다. 시험은 EEPROM 모델(포인터·페이지 버퍼·기록 중 NACK)을 자체 tb에 둔다.
