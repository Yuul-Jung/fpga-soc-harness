---
name: zipcpu-llvga-video-timing
url: https://zipcpu.com/blog/2018/11/29/llvga.html
source_type: article
vendor: neutral
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Verilator, SymbiYosys]
bus: none
peripherals: [video-vga]
stage: T1
license: unknown (글에 라이선스 표기 없음, 코드는 vgasim 저장소 별도 확인 필요)
stats: {published: 2018-11-29}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://zipcpu.com/blog/2018/11/29/llvga.html]
unverified: vgasim 저장소 라이선스와 SHA(저장소 미열람), 25 MHz 외 모드별 자원 수치(글에 없음), 글에 언급된 Basys3 프로젝트의 공개 위치
---

## 요약
VGA 비디오 컨트롤러의 타이밍부는 가로·세로 카운터 한 쌍이라는 점을 설명한 글. 모드를 값 8개(가로 4, 세로 4)로 정하고, Verilator 기반 VGA 시뮬레이터로 화면을 PC에서 확인하는 흐름을 소개한다(글 기준).
핵심 관점은 Basys3에 외부 RAM이 없어 640x480 프레임 버퍼(글 서술로 약 307 kB)를 둘 수 없다는 제약과 그 우회다.

## 구조
- 카운터: hpos가 한 줄 끝에서 리셋되고 hsync, 새 줄 신호, 가로 유효 구간을 만든다. vpos는 hpos가 가로 포치 값에 닿을 때 증가해 vsync를 만든다. 동기 신호는 active low(글 서술).
- 출력: 유효 화소 표시(o_rd), 프레임 끝 펄스(o_newframe). 모드 값은 폭 < 포치 < 동기 < 전체 순으로 증가해야 한다.
- 픽셀 클럭은 시스템 클럭과 별도(i_pixclk). 이전 Basys3 프로젝트는 25 MHz 픽셀 클럭, 12비트 색을 목표로 했다고 서술.
- 프레임 버퍼 회피 방법: 이전 설계는 플래시에 런렝스 부호화한 이미지를 두고 화소당 4비트 + 색 조회표로 줄였다. 시험 무늬 생성기는 화면 값을 계산해 내므로 버퍼가 필요 없다. 데모에는 FIFO 기반 프레임 버퍼 경로(wbvgaframe.v)도 있다.

## 검증·재현성
- 시뮬레이터: github.com/ZipCPU/vgasim, Verilator와 gtkmm-3.0 필요. 형식 검증(SymbiYosys) 자료를 링크한다.
- 형식 검증 가정: 최소 폭·높이가 16 화소 초과, 모드가 안정된 동안만 카운터 성질 검사.

## 한계·위험
- 글에 라이선스가 없어 코드 가져오기는 "라이선스 확인 필요". 저장소를 열람하지 않았다.
- 시뮬레이터는 채널당 8비트까지 받고 초과분은 상위 8비트만 쓴다(글 서술). Windows는 Cygwin 가능성만 언급, 시험하지 않았다고 서술.

## 재사용 메모
- 내 판단: VGA 타이밍을 "카운터 + 모드 8값 레지스터"로 정의하는 방식은 AXI4-Lite 레지스터(H/V 모드 값, 프레임 끝 인터럽트 1비트)로 그대로 옮기기 좋다. 프레임 버퍼 없는 설계(S4)의 출발점으로 타이밍부를 자체 RTL로 새로 쓰면 된다.
- 개조: 이 자료는 CPU와 무관한 순수 RTL 설계 관점이다. MicroBlaze V 기준에서는 타이밍 모드 값을 레지스터화하고 o_newframe를 INTC 빈 입력에 배정하는 안을 제안할 수 있다(내 판단, 슬롯 배정은 사용자 동결 필요).
