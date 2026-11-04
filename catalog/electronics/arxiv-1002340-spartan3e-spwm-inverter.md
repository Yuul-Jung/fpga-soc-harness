---
name: arxiv-1002340-spartan3e-spwm-inverter
url: https://arxiv.org/abs/1002.3340
source_type: paper
vendor: amd
board: [Spartan-3E Starter Kit]
fit_basys3: needs-port
cpu: none(전력전자·SPWM FSM)
language: VHDL
tools: [Xilinx ISE 9.2i]
bus: none
peripherals: [spwm, inverter-ac]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://arxiv.org/pdf/1002.3340]
---

## 요약

Spartan-3E Starter Kit + ISE 9.2i 기반 태양광 가정용 인버터용 SPWM 발생기 논문. 220V 300VA 50Hz 출력을 목표로 중간 탭 방식(center-tap, 양·음군 별도) 인버터를 VHDL로 구현한다. ISE 시뮬레이션과 실물 하드웨어 모두 확인했으나 게이트 격리·데드타임은 명시하지 않는다.

## 구조

- 토폴로지: 중간 탭 인버터(12-0-12V). 양군·음군 각 1개씩 2N3055 트랜지스터 5개씩 사용 (풀브리지 아님)
- VHDL FSM: Pulse Count N=3 고정 (N 값별 타이밍 테이블 제공, Appendix에 하드코딩)
- 출력 목표: 220V, 300VA, 50Hz. 클럭 주파수·캐리어 주파수 미명시
- 변조 지수 K: 0–1 범위 정의, 실제 동작 값 미기록
- 검증: ISE 시뮬레이션(오실로스코프 파형 캡처), MATLAB THD 분석(N에 따른 THD 그래프), 효율-부하 플롯(하드웨어)

## 검증·재현성

- 논문 PDF 직접 열람(L3). 타이밍 표(Table 6, N=3), 회로 설명, Appendix VHDL 코드 발췌 포함
- Spartan-3E 보드에서 오실로스코프로 MSS·PCS 파형 캡처 확인
- THD "3–5% 미만" 주장이나 수치 본문에 없음(그래프만), 효율 "거의 일정" 수치 미명시

## 한계·위험

- 게이트 격리(포토커플러·게이트 드라이버 IC) 미언급 — 실제 고전압 구동 회로는 별도 설계 필요
- 데드타임 미구현 — 슛스루 방지 로직 없음
- 명세 불일치: 배터리 용량 150Ah(4×40Ah) vs 2×80Ah, 계통 허용오차 ±10%(표2) vs ±20%(표5)
- Appendix VHDL은 N=3 고정 코드 — N 가변 설계로 개선 필요
- 2N3055 BJT 사용 — 현대 MOSFET·IGBT 설계와 다름

## 재사용 메모

풀브리지가 아닌 중간 탭 방식이므로 구조 직접 이식 불가. SPWM FSM 로직(반송파·기준파 비교, N 펄스 생성)과 THD–N 관계 분석 방법론을 참고한다.
개조: MicroBlaze V SoC 적용 시 N을 AXI4-Lite 레지스터(PULSE_COUNT)로 소프트웨어에서 가변 조절 가능. 단, 현대 풀브리지 SPWM은 삼각파-기준파 비교 방식(이 논문의 FSM보다 단순)을 쓰므로 RTL 직접 차용보다 아이디어 출발점으로 쓴다. 내 판단: 교육·역사적 참조가치 있음. Basys3로 옮길 때 클럭 적합성은 확인 필요.
라이선스 확인 필요: license unknown이므로 Appendix VHDL 코드를 저장소에 반입하지 않는다. FSM 설계 개념만 참조한다.
