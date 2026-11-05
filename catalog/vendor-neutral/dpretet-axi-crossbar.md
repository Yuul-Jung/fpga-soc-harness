---
name: dpretet-axi-crossbar
url: https://github.com/dpretet/axi-crossbar
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(AXI4/AXI4-Lite 버스 IP)
language: SystemVerilog
tools: [Icarus Verilog 11, SVUT]
bus: AXI4, AXI4-Lite
peripherals: []
stage: T2
license: MIT
stats: {stars: n/a, commits: n/a, last_update: "n/a"}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://www.github.com/dpretet/axi-crossbar, https://www.github.com/dpretet/axi-crossbar/blob/main/doc/architecture.md, https://www.github.com/dpretet/axi-crossbar/blob/main/doc/io_parameter.md]
---

## 요약

Damien Pretet이 작성한 MxN AXI4/AXI4-Lite 크로스바. 위자드(TUI 또는 JSON)로 설정을 생성하고, 슬레이브 접근 라우팅 테이블·라운드 로빈 중재·CDC(클록 도메인 교차)를 지원한다. 주소 범위(시작+끝 주소)로 슬레이브를 디코딩하고, 미인가 접근에는 AXI DECERR를 반환한다.

## 구조

**주요 파라미터 (doc/io_parameter.md 기준):**
- 주소·데이터·ID 폭 (인터페이스 간 공유)
- M × N (마스터 수 × 슬레이브 수)
- 인터페이스별 버퍼 깊이와 페이로드 크기
- AXI 또는 AXI4-Lite 모드 선택
- 중재 우선순위(최대 4단계), 채널별 USER 신호
- 리셋 정책(동기/비동기), CDC 지원

**주소 디코딩 방식 (architecture.md 기준):**
- 요청(AR/AW) 채널: 슬레이브별 시작+끝 주소 범위로 디코딩
- 응답(B/R) 채널: 마스터 ID 필드의 ID 마스크로 역방향 라우팅
- 허용되지 않은 주소 범위 접근 → `DECERR`로 완료

**위자드:**
- JSON 설정: `./flow.sh wizard -c my_config.json`
- TUI: `./flow.sh wizard --tui`
- 출력: SystemVerilog RTL 자동 생성

**라우팅 테이블:**
- 슬레이브별 접근 가능한 마스터 집합을 테이블로 선언. 미등록 마스터의 슬레이브 접근 차단

**주소 중첩 검사:**
- 현재 미구현 — 향후 개발 계획으로만 명시. 현재는 정적 충돌 감지 없음
- 중첩 범위 설정 시 런타임 거동 미정의 (내 판단: 주소 계산 외부 도구로 사전 검증 필요)

## 검증·재현성

- 테스트벤치: 의사난수 드라이버+모니터, SVUT 프레임워크로 Icarus Verilog 11 실행
- CI: `.github/workflows/ci.yaml`로 GitHub Actions 자동화
- 검증 범위: 의사난수 트래픽의 정확성. CocoTB 테스트·주소 분포 통계는 향후 계획
- SystemVerilog 사용 → iverilog 최신 버전 필요, 이전 버전 호환 주의

## 한계·위험

- 주소 중첩 검사 미구현 — 외부에서 범위를 사전 계산해야 함
- SystemVerilog 전용 → Vivado 합성 가능하나 Verilog-only 플로에는 부적합
- Basys3 직접 XDC·예제 프로젝트 없음
- 별·커밋 수·최신 갱신일 미확인 (GitHub 직접 접근 불가)

## 재사용 메모

- 위자드가 JSON 설정으로 RTL을 자동 생성하는 방식은 MicroBlaze V 동결 맵을 JSON으로 관리하는 이 하네스의 패턴(`config/soc_address_map.json`)과 구조적으로 유사. 위자드 접근법을 참고해 동결 맵 → AXI4-Lite 크로스바 RTL 생성 도구를 별도 작성할 수 있음.
- 개조: SystemVerilog → Verilog-2001로 재작성 필요 (iverilog, yosys 호환). ID 마스크 역방향 라우팅 패턴은 MicroBlaze V의 M_AXI 마스터 ID가 1비트이므로 간략화 가능. 주소 범위(시작+끝)를 동결 맵 슬롯 기준으로 변환하는 변환 공식: `base = slot_base`, `limit = slot_base + slot_size - 1`.
