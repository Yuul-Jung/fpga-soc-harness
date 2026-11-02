---
name: element14-security-camera-2-sd-card-interfacing
url: https://community.element14.com/challenges-projects/design-challenges/summer-of-fpga/b/blog/posts/security-camera-2-sd-card-interfacing-52194343
source_type: article
vendor: amd
board: ["CMOD S7 (페이지 태그 기준, 본문 미명시)"]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: ["unverified: 글에 도구 이름 없음"]
bus: none
peripherals: [storage-sd, comm-spi, comm-uart]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-02
sources: [https://community.element14.com/challenges-projects/design-challenges/summer-of-fpga/b/blog/posts/security-camera-2-sd-card-interfacing-52194343, https://digilent.com/reference/_export/xhtml/pmod/pmodmicrosd/reference-manual]
---

## 요약
element14 "Summer of FPGA" 챌린지 보안 카메라 프로젝트 2편. SPI 모드 SD 카드 인터페이스를 Verilog로 직접 쓴 글로, 초기화 순서와 512바이트 블록 쓰기를 설명한다.

## 구조
- 모듈 3개: 파라미터화된 SPI 마스터(모드 0 사용, 저속·고속 두 클럭), `sdcard_interface` 상태기계(초기화·쓰기, RGB LED 상태 표시), 디버그용 UART(9600 baud).
- 초기화: 80클럭 이상 CS·MOSI 높음 → CMD0 → CMD8 → CMD59(CRC 끔) → CMD55+ACMD41 반복(1000회 실패 시 처음부터) → CMD58로 OCR 확인(SDHC/SDXC) → 고속 클럭 전환. 초기화 중 클럭은 약 400 kHz 이하라고 글이 설명(코드는 100 MHz/250 = 400 kHz, 재열람). 코드에는 CMD16(블록 길이 512)도 있고 쓰기 상태 확인에 CMD13을 씀.
- 쓰기: CMD24로 한 블록(512바이트, 예제 주소 2050), 시작 토큰 → 데이터 → 응답 → busy 해제 대기. 블록은 끊김 없이 한 번에 보내야 해서 FIFO에서 다음 바이트를 요청하는 구조.
- SD 모드는 약 100 Mbit/s이나 NDA·로열티가 필요하고 SPI 모드는 약 25 Mbit/s라고 글이 설명(글의 서술이며 SD 협회 문서는 미열람).

## 검증·재현성
- 전체 Verilog가 글 안에 인라인으로 실려 있음. 별도 저장소 링크 없음. 블록 읽기는 이 글에서 구현·설명하지 않음. 동작 검증은 다음 편 예고만 있음.
- 자원 사용량: 글에 없음.

## 한계·위험
- 글 내 불일치(재열람): 고속 분주 파라미터는 HI_FREQ_DIV=20(100 MHz 기준 5 MHz, 내 계산)인데 주석은 100MHz/6=16.7MHz로 적어 실제 속도가 불명확.
- 라이선스 명시 없음 → unknown. 코드 복사 금지, 순서(시퀀스)만 참고.
- 보드가 Basys3가 아니므로 핀 제약은 새로 써야 함. 글 속 시스템 클럭은 100 MHz로 주석에 나온다(Basys3와 같은 값).
- 공식 Pmod MicroSD 매뉴얼(L3): 1번 ~CS, 2번 MOSI, 3번 MISO, 4번 SCK, 9번 카드 감지(CD), 전원 3.3 V(SD 규격 2.7–3.6 V). 최대 클럭은 매뉴얼에 없음.

## 재사용 메모
- 내 판단: CMD 시퀀스와 "저속 초기화 → 고속 전환" 구조가 간결해 SD SPI 초기화 테스트벤치(카드 모델 응답 PASS/FAIL)의 기준 시나리오로 쓸 수 있다.
- 내 판단: 읽기 경로가 없으므로 읽기까지 있는 wangxuan95-fpga-sdcard-file, 레지스터 인터페이스 설계는 zipcpu-sdspi와 짝지어 사다리를 만들 수 있다.
