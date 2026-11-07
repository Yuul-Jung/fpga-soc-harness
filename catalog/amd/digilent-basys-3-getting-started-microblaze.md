---
name: digilent-basys-3-getting-started-microblaze
url: https://reference.digilentinc.com/learn/programmable-logic/tutorials/basys-3-getting-started-with-microblaze/start
source_type: course
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: MicroBlaze
language: none
tools: [Vivado (버전 미표기), Xilinx SDK]
bus: AXI4-Lite
peripherals: [comm-uart]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-08
sources: [https://digilent.com/reference/_export/xhtml/learn/programmable-logic/tutorials/basys-3-getting-started-with-microblaze/start]
unverified: 게시·수정일, Vivado 정확한 버전, 라이선스(문서 사이트 약관 미확인)
---

status: 문서가 구식(obsolete)이라고 표기하고 갱신판 안내로 넘긴다(열람한 페이지의 안내 기준). 2024.2 + MicroBlaze V 절차로는 그대로 쓸 수 없다.

## 요약
Digilent의 Basys3용 MicroBlaze 첫걸음 튜토리얼. 클럭 위저드, MicroBlaze, USB UART(AXI Uartlite)만으로 블록 디자인을 만들고 Hello World를 SDK에서 실행하는 흐름이다.

## 구조
- 클럭: 시스템 클럭 → Clocking Wizard, clk_out1 100 MHz, 리셋 active-high (페이지 서술).
- MicroBlaze: 로컬 메모리 128 KB(ECC 없음), 캐시 없음, 디버그 모듈 Debug only, 주변장치 AXI 포트 사용, 인터럽트 컨트롤러 비활성.
- 주변장치: AXI Uartlite 하나, 기본 9600 baud. GPIO·타이머·인터럽트 컨트롤러는 없음. 메모리맵 주소는 페이지에 없음(`unverified`).
- 절차 12단계: RTL 프로젝트(보드 선택) → 블록 디자인 → 클럭 → MicroBlaze 블록 자동화 → UART 연결 자동화 → 검증·HDL 래퍼 → 비트스트림 → 하드웨어 내보내기 → SDK → 프로그램 → 터미널.

## 검증·재현성
- 테스트벤치·CI 없음(튜토리얼). 자원·타이밍 수치 없음.

## 한계·위험
- 사용자 정의 AXI IP 없음, 인터럽트 없음. 구식 표기. 도구가 SDK라 Vitis 2024.2와 다르다.

## 재사용 메모
- 내 판단: 우리 시리즈의 L 트랙 첫 단계(MicroBlaze + UART)와 구성이 같은 가장 낮은 기준선이다. 로컬 메모리 크기와 인터럽트 컨트롤러 유무가 이후 단계에서 달라지는 지점이므로 비교 기준으로 쓴다.
- 개조: MicroBlaze V 기준으로 코어 블록만 교체하고 클럭 100 MHz, UART 연결 자동화 흐름은 유지. 동결 맵의 UART 영역에 맞춰 주소를 확인한다(이 자료에는 주소가 없음).
