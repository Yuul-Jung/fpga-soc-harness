---
name: zipcpu-pmodamp2-project-ladder
url: https://zipcpu.com/blog/2019/04/24/pl-pmodamp2.html
source_type: article
vendor: neutral
board: [iCE40-HX8K, iCE40-1K-GO]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [unverified: 글에 도구 이름 없음]
bus: none
peripherals: [audio-pwm, Pmod-AMP2-SSM2377, BRAM-sample-playback]
stage: T0-T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://zipcpu.com/blog/2019/04/24/pl-pmodamp2.html]
---

## 요약
Pmod AMP2(SSM2377, 모노 D급 증폭기)를 1비트 PWM으로 구동하는 12단계 프로젝트 사다리(2019-04-24 글). 핀 확인에서 시작해 단음, 사인 테이블, 볼륨, 음계, 4성 화음, BRAM 샘플 재생, CPU 구동 오디오로 올라간다.

## 구조
- 신호: 오디오 입력(PWM), 활성 저전위 셧다운, 이득 선택. 직렬 버스 없음. 로직 레벨은 3.3V로 보인다는 글의 측정 서술 기준.
- 단계: 0 자료 수집, 1 핀 매핑, 2 PWM 전압 시험, 3 스위치 임계값, 4 440 Hz 사각파, 5 사인 테이블 + 개선된 PWM, 6 볼륨, 7 스윕, 8 C 장조 음계, 9 BRAM의 곡 재생, 10 4성 화음, 11 샘플 오디오, 12 CPU 구동(폴링, 인터럽트, FIFO, DMA).
- 글이 언급한 주의: 목소리 합산 시 비트 성장과 클리핑, 시뮬레이션과 형식 검증을 먼저 할 것.

## 검증·재현성
- 완전한 프로젝트 저장소는 링크되지 않음. 인라인 코드 조각에 오타와 오류가 있어(글에서 확인) 그대로 합성되지 않는다.
- 작성자 본인의 보드와 클럭: unverified: 글에 명시 없음. 언급된 보드는 iCE40 HX8K/1K와 GO 보드.

## 한계·위험
- 라이선스 명시 없음 → unknown. 코드 복사 금지, 구조(사다리)만 참고.
- Basys3 핀 매핑은 별도 작업 필요(Pmod 헤더 JA~JC에 맞춰야 함).

## 재사용 메모
- 내 판단: 난이도 사다리(S7)로 바로 쓸 수 있는 구조. 1~9단계는 CPU 없이 FSM + BRAM으로 가능해 Basys3 T0~T2 캡스톤 패키지의 단계 분할 근거가 된다. 12단계는 우리 SoC의 MMIO 오디오 주변장치로 연결된다.
- 내 판단: AMP2는 PWM이라 I2S 클럭 문제(forum 카드 참고)를 피하는 가장 쉬운 오디오 출력 경로다.
