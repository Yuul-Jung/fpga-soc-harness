---
name: digilent-basys-3-keyboard
url: https://github.com/Digilent/Basys-3-Keyboard
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado 2018.2, Vivado 2022.1]
bus: none
peripherals: [hid-ps2, comm-uart]
stage: T1
license: unknown
stats: {stars: 19, commits: 13}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-07
status: 2026-11-02 /verify 재열람: 저장소 페이지만 성공(Vivado 2018.2, 별 19, 커밋 13, 9600 baud, F0 접두 일치). 데모 페이지·포럼·매뉴얼 출처는 미재열람
sources: [https://github.com/Digilent/Basys-3-Keyboard, https://reference.digilentinc.com/programmable-logic/basys-3/demos/keyboard, https://forum.digilent.com/topic/24733-does-basys-3-usb-hid-supports-device-with-mousekeyboard/, https://www.physics.umd.edu/hep/drew/495/basys3_rm.pdf]
unverified: 소스 모듈·포트·xdc 미열람(저장소 README와 데모 페이지만 읽음), source_rev 미확인(범위 밖 저장소의 커밋 SHA를 조회하지 못함)
---

## 요약
Digilent 공식 Basys3 키보드 데모. 보드의 USB HID 호스트 포트(J2)에 꽂은 USB 키보드의 키 코드를 FPGA가 받아 USB-UART로 PC 터미널에 내보낸다. 눌림과 뗌이 각각 코드로 나오며, 뗌은 F0 접두가 붙은 PS/2 방식이다.

## 구조
- 저장소 최상위: `digilent-vivado-scripts/`(서브모듈), `proj/`, `repo/`, `sdk/`, `src/`, `project_info.tcl`, `README.md` (저장소 페이지 기준).
- 동작 예: 'a' 키는 `1C`, 뗄 때 `F0 1C`. 여러 키는 입력 순서대로 나옴 (데모 페이지 기준).
- 시리얼 속도 9600 baud (저장소 README 기준).
- 보드 쪽 사실(Basys3 레퍼런스 매뉴얼): PIC24FJ128 보조 MCU가 USB HID를 PS/2 버스로 에뮬레이션하므로 FPGA는 PS/2 호스트로 동작한다. 신호는 PS2_CLK, PS2_DAT이며 FPGA 핀 C17, B17이 표기되나 신호와의 대응은 xdc로 확인해야 한다. 클럭·데이터는 유휴 시 High라 FPGA 내부 풀업이 필요하다고 서술.
- 모듈 목록, 최상위 포트, 레지스터: unverified: `src/` 미열람.

## 검증·재현성
- 빌드: 릴리스 ZIP의 Vivado 프로젝트를 열고 합성·구현·비트스트림 후 하드웨어 매니저로 프로그램. 데모 페이지는 5~60분이 걸릴 수 있다고 안내.
- 테스트벤치·CI·자원 사용·WNS: unverified: 어느 페이지에도 없음.

## 한계·위험
- 라이선스 표기 없음 → `unknown`. 코드를 가져오려면 라이선스 확인 필요.
- 버전 어긋남: 저장소 README는 Vivado 2018.2, 데모 페이지는 2022.1 릴리스를 안내. README의 `vivado_proj/` 폴더명과 실제 목록의 `proj/`도 다르다.
- USB 허브 미지원. 키보드나 마우스 중 하나만 쓸 수 있다(매뉴얼 기준). 포럼 질문자는 키보드+마우스 복합 장치에서 마우스로만 인식되는 문제를 보고했고, 답변은 펌웨어에 허브 지원이 없다는 것이었다(포럼 기준, 해결책 없음).
- 이 저장소의 키 코드는 PS/2 set 2 스캔코드 그대로라서 ASCII 변환은 별도로 써야 한다.

## 재사용 메모
- 내 판단: 키보드 입력 경로 전체(HID→PS/2→UART)가 하나의 FSM으로 닫혀 있어 T1 수준의 입력 주변장치 기준점으로 쓸 수 있다. 우리 SoC의 MMIO 레지스터(수신 바이트 + 유효 비트)로 감싸는 방식으로 연결된다.
- 내 판단: 코드는 가져오지 않고, 매뉴얼에서 뽑은 프로토콜(F0/E0 접두, 마우스 AA→00→F4 초기화)을 근거로 자체 PS/2 수신기와 테스트벤치를 새로 쓴다. 장치 모델을 테스트벤치에 두면 보드 없이 검증 가능.
