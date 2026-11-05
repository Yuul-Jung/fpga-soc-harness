---
name: zipcpu-icontrol
url: https://zipcpu.com/zipcpu/2019/04/02/icontrol.html
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [sby (formal)]
bus: Wishbone
peripherals: []
stage: T2
license: GPL-3.0
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev:
sources: [https://zipcpu.com/zipcpu/2019/04/02/icontrol.html, https://github.com/ZipCPU/zipcpu/blob/master/rtl/peripherals/icontrol.v]
---

## 요약 (3줄 이내, 내 표현으로)

ZipCPU 프로젝트용 Verilog 인터럽트 컨트롤러(`icontrol.v`). 최대 15개 인터럽트 입력을 단일 `o_interrupt` 출력으로 집계하는 Wishbone 슬레이브. 열림(pending) 비트 래칭·소스별 활성화·마스터 인터럽트 활성화(MIE)로 구성되며, 출력을 레지스터 처리해 CPU 타이밍 부담을 없앤다.

## 구조
- **입력:** 최대 15개 `i_irqs` + Wishbone 버스(단일 주소, 32비트 데이터)
- **출력:** `o_interrupt` (레지스터 처리됨), `o_wb_ack` (동사이클 응답, 절대 stall 없음)
- **레지스터 레이아웃(단일 주소, 비트 필드):**
  - 비트 [14:0]: pending 비트 (소스별 인터럽트 래치). 1을 쓰면 클리어, 소스가 계속 활성이면 재설정
  - 비트 [30:16]: 소스별 Enable (상위 16비트 쓰기, 비트 15로 set/clear 선택)
  - 비트 31: 마스터 인터럽트 활성화(MIE). 모든 출력의 최종 게이트
- **우선순위:** 없음. `o_interrupt`는 MIE AND (enabled pending sources) 조건으로만 결정
- **출력 조건:** `o_interrupt = MIE & |(pending & enabled)`
- **블로그에서 확인한 2세대 개선점:** 1세대는 소스별 Enable 쓰기가 MIE를 부수는 버그. 2세대는 bit 31도 함께 쓸 때만 MIE가 바뀜
- **ArrowZip 적용 사례:** 15개 인터럽트 입력 연결. AutoFPGA로 조합

## 검증·재현성
- 형식 검증(sby, Symbiyosys): 리셋 동작, 인터럽트 생성, enable/disable 쓰기, Wishbone 버스 동작 전부 assertion
- 테스트벤치 없음(형식 검증으로 대체). 시뮬레이션 결과는 별도 미확인
- 소스 직접 열람 불가(PROVENANCE_REQUIRED): 블로그 본문으로만 L3 판정
- 빌드: ZipCPU 저장소 내 `rtl/peripherals/icontrol.v`

## 한계·위험
- Wishbone 인터페이스 전용 → AXI4-Lite 환경(MicroBlaze V)에는 직접 사용 불가
- 소스별 우선순위 없음. 가장 낮은 번호(bit 0) 소스가 먼저 처리되는 소프트웨어 의존적 구조
- GPL-3.0: 라이선스 전파 조건 주의 (파생 작업 배포 시)
- ArrowZip에서 2세대 버전이 "모든 프로젝트에 아직 전파되지 않았다"고 명시

## 재사용 메모
- 비트 필드 구조(pending/enable/MIE를 한 레지스터에 묶는 방식)는 Basys3 AXI INTC 자체 구현 시 참고 가능. MicroBlaze V 기준이라면 AMD AXI INTC(PG099)가 더 적합
- 형식 검증 절차(assertion 패턴, Wishbone 가정, cover 문)는 AXI4-Lite INTC 자체 RTL 테스트벤치 설계에 직접 이식 가능
- 개조: Wishbone → AXI4-Lite 변환이 핵심. 레지스터 맵(ISR·IER·MER)은 AMD PG099(카드 `amd-axi-intc-pg099`)에 맞춰 재설계하고, 소스 RTL은 버리되 인터럽트 래칭·MIE 로직(2세대 고침 포함)은 그대로 차용 가능. `free_slots` 배정 후 IP 표준 AXI4-Lite 래퍼로 새로 작성 권장
