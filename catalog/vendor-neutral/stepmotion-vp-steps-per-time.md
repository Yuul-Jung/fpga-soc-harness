---
name: stepmotion-vp-steps-per-time
url: https://pic.hallikainen.org/techref/microchip/io/dev/motor/stepmotion-vp.htm
source_type: article
vendor: neutral
board: [PIC18F (MCU, 10 MIPS)]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified: 페이지에 알고리즘 서술 중심, 소스 언어 미확인
tools: []
bus: none
peripherals: [actuator-servo]
stage: T2
license: unknown
stats: {last_update: 2011-05-26}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 원저자 표기 불일치(VegiPete 전재 / 메타데이터 author 다름). 2011년 자료
sources: [https://pic.hallikainen.org/techref/microchip/io/dev/motor/stepmotion-vp.htm]
---

## 요약
MCU에서 스테퍼의 실시간 가감속 프로파일을 덧셈과 비교만으로 만드는 "단위 시간당 스텝" 방식을 설명한 페이지. D. Austin의 스텝당 시간 방식의 역수 접근이라고 밝힌다. 곱셈·나눗셈·제곱근이 없어 FPGA 카운터 FSM에 그대로 대응된다.

## 구조
- 상태 4개: Idle, Accelerating, At_Max, Decelerating (페이지 서술).
- 고정 타이머 틱마다 속도를 소수 스텝 누산기에 더하고, 오버플로가 나면 스텝 펄스를 내고 스텝 카운트를 올린다.
- 가속 중 속도에 가속도를 더하고, 이동 거리의 절반이나 최대 속도에 닿으면 감속 시작점을 "전체 스텝 − 가속에 쓴 스텝"으로 계산한다. 중간점은 오른쪽 시프트 한 번으로 구한다.
- 고정소수점 형식(페이지 서술): step_count 32.0, step_frac 0.16, step_speed 16.8, step_accel 8.8.
- 보고 성능: PIC18F 10MIPS에서 스텝 펄스 60kHz.

## 검증·재현성
- 테스트 코드, 실측 응답: 없음 (unverified: 페이지에 없음).

## 한계·위험
- 개루프라 모터가 실제로 움직였는지 확인하지 못한다 (페이지 서술). 가속도가 부하 한계를 넘으면 스텝이 빠진다.
- 속도가 오르면 토크가 떨어져 최대 속도가 제한된다 (페이지 서술).
- 정수 근사는 정확도를 일부 포기한다 (페이지 서술).
- 라이선스 unknown. 코드는 가져오지 않는다. 원저자 표기가 일관되지 않아 출처 신뢰는 L3(본문 열람)이지만 귀속은 불확실.

## 재사용 메모
- 내 판단: 누산기 32비트 하나와 덧셈 두 개로 구성돼 Basys3의 LUT 수십 개 규모로 보인다(자원 수치는 소스에 없음, 추정). 100MHz 클럭을 `tick`으로 나눠 쓰면 TB로 가속/등속/감속 구간 스텝 수를 정확히 비교할 수 있다.
- 내 판단: 이동 스텝 수가 홀수일 때 중간점 처리와 짧은 이동(가속 도중 감속)이 경계 사례이므로 TB의 필수 시험 항목으로 삼는다.
- 개조: 해당 없음 (CPU 비종속). IP 표준 레지스터로 TARGET_STEPS, MAX_SPEED, ACCEL, STATUS(busy, done)를 제안하고 `free_slots` 한 칸에 배정한다.
