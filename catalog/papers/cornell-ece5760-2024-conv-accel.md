---
name: cornell-ece5760-2024-conv-accel
url: https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/s2024/yx623_jz2275_sl2874_NEW/
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: ARM(HPS-Cyclone V)
language: Verilog, C
tools: [Quartus]
bus: AXI(HPS-to-FPGA)
peripherals: [accelerator]
stage: T4
license: academic(Cornell ECE 5760)
stats: {stars: N/A, commits: N/A, last_update: 2024}
doc_language: en
verification: L2
checked_at: 2026-11-07
source_rev:
sources: [https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/s2024/yx623_jz2275_sl2874_NEW/yx623_jz2275_sl2874/yx623_jz2275_sl2874_report_logic_struc.html, https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/s2024/yx623_jz2275_sl2874_NEW/yx623_jz2275_sl2874/yx623_jz2275_sl2874_report_software_design.html, https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/s2024/yx623_jz2275_sl2874_NEW/yx623_jz2275_sl2874/yx623_jz2275_sl2874_report_overview_math.html]
unverified: 세부 모듈 목록·메모리맵·자원 사용·라이선스·source_rev — URL 목록과 제목만 확인, 본문 열람 불가(WebFetch PROVENANCE_REQUIRED 차단). 검색 결과에서 여러 하위 URL(logic_struc, software_design, overview_math) 확인.
---

## 요약

Cornell ECE 5760 (2024 봄) 최종 프로젝트. 파라미터화 가능한 합성곱(Convolution) 가속기 설계. DE1-SoC(Cyclone V + ARM HPS)에서 HPS가 AXI 버스로 FPGA 패브릭의 가속기를 제어하는 구조로 추정된다. 보고서가 하드웨어(logic_struc), 소프트웨어(software_design), 수학(overview_math)의 3개 HTML 페이지로 나뉘어 있어 HW/SW 분리 설계가 명확한 것으로 보인다.

## 구조
- 보드: DE1-SoC (Intel Cyclone V SoC, 85K LE, 4GB DDR3 HPS측)
- CPU: ARM Cortex-A9 HPS (소프트웨어 제어)
- 버스: HPS-to-FPGA AXI (추정, DE1-SoC 표준 연결)
- 가속기: 파라미터화 합성곱 (커널 크기·채널 수 조정 가능 추정)
- 소프트웨어: C (Linux on HPS, AXI 메모리 매핑 접근)
- unverified: 커널 크기 범위, 가중치 로드 방식, 채널 수, 메모리맵 주소 — 본문 미열람

## 검증·재현성
- 미확인: 시뮬레이션, CI, 자원 사용 — 본문 미열람
- 보고서 형태(HTML 3개 페이지)로 완성도 높은 설계 문서화 추정

## 한계·위험
- DE1-SoC 전용: Cyclone V IP, Quartus 프로젝트, DDR3(HPS측) 필요 → Basys3 직접 이식 불가
- WebFetch PROVENANCE_REQUIRED 차단으로 본문 열람 실패 (2026-11-07 기준), 재시도 필요
- 라이선스: 대학 과제물이므로 코드 반입 전 개인 확인 필요
- unverified: 소스코드 공개 여부, Quartus 프로젝트 첨부 여부

## 재사용 메모
- HW/SW 분리 패턴(FPGA 가속기 ↔ ARM HPS ↔ AXI 버스)은 MicroBlaze V + AXI4-Lite NPU IP 설계에 직접 참조 가능.
- 소프트웨어 제어 흐름(C에서 가중치 쓰기 → 추론 시작 → 결과 읽기)이 소프트웨어_설계 페이지에 있을 것으로 추정 — L3 열람 후 MicroBlaze V Vitis C 드라이버 흐름에 적용 가능.
- 개조: DE1-SoC HPS(ARM/Linux)를 MicroBlaze V(bare-metal Vitis)로 교체하고, Cyclone V AXI 연결을 AXI4-Lite 동결 맵 free_slots로 대체한다. BRAM 가중치 테이블은 Artix-7 36Kb BRAM으로 직접 이식 가능. DDR3은 MicroBlaze V 프로젝트에서 사용하지 않으므로 BRAM 용량 내로 가중치 크기를 제한한다.
- 내 판단: S5 비정형 출처 — Cornell 강의 프로젝트 페이지(GitHub 외). software_design 페이지가 AXI 소프트웨어 드라이버 패턴의 핵심 근거가 될 것.
