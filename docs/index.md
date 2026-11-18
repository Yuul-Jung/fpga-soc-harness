<style>
/* 자료 탐색 홈 — rule_md 일반 기술문서 프로파일 */
.hub-hero{padding:1.5rem 1.7rem;background:linear-gradient(110deg,#15171c,#33305d);color:#fff;border-radius:12px;margin-bottom:1.2rem}
.hub-hero h1{color:#fff!important;margin:.2rem 0 .5rem!important}.hub-hero p{color:#e5e4f0;margin:0}
.hub-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.8rem;margin:1rem 0}
.hub-card{display:block;border:1px solid var(--md-default-fg-color--lightest,#ddd);border-radius:9px;padding:1rem 1.1rem;text-decoration:none!important;background:var(--md-code-bg-color,#fff)}
.hub-card strong{display:block;font-size:1rem;margin-bottom:.3rem}.hub-card span{display:block;font-size:.82rem;color:var(--md-default-fg-color--light,#555)}
.hub-card:hover{border-color:#4635b1;box-shadow:0 3px 12px #4635b11a}
.hub-pills{display:flex;gap:.45rem;flex-wrap:wrap;margin:1rem 0}.hub-pills a{border:1px solid #bbb;border-radius:6px;padding:.25rem .65rem;text-decoration:none;font-size:.83rem}
@media(max-width:650px){.hub-grid{grid-template-columns:1fr}.hub-hero{padding:1.1rem}}
</style>

<div class="hub-hero">
  <h1>FPGA·SoC 기술 지식 허브</h1>
  <p>수집 자료에서 캡스톤까지 — 기술 분야·학습 단계·주변장치별로 찾아보는 설계 자료실</p>
</div>

<div class="hub-pills">
<a href="#캡스톤-실습">캡스톤 실습</a>
<a href="#기술-분야별-자료">기술 분야</a>
<a href="#학습-기술-트리">기술 트리</a>
<a href="#주변장치-자료">주변장치</a>
<a href="#아이디어와-검증">아이디어·검증</a>
</div>

## 00. 빠른 시작

<div class="hub-grid">
<a class="hub-card" href="hub.html#capstones"><strong>캡스톤 패키지 보기</strong><span>설계 문서 · 계통도 · RTL 소스 · 검증 상태</span></a>
<a class="hub-card" href="catalog/index.html"><strong>수집 카탈로그</strong><span>원천 기술 자료와 검증 등급을 확인</span></a>
<a class="hub-card" href="soc-map/tech-tree.html"><strong>학습 기술 트리</strong><span>T0~T5 단계별 학습 및 과제 탐색</span></a>
<a class="hub-card" href="inbox/ideas.html"><strong>아이디어 목록</strong><span>수집된 아이디어와 진행 상태</span></a>
</div>

## 01. 캡스톤 실습

**[캡스톤 전체 목록 · 문서 · 계통도 · 소스 다운로드](hub.html#capstones)**

- [기술 단계별 캡스톤 목록](hub.html#tree)
- [주제별 기술 종합 자료](hub.html#atlas)
- [캡스톤 저장소 원본](https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/capstones)

캡스톤별 린트·시뮬레이션·합성·보드 검증 표시는 실제 실행 증거와 구분해서 확인합니다.

## 02. 기술 분야별 자료

<div class="hub-grid">
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/amd"><strong>AMD / Xilinx</strong><span>Basys3 · FPGA · MicroBlaze · AXI · 가속기</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/intel"><strong>Intel FPGA</strong><span>FPGA 기반 주변장치·신호처리·설계 사례</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/lattice"><strong>Lattice FPGA</strong><span>소형 FPGA · 오픈소스 설계 사례</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/vendor-neutral"><strong>범용 RTL</strong><span>보드 독립형 Verilog · IP · 설계 기법</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/papers"><strong>논문·연구</strong><span>FPGA · SoC · NPU · 최신 기술 사례</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/embedded"><strong>임베디드 공통</strong><span>MCU · 센서 · 통신 · 제어 시스템</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/arduino"><strong>Arduino</strong><span>범용 센서·액추에이터 응용</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/stm32"><strong>STM32</strong><span>타이머 · UART · ADC · 인터럽트</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/esp32"><strong>ESP32</strong><span>무선 통신 · IoT · 임베디드 제어</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/rpi"><strong>Raspberry Pi</strong><span>Linux · GPIO · 엣지 호스트</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/catalog/electronics"><strong>전자회로</strong><span>회로 · 부품 · 인터페이스 · 전기적 제약</span></a>
</div>

[카탈로그 전체 색인](catalog/index.html)

## 03. 학습 기술 트리

**[T0~T5 기술 트리 전체 보기](soc-map/tech-tree.html)**

| 단계 | 학습 주제 |
|---|---|
| T0 | ISA(명령어 집합 구조) · 개발 도구 |
| T1 | 단일 사이클 코어 · MMIO(메모리 맵 입출력) |
| T2 | SoC 주변장치 연결 · 인터페이스 |
| T3 | 프레임워크 기반 SoC |
| T4 | NPU(신경망 처리 장치) · 영상·신호처리 가속 |
| T5 | 운영체제 구동 및 확장 |

[단계별 캡스톤과 수집 카드](hub.html#tree)

## 04. 주변장치 자료

<div class="hub-grid">
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/devices/i2c"><strong>I2C</strong><span>직렬 센서 통신</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/devices/bluetooth"><strong>Bluetooth</strong><span>무선 명령·제어</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/devices/ethernet"><strong>Ethernet</strong><span>유선 네트워크 통신</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/devices/ir"><strong>IR</strong><span>적외선 리모컨</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/devices/1-wire"><strong>1-Wire</strong><span>단일 데이터선 센서</span></a>
<a class="hub-card" href="https://github.com/Yuul-Jung/fpga-soc-harness/tree/main/devices/xadc"><strong>XADC</strong><span>FPGA 내부 아날로그 입력</span></a>
</div>

## 05. 아이디어와 검증

- [아이디어 파이프라인](inbox/ideas.html)
- [수집 대기 목록](inbox/queue.html)
- [최근 수집·검증 활동](hub.html#log)
- [수집 및 검증 운영 지침](harness.html)
- [GitHub 원본 저장소](https://github.com/Yuul-Jung/fpga-soc-harness)
- [HTML 제작 공통 규칙](https://github.com/Yuul-Jung/rule_md/blob/main/web/education-html/STANDARD.md)

> **검증 기준:** 수집 등급과 실제 RTL 시뮬레이션·합성·타이밍·하드웨어 검증은 별개입니다. 확인되지 않은 실행 결과는 미검증으로 취급합니다.
