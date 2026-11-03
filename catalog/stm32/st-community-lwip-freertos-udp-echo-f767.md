---
name: st-community-lwip-freertos-udp-echo-f767
url: https://community.st.com/t5/stm32-mcus/implementing-a-lwip-and-freertos-v1-udp-echo-server-on-the/ta-p/780261
source_type: article
vendor: neutral
board: [NUCLEO-F767ZI]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M7)
language: C (ST HAL + LwIP + FreeRTOS CMSIS_V1)
tools: [STM32CubeIDE 1.18.1, STM32CubeMX 6.14.1, Packet Sender]
bus: Ethernet (RMII, LwIP netconn)
peripherals: [comm-eth]
stage: T3
license: unknown (커뮤니티 글, 코드 반입 대상 아님)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/t5/stm32-mcus/implementing-a-lwip-and-freertos-v1-udp-echo-server-on-the/ta-p/780261]
---
unverified: source_rev — 커뮤니티 글이라 해당 없음. unverified: 게시일

## 요약
NUCLEO-F767ZI에서 LwIP와 FreeRTOS(CMSIS_V1)로 UDP 7번 포트 에코 서버를 만드는 CubeMX 설정 절차 글이다. 타임베이스를 SysTick 대신 TIM6으로 돌리고, 이더넷 디스크립터를 링커 스크립트로 전용 영역에 배치하는 점이 특징이다.

## 구조
- 값(글 서술): RMII, 이더넷 인터럽트 선점 우선순위 5, GPIO 속도 Very High, 보드 PHY는 LAN8740이며 드라이버는 LAN8742로 지정. 코어 216 MHz, 캐시 사용, MPU 영역 설정.
- 값(글 서술): LwIP `MEM_SIZE` = 16*1024, `LWIP_RAM_HEAP_POINTER` = 0x20078000, `LWIP_NETIF_LINK_CALLBACK` 사용. defaultTask 스택 512 워드.
- 값(글 서술): 링커에 `.RxDecripSection`(0x2007C000, 0xA0)과 `.TxDecripSection`(0x2007C0A0, 0xA0) 배치.
- 값(글 서술): `udpecho_thread`가 `netconn_new(NETCONN_UDP)`로 포트 7에 바인드하고, 수신 패킷마다 송신자 주소·포트를 읽어 `netconn_send`로 되돌린 뒤 버퍼를 해제.
- 값(글 서술, 댓글): CMSIS_V2 사용 시 H723 보드가 몇 분 뒤 핑에 응답하지 않았고 V1로 바꾸면 9시간 동작했다는 독자 보고(다른 보드, 글 작성자 확인 아님). F779I-EVAL에서 MPU 설정으로 하드 폴트가 났다는 보고도 있음.
- unverified: MPU 영역 1·2의 세부 값(글에서 이미지로만 제시).

## 검증·재현성
- 시험은 Packet Sender로 UDP 7번에 보내 에코를 확인하는 수동 절차. 자원(RAM/Flash) 수치와 CI는 없다.

## 한계·위험
- F7 전용 메모리 주소가 하드코딩되어 있어 다른 칩으로 옮길 때 데이터시트 확인이 필요하다고 글과 댓글이 지적.
- 장시간 안정성은 RTOS API 버전에 좌우된다는 독자 보고가 있으나 근거는 한 건이다.
- 라이선스 미표기 → 코드 반입 금지.

## 재사용 메모
- 내 판단: 이 글의 구조(링크 콜백, 소켓 한 개를 스레드가 소유, 수신→송신자 정보로 회신)는 FPGA 쪽 UDP 에코 IP를 만들 때 STATUS(링크 상태)·RX 메타데이터(원격 IP/포트) 레지스터 설계의 참조가 된다.
- 개조: 옮길 부분은 링크 업/다운 이벤트를 인터럽트 소스로 두는 규약과 RX 메타데이터 레지스터 구성, 포트 7 에코 시험 시나리오(시험 환경). 못 옮길 부분은 LwIP·MPU·디스크립터 메모리 배치(CPU·MAC 전용).
- 관련: [[wiznet-makers-gavinchang-w5500-udp-loopback]], [[digilent-pmod-nic100-reference-manual]], [[digilent-forum-basys3-ethernet-ipv4-udp]].
