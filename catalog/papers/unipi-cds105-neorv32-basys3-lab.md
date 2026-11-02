---
name: unipi-cds105-neorv32-basys3-lab
url: https://thales.cs.unipi.gr/modules/document/file.php/CDS105/Lab/RISC-V/_236906629-NEORV32%20RISC-V%20on%20Digilent%20Basys3-070225-112056.pdf
source_type: course
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: NEORV32
language: VHDL
tools: [Vivado 2016.4 (VM 환경), NEORV32 v1.11.0]
bus: native
peripherals: [GPIO-LED, comm-uart]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://thales.cs.unipi.gr/modules/document/file.php/CDS105/Lab/RISC-V/_236906629-NEORV32%20RISC-V%20on%20Digilent%20Basys3-070225-112056.pdf]
unverified: 라이선스, 자원 사용량, 메모리 크기, 활성화한 주변장치 전체 목록(문서에 GPIO와 UART0만 언급), 소스 저장소 SHA
---

## 요약
그리스 피레우스대학 강의(CDS105)의 실습 문서. NEORV32 부트로더 테스트 구성을 Basys3에 올려 LED 출력과 UART 업로드까지 해 보는 순서를 적었다.

## 구조
- 클럭: 100MHz 보드 발진기(W5)를 `clk_i`에 연결, 10ns 제약.
- 리셋 `rstn_i`는 스위치 SW15(R2)에 연결, 능동 low 비동기 전역 리셋이라 스위치를 ON으로 둬야 동작.
- GPIO 출력 8개를 LED에, UART0는 보드 USB-UART 핀(수신 B18, 송신 A18)에 연결.
- 구성 설정: 3.3V I/O, 쿼드 SPI 플래시 모드, 비트스트림 압축, 구성 속도 33MHz.
- 최상위 모듈은 부트로더 테스트 구성. 직렬 터미널에서 `u`로 실행 파일 업로드, `e`로 실행.

## 검증·재현성
- 문서 절차만 읽었고 실행하지 않았다(§7). 자원·타이밍 수치는 없음.

## 한계·위험
- 문서에 UART 수신 제약의 오타(`get_ports` 중복)가 있다고 확인됨. 따라 하면 수정 필요.
- Vivado 2016.4 기준이라 프로젝트 기준(2024.2 이상)과 다름. 최신 도구에서는 xdc 문법·IP 차이 확인 필요.

## 재사용 메모
- 내 판단: 리셋을 스위치에 두고 UART 부트로더로 프로그램을 올리는 흐름은, 소프트코어 교체 트랙에서 "보드 배선·제약" 부분을 가장 짧게 점검하는 예시다.
- 개조: Basys3 핀 배치(W5 클럭, SW15 리셋, B18/A18 UART)는 CPU와 무관하므로 MicroBlaze V 쪽 xdc에서 같은 핀 근거로 재확인할 수 있다. 부트로더 업로드 방식 자체는 NEORV32 전용이라 옮기지 못한다(MicroBlaze V는 Vitis 다운로드/QSPI).
