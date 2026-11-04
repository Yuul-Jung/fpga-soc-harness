---
name: algofoogle-raybox-zero
url: https://github.com/algofoogle/raybox-zero
source_type: repo
vendor: neutral
board: [DE0-Nano, Tiny Tapeout]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Verilator, SDL2]
bus: SPI (POV 설정)
peripherals: [video-vga]
stage: T4
license: unknown (README 요약에 표기 없음, 저장소 LICENSE 미열람)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/algofoogle/raybox-zero, https://tinytapeout.com/chips/tt04/033, https://github.com/algofoogle/tt04-raybox-zero]
unverified: source_rev(커밋 SHA 미확인), 라이선스, FPGA 자원(LUT/BRAM)과 타이밍, Basys3 핀 매핑, CI 구성(Actions 탭 존재만 확인)
---

## 요약
프레임 버퍼 없이 VGA 신호를 실시간으로 만드는 Wolf3D풍 레이캐스터. 호스트가 SPI로 시점(POV)을 바꾸고, 하드웨어가 한 줄씩 광선을 추적해 화소를 낸다(Tiny Tapeout 페이지 서술).
같은 설계를 Tiny Tapeout ASIC 여러 회차와 DE0-Nano 래퍼로 구현했다.

## 구조
- VGA 640x480 약 60 Hz, 25 MHz 클럭, RGB222 + HSYNC/VSYNC, 블랭크 신호를 선택적 인터럽트로 제공(TT04 페이지).
- 입력: SPI(sclk, mosi, ss_n)로 POV, 두 번째 SPI로 천장·바닥 색 설정. 데모 이동 핀과 리셋 시 기본 POV 적재.
- 모듈(README 서술): 행 렌더러, VGA RGB mux, LZC(Q10.10 고정소수점), 역수 근사, 추적 FSM, 맵(16x16 하드코딩), 시점 벡터 + SPI 주변장치 제어기, 공유 곱셈기, 디버그 오버레이. 선택: 텍스처 SPI RAM 마스터.
- 줄 단위 추적(row-tracing)이면 프레임 버퍼 대신 줄당 약 9비트 수준 상태로 충분하다고 README가 논의. 단 가로/세로 방향이 어긋나 화면을 돌려야 하는 단점도 README가 적는다.
- TT04 면적: 4x2 타일 약 0.16 mm²(130 nm, 밀도 약 48%).

## 검증·재현성
- Verilator + SDL2 시뮬레이터(Linux Ubuntu 20.04 / Windows MSYS2 절차 기술), make 타깃. sim/, test/ 디렉터리 존재. 내용은 열람하지 않음.
- 저장소의 빌드 명령은 실행하지 않았다(§7).

## 한계·위험
- 8bitworkshop 시뮬레이터 대상은 현재 오류라고 README가 서술.
- 라이선스 확인 필요 → 코드 가져오기 금지, 구조 사양만 사용.
- Basys3 관련 서술은 없음(검색에서도 못 찾음).

## 재사용 메모
- 내 판단: 프레임 버퍼 대신 "줄마다 계산"하는 접근(S4)의 극단 사례다. 곱셈기 공유와 Q10.10 고정소수점은 Artix-7 DSP 슬라이스로 옮기기 좋아 보이나 자원은 미확인.
- 개조: CPU 없는 설계라 CPU 종속 부분이 없다. POV 설정용 SPI를 AXI4-Lite 레지스터(x, y, 방향 벡터, 색 2개)로 바꾸고 MicroBlaze V가 쓰는 구성으로 옮길 수 있다(내 판단). 레이캐스터 자체를 만들기보다 같은 레지스터 방식을 더 단순한 줄 렌더러(수평 막대, 파형)에 적용하는 편이 현실적이다.
