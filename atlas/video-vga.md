# VGA·카메라·LED·PWM 주변장치 비교

갱신: 2026-11-06 (/verify 20차). 카드 9건 기반.
VGA 출력(video-vga), 카메라 파이프라인(camera), LED·PWM(pwm-rgb) 주변장치 사례를 정리한다.

---

## VGA + 7세그먼트 동시 표시 (Basys3 직접 연결)

| 항목 | argrabowski-fpga-vga-display | byu-ecen423-lab10-riscv-vga-7seg | itsnotjiaching-ec311project |
|---|---|---|---|
| 카드 | [argrabowski-fpga-vga-display](../catalog/amd/argrabowski-fpga-vga-display.md) | [byu-ecen423-lab10-riscv-vga-7seg](../catalog/amd/byu-ecen423-lab10-riscv-vga-7seg.md) | [itsnotjiaching-ec311project](../catalog/amd/itsnotjiaching-ec311project.md) |
| 보드 | Basys3 | Basys3 | Basys3(추정) |
| CPU | 없음(FSM) | RISC-V 포워딩 파이프라인 | 없음(FSM) |
| 버스 | 없음 | 커스텀 MMIO | 없음 |
| 주변장치 | VGA 패턴+이동, 4자리 7세그 | VGA 텍스트 80×30, 7세그 카운터 | VGA Pong, 4자리 7세그 점수 |
| 라이선스 | unknown | unknown(과목) | unknown |
| 단계 | T2 | T4 | T2 |
| 등급 | L2 | L2 | L2 |
| 한계 | 테스트벤치 미확인, 커밋 2건 | 소스 비공개(과목 과제) | 보드명 미명시, 테스트벤치 세부 미열람 |

**패턴 (내 판단):** 세 사례 모두 VGA 타이밍 모듈과 7세그 멀티플렉서 모듈을 각각 독립적으로 분리하고 최상위에서 연결하는 구조이다. CPU 없는 T2(FSM) 사례와 CPU가 소프트웨어로 제어하는 T4 사례가 명확히 구분된다. MicroBlaze V SoC 적용 시 T2 사례는 AXI4-Lite 슬레이브로 감싸는 개조 경로가 명확하고, T4 사례(byu)는 드라이버 계층 설계의 직접 참고 모델이다.

---

## VGA 프레임버퍼 / BRAM 그래픽 (벤더 중립·needs-port)

| 항목 | fcayci-xilinx-vga-framebuffer-ip-core | projf-projf-explore | talsania-fpga-image-buffer |
|---|---|---|---|
| 카드 | [fcayci-xilinx-vga-framebuffer-ip-core](../catalog/amd/fcayci-xilinx-vga-framebuffer-ip-core.md) | [projf-projf-explore](../catalog/vendor-neutral/projf-projf-explore.md) | [talsania-fpga-image-buffer](../catalog/vendor-neutral/talsania-fpga-image-buffer.md) |
| 보드 | 미확인(Xilinx 계열 추정) | Arty S7, iCE40 UP5K | 미확인 |
| CPU | 없음(IP 코어) | 없음(순수 RTL) | 없음(UART 로더) |
| 버스 | 듀얼포트 BRAM 공유(상위 버스 미확인) | 없음 | UART 입력 |
| 프레임버퍼 | 듀얼포트 BRAM, 포트A=호스트·포트B=VGA 스캔 | BRAM 타일·스프라이트·애니메이션 | 듀얼포트 BRAM, UART 로더 → VGA 스캔 |
| 더블 버퍼 | 미확인(단일 추정) | 미확인 | 미확인(단일 추정) |
| 언어 | Verilog | SystemVerilog | Verilog |
| 단계 | T2 | T2 | T2 |
| 등급 | L2 | L2 | L2 |
| fit_basys3 | needs-port | needs-port | needs-port |
| 한계 | 보드·클럭·해상도 미확인 | Basys3 XDC 없음, SV → Verilog-2001 변환 필요 | UART 로딩 속도 제한(~1.7초/프레임) |

**패턴 (내 판단):** 세 사례 모두 듀얼포트 BRAM을 프레임버퍼로 쓰는 같은 패턴이다. Basys3 no-dram 환경에서 가장 현실적인 접근법이며, 160×120×1 byte = ~19 KB로 Basys3 BRAM(225 KB) 예산 내에서 더블 버퍼(핑퐁)도 가능하다. talsania는 S4(제약 역전) 사례로 UART 로더가 SD 카드·DDR을 대체하는 패턴을 보여 준다.

**개조 경로 (내 판단):** fcayci 패턴(포트A=CPU, 포트B=VGA)에 AXI4-Lite 슬레이브 래퍼를 붙이면 MicroBlaze V SoC의 VGA 주변장치 IP 구조가 된다. 동결 맵 `free_slots`에서 64 KB 슬롯 1개를 프레임버퍼 쓰기 포트에 배정하고, VSync 인터럽트로 버퍼 전환을 제어하면 테어링 없는 더블 버퍼가 가능하다.

---

## 카메라 파이프라인 (needs-port, T4)

| 항목 | olivier-le-sage-camera-filters |
|---|---|
| 카드 | [olivier-le-sage-camera-filters](../catalog/vendor-neutral/olivier-le-sage-camera-filters.md) |
| 보드 | Spartan Edge Accelerator (XC7S50) |
| 카메라 | OV2640 (DVIO 인터페이스) |
| 출력 | HDMI |
| 처리 | 감마 보정(piecewise linear, 시프트 근사), BT.601 RGB→Y'UV |
| 자원 | 약 500 LUT, 약 100 FF (README 기준) |
| 라이선스 | MIT |
| 등급 | L3 |
| fit_basys3 | needs-port |
| 단계 | T4 |

**패턴 (내 판단):** 곱셈기·BRAM LUT 없이 시프트 연산만으로 감마 보정과 색공간 변환을 구현한 최소 면적 사례이다. HDMI 출력을 VGA로 교체하고 카메라 xdc를 Pmod용으로 재설계하면 Basys3 포팅이 가능하다. MIT 라이선스이므로 감마 근사 계수와 BT.601 행렬 아이디어를 착용해 자체 RTL 재작성에 활용할 수 있다.

---

## LED · RGB PWM (T1, needs-port)

| 항목 | maplesilicon-mapleled-core | mit-6205-rgb-pwm-week01 |
|---|---|---|
| 카드 | [maplesilicon-mapleled-core](../catalog/vendor-neutral/maplesilicon-mapleled-core.md) | [mit-6205-rgb-pwm-week01](../catalog/papers/mit-6205-rgb-pwm-week01.md) |
| 보드 | iCEBreaker (iCE40 UP5K) | Urbana FPGA (Xilinx 계열) |
| 주요 기능 | 8비트 PWM + 감마 보정 LUT | 8비트 PWM + cocotb 테스트 |
| 라이선스 | MIT | 미명시 |
| 등급 | L2 | L2 |
| 단계 | T1 | T1 |
| fit_basys3 | needs-port | needs-port |
| 핵심 교훈 | 감마 LUT BRAM 초기화 패턴 | **PWM glitch 방지**: 듀티 사이클 변경은 카운터 리셋 시점에 래치해야 함 |

**패턴 (내 판단):** MIT 카드(mit-6205)는 PWM IP 작성 전 반드시 참고해야 할 S6 실패 사례를 담고 있다. "카운터 중간에 듀티 사이클을 바꾸면 잘못된 PWM 주파수가 발생한다"는 교훈은 모든 PWM 모듈 설계에 적용된다. maplesilicon 카드는 감마 LUT를 BRAM 초기화 블록(`$readmemh`)으로 구성하는 아이디어를 제공한다.

---

## gap 목록 (내 판단)

- gap T2: Basys3 MicroBlaze V AXI4-Lite VGA 텍스트 IP 카드 없음 — I-108(vetted)이 채울 예정.
- gap T2: Basys3 Pong 게임 MicroBlaze V + VGA + 7세그 통합 SoC 카드 없음 — I-109(vetted)가 채울 예정.
- gap T2: 듀얼포트 BRAM 프레임버퍼 AXI4-Lite 슬레이브 IP 카드 없음(fcayci/talsania가 개조 근거).
- gap T3: OV7670(Pmod 호환) → VGA 직접 스트리밍 Basys3 카드 없음(연관: kwondo99-fpga-vga-photobooth-project).
- gap T1: RGB LED Basys3 AXI4-Lite 슬레이브 IP 카드 없음 — I-030(ready), I-031(ready)이 채울 예정.

---

## 관련 카드 (기존 수집)

- kwondo99-fpga-vga-photobooth-project — OV7670 → VGA 파이프라인, T4, L3 (카드 미작성, §10 시드 목록)
- fanguoc2len-risc-v-computer — PicoRV32 + VGA 텍스트 80×29, T2, L3 (카드 미작성, §10 시드 목록)
