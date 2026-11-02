---
name: shubhayu-das-vl504-project
url: https://github.com/Shubhayu-Das/VL504-project
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado, Python, MATLAB]
bus: none
peripherals: [camera, video-vga, comm-uart]
stage: T4
license: BSD-3-Clause
stats: {commits: 4}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2026-11-02 /verify 재열람 시도 실패(WebFetch 권한 요청 미응답) — 이번 사이클 미대조, rechecked_at 미기록
sources: [https://github.com/Shubhayu-Das/VL504-project]
---

## 요약
IIITB의 VL504(FPGA 시스템 설계) 수업 프로젝트. FIFO 칩이 없는 OV7670 모듈을 Basys3에 직접 연결해 VGA로 영상을 보여준다. 카메라 없이 PC에서 UART로 영상을 보내 VGA에 띄우는 보조 경로도 있다.

## 구조
- README 폴더 트리 기준 모듈: `ov7670/` 아래 `camera_configuration.v`, `camera_read.v`, `OV7670_configuration_rom.v`, `OV7670_configuration.v`, `SCCB_configuration.v`, `top_camera.v`, 그 위에 `top_controller.v`, VGA는 `vga.v`·`h_sync.v`·`v_sync.v`. 별도로 `src/our-sccb/sccb_configuration.v`가 있다.
- UART 경로: `uart_rx.v` + `vga_over_uart_controller.v` + Python `video_over_uart.py`. `create_coe.py`, `downscale.m`이 있어 이미지를 COE(BRAM 초기화 파일)로 줄여 쓰는 흐름으로 보이나, 용도는 README에 설명되지 않음.
- 제약 파일 2개(`ov7670_constraints.xdc`, `vga_over_uart_constraints.xdc`)와 배선표 `ov7670_basys3_wiring.txt`가 있다고 README가 안내.

## 검증·재현성
- 빌드: README의 6단계(새 Vivado 프로젝트 → 소스 추가 → xdc 추가 → 비트스트림 → 배선 → 프로그래밍). Vivado 버전은 unverified: README에 없음.
- 시뮬레이션 테스트벤치 2개: `simulation/sccb/sccb_configuration_tb.v`, `simulation/vga/vga-tb.v` (README 트리 기준). 자체 점검형(PASS/FAIL)인지 unverified.
- 자원 사용(LUT/FF/BRAM)과 WNS: unverified: README에 없음. 프로젝트 보고서 PDF(`VL504_Project_Report.pdf`)에 있을 수 있으나 열람 권한 요청이 응답되지 않아 못 읽음.

## 한계·위험
- 카메라 영상의 버퍼링 방식(프레임 버퍼 유무, 해상도): unverified: README에 없고 소스·보고서 미열람. 내 판단: FIFO 없는 모듈이므로 BRAM 버퍼 또는 스트리밍 중 하나일 텐데 어느 쪽인지 단정할 수 없다.
- README의 UART 절차는 `vga_over_uart.py`라고 쓰지만 폴더 트리에는 `video_over_uart.py`가 있어 이름이 어긋난다.
- 저장소에 수업 팀원 사진과 이름이 있으나 이 카드에는 기록하지 않음(§6.5).
- 라이선스 BSD-3-Clause(저장소 LICENSE 링크 기준). 코드를 가져올 때는 고지 조건 확인 필요.

## 재사용 메모
- 내 판단: 카탈로그에서 Basys3에 직접 OV7670을 붙인 xdc·배선표 근거가 있는 유일한 후보. 카메라 캡처 → VGA 캡스톤의 1순위 참조로 쓸 수 있으나, 버퍼 구조는 보고서를 읽어 L3로 확정한 뒤에 따라야 한다.
- 내 판단: SCCB 설정 ROM 구조(`OV7670_configuration_rom.v`)와 SCCB 테스트벤치 조합은 자체 점검형 SCCB 송신기 패키지의 시나리오 근거가 된다.
