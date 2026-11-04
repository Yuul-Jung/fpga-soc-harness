## Basys3 (XC7A35T-1CPG236C) 제약 파일
## mmio-relay-autotune-ip 패키지
## 하네스 직접 작성 원본.
## 주의: 단독 IP XDC. SoC 최상위 통합 시 basys3_top.xdc로 병합한다.

## ----------------------------------------------------------------
## 클럭 (s_axi_aclk)
## ----------------------------------------------------------------
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS33} [get_ports s_axi_aclk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports s_axi_aclk]

## ----------------------------------------------------------------
## 리셋 (액티브-로우, BTNC)
## ----------------------------------------------------------------
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports s_axi_aresetn]

## ----------------------------------------------------------------
## 릴레이 출력 (Pmod JA 핀 1 — H-브리지 방향 비트)
## Pmod JA: JA1=J1, JA2=L2, JA3=J2, JA4=G2 (상단 행)
## ----------------------------------------------------------------
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports relay_out]

## ----------------------------------------------------------------
## 엔코더 속도 입력 (speed_in[15:0])
## 테스트벤치에서는 motor_model이 대신한다.
## 보드 연결 시 QDEC IP 출력을 AXI4-Lite 버스로 연결.
## 이 XDC는 직접 핀 연결이 필요한 경우의 예시다.
## 실제 SoC 통합에서는 speed_in을 AXI interconnect로 연결.
## ----------------------------------------------------------------
## (SoC 최상위 통합 시 speed_in은 AXI4-Lite 내부 버스 경유 — 핀 불필요)
## 단독 테스트용: Pmod JB (JB1~JB4, JB7~JB10) 또는 스위치 사용 가능.
## 아래는 주석 처리 (SoC 통합 시 사용 안 함).
# set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {speed_in[0]}]
# set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {speed_in[1]}]
# ...

## ----------------------------------------------------------------
## IRQ (Pmod JA 핀 2 — 필요 시 MicroBlaze V intc 연결)
## ----------------------------------------------------------------
set_property -dict {PACKAGE_PIN L2  IOSTANDARD LVCMOS33} [get_ports irq]

## ----------------------------------------------------------------
## 타이밍 예외 (AXI 경로)
## ----------------------------------------------------------------
set_false_path -from [get_ports s_axi_aresetn]
