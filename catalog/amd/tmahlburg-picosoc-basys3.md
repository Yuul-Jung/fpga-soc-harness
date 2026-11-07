---
name: tmahlburg-picosoc-basys3
url: https://github.com/tmahlburg/picosoc-basys3
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: PicoRV32
language: Verilog
tools: [Vivado (토픽 태그만, 버전 미표기)]
bus: native(PicoSoC)
peripherals: [PicoSoC 기본 구성]
stage: T2
license: unknown
stats: {stars: 2, commits: 6}
doc_language: en
verification: L2
checked_at: 2026-11-02
rechecked_at: 2026-11-07
sources: [https://github.com/tmahlburg/picosoc-basys3]
unverified: 커밋 SHA(source_rev), 라이선스, 클럭·보레이트, 주변장치 구성, 빌드 흐름(Vivado/오픈소스), basys3.v 본문(raw 열람 권한 요청 미응답, blocked)
---

## 요약
PicoSoC 저장소의 보드 래퍼 방식을 따라 Basys3용으로 만든 래퍼 한 벌. Digilent 마스터 XDC에 의존하며, README는 래퍼를 PicoSoC 래퍼 디렉터리에 복사해 쓰라고 안내한다.

## 구조
- 파일 목록(저장소 페이지): Makefile, README.md, basys3.v, basys3_tb.v, sections.lds.
- 기본 브랜치 이름은 master, 커밋 6건. 래퍼 + 테스트벤치 + 링커 스크립트 구성이다.

## 검증·재현성
- 재열람(2026-11-02): 저장소 페이지의 커밋 6, 별 2, 포크 0, Makefile, Vivado 토픽, Digilent 마스터 XDC 의존이 카드와 일치. README는 짧아 클럭·주변장치·라이선스 정보가 없음을 재확인. basys3.v 본문은 이번에도 열람하지 않아 L2 유지(사유: 소스 본문 미열람).
- 테스트벤치 파일이 있으나 내용과 실행 결과는 열람하지 못했다. 빌드 방법·CI 없음(확인 못 함).

## 한계·위험
- 라이선스·클럭·주변장치 정보 모두 페이지에 없어 unverified. 코드 반입 불가(라이선스 확인 필요).
- 규모가 작고(커밋 6) 문서가 짧다. 이는 사실이며 품질 판단이 아니다.
- raw 파일 열람이 막혀 L2에 머문다.

## 재사용 메모
- 내 판단: 외부 플래시를 쓰는 PicoSoC 구성을 Basys3 QSPI 플래시에 맞추는 사례일 수 있으나 확인하지 못했다. [[symbiflow-arch-defs-picosoc-basys3]]의 ROM 방식과 대비해 읽을 만하다.
- 개조: sections.lds가 가리키는 "코드·데이터 영역 분리" 개념만 참고해 Vitis 링커 스크립트 설계 메모로 쓴다(파일 존재만 확인했고 내용은 unverified). 래퍼 RTL은 옮기지 못한다.
