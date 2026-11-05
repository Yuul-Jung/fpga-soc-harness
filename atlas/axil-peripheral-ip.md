# AXI4-Lite 주변장치 IP 비교: INTC·타이머/WDT·레지스터 템플릿

갱신: 2026-11-05 (/verify 25차). 카드 14건 기반.
인터럽트 컨트롤러(INTC), 타이머·WDT, AXI4-Lite 슬레이브 레지스터 파일, AXI4 크로스바/인터커넥트 사례를 정리한다. 모두 MicroBlaze V SoC의 `free_slots` 배정과 관련된 주제다.

---

## 1. 인터럽트 컨트롤러 (INTC)

| 항목 | amd-axi-intc-pg099 | zipcpu-icontrol | realisshoon-axi4-lite-multi-peripheral-soc |
|---|---|---|---|
| 카드 | [amd-axi-intc-pg099](../catalog/papers/amd-axi-intc-pg099.md) | [zipcpu-icontrol](../catalog/vendor-neutral/zipcpu-icontrol.md) | [realisshoon-axi4-lite-multi-peripheral-soc](../catalog/amd/realisshoon-axi4-lite-multi-peripheral-soc.md) |
| 보드 | 모두(Artix-7) | 중립 | Basys3 |
| CPU | MicroBlaze | ZipCPU | MicroBlaze |
| 버스 | AXI4-Lite | Wishbone | AXI4-Lite |
| 소스 입력 최대 | 32개 | 15개 | 주변장치별 연결 |
| 레지스터 | ISR·IER·IAR·IVR·MER(+IMR·IVAR) | 단일 32비트(pending/enable/MIE) | AMD IP 사용 |
| 우선순위 | 하드웨어(bit 0 최고) | 없음(SW 의존) | AMD IP 의존 |
| 형식 검증 | 없음(제품 IP) | sby(SymbiYosys) | 없음 |
| 라이선스 | Xilinx EULA | GPL-3.0 | unknown |
| 등급 | L3 | L3 | L2 |
| 단계 | T3 | T2 | T3 |
| Basys3 적합성 | yes | needs-port | yes |

**패턴 (내 판단):** AMD PG099 INTC는 MicroBlaze V 소프트웨어 스택(XIntc 드라이버)과 완전 호환되는 표준 경로이나 Xilinx EULA로 묶여 있다. ZipCPU icontrol은 단일 레지스터 비트 필드 설계가 간결하고 형식 검증이 갖춰져 있으나 Wishbone 인터페이스이므로 AXI4-Lite로 포팅하려면 버스 래퍼와 레지스터 맵 재설계가 필요하다. realisshoon 사례는 AMD AXI INTC를 Basys3에서 실제로 연결한 한국어 사례로, 주소 `0x4120_0000`이 동결 맵 `INT_CTRL` 슬롯에 그대로 맞는다.

**MicroBlaze V 개조 경로 (내 판단):** PG099 레지스터 맵(ISR/IER/IAR/IVR/MER)을 그대로 따르는 오픈소스 Verilog IP(I-111 아이디어)를 새로 작성하면 XIntc 드라이버와 호환되면서 Xilinx EULA를 피할 수 있다. ZipCPU icontrol에서 인터럽트 래칭·MIE 2세대 버그 수정 패턴과 형식 검증 패턴을 참조하되 RTL은 새로 작성한다.

---

## 2. 타이머 / WDT

| 항목 | amd-axi-timebase-wdt-pg083 | amoghvarsh-axi4-lite-timer-wdt | mij001-axil-timer | ignaciosim-tt06-triple-watchdog |
|---|---|---|---|---|
| 카드 | [amd-axi-timebase-wdt-pg083](../catalog/amd/amd-axi-timebase-wdt-pg083.md) | [amoghvarsh-axi4-lite-timer-wdt](../catalog/vendor-neutral/amoghvarsh-axi4-lite-timer-wdt.md) | [mij001-axil-timer](../catalog/vendor-neutral/mij001-axil-timer.md) | [ignaciosim-tt06-triple-watchdog](../catalog/vendor-neutral/ignaciosim-tt06-triple-watchdog.md) |
| 보드 | Basys3 | 중립 | 중립 | ASIC(sky130) |
| 버스 | AXI4-Lite | AXI4-Lite | AXI4-Lite | none(FSM) |
| 언어 | Verilog(IP) | Verilog | SystemVerilog | Verilog |
| 기능 | 기본WDT+윈도우WDT+WDTOUT | 범용타이머+WDT모드 | 주기·원샷·카운트다운+IRQ | 기본WDT+윈도우WDT+독립WDT 삼중 채널 |
| 테스트벤치 | 없음(IP) | OKAY/SLVERR/DECERR 셀프체킹 | SVA+Python UVM 1.2 | 미확인(ASIC 타겟) |
| 형식 검증 | 없음 | 없음 | SVA 단언 | 없음(미확인) |
| 라이선스 | Xilinx IP 라이선스 | unknown | MIT | unknown |
| 등급 | L2 | L2 | L3 | L2 |
| 단계 | T2 | T2 | T2 | T1 |
| Basys3 적합성 | yes | needs-port | needs-port | needs-port |

**패턴 (내 판단):** AMD WDT IP는 윈도우 모드와 WDTOUT 하트비트 핀 출력이 특징적이며 Vivado에서 IP 추가만으로 동작한다. amoghvarsh 타이머는 소스 미열람(L2)이나 셀프체킹 TB가 하네스 CI 패턴에 맞는다. mij001 타이머는 SystemVerilog UVM 환경이 풍부하여 AXI4-Lite 슬레이브 IP 테스트 패턴 참고용으로 가치가 높고, MIT 라이선스라 개조 허용 범위가 넓다. ignaciosim-tt06-triple-watchdog은 TinyTapeout 6 ASIC 타겟 Verilog FSM으로 기본·윈도우·독립 세 가지 WDT 모드를 하나의 소형 IP에 구현한 사례 — 버스 없이 FSM 전용이므로 AXI4-Lite 래퍼를 추가해야 MicroBlaze V SoC에 연결 가능하나, 세 모드 비교 실습(I-118 아이디어)의 RTL 참조 패턴으로 가치가 있다(내 판단).

**MicroBlaze V 개조 경로 (내 판단):** 세 카드 모두 AXI4-Lite 슬레이브로 `free_slots`에 직접 배정 가능하다. AMD IP(axi_timebase_wdt)를 쓰면 Vivado IP 카탈로그에서 즉시 연결 가능하나 소스 비공개. mij001 타이머는 MIT 라이선스이므로 Verilog-2001로 재작성 후 IP 표준 래퍼 적용 경로가 가능하다. WDTOUT 핀 출력을 Pmod에 연결해 외부 슈퍼바이저 모의(I-119 아이디어)를 테스트할 수 있다.

---

## 3. AXI4-Lite 슬레이브 레지스터 파일 템플릿

| 항목 | zipcpu-wb2axip-easyaxil | chclau-magellan-basys3-axil-regs | bugratufan-axion-hdl |
|---|---|---|---|
| 카드 | [zipcpu-wb2axip-easyaxil](../catalog/vendor-neutral/zipcpu-wb2axip-easyaxil.md) | [chclau-magellan-basys3-axil-regs](../catalog/amd/chclau-magellan-basys3-axil-regs.md) | [bugratufan-axion-hdl](../catalog/vendor-neutral/bugratufan-axion-hdl.md) |
| 보드 | 중립 | Basys3 | 중립 |
| 언어 | Verilog | VHDL | Python→VHDL/SV |
| 접근 방식 | 패턴(코드 스니펫) | Vivado Block Design + 커스텀 | 코드 생성 도구 |
| WSTRB 처리 | apply_wstrb() 함수 (명시적) | 미확인 | 도구 자동 생성 |
| CDC 지원 | 없음(기본) | 없음 | 선택적(토글 동기화기) |
| 형식 검증 | faxil_slave.v (SymbiYosys) | 없음 | 없음 |
| 라이선스 | unknown | unknown | MIT |
| 등급 | L3 | L3 | L3 |
| 단계 | T2 | T2 | T2 |
| Basys3 적합성 | needs-port | yes | needs-port |

**패턴 (내 판단):** zipcpu-easyaxil은 AXI4-Lite 슬레이브 설계의 핵심 버그(axi_arready 항상 1 패턴)를 형식 검증으로 잡아낸 사례이며, WSTRB·$clog2 디코더 패턴이 가장 명확하게 문서화되어 있다. chclau-magellan은 Basys3에서 JTAG-to-AXI 마스터 연결을 TCL로 보여주는 유일한 L3 Basys3 사례로, MicroBlaze 없이 IP 디버그 경로를 보여준다. bugratufan-axion-hdl은 @axion 주석에서 레지스터 맵을 자동 생성하므로 반복 IP 개발 시 도구 체인 채택 가치가 있다.

**MicroBlaze V 개조 경로 (내 판단):** 셋 모두를 조합한 IP 표준 Verilog-2001 슬레이브 파일(I-114 아이디어)이 목표다. zipcpu-easyaxil의 WSTRB·디코더 패턴을 적용하고, faxil_slave.v 형식 검증을 연결하며, MicroBlaze V 동결 맵 `free_slots` 주소를 파라미터로 받도록 한다. VHDL(magellan)이나 Python 생성(axion)은 IP 표준 Verilog-2001 목표와 언어가 달라 직접 복사 대신 설계 패턴만 참조한다.

---

## 4. AXI4 크로스바 / 인터커넥트 IP

(2026-11-06 /verify 23차 추가. 카드 3건 기반: alexforencich-verilog-axi-crossbar, dpretet-axi-crossbar, zipcpu-wb2axip-crossbar-addrdecode)

| 항목 | alexforencich-verilog-axi-crossbar | dpretet-axi-crossbar | zipcpu-wb2axip-crossbar-addrdecode |
|---|---|---|---|
| 카드 | [alexforencich-verilog-axi-crossbar](../catalog/vendor-neutral/alexforencich-verilog-axi-crossbar.md) | [dpretet-axi-crossbar](../catalog/vendor-neutral/dpretet-axi-crossbar.md) | [zipcpu-wb2axip-crossbar-addrdecode](../catalog/vendor-neutral/zipcpu-wb2axip-crossbar-addrdecode.md) |
| 버스 | AXI4 | AXI4, AXI4-Lite | AXI4-Lite, AXI4, Wishbone |
| 언어 | Verilog-2001 | SystemVerilog | Verilog |
| 등급 | L3 | L3 | L2 |
| 라이선스 | MIT | MIT | unknown(GPL 추정, 미확인) |
| 주소 디코딩 방식 | 범위 기반(M_BASE_ADDR, 2^M_ADDR_WIDTH 경계) | 시작+끝 주소 범위 | SLAVE_ADDR/MASK AND 방식 |
| 중복 주소 검출 | elaboration-time `$error`/$finish | 미구현(향후 계획) | 없음(형식 검증으로 대체) |
| 에러 슬레이브 | m_decerr 플래그 | DECERR 반환 | NS+1번째 에러 슬레이브 |
| 중재 방식 | 접수 제어(ID 추적, S_THREADS/S_ACCEPT) | 라운드 로빈(우선순위 최대 4단계) | 번호 낮은 마스터 우선, stay_on_channel |
| 형식 검증 | 없음 | 없음(CocoTB 향후 계획) | SymbiYosys($onehot0 grant) |
| 위자드/도구 | 없음 | JSON/TUI 위자드 | 없음 |
| CDC 지원 | 없음 | 있음 | 없음 |
| Basys3 적합성 | needs-port | needs-port | needs-port |
| 단계 | T2 | T2 | T2 |

**패턴 (내 판단):**
- alexforencich: `M_BASE_ADDR`가 0이면 순차 자동 배치(2^M_ADDR_WIDTH 단위), elaboration-time `$error`로 겹침 차단 — 동결 맵 슬롯에서 파라미터 직접 추출 가능. M_ADDR_WIDTH 최소 12비트(4KB) 조건이 Basys3 Pmod 범위(4KB 미만) 사례를 제한함.
- dpretet: JSON 위자드로 RTL 자동 생성하는 접근법이 `config/soc_address_map.json` 패턴과 구조적으로 유사. SystemVerilog 전용 → iverilog 최신 버전 필요, Verilog-only 플로에는 부적합.
- zipcpu wb2axip: `SLAVE_ADDR/SLAVE_MASK` AND-마스크 방식은 2의 거듭제곱 정렬 범위만 표현 가능(동결 맵 64KB 슬롯과 호환). `$onehot0` 어서션으로 grant 무결성 형식 검증 — 단, 라이선스 미확인(GPL 추정)이므로 코드 반입 전 확인 필수.

**MicroBlaze V 개조 경로 (내 판단):**
소형 AXI4-Lite 크로스바(I-121)는 alexforencich 범위 비교 패턴과 zipcpu 에러 슬레이브·중재 규칙을 참조해 Verilog-2001 자체 RTL로 작성한다. `M_BASE_ADDR`는 `config/soc_address_map.json`의 `free_slots`에서 직접 채우는 `parameter` 블록으로 연결. dpretet의 JSON 위자드 접근법은 동결 맵→RTL 생성 도구(I-120) 아이디어의 참조 패턴으로 활용.

---

## 조합 아이디어 요약

| 아이디어 | 조합 | 근거 카드 | 상태 |
|---|---|---|---|
| I-111 AXI4-Lite INTC IP | PG099 호환 Verilog INTC | amd-axi-intc-pg099, zipcpu-icontrol, mij001-axil-timer | ready |
| I-112 UART+INTC 연동 | UART RX not-empty 인터럽트 | amd-axi-intc-pg099, realisshoon, opencores-auto-baud | ready |
| I-113 INTC 난이도 사다리 | T1 OR→T2 icontrol→T3 AXI INTC | zipcpu-icontrol, amd-axi-intc-pg099, mij001-axil-timer | ready |
| I-114 AXI4-Lite 레지스터 파일 IP | WSTRB+$clog2+faxil_slave | zipcpu-wb2axip-easyaxil, chclau-magellan, bugratufan-axion | ready |
| I-115 JTAG-to-AXI 디버그 하네스 | JTAG-to-AXI + TCL 패턴 | chclau-magellan, zipcpu-easyaxil, amd-axi-intc-pg099 | ready |
| I-116 AXI4-Lite 슬레이브 사다리 | RW뱅크→CDC→인터럽트 소스 | zipcpu-wb2axip-easyaxil, bugratufan-axion, zipcpu-icontrol | ready |
| I-117 WDT + 7세그 가시화 | 윈도우 WDT + 7세그 FSM | amd-axi-timebase-wdt-pg083, mij001-axil-timer, chclau-magellan | vetted |
| I-118 삼중 WDT 비교 패널 | 기본+윈도우+SW에뮬 WDT | amd-axi-timebase-wdt-pg083, ignaciosim-tt06, mij001-axil-timer | vetted |
| I-119 WDT 하트비트 핀 출력 | WDTOUT→Pmod+슈퍼바이저 FSM | amd-axi-timebase-wdt-pg083, suoglu-axi-lite-slave, amoghvarsh | vetted |
| I-120 동결 맵 AXI 충돌 검사기 | Python 생성기 + Verilog $error 가드 | alexforencich-verilog-axi-crossbar, zipcpu-wb2axip-crossbar-addrdecode, zipcpu-wb2axip-easyaxil | vetted |
| I-121 2M+4S AXI4-Lite 소형 크로스바 | 에러 슬레이브+중재+형식 어서션 | alexforencich-verilog-axi-crossbar, zipcpu-wb2axip-crossbar-addrdecode, dpretet-axi-crossbar | vetted |
| I-122 AXI 주소 범위 TB 자동 생성기 | 경계값 주입+DECERR 검증 | alexforencich-verilog-axi-crossbar, zipcpu-wb2axip-crossbar-addrdecode, zipcpu-wb2axip-easyaxil | vetted |

---

## 교훈

- **내 판단: AMD IP vs 오픈소스 Verilog IP:** AMD PG099 INTC·WDT는 Vivado에서 즉시 사용 가능하나 Xilinx EULA로 소스 수정·재배포가 제한된다. 같은 레지스터 맵을 따르는 오픈소스 Verilog IP는 CI 검증·수정·교육 가치가 높으며, MicroBlaze V 소프트웨어 드라이버(XIntc, XIicPs 등) 호환성도 유지된다.
- **내 판단: WSTRB 버그:** Xilinx 공식 AXI4-Lite 슬레이브 템플릿의 `axi_arready` 상시-1 버그는 단일 마스터 환경(MicroBlaze V)에서 증상이 숨겨질 수 있다. zipcpu-easyaxil의 올바른 패턴을 IP 표준 래퍼의 기초로 삼아야 한다.
- **내 판단: 형식 검증의 현실적 가치:** AXI4-Lite 슬레이브 IP를 새로 작성할 때 faxil_slave.v(ZipCPU)를 연결하면 하네스 CI에서 iverilog/verilator 외에 sby 형식 검증까지 추가할 수 있다. 단, sby 환경은 현재 하네스 CI에 없으므로 추가 여부는 사용자 결정 사항이다.
- **내 판단: free_slots 배정 계획:** INTC 1건(I-111/I-113)·WDT 1건(I-117~119 중 1건)·레지스터 파일 IP 1건(I-114)이 같은 사이클에 패키지화될 경우 `free_slots`에서 최소 3개(64KB × 3)를 소비한다. 현재 동결 맵 `free_slots` 여유 확인 필요.
