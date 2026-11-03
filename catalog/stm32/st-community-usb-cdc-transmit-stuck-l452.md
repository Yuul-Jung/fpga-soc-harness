---
name: st-community-usb-cdc-transmit-stuck-l452
url: https://community.st.com/t5/stm32-mcus-embedded-software/stm32l452re-gt-usb-cdc-transmit-stuck-hcdc-gt-txstate-never/m-p/779785
source_type: article
vendor: neutral
board: [STM32L452RE (보드명 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C (ST HAL + USB Device 미들웨어)
tools: [STM32CubeIDE, STM32CubeL4 V1.18.1]
bus: USB
peripherals: [comm-uart]
stage: T1
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/t5/stm32-mcus-embedded-software/stm32l452re-gt-usb-cdc-transmit-stuck-hcdc-gt-txstate-never/m-p/779785]
---
unverified: source_rev — 포럼 글이라 해당 없음. unverified: 게시일

## 요약
STM32L452RE에서 CubeMX로 만든 USB CDC 가상 COM 포트가 PC에는 COM12로 잡히고 수신도 되는데, `CDC_Transmit_FS()`가 송신 상태 변수(`hcdc->TxState`)가 0으로 돌아오길 기다리며 멈추는 사례다. 해결로 채택된 답은 코드가 아니라 USB 데이터선 배선 문제(D+ = PA12, D− = PA11)였다.

## 구조
- 값(글 서술): 증상은 열거는 성공, PC→MCU 수신은 정상, MCU→PC 송신만 `TxState` 대기에서 정지. `hUsbDeviceFS.pClassData` 값이 유효하지 않다는 관찰과 `USBD_RegisterClass()`가 `USBD_OK`를 반환한다는 관찰이 함께 적혀 있다.
- 값(글 서술): 환경은 CubeIDE, CubeL4 펌웨어 패키지 V1.18.1, Windows 11, 단말 프로그램 Hercules 3.2.8.
- 값(글 서술): 채택 답변은 케이블 데이터선을 PA12(USB_DP)와 PA11(USB_DM)에 맞게 연결하라는 것이며 코드 수정은 없었다.
- unverified: 열거가 되는데도 배선이 틀렸다는 설명의 물리적 메커니즘(글에 없음).

## 검증·재현성
- 테스트벤치·CI 없음. 증상 보고와 채택 답변만 있다.

## 한계·위험
- 원인이 배선이라는 결론은 스레드 작성자가 채택한 답에 근거한다. 다른 USB CDC 송신 정지 원인(클럭, 버퍼 상태)을 배제한 것은 아니다. 내 판단: 같은 증상의 다른 스레드가 검색에 여러 건 나왔으므로(큐 참고) 원인은 하나로 단정할 수 없다.
- 라이선스 미표기 → 코드 반입 금지.

## 재사용 메모
- 내 판단: "수신은 되는데 송신이 상태 변수에서 멈춤"은 FPGA UART 브리지 IP에서 TX 완료 플래그와 FIFO 가득 상태를 분리해 STATUS 레지스터에 노출하는 설계 이유가 된다(펌웨어가 무한 대기하지 않도록 타임아웃 레지스터 포함).
- 개조: 옮길 부분은 TX busy/완료를 비트로 노출하고 펌웨어가 타임아웃으로 빠져나오는 규약. 못 옮길 부분은 USB 장치 스택 자체(Basys3의 USB 포트는 FTDI UART라 CDC 스택이 필요 없음).
- 관련: [[freertos-forum-stm32-cubemx-uart-example]].
