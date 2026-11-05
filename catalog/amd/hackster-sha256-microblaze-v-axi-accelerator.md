---
name: hackster-sha256-microblaze-v-axi-accelerator
url: https://www.hackster.io/raymondkelly454/sha-256-hardware-accelerator-for-microblaze-v-zybo-7000-eb4e99
source_type: article
vendor: amd
board: [Zybo 7000]
fit_basys3: needs-port
cpu: MicroBlaze V
language: SystemVerilog C
tools: [Vivado, Vitis, PetaLinux]
bus: AXI4-Lite AXI-Stream
peripherals: [accelerator]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://www.hackster.io/raymondkelly454/sha-256-hardware-accelerator-for-microblaze-v-zybo-7000-eb4e99]
---

## 요약
Zybo 7000 보드의 MicroBlaze-V 위에서 SHA-256 하드웨어 가속기를 구현한 Hackster.io 프로젝트. 사용자 IP(SystemVerilog)를 AXI4-Lite 제어 인터페이스 + AXI Stream 데이터 인터페이스로 패키징하고, AXI DMA를 통해 DDR 메모리에서 데이터를 공급하는 흐름을 보여준다.

## 구조
- **IP 패키징**: Vivado "Create and Package New IP" → "Create a new AXI4 Peripheral"으로 뼈대 생성 → 자동 생성 Verilog를 제거하고 SystemVerilog 소스 삽입 → 패키지 재등록
- **블록 디자인**:
  - AXI4-Lite 슬레이브: 제어·상태 레지스터(10개) → SmartConnect → MicroBlaze-V M_AXI 버스
  - AXI Stream 슬레이브: AXI DMA의 MM2S 채널 → SHA-256 코어 (DMA는 Zynq HP 포트로 DDR 접근)
  - 클럭·리셋은 연결 자동화(Connection Automation)로 연결
- **레지스터 맵** (AXI4-Lite, 오프셋):
  - 0x00 제어: `0x2` 다이제스트 리셋, `0x1` 첫 블록 플래그, `0x0` 이후 블록
  - 0x04 상태: bit0 코어 완료, bit1 마지막 블록 완료 (소프트웨어가 폴링)
  - 0x08~ 다이제스트: 32비트 × 8워드 (SHA-256 출력)
- **xparameters.h 매크로 사용**:
  - `XPAR_AXI_DMA_0_BASEADDR` — DMA 베이스 주소
  - `XPAR_SHA256_COMPRESSION_0_BASEADDR` — SHA 코어 베이스 주소
  - `XPAR_AXI_TIMER_0_CLOCK_FREQUENCY` — 타이머 클럭(성능 측정용)
- **소프트웨어 API**:
  - 제어 레지스터: `Xil_Out32(BASEADDR + 오프셋, 값)` 직접 쓰기
  - 상태 레지스터: `Xil_In32(BASEADDR + 0x04)` 폴링
  - DMA: `XAxiDma_LookupConfig` → `XAxiDma_CfgInitialize` → `XAxiDma_IntrDisable` → `XAxiDma_SimpleTransfer` → 완료 폴링
  - 타이머: `XTmrCtr`로 64비트 사이클 카운트 (성능 측정)
- **데이터 흐름**: 메시지를 32 MB 단위로 분할 → DMA 전송 → SHA 상태 폴링 → 다이제스트 읽기

## 검증·재현성
- Hackster.io 프로젝트 (실제 보드 테스트 포함 추정, 기사 내 하드웨어 결과 언급). 그러나 CI·테스트벤치 없음.
- PetaLinux 플로우: `petalinux-config --get-hw-description` → `petalinux-build` → `petalinux-package --boot`

## 한계·위험
- Basys3는 MIG(DDR 컨트롤러)가 없어 AXI DMA + DDR 흐름은 직접 재현 불가. BRAM 버퍼 대체 필요.
- AXI Stream 인터페이스는 Basys3 MicroBlaze-V가 HP 포트가 없는 Artix-7 패브릭에서 연결 방식을 바꿔야 한다.
- DMA 완료를 인터럽트 없이 폴링 방식으로 처리. 빈 딜레이 루프(하드웨어 버그 우회)가 소스에 존재.
- 라이선스 미명시.

## 재사용 메모
- 내 판단: MicroBlaze-V + 사용자 AXI IP + xparameters.h 패턴을 최신 버전 기준으로 보여 주는 드문 자료. 사용자 IP 패키징(SystemVerilog 삽입 → 재패키지) 흐름은 직접 참고 가능.
- 개조: Basys3 이식 시 DDR+DMA → BRAM 블록으로 교체. AXI4-Lite 제어·상태 레지스터 패턴(0x00 제어, 0x04 상태, 0x08~ 결과)은 IP 표준(`config/ip_standard.json`)의 레지스터 레이아웃과 비교해 그대로 적용 가능. `XPAR_<IP>_0_BASEADDR` 매크로가 동결 맵의 `free_slots` 배정 주소와 일치하는지 확인한다. `Xil_Out32`/`Xil_In32` 직접 접근 패턴은 드라이버 없는 초기 검증 단계에 쓸 수 있다.
