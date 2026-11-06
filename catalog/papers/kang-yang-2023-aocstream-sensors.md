---
name: kang-yang-2023-aocstream-sensors
url: https://www.mdpi.com/1424-8220/23/19/8104
source_type: paper
vendor: neutral
board: [XCKU5P, XC7K325T]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Vivado]
bus: none
peripherals: []
stage: T4
license: open-access
stats: {stars: null, commits: null, last_update: 2023-10-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev:
sources: [https://www.mdpi.com/1424-8220/23/19/8104]
---

## 요약

외부 메모리 없이 라인 버퍼만으로 임의 크기 CNN을 스트리밍 추론하는 AoCStream 아키텍처. 각 레이어 출력이 다음 레이어 라인 버퍼에 직결되어 프레임 버퍼 없이 90~260 FPS 처리 가능. 저자: Hyeong-Ju Kang, Byung-Do Yang (Sensors 2023, 23(19), 8104).

## 구조

핵심 원리: 각 CNN 레이어의 출력 픽셀을 BRAM 라인 버퍼(K-1 라인)에 임시 저장 → 다음 레이어 슬라이딩 윈도우로 직접 공급. 레이어 간 완전한 출력 맵을 저장하지 않으므로 외부 DRAM 불필요.

BRAM 사용: 레이어당 K-1 라인 × 채널 수 × 비트 폭. 채널 수가 늘수록 BRAM 증가.

검증 보드: XCKU5P(UltraScale+) 메인, 비교 대상으로 XC7K325T(Kintex-7) 사용.

성능(논문 Table):
- 90~260 FPS (레이어 구성에 따라 다름)
- 추론 지연: 약 1.5 프레임 기간 (파이프라인 채움 시간)
- XC7K325T에서 87.5% 가중치 프루닝 필요 (BRAM 한계)

## 검증·재현성

MDPI Sensors 오픈 액세스 논문으로 본문 직접 열람. 저자 측 GitHub 소스 코드 링크 없음(논문 내 미제공). 아키텍처와 BRAM 소요량 계산식은 명시. 실제 구현 코드 미공개.

unverified: GitHub 소스 없음, Basys3에서 직접 테스트 불가.

## 한계·위험

- XC7K325T에서 87.5% 프루닝 없이는 BRAM 초과 — Basys3 XC7A35T(225 KB BRAM)는 더 적음
- 채널 수가 커지면 레이어당 K-1 라인 버퍼 BRAM이 급증 — 소형 모델(채널≤8) 한정
- 오픈소스 구현 미제공 — 아키텍처 참고용

## 재사용 메모

"외부 DRAM 없이 임의 CNN 스트리밍"의 아키텍처 근거 논문으로 가치가 크다. Basys3의 no-DRAM 제약을 역이용하는 S4 전략의 이론적 근거를 제공한다.

개조: MicroBlaze V SoC로 — 이 아키텍처의 핵심은 레이어 간 라인 버퍼(BRAM)이다. 각 conv 레이어를 AXI4-Stream 소비자/생산자로 감싸고 MicroBlaze V가 AXI4-Lite 슬레이브로 채널 수·커널 크기·스트라이드를 설정하면 소프트웨어에서 네트워크를 재구성할 수 있다. Basys3 적합성: 채널 수를 8 이하로 제한하면 XC7A35T BRAM 225 KB 내에서 2레이어 모델(예: 1→8→16 채널) 구현 가능(내 판단, 계산 근거: 3×3 커널, 28×28 입력 시 레이어 1 라인 버퍼 2×28×8b=56B, 레이어 2: 2×14×16×8b=448B, 가중치 포함해도 50 KB 미만 추정). 옮기지 못하는 부분: 소스 코드 미공개 — 아키텍처만 참고하고 RTL은 자체 작성 필요.
