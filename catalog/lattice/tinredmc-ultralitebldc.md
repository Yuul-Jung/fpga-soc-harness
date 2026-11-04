---
name: tinredmc-ultralitebldc
url: https://github.com/TiNredmc/UltraLiteBLDC
source_type: repo
vendor: lattice
board: [iCE40UL1K SWG16 (개발 보드 미명시)]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog (파일 확장자 근거, 언어 통계는 비어 있음)
tools: [iCECube2, Lattice LSE]
bus: I2C 슬레이브 (iCE40UL 하드 I2C)
peripherals: [actuator-servo, comm-i2c]
stage: T2
license: GPL-3.0
stats: {stars: 2, commits: 8}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: README와 루트만 열람. 하위 폴더 내용은 unverified
unverified_source_rev: 열람 가능한 경로에서 SHA를 얻지 못함
sources: [https://github.com/TiNredmc/UltraLiteBLDC]
---

## 요약
초소형 iCE40UL1K로 BLDC 3상 구동 파형을 만들고, I2C로 속도와 방향을 받는 프로젝트. 출력은 오픈드레인 PWM이라 외부 풀업과 H-브리지 드라이버가 필요하다. 센서 없는 단순 구동 사례.

## 구조
- 최상위 top.v, top_prim.v와 합성 폴더 UltraLite_BLDC_DRV_Implmnt (내부 모듈 이름은 unverified).
- 출력: SB_RGBA_DRV 프리미티브로 PWM 구동하는 오픈드레인, 채널마다 외부 풀업.
- I2C 호스트 인터페이스: 하드 I2C IP, 최대 400 kHz. 명령: 속도 설정 0x10(값 0~255, 기본 0), 모터 켬 0x01, 끔 0x02(기본), 시계방향 0x0A(기본), 반시계 0x0B.
- 합성 설정: FSM 인코딩 Binary, 최적화 Balanced, 목표 48 MHz (README 서술).

## 검증·재현성
- 테스트벤치, 자원 사용, 실제 구동 모터: unverified: README에 없음.

## 한계·위험
- 홀 센서 입력, 데드타임 삽입, 폐루프 제어는 README에 언급 없음 → 확인되지 않음.
- GPL-3.0 → 코드를 하네스에 반입하지 않고 명령 체계 같은 사실만 기록.
- iCE40UL 전용 프리미티브(SB_RGBA_DRV, 하드 I2C)는 Artix-7에 없어 포팅 필요.

## 재사용 메모
- 내 판단: 속도(0~255), 켬/끔, 방향의 3개 지령만으로 구동하는 최소 레지스터 구성은 A 트랙 BLDC 입문(최상 단계 전 단계)의 최소 IP 범위를 정하는 참고가 된다. 데드타임이 없으므로 실제 3상 브리지를 직결하면 위험하다(내 판단).
- 개조: I2C 명령 대신 AXI4-Lite 레지스터(SPEED, CONTROL, DIR)로 옮기고 오픈드레인 프리미티브는 일반 3.3 V 출력으로 바꾼다. 하드 I2C IP는 옮길 수 없다.
