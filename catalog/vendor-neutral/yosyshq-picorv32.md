---
name: yosyshq-picorv32
url: https://software.mcgoron.com/Hardware/picorv32/src/commit/23b700cf73b7b01b4737db106226bd4220799290
source_type: repo
vendor: neutral
board: [범용]
fit_basys3: needs-port
cpu: PicoRV32
language: Verilog
tools: [unverified]
bus: native 메모리 인터페이스 + AXI4-Lite 변형(picorv32_axi) + 어댑터
peripherals: [timer-IRQ]
stage: T2
license: ISC
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-03
source_rev: 23b700cf73b7b01b4737db106226bd4220799290
sources: [https://software.mcgoron.com/Hardware/picorv32/src/commit/23b700cf73b7b01b4737db106226bd4220799290]
unverified: 원본 저장소(YosysHQ/picorv32) 직접 열람과 LICENSE 파일(미러 README 요약만 봄), 네이티브 메모리 신호 목록(요약에 없음), 외부 IRQ 활성 파라미터 이름, PCPI·Wishbone 래퍼 존재 여부(요약에 언급 없음), 자원 수치
---

## 요약
크기를 줄인 RV32 코어. 사용자가 붙이는 주변장치는 단순한 네이티브 메모리 인터페이스나 AXI4-Lite 변형으로 연결하고, 인터럽트는 q 레지스터와 전용 명령으로 처리한다.

## 구조
- 네이티브 메모리 인터페이스: 읽기 데이터는 `mem_valid`와 `mem_ready`가 모두 1인 사이클에서만 유효(`LATCHED_MEM_RDATA`=1이면 외부가 데이터를 유지해야 함). [README 미러]
- `picorv32_axi`는 AXI4-Lite 마스터 변형, `picorv32_axi_adapter`가 네이티브→AXI4 변환. 로컬 메모리·주변장치는 네이티브 버스에, 나머지는 AXI4로 밖에 연결하는 구성을 설명한다.
- 인터럽트: 모든 IRQ는 기본 비활성. 핸들러 시작은 `PROGADDR_IRQ`(기본 16), 리셋 시작은 `PROGADDR_RESET`(기본 0). 반환 주소·IRQ 번호는 q0·q1에 담기고, `maskirq`로 마스크(비트0 외부, 비트1 타이머, 비트2 불법 명령), `retirq`로 복귀. 불법 명령 IRQ가 꺼져 있으면 코어가 멈춘다.
- 타이머: `ENABLE_TIMER_IRQ`(기본 0)로 켜고, 다운 카운터가 1→0이 될 때 타이머 IRQ 발생.
- 라이선스: ISC (미러 README 요약 기준).

## 검증·재현성
- 빌드·실행하지 않았다(§7). 요약 열람이라 L2.

## 한계·위험
- 열람 경로가 미러이고 요약 도구를 거쳤다. 파라미터 이름 등 일부가 요약에서 빠졌다(unverified).
- 전용 IRQ 레지스터(q0~q3)와 사용자 정의 명령은 PicoRV32에만 있다.

## 재사용 메모
- 내 판단: 주변장치를 네이티브 인터페이스(valid/ready) 뒤에 두면 어댑터 하나로 AXI4-Lite로 감싸는 구조가 되므로, "주변장치는 CPU를 모르게" 만드는 선례다.
- 개조: 주변장치는 AXI4-Lite 슬레이브 래퍼 + 인터럽트 1비트 출력으로만 설계하고, PicoRV32 IRQ(q 레지스터, `maskirq`)는 `cpu_irq_picorv32.c` 한 파일에 격리한다. 옮기지 못하는 것: 코어와 q 레지스터 기반 인터럽트 처리. 코드는 가져오지 않는다(ISC이나 반입 승인 없음, G4). 관련: [[yosyshq-picorv32-picosoc]].
