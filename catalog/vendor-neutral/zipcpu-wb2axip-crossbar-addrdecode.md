---
name: zipcpu-wb2axip-crossbar-addrdecode
url: https://zipcpu.com/blog/2019/07/17/crossbar.html
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(AXI4-Lite/AXI4/Wishbone 버스 IP)
language: Verilog
tools: [SymbiYosys (formal verification)]
bus: AXI4-Lite, AXI4, Wishbone
peripherals: []
stage: T2
license: unknown
stats: {stars: n/a, commits: n/a, last_update: "2019-07-17 (블로그 게시일)"}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://zipcpu.com/blog/2019/07/17/crossbar.html, https://github.com/ZipCPU/wb2axip/blob/master/rtl/addrdecode.v, https://github.com/ZipCPU/wb2axip/blob/master/rtl/axilxbar.v, https://github.com/ZipCPU/wb2axip/blob/master/rtl/axixbar.v]
unverified: GitHub 저장소 직접 열람 불가(PROVENANCE_REQUIRED), 라이선스·별 수·최신 커밋 미확인
---

## 요약

ZipCPU(Dan Gisselquist) 블로그의 크로스바 설계 기사. `wb2axip` 저장소의 Wishbone/AXI-Lite/AXI 크로스바 셋이 공유하는 주소 디코더(`addrdecode.v`)와 중재 설계 원칙을 상세히 설명한다. `SLAVE_ADDR`/`SLAVE_MASK` 파라미터 기반 디코딩과 형식 검증(SymbiYosys)을 사용한다.

## 구조 (블로그 본문 직접 열람 기준)

**공유 주소 디코더 `addrdecode.v`:**
- 파라미터: `SLAVE_ADDR`, `SLAVE_MASK` — 슬레이브마다 `AW` 비트 항목 하나
- 비교 규칙: `SLAVE_MASK`가 1인 비트에 대해서만 `SLAVE_ADDR`와 대조 (AND-마스크 방식)
- `request[M]`: 요청 주소가 슬레이브 M의 조건을 만족하면 1
- 미매핑 주소: `NS`번째 "에러 슬레이브"로 라우팅 → 버스 에러 반환

**중재 규칙 (기사에서 명명한 5가지):**
- 규칙 2: 한 슬레이브에는 마스터 하나만. `$onehot0(grant[iN])` 어서션으로 형식 검증
- 규칙 3: 한 마스터에는 슬레이브 하나만. `sgrant`/`sindex`로 관리
- 규칙 4: 미매핑 주소 → "에러 슬레이브"(NS번째). 복수 마스터가 동시 접근 가능
- 규칙 5: 미완료 트랜잭션이 있는 동안은 grant 변경 금지. 카운터+`mempty`/`mfull` 플래그로 관리, 카운터 오버플로 → 스톨
- AXI는 읽기/쓰기 채널 분리: `wgrant`와 `rgrant`를 별도로 관리

**우선순위 중재:**
- 번호 낮은 마스터 우선. `requested[N][M]`: 더 높은 우선순위 마스터가 같은 슬레이브 요청 여부
- `stay_on_channel`: 같은 슬레이브 연속 요청 또는 미완료 응답이 있으면 현재 연결 유지
- `OPT_LINGER`: 연결 유지 클럭 수 설정 옵션
- `OPT_TIMEOUT` / `OPT_STARVATION_TIMEOUT`: Wishbone 크로스바용 시간 초과 옵션

**RTL 구조:**
- `for` + `genvar`로 M×N 파라미터화
- `ARBITRATE_REQUESTS` generate 블록에서 마스터별 중재
- 슬레이브 출력: `sindex`로 선택. 마스터 응답: `mindex`로 복사
- 스키드 버퍼(`skidbuffer`) 별도 모듈로 분리, 임계 경로 클럭 추가 옵션

## 검증·재현성

- 모든 버스 인터페이스에 SymbiYosys 형식 검증 속성 파일 첨부
- `$onehot0` 어서션으로 grant 무결성 증명
- Basys3 직접 예제 없음. 기사에서 "과거 비디오 프로젝트 보드"로만 언급
- 라이선스 미확인 (GitHub 직접 열람 불가)

## 한계·위험

- 중재 로직이 한 클럭에 계산 → M×N 규모 증가 시 타이밍 악화. 기사는 스키드 버퍼로 해결 가능하다고 언급
- `SLAVE_ADDR`/`SLAVE_MASK` AND 방식은 AND-마스크가 아닌 임의 범위를 표현 불가 (2의 거듭제곱 정렬 범위만)
- 라이선스 미확인 → 코드 사용 전 확인 필요 (일반적으로 GPL로 알려져 있으나 미검증)

## 재사용 메모

- `addrdecode.v`의 `SLAVE_ADDR`/`SLAVE_MASK` 파라미터 패턴은 동결 맵(`config/soc_address_map.json`)에서 직접 추출 가능. `base_addr`를 `SLAVE_ADDR`로, `2^ceil(log2(size)) - 1`의 보수를 `SLAVE_MASK`로 변환하면 동결 맵 → AXI 주소 디코더 파라미터 자동 생성 도구를 작성할 수 있음.
- 개조: 에러 슬레이브(NS+1번째) 패턴은 MicroBlaze V의 미인가 주소 접근 처리에 직접 적용 가능. `wgrant`/`rgrant` 분리 방식은 AXI4-Lite에서는 단순화 가능(W 채널과 AW가 한 번에 처리됨). `OPT_LINGER`는 단일 마스터(MicroBlaze V) 환경에서 불필요.
