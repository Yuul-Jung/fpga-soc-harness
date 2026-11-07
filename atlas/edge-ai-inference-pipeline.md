# 엣지 AI 추론 파이프라인: BNN·LeNet·카메라 실시간 처리

갱신: 2026-11-07 (/verify 35차). 카드 3건 기반 (BNN BCNN 카메라 1건, BNN FC MNIST 1건, LeNet Q4.4 HPS 1건).
카메라 입력 → 전처리 → 추론 → 출력으로 이어지는 엣지 AI 파이프라인의 FPGA 구현 사례를 정리한다.
MicroBlaze V SoC 통합 경로와 Basys3(XC7A35T) 적합성을 중심으로 분석한다.

---

## 1. 사례 개요

| 항목 | rajmali-22-fpga-zebra-crossing-camera | emirertorer-bnn-mnist-nexys-a7 | columbia-4840-sp24-lenet-classifier |
|---|---|---|---|
| 카드 | [rajmali-22-fpga-zebra-crossing-camera](../catalog/amd/rajmali-22-fpga-zebra-crossing-camera.md) | [emirertorer-bnn-mnist-nexys-a7](../catalog/amd/emirertorer-bnn-mnist-nexys-a7.md) | [columbia-4840-sp24-lenet-classifier](../catalog/papers/columbia-4840-sp24-lenet-classifier.md) |
| 보드 | EDGE Artix-7 (XC7A35T) | Nexys A7-100T (XC7A100T) | DE1-SoC (Cyclone V) |
| 칩 | XC7A35T ← Basys3 동일 칩 | XC7A100T (BRAM 135개) | Cyclone V (Intel/Altera) |
| 추론 방식 | 1-bit BNN (BCNN, 4 conv + FC) | 1-bit BNN (FC 전용: 784→128→64→10) | Q4.4 고정소수점 LeNet (2 conv + 3 FC) |
| 입력 | OV7670 카메라 (640×480 RGB565) | MNIST 픽셀 직접 주입 (카메라 없음) | OV7670 카메라 (640×480 RGB565) |
| 전처리 | 8×8 블록 평균 → 80×60 그레이스케일 | 없음 (테스트 데이터 직접) | HPS 소프트웨어: 80×60 → 42×42 센터크롭 |
| CPU | 없음 (순수 RTL FSM) | 없음 (순수 RTL FSM) | HPS (ARM Cortex-A9) + FPGA |
| 버스 | 없음 | 없음 | Avalon-MM |
| 출력 | VGA 640×480 오버레이 (컬러 보더 + 배너) | 7세그먼트 (숫자 0~9) | 7세그먼트 (숫자 0~9) |
| 처리량 | 26.7 fps / 34 ms/프레임 | 17,845 ns/추론 @ 80MHz | 미보고 |
| 정확도 | 횡단보도 이진 분류 (클래스 1) | 87.97% (MNIST 10,000장) | 90.86% (MNIST 10,000장) |
| 라이선스 | MIT | unknown | unknown |
| 등급 | L3 | L3 | L3 |
| 단계 | T4 | T4 | T3 |
| Basys3 적합성 | needs-port | no | needs-port |

---

## 2. BRAM 사용량 비교

**BRAM 사용량 비교가 이 사례 묶음의 가장 중요한 교훈이다.**

| 설계 | BRAM 사용 | 이유 |
|---|---|---|
| rajmali-22 (BNN BCNN) | 19 / 50 (38%) | 1-bit 가중치 11.4 KB 전량 온칩 BRAM, 합성곱 계층화 + 작은 FC 출력(1개) |
| emirertorer (BNN FC) | 132 / 135 (97.78%) | FC 전용: 784→128→64→10 BNN 가중치를 모두 BRAM에 저장, 합성곱 없어 가중치 재사용률 낮음 |
| columbia-4840 (LeNet Q4.4) | 미보고 (DRAM 의존) | HPS DRAM에 가중치 저장, 추론 전 Avalon을 통해 FPGA 로컬 메모리 로드 |

**내 판단: 합성곱 BNN(BCNN)이 FC BNN보다 BRAM 효율이 현저히 높다.** 같은 1-bit BNN이지만 rajmali-22(BCNN)는 BRAM 38%로 Basys3에서 여유 있게 동작하는 반면, emirertorer(FC BNN)는 BRAM 97.78%로 Nexys A7-100T(BRAM 135개)에서도 포화 직전이다. Basys3(BRAM 50개)에서는 emirertorer 방식을 직접 이식하면 가중치 용량이 2.6배 초과한다. 합성곱 계층화(BNN)와 작은 FC 출력(1클래스 판별)이 BRAM 효율의 핵심이다.

---

## 3. 카메라 전처리 파이프라인 비교

| 항목 | rajmali-22 | columbia-4840 |
|---|---|---|
| 카메라 | OV7670 (RGB565 640×480, 26.7fps) | OV7670 (RGB565 640×480) |
| 초기화 | SCCB 직렬 버스 (I2C 호환) | SCCB (HPS 소프트웨어) |
| 다운샘플 | 8×8 블록 평균 → 80×60 (FPGA RTL) | HPS 소프트웨어: 80×60 그레이스케일 |
| 추가 전처리 | 없음 | 42×42 센터 크롭 (HPS 소프트웨어) |
| 색상 변환 | RGB → 그레이스케일 (가중치 평균 추정) | RGB → 그레이스케일 (HPS) |
| 전처리 위치 | FPGA 하드웨어 (실시간 스트리밍) | HPS CPU (프레임 버퍼 방식) |

**내 판단: rajmali-22의 카메라 전처리 블록(SCCB 초기화, 8×8 평균, RGB→Gray)은 독립 모듈로 분리 재사용 가능하다.** columbia-4840은 HPS 없는 환경(Basys3)에서 이 전처리를 FPGA RTL로 대체해야 한다. rajmali-22의 전처리 아키텍처가 직접 참조 대상이다.

---

## 4. 실패 사례와 교훈 (§S6)

columbia-4840 보고서(§6 교훈)가 상세한 실패 사례를 기록하고 있다. 하네스에서 직접 활용 가능한 교훈이다.

| 실패 | 원인 | 해결 / 교훈 |
|---|---|---|
| FSM 오동작 | 클럭 도메인 불일치 | 동기화 로직 추가. **처음부터 단일 클럭 도메인 설계 권장** |
| 유지보수성 저하 | Avalon 레지스터 주소 하드코딩 | `config/soc_address_map.json` 동결 맵 슬롯 사용 |
| 고정소수점 오버플로우 | Q4.4 내적 계산 중 중간값 비트폭 초과 | **중간 누산기를 항상 2배 폭(≥8비트) 이상 확보**, 클리핑 또는 Sat 연산 |
| 경계 픽셀 오분류 | Conv 2층 패딩 오류 | 미해결(보고서 한계). 패딩 처리를 RTL 설계 초기에 검증 필수 |

**내 판단: 위 교훈은 Basys3 BNN 추론 IP(I-137, I-139 아이디어) 설계에 직접 적용해야 한다.** 특히 Q4.4 중간 누산기 비트폭 문제는 BNN에서는 1-bit × 1-bit 팝카운트이므로 오버플로우 위험이 없지만, Q4.4 LeNet 포팅 시에는 반드시 2배 폭 임시 레지스터를 사용해야 한다.

---

## 5. Basys3 이식 경로

### 5.1 rajmali-22 → Basys3 이식 (needs-port)

**이식 가능성: 높음.** XC7A35T 동일 칩, LUT 16% (3,370/20,800), BRAM 38% (19/50)로 여유 있다.

| 항목 | 필요 작업 |
|---|---|
| XDC 파일 | Basys3 핀맵으로 전면 교체 (Pmod OV7670, VGA 온보드) |
| LCD·버저 | Pmod 대체 또는 제거 |
| MMCM 클럭 플랜 | 133.33 MHz (카메라·SDRAM), 66.7 MHz (BCNN), 25 MHz (VGA), 21.33 MHz (OV7670 XCLK) → Basys3 100 MHz 입력에서 재분주 |
| 소프트웨어 의존성 | 없음 (순수 RTL FSM, MicroBlaze 불필요) |
| MicroBlaze V 연동 | BCNN 코어를 AXI4-Lite 슬레이브 IP로 래핑, 가중치 로드·추론 트리거·결과 읽기를 C 드라이버로 처리 |

### 5.2 emirertorer → Basys3 이식 (no)

**직접 이식 불가.** BRAM 132/135 필요 → Basys3 50개의 2.6배 초과.

**축소 이식 경로 (내 판단):** 784→32→16→10 으로 대폭 축소 시 가중치 ≈ 25,600 + 512 + 160 = 26,272 비트 ≈ 3.3 KB → BRAM 7개 이하로 Basys3에서 동작 가능성 있음. 단, 정확도 저하(87.97% → 추정 70~80%) 예상.

### 5.3 columbia-4840 → Basys3 이식 (needs-port)

**이식 난이도: 높음.** Intel/Altera 전용(Cyclone V HPS, Avalon-MM 버스) + 가중치 DRAM 의존이 주요 장벽.

| 항목 | 필요 작업 |
|---|---|
| CPU | HPS(ARM) 역할 → MicroBlaze V C 드라이버로 대체 |
| 버스 | Avalon-MM → AXI4-Lite 슬레이브 IP 래핑 |
| 카메라 전처리 | 80×60 다운샘플·42×42 크롭 → AXI Stream 모듈로 분리, rajmali-22 전처리 블록 참조 |
| 가중치 저장 | HPS DRAM(400KB 추정) → Basys3 BRAM 용량 초과. BNN화(1-bit) 없이는 적재 불가. BNN화 시 11.4KB → BRAM 3개. |
| 클럭 패딩 오류 | Conv 2층 패딩 버그 미해결 → RTL 재작성 시 패딩 처리 초기에 검증 |

---

## 6. MicroBlaze V SoC 통합 경로

**rajmali-22(BNN BCNN)가 가장 직접적인 MicroBlaze V SoC 통합 후보이다.**

```
MicroBlaze V C 드라이버
  ↓ AXI4-Lite write (가중치 로드, 추론 트리거)
BCNN 코어 (AXI4-Lite 슬레이브 IP)  ← rajmali-22 RTL 래핑
  ↑ AXI Stream
카메라 전처리 블록 (SCCB + 8×8 평균 + RGB→Gray)  ← rajmali-22 분리 재사용
  ↑ DVP 직렬
OV7670 (Pmod)
```

- 가중치(11.4 KB)는 BRAM 초기값(.mem 파일)으로 고정하거나 MicroBlaze V가 AXI4-Lite write로 적재.
- 동결 맵 `free_slots` 중 한 64KB 영역에 BCNN 슬레이브 배정.
- VGA 출력은 MicroBlaze V 비종속(순수 FSM)이므로 별도 AXI 연결 불필요.

**이 아이디어가 I-139(BNN BCNN 횡단보도 감지 Basys3 AXI4-Lite SoC 통합)로 등록되었으며 2026-11-07 차단조건재심사 10점으로 ready 상태이다.**

---

## 7. 조합 아이디어 연결

| 아이디어 | 설명 | 근거 카드 | 상태 |
|---|---|---|---|
| I-137 (AXI4-Lite NPU IP 1-MAC) | 1-MAC AXI4-Lite NPU 슬레이브 → T4 추론 IP 기초 | emirertorer(BNN FC 아키텍처) + rajmali-22(BCNN XNOR+팝카운트) + adityapusalkar | ready (차단조건 9점) |
| I-139 (BNN BCNN 횡단보도 Basys3 이식) | rajmali-22 BNN BCNN 추론 파이프라인 Basys3 AXI4-Lite SoC 통합 | rajmali-22 (MIT, XC7A35T, BRAM 38%) + emirertorer (BRAM 비교) + columbia-4840 (카메라 전처리) | ready (차단조건 10점) |
| I-140 (소형 BNN FC + OV7670) | emirertorer FC 축소(784→32→16→10) + rajmali-22 카메라 전처리 조합 | emirertorer + rajmali-22 + columbia-4840 | vetted (차단조건 9점, 슬롯소진) |
| I-141 (Q4.4 LeNet → Basys3 FSM) | columbia-4840 LeNet을 순수 FSM + AXI4-Lite 슬레이브로 재설계, 실패 교훈 반영 | columbia-4840 + adityapusalkar + columbia-4840-sp26 | vetted (차단조건 9점, 슬롯소진) |

---

## 교훈

- **내 판단: 엣지 AI 파이프라인의 완결형으로 rajmali-22가 하네스 최우선 참조 대상이다.** 카메라 → 전처리 → BNN 추론 → VGA 출력 전 단계를 한 저장소에서 볼 수 있는 드문 사례이고, XC7A35T(Basys3 동일 칩)에서 LUT 16%, BRAM 38%로 동작한다.
- **내 판단: BNN FC 전용 설계(emirertorer)는 BRAM 병목이 치명적이다.** FC 레이어는 가중치 재사용률이 낮아 BRAM 소모가 합성곱 대비 현저히 높다. Basys3에서 BNN FC를 쓰려면 층 수·폭을 대폭 줄이거나 BNN BCNN으로 아키텍처를 바꿔야 한다.
- **내 판단: columbia-4840 §6 실패 교훈(클럭 도메인 불일치, Q4.4 오버플로우, 패딩 오류)은 RTL 설계 체크리스트로 직접 활용한다.** 특히 Q4.4 중간 누산기 비트폭 문제와 패딩 처리는 T4 추론 IP 설계 초기에 반드시 검증해야 한다.
