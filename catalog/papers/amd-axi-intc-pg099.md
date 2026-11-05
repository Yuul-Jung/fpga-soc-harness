---
name: amd-axi-intc-pg099
url: https://docs.amd.com/api/khub/documents/FvmVVMsqlVvvwmnk0k6G6A/content
source_type: article
vendor: amd
board: []
fit_basys3: yes
cpu: none(FSM)
language: VHDL
tools: [Vivado]
bus: AXI4-Lite
peripherals: []
stage: T3
license: Xilinx End User License
stats: {stars: n/a, commits: n/a, last_update: 2013-03-20}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev:
sources: [https://docs.amd.com/api/khub/documents/FvmVVMsqlVvvwmnk0k6G6A/content, https://users.ece.utexas.edu/~mcdermot/arch/articles/Zynq/pg099-axi-intc-2.pdf]
---

## 요약 (3줄 이내, 내 표현으로)

AMD(Xilinx) AXI Interrupt Controller(INTC) v3.0 제품 가이드 PG099. 최대 32개 주변장치 인터럽트를 하나의 `irq` 출력으로 집계하는 AXI4-Lite 슬레이브 IP로, Vivado IP 카탈로그에서 Basys3(Artix-7)에 바로 사용 가능하다. MicroBlaze V와의 연동 표준 IP이며 ISR/IER/IAR/IVR/MER 레지스터를 통해 소프트웨어·하드웨어 인터럽트를 모두 지원한다.

## 구조

**레지스터 맵 (AXI4-Lite, 4바이트 정렬):**

| 오프셋 | 레지스터 | 접근 | 설명 |
|--------|----------|------|------|
| 0x00 | ISR | R/W | 인터럽트 상태 (각 소스 발생 여부) |
| 0x04 | IPR | R   | 인터럽트 보류 (ISR AND IER, 선택) |
| 0x08 | IER | R/W | 인터럽트 활성화 (소스별 마스크) |
| 0x0C | IAR | W   | 인터럽트 확인 응답 (ISR 비트 클리어) |
| 0x10 | SIE | W   | IER 비트 원자 Set (선택) |
| 0x14 | CIE | W   | IER 비트 원자 Clear (선택) |
| 0x18 | IVR | R   | 최고 우선순위 활성 소스 번호 (선택, 없으면 all-1) |
| 0x1C | MER | R/W | 마스터 활성화: ME(bit 0) 전체 게이트, HIE(bit 1) HW 인터럽트 활성 |
| 0x20 | IMR | R/W | 고속 인터럽트 모드 (소스별, 선택) |
| 0x100–0x17C | IVAR | R/W | 소스별 벡터 주소 (고속 모드 전용) |

**신호 목록:**
- AXI: `s_axi_aclk`, `s_axi_aresetn` (active-Low), 표준 AXI4-Lite 채널 5개
- 인터럽트: `intr[N-1:0]` (입력, N=1~32), `irq` (출력)
- 고속 모드 전용: `interrupt_address[31:0]` (출력), `processor_ack[1:0]` (입력), `processor_clk`, `processor_rst`, cascade 신호

**우선순위:** 비트 0(INT0)이 최고, 비트 31(INT31)이 최저. IVR로 소프트웨어 벡터링 지원.

**에지/레벨 감지:** 소스별 개별 설정(Rising/Falling Edge, High/Low Level). 출력 `irq`도 edge/level 선택 가능.

**고속 인터럽트 모드:** IMR 비트 설정 시 `processor_ack` 핸드셰이크와 IVAR 주소 출력으로 하드웨어 벡터링 지원.

**캐스케이드:** bit 31을 하위 인스턴스에 연결해 32개 이상 소스 처리 가능.

## 검증·재현성

- Artix-7(XC7A100T-3) 기준 자원: 8 입력→176 LUT/161 FF, 32 입력→406 LUT/427 FF
- Artix-7 Fmax ≈ 120 MHz (일반 특성치), Basys3 XC7A35T에서는 약간 낮을 수 있음
- Vivado IP 카탈로그에서 직접 인스턴스화. XDC 불필요(내부 타이밍 제약 포함)
- 별도 testbench·예제 설계 없음. ModelSim/Questa SIM으로 시뮬레이션 가능

## 한계·위험
- VHDL 전용 (Verilog 래퍼 없음). Vivado IP 카탈로그로만 사용하거나 Xilinx EULA 조건 하에서만 배포 가능
- ISR은 HIE가 0일 때만 소프트웨어로 쓸 수 있어 테스트 주입에 제한
- IER이 소스를 막아도 ISR 래치는 계속 됨. 재활성화 시 즉시 IRQ 발생 주의
- IVAR 레지스터는 ME=0 상태에서만 쓸 것 (비동기 위험)
- 단일 인스턴스 최대 32개. 그 이상은 cascade 필수

## 재사용 메모
- MicroBlaze V + Basys3 조합의 표준 인터럽트 컨트롤러. 동결 맵의 `free_slots`에서 하나를 배정해 Vivado 블록 다이어그램으로 연결하면 됨
- 레지스터 맵(ISR/IER/IAR/MER 순서와 오프셋)을 Basys3 AXI4-Lite 자체 INTC IP 설계 시 그대로 채택할 수 있음 — 소프트웨어 드라이버(XIntc_*)가 이 오프셋을 가정함
- 개조: 이 IP는 VHDL 클로즈드이므로 Verilog 자체 RTL로 동일 레지스터 맵을 구현하는 것이 IP 표준 준수의 핵심. `config/soc_address_map.json`의 free_slot에 배정하고 AXI4-Lite 래퍼(`config/ip_standard.json` 준수)로 새로 작성하면, XIntc 드라이버와 호환되는 오픈소스 대체 IP가 된다. 대체할 수 없는 부분: 고속 인터럽트 모드(`interrupt_address`/`processor_ack`)는 MicroBlaze 전용 신호이므로 MicroBlaze V 삭제 시 제거해야 함
