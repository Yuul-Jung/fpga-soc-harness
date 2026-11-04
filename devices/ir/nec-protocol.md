# NEC 적외선 리모컨 프로토콜

갱신: 2026-11-03 · 등급: L3(카드 근거 3건 열람의 교차 확인) · 출처: [bcit-elex7660-infrared-communication](../../catalog/papers/bcit-elex7660-infrared-communication.md), [opencores-nec-ir-decoder](../../catalog/vendor-neutral/opencores-nec-ir-decoder.md), [marph91-icestick-remote](../../catalog/lattice/marph91-icestick-remote.md)

## 프레임 (문서 수치)
| 구간 | 값 |
|---|---|
| 리더 | 9 ms 버스트 + 4.5 ms 공백 |
| 필드 | 주소 8비트, 주소 반전 8비트, 명령 8비트, 명령 반전 8비트 (LSB 먼저) |
| 비트 0 | 562.5 µs 버스트 + 562.5 µs 공백 |
| 비트 1 | 562.5 µs 버스트 + 1.6875 ms 공백 |
| 종료 | 562.5 µs 버스트 |
| 전체 | 약 67.5 ms (BCIT 보고서) |
| 반송파 | 38 kHz (BCIT 보고서) |

## 해독 FSM 주의
- IR 수신 모듈 출력은 보통 active-low(반송파가 있으면 Low)이며 두 동기화 단계가 필요하다(내 판단). jagumiel/irReceiver(Sony SIRC, DE1-SoC, MIT, 카드 없음)는 열람 결과 입력 동기화기가 없었다.
- 단계마다 시간 창을 두고, 벗어나면 프레임을 버려 대기로 복귀한다.
- 반전 바이트 일치 검사로 오류를 거른다.
- 반복 코드(버튼 유지)는 OpenCores 코어에서 미구현. 리더 뒤 짧은 프레임 형태라는 서술은 이 저장소 열람 자료에 없어 unverified.

## Basys3 (내 계산·판단)
- 100 MHz에서 562.5 µs = 56,250 클럭. 판정 경계는 비트 0·1 공백의 중간(약 1.1 ms)을 쓰면 여유가 있다.
- IR 수신 모듈은 3.3 V 급전형을 쓰면 레벨 변환이 필요 없다. 5 V형은 변환 필요.

## unverified
- 반복 코드 정확한 형식, 확장 NEC(16비트 주소) 해석: 열람 자료에 없음. Altium 문서는 리다이렉트로 열람하지 못함.
