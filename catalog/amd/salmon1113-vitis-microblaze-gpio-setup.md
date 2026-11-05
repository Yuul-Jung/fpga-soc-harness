---
name: salmon1113-vitis-microblaze-gpio-setup
url: https://salmon1113.tistory.com/140
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: needs-port
cpu: MicroBlaze
language: C
tools: [Vivado, Vitis]
bus: AXI4-Lite
peripherals: [comm-uart, debug]
stage: T3
license: unknown
stats: {}
doc_language: ko
verification: L3
checked_at: 2026-11-05
sources: [https://salmon1113.tistory.com/140]
unverified: 보드 정확한 모델, 도구 버전, 갱신일
---

## 요약
한국어로 작성된 MicroBlaze + Vitis 플랫폼 첫걸음 튜토리얼. Vivado에서 블록 디자인(MicroBlaze + clk_wiz + GPIO + UART)을 구성하고 XSA로 내보내 Vitis에서 BSP를 자동 생성한 뒤 xparameters.h를 활용해 LED 쉬프트와 버튼 입력을 구현한다. 국내 사용자의 Basys3 환경과 직접 연결되는 한국어 자료.

## 구조
- **블록 디자인**:
  - MicroBlaze + "Run Block Automation"(인터럽트 컨트롤러, 메모리 컨트롤러, 클럭·리셋 자동 연결)
  - clk_wiz: 클럭 생성·주파수·위상·분주 설정
  - AXI GPIO(출력 LED), AXI GPIO(입력 버튼), AXI Uartlite
  - 주소맵 자동 구성
- **XSA 내보내기**: 비트스트림 생성 → "Export Hardware(Include Bitstream)" → `.xsa` 파일
- **Vitis BSP 자동 생성**:
  - `.xsa` 임포트 → 플랫폼 생성 → 도메인 선택 → BSP 빌드
  - `xparameters.h` 자동 생성: 각 주변장치의 베이스 주소(`XPAR_AXI_GPIO_0_BASEADDR` 등), UART 보드레이트, Device ID 등이 선언됨
- **GPIO 레지스터 직접 접근**:
  - 오프셋 0x00: 데이터 레지스터(LED 값 쓰기)
  - 오프셋 0x04: 모드 레지스터(0=출력, 1=입력 방향 설정)
  - 출력 모드 설정 후 데이터 레지스터에 값 써서 LED 점멸; `usleep(300000)`으로 지연
- **버튼 입력 추가**: 입력용 GPIO IP 별도 추가 → XSA 재생성 → Vitis 플랫폼 갱신 → 버튼 상태로 LED 쉬프트 방향 제어

## 검증·재현성
- 단계별 스크린샷과 코드 조각 포함. 실제 보드 테스트 여부는 본문에서 확인하지 못함(unverified).
- 주의: 본문이 8비트 예시로 설명하지만 코드는 16비트 기준 쉬프트값을 사용하므로 비트 폭 확인 필요.

## 한계·위험
- 도구 버전 미명시. Vivado/Vitis 24.2와 UI가 다를 수 있음.
- 사용자 정의 AXI IP 패키징, 커스텀 드라이버, 인터럽트 없음(GPIO 폴링 방식만).
- 라이선스 미명시(블로그 포스트).

## 재사용 메모
- 내 판단: Basys3 한국어 환경에서 MicroBlaze Vitis 첫 단계를 익히는 데 적합. xparameters.h 자동 생성과 GPIO 레지스터 직접 접근(오프셋 0x00/0x04) 패턴을 국문으로 확인할 수 있다.
- 개조: MicroBlaze V(Vitis 2024.2) 기준으로 블록 자동화 절차는 거의 동일하다. xparameters.h의 `XPAR_AXI_GPIO_0_BASEADDR`가 동결 맵 GPIO 슬롯 주소와 일치하는지 확인한다. 버튼 입력 GPIO를 추가할 때 XSA를 재생성하면 xparameters.h의 `XPAR_AXI_GPIO_1_BASEADDR`도 자동 갱신된다는 점을 L 트랙 실습 절차에 적용 가능.
