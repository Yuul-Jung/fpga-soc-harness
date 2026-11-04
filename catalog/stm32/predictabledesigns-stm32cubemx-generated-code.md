---
name: predictabledesigns-stm32cubemx-generated-code
url: https://predictabledesigns.com/auto-generated-firmware-code-deconstructing-an-stm32cubemx-project/
source_type: article
vendor: neutral
board: [STM32F103C8 (글의 예)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M3)
language: C
tools: [STM32CubeMX]
bus: none
peripherals: [comm-uart, comm-i2c, sensor]
stage: T1
license: unknown (블로그 글, 코드 반입 대상 아님)
stats: {last_update: 2023-09-22}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://predictabledesigns.com/auto-generated-firmware-code-deconstructing-an-stm32cubemx-project/]
---
unverified: source_rev — 블로그 글이라 해당 없음

## 요약
CubeMX가 만든 STM32F103C8 프로젝트의 폴더와 생성 코드를 하나씩 풀어 설명하는 글이다. 2022-07-20 발행, 2023-09-22 수정(글 표기), 저자는 Brandon Alba로 표기된다.

## 구조
- 루트: .ioc 프로젝트 파일, Makefile, 어셈블리 시작 파일(약한 인터럽트 핸들러 정의). Core/Src: main.c, `stm32f1xx_hal_msp.c`(핀·클럭·인터럽트 설정), `stm32f1xx_it.c`, `system_stm32f1xx.c`. Core/Inc: main.h, `stm32f1xx_hal_conf.h`(HAL 모듈 선택). Drivers/: CMSIS와 HAL 드라이버.
- main()은 HAL_Init → SystemClock_Config → 주변장치별 MX_*_Init 순서. 주변장치마다 핸들 구조체(hadc1, hi2c1, huart1)가 생기고, 예로 MX_USART1_UART_Init가 huart1의 Instance와 Init 하위 구조체를 채워 HAL_UART_Init에 넘긴다.
- GPIO는 핸들이 없고 포트·핀을 직접 인자로 받는다(HAL_GPIO_TogglePin).
- `USER CODE BEGIN/END` 블록 안의 코드만 재생성 때 보존된다.

## 검증·재현성
- 글의 서술만 확인했고 프로젝트 파일은 받지 않았다. unverified: 글의 코드와 실제 CubeMX 버전별 출력 차이.

## 한계·위험
- 글이 든 위험: 하드웨어에 없는 DMA 연결도 컴파일되고 런타임 HardFault가 난다. 보드 리비전이 여럿이면 생성 구조가 불편하다. HAL은 레지스터 직접 접근보다 오버헤드가 있다는 비판이 있다.
- 댓글 한 건: DMA 초기화가 USART 초기화 뒤에 생성돼 DMA가 깨졌다는 보고(글 본문 아님, .ioc 편집으로 우회했다고 함). 확인하지 못함.

## 재사용 메모
- 내 판단: "주변장치당 핸들 구조체 + init 함수 + MSP(핀·클럭) 분리"는 FPGA 쪽 IP 표준 래퍼의 레지스터 블록(설정)과 보드 래퍼(핀·클럭)의 분리와 같은 발상이다.
- 개조: 옮길 부분은 핸들/Init 분리와 USER CODE 보존 규약(생성물과 손코드 분리)의 설계 아이디어. 못 옮길 부분은 CubeMX, HAL 코드 자체, Cortex-M 전용 인터럽트 설정(`cpu_irq_<cpu>.c`로 격리).
- 소프트웨어 드라이버 구조: MicroBlaze V 쪽 CPU 비종속 드라이버(레지스터 접근과 응용 로직 분리)의 비교 사례로 쓸 수 있다.
