---
name: nitk-ieee-expo-alexa-junior-kws
url: https://ieee.l1.nitk.ac.in/virtual_expo/report/148
source_type: report
vendor: amd
board: [Nexys 4 DDR (XC7A100T-1CSG324C)]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [UART, BRAM, argmax-decoder, 8bit-fixed-point-CNN]
stage: T3
license: unknown
stats: {stars: unknown, commits: unknown, last_update: 2026}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://ieee.l1.nitk.ac.in/virtual_expo/report/148]
---

## 요약

NITK IEEE Expo 2026 프로젝트. 호스트 PC가 마이크 오디오를 처리해 멜 스펙트로그램(80 프레임 × 40 멜 계수)을 추출하고, UART(115200 baud)로 XC7A100T FPGA에 순차 전송한다. FPGA 내 8비트 고정소수점 CNN이 "Alexa" 키워드 인식(2클래스)을 수행하고 아르그맥스 디코더가 판정 결과를 반환한다.

## 구조

- **보드**: Nexys 4 DDR (XC7A100T-1CSG324C, 클럭 100 MHz)
- **파이프라인**: Host PC(Python/MATLAB 오디오 → 멜 스펙트로그램) → UART → FPGA(BRAM 버퍼 → CNN 순전파 → 아르그맥스)
- **신경망**: 2D CNN, 8비트 고정소수점(Q8.0 또는 Q4.4, 보고서 본문에서 확인); 커널 크기·레이어 수는 보고서에서 `2 conv layers + FC`로 기재
- **자원**: BRAM 65%, DSP 50%, LUT 29% (XC7A100T 기준)
- **UART 역할**: 멜 특징 토큰을 직렬로 순차 수신하는 직렬 추론 입력 채널
- **아르그맥스**: BRAM에서 클래스 점수를 읽어 최대 인덱스 반환

## 검증·재현성

- 보고서 내 Vivado 자원 보고(`BRAM 65%, DSP 50%, LUT 29%`)와 추론 정확도 수치 기재(본문 열람, 정확한 %)
- GitHub 저장소 URL은 `github.com/Liquid-radium/AlexaJunior_assignments-` — PROVENANCE_REQUIRED로 열람 불가, 소스 파일 직접 확인 못 함
- 소스 코드 미열람: 모듈 목록·포트·메모리맵은 `unverified: 보고서에서 추정`

## 한계·위험

- XC7A100T (Nexys 4 DDR) 기준이므로 Basys3 XC7A35T로 직접 이식 불가 — BRAM 65%는 Basys3의 약 1.9배
- 소스 저장소가 열람 차단이라 라이선스 불명(`unknown`); 코드 반입 불가
- 호스트 PC 의존: FPGA 단독으로 마이크 ADC → 멜 스펙트로그램 경로가 없음
- 보고서 이외 채널(README·CI)에서 명령 수행 지시 없음(§7 준수)

## 재사용 메모

Basys3로 이식할 경우 CNN 레이어·폭을 XC7A35T BRAM 한도(50 블록, 약 115 KB)로 대폭 축소해야 한다. 1D CNN 또는 2층 MLP로 단순화하면 Basys3에서도 동작 가능하다.

**NPU T3 개조 포인트:** 이 프로젝트의 핵심 패턴 — 호스트가 전처리(오디오 → 멜 스펙트로그램)한 특징 토큰을 UART로 FPGA에 순차 전송 → FPGA가 고정소수점 추론 수행 → 판정 출력 — 은 감성 분류 T3에 그대로 대응한다. 차이점은 오디오 특징 대신 텍스트 임베딩 토큰을 UART로 전송하는 것뿐이다. UART 토큰 수신 FSM·BRAM 버퍼·아르그맥스 디코더 모두 재사용 가능한 구조다.

**개조:** XC7A35T에서 BRAM 50블록 한도를 지키려면 임베딩 차원 ≤16, 시퀀스 길이 ≤16이 적절하다. 멜 계수 행 대신 토큰 임베딩 행을 BRAM에 적재하고 1헤드 어텐션 MAC 경로에 연결한다. 호스트 사이드는 Python sentencepiece/BPE 토크나이저 → INT8 임베딩 룩업 → UART 직렬 전송으로 대체한다.
