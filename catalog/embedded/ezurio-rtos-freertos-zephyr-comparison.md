---
name: ezurio-rtos-freertos-zephyr-comparison
url: https://www.ezurio.com/resources/blog/zephyr-rtos-vs-freertos-a-comprehensive-comparison-for-iot-and-embedded-systems
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.ezurio.com/resources/blog/zephyr-rtos-vs-freertos-a-comprehensive-comparison-for-iot-and-embedded-systems]
---

## 요약 (3줄 이내, 내 표현으로)

Ezurio의 FreeRTOS vs Zephyr 비교 글. FreeRTOS의 단순성과 낮은 메모리 요구, Zephyr의 광범위한 하드웨어 지원과 고급 스케줄링을 대조한다. 임베디드 IoT 프로젝트에서 RTOS 선택 기준을 제시한다.

## 구조

### FreeRTOS
- 태스크 모델: 동적 힙 할당 기반 태스크 생성 (정적 할당 옵션 있음)
- 최소 커널 크기: ROM 약 5~10 KB (기본 빌드 기준)
- 스케줄러: 고정 우선순위 선점형; 같은 우선순위 태스크는 타임슬라이싱 옵션
- 뮤텍스에 우선순위 역전 방지(priority inheritance) 지원
- 협력형 스케줄링 모드 설정 가능
- SMP(다중 코어) 지원: 없음(공식 커널 기준)
- 메모리 보호 없음; 모든 태스크가 단일 주소 공간 공유
- 틱리스(tickless) 절전 모드 지원
- 라이선스: MIT

### Zephyr
- 태스크(스레드) 모델: 정적 할당 선호, 컴파일 타임 리소스 정의
- 최소 커널 크기: 이론상 약 2 KB; 실제 애플리케이션 최소 약 8 KB (Hello World는 수십 KB)
- 최소 RAM: 최소화 설정 시 8 KB
- 스케줄러: 선점형 + 협력형 혼용; EDF(최단 마감 우선) 옵션; SMP 로드 밸런싱
- 스택 오버플로 감지 내장 (스택 가드, MPU 영역)
- 지원 보드: 600+ (공식 문서 기준)
- 라이선스: Apache 2.0

### 비교
| 항목 | FreeRTOS | Zephyr |
|---|---|---|
| 메모리 풋프린트 | Very Low | Low |
| SMP 지원 | 없음(공식 커널) | 있음 |
| 스택 보호 | 없음(기본) | 있음(MPU) |
| 하드웨어 지원 등급 | Excellent | 광범위 |
| 학습 난이도 | 낮음(최소 API) | 높음("80% 설정, 20% 코딩") |

## 검증·재현성

- WebFetch로 본문 직접 열람 (2026-11-04)
- 메모리 수치: ezurio 글 인용(FreeRTOS 5~10 KB ROM; Zephyr Hello World 수십 KB)
- AMD(Xilinx) 백서 인용: FreeRTOS는 "리소스 제약 환경에서 최적화 쉬움", Zephyr는 "다양한 드라이버·기능 out-of-the-box"
- 실측 벤치마크 없음; 각 수치는 문서 기재 추정치

## 한계·위험

- 기사 기준 스택 오버헤드 수치(TCB, 스택 크기)는 미기재
- FreeRTOS SMP: FreeRTOS-SMP(실험) 존재하나 본 글은 공식 커널 기준으로만 서술
- 태스크/스레드 생성 API 코드 예시 없음

## 재사용 메모

- 내 판단: FPGA SoC 맥락에서 FreeRTOS는 MicroBlaze V + AXI4-Lite 소프트코어 위에서 사용 가능. 태스크 모델과 스케줄러 개념은 HW FSM 설계 시 "소프트 타이머"와 비교할 근거가 됨.
- 개조: MCU 펌웨어 패턴이므로 RTL로 직접 옮기는 것은 없음. RTOS 기반 드라이버 구조(ISR + 큐 + 태스크)는 Basys3 위 MicroBlaze V 펌웨어 작성 시 참고 가능. CPU 비종속 부분 없음.
- Basys3 적합성: needs-port (SoC로 옮길 수 있는 것은 "소프트웨어 구조 패턴"뿐, FPGA RTL과 직접 대응 없음)
