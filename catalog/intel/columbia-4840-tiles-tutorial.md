---
name: columbia-4840-tiles-tutorial
url: https://www.cs.columbia.edu/~sedwards/classes/2025/4840-spring/tiles.pdf
source_type: course
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: HPS ARM (Avalon-MM 슬레이브 주변장치)
language: SystemVerilog
tools: [Quartus]
bus: Avalon-MM
peripherals: [video-vga]
stage: T3
license: unknown (강의 자료, 재배포 조건 미표기)
stats: {published: 2025}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.cs.columbia.edu/~sedwards/classes/2025/4840-spring/tiles.pdf]
unverified: 소스 코드 본문(자료에 코드가 어디까지 실렸는지), 타이밍 제약·WNS, 스프라이트(자료에서 다루지 않음)
---

## 요약
Columbia 임베디드 시스템 강의의 타일 기반 VGA 그래픽 튜토리얼. 화소마다 색을 저장하는 대신 타일 번호 격자(tilemap), 8x8 화소 패턴(tileset), 작은 팔레트를 조회해 화소를 만든다.
DE1-SoC의 HPS가 Avalon-MM으로 이 주변장치를 쓰는 구성(자료 기준).

## 구조
- 메모리 비교(자료 수치): 640x480 24bpp 약 900 KB, 8bpp 색인 + 팔레트 약 300 KB, 1bpp 약 37.5 KB, 텍스트 모드(80x30, 글리프 256개) 격자 약 2.34 KB + 글꼴 4 KB.
- 이 설계: tilemap 8192x8비트(80x60 격자를 128x64로 패딩), tileset 16Kx4비트(타일 256개), 팔레트 16x24비트.
- Avalon-MM 슬레이브, 0x0000–0x7FFF: 0000–1FFF tilemap, 2000–203F 팔레트(색당 4바이트, 4번째 바이트 쓰기가 반영 트리거, 24비트 스테이징 레지스터), 4000–7FFF tileset.
- 화소는 가로·세로 카운터 순서로 생성하고 파이프라인 레지스터로 타일·블랭크·동기 신호를 맞춘다.

## 검증·재현성
- Quartus 보고: 블록 메모리 131,456 비트, PLL 1개, ALM 406개(자료 수치). U-Boot 시험은 기준 주소 0xFF200000 사용.
- Basys3 환산(내 계산): 131,456 비트는 약 16 KB. Basys3 BRAM 용량 대비 작아 보이나 Basys3 BRAM 총량은 이 자료 밖 수치라 확정하지 않음, 공식 매뉴얼로 대조 필요.

## 한계·위험
- 라이선스 미표기. 코드를 가져오지 않고 메모리맵과 구조만 사양으로 쓴다.
- 스프라이트는 다루지 않는다(자료 서술). Avalon-MM, Quartus, HPS 의존이라 그대로 이식은 불가.

## 재사용 메모
- 내 판단: no-dram 제약(S4) 아래서 가장 직접적인 해법이다. 80x60 tilemap + 256 타일 + 16색 팔레트는 BRAM 몇 개 수준으로 추정된다(내 추정).
- 개조: Avalon-MM 레지스터 배치(tilemap/팔레트/tileset 영역 3개, 팔레트 4바이트 쓰기 트리거)를 AXI4-Lite 슬레이브로 옮기고, 64KB 슬롯 하나 안에 세 영역을 배치하는 안을 제안할 수 있다(내 판단). HPS 종속 부분은 MicroBlaze V가 대신하므로 옮길 필요 없음.
