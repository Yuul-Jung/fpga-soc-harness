---
name: jie-2011-fpga-inverted-pendulum-robot
url: https://www.nepjol.info/index.php/JIE/article/view/5111
source_type: paper
vendor: amd
board: [미명시 ("FPGA"만 언급)]
fit_basys3: needs-port
cpu: MicroBlaze
language: unverified: 초록 페이지만 열람
tools: [unverified]
bus: unverified
peripherals: [sensor, actuator-servo, accelerator]
stage: T4
license: unknown
stats: {published: 2011}
doc_language: en
verification: L3
checked_at: 2026-11-02
변경: 2026-11-02 L2→L3. 본문 PDF(nepjol 5111/4247) 열람, 센서(MMA7260 가속도계·ENC-03R 자이로)와 구성 확인. 이전 값: L2(초록만)
sources: [https://www.nepjol.info/index.php/JIE/article/view/5111, https://nepjol.info/index.php/JIE/article/view/5111/4247]
unverified: 보드, IMU 부품명, 모터 드라이버, 고정소수점 여부, 자원 사용, 본문 열람
---

## 요약
Journal of the Institute of Engineering(트리부반대 풀찬크 캠퍼스) Vol.8 No.1-2(2011) pp.188-196. FPGA 안의 MicroBlaze에서 디지털 PID와 칼만 필터로 균형 유지 이동 역진자 로봇을 제어한 사례(초록 기준). DOI 10.3126/jie.v8i1-2.5111.

## 구조
- 저가 관성 센서(부품명 미기재) + 칼만 필터, 광학 엔코더를 칼만 필터 조정의 기준으로 사용(초록 서술).
- 엔코더 직교 디코딩과 PWM 생성은 FPGA 로직, 제어는 MicroBlaze.

## 검증·재현성
- 로봇이 스스로 균형을 잡는다고 초록이 서술. 정량 결과·자원 수치는 unverified.

## 본문 확인(2026-11-02)
- 센서: MMA7260 가속도계 + ENC-03R 자이로를 확장 칼만 필터로 융합, 엔코더를 기준 각도로 사용. 제어: 위치용·기울기용 증분형 PID 두 개를 합산해 PWM. VHDL로 PWM·직교 디코딩, MicroBlaze가 필터·PID.
- 결과: 평형 부근 약 ±0.05 rad 진동. 이득은 시행착오 조정. 고정소수점·자원 수치는 본문에 없음(unverified).

## 한계·위험
- 초록만 읽었다. 저작권은 저널 소유. 코드 공개 여부 unverified.

## 재사용 메모
- 내 판단: 균형 로봇 사다리(IMU + 엔코더 + PID)의 구성 요소가 "엔코더·PWM은 HDL, 필터·PID는 MicroBlaze"로 나뉜다는 것은 우리 프로젝트의 역할 분담(IP + C)과 일치한다. 세부는 본문 열람 후 L3로 올려야 한다.
- 개조: 엔코더 디코더·PWM을 IP 표준 래퍼(AXI4-Lite)로, 필터·PID는 MicroBlaze V C 코드로. 이 구성은 이미 MicroBlaze라 CPU 개조 부담이 작다.
