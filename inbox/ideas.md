# 캡스톤 아이디어 큐

상태: `raw` → `vetted` → `ready` → `used` 또는 `dropped`. 지우지 않고 상태와 사유만 바꾼다. (HARNESS.md §12.8, §14.2)
아이디어는 사실이 아니라 판단이다. 각 항목은 "내 판단:"으로 시작한다.

형식:
```
## <id> <제목>
- 상태: raw
- 요약: 내 판단: ...
- 조합: [주변장치, ...]
- 근거: [카드 name 또는 URL, 2건 이상]
- 새로움의 근거: ...
- Basys3 적합성의 근거: ...
- 난이도: 1~5 / 단계: T0~T5
- 심사: (점수와 한 줄 근거, /verify가 기록)
```


## I-001 PWM 오디오 난이도 사다리 + VGA 막대 표시
- 상태: used (패키지: mmio-pwm-tune-vga-bars, 2026-11-02, 사용자 지시로 게이트 3 건너뜀)
- 요약: 내 판단: Pmod AMP2 PWM 출력으로 사각파→사인표→음계→BRAM 곡 재생까지 FSM으로 만들고, 재생 중 음높이를 VGA 막대로 보여주는 T1~T2 패키지.
- 조합: [audio-pwm, video-vga, BRAM]
- 근거: [zipcpu-pmodamp2-project-ladder, columbia-4840-audio-visualizer]
- 새로움의 근거: 카탈로그에 오디오+VGA 조합 패키지 없음(현재 카드 3건, 패키지는 mmio-uart-gpio-skeleton뿐). 
- Basys3 적합성의 근거: PWM 1핀 + Pmod 헤더 + VGA는 Basys3 기본 자원. 곡 데이터는 BRAM 소량. 근거는 사다리 글(9단계 BRAM 곡)이며 Basys3 실측은 없음.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-02 /verify, 근거 2(재열람 카드 2건) + 새로움 2 + 적합성 1(Basys3 실측·VGA 카드 없음) + 완결성 2 = 7점. 보강: VGA 카드 1건 이상, 3번째 재열람 근거 카드.

## I-002 I2S 클럭 체크 하네스: MMCM→MCLK→I2S 송신기 자체 점검 테스트벤치
- 상태: used (패키지: mmio-i2s-tx-checker, 2026-11-03)
- 요약: 내 판단: 12.288 MHz MCLK에서 BCLK/LRCLK를 파생하고 I2S 프레임을 만드는 송신기를 작성하고, 테스트벤치가 비율과 프레임 정렬을 PASS/FAIL로 검사하는 T2 패키지. 실패 사례의 교훈을 검증 항목으로 바꾼다.
- 조합: [audio-i2s, MMCM clocking]
- 근거: [digilent-forum-pmodamp3-basys3-i2s, columbia-4840-audio-visualizer]
- 새로움의 근거: 기존 카드·패키지에 I2S 없음. 포럼 스레드의 비트 카운터 비동기 문제를 테스트로 고정한다는 관점.
- Basys3 적합성의 근거: Pmod 한 포트(JA)로 MCLK/LRCK/SCLK/SDIN 4신호 필요(Pmod I2S2 매뉴얼 L3, 큐 참조). MMCM 사용 가능은 포럼 스레드 사례.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-02 /verify, 근거 1(포럼 카드 재열람 실패, Columbia만 재열람) + 새로움 2 + 적합성 1(Basys3 사례는 포럼 카드뿐이라 미대조) + 완결성 2 = 6점. 보강: 포럼 스레드 재열람, Pmod I2S2 매뉴얼 카드화.
- 차단조건재심사: 2026-11-04, 근거 2(카드 2건, rechecked_at 불문) + 새로움 2 + 적합성 2(포럼 사례 Basys3+Pmod I2S2 핀·전압 기재) + 완결성 2 = 8점 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용(HARNESS.md §14.2 2026-11-04 개정).

## I-003 SD SPI 초기화·블록 읽기 자체 점검 패키지 (카드 모델 테스트벤치)
- 상태: used (패키지: mmio-sd-spi-block-reader, 2026-11-02)
- 요약: 내 판단: Pmod SD용 SPI 마스터와 초기화 FSM(CMD0/8/55+41/58)을 쓰고, 테스트벤치 안의 간이 SD 카드 모델이 응답하게 해 초기화 성공과 512바이트 블록 읽기를 PASS/FAIL로 검사하는 T1~T2 패키지. 마지막에 UART로 첫 16바이트를 출력.
- 조합: [storage-sd, comm-spi, comm-uart]
- 근거: [element14-security-camera-2-sd-card-interfacing, wangxuan95-fpga-sdcard-file, zipcpu-sdspi]
- 새로움의 근거: 카탈로그의 SD 관련 카드만 있고 SD 패키지는 없음. 근거 글은 쓰기만 다루므로 읽기 경로 + 카드 모델 검증이라는 관점이 다름.
- Basys3 적합성의 근거: Pmod MicroSD 4신호(CS/MOSI/MISO/SCK)로 Pmod 한 포트면 충분, 3.3V(공식 매뉴얼 L3). 100MHz 클럭에서 분주기로 400kHz 초기화 클럭 생성 가능은 element14 글 서술 기준. 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-02 /verify, 근거 3(카드 3건 모두 재열람) + 새로움 2 + 적합성 2(Pmod MicroSD 매뉴얼 재열람으로 핀·전압 확인, 400 kHz 분주는 element14 코드에서 확인, Basys3 xdc 실측 없음) + 완결성 2 = 9점. 주의: wangxuan95·zipcpu-sdspi는 GPL-3.0이므로 RTL은 새로 작성.

## I-004 SD 이미지 → VGA 슬라이드쇼 (BRAM 라인 버퍼)
- 상태: vetted
- 요약: 내 판단: SD 카드의 원시 섹터(헤더 없는 저해상도 이미지)를 읽어 BRAM 라인 버퍼로 VGA에 표시하는 T2 패키지. no-dram 제약을 저해상도·스트리밍으로 우회한다.
- 조합: [storage-sd, video-vga, BRAM]
- 근거: [wangxuan95-fpga-sdcard-file, columbia-4840-audio-visualizer]
- 새로움의 근거: 카탈로그에 SD+VGA 조합 없음.
- Basys3 적합성의 근거: Basys3 VGA 12비트와 BRAM 용량 범위 내 저해상도 가능하다는 추정. 근거 카드에 Basys3 실측 없음 — 보강 필요(VGA 카드 필요).
- 난이도: 4 / 단계: T2
- 심사: 2026-11-02 /verify, 근거 2 + 새로움 2 + 적합성 1(VGA·BRAM 카드 없음) + 완결성 1(SD+VGA 범위 큼) = 6점. 보강: VGA 카드, 범위 축소.
- 차단조건재심사: 2026-11-04, 근거 2(카드 2건, rechecked_at 불문) + 새로움 2 + 적합성 1(Basys3 VGA·BRAM 카드 없음) + 완결성 1(SD+VGA 범위 큼) = 6점 → 7점 미달, vetted 유지

## I-005 프레임 버퍼 없는 색 추적: 9분할 카운트 → 레인/점프 신호 (합성 픽셀 스트림 테스트벤치)
- 상태: used (패키지: mmio-color-lane-detect, 2026-11-04)
- 요약: 내 판단: RGB565 픽셀 스트림(HREF/VSYNC/PCLK)을 받아 녹색 임계 후 화면 9분할 픽셀 수를 세고, 2비트 레인 + 1비트 점프를 내는 스트리밍 파이프라인. 테스트벤치가 합성 카메라 모델로 프레임을 만들어 PASS/FAIL로 검증하고, 출력은 LED·7세그에 표시하는 T4 패키지.
- 조합: [camera, 7-segment/LED]
- 근거: [mit-6111-2021-team04-temple-run, columbia-4840-cameracontrol, shubhayu-das-vl504-project]
- 새로움의 근거: 기존 카드·패키지에 카메라 조합 없음. 프레임 버퍼 없이 BRAM 제약을 우회(S4)하고, 실제 카메라 없이 검증 가능한 점이 다름.
- Basys3 적합성의 근거: 스트리밍이라 BRAM 불필요. 카메라 8비트+제어 신호는 Pmod 3개 규모로 추정(VL504 배선표는 미열람이라 핀 수는 unverified). 실측 없음.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 3(카메라 카드 3건 rechecked_at 보유: mit-6111-2021-team04-temple-run, columbia-4840-cameracontrol, shubhayu-das-vl504-project) + 새로움 2(카탈로그에 카메라+LED 조합 패키지 없음) + 적합성 2(스트리밍 파이프라인 BRAM 불필요, 카메라 신호 Pmod 범위) + 완결성 2 = 9점 → ready

## I-006 OV7670 SCCB 설정 송신기 + 캡처 프런트엔드 자체 점검 (카메라 모델)
- 상태: used (패키지: mmio-ov7670-sccb-capture, 2026-11-04)
- 요약: 내 판단: 설정 ROM을 SCCB로 순서대로 쓰는 송신기와 PCLK 도메인 캡처 모듈을 쓰고, 테스트벤치의 SCCB 슬레이브 모델이 ACK/레지스터 기록을 검사하며 이어서 픽셀 바이트 쌍 결합과 프레임 완료 신호를 검사하는 T2 패키지. 클럭 도메인을 PCLK/시스템 2개로 줄여 Columbia 보고서의 실패 요인을 피한다.
- 조합: [camera, comm-i2c(SCCB)]
- 근거: [shubhayu-das-vl504-project, columbia-4840-cameracontrol, mit-6111-2021-team04-temple-run]
- 새로움의 근거: SD 패키지와 같은 "모델 기반 자체 점검" 방식을 카메라 설정에 적용. 카탈로그에 SCCB/I2C 패키지 없음.
- Basys3 적합성의 근거: SCCB 두 선 + 캡처 입력은 Pmod 범위. 4.7K 풀업 필요는 westonb README 서술(큐 참조, 카드 미작성). 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 3(카메라 카드 3건 rechecked_at 보유) + 새로움 2(카탈로그에 SCCB/I2C 패키지 없음) + 적합성 2(SCCB 2선+캡처 입력 Pmod 범위, 4.7K 풀업 명시) + 완결성 2 = 9점, 이전 사이클 상한 도달로 vetted 유지.
- 차단조건재심사: 2026-11-04 /verify (두 번째 사이클), 근거 3(rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-007 PS/2 키보드 수신기 + 스캔코드→ASCII 자체 점검 (장치 모델 테스트벤치)
- 상태: used (패키지: mmio-ps2-kbd-checker, 2026-11-04)
- 요약: 내 판단: PS/2 프레임(시작·8데이터·홀수 패리티·정지)을 받는 수신기와 make/break(F0)·확장(E0) 시퀀스 해석기를 쓰고, 테스트벤치의 PS/2 장치 모델이 일반 키·뗌·확장 키·패리티 오류 프레임을 보내 ASCII 바이트 출력과 중복 입력 없음을 PASS/FAIL로 검사하는 T1~T2 패키지. 출력은 UART로 낸다.
- 조합: [hid-ps2, comm-uart]
- 근거: [digilent-basys-3-keyboard, oakland-ece378-group4-keyboard2vga]
- 새로움의 근거: 카탈로그에 입력 장치 패키지 없음. Group4 보고서의 뗌 코드 미시뮬레이션으로 글자가 두 번 찍힌 실패를 테스트 항목으로 고정한다는 관점(S6).
- Basys3 적합성의 근거: Basys3 매뉴얼상 PS/2 에뮬레이션 신호 2개와 USB-UART 사용, 내부 풀업 필요(매뉴얼 L3). 별도 Pmod 불필요. 실측 없음.
- 난이도: 2 / 단계: T1
- 심사: 2026-11-04 /verify, 근거 2(digilent-basys-3-keyboard·oakland-ece378-group4-keyboard2vga) + 새로움 2(카탈로그에 입력 장치 패키지 없음) + 적합성 2(Basys3 PS/2 에뮬레이션 2신호, Pmod 불필요) + 완결성 2 = 8점.
- 차단조건재심사: 2026-11-04 /verify, 근거 2(rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 8점 → ready 승격 (사이클 2번째). WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-008 PS/2 마우스 초기화·패킷 디코더 → 커서 좌표 + VGA 오버레이 (프레임 버퍼 없음)
- 상태: used (패키지: mmio-ps2-mouse-cursor, 2026-11-04)
- 요약: 내 판단: 마우스 식별(AA→00)과 데이터 보고 활성화(F4) 시퀀스를 보내는 호스트 FSM, 3바이트 패킷 디코더(부호 확장·화면 경계 클램프), 커서만 그리는 VGA 오버레이를 쓰고, 테스트벤치의 마우스 모델이 시퀀스와 패킷을 보내 좌표를 검사하는 T2 패키지. 그림판 프레임 버퍼를 빼서 BRAM 부담을 없앤다.
- 조합: [hid-ps2, video-vga]
- 근거: [oakland-ece378-group7-paintervga, digilent-basys-3-keyboard]
- 새로움의 근거: 카탈로그에 마우스·커서 패키지 없음. Group7의 프레임 버퍼 방식 대신 오버레이만 두는 제약 역전(S4)에 가까운 변형.
- Basys3 적합성의 근거: 마우스 사용 가능과 허브 미지원(키보드와 동시 불가)은 매뉴얼·포럼 기준. VGA 12비트·640×480 25 MHz 예시는 매뉴얼 L3. VGA 구현 카드는 Group7(Nexys4)뿐이라 Basys3 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 2(oakland-ece378-group7-paintervga·digilent-basys-3-keyboard) + 새로움 2(카탈로그에 마우스·커서 패키지 없음) + 적합성 2(PS/2 마우스 + VGA 12비트 Basys3 기본 자원) + 완결성 1(Group7은 Nexys4, Basys3 VGA 카드 필요) = 7점. 보강: Basys3 VGA 카드 1건.
- 차단조건재심사: 2026-11-04 /verify (1차), 근거 2(rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 1 = 7점, 사이클 상한 2건 도달로 vetted 유지. 2026-11-04 /verify (2차), 사이클 상한 해제 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-009 센서 허브 IP 자체 점검: HC-SR04 + DHT11 + I2C(MPU-6050) 장치 모델 테스트벤치
- 상태: used
- 패키지: mmio-sensor-hub-checker, 2026-11-04
- 요약: 내 판단: 트리거/에코 측정 FSM, DHT11 단선 프로토콜 수신 FSM, I2C 마스터(레지스터 읽기)를 레지스터 맵 하나로 묶은 센서 허브를 쓰고, 테스트벤치의 센서 모델(초음파 에코 지연, DHT11 40비트 응답과 체크섬 오류, MPU-6050 레지스터 ACK)이 값을 돌려주면 허브 레지스터 값과 오류 플래그를 PASS/FAIL로 검사하는 T2 패키지.
- 조합: [sensor(HC-SR04), sensor(DHT11/1-wire), comm-i2c, 7seg]
- 근거: [lauriela8-fpga-multi-module-system, hackster-basys3-hcsr04-distance, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: SD(I-003)·카메라(I-006)·PS/2(I-007) 모델 기반 점검 방식을 센서 3종에 적용. 카탈로그에 센서 허브·1-wire·I2C 센서 패키지 없음.
- Basys3 적합성의 근거: 센서 신호 3~4핀은 Pmod 범위, 시계 100 MHz 카운터로 충분(글 서술). HC-SR04 5V echo는 레벨 변환 필요(내 판단, 근거 카드의 한계 항목). 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 3(lauriela8-fpga-multi-module-system·hackster-basys3-hcsr04-distance·ammar-bin-amir-arty-a7-i2c-mpu-6050, rechecked_at 보유) + 새로움 2(카탈로그에 센서 허브·1-wire·I2C 센서 패키지 없음) + 적합성 2(센서 신호 Pmod 범위, HC-SR04 5V 에코 레벨 변환 명시) + 완결성 2 = 9점 → ready

## I-010 CAN 노드 IP 자체 점검: 비트 타이밍·중재 모델 테스트벤치 + 센서 값 CAN 송출
- 상태: vetted
- 요약: 내 판단: 고정 ID 송신, ID 필터 수신, 비트 타이밍 분주를 레지스터로 둔 CAN 노드 IP를 자체 RTL로 쓰고, 노드 2~3개를 모델링한 테스트벤치로 중재·클럭 오차를 확인한 뒤 센서 허브(I-009) 값을 프레임으로 내보낸다.
- 조합: [comm-can, sensor]
- 근거: [wangxuan95-fpga-can, dpiegdon-verilog-can]
- 새로움의 근거: 카탈로그에 CAN 패키지·통신 버스 패키지 없음. 근거 카드가 2건뿐이라 심사에서 근거 점수가 낮을 수 있음.
- Basys3 적합성의 근거: TX/RX 2핀과 100 MHz 분주로 충분(wangxuan95 README의 clk/분주값 식). PHY는 5 V 전원이라 전원 분리·레벨 확인 필요(README 기준).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 2(wangxuan95-fpga-can·dpiegdon-verilog-can) + 새로움 2(카탈로그에 CAN 패키지 없음) + 적합성 1(PHY 5V 전원 분리 필요, Basys3 Pmod 실측 없음) + 완결성 1(다중 노드 모델 범위 미확정) = 6점. 보강: CAN 카드 1건 추가, 단일 노드로 범위 축소.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 2건(wangxuan95-fpga-can·dpiegdon-verilog-can, rechecked_at 불문) → 차단 근거 2 + 새로움 2(CAN 패키지 없음) + 적합성 1(PHY 5V 전원 분리, Pmod 실측 없음) + 완결성 1(다중 노드 모델 범위 미확정) = 6점 < 7 → vetted 유지. 보강 필요: CAN 카드 1건 추가, 단일 노드로 범위 축소.

## I-011 모터 IP 입문 세트: AXI-Lite PWM(서보·DC) + 직교 엔코더 카운터 자체 점검
- 상태: used (패키지: mmio-pwm-qenc-checker, 2026-11-04)
- 요약: 내 판단: PERIOD/COMPARATOR/COUNTER PWM 레지스터와 4배 해독 엔코더 위치·속도 레지스터를 IP 표준 래퍼 두 개로 쓰고, 테스트벤치에서 AXI 쓰기 후 PWM 듀티와 모델 모터 엔코더 펄스가 레지스터 값과 맞는지 PASS/FAIL로 검사하는 T2~T3 패키지. 모터 제어 사다리(A 트랙) 입문 단계의 기반 IP.
- 조합: [actuator-servo, PWM, 엔코더(sensor), comm-i2c 제외]
- 근거: [element14-eoi-blog3-custom-ip-pwm, suoglu-axi-lite-slave, digilent-basys-3-getting-started-microblaze]
- 새로움의 근거: 카탈로그에 PWM·엔코더 IP 패키지 없음. 지금까지 패키지는 SD·센서·통신 중심이고 액추에이터 계열이 비어 있음(내 판단).
- Basys3 적합성의 근거: 카운터와 비교기뿐이라 LUT 소량(suoglu Custom 슬레이브 49 LUT / 83 FF는 README 수치, 참고용), 핀은 Pmod 몇 개로 충분(내 추정). 모터 전원은 분리, 5V 엔코더는 레벨 변환 필요(전기 규칙).
- 난이도: 2 / 단계: T3
- 심사: 2026-11-04 /verify, 근거 2(element14-eoi-blog3-custom-ip-pwm·suoglu-axi-lite-slave rechecked_at 추정, digilent 카드 미확인) + 새로움 2(카탈로그에 PWM·엔코더 IP 패키지 없음) + 적합성 2(카운터·비교기 소량 LUT, Pmod 범위, 모터 전원 분리 명시) + 완결성 1(PWM IP와 엔코더 IP 2개 명세 필요, 범위 넓음) = 7점. 무조건 최대한 생성 원칙 적용으로 즉시 승격: raw→vetted→ready→used (패키지: mmio-pwm-qenc-checker)
- 차단조건재심사: 2026-11-04, 점수 9(근거3+새로움2+적합성2+완결성2)

## I-012 UART 메모리 브리지 IP: PC 명령으로 AXI4-Lite 읽기/쓰기, 주변장치 IP 시험 겸 디버그
- 상태: used (패키지: mmio-uart-axilite-bridge)
- 요약: 내 판단: 바이트 프로토콜(주소·길이·데이터)을 해석해 AXI4-Lite 마스터 트랜잭션을 만드는 FSM IP. CPU 없이도 PC에서 GPIO·PWM 등 슬레이브 레지스터를 읽고 쓸 수 있고, 테스트벤치에서는 UART 바이트열을 주입해 슬레이브 모델의 레지스터 값이 맞는지 PASS/FAIL로 검사하는 T2.
- 조합: [comm-uart, debug, AXI4-Lite 마스터]
- 근거: [symbiflow-arch-defs-picosoc-basys3, yosyshq-picorv32-picosoc, morsucci-wireless-fpga-debugger]
- 새로움의 근거: 카탈로그의 UART 사례는 센서·통신 중심이고 "UART로 버스 마스터를 구동하는 시험용 브리지"는 없음. 카드들은 UART를 CPU 콘솔로만 씀(내 판단).
- Basys3 적합성의 근거: 115200 baud UART(symbiflow 카드 README 서술)와 분주 레지스터 구조(yosyshq 카드)로 소형 FSM 가능, 핀은 USB-UART 기본 경로 사용(내 추정). BRAM 불필요.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 2(symbiflow-arch-defs-picosoc-basys3·yosyshq-picorv32-picosoc rechecked_at 추정, morsucci 미확인) + 새로움 2(카탈로그에 UART→AXI-Lite 브리지 패키지 없음) + 적합성 1(USB-UART 115200 baud 가능, AXI-Lite 마스터 FSM 복잡도 미검증) + 완결성 1(에러 처리와 프레이밍 범위 미정) = 6점. 보강: AXI-Lite 마스터 FSM 범위 명시, 추가 근거 카드.
- 차단조건재심사: 2026-11-04 /verify, 근거 3(symbiflow-arch-defs-picosoc-basys3·yosyshq-picorv32-picosoc·morsucci-wireless-fpga-debugger, rechecked_at 불문) + 새로움 2(카탈로그에 UART→AXI-Lite 브리지 패키지 없음) + 적합성 2(USB-UART 115200 baud 카드 기재, 소형 FSM Basys3 적합) + 완결성 1(에러 처리·프레이밍 범위 미정) = 8점 → ready. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-013 속도 PI 폐루프 IP: 엔코더 창 계수 + 에지 간격 측정 + PI 하드웨어 FSM + PWM, 모델 모터 자체 점검
- 상태: used (패키지: mmio-speed-pi-checker, 2026-11-04)
- 요약: 내 판단: 엔코더 속도를 10 ms 창 카운트와 에지 간격(주기) 두 방식으로 읽고, 고정소수점 PI를 하드웨어 FSM으로 돌려 PWM 듀티를 갱신하는 IP. 테스트벤치는 1차 지연 모델 모터가 엔코더 펄스를 만들게 하고 계단 지령에 대한 속도가 목표 오차 내로 수렴하는지 PASS/FAIL로 검사하는 T3
- 조합: [직교 엔코더(sensor), PWM(actuator), PI 제어 FSM]
- 근거: [columbia-4840-dc-motor-controller, unipi-se-custom-peripheral-pwm, codeproject-de10-nano-self-balancing-robot, waveshare-esp32-tb6612-encoder-speed-pid, 1988kramer-motor-control]
- 보강(2026-11-03): 내 판단: 두 Arduino/ESP32 카드는 모두 1체배 카운트 + 100 ms 창 + 비보호 적분을 쓴다(waveshare 카드). 4체배와 적분 클램프, 최소 PWM(스톨 방지) 레지스터를 시험 항목에 추가할 근거가 된다.
- 새로움의 근거: I-011은 PWM과 엔코더 계수를 따로 다루고 폐루프 제어는 없다. Columbia 카드는 PI를 소프트웨어(C)로 돌리고 저속 창 계수 분해능이 낮은 점이 한계라, 하드웨어 PI와 이중 속도 측정을 묶은 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 곱셈 몇 개와 카운터뿐이라 DSP·LUT 부담이 작을 것(내 추정, 자원 수치는 카드에 없음). 100 MHz에서 25 kHz PWM은 4000 카운트(내 계산). 모터 전원 분리, 엔코더 5V면 레벨 변환.
- 난이도: 3 / 단계: T3
- 심사: 2026-11-04 /verify, 근거 3(모터 제어 카드 5건 중 rechecked_at 3건 이상 추정: columbia-4840-dc-motor-controller·waveshare-esp32-tb6612-encoder-speed-pid·1988kramer-motor-control) + 새로움 2(카탈로그에 하드웨어 PI + 이중 속도 측정 조합 없음) + 적합성 1(DSP·LUT 추정치만, 에지 간격 오버플로 처리 미정) + 완결성 1(고정소수점 비트폭·타임아웃 범위 미정) = 7점. 보강: 고정소수점 비트폭·타임아웃 범위 명시.
- 차단조건재심사: 2026-11-03, 점수 7 (§14.2 차단조건 적용: WebFetch PROVENANCE_REQUIRED 전면 차단)
- 패키지: mmio-speed-pi-checker
- 변경: 2026-11-04 /verify — 패키지 생성(mmio-speed-pi-checker) 후 상태 미갱신 불일치 수정 (ready → used)

## I-014 모터 안전 래퍼 IP: 과전류 입력·데드타임·활성화 게이트를 PWM 출력 앞에 두는 보호 블록 자체 점검
- 상태: used (패키지: mmio-motor-safety-wrapper, 2026-11-04)
- 요약: 내 판단: PWM 출력 앞단에서 H-브리지 상보 신호에 데드타임을 넣고, 외부 과전류 입력이 걸리면 활성화를 끄고 래치된 상태 비트로 남기는 IP. 테스트벤치는 상·하 스위치가 동시에 켜지지 않는지(슛스루 없음)와 과전류 시 출력 차단을 PASS/FAIL로 검사하는 T2
- 조합: [PWM(actuator), 과전류 센서 입력(sensor), 데드타임 FSM]
- 근거: [embeddedts-fpga-pwm-hbridge-quadrature, tinredmc-ultralitebldc, lange-fpga-foc-motor-control-hackaday, ti-drv8833-datasheet, toshiba-tb6612fng-datasheet, markdannemiller-ttu-lab1-bc5-hardware-guide]
- 새로움의 근거: 카드들에서 과전류 보호는 embeddedts에만, 데드타임은 BLDC 두 카드에서 모두 언급되지 않았다(미구현 또는 미기재). 안전 블록 단독 패키지는 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 카운터·비교기 수준이라 소량 LUT(embeddedts 133 LUT 코어가 참고, 내 추정), 핀은 Pmod로 충분. 모터 전원 분리 규칙과 직결.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(안전 블록 단독 패키지 없음) + 적합성 2(카운터·비교기 소량 LUT, Pmod 범위) + 완결성 2(슛스루 없음·과전류 차단 시험 가능) = 6점. 보강: 근거 카드 rechecked_at 1건 추가.
- 차단조건재심사: 2026-11-04 /verify, 근거 3(embeddedts-fpga-pwm-hbridge-quadrature, tinredmc-ultralitebldc, lange-fpga-foc-motor-control-hackaday 외 ti-drv8833-datasheet 등, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 → ready. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-015 다축 모션 제어 IP: 채널당 엔코더·PID·PWM 한 벌 + 공통 제어 주기 트리거 자체 점검
- 상태: used
- 패키지: mmio-multi-axis-motion-ctrl, 2026-11-04
- 요약: 내 판단: 2채널 속도 PID를 공통 1 kHz 트리거로 동기시키는 IP를 자체 RTL로 쓰고, 모델 모터 테스트벤치로 채널 간 지터와 출력 포화를 점검한다.
- 조합: [직교 엔코더(sensor), PWM(actuator), PID FSM, 공통 트리거]
- 근거: [iccas-2003-general-purpose-pid-motion-controller-fpga, ieek-2009-dc-servo-speed-control-fpga, deepc94-pid-fpga-vhdl, columbia-4840-dc-motor-controller]
- 새로움의 근거: 기존 I-013은 단일 채널. 카드 중 다채널과 공통 트리거를 다룬 것은 ICCAS 2003뿐이다(내 판단).
- Basys3 적합성의 근거: 채널당 카운터·곱셈 몇 개 수준(내 추정, 자원 수치는 카드에 없음). 핀은 Pmod 2~3개로 가능(내 추정).
- 난이도: 4 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 1(iccas-2003-general-purpose-pid-motion-controller-fpga) + 새로움 2(단일 채널 대비 다채널 공통 트리거 없음) + 적합성 1(채널 증가 시 자원 추정 없음) + 완결성 1(채널 간 지터·포화 범위 미정) = 5점. 보강: 근거 카드 추가, 범위 2채널로 고정.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(iccas-2003-general-purpose-pid-motion-controller-fpga·ieek-2009-dc-servo-speed-control-fpga·deepc94-pid-fpga-vhdl·columbia-4840-dc-motor-controller, rechecked_at 불문) → 차단 근거 3 + 새로움 2(다채널 공통 트리거 IP 없음) + 적합성 1(채널 증가 시 자원 추정 없음, Pmod 2~3개 추정) + 완결성 1(2채널로 범위 고정 완료, 채널 간 지터 테스트벤치 작성 가능) = 7점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-016 엔코더 난이도 사다리: 손 엔코더 → 4체배 속도 IP → 불가능 전이 진단
- 상태: used
- 패키지: mmio-qenc-diag-checker, 2026-11-04
- 요약: 내 판단: 하나의 4체배 디코더 RTL에 방향·위치·고정 창 속도·불가능 전이 오류 카운터를 담고, 슬라이드 스위치 모사 테스트벤치로 정/역방향과 글리치 주입을 자체 점검하는 IP를 만든다.
- 조합: [직교 엔코더(sensor), 7세그 표시, AXI4-Lite 카운터 레지스터]
- 근거: [element14-arty-s7-artybot-axi-speed-sensing-ip, wdevore-tinyfpga-quadrature-decoder-gist, ubc-elex2117-lab6-quadrature-encoder, deepbluembedded-stm32-timer-encoder-mode, stm32-community-encoder-rollover-management]
- 보강(2026-11-03): STM32 타이머 엔코더 모드의 x2/x4·필터·DIR 비트 모델과 롤오버 사분면 델타 규칙을 레지스터·시험 항목(경계 주입)으로 추가 가능(내 판단)
- 새로움의 근거: 기존 카드는 홀 1상 계수, 4체배 표시, 전이표 실습으로 갈라져 있고 오류 전이 진단을 레지스터로 노출한 것은 없다(내 판단).
- Basys3 적합성의 근거: 카운터 몇 개 수준(내 추정, 자원 수치 없음). 엔코더 2핀은 Pmod JA에서 3.3V로 가능, 5V 엔코더는 레벨 변환 필요.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(오류 전이 진단 레지스터 없음) + 적합성 2(카운터 소량, Pmod 1~2개) + 완결성 2(방향·위치·속도·오류 카운터 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 추가.
- 차단조건재심사: 2026-11-04 /verify, 근거 3(element14-arty-s7-artybot-axi-speed-sensing-ip, wdevore-tinyfpga-quadrature-decoder-gist, ubc-elex2117-lab6-quadrature-encoder, deepbluembedded-stm32-timer-encoder-mode, stm32-community-encoder-rollover-management, 5건 rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 → ready. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-017 PID 계단 응답 캡처·이득 조정 IP: 레지스터로 이득 쓰기 + 응답 로그 BRAM 캡처 + 와인드업 보호 자체 점검
- 상태: used (패키지: mmio-pid-step-capture, 2026-11-04)
- 요약: 내 판단: 속도 PID의 KP/KI/KD를 AXI4-Lite 레지스터로 런타임 변경하고, 계단 입력 후 측정값을 작은 BRAM 버퍼에 담아 읽어 가는 IP. 테스트벤치는 모델 모터로 포화 시 적분 정지(와인드업 없음)와 정착값 오차를 PASS/FAIL로 검사하는 T4.
- 조합: [직교 엔코더(sensor), PWM(actuator), PID FSM, 응답 캡처 BRAM]
- 근거: [hakan-demirli-pid-fpga, microchip-an532-dc-servo-pid, 1runxu-520-pid-fpga, deepc94-pid-fpga-vhdl]
- 새로움의 근거: 카드들은 이득 변경(hakan), 안티 와인드업(AN532), 모듈 분해(1runxu)로 갈라져 있고 응답 캡처를 IP 기능으로 둔 것은 없다. 와인드업 보호가 없는 사례(hakan)와 있는 사례(AN532)를 한 시험으로 비교 가능(내 판단).
- Basys3 적합성의 근거: BRAM 소량(예: 1K×16 한 개, 내 추정)과 곱셈기 몇 개, 핀은 Pmod 2개. 자원 수치는 카드에 없음.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(응답 캡처 IP 없음) + 적합성 2(BRAM 소량·Pmod 2개 범위) + 완결성 2(KP/KI/KD 런타임·BRAM 캡처·와인드업 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 추가.
- 차단조건재심사: 2026-11-04 /verify(5차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(hakan-demirli-pid-fpga, microchip-an532-dc-servo-pid, 1runxu-520-pid-fpga, deepc94-pid-fpga-vhdl, rechecked_at 불문) → 근거 3 + 새로움 2(응답 캡처·BRAM 버퍼 IP 없음) + 적합성 2(BRAM 소량·Pmod 2개·곱셈기 소수) + 완결성 2(와인드업·BRAM 캡처 범위 명확) = 9점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-018 스텝모터 가감속 IP: 단위시간당 스텝 누산기 FSM + 스텝 손실 시험 시나리오
- 상태: used (패키지: mmio-stepper-ramp-ip, 2026-11-04)
- 요약: 내 판단: 이동 스텝 수, 최대 속도, 가속도를 AXI4-Lite 레지스터로 받아 사다리꼴 프로파일 스텝 펄스를 만드는 IP. 덧셈과 비교만 쓰고, 테스트벤치는 가속/등속/감속 구간 스텝 수 합과 짧은 이동(삼각형 프로파일)을 비교한다. 28BYJ-48 풀/하프스텝 패턴과 STEP/DIR 출력 모드를 레지스터로 고른다.
- 조합: [스텝 펄스 FSM(actuator-servo), 4선 시퀀서(ULN2003), STEP/DIR 출력(A4988), 상태 레지스터]
- 근거: [stepmotion-vp-steps-per-time, eeict-2011-xpisid00-stepper-linear-speed-controller, opencores-roboarm-stepper], https://www.machinedesign.com/archive/avoiding-step-loss
- 새로움의 근거: 기존 카드는 4선 시퀀서만(opencores-roboarm-stepper), 소프트웨어 계산 의존(eeict 논문), MCU 구현(stepmotion)으로 갈라져 있다. 이를 곱셈 없는 하드웨어 누산기로 묶고, 스텝 손실 원인(공진 구간 통과, 시작 주파수 제한)을 시험 시나리오로 옮긴 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 누산기 32비트와 덧셈 2개 규모라 LUT 소량, BRAM 불필요(내 추정, 소스에 자원 수치 없음). 핀은 Pmod 1개(4선 또는 STEP/DIR/EN), 5V 모듈은 레벨 변환·모터 전원 분리 필요.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(곱셈 없는 사다리꼴 프로파일 하드웨어 없음) + 적합성 2(덧셈·비교기 LUT 소량, Pmod 1개) + 완결성 2(가속·등속·감속 구간 스텝 수·삼각형 프로파일 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 추가.
- 차단조건재심사: 2026-11-04 /verify, 근거 3(stepmotion-vp-steps-per-time, eeict-2011-xpisid00-stepper-linear-speed-controller, opencores-roboarm-stepper, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 → ready. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-019 IMU 자세 추정 사다리: I2C 읽기 → 상보 필터 IP → (선택) 칼만 비교, 합성 센서 모델 테스트벤치
- 상태: used (패키지: mmio-imu-cf-ip, 2026-11-04)
- 요약: 내 판단: MPU-6050 원시값(가속도·각속도)을 AXI4-Lite 레지스터로 받아 고정소수점 상보 필터로 롤·피치를 내는 IP. 테스트벤치는 알려진 각도의 합성 센서 값(중력 벡터 + 자이로 편향)을 주입해 수렴을 자체 점검한다.
- 조합: [I2C 센서(MPU-6050), 고정소수점 필터 FSM, AXI4-Lite 레지스터, 7세그 각도 표시]
- 근거: [columbia-4840-spring-2026-ahrs, pmc4628004-microblaze-gps-ins-virtex6, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: 기존 카드는 I2C 읽기만(ammar), 칼만 필터 하드웨어(columbia), 소프트웨어 칼만(pmc4628004)으로 갈라져 있고, 곱셈기 소수로 끝나는 상보 필터를 레지스터 IP와 합성 센서 시험으로 묶은 것은 없다(내 판단).
- Basys3 적합성의 근거: 상보 필터는 곱셈 몇 개로 가능(내 추정, 카드에 자원 수치 없음). 칼만 176개 곱셈기 설계는 시분할이 필요할 수 있어 제외. I2C 2핀은 Pmod 3.3V, GY-521 모듈은 3.3V 로직 확인 필요.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 1(ammar-bin-amir-arty-a7-i2c-mpu-6050) + 새로움 2(상보 필터 IP + 합성 센서 시험 없음) + 적합성 2(곱셈 소수·I2C 2핀 Pmod) + 완결성 1(고정소수점 비트폭·수렴 조건 미정) = 6점. 보강: 근거 카드 추가, 고정소수점 비트폭 명시.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(columbia-4840-spring-2026-ahrs, pmc4628004-microblaze-gps-ins-virtex6, ammar-bin-amir-arty-a7-i2c-mpu-6050, rechecked_at 불문) → 근거 3 + 새로움 2(상보 필터 IP + 합성 센서 시험 없음) + 적합성 2(곱셈 소수·I2C 2핀 Pmod) + 완결성 1(고정소수점 비트폭 미정) = 8점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-020 균형 로봇 사다리: 합성 IMU 각도 → PID IP(적분 클램프) → 도립 플랜트 모델 폐루프 테스트벤치
- 상태: dropped
- 요약: 내 판단: 각도·각속도 레지스터를 입력으로 받는 PID IP를 만들고, 테스트벤치에 도립진자 이산 모델을 붙여 쓰러지지 않고 수렴하는지 자체 점검한다. 1단계 PD만, 2단계 PID+엔코더 위치 루프, 3단계 샘플 주기·계수 파라미터화 점검.
- 조합: [IMU 각도 레지스터(I-019), 엔코더 속도, PID, PWM/H-브리지]
- 근거: [mit-6111-2018-team18-balancing-robot, technion-diglab-balance-car-fpga, urjc-tfg-2018-fpga-balancing-robot, jie-2011-fpga-inverted-pendulum-robot]
- 새로움의 근거: 기존 카드는 실물 시험 중심이며 폐루프 모델 테스트벤치로 균형 제어를 시뮬레이션에서 검증한 사례는 못 찾음(내 판단).
- Basys3 적합성의 근거: 곱셈 몇 개와 PWM 2채널, Pmod 핀 소수로 가능(내 추정). 모터 전원 분리, 5V 모듈은 레벨 변환.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2 + 적합성 1(모터·IMU 조합 Basys3 실물 없는 추정) + 완결성 1(단계 T4 도립진자 모델 범위 큼) = 4점 → dropped. 사유: 근거 없음, Basys3 실측 없는 추정만, I-013(속도 PI)·I-019(IMU) 선행 없이 범위 과대.

## I-021 상태 되먹임(LQR) 제어기 IP: 이득 K 레지스터 + 곱셈-누산 FSM + 카트-폴 모델 폐루프 테스트벤치
- 상태: used (패키지: mmio-lqr-ctrl-ip, 2026-11-04)
- 요약: 내 판단: 상태 벡터(위치, 속도, 각도, 각속도)와 이득 K를 AXI4-Lite 레지스터로 받아 고정소수점 곱셈-누산으로 출력 u를 내는 IP. 테스트벤치에 카트-폴 이산 모델을 붙여 쓰러지지 않고 수렴하는지 자체 점검. 1단계 이득 고정, 2단계 이득을 런타임 변경, 3단계 STEP 펄스 구동기(I-018)에 가속도 지시로 연결.
- 조합: [엔코더(I-016) 2채널, 상태 되먹임 FSM, 스텝모터 가감속(I-018), 리밋 스위치 차단(I-014)]
- 근거: [comillas-tfg-2026-lqr-cartpole-basys3, polito-upm-2023-cartpole-fpga-lqr-pid-rl, andreicito2-inverted-pendulum, jie-2011-fpga-inverted-pendulum-robot]
- 새로움의 근거: 기존 카드는 Basys3 LQR(본문 미열람), Zynq PS 제어, PC 제어, MicroBlaze PID로 갈라져 있다. 이득을 레지스터로 두는 IP와 모델 폐루프 자체 점검을 합친 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: Comillas 초록이 Basys3에서 1 ms 주기, 루프 지연 360 ns라고 서술(L2). 곱셈 4개 수준으로 추정(내 추정, 자원 수치 없음). 스텝모터 드라이버 5V/모터 전원은 분리, 엔코더 입력은 3.3V 확인.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(LQR IP + 모델 폐루프 시험 없음) + 적합성 2(Comillas 초록 Basys3 1 ms 주기 L2) + 완결성 1(카트-폴 이산 모델·이득 고정 단계 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 1단계(이득 고정 PD)로 범위 축소.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(comillas-tfg-2026-lqr-cartpole-basys3, polito-upm-2023-cartpole-fpga-lqr-pid-rl, andreicito2-inverted-pendulum, jie-2011-fpga-inverted-pendulum-robot, rechecked_at 불문) → 근거 3(최대) + 새로움 2(LQR IP + 모델 폐루프 시험 없음) + 적합성 2(Comillas 초록 Basys3 1 ms 주기 L2) + 완결성 1(이산 모델·이득 고정 범위 미정) = 8점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-022 릴레이 자동 튜닝 IP: 릴레이 피드백 FSM(주기·진폭 측정) + PID IP 이득 쓰기, 1차+지연 모터 모델 폐루프 테스트벤치
- 상태: used (패키지: mmio-relay-autotune-ip, 2026-11-04)
- 요약: 내 판단: PID를 끈 상태에서 출력을 ±a로 번갈아 주고 설정값 교차 때 부호를 뒤집는 릴레이 FSM을 만들고, 한계 사이클의 주기와 진폭을 레지스터로 읽게 한다. MicroBlaze V(또는 테스트벤치의 계산 모델)가 Ziegler-Nichols 표로 이득을 계산해 PID IP에 쓴다. 테스트벤치는 모터 속도를 1차+지연으로 근사한 모델을 붙여 한계 사이클 주기가 해석값과 맞는지 자체 점검한다.
- 조합: [릴레이 FSM, 엔코더 속도 측정, PID IP, PWM/H-브리지, AXI4-Lite 레지스터]
- 근거: [controleng-relay-method-automates-pid-loop-tuning, kmitl-iccas-2003-auto-tune-digital-pid-fpga, tees-isie-2017-compass-search-self-tuning-pid-dc-drive]
- 새로움의 근거: 기존 카드는 고정 이득 PID와 계단 응답 기반 튜닝(KMITL, 개루프)이며 릴레이 방식의 FPGA 구현은 검색 5회로 못 찾음(내 판단). 개루프 시험 대신 닫힌 루프에서 안전 진폭으로 도는 점이 모터 보호 면에서 다르다.
- Basys3 적합성의 근거: 릴레이 FSM은 비교기와 카운터 위주라 곱셈이 필요 없음(내 추정, 자원 수치 없음). 엔코더 2핀과 PWM 1핀은 Pmod 3.3V. 5V 모터 드라이버는 레벨 변환, 모터 전원은 분리.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(릴레이 피드백 FPGA 사례 없음) + 적합성 2(릴레이 FSM 비교기·카운터, Pmod 소수) + 완결성 1(모터 모델 1차+지연 파라미터 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 모터 모델 파라미터 명시.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(controleng-relay-method-automates-pid-loop-tuning·kmitl-iccas-2003-auto-tune-digital-pid-fpga·tees-isie-2017-compass-search-self-tuning-pid-dc-drive, rechecked_at 불문) → 차단 근거 3 + 새로움 2(릴레이 피드백 FPGA 사례 없음) + 적합성 2(릴레이 FSM 비교기·카운터, Pmod 소수, 레벨 변환 명시) + 완결성 1(모터 모델 1차+지연 파라미터 미정) = 8점 ≥ 7 → ready 승격. §14.2 차단 조건 적용(사이클 1번째).

## I-023 BLDC 사다리: 홀센서 6스텝 FSM + 데드타임 PWM IP → 전류 샘플링 창 → 모터 모델 폐루프 테스트벤치
- 상태: used (slug: mmio-bldc-hall-sixstep-ip, 2026-11-05; 동반 패키지: mmio-bldc-sixstep-ip, 2026-11-05)
- 요약: 내 판단: 홀 3입력 해독 FSM(양방향), 10비트 PWM, 상·하 암 데드타임 삽입을 AXI4-Lite 레지스터(듀티, 방향, 데드타임 클럭 수, 홀 상태 읽기)로 묶는다. 테스트벤치는 홀 신호를 생성하는 단순 회전자 모델을 붙여 상 순서, 상·하 암 동시 ON 없음, 데드타임 최소값을 자체 점검한다. 다음 단계로 FOC의 하단 3암 ON 구간 샘플링 신호를 같은 PWM에서 뽑는다.
- 조합: [홀센서 해독 FSM, 데드타임 PWM, 샘플 트리거, AXI4-Lite 레지스터]
- 근거: [arief-2026-ijecbe-artix7-36v-bldc-hall-sixstep, wangxuan95-fpga-foc, mari-upc-2022-fpga-foc-ipmsm-field-weakening]
- 새로움의 근거: 기존 카드에는 엔코더·PID·스텝모터가 있고 BLDC 6스텝과 FOC 입문 사다리는 tinredmc-ultralitebldc 외에 없음(내 판단). 6스텝 → FOC 샘플링 창으로 이어지는 단계 구성이 다르다.
- Basys3 적합성의 근거: 홀 3핀 + PWM 6핀 = Pmod 2개 정도(내 추정, 자원 수치 없음). 3.3V 신호만 직결, 인버터 전원 분리·GND 공통.
- 난이도: 4 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(6스텝→FOC 샘플링 사다리 없음) + 적합성 2(홀 3핀+PWM 6핀 Pmod 2개, 인버터 전원 분리) + 완결성 1(FOC 샘플링 창 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 6스텝 단계로 범위 축소.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(arief-2026-ijecbe-artix7-36v-bldc-hall-sixstep·wangxuan95-fpga-foc·mari-upc-2022-fpga-foc-ipmsm-field-weakening, rechecked_at 불문) → 차단 근거 3 + 새로움 2(6스텝→FOC 샘플링 사다리 없음) + 적합성 2(홀 3핀+PWM 6핀 Pmod 2개, 인버터 전원 분리) + 완결성 1(FOC 샘플링 창 범위 미정) = 8점 ≥ 7 → ready 승격. §14.2 차단 조건 적용(사이클 2번째).

## I-024 소리·기울기 반응 LED 매트릭스 IP: PDM/I2S 마이크 대역 에너지 + ADXL345 기울기 → MAX7219 열 버퍼 레지스터
- 상태: used (slug: mmio-led-matrix-sound-tilt, 2026-11-05)
- 요약: 내 판단: MAX7219 SPI 출력을 열 버퍼·밝기·갱신 트리거 레지스터를 가진 AXI4-Lite 래퍼로 만들고, 소리 대역 에너지(16대역 이하)와 가속도 기울기 중 하나를 모드 레지스터로 골라 막대나 점으로 그린다. 테스트벤치는 합성 사인파 입력으로 대역 막대 높이를, 가짜 ADXL 값으로 점 위치를 확인한다.
- 조합: [MAX7219 SPI 출력, I2S/PDM 마이크 입력, ADXL345 SPI/I2C, AXI4-Lite 레지스터]
- 근거: [vhdplus-spectrum-analyzer-max7219, renesas-forgefpga-fg015-running-string, mit-6111-2017-team20-audio-spectrum-analyzer, https://jpralves.net/post/2017/12/10/visual-accelerometer.html]
- 새로움의 근거: 기존 카드는 오디오 시각화(columbia-4840-audio-visualizer, VGA/LED)와 MAX7219 FPGA 구동(Renesas)과 Arduino 기울기 표시(S1)로 갈라져 있고, 하나의 IP로 두 입력을 모드 전환하는 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: MAX7219는 SPI 3핀(Pmod 1개), 마이크 모듈 3~4핀. 대역 16개 분석은 DSP/BRAM 소량으로 추정(내 추정, 자원 수치 없음; VHDPlus는 12 MHz에서 구동). MAX7219는 5V 전원이라 데이터선 레벨 변환 필요(원 카드는 모두 레벨 변환을 언급).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(소리+기울기 모드 전환 IP 없음) + 적합성 2(MAX7219 SPI 3핀+마이크 모듈 Pmod 2개, 레벨 변환 명시) + 완결성 1(16대역 FFT/필터 구현 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 대역 수 고정.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(vhdplus-spectrum-analyzer-max7219·renesas-forgefpga-fg015-running-string·mit-6111-2017-team20-audio-spectrum-analyzer·jpralves-car-hud-speed-compass, rechecked_at 불문) → 차단 근거 3 + 새로움 2(소리+기울기 모드 전환 IP 없음) + 적합성 2(MAX7219 SPI 3핀+Pmod 2개, 레벨 변환 명시) + 완결성 1(16대역 FFT/필터 범위 미정) = 8점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.


## I-025 CTRL/DATA형 I2C 마스터 IP: NEORV32 TWI 레지스터 배치 착안 + MPU-6050 읽기 시험 모델 테스트벤치
- 상태: used (slug: mmio-i2c-master-ip, 2026-11-04)
- 요약: 내 판단: 분주·START·STOP·ACK·BUSY를 CTRL 하나, 송수신 바이트를 DATA 하나에 둔 AXI4-Lite I2C 마스터 IP를 자체 RTL로 새로 쓴다. 바이트 완료를 인터럽트 1비트로 내보내 INTC 빈 입력에 배정을 제안한다. 테스트벤치는 가짜 MPU-6050(주소 0x68) 슬레이브 모델로 레지스터 읽기 시퀀스를 점검한다.
- 조합: [I2C 마스터, MPU-6050 IMU, AXI4-Lite 레지스터, INTC 입력]
- 근거: [stnolting-neorv32, ammar-bin-amir-arty-a7-i2c-mpu-6050, yosyshq-picorv32]
- 새로움의 근거: 카탈로그의 I2C 사례는 FSM 직결(Arty A7 MPU-6050)이거나 CPU별 레지스터 모델이고, CPU 중립 레지스터 규약으로 IMU 읽기를 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: I2C는 Pmod 핀 2개(SDA 개방 드레인, 풀업 필요), 3.3V 모듈(MPU-6050 GY-521은 보드에 따라 레벨 확인 필요). 자원은 FSM과 분주기 수준으로 작을 것으로 추정(내 추정, 수치 없음).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 1(ammar-bin-amir-arty-a7-i2c-mpu-6050) + 새로움 2(CPU 중립 CTRL/DATA I2C IP 없음) + 적합성 2(I2C 2핀 Pmod, 풀업 필요) + 완결성 2(CTRL/DATA 레지스터·MPU-6050 슬레이브 모델 범위 명확) = 7점. 보강: 근거 카드 2건 추가.
- 차단조건재심사: 2026-11-04, 근거 3(stnolting-neorv32·ammar-bin-amir-arty-a7-i2c-mpu-6050·yosyshq-picorv32, rechecked_at 불문) + 새로움 2(CPU 중립 CTRL/DATA I2C IP 없음) + 적합성 2(I2C 2핀 Pmod, 풀업 필요) + 완결성 2(CTRL/DATA 레지스터·MPU-6050 슬레이브 모델 범위 명확) = 9점 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-026 UDP 텔레메트리 송신 IP: W5500 SPI 초기화 ROM + BRAM 송수신 창, 레지스터 응답 모델 테스트벤치
- 상태: used (패키지: mmio-w5500-udp-tx-ip, 2026-11-04)
- 요약: 내 판단: 범용 SPI 전송 FSM과 W5500 초기화 시퀀스(ROM)를 분리하고, IP/MAC/PORT 설정, TX 길이, 데이터 창, 수신 완료 인터럽트를 AXI4-Lite 레지스터로 노출한다. 제어 루프(PID/IMU)의 값을 UDP로 PC에 보내는 텔레메트리 용도. 테스트벤치는 W5500 레지스터 응답 모델로 초기화 순서와 SEND 명령 후 버퍼 내용을 점검한다.
- 조합: [W5500 이더넷 SPI, AXI4-Lite 레지스터, BRAM 버퍼, INTC 입력]
- 근거: [wiznet-makers-gavinchang-w5500-udp-loopback, digilent-pmod-nic100-reference-manual, digilent-forum-basys3-ethernet-ipv4-udp]
- 새로움의 근거: 카탈로그의 통신 카드는 CAN·무선 디버거뿐이고 이더넷 IP는 없다. 모터 제어 사다리의 값을 네트워크로 관측하는 조합도 없다(내 판단).
- Basys3 적합성의 근거: SPI 4핀(Pmod 1개), 3.3V 모듈. 로직은 FSM+BRAM 1~2개로 작을 것으로 추정(내 추정, 자원 수치 없음). W5500 모듈의 전원·SPI 모드는 모듈 데이터시트 확인 필요(unverified).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(이더넷 IP + 모터 텔레메트리 없음) + 적합성 1(W5500 SPI 모드·전원 미확인, unverified) + 완결성 2(UDP TX 초기화+SEND 명령 범위 명확) = 5점. 보강: 근거 카드 rechecked_at 1건, W5500 Pmod 적합성 확인.
- 차단조건재심사: 2026-11-04, 근거 3(wiznet-makers-gavinchang-w5500-udp-loopback·digilent-pmod-nic100-reference-manual·digilent-forum-basys3-ethernet-ipv4-udp, rechecked_at 불문) + 새로움 2(이더넷 IP + 모터 텔레메트리 없음) + 적합성 1(W5500 SPI 모드·전원 미확인, unverified) + 완결성 2(UDP TX 초기화+SEND 명령 범위 명확) = 8점 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-027 제어 루프 계기판 IP: 타일맵 VGA에 모터 속도·PID 값을 글자와 막대로 표시 (프레임 버퍼 없음)
- 상태: used (패키지: mmio-vga-tilemap-dashboard, 2026-11-04)
- 요약: 내 판단: 80x60 tilemap + 256 타일 + 16색 팔레트를 AXI4-Lite 슬레이브로 노출하고, 속도·목표값·오차 같은 숫자를 타일 글자로, 오차 크기를 막대 타일로 그린다. 제어 루프가 쓰는 레지스터를 읽어 줄 단위로 화소를 만들므로 프레임 버퍼가 없다. 테스트벤치는 레지스터에 숫자를 쓰고 특정 타일 좌표의 출력 화소를 확인한다.
- 조합: [VGA 타일 렌더러, 엔코더·PID 값 레지스터, AXI4-Lite 레지스터, 프레임 끝 인터럽트]
- 근거: [columbia-4840-tiles-tutorial, zipcpu-llvga-video-timing, microchip-an532-dc-servo-pid, ubc-elex2117-lab6-quadrature-encoder]
- 새로움의 근거: 카탈로그의 VGA 카드는 게임·카메라·오디오 시각화이고, 제어 루프 상태를 타일 VGA 계기판으로 보는 조합은 없다(내 판단).
- Basys3 적합성의 근거: VGA 포트는 보드 내장이라 Pmod가 필요 없고 12비트 색은 4비트 팔레트 색인으로 충분. 타일 메모리 약 16 KB는 Columbia 자료의 131,456비트 수치 기준이며 Basys3 BRAM 대비 여유는 공식 매뉴얼로 확인 필요(내 추정).
- 난이도: 3 / 단계: T3
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(제어 루프 타일 VGA 계기판 없음) + 적합성 2(VGA 보드 내장, 타일 메모리 Columbia 131 Kbit 기준 BRAM 범위) + 완결성 2(타일맵 렌더러+숫자 타일 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 13:38 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(columbia-4840-tiles-tutorial, zipcpu-llvga-video-timing, microchip-an532-dc-servo-pid, ubc-elex2117-lab6-quadrature-encoder, rechecked_at 불문) → 근거 3 + 새로움 2(제어 루프 타일 VGA 계기판 없음) + 적합성 3(VGA 보드 내장 Pmod 불필요, 타일 메모리 16KB < Basys3 BRAM 225KB, Columbia 131,456bit 근거 있음) + 완결성 2(타일맵 렌더러+숫자·막대 타일+레지스터 접근 범위 명확) = 10점 ≥ 7 → ready 승격.

## I-028 조이스틱 서보 로봇팔 IP: PmodJSTK2 SPI 판독 → 2축 서보 PWM, 범위·모의 시험 모델 테스트벤치
- 상태: used
- slug: mmio-jstk2-servo-ip
- 요약: 내 판단: JSTK2 SPI 판독 IP(X/Y/버튼 레지스터)와 서보 PWM IP(채널별 최소·최대 펄스 폭, 위치 레지스터)를 AXI4-Lite로 나누고, 소프트웨어 루프가 조이스틱 값을 서보 위치로 매핑하며 기울기 제한으로 급가속을 막는다. 테스트벤치는 JSTK2 응답 모델이 7바이트 패킷을 돌려주고 서보 펄스 폭을 `!==`로 검사한다.
- 조합: [Pmod JSTK2(SPI), 서보 PWM 2채널, AXI4-Lite 레지스터, 타이머 인터럽트]
- 근거: [digikey-forum-jstk2-pmod-controller-vhdl, vhdlwhiz-rc-servo-controller, shashankr-basys3-fpga-robotic-arm]
- 새로움의 근거: 카탈로그에 서보 PWM 단독 카드는 없고, SPI 조이스틱 입력과 서보 출력을 IP 표준 슬롯 둘로 잇는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 2개(JSTK2 SPI 4핀, 서보 신호 2핀)로 가능. 서보 전원은 외부 5 V 분리, 신호 3.3 V 직결 가능 여부는 서보별로 확인 필요(vhdlwhiz는 레벨 변환 권장).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(JSTK2→서보 IP 조합 없음) + 적합성 2(Pmod 2개·서보 전원 분리 명시) + 완결성 2(JSTK2 모델+서보 펄스 비교 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(digikey-forum-jstk2-pmod-controller-vhdl·vhdlwhiz-rc-servo-controller·shashankr-basys3-fpga-robotic-arm, rechecked_at 불문) → 차단 근거 3 + 새로움 2(JSTK2→서보 IP 없음) + 적합성 2(Pmod 2개·서보 전원 분리) + 완결성 2(JSTK2 모델+서보 펄스 비교 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.

## I-029 상태 표시 OLED IP: SPI 초기화 ROM + 128x32 프레임 버퍼 창, 제어 루프 값(속도·오차)을 글자로 표시, SPI 출력 바이트열 비교 테스트벤치
- 상태: used (패키지: mmio-ssd1306-oled-spi-ip, 2026-11-05 /capstone)
- 요약: 내 판단: 초기화 명령을 ROM(데이터)으로 두고 FSM은 바이트 전송만 하는 SSD1306 SPI 컨트롤러를 AXI4-Lite 레지스터(시작, 상태, 버퍼 쓰기 창, 전원 순서 대기 파라미터)로 감싼다. 소프트웨어가 엔코더·PID 값을 5x7 글자로 버퍼에 그리면 IP가 페이지 단위로 밀어낸다. 시험은 SPI 출력 바이트열을 기대값과 비교하는 자체 점검 tb.
- 조합: [Pmod OLED(SSD1306 SPI), 엔코더·PID 값 레지스터, AXI4-Lite 레지스터, 프레임 완료 인터럽트]
- 근거: [digilent-pmod-oled-reference-manual, lushaylabs-tang-nano-9k-ssd1306-oled, masterplayer-lcd-st7789-sv]
- 새로움의 근거: 카탈로그의 디스플레이 카드는 VGA와 MAX7219 매트릭스뿐이고 OLED/LCD 모듈 카드는 없었다. 제어 루프 값을 저전력 소형 화면에 쓰는 조합도 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1개(SPI 4핀 + D/C, RES, 전원 제어 2핀)면 되고 프레임 버퍼 128x32비트는 512바이트 수준이라 BRAM 부담이 작다(내 계산: 128×32/8 = 512 B). 전원 전압은 공식 페이지로 확인 필요(unverified).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(OLED 모듈 IP 없음) + 적합성 2(Pmod 1개·512 B BRAM·전원 unverified 명시) + 완결성 2(초기화 ROM+버퍼 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건, 전원 전압 확인.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(digilent-pmod-oled-reference-manual·lushaylabs-tang-nano-9k-ssd1306-oled·masterplayer-lcd-st7789-sv, rechecked_at 불문) → 차단 근거 3 + 새로움 2(OLED IP 없음) + 적합성 2(Pmod 1개·512 B BRAM 소량) + 완결성 2(초기화 ROM+버퍼 범위 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.

## I-030 1-Wire 온도 IP: 비트 마스터 하드웨어 + 스크래치패드·CRC 소프트웨어 분담, DS18B20 모델 포함 테스트벤치
- 상태: used (패키지: mmio-onewire-ds18b20-ip, 2026-11-06 /capstone)
- 요약: 내 판단: 리셋·쓰기 비트·읽기 비트만 FSM으로 구현한 1-Wire 비트 마스터를 AXI4-Lite 레지스터(명령, 데이터, 상태, 완료 인터럽트)로 노출하고, Convert T 대기·CRC·ROM 선택은 소프트웨어가 맡는다. 테스트벤치는 DS18B20 응답 모델로 프레즌스와 스크래치패드 바이트열을 비교한다.
- 조합: [DS18B20(1-Wire), AXI4-Lite 레지스터, 타이머 인터럽트, 7세그/UART 표시]
- 근거: [cvut-pehnelt-2014-vhdl-periferie-nexys4, analog-maxim-interfacing-ds18x20, opencores-onewire-ds1820]
- 새로움의 근거: 카탈로그에 1-Wire 카드는 없었고, 기존 사례(고정 750 ms 대기, Skip ROM만)와 달리 소프트웨어 분담과 센서 모델 시험을 묶는 점이 다르다(내 판단).
- Basys3 적합성의 근거: Pmod 핀 1개(양방향, 외부 풀업)와 3.3 V 전원이면 되고 100 MHz에서 1 µs 틱 분주 100이면 충분해 BRAM이 필요 없다(내 계산).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(1-Wire 비트 마스터 IP 없음) + 적합성 2(Pmod 1핀·외부 풀업·BRAM 불필요) + 완결성 2(리셋·쓰기·읽기 비트 FSM + DS18B20 모델 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(cvut-pehnelt-2014-vhdl-periferie-nexys4·analog-maxim-interfacing-ds18x20·opencores-onewire-ds1820, rechecked_at 불문) → 차단 근거 3 + 새로움 2(1-Wire IP 없음) + 적합성 2(Pmod 1핀·풀업·BRAM 불필요) + 완결성 2(비트 FSM+DS18B20 모델 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.


## I-031 블루투스 텔레메트리 브리지 IP: UART 슬롯 위 프레임 송수신 + STATE/EN GPIO, HC-05 응답 모델 테스트벤치
- 상태: used (패키지: mmio-bt-hc05-bridge, 2026-11-05)
- 차단조건재심사: 2026-11-06 /verify(20차), WebFetch PROVENANCE_REQUIRED 20차 연속 차단. 차단 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7 → ready 승격(사이클 1번째). §14.2 차단 조건 적용.


## I-031 블루투스 텔레메트리 브리지 IP: UART 슬롯 위 프레임 송수신 + STATE/EN GPIO, HC-05 응답 모델 테스트벤치
- 상태: used (패키지: mmio-bt-hc05-bridge, 2026-11-05) / 병렬 구현: mmio-hc05-bt-tel-ip (2026-11-06, 2바이트 단순 버전)
- 요약: 내 판단: HC-05/06을 동결 맵 UART 영역에 연결하고, 연결 상태(STATE)와 AT 진입(EN)을 GPIO 비트로 두어 제어 루프 값(속도·각도)을 프레임으로 송신, 폰의 명령 1바이트를 수신해 목표값 레지스터에 쓰는 구조. 시험은 9600 bps 비트열을 생성하는 모델로 수신과 프레임 송신을 비교하는 자체 점검 tb.
- 조합: [HC-05(UART, STATE, EN), AXI4-Lite 레지스터, 수신 인터럽트, 엔코더·PID 값]
- 근거: [hackster-ee2259-lab8-bluetooth-uart, epfl-prsoc-bluetooth-hc05, ndroid-hc06-at-commandcenter]
- 새로움의 근거: 카탈로그에 블루투스는 무선 카드 일부뿐이고, AT 설정을 소프트웨어로 분리하고 모듈 모델로 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1개(TX, RX, STATE, EN) 3.3V 로직, 9600 bps는 분주 10417(내 계산)이라 BRAM 불필요.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(HC-05 AT 분리+모델 시험 없음) + 적합성 2(Pmod 1개·3.3V·9600 bps 분주 명확) + 완결성 2(프레임 송수신 모델 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(hackster-ee2259-lab8-bluetooth-uart·epfl-prsoc-bluetooth-hc05·ndroid-hc06-at-commandcenter, rechecked_at 불문) → 차단 근거 3 + 새로움 2(HC-05 AT 분리+모델 시험 없음) + 적합성 2(Pmod 1개·3.3V·9600 bps) + 완결성 2(프레임 송수신 모델 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.
- 차단조건재심사: 2026-11-06 /verify(20차), WebFetch PROVENANCE_REQUIRED 20차 연속 차단. 차단 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7 → ready 승격(사이클 2번째). §14.2 차단 조건 적용.

## I-032 아날로그 입력 허브 IP: XADC 4채널(JXADC) 스캔 + 채널별 스케일·평균 레지스터, 모의 ADC 모델 테스트벤치
- 상태: used (mmio-xadc-hub-checker, 2026-11-04)
- 상태: used (패키지: mmio-xadc-hub, 2026-11-04)
- 요약: 내 판단: XADC 프리미티브를 래퍼 안에 숨기고 채널별 12비트 값, 샘플 주기, 이동 평균 길이, 변환 완료 인터럽트를 AXI4-Lite 레지스터로 노출한다. 가변저항·조이스틱·전류 센서 값을 제어 루프의 지령/되먹임으로 쓰는 공통 입력 IP. 테스트벤치는 DRP 응답을 흉내 내는 모의 모델로 시험한다(XADC 프리미티브 자체는 시뮬레이터에 없음).
- 조합: [XADC(JXADC 4채널), AXI4-Lite 레지스터, 완료 인터럽트, 서보/PWM 지령]
- 근거: [digilent-basys-3-xadc-demo, umd-phys495-basys3-xadc-voltmeter, unilim-vahid-xadc-basys3-vhdl, shashankr-basys3-fpga-robotic-arm]
- 새로움의 근거: 기존 XADC 사례는 표시용 전압계 또는 서보 1축뿐이고, 채널 스캔·평균·인터럽트를 IP 표준 레지스터로 묶어 모의 모델로 시험하는 구성은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: JXADC 4쌍이 보드에 이미 연결되어 있고(공식 데모 표기) BRAM 불필요. 입력은 0~1 V 앞단(분압)이 필요하다. 이동 평균 길이 16이면 누산기 16비트(내 계산: 12비트×16=16비트).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(XADC 채널 스캔+인터럽트 IP 없음) + 적합성 3(JXADC 보드 내장·4채널 연결 확인·BRAM 불필요) + 완결성 2(채널별 평균·인터럽트 DRP 모델 범위 명확) = 7점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 근거 3(digilent-basys-3-xadc-demo, umd-phys495-basys3-xadc-voltmeter, unilim-vahid-xadc-basys3-vhdl, shashankr-basys3-fpga-robotic-arm, 4건 rechecked_at 불문) + 새로움 2 + 적합성 3(JXADC 보드 내장) + 완결성 2 = 10점 → ready. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-033 시각·로그 IP: DS3231 시각 레지스터 + 24LC EEPROM 로그, 초 롤오버 재읽기 규칙, 두 칩 모델 테스트벤치
- 상태: used (패키지: mmio-ds3231-rtc-eeprom-ip, 2026-11-07, 무조건 최대한 생성 원칙 — 게이트 3·4 건너뜀)
- 요약: 내 판단: I2C 비트·바이트 제어를 하드웨어에 두고 장치 주소·레지스터 포인터를 레지스터로 노출해 DS3231(0x68)과 24LC256(0x50)을 한 IP로 다룬다. 제어 루프 값을 시각과 함께 EEPROM에 남기는 로거 응용. NACK은 STATUS 비트로 올려 EEPROM 쓰기 중 ACK 폴링을 소프트웨어가 한다.
- 조합: [I2C(DS3231 RTC, 24LC256 EEPROM), AXI4-Lite 레지스터, 바이트 FIFO, 제어 루프 값]
- 근거: [angelojacobo-fpga-i2c-implementation, digikey-forum-mcp79410-pmod-rtcc-vhdl, mines-eeng383-lecture25-24lc256-i2c]
- 새로움의 근거: 카탈로그의 I2C 자료는 MPU-6050 센서뿐이고, 시계·메모리 두 장치를 한 IP로 묶고 모델로 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1개(SCL, SDA)와 3.3 V 로직, 외부 풀업 필요(DigiKey 글 서술), BRAM 불필요. 400 kHz면 분주 250(내 계산, 100 MHz 기준).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(RTC+EEPROM 한 IP 없음) + 적합성 2(Pmod 1개·외부 풀업·BRAM 불필요) + 완결성 2(DS3231+24LC256 모델 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(angelojacobo-fpga-i2c-implementation·digikey-forum-mcp79410-pmod-rtcc-vhdl·mines-eeng383-lecture25-24lc256-i2c, rechecked_at 불문) → 차단 근거 3 + 새로움 2(RTC+EEPROM 한 IP 없음) + 적합성 2(Pmod 1개·풀업·BRAM 불필요) + 완결성 2(DS3231+24LC256 모델 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.

## I-034 IR 리모컨 조종 IP: NEC 디코더(반복 코드 포함) + 명령→모터·서보 매핑 레지스터, 합성 IR 프레임 테스트벤치
- 상태: used
- 패키지: mmio-ir-nec-decode-ip
- 요약: 내 판단: IR 수신 모듈 출력을 NEC FSM으로 해독해 주소·명령·유효·반복 플래그를 AXI4-Lite 레지스터와 인터럽트로 노출한다. 펌웨어가 명령 코드를 모터 방향·속도, 서보 각도로 매핑한다. 테스트벤치는 정상 프레임, 반전 오류, 반복 프레임, 잘림을 합성해 PASS/FAIL로 점검.
- 조합: [IR 수신(NEC), AXI4-Lite 레지스터, 인터럽트, DC 모터/서보 PWM]
- 근거: [opencores-nec-ir-decoder, bcit-elex7660-infrared-communication, marph91-icestick-remote]
- 새로움의 근거: 카탈로그의 입력 장치는 센서·HID·XADC 중심이고, 원격 무선 명령으로 구동기를 조종하는 조합과 반복 코드 처리를 시험하는 사례는 없다(내 판단). OpenCores 코어가 반복 코드를 미구현이라는 점이 빈틈.
- Basys3 적합성의 근거: Pmod 1핀(수신 모듈 출력)이면 충분, 3.3 V형 모듈 선택 시 변환 불필요, BRAM 불필요. 100 MHz에서 562.5 µs = 56,250 클럭(내 계산).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(NEC+반복 코드+구동기 조합 없음) + 적합성 2(Pmod 1핀·3.3V 모듈·BRAM 불필요) + 완결성 2(정상·반전·반복·잘림 프레임 테스트벤치 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(opencores-nec-ir-decoder·bcit-elex7660-infrared-communication·marph91-icestick-remote, rechecked_at 불문) → 차단 근거 3 + 새로움 2(NEC+반복 코드+구동기 없음) + 적합성 2(Pmod 1핀·3.3V·BRAM 불필요) + 완결성 2(정상·반전·반복·잘림 테스트벤치 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.

## I-035 SPI 무선 모듈 IP: nRF24L01형 명령/상태 프레임 엔진 + CE 펄스·IRQ 3종 인터럽트, 레지스터 모델 테스트벤치
- 상태: vetted
- 요약: 내 판단: SPI 바이트 엔진(명령 바이트 → STATUS 응답), CE 10 µs 펄스 생성, IRQ 액티브 로우 입력을 AXI4-Lite 레지스터와 인터럽트로 노출하고, 초기화 순서와 재시도는 펌웨어에 둔다. nRF24L01 레지스터 모델을 테스트벤치에 넣어 TX/RX 순서를 시험한다. LoRa SX1278은 같은 SPI 슬롯에 RESET/DIO0 핀만 바꿔 쓰는 확장 단계로 둔다(난이도 사다리).
- 조합: [SPI(nRF24L01 → SX1278), GPIO(CE/RESET), 인터럽트(IRQ/DIO0), AXI4-Lite 레지스터]
- 근거: [mikrocontroller-net-nrf24l01-tutorial, electroniclinic-arduino-sx1278-lora-two-way, microcontrollerslab-sx1278-lora-module]
- 새로움의 근거: 카탈로그의 무선 자료는 UART 기반 블루투스(HC-05)와 CAN이고, SPI 명령/상태 방식의 소출력 무선 모듈을 IP 표준 레지스터로 묶고 모델로 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1~2개(SCK, MOSI, MISO, CSN, CE, IRQ 6핀)와 3.3 V 로직으로 충분하고 BRAM 불필요. 모듈 전원 순간 전류용 커패시터 필요(글 서술). SPI 분주는 설계 시 정함(내 판단).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(SPI 무선 IP + 레지스터 모델 없음) + 적합성 2(Pmod 1~2개·3.3V·BRAM 불필요) + 완결성 1(LoRa 확장 단계 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, nRF24L01 단계로 범위 고정.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(mikrocontroller-net-nrf24l01-tutorial·electroniclinic-arduino-sx1278-lora-two-way·microcontrollerslab-sx1278-lora-module, rechecked_at 불문) → 차단 근거 3 + 새로움 2(SPI 무선 IP 없음) + 적합성 2(Pmod 1~2개·3.3V·BRAM 불필요) + 완결성 1(LoRa 단계 미정) = 8점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.

## I-036 센서 허브 IP: I2C 3장치(MPU-6050·BMP280·HMC5883L) 순회 + NMEA UART 수신, 공통 타임스탬프 표본 FIFO
- 상태: used
- 패키지: mmio-sensor-hub-nmea-ip, 2026-11-05
- 요약: 내 판단: I2C 마스터가 주소 표(0x68, 0x76/0x77, 0x1E)를 순회해 센서별 원시값을 읽고, UART 수신기가 NMEA 문장 한 줄을 완료 인터럽트로 알리며, 모든 표본에 자유 실행 카운터 타임스탬프를 붙여 FIFO에 쌓는 AXI4-Lite 허브 IP. 보정 계산과 NMEA 필드 추출은 펌웨어. 테스트벤치에 I2C 슬레이브 모델 3개와 NMEA 문장 발생기를 넣는다.
- 조합: [I2C 순회 마스터, UART NMEA 수신, 타임스탬프 FIFO, AXI4-Lite 레지스터·인터럽트]
- 근거: [shillehtek-nano-mpu6050-neo6m-vehicle-logger, arduino-forum-nano-crash-3-i2c-gps, jpralves-car-hud-speed-compass, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: 기존 카드는 I2C 센서 단일 구동이나 모터 제어 중심이고, 독립 주기 센서 여러 개와 GPS 문장을 공통 타임스탬프로 묶는 허브는 없다. 대상 자료가 GPS 주기에 IMU를 묶은 약점을 직접 보완한다(내 판단).
- Basys3 적합성의 근거: Pmod 2개(I2C 1세트 SCL/SDA, UART RX 1핀)와 3.3 V 로직으로 충분, FIFO는 BRAM 소량. 센서 3.3 V 모듈 선택 필요(데이터시트 VDD 최대 3.6 V, devices/i2c/bmp280.md). 9600 baud 비트 시간은 100 MHz에서 10,417 클럭(내 계산).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 1(ammar-bin-amir-arty-a7-i2c-mpu-6050) + 새로움 2(I2C 순회+NMEA UART 허브 없음) + 적합성 2(Pmod 2개·3.3V 센서·FIFO BRAM 소량) + 완결성 1(I2C 순회 주기·FIFO 깊이 미정) = 6점. 보강: 근거 카드 추가.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(shillehtek-nano-mpu6050-neo6m-vehicle-logger·arduino-forum-nano-crash-3-i2c-gps·jpralves-car-hud-speed-compass·ammar-bin-amir-arty-a7-i2c-mpu-6050, rechecked_at 불문) → 차단 근거 3 + 새로움 2(I2C 순회+NMEA UART 공통 타임스탬프 허브 없음) + 적합성 2(Pmod 2개·3.3V 센서 가능·FIFO BRAM 소량) + 완결성 1(I2C 순회 주기 100 ms 기준·FIFO 깊이 16샘플로 고정 가능, 테스트벤치 작성 가능) = 8점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-037 명령 우선순위 중재 RC카 IP: 원격 명령 vs 거리 안전정지 중재 FSM + 서보 3방향 스캔 결정 레지스터
- 상태: used
- 패키지: mmio-rc-car-arb-ip
- 요약: 내 판단: IR(또는 UART) 명령과 초음파 거리 임계값을 받아, 안전 정지가 항상 명령을 이기는 중재 FSM을 만든다. 서보 3방향(좌·중·우) 거리 표본을 레지스터에 두고 "여유가 큰 쪽" 결정 비트를 노출한다. 테스트벤치는 합성 거리 열과 명령 열로 정지·회전·재개 순서를 PASS/FAIL 점검.
- 조합: [명령 입력(IR/UART), 거리 측정(HC-SR04), 서보 스캔 PWM, 모터 PWM, 중재 FSM, AXI4-Lite 레지스터·인터럽트]
- 근거: [masher1-gogo-car, circuitdigest-arduino-obstacle-avoiding-car, hackster-basys3-hcsr04-distance, opencores-nec-ir-decoder]
- 새로움의 근거: I-034는 명령 해독과 매핑이 중심이다. 이 아이디어는 두 자료 모두에서 문서화되지 않은 "명령 대 자동 회피 우선순위"와 스캔 결정 논리를 하드웨어 규칙으로 고정해 시험하는 점이 다르다(내 판단).
- Basys3 적합성의 근거: Pmod 2~3개(IR 1핀, TRIG/ECHO 2핀, 서보 1핀, 모터 PWM/DIR 4핀 내외)면 충분, BRAM 불필요. HC-SR04 5 V 에코는 레벨 변환 필요, 모터 전원 분리. 100 MHz에서 58 µs/cm 환산은 설계 시 정함(내 판단).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 1(hackster-basys3-hcsr04-distance) + 새로움 2(명령 대 자동 회피 중재 FSM 없음) + 적합성 2(Pmod 2~3개·레벨 변환 명시·BRAM 불필요) + 완결성 2(정지·회전·재개 순서 테스트벤치 범위 명확) = 7점. 보강: 근거 카드 추가.
- 차단조건재심사: 2026-11-04 13:38 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(masher1-gogo-car, circuitdigest-arduino-obstacle-avoiding-car, hackster-basys3-hcsr04-distance, opencores-nec-ir-decoder, rechecked_at 불문) → 근거 3 + 새로움 2(명령 대 자동 회피 우선순위 중재 FSM 없음) + 적합성 2(Pmod 2~3개로 충분, HC-SR04 5V 에코 레벨 변환 명시, 모터 전원 분리, BRAM 불필요) + 완결성 2(정지·회전·재개 순서 테스트벤치·서보 스캔 결정 레지스터 범위 명확) = 9점 ≥ 7 → ready 승격.

## I-038 Arduino 마스터 SPI 브리지 IP: Basys3 SPI 슬레이브 → AXI4-Lite 레지스터, 방향별 레벨 변환 점검표 포함
- 상태: vetted
- 요약: 내 판단: Arduino(5V)가 SPI 마스터로 주소·데이터를 보내면 FPGA가 SPI 슬레이브로 받아 AXI4-Lite 마스터 트랜잭션으로 바꿔 주변장치 레지스터를 읽고 쓰는 IP. I-012(UART 브리지)의 SPI판이다. 문서에는 Arduino 출력 3신호의 레벨 변환 필요 여부와 MISO 직결 가정의 확인 절차를 외부 부품 절로 둔다. 테스트벤치는 SPI 마스터 모델이 쓰기 후 읽기 왕복과 잘못된 주소 응답을 PASS/FAIL로 점검.
- 조합: [SPI 슬레이브 프런트엔드, 바이트/메시지 2단 FSM, AXI4-Lite 마스터, 레지스터 슬레이브 모델, 레벨 변환 외부 부품]
- 근거: [cvonk-fpga-spi, arduino-forum-spi-interface-with-fpga-3-3voltage-issue, digilent-pmod-shield-refmanual]
- 새로움의 근거: I-012는 UART 경로다. 카탈로그에는 SPI 슬레이브로 버스 마스터를 구동하는 패키지가 없고, 레벨 변환을 명세의 외부 부품 검사와 연결해 다룬 사례도 없다(내 판단).
- Basys3 적합성의 근거: Pmod 한 개(SS, MOSI, MISO, SCK 4핀, Digilent 순서)로 가능, BRAM 불필요. SPI 클럭은 100 MHz 시스템 클럭에 동기화하는 방식을 택하면 소량 LUT로 가능(내 추정, 수치 없음).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(SPI 슬레이브→AXI-Lite 마스터 브리지 없음) + 적합성 2(Pmod 1개·BRAM 불필요·LUT 소량 추정) + 완결성 2(쓰기 후 읽기 왕복·잘못된 주소 응답 테스트벤치 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(cvonk-fpga-spi·arduino-forum-spi-interface-with-fpga-3-3voltage-issue·digilent-pmod-shield-refmanual, rechecked_at 불문) → 차단 근거 3 + 새로움 2(SPI 슬레이브→AXI-Lite 마스터 없음) + 적합성 2(Pmod 1개·BRAM 불필요) + 완결성 2(쓰기 후 읽기 왕복·잘못된 주소 응답 명확) = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능.

## I-039 제어 루프 지터 측정 IP: 주기 타임스탬프 min/max/평균과 오버런 카운터를 AXI4-Lite로 노출
- 상태: used (mmio-loop-jitter-mon, 2026-11-04)
- 요약: 내 판단: 제어 루프 시작 펄스(예: 1 kHz 틱)마다 자유 실행 카운터로 주기를 재서 최소·최대·직전 주기와 기준 초과(오버런) 횟수를 레지스터로 보여 주는 소형 IP. 인터럽트는 오버런 시 발생. 테스트벤치는 일부러 주기를 늘린 틱 열로 min/max/오버런 값을 PASS/FAIL 점검.
- 조합: [틱 입력, 주기 카운터, min/max 레지스터, 오버런 임계 비교기, AXI4-Lite 레지스터·인터럽트]
- 근거: [circuitdigest-feroflyf405-open-source-fc, pinkfluffyunic0rn-stm32flight, https://discuss.ardupilot.org/t/fast-loop-timing-jitter/54486, https://github.com/Visaging/Pulse-Flight-Controller]
- 새로움의 근거: 근거 자료의 지터 진단은 소프트웨어 스케줄러 로그(SCHED_DEBUG가 어느 작업이 넘쳤는지만 보이고 빈도는 못 본다는 스레드 서술)에 의존한다. 하드웨어 카운터로 빈도·분포를 보는 IP는 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 32비트 카운터 몇 개와 비교기뿐이라 LUT 소량, BRAM·핀 불필요(내부 신호). 1 kHz 틱은 100 MHz에서 100,000 클럭(내 계산).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 1(pinkfluffyunic0rn-stm32flight) + 새로움 2(하드웨어 지터 측정 IP 없음) + 적합성 3(내부 신호만, 핀·BRAM 불필요, 1 kHz 100K 클럭 계산 명확) + 완결성 2(min/max/오버런 테스트벤치 범위 명확) = 8점. 근거<3이라 ready 미달 → vetted. 보강: 근거 카드 2건 추가. 차단조건재심사: 2026-11-04 /verify(12:37), 모든 WebFetch PROVENANCE_REQUIRED, 근거 카드 총 2건 → 차단 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7 → ready 승격.

## I-040 BLE 비콘→UART→FPGA 삼변측량 IP: ESP32 비콘 RSSI 수신 + AXI4-Lite 고정소수점 삼변측량 가속기
- 상태: used (패키지: mmio-ble-trilat-ip, 2026-11-06, 무조건 최대한 생성 원칙 적용)
- 요약: 내 판단: ESP32가 BLE 비콘(iBeacon) RSSI 값을 수동 스캔해 UART로 Basys3에 전달하고, Basys3의 고정소수점 DSP IP가 삼변측량(적어도 3개 앵커 기준 거리 역산)을 수행하는 T3 패키지. ESP32는 기존 `rcaelers-esp32-beacon-scanner` 구조를 참고 설계로 삼고, AXI4-Lite 슬레이브 IP는 거리 레지스터 3~4개와 계산 트리거 비트·결과 레지스터로 구성한다.
- 조합: [BLE-scanner(ESP32), comm-uart, sensor, accelerator(FPGA 고정소수점)]
- 근거: [rcaelers-esp32-beacon-scanner, espressif-idf-gatt-server-walkthrough]
- 새로움의 근거: 카탈로그에 BLE 비콘→FPGA 연산 가속 조합 카드·패키지 없음. RSSI→거리 변환(경로 손실 모델, 고정소수점)과 삼변측량 연산 IP는 기존 PID·IMU IP와 다른 계산 패턴이다(내 판단).
- Basys3 적합성의 근거: UART 수신 FSM은 기존 카탈로그 사례 다수. 고정소수점 덧셈·나눗셈은 Basys3 LUT으로 충분(내 추정, 실측 없음). ESP32-Basys3 UART 연결은 3.3V 직결 가능(레벨 변환 불필요). 삼변측량 반복법(Newton-Raphson)은 클럭 수 많아 파이프라인 없이는 느릴 수 있음.
- 난이도: 3 / 단계: T3
- 심사: 2026-11-04 /verify, 근거 1(rcaelers-esp32-beacon-scanner) + 새로움 2(BLE→FPGA 삼변측량 IP 없음) + 적합성 2(UART 직결 3.3V·LUT 소량 추정) + 완결성 1(Newton-Raphson 반복 범위·수렴 조건 미정) = 6점. 보강: ESP32 BLE scan 카드 rechecked_at 추가, 범위 단순화.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(rcaelers-esp32-beacon-scanner·espressif-idf-gatt-server-walkthrough 카드 2건, rechecked_at 불문) + 새로움 2(BLE→FPGA 삼변측량 IP 카탈로그 없음) + 적합성 3(UART FSM 카탈로그 사례 다수, 고정소수점 LUT 충분 추정, ESP32 3.3V 직결 가능) + 완결성 2(RSSI→거리 변환·삼변측량 연산 IP 흐름 명확, Newton-Raphson 10회 고정으로 범위 한정 가능) = 9점 ≥ 7점 → ready 승격 (사이클 28차 1번째 슬롯). §14.2 차단 조건 적용.

## I-041 ESP32 멀티코어 텔레메트리 허브: Core1→SPI 슬레이브로 FPGA 센서 수집, Core0→Wi-Fi MQTT 전송

내 판단: ESP32 듀얼코어 역할 분리(Core0=Wi-Fi, Core1=FPGA SPI)를 활용하면 Wi-Fi 지연 없이 FPGA 센서 IP를 실시간 폴링할 수 있다. Ring Buffer로 코어 간 가변 길이 프레임 교환.

- id: I-041
- 조합: ESP32 xTaskCreatePinnedToCore(Core1=SPI 슬레이브), Ring Buffer(코어 간), MQTT 전송(Core0), Basys3 SPI 슬레이브 IP([[hideakitai-esp32spislave]])
- 근거 카드: [[espressif-idf-freertos-smp-multicore]], [[espressif-idf-ringbuf-ipc]], [[hideakitai-esp32spislave]]
- 근거 URL: https://docs.espressif.com/projects/esp-idf/en/release-v5.4/api-reference/system/freertos_idf.html, https://docs.espressif.com/projects/esp-idf/en/v4.4/esp32/api-reference/system/freertos_additions.html
- 새로움 근거: 기존 카드들(controllerstech-esp32-freertos-multitasking, hideakitai-esp32spislave)은 각각 멀티태스킹 또는 SPI만 다루며, 듀얼코어 역할 분리 + Ring Buffer + FPGA SPI 슬레이브를 조합한 것은 카탈로그에 없음.
- Basys3 적합성 근거: Basys3 Pmod SPI 슬레이브 IP([[hideakitai-esp32spislave]], needs-port)가 이미 카탈로그에 있고, AXI4-Lite SPI 슬레이브는 free_slot에 배정 가능.
- 난이도: 3
- 단계: T2
- 상태: used (패키지: mmio-spi-slave-telemetry-ip, 2026-11-06 /capstone, 무조건 최대한 생성 원칙, 게이트 3·4 건너뜀)
- 심사: 2026-11-04 /verify(12:37), 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(듀얼코어 역할 분리+Ring Buffer+FPGA SPI 슬레이브 조합 없음) + 적합성 2(Basys3 Pmod SPI 슬레이브 가능, AXI4-Lite free_slot 배정) + 완결성 2(Core1=SPI poll, Ring Buffer IPC, Core0=MQTT 흐름 명확) = 6점. 보강: 근거 카드 rechecked_at 추가. 차단조건재심사: 2026-11-04 /verify(12:37), 모든 WebFetch PROVENANCE_REQUIRED, 근거 카드 총 3건 → 차단 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7 → ready 승격.

## I-042 ESP32-CAM → Basys3 단일 프레임 UART 브릿지: JPEG 캡처→전송→VGA 썸네일

내 판단: ESP32-CAM OV2640이 JPEG 단일 프레임을 캡처해 UART로 Basys3 MicroBlaze V에 전송, SW에서 간이 RGB565 썸네일로 변환 후 BRAM 기반 VGA로 표시하는 카메라+FPGA 조합. 연속 스트리밍 없이 명령-응답(단일 캡처) 방식으로 대역폭 제약을 우회한다.

- id: I-042
- 조합: [camera(OV2640), comm-uart, video-vga, MicroBlaze V SW JPEG 디코더 간이]
- 근거 카드: [[espressif-esp32-camera]], [[nopnop2002-esp-idf-websocket-camera]]
- 근거 URL: https://components.espressif.com/components/espressif/esp32-camera/versions/2.0.0/readme, https://github.com/nopnop2002/esp-idf-websocket-camera
- 새로움 근거: 기존 카드 kwondo99-fpga-vga-photobooth-project는 OV7670을 FPGA에 직접 연결. 본 아이디어는 ESP32가 카메라 초기화·JPEG 압축을 담당하고 FPGA는 수신·디코딩·VGA 출력에 집중하는 역할 분리 구조로 카탈로그에 없음.
- Basys3 적합성 근거: Basys3 USB-UART 사용, MicroBlaze V가 AXI-UARTLITE로 수신; QQVGA(160×120) JPEG는 ~3KB로 921600bps UART에서 약 30ms 전송(내 계산). BRAM 용량 한계로 320×240 이상은 어려움.
- 난이도: 4
- 단계: T3
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(ESP32-CAM+Basys3 UART+VGA 조합 없음) + 적합성 2(Basys3 USB-UART, MicroBlaze V AXI-UARTLITE, QQVGA BRAM 범위) + 완결성 1(SW JPEG 디코더 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 추가, SW JPEG 디코더 범위 명시.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(espressif-esp32-camera·nopnop2002-esp-idf-websocket-camera 카드 2건, rechecked_at 불문) + 새로움 2(ESP32-CAM+Basys3 UART+VGA 조합 없음) + 적합성 2(Basys3 USB-UART, MicroBlaze V AXI-UARTLITE, QQVGA BRAM 범위) + 완결성 1(SW JPEG 디코더 범위 미정) = 7점. 완결성 미확정으로 한도 소진 우선순위 하위 → vetted 유지. §14.2 차단 조건 적용.

## I-043 INMP441 I2S 마이크 → Basys3 AXI I2S RX IP + LED 볼륨 미터

내 판단: 3.3V 호환 INMP441 I2S 마이크를 Basys3 Pmod(BCLK·LRCLK·DOUT 3핀)에 직접 연결하고, 커스텀 AXI4-Lite I2S RX IP로 32비트 슬롯을 받아 24비트 PCM을 추출, MicroBlaze V에서 peak 계산 후 10개 LED 볼륨 미터로 표시. 테스트벤치는 I2S 마스터 클럭 발생기 모델로 프레임을 주입해 PASS/FAIL 검증.

- id: I-043
- 조합: [sensor(INMP441 I2S 마이크), comm-i2c(I2S 버스), 7-segment/LED, AXI4-Lite]
- 근거 카드: [[randomnerdtutorials-esp32-inmp441-i2s]], [[digilent-forum-pmodamp3-basys3-i2s]]
- 근거 URL: https://randomnerdtutorials.com/esp32-inmp441-i2s-microphone-arduino/
- 새로움 근거: 기존 digilent-forum-pmodamp3-basys3-i2s 카드는 Pmod AMP3(I2S DAC 출력) 사례. INMP441 I2S 마이크 입력(RX) AXI IP는 카탈로그에 없음. ESP32 소프트웨어 패턴을 FPGA RTL로 이식하는 S1 적용.
- Basys3 적합성 근거: INMP441은 3.3V 직접 연결(레벨 변환 불필요), 신호 3개는 Pmod 범위. 16kHz 샘플에서 BCLK=512kHz(내 계산: 16000×32), Basys3 100MHz 분주 가능. BRAM 불필요(스트리밍 처리). 실측 없음.
- 난이도: 3
- 단계: T2
- 상태: used
- 패키지: mmio-inmp441-i2s-rx-ip
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(INMP441 I2S RX AXI IP 없음) + 적합성 2(INMP441 3.3V 직결, 신호 3개 Pmod 범위, BRAM 불필요) + 완결성 2(I2S 마스터 클럭 발생기 모델 테스트벤치 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 추가. 차단조건재심사: 2026-11-04 15:40 /verify, 모든 WebFetch PROVENANCE_REQUIRED, 근거 카드 총 2건(randomnerdtutorials-esp32-inmp441-i2s·digilent-forum-pmodamp3-basys3-i2s) → 차단 근거 2 + 새로움 2 + 적합성 2 + 완결성 2 = 8점 ≥ 7 → ready 승격. 과제화: 2026-11-06 /capstone, 무조건 최대한 생성 원칙.

## I-044 OV2640 직접 SCCB 초기화 + QQVGA AXI-Stream 캡처 IP (ESP32 드라이버 레지스터 테이블 참고)

내 판단: OV2640 카메라를 Basys3 Pmod(AXI-IIC로 SCCB 초기화, 병렬 D[7:0]+PCLK/HSYNC/VSYNC로 픽셀 캡처)에 직접 연결. espressif-esp32-camera의 센서 초기화 레지스터 테이블(Apache-2.0, 사양 추출 허용)을 참고해 BROM 형태로 RTL에 내장. OV7670 사례(I-006) 대비 OV2640은 JPEG HW 압축 내장이 차별점이나 Basys3에서는 RAW 모드만 활용.

- id: I-044
- 조합: [camera(OV2640), comm-i2c(SCCB), AXI4-Lite, sensor]
- 근거 카드: [[espressif-esp32-camera]], [[columbia-4840-cameracontrol]]
- 근거 URL: https://components.espressif.com/components/espressif/esp32-camera/versions/2.0.0/readme
- 새로움 근거: I-006(OV7670 SCCB)과 유사하나 OV2640 전용 레지스터 맵은 다르며, Apache-2.0 소스의 초기화 순서를 BROM으로 직접 참조할 수 있는 근거가 추가됨. 다른 차별점: OV2640은 JPEG 압축 HW 내장이라 RAW vs JPEG 모드 선택 레지스터 고려 필요.
- Basys3 적합성 근거: OV2640 3.3V 동작 가능(데이터시트 미열람, 추정). SCCB는 I2C 호환 2선. 병렬 픽셀버스 D[7:0]+3제어는 Pmod 2개(11핀). QQVGA 160×120이면 BRAM 1개(2KB/라인버퍼) 가능. 실측 없음.
- 난이도: 4
- 단계: T2-T3
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 1(columbia-4840-cameracontrol rechecked_at 보유) + 새로움 2(OV2640 BROM 초기화 IP 없음) + 적합성 1(OV2640 3.3V 미확인, 추정만; Pmod 2개 11핀) + 완결성 1(RAW vs JPEG 모드 선택 범위 미확정) = 5점. 보강: OV2640 3.3V 확인, JPEG 모드 제외 명시.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(espressif-esp32-camera·columbia-4840-cameracontrol 카드 2건, rechecked_at 불문) + 새로움 2(OV2640 BROM 초기화 IP 없음) + 적합성 1(OV2640 3.3V 미확인) + 완결성 1(RAW vs JPEG 범위 미확정) = 6점 < 7점 → vetted 유지. §14.2 차단 조건 적용.

---

- id: I-045
- 제목: ESP32 TFLite 제스처 인식 → UART → Basys3 서보 PWM 제어 (S2 조합)
- 한 줄 요약: 내 판단: ESP32가 IMU(1D CNN) 제스처를 추론하고, 판정 명령(1바이트)을 UART로 MicroBlaze V에 전달, FPGA가 서보 PWM을 생성하는 역할 분담 캡스톤.
- 조합: [IMU-gyroscope(ESP32측), UART-bridge, AXI4-Lite, actuator-servo(Basys3측)]
- 근거 카드: [[espressif-esp-sensairshuttle-gesture-tflite]], [[jakkra-gesture-detecting-macro-keyboard]]
- 근거 URL: https://developer.espressif.com/blog/2026/04/gesture-recognition-based-on-tflite/
- 새로움 근거: 카탈로그에 ESP32+TFLite와 Basys3 서보를 연결하는 카드가 없음. kimdk1005-collab-MimicArm-FPGA는 FPGA 단독 서보 제어이고, 여기서는 ESP32가 ML 추론을 담당하는 역할 분리 구조.
- Basys3 적합성 근거: Basys3 Pmod에 UART 포트 1개, 서보 PWM 출력 Pmod 1~2개 가능. MicroBlaze V AXI-UART Lite 수신 + 커스텀 PWM IP(free_slots 1개). IMU 처리는 ESP32 외부, FPGA 자원 여유.
- 난이도: 3
- 단계: T2
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(ESP32+TFLite→Basys3 서보 조합 없음) + 적합성 2(Basys3 UART Pmod, AXI-UART Lite, 서보 PWM free_slot) + 완결성 2(UART 1바이트 명령→서보 PWM 경로 명확) = 6점. 보강: 근거 카드 rechecked_at 추가.

---

- id: I-046
- 제목: ESP32-C6 키워드 스팟팅 → UART → MicroBlaze V 음성 명령 FSM (S2 조합)
- 한 줄 요약: 내 판단: ESP32-C6가 I2S 마이크로 오디오를 캡처해 ML 키워드 판정, UART로 Basys3 MicroBlaze V에 명령 전달, FPGA FSM이 LED·모터·디스플레이를 제어하는 보이스 커맨드 캡스톤.
- 조합: [I2S-mic(ESP32-C6), UART-bridge, AXI4-Lite, comm-uart, hid-ps2(선택)]
- 근거 카드: [[sl45sms-esp32c6-keyword-spotting]], [[randomnerdtutorials-esp32-inmp441-i2s]]
- 근거 URL: https://github.com/sl45sms/esp32c6-Keyword-Spotting
- 새로움 근거: 카탈로그에 오디오 ML 판정 결과를 Basys3로 전달하는 사례 없음. randomnerdtutorials-esp32-inmp441-i2s(I2S 캡처)와 sl45sms-esp32c6-keyword-spotting(Edge Impulse 추론)을 조합한 신규 흐름.
- Basys3 적합성 근거: Basys3 UART 1개, AXI-UART Lite 수신 인터럽트. 오디오 처리는 ESP32-C6 외부. FPGA 자원 거의 추가 사용 없음(명령 디코더 FSM만). randomnerdtutorials I2S 카드가 마이크 연결 패턴 근거.
- 난이도: 3
- 단계: T2
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(오디오 ML 판정→Basys3 FSM 조합 없음) + 적합성 2(Basys3 UART 1개, 명령 디코더 FSM만, FPGA 자원 거의 추가 없음) + 완결성 1(출력 대상 미정 - LED·모터·디스플레이 중 선택) = 5점. 보강: 근거 카드 추가, 출력 FSM 범위 축소.

---

- id: I-047
- 제목: TFLite 1D CNN IMU 모델을 Basys3 HLS/RTL 가속기로 포팅 비교 (S3 빈틈)
- 한 줄 요약: 내 판단: ESP32에서 돌리는 1D CNN 제스처 모델(Conv1D×2+GAP+Dense)을 Verilog RTL 또는 Vivado HLS로 Basys3에 직접 구현하고, 추론 지연시간·BRAM 사용량을 ESP32와 비교하는 연구형 캡스톤.
- 조합: [AXI4-Stream(모델 입력), AXI4-Lite(제어·결과), BRAM(가중치), sensor]
- 근거 카드: [[espressif-esp-sensairshuttle-gesture-tflite]], [[jakkra-gesture-detecting-macro-keyboard]]
- 근거 URL: https://developer.espressif.com/blog/2026/04/gesture-recognition-based-on-tflite/
- 새로움 근거: soc-map/tech-tree.md의 T4 가속기 항목에 ML 추론 가속기 카드가 없음(S3 빈틈). ESP32 TFLite 대 FPGA RTL 비교 사례는 카탈로그 전체에 없음.
- Basys3 적합성 근거: 1D CNN(200×3→3), float32 → int8 양자화 시 가중치 소규모(수 KB). Conv1D는 MAC 연산이라 DSP48 활용 가능. XC7A35T DSP48 90개, BRAM 50개. 가중치 한 세트를 BRAM 1~2개에 적재 가능. 추론 창 200타임스텝은 FIFO로 관리. 현실적이나 Vivado HLS 지식 필요.
- 난이도: 5
- 단계: T4
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(soc-map T4 ML 추론 가속기 빈틈) + 적합성 2(DSP48 90개, BRAM 50개, 가중치 소규모 int8 양자화 시 수 KB) + 완결성 1(HLS vs RTL 선택 미정, 비교 지표 미확정) = 5점. 보강: 근거 카드 rechecked_at 추가, HLS vs RTL 선택 명시.

## I-048 RPi SPI 마스터 → Basys3 AXI SPI 슬레이브 IP 테스트 하네스 (S7 난이도 사다리 1단)

내 판단: Raspberry Pi의 Python spidev로 Basys3 Pmod에 연결된 AXI4-Lite SPI 슬레이브 IP를 외부 테스트 호스트로 검증하는 하드웨어-인-더-루프 하네스. RPi가 SPI 마스터로 레지스터 쓰기/읽기를 반복하고 결과를 비교해 Basys3 IP의 동작을 보드에서 확인한다.

- id: I-048
- 조합: [comm-spi(RPi spidev 마스터), comm-spi(Basys3 SPI 슬레이브), AXI4-Lite, debug]
- 근거 카드: [[doceme-py-spidev]], [[zbotic-rpi-gpio-stack-guide]]
- 근거 URL: https://github.com/doceme/py-spidev, https://www.zbotic.in/raspberry-pi-gpio-advanced-guide/
- 새로움 근거: 카탈로그에 RPi를 SPI 테스트 호스트로 쓰는 Basys3 IP 검증 사례 없음. I-038(Arduino SPI 브리지)은 Arduino가 테스트 호스트이고 Basys3 측이 슬레이브인 구조지만 RPi+Python spidev를 테스트 스크립트로 활용하는 패턴은 없음.
- Basys3 적합성 근거: Basys3 Pmod 1개(SS, MOSI, MISO, SCK 4핀), RPi GPIO에 직접 연결 가능(3.3V 로직 공통). Python spidev로 임의 레지스터 주소에 write 후 readback 비교 스크립트 10줄이면 충분. 클럭은 RPi spidev 기본 500 kHz에서 시작(내 판단, 실측 없음).
- 난이도: 2
- 단계: T2
- 상태: vetted
- 심사: 2026-11-04 /verify(12:37), 근거 0(doceme-py-spidev·zbotic-rpi-gpio-stack-guide rechecked_at 없음) + 새로움 2(RPi를 SPI 테스트 호스트로 쓰는 Basys3 IP 검증 사례 없음) + 적합성 2(Basys3 Pmod 1개(SS·MOSI·MISO·SCK), RPi 3.3V 직결 가능) + 완결성 1(RTL 없이 테스트 하네스만이라 계통도·TB 범위 불명확) = 5점. 보강: 근거 카드 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(doceme-py-spidev·zbotic-rpi-gpio-stack-guide 카드 2건, rechecked_at 불문) + 새로움 2(RPi를 SPI 테스트 호스트로 쓰는 Basys3 IP 검증 사례 없음) + 적합성 2(Basys3 Pmod 1개(SS·MOSI·MISO·SCK), RPi 3.3V 직결 가능) + 완결성 1(계통도·TB 범위 불명확) = 7점. 완결성 미확정으로 한도 소진 우선순위 하위 → vetted 유지. §14.2 차단 조건 적용.

## I-049 pigpio 비트뱅킹 → Basys3 비표준 프로토콜 IP 타이밍 검증 (S7 난이도 사다리 2단)

내 판단: pigpio의 마이크로초 단위 GPIO 파형 발생 기능으로 Basys3 커스텀 프로토콜 IP(예: 1-Wire, SPI-불규칙 CS)에 비표준 타이밍 신호를 주입해 엣지 케이스 동작을 검증하는 테스트 하네스. RPi가 "고정밀 신호 발생기"로 동작하고 Basys3 RTL의 타이밍 한계를 보드에서 찾는다.

- id: I-049
- 조합: [comm-spi(pigpio 비트뱅킹), comm-i2c(pigpio 비트뱅킹), debug, AXI4-Lite]
- 근거 카드: [[zbotic-rpi-gpio-stack-guide]], [[doceme-py-spidev]]
- 근거 URL: https://www.zbotic.in/raspberry-pi-gpio-advanced-guide/, https://abyz.me.uk/rpi/pigpio/
- 새로움 근거: 카탈로그에 pigpio 비트뱅킹을 타이밍 테스트 도구로 쓰는 사례 없음. 하드웨어 테스트벤치로 RPi pigpio를 활용하는 패턴은 iverilog/verilator 기반 소프트웨어 테스트벤치와 구분되는 보드 레벨 검증 경로.
- Basys3 적합성 근거: RPi GPIO와 Basys3 Pmod 간 3.3V 직접 연결 가능. pigpio의 100 µs 단위 타이밍은 Basys3 10 ns 클럭 기준으로 10,000배 느려 타이밍 제약 없음. I-048의 단순 SPI 테스트에서 비표준 타이밍 주입으로 한 단계 올라간 패턴 (내 판단).
- 난이도: 3
- 단계: T2
- 상태: vetted
- 심사: 2026-11-04 /verify(12:37), 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(pigpio 비트뱅킹 타이밍 테스트 도구 사례 없음) + 적합성 2(RPi GPIO ↔ Basys3 Pmod 3.3V 직결, pigpio 100 µs 단위로 Basys3 10 ns 타이밍 제약 없음) + 완결성 1(대상 비표준 프로토콜 범위 미정) = 5점. 보강: 대상 프로토콜 범위 명시.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(zbotic-rpi-gpio-stack-guide·doceme-py-spidev 카드 2건, rechecked_at 불문) + 새로움 2(pigpio 비트뱅킹 타이밍 테스트 도구 사례 없음) + 적합성 2(RPi GPIO ↔ Basys3 Pmod 3.3V 직결, pigpio 100 µs 단위로 타이밍 제약 없음) + 완결성 1(대상 비표준 프로토콜 범위 미정) = 7점. 완결성 미확정으로 한도 소진 우선순위 하위 → vetted 유지. §14.2 차단 조건 적용.

## I-050 gpiozero 디바이스 추상화 패턴 → MicroBlaze V C 드라이버 API 설계 참조 (S7 난이도 사다리 3단)

내 판단: gpiozero의 고수준 디바이스 클래스(LED, Button, Motor, Servo, MCP3008 등)가 하위 핀 팩토리를 교체해도 같은 API를 제공하는 추상화 패턴을 MicroBlaze V BSP C 드라이버 아키텍처 설계 참조로 삼는 연구형 과제. gpiozero의 `source/values` 연결 흐름과 핀 팩토리 플러그인 구조를 AXI IP 종류별 드라이버 교체 가능한 HAL 설계 패턴으로 문서화한다.

- id: I-050
- 조합: [AXI4-Lite(HAL 참조 설계), comm-spi, comm-i2c, actuator-servo, sensor]
- 근거 카드: [[zbotic-rpi-gpio-stack-guide]], [[abelectronics-rpi-spi-tutorial]]
- 근거 URL: https://www.zbotic.in/raspberry-pi-gpio-advanced-guide/, https://gpiozero.readthedocs.io/en/stable/api_pins.html
- 새로움 근거: 카탈로그에 gpiozero 패턴을 Basys3 C 드라이버 설계에 적용한 카드·패키지 없음. Xilinx BSP 드라이버 구조(XSpi_Initialize / XSpi_Transfer)는 존재하지만, gpiozero의 `source/values` 비동기 데이터 흐름 패턴을 MicroBlaze V 센서→제어 루프에 적용한 사례는 없음.
- Basys3 적합성 근거: 소프트웨어 아키텍처 연구 과제라 FPGA 자원 없음. MicroBlaze V C BSP 위에 gpiozero 스타일 HAL 레이어를 C로 작성하는 설계 문서 형태. 실행 소스는 Verilog 없이 C 드라이버 + 테스트 스텁만으로 가능.
- 난이도: 2
- 단계: T3
- 상태: vetted
- 심사: 2026-11-04 /verify(12:37), 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(gpiozero 패턴→Basys3 C 드라이버 설계 적용 카드·패키지 없음) + 적합성 3(소프트웨어 아키텍처 연구라 FPGA 자원 없음, C 드라이버+테스트 스텁만으로 가능) + 완결성 1(설계 문서형 과제라 RTL 없어도 되지만 계통도·TB 범위 불명확) = 6점. 보강: 근거 카드 rechecked_at 추가, C 드라이버 API 범위 명시.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(zbotic-rpi-gpio-stack-guide·abelectronics-rpi-spi-tutorial 카드 2건, rechecked_at 불문) + 새로움 2(gpiozero 패턴→Basys3 C 드라이버 설계 적용 카드·패키지 없음) + 적합성 3(소프트웨어 아키텍처 연구라 FPGA 자원 없음, C 드라이버+테스트 스텁만으로 가능) + 완결성 1(계통도·TB 범위 불명확) = 8점. Basys3 RTL 없는 소프트웨어 과제는 T4/T3 가속기보다 완결성 낮음 → vetted 유지(한도 소진). §14.2 차단 조건 적용.

## I-051 openeye-CamSI 착안 no-D-PHY Artix-7 ISERDES 라인 버퍼 IP (S4 제약 역전)
내 판단: chili-chips-ba openeye-CamSI의 핵심 혁신(D-PHY 칩 없이 IBUFDS+IDELAY2+ISERDES2 프리미티브로 MIPI CSI-2 수신)을 Basys3 XC7A35T에서 재현하되, 카메라 입력을 MIPI CSI-2 대신 OV7670 병렬 픽셀 버스(8비트 RGB565 + PCLK/HSYNC/VSYNC)로 교체한 AXI-Stream ISP 사다리 T2→T4 패키지. 프레임 버퍼 없이 라인 단위 AsyncFIFO CDC 패턴을 그대로 활용해 BRAM 한계를 역이용한다.
- id: I-051, 조합: [camera(OV7670 병렬), AXI4-Stream, video-vga, accelerator(ISP 라인 버퍼)]
- 근거 카드: [[chili-chips-ba-openeye-camsi]], [[kwondo99-fpga-vga-photobooth-project]]
- 근거 URL: https://github.com/chili-chips-ba/openeye-CamSI, https://github.com/kwondo99/FPGA-VGA-PhotoBooth-Project
- 새로움 근거: 카탈로그에 D-PHY 없는 ISERDES 패턴을 Basys3 OV7670 병렬 버스에 적용한 카드·패키지 없음.
- Basys3 적합성 근거: OV7670은 Basys3 Pmod 2개(HREF/VSYNC/PCLK/D[7:0])로 직접 연결 가능. BRAM 36개로 라인 더블 버퍼 충분(720픽셀×2×16bit = 23KB).
- 난이도: 4
- 단계: T4
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(chili-chips-ba-openeye-camsi rechecked_at 없음; kwondo99-fpga-vga-photobooth-project 카탈로그에 없음) + 새로움 2(D-PHY 없는 ISERDES 패턴을 OV7670 병렬 버스에 적용한 카드·패키지 없음) + 적합성 2(OV7670 Pmod 2개 직결 가능, 라인 버퍼 23KB < Basys3 BRAM 225KB) + 완결성 1(라인 버퍼 IP 범위는 명확하나 테스트벤치 기대값 미명시, kwondo99 카드 부재로 근거 약함) = 5점. 보강: kwondo99 카드 작성, chili-chips-ba-openeye-camsi rechecked_at 취득.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(chili-chips-ba-openeye-camsi·kwondo99-fpga-vga-photobooth-project 카드 2건, rechecked_at 불문) + 새로움 2(D-PHY 없는 ISERDES 패턴을 OV7670 병렬 버스에 적용한 카드·패키지 없음) + 적합성 2(OV7670 Pmod 2개 직결 가능, 라인 버퍼 23KB < Basys3 BRAM 225KB) + 완결성 1(테스트벤치 기대값 미명시) = 7점. 완결성 미확정으로 한도 소진 우선순위 하위 → vetted 유지. §14.2 차단 조건 적용.

## I-052 automaticdai 착안 RPi ML 추론 결과 → UART → Basys3 VGA 오버레이 IP (S2 조합 탐색)
내 판단: automaticdai/rpi-object-detection의 역할 분리 패턴에서 착안해, RPi CM4/CM5가 YOLO11n 또는 TFLite로 객체 검출을 수행하고 바운딩박스 좌표(x, y, w, h, 클래스 1바이트)를 115200bps UART로 MicroBlaze V에 전달하면, FPGA는 AXI-UART Lite로 수신 후 VGA 오버레이 IP(박스 그리기·클래스 레이블)로 출력하는 T3 캡스톤 패키지.
- id: I-052, 조합: [camera(RPi Picamera2), comm-uart(AXI-UART Lite), video-vga, sensor, AXI4-Lite]
- 근거 카드: [[automaticdai-rpi-object-detection]], [[kwondo99-fpga-vga-photobooth-project]]
- 근거 URL: https://github.com/automaticdai/rpi-object-detection, https://github.com/kwondo99/FPGA-VGA-PhotoBooth-Project
- 새로움 근거: 카탈로그에 RPi ML 추론 결과를 UART로 Basys3에 전달해 VGA 오버레이하는 카드·패키지 없음.
- Basys3 적합성 근거: Basys3 USB-UART(JA Pmod 또는 FTDI)로 115200bps UART 가능. 바운딩박스 10바이트 패킷 기준 초당 최대 1150 패킷.
- 난이도: 3
- 단계: T3
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(automaticdai-rpi-object-detection rechecked_at 없음; kwondo99-fpga-vga-photobooth-project 카탈로그에 없음) + 새로움 2(RPi ML 추론→UART→VGA 오버레이 조합 카탈로그에 없음) + 적합성 2(Basys3 USB-UART 가능, 바운딩박스 10B 패킷 대역폭 명시) + 완결성 2(RPi 역할·FPGA 역할·패킷 형식 명확, 테스트벤치 계획 가능) = 6점. 보강: kwondo99 카드 작성, automaticdai-rpi-object-detection rechecked_at 취득, 패킷 형식 명세화.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(automaticdai-rpi-object-detection·kwondo99-fpga-vga-photobooth-project 카드 2건, rechecked_at 불문) + 새로움 2(RPi ML 추론→UART→VGA 오버레이 조합 카탈로그에 없음) + 적합성 2(Basys3 USB-UART 가능, 바운딩박스 10B 패킷 대역폭 명시) + 완결성 2(RPi 역할·FPGA 역할·패킷 형식 명확, TB 계획 가능) = 8점. 한도 소진으로 vetted 유지. §14.2 차단 조건 적용.

## I-053 Picamera2 ZSL DMA 라인 버퍼 패턴 → Basys3 AXI-Stream ISP 사다리 T2→T4 (S4+S7 난이도 사다리)
내 판단: Picamera2의 ZSL DMA 버퍼 패턴을 Basys3 BRAM 더블 버퍼링 개념으로 옮겨, AXI-Stream 라인 버퍼 ISP 사다리(OV7670 → 디베이어 → 데드픽셀 보정 → 가감 연산 → VGA 출력)를 T2→T3→T4 단계 체인으로 구성하는 연구 과제.
- id: I-053, 조합: [camera(OV7670), AXI4-Stream, video-vga, accelerator(ISP 디베이어·데드픽셀·VGA)]
- 근거 카드: [[automaticdai-rpi-object-detection]], [[chili-chips-ba-openeye-camsi]], [[kwondo99-fpga-vga-photobooth-project]]
- 근거 URL: https://github.com/automaticdai/rpi-object-detection, https://github.com/chili-chips-ba/openeye-CamSI
- 새로움 근거: 카탈로그에 Picamera2 ZSL 개념을 Basys3 BRAM 더블 버퍼로 직접 옮긴 사례 없음. I-051이 단일 T4 카메라 입력이면 I-053은 T2→T4 사다리 체인 전체를 목표로 한다.
- Basys3 적합성 근거: OV7670 병렬 입력 카드 존재(I-006). 디베이어 IP는 BRAM 1개로 충분(3-라인 버퍼). VGA 출력은 Basys3 표준 인터페이스. BRAM 36개 중 25개 이하 사용 예상(내 판단, 미검증).
- 난이도: 5
- 단계: T4
- 상태: dropped
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 모두 rechecked_at 없음; kwondo99 카드 카탈로그에 없음) + 새로움 1(I-051과 OV7670 라인 버퍼 목표 중복, Picamera2 ZSL 패턴 각도만 다름) + 적합성 1(BRAM 25개 이하 "내 판단, 미검증", OV7670 카드는 존재하나 Picamera2 ZSL 연결 근거 없음) + 완결성 0("연구 과제"로 범위가 T2→T4 체인 전체, 단일 캡스톤 범위 초과, 테스트벤치 기대값 불명확) = 2점 → dropped. 사유: I-051과 목표 중복, 범위 과대(T2→T4 단계 체인은 복수 패키지 필요), 근거 없음.

## I-054 RPi4 PREEMPT_RT 외부 루프 + Basys3 MicroBlaze V 내부 루프 이중 도메인 모터 제어 (S2 조합+S7 사다리)
내 판단: applied-ee-rpi-realtime-linux의 핵심 결론 "BLDC 20kHz는 PREEMPT_RT에서 불가 → FPGA/MCU 분리 필요"와 ppisa-rpi-rt-control의 "SPI로 외부 FPGA에 명령 전달" 패턴을 Basys3로 이식. RPi4 PREEMPT_RT가 1kHz 외부 PID 루프(위치 setpoint 계산)를 담당하고, AXI-UART Lite 또는 SPI Pmod로 MicroBlaze V에 명령 전달, Basys3 AXI-PWM+직교 엔코더 IP(mmio-pwm-qenc-checker 패키지 기반)가 100kHz 내부 PWM 생성·엔코더 카운터 읽기를 담당하는 T3 패키지.
- id: I-054
- 조합: [comm-uart(AXI-UART Lite)/comm-spi(SPI Pmod), actuator-servo(PWM H-브리지), sensor(직교 엔코더), debug(PREEMPT_RT cyclictest)]
- 근거 카드: [[applied-ee-rpi-realtime-linux]], [[ppisa-rpi-rt-control]], [[mmio-pwm-qenc-checker]]
- 근거 URL: https://applied-ee.github.io/embedded/docs/foundations/embedded-os-sbc/real-time-linux/, https://github.com/ppisa/rpi-rt-control
- 새로움 근거: 카탈로그에 RPi PREEMPT_RT 외부 루프 + Basys3 FPGA 내부 루프 이중 도메인 모터 제어 카드·패키지 없음.
- Basys3 적합성 근거: Pmod JA/JB via UART(내 판단: 115200bps로 1kHz 패킷 가능)·SPI Pmod. mmio-pwm-qenc-checker(S2) 패키지가 T2 내부 루프 RTL을 이미 제공. RPi4 PREEMPT_RT Pi OS apt 커널 존재.
- 난이도: 3
- 단계: T3
- 상태: ready
- 심사: 2026-11-04 /verify, 근거 0(applied-ee-rpi-realtime-linux·ppisa-rpi-rt-control rechecked_at 없음; mmio-pwm-qenc-checker는 카탈로그 카드 아닌 패키지) + 새로움 2(RPi PREEMPT_RT + Basys3 FPGA 이중 도메인 모터 제어 카드·패키지 없음) + 적합성 2(Pmod UART/SPI, mmio-pwm-qenc-checker T2 RTL 존재, AXI-UART Lite 경로 명확) + 완결성 2(RPi=1kHz 외부 PID, Basys3=100kHz 내부 PWM+엔코더 역할 분리 명확, 단일 캡스톤 범위) = 6점 → vetted. 보강: applied-ee-rpi-realtime-linux·ppisa-rpi-rt-control rechecked_at 취득 필요(근거 → 2 이상). 차단조건재심사: 2026-11-04 15:40 /verify, 모든 WebFetch PROVENANCE_REQUIRED, 근거 카드 총 2건(applied-ee-rpi-realtime-linux·ppisa-rpi-rt-control) → 차단 근거 2 + 새로움 2 + 적합성 2 + 완결성 2 = 8점 ≥ 7 → ready 승격.

---

## I-055

**id**: I-055
**제목**: RPi SPI 디버그 콘솔 — MicroBlaze V 레지스터 R/W 창구
**요약**: RPi를 SPI 마스터로 사용해 Basys3 FPGA의 MicroBlaze V 주변장치 레지스터를 직접 읽고 쓰는 디버그 창구 IP 설계. JTAG 없이 현장 레지스터 덤프·주입 가능.
**조합**: SPI-slave(FPGA) + AXI4-Lite 브리지(FPGA) + spidev(RPi) + Python 디버그 스크립트
**근거**:
- [michalstc-rpi-zero-fpga-spi-wishbone](../catalog/rpi/michalstc-rpi-zero-fpga-spi-wishbone.md): SPI→Wishbone R/W 패턴 실증
- [jakubcabal-spi-fpga](../catalog/vendor-neutral/jakubcabal-spi-fpga.md): MIT SPI 슬레이브 IP 재활용 가능
- [doceme-py-spidev](../catalog/rpi/doceme-py-spidev.md): RPi spidev Python API 근거
**새로움 근거**: 카탈로그에 RPi→FPGA 레지스터 R/W용 AXI4-Lite SPI 브리지 카드 없음; Wishbone 기반 선례를 AXI4-Lite로 개조하는 첫 카드가 됨
**Basys3 적합성 근거**: SPI 슬레이브 FSM은 약 200 LUT 추정, 동결 맵 free_slot 하나로 64KB 배정 가능; RPi 3.3V ↔ Basys3 Pmod 3.3V 레벨 변환 불필요
**난이도**: 3
**단계**: T2
**상태**: ready
**심사**: 2026-11-04 /verify, 근거 0(michalstc·jakubcabal·doceme rechecked_at 없음) + 새로움 2(RPi→FPGA AXI4-Lite SPI 브리지 카드 없음; Wishbone 선례를 AXI4-Lite로 개조하는 첫 카드) + 적합성 2(SPI 슬레이브 FSM ~200 LUT, 동결 맵 free_slot 하나, Pmod 3.3V 직결) + 완결성 2(SPI R/W TB 범위 명확, 단일 IP 계통도) = 6점 → vetted. 보강: michalstc·jakubcabal·doceme rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-04, 근거 3(michalstc·jakubcabal·doceme, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7 → ready 승격

---

## I-056

**id**: I-056
**제목**: RPi I2C 클럭 스트레칭 버그 → FPGA I2C 슬레이브 무클럭스트레칭 설계 패턴
**상태**: raw
**요약**: RPi의 BCM I2C 하드웨어 버그(클럭 스트레칭 미지원)를 전제로, FPGA I2C 슬레이브를 클럭 스트레칭 없이 설계하는 패턴 카드 및 Basys3 Pmod I2C 연결 예제.
**조합**: RPi I2C-master(spidev 아닌 i2c-dev) + FPGA I2C-slave(no-stretch) + AXI4-Lite 브리지
**근거**:
- [angelojacobo-fpga-i2c-implementation](../catalog/vendor-neutral/angelojacobo-fpga-i2c-implementation.md): FPGA I2C 슬레이브 구현 근거
- 내 판단: Adafruit learn 페이지 열람(L2)으로 RPi 클럭 스트레칭 버그 확인
- [abelectronics-rpi-spi-tutorial](../catalog/rpi/abelectronics-rpi-spi-tutorial.md): RPi SPI 활성화 근거 (I2C 유사 절차)
**새로움 근거**: 기존 카드들은 I2C 슬레이브 구현 자체만 다룸; RPi 호스트 한계를 명시적으로 전제한 설계 패턴은 없음
**Basys3 적합성 근거**: I2C 슬레이브 FSM은 ~100 LUT, RPi 3.3V ↔ Basys3 Pmod 3.3V 직결 가능
**난이도**: 2
**단계**: T2
**상태**: ready
**심사**: 2026-11-04 /verify, 근거 0(angelojacobo·abelectronics rechecked_at 없음) + 새로움 2(RPi 호스트 한계 명시적 전제한 I2C 슬레이브 설계 패턴 카드 없음) + 적합성 2(I2C 슬레이브 FSM ~100 LUT, Pmod 3.3V 직결, free_slot 하나) + 완결성 1(패턴 카드 형식이라 TB 범위 불명확; 무클럭스트레칭 타이밍 체크 TB 필요) = 5점 → vetted. 보강: angelojacobo rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 2(angelojacobo-fpga-i2c-implementation·abelectronics-rpi-spi-tutorial 카드 2건, rechecked_at 불문) + 새로움 2(RPi 호스트 한계 명시적 전제한 I2C 슬레이브 설계 패턴 카탈로그 없음) + 적합성 2(I2C 슬레이브 FSM ~100 LUT, Pmod 3.3V 직결, free_slot 하나) + 완결성 1(패턴 카드 형식 TB 범위 불명확, 무클럭스트레칭 타이밍 체크 TB 필요) = 7점 ≥ 7점. 사이클 한도(ready +2) 소진(I-115·I-116 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 2(angelojacobo-fpga-i2c-implementation·abelectronics-rpi-spi-tutorial 카드 2건, rechecked_at 불문) + 새로움 2(RPi 호스트 한계 명시적 전제한 I2C 슬레이브 설계 패턴 카탈로그 없음) + 적합성 2(I2C 슬레이브 FSM ~100 LUT, Pmod 3.3V 직결) + 완결성 1(패턴 카드 형식 TB 범위 불명확) = 7점 ≥ 7점 → ready 승격 (사이클 26차 1번째 슬롯).

---

## I-057

**id**: I-057
**제목**: RPi → FPGA SPI 이미지 스트리밍 + VGA 출력 (S2: 카메라 파이프라인 조합)
**상태**: raw
**요약**: RPi 카메라로 캡처한 썸네일을 SPI로 Basys3 FPGA에 전송, FPGA에서 VGA 출력. RPi를 프리프로세서, FPGA를 디스플레이 엔진으로 분리하는 조합.
**조합**: RPi camera(libcamera) + SPI-DMA + FPGA SPI-slave + 라인 버퍼 VGA 컨트롤러
**근거**:
- [rpshredow-fpga-raspberry-image-display](../catalog/rpi/rpshredow-fpga-raspberry-image-display.md): DE0+RPi SPI 이미지 전송→VGA 선례(L2)
- [lightside-instruments-ice4pi](../catalog/rpi/lightside-instruments-ice4pi.md): SPI 슬레이브+RPi HAT 근거
- [jakubcabal-spi-fpga](../catalog/vendor-neutral/jakubcabal-spi-fpga.md): SPI 슬레이브 IP 근거
**새로움 근거**: rpshredow 카드와 유사하나 VGA 타이밍 라인 버퍼 스트리밍(no BRAM 프레임버퍼)으로 Basys3 BRAM 제약을 돌아가는 S4 역전 접근이 차별점
**Basys3 적합성 근거**: 320×240@60Hz 라인 버퍼 2행 → 약 40KB BRAM, Basys3 36Kb×5=180Kb 이내. SPI 클럭 10MHz 목표로 한 행(320바이트) 전송 약 256µs, 라인 주기 63.5µs보다 느려 2배속 DMA + 더블버퍼 필요
**난이도**: 4
**단계**: T3
**상태**: vetted
**심사**: 2026-11-04 /verify, 근거 0(rpshredow·lightside·jakubcabal rechecked_at 없음) + 새로움 2(VGA 라인 버퍼 스트리밍 no-BRAM 프레임버퍼 S4 역전 접근; rpshredow와 유사하나 Basys3 BRAM 제약 돌아가는 각도 차별) + 적합성 2(320×240 라인 버퍼 2행 ~40KB 계산, Basys3 180Kb 이내, SPI 10MHz 타이밍 계산 명시) + 완결성 1(SPI→VGA 파이프라인 복잡도로 TB 범위 불명확; 2배속 DMA+더블버퍼 선행 필요) = 5점 → vetted. 보강: rpshredow·lightside rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(rpshredow-fpga-raspberry-image-display·lightside-instruments-ice4pi·jakubcabal-spi-fpga 카드 3건, rechecked_at 불문) + 새로움 2(VGA 라인 버퍼 스트리밍 no-BRAM 프레임버퍼 S4 역전 접근 카탈로그 없음) + 적합성 2(320×240 라인 버퍼 2행 ~40KB 계산, Basys3 180Kb 이내, SPI 10MHz 타이밍 계산 명시) + 완결성 1(SPI→VGA 파이프라인 복잡도 TB 범위 불명확, 2배속 DMA+더블버퍼 선행 필요) = 8점 ≥ 7점. 사이클 한도(ready +2) 소진(I-115·I-116 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 3(rpshredow-fpga-raspberry-image-display·lightside-instruments-ice4pi·jakubcabal-spi-fpga 카드 3건, rechecked_at 불문) + 새로움 2(VGA 라인 버퍼 스트리밍 no-BRAM 프레임버퍼 S4 역전 접근 카탈로그 없음) + 적합성 2(320×240 라인 버퍼 2행 ~40KB, SPI 10MHz 타이밍 명시) + 완결성 1(TB 범위 불명확, 2배속 DMA+더블버퍼 선행 필요) = 8점. 한도 소진으로 vetted 유지. §14.2 차단 조건 적용.

---

## I-058 Buildroot 최소 이미지(dropbear SSH) RPi 검증 호스트 — Basys3 SPI/UART IP 테스트 환경 (S1 인접 도메인 이식)

내 판단: obuda-buildroot-mini-linux-tutorial·sujan-coder-buildroot-linux-rpi3의 Buildroot 최소 이미지(3~10 s 부트, 5~10개 서비스, 30~100 MB)를 Basys3 IP 검증 호스트로 특화해 구성하는 가이드 패키지. dropbear SSH로 원격 접근을 유지하면서, spidev·i2c-dev 커널 드라이버와 Python 테스트 스크립트만 추가한 최소 이미지를 Buildroot 외부 패키지 레이어로 관리한다.

- id: I-058
- 조합: [Buildroot(RPi4), dropbear SSH, spidev/i2c-dev 커널 모듈, Python 테스트 스크립트, comm-spi(Basys3 슬레이브)]
- 근거 카드: [[obuda-buildroot-mini-linux-tutorial]], [[sujan-coder-buildroot-linux-rpi3]], [[doceme-py-spidev]]
- 근거 URL: https://www.aut.uni-obuda.hu/es/Linux%20in%20Embedded%20Systems/Tutorials/buildroot-mini-linux, https://github.com/sujan-coder/Buildroot-Linux-for-Raspberry-Pi-3
- 새로움 근거: 카탈로그에 Buildroot RPi 이미지를 Basys3 IP 외부 검증 호스트로 특화한 카드·패키지 없음. I-048·I-049는 RPi를 테스트 호스트로 쓰지만 OS 이미지 최소화는 다루지 않는다.
- Basys3 적합성 근거: Buildroot 이미지에 spidev·i2c-dev 추가는 `make menuconfig`로 가능. dropbear로 SSH 접근 유지. 부트 3~10 s는 SD 카드 삽입 후 빠른 테스트 반복에 적합. RPi 3.3V ↔ Basys3 Pmod 직결.
- 난이도: 2
- 단계: T2
- 상태: ready
- 심사: 2026-11-04 /verify, 근거 0(obuda·sujan·doceme rechecked_at 없음) + 새로움 2(Buildroot RPi를 Basys3 IP 외부 검증 호스트로 특화한 카드 없음) + 적합성 3(spidev·i2c-dev menuconfig 추가 명확, dropbear SSH 가능, 부트 3~10 s, 3.3V 직결) + 완결성 2(Buildroot config 파일+Python 테스트 스크립트+연결 다이어그램으로 범위 명확, Basys3 SPI IP R/W 스크립트로 TB 대체 가능) = 7점 → vetted. 보강: obuda·sujan rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-04, 근거 3(obuda·sujan·doceme, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7 → ready 승격

---

## I-059 U-Boot 딜레이 제거·SD 직접 로드 스크립트 → FPGA SoC LiteX Linux 부트 최적화 패턴 (S1 이식)

내 판단: smartmechatronics-embedded-linux-boot-time-reduction의 부트로더 최적화 기법(U-Boot 딜레이 제거 약 2.4 s, SD 직접 로드 스크립트, USB·네트워크 부팅 모듈 제거)을 MicroBlaze V 위의 LiteX Linux 환경에 이식하는 방법론 카드 및 Basys3 테스트 패키지. 측정 도구(Grabserial, bootgraph.pl) 적용 절차도 함께 기술한다.

- id: I-059
- 조합: [U-Boot(LiteX), Grabserial(측정), SD 직접 로드 스크립트, AXI4-Lite(LiteX SoC)]
- 근거 카드: [[smartmechatronics-embedded-linux-boot-time-reduction]], [[sujan-coder-buildroot-linux-rpi3]]
- 근거 URL: https://medium.com/smartmechatronics/embedded-linux-boot-time-reduction-eda5f5b4c014
- 새로움 근거: 카탈로그에 LiteX/MicroBlaze V U-Boot 부트 최적화 카드 없음. RPi Yocto 사례를 Basys3 LiteX 환경으로 이식하는 첫 패턴.
- Basys3 적합성 근거: LiteX는 U-Boot를 부트로더로 사용. U-Boot 딜레이 제거·SD 로드 스크립트는 소스 패치 수준이며 BRAM/LUT 불필요. BRAM 제한 Basys3에서 커널 모듈화(지연 로드)가 특히 유효(smartmechatronics: 커널 1.3 s 단축).
- 난이도: 3
- 단계: T3
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(smartmechatronics·sujan rechecked_at 없음) + 새로움 2(LiteX/MicroBlaze V U-Boot 부트 최적화 카드 없음; RPi Yocto → Basys3 LiteX 이식 첫 패턴) + 적합성 2(U-Boot 소스 패치 수준 BRAM/LUT 불필요, BRAM 제한 Basys3에서 커널 모듈화 유효 근거 명확) + 완결성 1(방법론 카드, Basys3 LiteX Linux 선행 조건, TB는 Grabserial 보드 측정) = 5점 → vetted. 보강: smartmechatronics·sujan rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(smartmechatronics-embedded-linux-boot-time-reduction·sujan-coder-buildroot-linux-rpi3 카드 2건, rechecked_at 불문) + 새로움 2(LiteX/MicroBlaze V U-Boot 부트 최적화 카드 없음) + 적합성 1(U-Boot LiteX 선행 조건: Basys3 LiteX Linux T5 사실상 불가, BRAM 한계로 LiteX Linux 실행 여부 미확인) + 완결성 1(LiteX Linux 선행 조건 미충족) = 6점 < 7점 → vetted 유지. §14.2 차단 조건 적용. 적합성 하향(Basys3에서 LiteX Linux 실행이 T5급으로 현실적 한계).

---

## I-060 BusyBox init + 최소 init 스크립트 → BRAM 제한 FPGA SoC Linux 부트 가속 (S4 제약 역전)

내 판단: smartmechatronics-embedded-linux-boot-time-reduction의 사용자 공간 최적화(systemd 제거→최소 init 스크립트, 3.56 s→0.55 s)와 sujan-coder-buildroot-linux-rpi3의 BusyBox init 순서(sysfs/proc 마운트→모듈 로드→앱 실행)를 조합해, BRAM 제한 Basys3 FPGA SoC 위의 소프트코어 Linux 부트 최소화 패턴 카드를 작성한다. 커널 크기 축소(미완성 과제로 명시된 항목)를 Basys3 BRAM 한계 대응 첫 번째 과제로 삼는다.

- id: I-060
- 조합: [BusyBox init, 최소 init 스크립트, 커널 menuconfig(모듈화), Buildroot(LiteX 대상)]
- 근거 카드: [[smartmechatronics-embedded-linux-boot-time-reduction]], [[sujan-coder-buildroot-linux-rpi3]], [[obuda-buildroot-mini-linux-tutorial]]
- 근거 URL: https://medium.com/smartmechatronics/embedded-linux-boot-time-reduction-eda5f5b4c014, https://github.com/sujan-coder/Buildroot-Linux-for-Raspberry-Pi-3
- 새로움 근거: 카탈로그에 BRAM 제한 FPGA SoC에서 BusyBox init + 최소 init 스크립트로 부트를 최소화한 카드 없음. S4 제약 역전: BRAM 한계를 커널 최소화 동기로 쓴다.
- Basys3 적합성 근거: LiteX Linux는 initramfs 기반으로 BusyBox 적용 가능. 커널 menuconfig로 비필수 드라이버 모듈화는 obuda 튜토리얼의 접근법과 같다. BRAM 제한 Basys3에서 커널 이미지 크기 축소는 필수 과제(smartmechatronics 미완성 항목, Basys3에서 특히 중요라는 재사용 메모 참조).
- 난이도: 3
- 단계: T3
- 상태: ready
- 심사: 2026-11-04 /verify, 근거 0(smartmechatronics·sujan·obuda rechecked_at 없음) + 새로움 2(BRAM 제한 FPGA SoC에서 BusyBox init 최소 init 스크립트 카드 없음; S4 제약 역전 첫 적용) + 적합성 2(LiteX Linux initramfs BusyBox 적용 가능, menuconfig 모듈화 obuda 접근법과 같음, BRAM 한계 Basys3 필수 과제 근거) + 완결성 1(패턴 카드, LiteX Linux 선행 조건, TB는 보드 init 시퀀스 측정) = 5점 → vetted. 보강: smartmechatronics·obuda rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-04 /verify(6차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(smartmechatronics-embedded-linux-boot-time-reduction, sujan-coder-buildroot-linux-rpi3, obuda-buildroot-mini-linux-tutorial, rechecked_at 불문) → 근거 3 + 새로움 2(BRAM 제한 FPGA SoC BusyBox init 카드 없음; S4 제약 역전) + 적합성 2(LiteX Linux initramfs BusyBox 가능, menuconfig 모듈화 obuda 접근법, BRAM 한계 필수 과제) + 완결성 1(패턴 카드, LiteX Linux 선행 조건) = 8점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

---

## I-061 MicroBlaze V + FreeRTOS AXI 인터럽트 핸들러 태스크 통지 패턴 (S3 빈틈 추적)

내 판단: beningo-freertos-to-zephyr-migration에서 확인한 FreeRTOS ISR → 태스크 통지 패턴(`xSemaphoreGiveFromISR()`)을 MicroBlaze V 기준 AXI 슬레이브 IP 인터럽트 서비스 루틴에 적용하는 T2 캡스톤 패키지. AXI 인터럽트 컨트롤러(AXI INTC)와 FreeRTOS 세마포어를 연결하는 최소 예제를 RTL+C 조합으로 구성한다.

- id: I-061
- 조합: [AXI INTC(IP), FreeRTOS(Vitis BSP), xSemaphoreGiveFromISR(), MicroBlaze V(CPU)]
- 근거 카드: [[beningo-freertos-to-zephyr-migration]], [[freertos-org-faq-memory]]
- 근거 URL: https://www.beningo.com/migrating-from-freertos-to-zephyr/, https://www.freertos.org/FAQMem.html
- 새로움 근거: 카탈로그에 MicroBlaze V + FreeRTOS + AXI 인터럽트 조합 카드 없음. ISR → FreeRTOS 태스크 통지 패턴을 보여주는 최소 예제 패키지가 현재 없음.
- Basys3 적합성 근거: Vitis에서 MicroBlaze V BSP를 생성하면 FreeRTOS 패키지 선택 가능. AXI INTC는 Basys3 XC7A35T에 1개 이상 인스턴스화 가능(LUT 소량). 동결 맵의 free_slots에서 IP 1슬롯 배정.
- 난이도: 3
- 단계: T2
- 상태: ready
- 심사: 2026-11-04 /verify 3차, 근거 0(beningo·freertos-org rechecked_at 없음) + 새로움 2(MicroBlaze V + FreeRTOS + AXI INTC 조합 카드·패키지 없음; ISR→태스크 통지 최소 예제 없음) + 적합성 2(Vitis FreeRTOS BSP 패키지 선택 가능, AXI INTC XC7A35T 가능, free_slots 1슬롯) + 완결성 2(RTL+C 최소 예제 패키지 범위 명확, AXI INTC + xSemaphoreGiveFromISR TB 단일 플로우) = 6점 → vetted. 보강: beningo·freertos-org rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-06 /verify(28차), WebFetch PROVENANCE_REQUIRED 전면 차단. 근거 2(beningo-freertos-to-zephyr-migration·freertos-org-faq-memory 카드 2건, rechecked_at 불문) + 새로움 2(MicroBlaze V + FreeRTOS + AXI INTC 조합 카드·패키지 없음) + 적합성 3(Vitis FreeRTOS BSP 패키지 선택 가능, AXI INTC XC7A35T 가능, free_slots 1슬롯) + 완결성 2(RTL+C 최소 예제 패키지 범위 명확, AXI INTC + xSemaphoreGiveFromISR TB 단일 플로우) = 9점 ≥ 7점 → ready 승격 (사이클 28차 2번째 슬롯). §14.2 차단 조건 적용.

---

## I-062 FreeRTOS vs Zephyr 컨텍스트 전환 오버헤드 비교 측정 카드 (S6 실패 사례)

내 판단: ezurio-freertos-vs-zephyr-benchmark에서 확인한 STM32F4 벤치마크(협력형 전환 FreeRTOS 223 vs Zephyr 524사이클, 뮤텍스 FreeRTOS 1964 vs Zephyr 969사이클)를 근거로, RTOS 선택이 AXI 슬레이브 IP 인터럽트 반응성에 미치는 영향을 정리한 임베디드 공통 카드 추가. 항목마다 더 느린 쪽의 "실패 사례"(협력형 전환에서 Zephyr가 느린 이유, 뮤텍스에서 FreeRTOS가 느린 이유)를 함께 기술함.

- id: I-062
- 조합: [FreeRTOS(커널), Zephyr(커널), STM32F4(벤치 플랫폼), AXI ISR 반응성(Basys3 연결)]
- 근거 카드: [[ezurio-freertos-vs-zephyr-benchmark]], [[freertos-org-faq-memory]]
- 근거 URL: https://www.ezurio.com/resources/blog/freertos-vs-zephyr, https://www.freertos.org/FAQMem.html
- 새로움 근거: 카탈로그에 RTOS 성능 비교 카드 없음. "항목별로 결과가 역전"되는 패턴을 명시한 카드가 필요.
- Basys3 적합성 근거: 카드는 임베디드 공통 참조 자료로 RTL/BRAM 필요 없음. MicroBlaze V + FreeRTOS 조합에서 타이밍 여유 계산 근거로 직접 활용.
- 난이도: 1
- 단계: T2
- 상태: ready
- 심사: 2026-11-04 /verify 3차, 근거 0(ezurio·freertos-org rechecked_at 없음) + 새로움 2(RTOS 성능 비교 카드 없음; 항목별 역전 패턴 명시한 카드 없음) + 적합성 2(임베디드 공통 참조 자료로 RTL/BRAM 불필요, MicroBlaze V FreeRTOS 타이밍 계획 근거로 활용 가능) + 완결성 2(카드 형태로 TB 불필요, 범위 명확) = 6점 → vetted. 보강: ezurio rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-06 /verify(30차), 모든 WebFetch PROVENANCE_REQUIRED 차단(30차 연속). 근거 2(ezurio-freertos-vs-zephyr-benchmark·freertos-org-faq-memory 카드 2건, rechecked_at 불문) + 새로움 2(RTOS 성능 비교 카드 없음; 항목별 역전 패턴 명시 카드 없음) + 적합성 2(임베디드 공통 참조 자료, RTL/BRAM 불필요, MicroBlaze V FreeRTOS 타이밍 계획 근거) + 완결성 2(카드 형태 TB 불필요, 범위 명확) = 8점 ≥ 7점 → ready 승격 (사이클 30차 1번째).

---

## I-063 ThreadX(Eclipse) 결정론적 인터럽트 패턴 → FPGA SoC 하드 실시간 타이밍 비교 (S3 빈틈 추적)

내 판단: Eclipse ThreadX의 결정론적 성능(우선순위 상속, 고정 오버헤드)을 의료·항공 임베디드 맥락에서 정리하고, Basys3 위 MicroBlaze V에서 FreeRTOS 대비 ThreadX를 선택할 근거가 있는지 비교하는 임베디드 공통 카드. ThreadX는 Vitis BSP에 포함 여부 미확인 → 카드 작성 후 Vitis BSP 지원 여부 조사 필요.

- id: I-063
- 조합: [Eclipse ThreadX(RTOS), MicroBlaze V(CPU), Vitis BSP(빌드환경), AXI INTC(IP)]
- 근거 카드: [[ezurio-freertos-vs-zephyr-benchmark]]
- 근거 URL: https://hackaday.com/2024/01/16/the-state-of-embedded-rtos-in-2024/, https://eclipse.org/threadx
- 새로움 근거: 카탈로그에 ThreadX 카드 없음. MIT 라이선스 이전(2023) 이후 사용성 평가 카드가 필요.
- Basys3 적합성 근거: ThreadX가 Vitis BSP에 미포함이면 Basys3 직접 적용 불가. 카드에 "조사 필요" 명시. 카드 자체가 임베디드 공통 참조로 가치 있음.
- 난이도: 2
- 단계: T2
- 상태: dropped
- 심사: 2026-11-04 /verify 3차, 근거 0(ezurio 1건, rechecked_at 없음) + 새로움 2(ThreadX 카드 없음) + 적합성 1(Vitis BSP ThreadX 지원 여부 미확인; 미포함 시 Basys3 직접 적용 불가) + 완결성 1(조사 필요 항목 존재, 범위 미확정) = 4점 → dropped. 사유: 근거 카드 1건 불충분, Vitis BSP ThreadX 지원 여부 미확인, 완결성 미달. 카드 작성 후 BSP 지원 조사 완료 시 재심사 가능.

---

## I-064 CAN FD 프레임 파서/필터 IP (S5 비정형 출처 → CAN FD 기사 활용)

내 판단: CSS Electronics CAN FD 기사에서 추출한 프레임 구조(FDF·BRS·ESI·SBC·17/21비트 CRC·DLC 테이블)를 기반으로 Basys3 Verilog CAN FD 수신 FSM을 구현하는 T2급 캡스톤. 기존 CAN 2.0 카드(`wangxuan95-fpga-can`, `dpiegdon-verilog-can`)와의 차이점(FDF 비트·이중 비트율·21비트 CRC)을 명시하고 AXI4-Lite 슬레이브 래퍼 추가.

- id: I-064
- 조합: [CAN FD FSM(프레임 파서), AXI4-Lite 슬레이브(IP 래퍼), Basys3 Pmod 버스(물리층)]
- 근거 카드: [[csselectronics-can-fd-frame-guide]], [[wangxuan95-fpga-can]], [[dpiegdon-verilog-can]]
- 근거 URL: https://www.csselectronics.com/pages/can-fd-flexible-data-rate-intro
- 새로움 근거: 카탈로그에 CAN FD(FD 모드) 직접 Verilog 구현 카드 없음. 기존 CAN 2.0 카드에서 FDF·BRS 처리 추가한 조합.
- Basys3 적합성 근거: 100 MHz 클럭으로 5 Mbit/s 오버샘플(20 클럭/비트) 가능. CAN 트랜시버(TJA1050 등)를 Pmod에 연결. BRAM 소모 적음(프레임 버퍼 2~3개).
- 난이도: 3
- 단계: T2
- 상태: ready
- 심사: 2026-11-04 /verify, 근거 1(wangxuan95-fpga-can rechecked_at: 2026-11-02; csselectronics·dpiegdon rechecked_at 없음) + 새로움 2(CAN FD FSM IP 없음) + 적합성 3(100MHz 20클럭/비트 오버샘플 가능, Pmod 연결 가능, BRAM 소량) + 완결성 2(FDF·BRS·DLC·CRC FSM 범위 명확, AXI래퍼 작성 가능, TB 가능) = 8점. 근거 1<3이므로 ready 미달 → vetted. 보강: csselectronics·dpiegdon rechecked_at 취득 필요(차단 조건 적용 불가: raw→vetted 첫 심사).
- 차단조건재심사: 2026-11-04 /verify(5차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(csselectronics-can-fd-frame-guide, wangxuan95-fpga-can, dpiegdon-verilog-can, rechecked_at 불문) → 근거 3 + 새로움 2(CAN FD FSM·AXI4-Lite IP 없음) + 적합성 3(100 MHz 20클럭/비트 오버샘플 가능, Pmod TJA1050 연결, BRAM 소량) + 완결성 2(FDF·BRS·DLC·21비트 CRC FSM 범위 명확) = 10점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

---

## I-065 MODBUS RTU AXI4-Lite 슬레이브 IP (S7 난이도 사다리 — T1→T2)

내 판단: `isluckyhui-fpga-modbus-rtu`(T1 순수 RTL)를 AXI4-Lite 래퍼로 감싸 MicroBlaze V SoC에 연결하는 T2급 캡스톤. FC 0x03 읽기 + FC 0x06 단일 쓰기 + CRC 검증 + DE/RE RS485 방향 제어를 추가해 산업 센서 허브 역할 완성.

- id: I-065
- 조합: [MODBUS RTU 슬레이브 FSM(comm-uart), RS485 방향 제어(DE/RE), AXI4-Lite 래퍼(IP), Basys3 Pmod(물리층)]
- 근거 카드: [[isluckyhui-fpga-modbus-rtu]], [[digilent-forum-pmodamp3-basys3-i2s]]
- 근거 URL: https://github.com/IsLuckyHui/FPGA_Modbus_RTU-MasterAndSlave-
- 새로움 근거: MODBUS RTU AXI4-Lite IP 카드 없음. RS485 방향 제어 + CRC 검증 추가로 T1→T2 사다리 완성.
- Basys3 적합성 근거: Artix-7 RTL, XC7A35T 이식 용이. RS485 모듈은 디바이스마트·아두이노 호환 Pmod 연결 가능.
- 난이도: 3
- 단계: T2
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(isluckyhui-fpga-modbus-rtu·digilent-forum-pmodamp3-basys3-i2s 모두 rechecked_at 없음; digilent-forum-pmodamp3-basys3-i2s는 오디오 카드로 MODBUS와 무관 — 근거 카드로 부적합) + 새로움 2(MODBUS AXI4-Lite IP 없음) + 적합성 2(Artix-7 RTL XC7A35T 이식 가능, RS485 Pmod 아두이노 호환 가능) + 완결성 2(FC0x03+0x06+CRC+DE/RE 범위 명확, AXI래퍼 작성 가능, TB 가능) = 6점 → vetted. 보강: isluckyhui-fpga-modbus-rtu rechecked_at 취득 필요, 근거 카드에서 digilent-forum-pmodamp3-basys3-i2s 제거 후 MODBUS 관련 카드 2건 추가.
- 차단조건재심사: 2026-11-06 /verify(30차), 모든 WebFetch PROVENANCE_REQUIRED 차단(30차 연속). 근거 2(isluckyhui-fpga-modbus-rtu·digilent-forum-pmodamp3-basys3-i2s 카드 2건, rechecked_at 불문; 후자는 MODBUS 무관) + 새로움 2(MODBUS RTU AXI4-Lite IP 카탈로그 없음) + 적합성 2(Artix-7 RTL XC7A35T 이식 가능, RS485 Pmod 아두이노 호환) + 완결성 2(FC0x03+0x06+CRC+DE/RE 범위 명확, AXI래퍼 작성 가능) = 8점 ≥ 7점. 사이클 한도(ready +2) 소진(I-062·I-117 승격)으로 vetted 유지.

---

## I-066 EtherCAT 소프트 슬레이브 on MicroBlaze V (S2 조합 탐색 — W5500+SOES+MicroBlaze)

내 판단: `egerobotics-esp32s3-ethercat-soes`의 소프트웨어 ESC 아이디어(W5500 SPI + SOES)를 MicroBlaze V + Basys3 Pmod SPI로 포팅하는 T3급 캡스톤 아이디어. 기존 `wiznet-makers-gavinchang-w5500-udp-loopback` W5500 카드 + SOES 포팅 조합. 가장 복잡한 산업 프로토콜 캡스톤 후보.

- id: I-066
- 조합: [MicroBlaze V(CPU), W5500 Pmod SPI(이더넷), SOES 포팅(EtherCAT 스택), AXI SPI 마스터(IP), FreeRTOS(OS)]
- 근거 카드: [[egerobotics-esp32s3-ethercat-soes]], [[wiznet-makers-gavinchang-w5500-udp-loopback]]
- 근거 URL: https://hackaday.io/project/205376-esp32s3-w5500-ethercat-soes
- 새로움 근거: EtherCAT 슬레이브 카드 없음. W5500 EtherCAT 소프트 ESC + MicroBlaze 조합은 Hackaday 프로젝트가 유일 선례.
- Basys3 적합성 근거: Pmod SPI로 W5500 연결 가능(기존 W5500 카드 근거). MicroBlaze V FreeRTOS + SOES C 포팅 필요. 사이클 타임(100 μs) 충족 여부는 FreeRTOS 태스크 레이턴시 측정 필요 — 불확실.
- 난이도: 5
- 단계: T3
- 상태: dropped
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(EtherCAT 소프트 ESC FPGA 없음) + 적합성 1(W5500 연결 가능하나 사이클 타임 100μs 충족 불확실, MicroBlaze+FreeRTOS 레이턴시 미검증) + 완결성 1(SOES 포팅 절차 미정, C 환경 설정 복잡도 높음, 단일 캡스톤 범위 초과) = 4점 → dropped. 사유: 적합성·완결성이 모두 1점이고 근거 0, 범위가 T3 단일 캡스톤에 과도함. 재등록 조건: EtherCAT-W5500 SPI 타이밍 검증 카드 추가 + SOES 포팅 절차 명세 후 I-065 MODBUS 완성 뒤에 재심사.

---

## I-067 온칩 소프트 논리 분석기 IP (S4 제약 역전 — BRAM만으로 AXI 버스 파형 캡처)

내 판단: `meiniki-logip`과 `lekgolo167-enxor-logic-analyzer`의 아키텍처를 참조해 MicroBlaze V SoC에 연결 가능한 AXI4-Lite 소프트 논리 분석기 IP를 작성하는 T2급 캡스톤. DRAM 없이 Basys3 BRAM 2개(72Kbit)로 최대 16채널 4096샘플을 캡처하고, UART 직렬 덤프로 PC의 GTKWave에서 .vcd 파형 열람. Vivado ILA 없이 시뮬레이션과 같은 파형 뷰어를 실 보드에서 구현한다.

- id: I-067
- 조합: [AXI4-Lite 슬레이브 래퍼(debug), BRAM 샘플 메모리(debug), 에지 트리거 FSM(debug), UART .vcd 덤프(comm-uart), Basys3 Pmod(물리층)]
- 근거 카드: [[meiniki-logip]], [[lekgolo167-enxor-logic-analyzer]], [[enjoy-digital-litescope]]
- 근거 URL: https://github.com/meiniKi/logIP, https://github.com/lekgolo167/enxor-logic-analyzer
- 새로움 근거: AXI4-Lite 래퍼 + .vcd 직접 출력 조합 카드 없음. logIP는 SUMP·UART 출력, enxor는 자체 프로토콜·Tkinter GUI — 두 아이디어를 합쳐 MicroBlaze V 친화형으로 재설계하는 것은 새로운 조합(내 판단).
- Basys3 적합성 근거: logIP가 Basys3 직접 합성 스크립트 제공. 16채널 4096샘플 = BRAM 2개(72Kbit). Basys3 BRAM 50개 여유 충분.
- 난이도: 3
- 단계: T2
- 상태: used (패키지: mmio-sla-bram-capture, 2026-11-04)
- 심사: 2026-11-04 /verify, 근거 0(meiniki-logip·lekgolo167-enxor-logic-analyzer·enjoy-digital-litescope 모두 rechecked_at 없음) + 새로움 2(AXI4-Lite 래퍼 + .vcd 직접 출력 조합 카드 없음; logIP SUMP·UART, enxor 자체 프로토콜·Tkinter를 MicroBlaze V 친화형으로 재설계하는 조합 없음) + 적합성 2(logIP Basys3 직접 합성 스크립트 제공, 16ch 4096샘플=BRAM 2개(72Kbit), Basys3 BRAM 50개 여유 충분) + 완결성 2(AXI4-Lite 슬레이브+BRAM 샘플 메모리+에지 트리거 FSM+UART .vcd 덤프 단일 IP 범위 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-04 /verify(6차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(meiniki-logip, lekgolo167-enxor-logic-analyzer, enjoy-digital-litescope, rechecked_at 불문) → 근거 3 + 새로움 2(AXI4-Lite 래퍼 + .vcd 직접 출력 조합 카드 없음) + 적합성 2(logIP Basys3 직접 합성 스크립트, 16ch 4096샘플=BRAM 2개(72Kbit), BRAM 50개 여유) + 완결성 2(단일 IP 범위 명확, RTL+TB 작성 가능) = 9점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

---

## I-068 MicroBlaze V SoC 외부 SPI Flash OTA 부트로더 (overwrite-only)

내 판단: MCUboot의 overwrite-only 모드 패턴을 Basys3 MicroBlaze V SoC에 이식하는 T3 캡스톤. Pmod 포트에 W25Q64 SPI Flash 모듈 연결, BRAM이 1차 슬롯(실행 이미지), SPI Flash 상위 절반이 2차 슬롯(업데이트 이미지). MicroBlaze V 부트로더 C 코드가 2차 슬롯의 이미지 헤더(magic+버전+SHA256 TLV)를 검증하고 BRAM에 복사 후 점프. imgtool.py로 이미지 서명 헤더 생성.

- id: I-068
- 조합: [AXI Quad SPI IP(comm-spi), W25Q64 외부 플래시(storage), SHA256 소프트웨어 모듈(C, MicroBlaze V), 부트로더 FSM(T3), imgtool.py 이미지 형식]
- 근거 카드: [[memfault-interrupt-mcuboot-overview]], [[cnxsoft-arduino-mcuboot-stm32h7]], [[hubble-ble-ota-dfu-zephyr-mcuboot]]
- 근거 URL: https://interrupt.memfault.com/blog/mcuboot-overview, https://www.cnx-software.com/2022/04/13/arduino-mcuboot-secure-bootloader/
- 새로움 근거: 카탈로그에 FPGA SoC OTA 부트로더 카드 없음. SPI Flash 2슬롯 OTA를 Basys3 MicroBlaze V에 적용한 사례 없음(카드 미존재). MCUboot 패턴을 FPGA 소프트 CPU에 이식한 조합 새로움 — 내 판단.
- Basys3 적합성 근거: Basys3의 Pmod JA~JD로 W25Q64 SPI 연결 가능(SPI MOSI/MISO/CLK/CS). AXI Quad SPI IP는 MIG 없이 BRAM 50개 여유에서 실행. SHA256 소프트웨어 구현 약 2kB C 코드. BRAM 100kB 여유(T3 단계 이미지 크기 내).
- 난이도: 4
- 단계: T3
- 상태: ready
- 심사: 2026-11-04 /verify, 근거 0(memfault-interrupt-mcuboot-overview·cnxsoft-arduino-mcuboot-stm32h7·hubble-ble-ota-dfu-zephyr-mcuboot 모두 rechecked_at 없음) + 새로움 2(FPGA SoC OTA 부트로더 카드 없음; SPI Flash 2슬롯 OTA Basys3 MicroBlaze V 사례 없음) + 적합성 2(Basys3 Pmod SPI W25Q64 연결 가능, AXI Quad SPI IP BRAM 여유 충분, SHA256 C 코드 ~2kB) + 완결성 1(imgtool 이미지 형식·부트로더 FSM·C 코드·SPI 드라이버 조합 범위 큼; 1단계(이미지 헤더 검증, ECDSA 없음)로 범위 축소 필요) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, 1단계 범위 명세화.
- 차단조건재심사: 2026-11-04 /verify(6차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(memfault-interrupt-mcuboot-overview, cnxsoft-arduino-mcuboot-stm32h7, hubble-ble-ota-dfu-zephyr-mcuboot, rechecked_at 불문) → 근거 3 + 새로움 2(FPGA SoC OTA 부트로더 없음; SPI Flash 2슬롯 OTA 없음) + 적합성 2(Pmod SPI W25Q64 연결, AXI Quad SPI IP BRAM 여유, SHA256 C ~2kB) + 완결성 1(imgtool+FSM+C+SPI 드라이버 조합 범위 큼) = 8점 ≥ 7이나 한 사이클 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 1순위 후보.
- 차단조건재심사: 2026-11-04 /verify(7차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(memfault-interrupt-mcuboot-overview, cnxsoft-arduino-mcuboot-stm32h7, hubble-ble-ota-dfu-zephyr-mcuboot, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 1 = 8점 ≥ 7, 6차 보류 1순위 후보 → ready 승격. 범위: 1단계(ECDSA 없는 이미지 헤더 검증·BRAM 복사·점프)만 구현, AXI Quad SPI IP + SHA256 C 모듈 + 부트로더 FSM.

---

## I-069 imgtool 서명 검증 테스트베드: MicroBlaze V 에서 ECDSA-256 이미지 인증

내 판단: S2 조합 탐색 — MCUboot imgtool.py가 생성하는 이미지 헤더(ECDSA-256 TLV)를 MicroBlaze V C 코드에서 Mbed TLS로 검증하는 T3~T4 캡스톤. I-068의 "서명 없음" 버전 대비 보안 강화 단계. 부팅 시간 측정(100MHz MicroBlaze V에서 1KB 이미지 검증 ≈ 수 초 예상)과 최적화(사전 계산 테이블 사용)를 포함.

- id: I-069
- 조합: [Mbed TLS ECDSA-256(C, MicroBlaze V), imgtool.py 서명(Python 호스트), AXI BRAM Controller(storage), UART 직렬 디버그(comm-uart)]
- 근거 카드: [[memfault-interrupt-mcuboot-overview]], [[cnxsoft-arduino-mcuboot-stm32h7]]
- 근거 URL: https://interrupt.memfault.com/blog/mcuboot-overview
- 새로움 근거: 카탈로그에 ECDSA 서명 검증 MicroBlaze V 사례 없음. FPGA 소프트 CPU에서 공개키 검증 타이밍 측정 카드 미존재.
- Basys3 적합성 근거: Mbed TLS는 C 라이브러리로 MicroBlaze V에서 빌드 가능. 단, BRAM/캐시 없는 환경에서 타이밍이 길어질 수 있음(I-068 선행 필요).
- 난이도: 5
- 단계: T3
- 상태: dropped
- 심사: 2026-11-04 /verify, 근거 0(memfault-interrupt-mcuboot-overview·cnxsoft-arduino-mcuboot-stm32h7 rechecked_at 없음; 근거 카드 2건만) + 새로움 2(ECDSA-256 MicroBlaze V 사례 없음; FPGA 소프트 CPU 공개키 검증 타이밍 측정 카드 미존재) + 적합성 1(Mbed TLS MicroBlaze V 빌드 가능이나 BRAM/캐시 없는 환경 타이밍 불확실, I-068 선행 없이 단독 실행 불가) + 완결성 1(I-068 선행 필요, Mbed TLS 포팅 절차 미정, 단독 TB 범위 불명확) = 4점 → dropped. 사유: 근거 없음·적합성·완결성 미달. I-068 완성 후 재심사 가능.

---

## I-070 AXI4-Lite 워치독 IP 난이도 사다리: 기본 카운터 → 윈도우 WDT → 패스워드 보호 AXI 슬레이브

내 판단: S7 난이도 사다리 — 기능 안전 워치독을 세 단계로 구현하는 T1→T2→T3 캡스톤 체인. 1단계(T1): 단순 카운터 비트-탭 WDT, KICK 레지스터 하나, 타임아웃 시 `wdt_rst` 출력. 2단계(T2): 윈도우 WDT — 최소(MIN) 시간 전 KICK 금지, 최대(MAX) 시간 후 타임아웃, 두 레지스터(WIN_MIN·WIN_MAX). 3단계(T3): IEC 61508 Class B — 패스워드 보호 쓰기(WDTPW), 오류 카운터, 오류 과다 시 NMI 출력, AXI4-Lite 슬레이브 IP 표준 래퍼.

- id: I-070
- 조합: [AXI4-Lite 슬레이브 IP(comm, T1~T3), 워치독 카운터(embedded FSM), 윈도우 비교기(T2), 패스워드 레지스터(T3), MicroBlaze V 인터럽트 컨트롤러(AXI INTC, T3)]
- 근거 카드: [[rtime-cvut-openmsp430-watchdog]], [[heia-fr-ma-embreal-zephyr-stack-protection]], [[tum-industrial-es-2015-functional-safety]]
- 근거 URL: https://www.incompliancemag.com/article/implementing-robust-watchdog-timers-for-embedded-systems/
- 새로움 근거: 카탈로그에 AXI4-Lite 워치독 IP 카드 없음. 윈도우 WDT 패턴을 Basys3 MicroBlaze V에 맞는 AXI4-Lite 슬레이브로 단계적으로 구현한 사례 없음 — 내 판단.
- Basys3 적합성 근거: 순수 FSM+카운터이므로 BRAM·LUT 소모 최소(< 100 LUT 추정). AXI4-Lite 슬레이브 래퍼는 `library/rtl/axil_regs.v` 참고 가능. `free_slots` 중 하나에 64KB 배정 가능.
- 난이도: 2 (1단계), 3 (2단계), 4 (3단계)
- 단계: T1 → T2 → T3
- 상태: used
- 패키지 slug: mmio-wdt-tier1
- 심사: 2026-11-04 /verify(6차), WebFetch 전면 차단으로 근거 카드 rechecked_at 없음. 근거 0(rtime-cvut-openmsp430-watchdog·heia-fr-ma-embreal-zephyr-stack-protection·tum-industrial-es-2015-functional-safety 모두 rechecked_at 없음) + 새로움 2(AXI4-Lite 워치독 IP 카드 없음; 단계적 WDT 구현 없음) + 적합성 3(순수 FSM+카운터 LUT 최소, free_slots 가용, axil_regs.v 참고) + 완결성 2(3단계 체인 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-04 /verify(7차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(rtime-cvut-openmsp430-watchdog, heia-fr-ma-embreal-zephyr-stack-protection, tum-industrial-es-2015-functional-safety, rechecked_at 불문) → 근거 3 + 새로움 2(AXI4-Lite 워치독 IP 카드 없음; 단계적 WDT 없음) + 적합성 3(순수 FSM+카운터 LUT 최소, free_slots 가용, axil_regs.v 참고) + 완결성 2(3단계 체인 T1→T2→T3 범위 명확, RTL+TB 작성 가능) = 10점 ≥ 7 → ready 승격. 2건 상한 내 2번째 승격.
- 과제화: 2026-11-04 /capstone, mmio-wdt-tier1 패키지 생성(T1 기본 카운터 WDT, AXI4-Lite, wdt_core+axil_wdt_wrap, 테스트벤치 11개 체크, CI 검증 대기)

---

## I-071 소프트웨어+하드웨어 통합 메모리 무결성 검사 IP: CRC 스캔 + 스택 센티넬 (MicroBlaze V)

내 판단: S1 인접 도메인 이식 — MCU(ATtiny, Zephyr) 환경의 Class B 안전 패턴 두 가지를 MicroBlaze V + Basys3 환경으로 이식. ① AXI4-Lite CRC 검사 IP: BRAM 명령 메모리의 CRC를 주기적으로 계산해 기준 레지스터와 비교, 불일치 시 인터럽트 발생. ② 소프트웨어 스택 센티넬: MicroBlaze V C 코드에서 스택 최하단에 매직 값 기록, 주기적 체크 함수 호출, 오버플로 검출 시 AXI GPIO로 LED 경보.

- id: I-071
- 조합: [AXI4-Lite CRC IP(T2, embedded FSM), AXI BRAM Controller(storage), 스택 센티넬 C 코드(T1 소프트웨어), AXI GPIO LED 경보(T1 peripheral), MicroBlaze V 인터럽트 컨트롤러]
- 근거 카드: [[tum-industrial-es-2015-functional-safety]], [[heia-fr-ma-embreal-zephyr-stack-protection]], [[rtime-cvut-openmsp430-watchdog]]
- 근거 URL: https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/197/ATAVRFEB-SAFETY_Web.pdf
- 새로움 근거: 카탈로그에 CRC 검사 AXI IP 카드 없음. 스택 센티넬 + CRC 복합 안전 계층을 Basys3 MicroBlaze V에 적용한 사례 없음 — 내 판단.
- Basys3 적합성 근거: CRC FSM은 LUT 소모 최소(< 200 LUT). BRAM 접근은 AXI BRAM Controller 경유. 스택 센티넬 C 코드는 MicroBlaze V에서 직접 동작. I-070 1단계(기본 WDT) 완성 후 T2 확장으로 추가 가능.
- 난이도: 3
- 단계: T2
- 상태: ready
- 심사: 2026-11-04 /verify(6차), WebFetch 전면 차단. 근거 0(근거 카드 모두 rechecked_at 없음) + 새로움 2(CRC 검사 AXI IP 없음; 복합 안전 계층 없음) + 적합성 2(CRC FSM LUT 최소, BRAM Controller 경유 가능, C 코드 MicroBlaze V 동작) + 완결성 1(CRC IP + 스택 센티넬 C 조합 TB 복잡, I-070 선행 필요) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, I-070 1단계 완성 후 재심사.
- 차단조건재심사: 2026-11-04 /verify(7차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(tum-industrial-es-2015-functional-safety, heia-fr-ma-embreal-zephyr-stack-protection, rtime-cvut-openmsp430-watchdog, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 1(I-070 선행 필요) = 8점 ≥ 7이나 한 사이클 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 1순위 후보.
- 차단조건재심사: 2026-11-04 /verify(8차), 모든 WebFetch PROVENANCE_REQUIRED 차단(8차 연속). 근거 카드 총 3건(rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 2(I-070 선행 mmio-wdt-tier1 완성으로 완결성 1→2 상향) = 9점 ≥ 7 → ready 승격. 8차 1번째 승격.

## I-072 FPGA RTL 데드타임 생성기 IP (IRS2110 외부 로직 대체)
- 상태: ready
- 요약: 내 판단: H-브리지 하이사이드/로우사이드 PWM 쌍을 AXI4-Lite 슬레이브로 제어하고, RTL 카운터로 200–500 ns 데드타임을 보장하는 T2 IP. IRS2110의 HIN/LIN 입력에 직접 연결.
- 조합: [Basys3 FPGA(PWM+데드타임 IP), 로직레벨 MOSFET(VGS(th)<2.5V), 쇼트키 플라이백 다이오드]
- 근거: [industrialmonitordirect-irs2110-half-bridge, zbotic-backem-flyback-protection, lcsc-mosfet-selection-motor-control]
- 새로움의 근거: 기존 아이디어들은 슛스루 차단이 주목적; 이 IP는 IRS2110 HIN/LIN 쌍 직접 구동을 위한 데드타임 타이밍 IP로 목적이 다름
- Basys3 적합성의 근거: Pmod JA/JB 핀(3.3V)으로 HIN/LIN 출력 가능; 100MHz 클럭으로 10 ns 분해능, 20클럭=200 ns 최소 데드타임 카운터 구현 가능
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify(7차), 근거 0(industrialmonitordirect-irs2110-half-bridge·zbotic-backem-flyback-protection·lcsc-mosfet-selection-motor-control 모두 rechecked_at 없음; 이번 사이클에 처음 추가된 카드) + 새로움 2(AXI4-Lite 데드타임 IP 카드 없음; IRS2110 HIN/LIN 직접 구동용 타이밍 IP 조합 없음) + 적합성 2(Pmod JA/JB 3.3V 출력, 100MHz 클럭 10ns 분해능, 순수 FSM+카운터 BRAM 미사용; 단 IRS2110 외부 연결 전기 호환성 미확인) + 완결성 1(PWM+데드타임 RTL 범위는 명확하나 IRS2110 외부 하드웨어 연결 절차 미정) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, IRS2110 외부 연결 절차 명세화. ※ 첫 raw→vetted 심사이므로 차단조건재심사 불적용(§14.2).
- 차단조건재심사: 2026-11-04 /verify(8차), 모든 WebFetch PROVENANCE_REQUIRED 차단(8차 연속). 7차에서 raw→vetted 첫 심사 완료, 8차는 차단조건재심사 적용 가능. 근거 카드 총 3건(industrialmonitordirect-irs2110-half-bridge, zbotic-backem-flyback-protection, lcsc-mosfet-selection-motor-control, rechecked_at 불문) → 근거 3 + 새로움 2(AXI4-Lite 데드타임 IP 카드 없음; IRS2110 HIN/LIN 구동용 타이밍 IP 없음) + 적합성 2(Pmod JA/JB 3.3V 출력, 100MHz 10ns 분해능, FSM+카운터 LUT 최소) + 완결성 1(IRS2110 외부 연결 절차 미정) = 8점 ≥ 7 → ready 승격. 8차 2번째 승격(상한 채움).

## I-073 역기전력 보호 회로 + FPGA XADC 과전류 감지 조합 T2
- 상태: ready
- 요약: 내 판단: RC 스너버·TVS·쇼트키 다이오드 하드웨어 보호와 Basys3 XADC 션트 저항 전류 측정을 결합한 소프트·하드 2중 모터 보호 시스템.
- 조합: [Basys3 XADC(전류 샘플), zbotic 플라이백 보호 회로, mmio-motor-safety-wrapper RTL 연장]
- 근거: [zbotic-backem-flyback-protection, industrialmonitordirect-irs2110-half-bridge]
- 새로움의 근거: 순수 하드웨어 보호(쇼트키+TVS)와 FPGA XADC 소프트 과전류 차단을 계층화; 기존 아이디어는 RTL 슛스루·데드타임만 처리, XADC 연동 없음
- Basys3 적합성의 근거: XADC JXADC 커넥터를 션트 저항 전압 측정에 사용(0–1V 범위); 외부 하드웨어 보호는 Pmod 외부 회로에 추가
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify(7차), 근거 0(zbotic-backem-flyback-protection·industrialmonitordirect-irs2110-half-bridge 모두 rechecked_at 없음; 근거 카드 2건만) + 새로움 2(XADC 연동 과전류 감지+하드웨어 플라이백 보호 조합 카드 없음; 기존 아이디어는 RTL 슛스루·데드타임만) + 적합성 2(Basys3 XADC JXADC 커넥터 사용 가능, 션트 저항 0–1V 범위 측정 가능; 단 외부 보호 회로 설계 미정) + 완결성 1(XADC IP+과전류 비교 로직+하드웨어 보호 회로 각각 명세 복잡, RTL+TB 범위 완전히 정의 안 됨) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득(카드 2건 부족, 1건 추가 필요), 범위 세분화. ※ 첫 raw→vetted 심사이므로 차단조건재심사 불적용(§14.2).
- 차단조건재심사: 2026-11-04 /verify(8차), 모든 WebFetch PROVENANCE_REQUIRED 차단(8차 연속). 7차에서 raw→vetted 첫 심사 완료, 8차는 차단조건재심사 적용 가능. 근거 카드 총 2건(zbotic-backem-flyback-protection, industrialmonitordirect-irs2110-half-bridge, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 2(XADC JXADC 커넥터 가용, 션트 저항 0–1V 범위) + 완결성 1(RTL+TB 범위 미정) = 7점 ≥ 7이나 8차 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 1순위 후보.
- 차단조건재심사: 2026-11-04 /verify(9차), 모든 WebFetch PROVENANCE_REQUIRED 차단(9차 연속). 8차 1순위 보류 건이므로 9차에 우선 승격. 근거 카드 총 2건(zbotic-backem-flyback-protection, industrialmonitordirect-irs2110-half-bridge, rechecked_at 불문) → 근거 2 + 새로움 2(XADC 연동 과전류+하드웨어 플라이백 조합 카드 없음) + 적합성 2(XADC JXADC 커넥터 가용, 션트 저항 0–1V 범위) + 완결성 1(RTL+TB 범위 미정) = 7점 ≥ 7 → ready 승격.

## I-074 Basys3 Pmod 3.3V 직구동 로직레벨 H-브리지 테스트베드 T1
- 상태: ready
- 요약: 내 판단: 별도 게이트 드라이버 없이 Basys3 Pmod 3.3V 신호로 VGS(th)<2.5V 로직레벨 MOSFET을 직접 구동하는 소신호 모터 테스트베드. 소전류 모터(< 500 mA) 대상 최소 구성.
- 조합: [Basys3 Pmod 직접 출력, 로직레벨 MOSFET(VGS(th)<2.5V), 쇼트키 플라이백]
- 근거: [lcsc-mosfet-selection-motor-control, zbotic-backem-flyback-protection]
- 새로움의 근거: 기존 카드들은 모두 별도 드라이버 IC 사용; Pmod 직접 구동 최소 구성 테스트베드는 카탈로그에 없음
- Basys3 적합성의 근거: Pmod 출력 전류 제한(< 24 mA per pin 확인 필요) → 소신호 MOSFET(e.g. 2N7002) 게이트 전류 감당 가능 여부 확인 필요; 대전류 모터에는 부적합
- 난이도: 1 / 단계: T1
- 심사: 2026-11-04 /verify(7차), 근거 0(lcsc-mosfet-selection-motor-control·zbotic-backem-flyback-protection 모두 rechecked_at 없음; 근거 카드 2건만) + 새로움 2(Pmod 직접 구동 최소 구성 테스트베드 카드 없음; 기존 카드는 모두 별도 드라이버 IC 사용) + 적합성 1(Pmod 3.3V 출력 가능하나 출력 전류 제한 < 24 mA per pin 미확인; 2N7002 게이트 전류 감당 가능성 미확인; 소전류 모터 직구동 가능성 불확실) + 완결성 2(T1 단계 단순 Verilog PWM+H-브리지 출력, 범위 최소, RTL+외부 BOM 작성 가능) = 5점 → vetted. 보강: Pmod 출력 전류 제한 공식 확인, 근거 카드 rechecked_at 취득, 근거 카드 1건 추가. ※ 첫 raw→vetted 심사이므로 차단조건재심사 불적용(§14.2).
- 차단조건재심사: 2026-11-04 /verify(8차), 모든 WebFetch PROVENANCE_REQUIRED 차단(8차 연속). 7차에서 raw→vetted 첫 심사 완료, 8차는 차단조건재심사 적용 가능. 근거 카드 총 2건(lcsc-mosfet-selection-motor-control, zbotic-backem-flyback-protection, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 1(Pmod 전류 제한 미확인) + 완결성 2(T1 단순 Verilog PWM+H-브리지, 범위 최소) = 7점 ≥ 7이나 8차 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 2순위 후보.
- 차단조건재심사: 2026-11-04 /verify(9차), 모든 WebFetch PROVENANCE_REQUIRED 차단(9차 연속). 8차 2순위 보류 건이므로 9차에 승격. 근거 카드 총 2건(lcsc-mosfet-selection-motor-control, zbotic-backem-flyback-protection, rechecked_at 불문) → 근거 2 + 새로움 2(Pmod 직접 구동 최소 구성 테스트베드 카탈로그에 없음) + 적합성 1(Pmod 전류 제한 미확인) + 완결성 2(T1 단순 Verilog PWM+H-브리지, 범위 최소) = 7점 ≥ 7 → ready 승격.

## I-075 Basys3 XADC 전원 모니터 AXI-Lite IP — 코어·보조 전압 감시 T2
- 상태: used: mmio-xadc-pwr-mon
- 요약: 내 판단: Artix-7 내장 XADC를 이용해 Vccint(1.0V), Vccaux(1.8V), Vccbram 세 레일을 주기적으로 샘플링하고, 임계값 초과 시 MicroBlaze V 인터럽트를 발생시키는 AXI4-Lite 슬레이브 IP. 외부 하드웨어 불필요.
- 조합: [Basys3 XADC 내부 채널, AXI4-Lite 슬레이브 레지스터, MicroBlaze V 인터럽트 컨트롤러, Vishay 전원 순서화 개념]
- 근거: [vishay-fpga-power-supply-consideration, altium-ldo-vs-switching-regulator]
- 새로움의 근거: 카탈로그 내 XADC를 전원 모니터로 쓰는 AXI-Lite IP 아이디어 없음. 기존 XADC 아이디어는 외부 센서(온도, 전류 샘플) 위주
- Basys3 적합성의 근거: Artix-7 XC7A35T에 XADC 하드 블록 내장. Vccint·Vccaux·Vccbram은 별도 외부 핀 불필요. XADC IP 코어는 Vivado에서 무료 사용 가능
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify(9차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(vishay-fpga-power-supply-consideration·altium-ldo-vs-switching-regulator 모두 rechecked_at 없음) + 새로움 2(XADC를 전원 모니터로 쓰는 AXI-Lite IP 아이디어 카탈로그 없음; 기존 XADC 아이디어는 외부 전류·온도 센서 위주) + 적합성 3(Artix-7 XC7A35T 내장 XADC 하드 블록, Vccint/Vccaux/Vccbram 외부 핀 불필요, Vivado XADC IP 코어 무료 사용 가능) + 완결성 2(AXI4-Lite 슬레이브 IP 범위 명확, 임계값 비교+인터럽트 출력 RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득 필요, AXI4-Lite 슬레이브 레지스터 세부 범위(채널 수, 임계값 레지스터 수) 명세화.
- 차단조건재심사: 2026-11-05 /verify(10차), 모든 WebFetch PROVENANCE_REQUIRED 차단(10차 연속). 근거 카드 총 2건(vishay-fpga-power-supply-consideration, altium-ldo-vs-switching-regulator, rechecked_at 불문) → 근거 2 + 새로움 2(XADC 전원 모니터 AXI IP 카탈로그 없음; 기존 XADC 아이디어와 측정 목적 다름) + 적합성 3(XADC 하드 블록 내장, 외부 핀 불필요, Vivado IP 무료) + 완결성 2(AXI4-Lite 슬레이브 레지스터+임계값+인터럽트 RTL+TB 작성 가능) = 9점 ≥ 7 → ready 승격.

## I-076 외부 보조 전원 보드 설계 가이드: 12V→5V+3.3V 이중 레일 for Basys3 확장 T0
- 상태: ready
- 요약: 내 판단: 모터·서보·센서 확장 모듈을 Basys3에 연결할 때 쓰는 외부 이중 레일 전원 보드. 12V→DC-DC 벅→5V/3A, 5V→LDO→3.3V/1A, GND 공통, USB 5V 격리 설계 가이드.
- 조합: [12V 입력, 벅 컨버터(MP1584·XL4016 등), LDO(AMS1117-3.3), 커플링 커패시터, 패러사이틱 인덕턴스 차단]
- 근거: [vishay-fpga-power-supply-consideration, wevolver-buck-converter-design-guide, altium-ldo-vs-switching-regulator]
- 새로움의 근거: 카탈로그 내 Basys3 모터 확장용 외부 전원 보드 설계 가이드 없음. 전원 순서화·GND 분리·USB 격리를 하나의 설계 가이드로 묶은 아이디어 없음
- Basys3 적합성의 근거: Basys3 외부 전원은 별도 보드로 공급(USB+배럴잭 모두 5V 한계). 모터·서보는 별도 전원 필수(전기 규칙 §17.2). 가이드 문서 형태이므로 RTL 불필요, 범위 T0
- 난이도: 1 / 단계: T0
- 심사: 2026-11-04 /verify(9차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(vishay-fpga-power-supply-consideration·wevolver-buck-converter-design-guide·altium-ldo-vs-switching-regulator 모두 rechecked_at 없음; 3건이지만 불문) + 새로움 2(Basys3 모터 확장용 외부 전원 보드 설계 가이드 카탈로그 없음; 전원 순서화·GND 분리·USB 격리 통합 가이드 아이디어 없음) + 적합성 2(Basys3 외부 전원 별도 보드 필수, 모터 전원 §17.2 분리 필수; 가이드 문서이므로 직접 RTL 불필요 → 적합성 판단 쉬우나 Basys3 RTL 연결 없어 3점 미달) + 완결성 1(T0 가이드 문서지만 범위 여전히 넓음; 어떤 부품·토폴로지 선정 기준을 RTL+TB 없이 문서로 완결할 수 있는지 불명확) = 5점 → vetted. 보강: 설계 가이드 범위 세분화(어떤 선택 항목 다루는지), 근거 카드 rechecked_at 취득.
- 차단조건재심사: 2026-11-05 /verify(10차), 모든 WebFetch PROVENANCE_REQUIRED 차단(10차 연속). 근거 카드 총 3건(vishay-fpga-power-supply-consideration, wevolver-buck-converter-design-guide, altium-ldo-vs-switching-regulator, rechecked_at 불문) → 근거 3 + 새로움 2(Basys3 모터 확장용 외부 전원 보드 설계 가이드 카탈로그 없음) + 적합성 2(Basys3 외부 전원 별도 보드 필수, §17.2 모터 전원 분리 필수; 가이드 문서이므로 RTL 불필요) + 완결성 1(T0 가이드 문서, TB 없음; 범위 여전히 넓어 완결성 낮음) = 8점 ≥ 7 → ready 승격.

## I-077 단상 풀브리지 SPWM 생성기 AXI4-Lite IP — 데드타임 레지스터 포함 T2

- 내 판단: 삼각파-기준파 비교 방식 SPWM 발생기와 보완 출력 + 데드타임 삽입 FSM을 MicroBlaze V SoC의 AXI4-Lite IP로 구현한다. 소프트웨어에서 PWM 주기·데드타임·변조 지수를 레지스터로 제어.
- 조합: [spwm-generator-rtl, deadtime-fsm, axi4-lite-slave, complementary-pwm-output]
- 근거 카드: [element14-cumps-deadtime-vhdl-pynqz2, industrialmonitordirect-irs2110-half-bridge, industrialmonitordirect-igbt-shootthrough]
- 근거 URL: [https://community.element14.com/technologies/fpga-group/b/blog/posts/vhdl-pwm-generator-with-dead-time-the-design, https://industrialmonitordirect.com/blogs/knowledgebase/igbt-h-bridge-shoot-through-fixing-pwm-timing-driver-issues]
- 새로움의 근거: 카탈로그 내 SPWM 전용 AXI4-Lite IP 없음; IRS2110 카드는 드라이버 IC 설계에 집중하고 RTL FSM 미포함
- Basys3 적합성의 근거: 100MHz 클럭 기준 500ns 데드타임 = 50 클럭 틱, 6비트 카운터 충분. Pmod 출력으로 HIN/LIN 쌍 직접 연결. 동결 맵 free_slots 1 블록(64KB) 배정
- 난이도: 2 / 단계: T2 / 상태: used (패키지: mmio-spwm-deadtime-ip, 2026-11-04)
- 심사: 2026-11-05 /verify(10차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(근거 카드 모두 rechecked_at 없음) + 새로움 2(카탈로그 내 SPWM 전용 AXI4-Lite IP 없음; IRS2110 카드는 드라이버 IC 설계에 집중하고 RTL FSM 미포함) + 적합성 3(100MHz 클럭 기준 500ns 데드타임 = 50 클럭 틱, 6비트 카운터 충분; Pmod 출력으로 HIN/LIN 쌍 직접 연결 가능; 동결 맵 free_slots 1 블록 배정 가능) + 완결성 2(SPWM+데드타임 FSM+AXI4-Lite RTL 범위 명확, 보완 출력 TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득, 삼각파-기준파 비교 RTL 세부 파라미터 명세화.
- 차단조건재심사: 2026-11-05 /verify(11차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(element14-cumps-deadtime-vhdl-pynqz2, industrialmonitordirect-irs2110-half-bridge, industrialmonitordirect-igbt-shootthrough, rechecked_at 불문) → 근거 3 + 새로움 2(카탈로그 내 SPWM 전용 AXI4-Lite IP 없음) + 적합성 3(100MHz 클럭 500ns 데드타임 50 클럭 틱, 6비트 카운터 충분, Pmod 출력 HIN/LIN 쌍 직접 연결, 동결 맵 free_slots 배정 가능) + 완결성 2(SPWM+데드타임 FSM+AXI4-Lite RTL 범위 명확, 보완 출력 TB 작성 가능) = 10점 ≥ 7 → ready 승격.

## I-078 Basys3 FPGA + IRS2110 + 소신호 H-브리지 슛스루 감지 테스트베드 T2

- 내 판단: Basys3 Pmod → IRS2110 → 소전력(5V, 1A 이하) MOSFET H-브리지 연결, FPGA 로직으로 HIN/LIN 보완 쌍을 생성하되 의도적으로 데드타임=0으로 설정해 슛스루 전류 파형을 오실로스코프로 확인하는 실험 보드. 슛스루 감지 assertion을 RTL에 내장해 CI에서도 검출.
- 조합: [basys3-pmod, irs2110-gate-driver, h-bridge-mosfet, deadtime-rtl, 슛스루-감지-assertion]
- 근거 카드: [industrialmonitordirect-irs2110-half-bridge, industrialmonitordirect-igbt-shootthrough, element14-cumps-deadtime-vhdl-pynqz2]
- 근거 URL: [https://industrialmonitordirect.com/blogs/knowledgebase/igbt-h-bridge-shoot-through-fixing-pwm-timing-driver-issues]
- 새로움의 근거: S6(실패 사례) 전략 — 슛스루를 의도적으로 재현해 데드타임 효과를 측정하는 교육용 테스트베드는 카탈로그에 없음
- Basys3 적합성의 근거: Pmod 3.3V 출력으로 IRS2110 HIN/LIN 구동(버퍼 추가), 소전력 테스트이므로 외부 전원 5V 1A 충분. 전기 규칙(§17.2): 모터 전원 보드 분리·GND만 공통 적용
- 난이도: 3 / 단계: T2 / 상태: vetted
- 심사: 2026-11-05 /verify(10차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(근거 카드 모두 rechecked_at 없음) + 새로움 2(슛스루를 의도적으로 재현해 데드타임 효과를 측정하는 교육용 테스트베드 카탈로그에 없음; S6 실패 사례 전략) + 적합성 2(Pmod 3.3V→IRS2110 HIN/LIN 구동 가능하나 버퍼 추가 필요; 소전력 테스트이므로 외부 전원 5V 1A 충분; 하드웨어 직접 확인이 RTL만큼 중요) + 완결성 1(보드 직접 오실로스코프 측정 필수, RTL+TB만으로 완결 어려움; 슛스루 감지 assertion은 RTL로 작성 가능하나 실제 파형 확인은 사람 필요) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, RTL 범위를 TB로 완결 가능한 assertion 중심으로 세분화.

## I-079 SPWM + XADC 조합: 출력 전압 피드백으로 변조 지수 자동 조정 T3

- 내 판단: FPGA SPWM 발생기의 변조 지수(M)를 XADC로 측정한 출력 전압 피드백으로 자동 조정하는 폐루프 제어. 단상 인버터 출력을 분압해 XADC에 입력, 소프트웨어(MicroBlaze V) 또는 RTL PI 제어기로 M 조정.
- 조합: [spwm-rtl, xadc-axi, pi-controller, axi4-lite-slave, feedback-loop]
- 근거 카드: [arxiv-1002340-spartan3e-spwm-inverter, element14-cumps-deadtime-vhdl-pynqz2, industrialmonitordirect-igbt-shootthrough]
- 근거 URL: [https://arxiv.org/abs/1002.3340, https://community.element14.com/technologies/fpga-group/b/blog/posts/vhdl-pwm-generator-with-dead-time-the-design]
- 새로움의 근거: 카탈로그 내 SPWM + XADC 폐루프 조합 없음. XADC는 Basys3 내장 IP이므로 외부 ADC 불필요
- Basys3 적합성의 근거: Basys3 XC7A35T에 XADC 블록 내장(12비트 1MSPS). 분압 저항으로 출력 전압 0–1V로 스케일해 XADC VAUXP/VAUXN에 연결(Pmod JA). I-077의 SPWM IP와 연동
- 난이도: 4 / 단계: T3 / 상태: ready
- 심사: 2026-11-05 /verify(10차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(근거 카드 모두 rechecked_at 없음) + 새로움 2(카탈로그 내 SPWM + XADC 폐루프 조합 없음; XADC 내장 IP로 외부 ADC 불필요한 접근) + 적합성 3(Basys3 XC7A35T XADC 블록 내장 12비트 1MSPS; 분압 저항으로 출력 전압 0–1V 스케일, XADC VAUXP/VAUXN 연결 가능; I-077의 SPWM IP와 연동) + 완결성 2(SPWM+XADC+PI 제어기 RTL 또는 SW 범위 명확, 개루프 대비 폐루프 TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득, PI 제어기 RTL 또는 SW 구현 방식 선택(T3 → SW 구현 추천), 분압 저항 값 명세화.
- 차단조건재심사: 2026-11-05 /verify(11차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(arxiv-1002340-spartan3e-spwm-inverter, element14-cumps-deadtime-vhdl-pynqz2, industrialmonitordirect-igbt-shootthrough, rechecked_at 불문) → 근거 3 + 새로움 2(카탈로그 내 SPWM + XADC 폐루프 조합 없음) + 적합성 3(Basys3 XC7A35T XADC 내장 12비트 1MSPS, VAUXP/VAUXN 연결 가능, I-077 SPWM IP와 연동) + 완결성 2(SPWM+XADC+PI 범위 명확, 개루프 대비 폐루프 TB 작성 가능) = 10점 ≥ 7 → ready 승격(2번째, 사이클 상한 도달).

## I-081 Basys3 XADC + ACS712 전류 측정 AXI4-Lite IP — T2

- 내 판단: ACS712 홀 전류 센서를 분압기로 조건화(2.5V 중심 출력 → 0–1V 단방향)해 Basys3 XADC JXADC 헤더에 연결, Verilog 이동 평균 필터와 오프셋 보정 로직을 갖춘 AXI4-Lite 슬레이브 IP로 패키징.
- 조합: [ACS712, Basys3 XADC, Verilog 이동 평균 필터, AXI4-Lite 슬레이브]
- 근거 카드: [sparkfun-acs712-current-sensor, xilinx-xapp795-driving-xadc, applied-ee-analog-front-end]
- 근거 URL: [https://learn.sparkfun.com/tutorials/acs712-low-current-sensor-hookup-guide/all?print=1]
- 새로움의 근거: 카탈로그 내 XADC + 홀 전류 센서 조합 카드 없음. 기존 XADC 아이디어(I-079)는 SPWM 출력 전압 감시 목적, 이 아이디어는 입력 전류 측정 AXI IP
- Basys3 적합성의 근거: Basys3 XADC 내장(XC7A35T), JXADC 헤더 4채널 사용. R1·R2(4kΩ/1kΩ)로 ACS712 출력(단방향 0–5A: 2.5–3.425V)을 0–0.5V로 스케일. RC 필터(150Ω, 1nF). 오프셋 보정은 소프트웨어.
- 내 판단: ACS712 출력 2.5V 중심이므로 분압 후 최대 0.5V·최소 0V 범위가 됨 — ±5A 범위를 절반만 측정하거나 오프셋을 소프트웨어로 보정해야 함. 단방향 전류(0~5A)면 0~0.5V 범위로 간단하게 가능. 변경: digilent-basys3-xadc-analog-input (존재하지 않는 카드)를 xilinx-xapp795-driving-xadc·amd-ug480-xadc-external-inputs로 교체.
- 난이도: 3 / 단계: T2 / 상태: ready
- 심사: 2026-11-05 /verify(10차), 첫 raw→vetted 심사(차단조건재심사 불적용). ID 충돌 수정: 이전 I-079(YAML 형식, 중복) → I-081(마크다운 형식)으로 재번호. 근거 카드 오류(digilent-basys3-xadc-analog-input 존재하지 않음) → xilinx-xapp795-driving-xadc로 수정. 근거 0(sparkfun-acs712-current-sensor·xilinx-xapp795-driving-xadc·applied-ee-analog-front-end 모두 rechecked_at 없음) + 새로움 2(XADC + 홀 전류 센서 AXI IP 조합 카탈로그 없음; 기존 XADC 아이디어와 측정 목적 다름) + 적합성 3(XADC 내장, JXADC 헤더 4채널 가용, 분압기 R1/R2로 0–0.5V 스케일 가능, RC 필터 설계 명확) + 완결성 2(AXI4-Lite+이동평균+XADC RTL 범위 명확, 오프셋 보정 로직 TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득, ACS712 버전(05B/20A/30A) 선택 명세화.
- 차단조건재심사: 2026-11-05 /verify(11차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(sparkfun-acs712-current-sensor, xilinx-xapp795-driving-xadc, applied-ee-analog-front-end, rechecked_at 불문) → 근거 3 + 새로움 2(XADC + 홀 전류 센서 AXI IP 조합 카탈로그 없음) + 적합성 3(XADC 내장, JXADC 헤더 4채널, 분압기 R1/R2로 0–0.5V 스케일 가능) + 완결성 2(AXI4-Lite+이동평균+XADC RTL 범위 명확, TB 작성 가능) = 10점 ≥ 7, 사이클당 최대 2건 상한(I-077·I-079 선 승격) → 보류. 다음 사이클 1순위.
- 차단조건재심사: 2026-11-05 /verify(12차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(sparkfun-acs712-current-sensor, xilinx-xapp795-driving-xadc, applied-ee-analog-front-end, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 1순위 → ready 승격.

## I-080 FPGA Verilog 범용 디지털 LPF 라이브러리 블록 (이동 평균 CIC 형식) — T1

- 내 판단: N을 파라미터로 받는 이동 평균 필터(CIC 형식: y[n] = y[n-1] + x[n] − x[n-N]) Verilog 모듈을 library/rtl/에 추가. XADC·인코더·열전대 등 다양한 ADC 데이터에 재사용. N을 2의 거듭제곱으로 제한하면 나눗셈이 비트 선택으로 대체됨.
- 조합: [Verilog CIC 이동 평균, 파라미터 N, XADC 데이터, 센서 필터링]
- 근거 카드: [amd-ug480-xadc-external-inputs, applied-ee-analog-front-end]
- 근거 URL: [https://www.allaboutcircuits.com/technical-articles/implementing-a-low-pass-filter-on-fpga-with-verilog/]
- 새로움의 근거: 현재 library/rtl/에 디지털 필터 모듈 없음. CIC 이동 평균은 곱셈기 불필요, LUT 소모 최소 → Basys3 자원 여유 충분
- Basys3 적합성의 근거: 순수 Verilog-2001, 파라미터 N(2의 거듭제곱) → 나눗셈이 비트 선택으로 대체됨. LUT/FF 사용량 O(log N). AllAboutCircuits 공식 Fco = 0.442947/√(N²−1) 참조.
- 내 판단: N이 2의 거듭제곱이 아닌 경우 나눗셈 비용 발생 — N을 항상 2의 거듭제곱으로 제한하거나 별도 처리 필요.
- 난이도: 2 / 단계: T1 / 상태: ready
- 심사: 2026-11-05 /verify(10차), 첫 raw→vetted 심사(차단조건재심사 불적용). 형식 변환: YAML 형식 → 마크다운 형식. 근거 카드 수정: digilent-basys3-xadc-analog-input(존재하지 않음) → amd-ug480-xadc-external-inputs. 근거 0(근거 카드 모두 rechecked_at 없음) + 새로움 2(library/rtl/ 디지털 필터 모듈 없음; CIC 이동 평균은 카탈로그 내 RTL 없음) + 적합성 3(순수 Verilog-2001, 2의 거듭제곱 N으로 나눗셈→비트 선택, LUT/FF 사용량 O(log N)) + 완결성 2(library/rtl/ 위치 명확, 파라미터 TB 작성 가능, Fco 공식으로 필터 특성 검증 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득, N 비2의거듭제곱 처리 방안 결정.
- 차단조건재심사: 2026-11-05 /verify(11차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 2건(amd-ug480-xadc-external-inputs, applied-ee-analog-front-end, rechecked_at 불문) → 근거 2 + 새로움 2(library/rtl/ 디지털 필터 모듈 없음; CIC 이동 평균 RTL 카탈로그 없음) + 적합성 3(순수 Verilog-2001, 2의 거듭제곱 N으로 나눗셈→비트 선택, LUT/FF 사용량 O(log N)) + 완결성 2(library/rtl/ 위치 명확, 파라미터 TB 작성 가능) = 9점 ≥ 7, 사이클당 최대 2건 상한(I-077·I-079 선 승격) → 보류. 다음 사이클 2순위.
- 차단조건재심사: 2026-11-05 /verify(12차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 2건(amd-ug480-xadc-external-inputs, applied-ee-analog-front-end, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 2순위 → ready 승격.

## I-082 MicroBlaze V AXI4-Lite SPI Pmod PCB 확장 보드 — PCB 설계 체크리스트 실습 (T2)

- 내 판단: Basys3 Pmod 포트에 연결하는 소형 PCB 확장 보드 설계 가이드라인 작성. 디커플링(100nF + 1µF 계층), GND 플레인, 3W 규칙, 직렬 종단(SPI 클럭·데이터)을 실제 KiCad 체크리스트 형태로 정리. MicroBlaze V AXI4-Lite 슬레이브를 거쳐 SPI Pmod 주변장치(온도 센서, DAC 등)를 구동.
- 조합: [jlcpcb-decoupling-capacitor-guide, rfessentials-split-ground-plane-emi, ema-eda-fpga-pcb-design-guide, MicroBlaze V AXI4-Lite SPI IP]
- 근거 카드: [jlcpcb-decoupling-capacitor-guide, rfessentials-split-ground-plane-emi, ema-eda-fpga-pcb-design-guide]
- 근거 URL: [https://jlcpcb.com/blog/decoupling-capacitors-guide, https://rfessentials.com/rf-knowledge-base/how-do-i-design-a-split-ground-plane-on-a-pcb-without-creating-emi-problems/, https://www.ema-eda.com/ema-resources/blog/essential-fpga-pcb-design-guide-emd/]
- 새로움의 근거: 카탈로그에 Pmod 확장 PCB 설계 체크리스트 형태 아이디어 없음. 기존 PCB 관련 아이디어(없음) 대비 하드웨어·소프트웨어 통합 체크리스트 접근
- Basys3 적합성의 근거: Basys3 표준 Pmod 포트(3.3V, JA-JD 커넥터), SPI는 MicroBlaze V AXI Quad SPI IP 활용, Pmod 핀 2개씩 배선 간격 ≥ 3×폭(3W 규칙) 적용 가능, 커넥터 근처 100nF + 1µF 배치
- 내 판단: S7 난이도 사다리의 최종 응용 단계. 디커플링(T0) → GND 분리(T1) → SI·FPGA 체크리스트(T2)를 Pmod PCB 설계에 통합 적용하는 캡스톤형 실습.
- 난이도: 3 / 단계: T2 / 상태: ready
- 심사: 2026-11-05 /verify(11차), 첫 raw→vetted 심사. 근거 0(jlcpcb-decoupling-capacitor-guide·rfessentials-split-ground-plane-emi·ema-eda-fpga-pcb-design-guide 모두 rechecked_at 없음) + 새로움 2(Pmod 확장 PCB 설계 체크리스트 형태 아이디어 카탈로그에 없음; 디커플링·GND 플레인·3W·직렬 종단 통합 가이드 없음) + 적합성 2(Basys3 Pmod 3.3V 커넥터 직접 해당, MicroBlaze V AXI Quad SPI IP 활용 가능; PCB 설계 가이드라서 RTL 없음 → 적합성은 보드 수준에서 충분하나 RTL-TB 연결 간접적) + 완결성 1(PCB 체크리스트 문서 주이므로 TB 없음; AXI4-Lite SPI IP 연동 RTL 범위 미명세화) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, AXI4-Lite SPI IP 연동 RTL 범위 명세화.
- 차단조건재심사: 2026-11-05 /verify(12차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(jlcpcb-decoupling-capacitor-guide, rfessentials-split-ground-plane-emi, ema-eda-fpga-pcb-design-guide, rechecked_at 불문) → 근거 3 + 새로움 2(Pmod 확장 PCB 체크리스트 없음) + 적합성 2(Basys3 Pmod 3.3V 직결 가능, RTL-TB 연결 간접적) + 완결성 1(PCB 체크리스트 주, TB 없음) = 8점 ≥ 7, 사이클당 최대 2건 상한(I-081·I-080 선 승격) → 보류. 다음 사이클 1순위.
- 차단조건재심사: 2026-11-05 /verify(13차), 모든 WebFetch PROVENANCE_REQUIRED 차단(13차 연속). 근거 카드 총 3건(jlcpcb-decoupling-capacitor-guide, rfessentials-split-ground-plane-emi, ema-eda-fpga-pcb-design-guide, rechecked_at 불문) → 근거 3 + 새로움 2(Pmod 확장 PCB 체크리스트 형태 아이디어 카탈로그 없음) + 적합성 2(Basys3 Pmod 3.3V 커넥터 직결, MicroBlaze V AXI Quad SPI IP 활용 가능; PCB 설계 가이드라서 RTL 없음) + 완결성 1(PCB 체크리스트 문서 주, TB 없음) = 8점 ≥ 7 → ready 승격. 13차 1번째. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-083 모터 드라이버 보드 GND 분리 + 스타 접지 실습 PCB 체크리스트 — MicroBlaze V PWM·H-브리지 경계 (T2)

- 내 판단: MicroBlaze V AXI GPIO PWM 출력이 H-브리지(12V+)를 구동하는 보드에서, 디지털 GND(FPGA I/O)와 모터 전원 GND(H-브리지)를 스타 접지로 분리하는 PCB 설계 가이드. rfessentials-split-ground-plane-emi의 스타 접지(연결 브리지 2~5mm 폭, 10nF+100pF 스티칭 커패시터) 직접 적용 사례.
- 조합: [rfessentials-split-ground-plane-emi, jlcpcb-decoupling-capacitor-guide, MicroBlaze V PWM IP, H-브리지 모터 드라이버]
- 근거 카드: [rfessentials-split-ground-plane-emi, jlcpcb-decoupling-capacitor-guide, industrialmonitordirect-irs2110-half-bridge]
- 근거 URL: [https://rfessentials.com/rf-knowledge-base/how-do-i-design-a-split-ground-plane-on-a-pcb-without-creating-emi-problems/]
- 새로움의 근거: 카탈로그에 MicroBlaze V PWM ↔ H-브리지 GND 분리 체크리스트 아이디어 없음. 기존 H-브리지(industrialmonitordirect-irs2110-half-bridge) 카드는 회로 가이드이며 GND 분리·스타 접지 조합 없음
- Basys3 적합성의 근거: Basys3 Pmod/GPIO 3.3V ↔ 12V 모터 전원 분리. H-브리지는 외부 보드(IRS2110 또는 L298N). GND 연결 브리지 2~5mm 폭, 광커플러 또는 MOSFET 드라이버 디커플링. FPGA 보드 자체는 무수정.
- 내 판단: 모터 제어 사다리(엔코더→PID→모터 드라이버)에서 PCB 하드웨어 단 보완 사례로 적합. 기존 아이디어와 겹치지 않음.
- 난이도: 3 / 단계: T2 / 상태: ready
- 심사: 2026-11-05 /verify(11차), 첫 raw→vetted 심사. 근거 0(rfessentials-split-ground-plane-emi·jlcpcb-decoupling-capacitor-guide·industrialmonitordirect-irs2110-half-bridge 모두 rechecked_at 없음) + 새로움 2(MicroBlaze V PWM ↔ H-브리지 GND 분리 체크리스트 아이디어 카탈로그에 없음; 기존 H-브리지 카드는 GND 분리·스타 접지 조합 없음) + 적합성 2(Basys3 Pmod/GPIO 3.3V ↔ 12V 모터 전원 분리 가능; H-브리지 외부 보드 필요; PCB 설계 가이드라서 RTL 불필요하나 외부 PCB 보드 필요) + 완결성 1(PCB 설계 가이드+스타 접지 체크리스트 문서 주이므로 TB 없음; MicroBlaze V PWM RTL 연동 범위 미명세화) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, MicroBlaze V PWM RTL 범위(레지스터·TB) 명세화.
- 차단조건재심사: 2026-11-05 /verify(12차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(rfessentials-split-ground-plane-emi, jlcpcb-decoupling-capacitor-guide, industrialmonitordirect-irs2110-half-bridge, rechecked_at 불문) → 근거 3 + 새로움 2(MicroBlaze V PWM ↔ H-브리지 GND 분리 체크리스트 없음) + 적합성 2(Basys3 Pmod/GPIO 3.3V ↔ 12V 분리 가능, 외부 PCB 필요) + 완결성 1(PCB 설계 가이드 주, TB 없음) = 8점 ≥ 7, 사이클당 최대 2건 상한(I-081·I-080 선 승격) → 보류. 다음 사이클 2순위.
- 차단조건재심사: 2026-11-05 /verify(13차), 모든 WebFetch PROVENANCE_REQUIRED 차단(13차 연속). 근거 카드 총 3건(rfessentials-split-ground-plane-emi, jlcpcb-decoupling-capacitor-guide, industrialmonitordirect-irs2110-half-bridge, rechecked_at 불문) → 근거 3 + 새로움 2(MicroBlaze V PWM ↔ H-브리지 GND 분리·스타 접지 체크리스트 카탈로그 없음) + 적합성 2(Basys3 Pmod/GPIO 3.3V ↔ 12V 모터 전원 분리 가능, H-브리지 외부 PCB 필요) + 완결성 1(PCB 설계 가이드+스타 접지 문서 주, TB 없음) = 8점 ≥ 7 → ready 승격. 13차 2번째(사이클 상한 채움). WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-084 FPGA SoC PCB 전원 무결성 검증 가이드 — VCCINT·VCCO·VCCAUX 디커플링 계층 체크 (T1)

- 내 판단: Basys3 XC7A35T의 VCCINT(1.0V)·VCCO(3.3V)·VCCAUX(1.8V) 각 전원 레일에 100nF + 1µF 쌍을 배치하는 체크리스트 작성. jlcpcb-decoupling-capacitor-guide의 계층별 값 선택 기준 + ema-eda-fpga-pcb-design-guide의 via-in-pad·GND 플레인 근접 배치 규칙을 조합. MicroBlaze V SoC IP 추가 시 PDN 임피던스 목표값 추정 방법 포함.
- 조합: [jlcpcb-decoupling-capacitor-guide, ema-eda-fpga-pcb-design-guide, vishay-fpga-power-supply-consideration]
- 근거 카드: [jlcpcb-decoupling-capacitor-guide, ema-eda-fpga-pcb-design-guide, vishay-fpga-power-supply-consideration]
- 근거 URL: [https://jlcpcb.com/blog/decoupling-capacitors-guide, https://www.ema-eda.com/ema-resources/blog/essential-fpga-pcb-design-guide-emd/]
- 새로움의 근거: 카탈로그에 XC7A35T 전원 레일별 디커플링 계층 체크리스트 아이디어 없음. vishay-fpga-power-supply-consideration(기존 T0)은 범용 가이드이며 XC7A35T 레일별 적용 조합 없음
- Basys3 적합성의 근거: XC7A35T 전원 핀 직접 해당. via-in-pad는 2층 기판 외 옵션, 4층 기판 권장 시 근접 GND 플레인 활용. Basys3 확장 보드 설계 시 적용 가능.
- 내 판단: S7 사다리의 T1 위치(입문 디커플링 개념 습득 후, 고급 SI 규칙 적용 전). 비교적 좁은 범위이지만 MicroBlaze V SoC 주변장치 PCB 설계 시 필수 체크 항목.
- 난이도: 2 / 단계: T1 / 상태: ready
- 심사: 2026-11-05 /verify(11차), 첫 raw→vetted 심사. 근거 0(jlcpcb-decoupling-capacitor-guide·ema-eda-fpga-pcb-design-guide·vishay-fpga-power-supply-consideration 모두 rechecked_at 없음) + 새로움 2(XC7A35T 전원 레일별 디커플링 체크리스트 아이디어 카탈로그에 없음; vishay 가이드는 범용, XC7A35T 레일별 적용 조합 없음) + 적합성 2(XC7A35T 전원 핀 직접 해당; 확장 보드 설계 대상이지만 RTL 불필요 → T1 위치 적합성 충분하나 RTL-TB 연결 없음) + 완결성 1(VCCINT·VCCO·VCCAUX 체크리스트 문서 완결 가능하나 MicroBlaze V SoC PDN 추정 방법 범위 넓어 TB 없음) = 5점 → vetted. 보강: 근거 카드 rechecked_at 취득, PDN 임피던스 추정 방법 범위 세분화.
- 차단조건재심사: 2026-11-05 /verify(12차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 3건(jlcpcb-decoupling-capacitor-guide, ema-eda-fpga-pcb-design-guide, vishay-fpga-power-supply-consideration, rechecked_at 불문) → 근거 3 + 새로움 2(XC7A35T 전원 레일별 디커플링 체크리스트 없음) + 적합성 2(XC7A35T 전원 핀 직접 해당, RTL-TB 연결 없음) + 완결성 1(VCCINT·VCCO·VCCAUX 체크리스트 문서, TB 없음) = 8점 ≥ 7, 사이클당 최대 2건 상한(I-081·I-080 선 승격) → 보류. 다음 사이클 3순위.
- 차단조건재심사: 2026-11-05 /verify(13차), 모든 WebFetch PROVENANCE_REQUIRED 차단(13차 연속). 근거 카드 총 3건(jlcpcb-decoupling-capacitor-guide, ema-eda-fpga-pcb-design-guide, vishay-fpga-power-supply-consideration, rechecked_at 불문) → 근거 3 + 새로움 2(XC7A35T VCCINT·VCCO·VCCAUX 레일별 디커플링 체크리스트 카탈로그 없음) + 적합성 2(XC7A35T 전원 핀 직접 해당, 확장 보드 설계 대상; RTL-TB 연결 없음) + 완결성 1(VCCINT·VCCO·VCCAUX 체크리스트 문서 완결 가능, TB 없음) = 8점 ≥ 7, 13차 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 1순위.
- 차단조건재심사: 2026-11-05 /verify(14차), 모든 WebFetch PROVENANCE_REQUIRED 차단(14차 연속). 근거 카드 총 3건(jlcpcb-decoupling-capacitor-guide, ema-eda-fpga-pcb-design-guide, vishay-fpga-power-supply-consideration, rechecked_at 불문) → 근거 3 + 새로움 2(XC7A35T VCCINT·VCCO·VCCAUX 레일별 디커플링 체크리스트 카탈로그 없음) + 적합성 2(XC7A35T 전원 핀 직접 해당, 확장 보드 설계 대상; RTL-TB 연결 없음) + 완결성 1(VCCINT·VCCO·VCCAUX 체크리스트 문서 완결 가능, TB 없음) = 8점 ≥ 7, 14차 1순위 → ready 승격. 14차 1번째. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-085 RPi4 Python spidev + airhdl SPI-to-AXI4-Lite → Basys3 AXI 주변장치 자동 테스트 하네스 (T2)

- 내 판단: Basys3 Pmod(JA/JB 헤더, 3.3V)에 RPi4 SPI0(GPIO 10/11/9/8=MOSI/MISO/CLK/CE) 직결. airhdl spi-to-axi-bridge(Apache-2.0)를 Basys3 `free_slots` 한 칸에 배정해 MicroBlaze V AXI4-Lite 슬레이브 IP를 MicroBlaze V 없이 RPi Python spidev로 자동 R/W 검증.
- 조합: [airhdl-spi-to-axi-bridge, RPi4 spidev, Basys3 Pmod, MicroBlaze V free_slots AXI4-Lite 슬레이브]
- 근거 카드: [airhdl-spi-to-axi-bridge, ananthu-islam-ahb-apb-bridge-rpi-artix7]
- 근거 URL: [https://github.com/airhdl/spi-to-axi-bridge, https://arxiv.org/html/2501.01147v1]
- 새로움의 근거: 카탈로그에 RPi4 spidev로 Basys3 AXI 주변장치를 자동화 테스트하는 아이디어 없음. michalstc-rpi-zero-fpga-spi-wishbone은 Wishbone 기반으로 AXI4-Lite 버스 직접 타깃 아님.
- Basys3 적합성의 근거: Basys3 Pmod 3.3V ↔ RPi GPIO 3.3V 레벨 변환 불필요. airhdl IP 단일 파일(sv 또는 vhd), Basys3 XC7A35T에 fit_basys3=yes. 11바이트 SPI 거래로 32비트 AXI4-Lite R/W 가능. RPi Python spidev 패키지가 CI에서 pytest로 자동화 가능.
- 내 판단: SoC 개발에서 MicroBlaze V 없이 주변장치 IP만 단독 검증하는 "headless AXI 테스트" 패턴. Basys3 Pmod에 RPi를 꽂고 pytest로 레지스터 R/W를 자동화하면 IP 개발 주기가 단축됨.
- 난이도: 3 / 단계: T2 / 상태: ready
- 심사: 2026-11-05 /verify(12차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(airhdl-spi-to-axi-bridge·ananthu-islam-ahb-apb-bridge-rpi-artix7 모두 rechecked_at 없음) + 새로움 2(RPi4 spidev로 Basys3 AXI 주변장치 자동화 테스트 카탈로그 없음; michalstc-rpi-zero-fpga-spi-wishbone은 Wishbone 기반으로 AXI4-Lite 타깃 아님) + 적합성 3(Basys3 Pmod 3.3V ↔ RPi GPIO 3.3V 직결 가능, airhdl IP fit_basys3=yes, 11바이트 SPI 거래로 32비트 AXI R/W 가능, pytest 자동화 가능) + 완결성 1(단독 테스트 패턴 범위 명확하나 AXI 슬레이브 IP 종류 미정, TB 세부 미명세) = 6점 → vetted. 보강: 근거 카드 rechecked_at 취득, 대상 AXI 슬레이브 IP 종류 선택, pytest TB 범위 명세화.
- 차단조건재심사: 2026-11-05 /verify(13차), 모든 WebFetch PROVENANCE_REQUIRED 차단(13차 연속). 근거 카드 총 2건(airhdl-spi-to-axi-bridge, ananthu-islam-ahb-apb-bridge-rpi-artix7, rechecked_at 불문) → 근거 2 + 새로움 2(RPi4 spidev로 Basys3 AXI 주변장치 자동화 테스트 카탈로그 없음; michalstc-rpi-zero-fpga-spi-wishbone은 Wishbone 기반으로 AXI4-Lite 직접 타깃 아님) + 적합성 3(Basys3 Pmod 3.3V ↔ RPi GPIO 3.3V 직결 가능, airhdl IP fit_basys3=yes, 11바이트 SPI 거래로 32비트 AXI R/W 가능) + 완결성 1(AXI 슬레이브 IP 종류 미정, TB 세부 미명세) = 8점 ≥ 7, 13차 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 2순위.
- 차단조건재심사: 2026-11-05 /verify(14차), 모든 WebFetch PROVENANCE_REQUIRED 차단(14차 연속). 근거 카드 총 2건(airhdl-spi-to-axi-bridge, ananthu-islam-ahb-apb-bridge-rpi-artix7, rechecked_at 불문) → 근거 2 + 새로움 2(RPi4 spidev로 Basys3 AXI 주변장치 자동화 테스트 카탈로그 없음; michalstc-rpi-zero-fpga-spi-wishbone은 Wishbone 기반으로 AXI4-Lite 직접 타깃 아님) + 적합성 3(Basys3 Pmod 3.3V ↔ RPi GPIO 3.3V 직결 가능, airhdl IP fit_basys3=yes, 11바이트 SPI 거래로 32비트 AXI R/W 가능) + 완결성 1(AXI 슬레이브 IP 종류 미정, TB 세부 미명세) = 8점 ≥ 7, 14차 2순위 → ready 승격. 14차 2번째(사이클 상한 채움). WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-086 spibone_gen.py AXI-Lite 출력 + Basys3 Pmod → RP2040(Pico) SPIBone으로 AXI-Lite IP 단독 검증 패턴 (T2-T3)

- 내 판단: enjoy-digital/litex_rp2040_pmod_test의 SPIBone 패턴을 Basys3로 이식. `spibone_gen.py --mode hybrid-axi-lite`로 Basys3 AXI4-Lite 슬레이브 Verilog IP를 추출해 `free_slots` 한 칸에 배정. RP2040 Pico를 Basys3 Pmod(JA)에 꽂아 MicroPython `test_spibone.py`로 AXI 레지스터 R/W. RPi4 Linux spidev 대신 Pico MicroPython을 호스트로 쓰는 경량 테스트 환경.
- 조합: [enjoy-digital-litex-rp2040-pmod-test(SPIBone), Basys3 Pmod, RP2040 Pico, MicroBlaze V free_slots]
- 근거 카드: [enjoy-digital-litex-rp2040-pmod-test, airhdl-spi-to-axi-bridge]
- 근거 URL: [https://github.com/enjoy-digital/litex_rp2040_pmod_test]
- 새로움의 근거: 카탈로그에 RP2040 Pico를 Basys3 Pmod 호스트로 쓰는 AXI-Lite 단독 검증 아이디어 없음. 기존 아이디어(I-085)는 RPi4 Linux spidev 사용으로 경량 Pico 패턴과 구분.
- Basys3 적합성의 근거: Basys3 Pmod 3.3V ↔ Pico GPIO 3.3V 직결 가능. spibone_gen.py --mode hybrid-axi-lite 출력은 LiteX 없이 순수 Verilog. SPIBone 9바이트 프레임은 단순해 Pico MicroPython에서 machine.SPI로 직접 구현 가능.
- 내 판단: LiteX/iCEBreaker 환경을 Basys3+MicroBlaze V 환경으로 옮기는 개조 경로가 명확. Pico 대신 RPi4를 쓸 때는 spidev로 같은 9바이트 프레임 전송 가능(I-085와 상호 보완).
- 난이도: 3 / 단계: T2-T3 / 상태: ready
- 심사: 2026-11-05 /verify(12차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(enjoy-digital-litex-rp2040-pmod-test·airhdl-spi-to-axi-bridge 모두 rechecked_at 없음) + 새로움 2(RP2040 Pico를 Basys3 Pmod 호스트로 쓰는 AXI-Lite 단독 검증 카탈로그 없음; I-085와 호스트 MCU 다름) + 적합성 3(Basys3 Pmod 3.3V ↔ Pico GPIO 3.3V 직결 가능, spibone_gen.py --mode hybrid-axi-lite 순수 Verilog 출력, SPIBone 9바이트 프레임 단순·Pico MicroPython machine.SPI 직접 구현 가능) + 완결성 2(spibone_gen.py 출력→Basys3 배정→Pico MicroPython test 경로 명확, 개조 단계 세부화 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득, spibone_gen.py --mode hybrid-axi-lite Verilog AXI-Lite 호환성 검증, 대상 free_slot 선택.
- 차단조건재심사: 2026-11-05 /verify(13차), 모든 WebFetch PROVENANCE_REQUIRED 차단(13차 연속). 근거 카드 총 2건(enjoy-digital-litex-rp2040-pmod-test, airhdl-spi-to-axi-bridge, rechecked_at 불문) → 근거 2 + 새로움 2(RP2040 Pico를 Basys3 Pmod 호스트로 쓰는 AXI-Lite 단독 검증 카탈로그 없음; I-085와 호스트 MCU 다름) + 적합성 3(Basys3 Pmod 3.3V ↔ Pico GPIO 3.3V 직결 가능, spibone_gen.py --mode hybrid-axi-lite 순수 Verilog 출력, SPIBone 9바이트 프레임 단순) + 완결성 2(spibone_gen.py 출력→Basys3 배정→Pico MicroPython test 경로 명확) = 9점 ≥ 7, 13차 2건 상한 초과로 보류 → vetted 유지. 다음 사이클 3순위.
- 차단조건재심사: 2026-11-05 /verify(14차), 모든 WebFetch PROVENANCE_REQUIRED 차단(14차 연속). 근거 카드 총 2건(enjoy-digital-litex-rp2040-pmod-test, airhdl-spi-to-axi-bridge, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 14차 2건 상한 초과(I-084·I-085 선 승격) → vetted 유지. 다음 사이클 1순위.
- 차단조건재심사: 2026-11-05 /verify(16차), 모든 WebFetch PROVENANCE_REQUIRED 차단(16차 연속). 근거 카드 총 2건(enjoy-digital-litex-rp2040-pmod-test, airhdl-spi-to-axi-bridge, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 16차 1번째 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

---

### I-072 AXI4-Lite 7세그먼트 IP — 자리별 blank+dp+PWM 밝기 통합 슬레이브

- id: I-072
- 제목: AXI4-Lite 래핑 Basys3 7세그 고급 IP (blank·dp·PWM 밝기 레지스터 제어)
- 한 줄 요약: MicroBlaze V에서 레지스터 2개(DIGIT_DATA, BRIGHTNESS)로 4자리 7세그먼트를 완전 제어하는 AXI4-Lite 슬레이브 IP
- 조합 주변장치: 7seg-mux, PWM 밝기 제어(pulseDuration), 소수점(dp), 자리별 blank
- 근거 카드:
  - byu-ecen320-seven-segment4 (blank[3:0]+dp_in[3:0]+REFRESH_RATE 파라미터)
  - element14-arty-s7-7seg-brightness (pulseDuration[3:0] 15단계 PWM 밝기+dotPoint)
- 근거 URL:
  - https://byu-cpe.github.io/ecen320/labs/lab-07
  - https://community.element14.com/technologies/fpga-group/b/blog/posts/seven-segment-display-controlled-by-arty-s7-board
- 새로움의 근거: 카탈로그에 blank·dp·PWM 밝기를 AXI4-Lite 레지스터로 통합한 Basys3 IP 없음. 기존 카드들은 개별 기능만 다루며 조합 IP 아이디어 없음.
- Basys3 적합성의 근거: Basys3 4자리 공통 애노드 7세그 직접 지원. REFRESH_RATE=200 → 4자리 × 200 Hz = 800 Hz 애노드 순환, 100 MHz 클럭 분주로 충분. PWM 밝기는 duty cycle 카운터로 추가 LUT 최소 소모.
- 내 판단: 두 카드의 아이디어를 조합하면 MicroBlaze V 소프트웨어에서 단순 레지스터 쓰기만으로 7세그 고급 제어가 가능한 IP 완성. T1→T2 전환점의 대표 예제로 적합.
- 난이도: 2 / 단계: T1-T2 / 상태: used (mmio-7seg-adv-ip)
- 심사: 2026-11-05 /verify(13차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(byu-ecen320-seven-segment4·element14-arty-s7-7seg-brightness 모두 rechecked_at 없음) + 새로움 2(카탈로그에 blank·dp·PWM 밝기를 AXI4-Lite 레지스터로 통합한 Basys3 IP 없음; 기존 7세그 카드들은 개별 기능만 다룸) + 적합성 3(Basys3 4자리 공통 애노드 7세그 직접 지원, REFRESH_RATE=200 → 100MHz 분주 충분, PWM 밝기 duty cycle 카운터 LUT 최소 소모) + 완결성 2(DIGIT_DATA+BRIGHTNESS 레지스터 2개 구조 제안, 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득 후 ready 재심사.
- 차단조건재심사: 2026-11-05 /verify(14차), 모든 WebFetch PROVENANCE_REQUIRED 차단(14차 연속). 근거 카드 총 2건(byu-ecen320-seven-segment4, element14-arty-s7-7seg-brightness, rechecked_at 불문) → 근거 2 + 새로움 2(카탈로그에 blank·dp·PWM 밝기를 AXI4-Lite 레지스터로 통합한 Basys3 IP 없음) + 적합성 3(Basys3 4자리 공통 애노드 7세그 직접 지원, REFRESH_RATE=200 → 100MHz 분주 충분, PWM 밝기 duty cycle 카운터 LUT 최소 소모) + 완결성 2(DIGIT_DATA+BRIGHTNESS 레지스터 2개 구조 제안, 범위 명확, RTL+TB 작성 가능) = 9점 ≥ 7, 14차 2건 상한 초과(I-084·I-085 선 승격) → vetted 유지. 다음 사이클 2순위.
- 차단조건재심사: 2026-11-05 /verify(16차), 모든 WebFetch PROVENANCE_REQUIRED 차단(16차 연속). 근거 카드 총 2건(byu-ecen320-seven-segment4, element14-arty-s7-7seg-brightness, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 16차 2번째 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.
- 과제화: 2026-11-05 /capstone(자동), ready→used. 슬러그 mmio-7seg-adv-ip, free_slot [1F] 0x401F_0000, T2 단계.

## I-087 AXI4-Lite 멀티 버튼 IP — 디바운스+긴 누름+원샷 에지 검출 통합, 소프트웨어 가변 임계값 (T2)

- 내 판단: Basys3 5개 버튼(BTNC·BTNL·BTNR·BTNU·BTND)에 대해 디바운스(5 ms)+긴 누름 임계값(소프트웨어 가변)+원샷 에지 검출을 단일 AXI4-Lite 슬레이브 IP로 통합. MicroBlaze V에서 `DEBOUNCE_MS`·`LONGPRESS_MS` 레지스터를 쓰면 모든 버튼의 임계값이 런타임에 바뀜. IRQ 선으로 인터럽트 발생, STATUS 레지스터로 어느 버튼이 눌렸는지 확인.
- 조합: [byu-ecen220-lab08-debounce-basys3, doyk0215-2d-labyrinth-on-fpga, nandland-project4-debounce-switch]
- 근거 카드: [byu-ecen220-lab08-debounce-basys3, doyk0215-2d-labyrinth-on-fpga, nandland-project4-debounce-switch]
- 근거 URL: [https://ecen220wiki.groups.et.byu.net/labs/lab-08/, https://nandland.com/project-4-debounce-a-switch/]
- 새로움의 근거: 카탈로그에 5버튼 all-in-one AXI4-Lite IP 아이디어 없음. 기존 카드들은 개별 버튼 디바운스만 다루며 MicroBlaze V 가변 임계값 조합 없음.
- Basys3 적합성의 근거: Basys3 5개 버튼 직접 지원. 디바운스 카운터(20비트 × 5) + 긴 누름 카운터(27비트 × 5) = ~235 FF, XC7A35T에 여유. AXI4-Lite 슬레이브 추가 LUT ~100개 추정(내 판단). free_slots 한 칸 배정 가능.
- 내 판단: S4 제약 역전 + S2 조합 — FPGA 병렬 카운터 5개를 동시에 독립 증가시키는 구조는 MCU로 불가. MicroBlaze V 인터럽트 패턴 연습과 AXI4-Lite 슬레이브 IP 설계 연습을 동시에 커버하는 T2 대표 과제.
- 난이도: 2 / 단계: T2 / 상태: ready
- 심사: 2026-11-05 /verify(14차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(byu-ecen220-lab08-debounce-basys3·doyk0215-2d-labyrinth-on-fpga·nandland-project4-debounce-switch 모두 rechecked_at 없음) + 새로움 2(5버튼 all-in-one AXI4-Lite IP + MicroBlaze V 가변 임계값 조합 카탈로그 없음; 기존 카드들은 개별 버튼 디바운스만 다룸) + 적합성 3(Basys3 5개 버튼 직접 지원, 디바운스 카운터 20비트×5+긴누름 카운터 27비트×5=~235 FF XC7A35T 여유, free_slots 한 칸 배정 가능) + 완결성 2(DEBOUNCE_MS·LONGPRESS_MS·STATUS·IRQ 레지스터 구조 제안, 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득.
- 차단조건재심사: 2026-11-05, /verify(17차), 모든 WebFetch PROVENANCE_REQUIRED 차단(17차 연속). 근거 카드 총 3건(byu-ecen220-lab08-debounce-basys3, doyk0215-2d-labyrinth-on-fpga, nandland-project4-debounce-switch, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 사이클 1번째 → ready 승격.

## I-088 Basys3 더블 클릭·긴 누름 패턴 감지 FSM — 타이머 2개 계층 구조 (T1-T2)

- 내 판단: 단일 버튼에서 ① 짧은 클릭(50~500 ms) ② 더블 클릭(두 번째 클릭이 500 ms 안에 도착) ③ 긴 누름(2초 이상) 세 가지를 FSM으로 구분. 계층 구조: 1단계 FSM(디바운스+에지 검출) → 2단계 FSM(클릭 패턴 분류). 출력: `o_single`, `o_double`, `o_long` 세 개 1클럭 펄스. MicroBlaze V 없이도 동작하는 순수 FSM + AXI4-Lite 래퍼 추가 가능.
- 조합: [byu-ecen220-lab08-debounce-basys3, doyk0215-2d-labyrinth-on-fpga]
- 근거 카드: [byu-ecen220-lab08-debounce-basys3, doyk0215-2d-labyrinth-on-fpga]
- 근거 URL: [https://ecen220wiki.groups.et.byu.net/labs/lab-08/, https://github.com/doyk0215/2D-Labyrinth-on-FPGA/pull/74]
- 새로움의 근거: 카탈로그에 더블 클릭 감지 FSM 아이디어 없음. doyk0215는 긴 누름만, byu-ecen220은 단순 디바운스만 다루며 멀티 클릭 분류 조합 없음.
- Basys3 적합성의 근거: Basys3 버튼 1개(예: BTNC)로 충분. 2단계 FSM 각 ~5상태, 타이머 2개(10ms 디바운스용, 500ms 더블클릭 창용). XC7A35T LUT/FF 여유. 7세그에 클릭 종류 표시하면 보드 없이도 시뮬레이션으로 검증 가능.
- 내 판단: S7 난이도 사다리 — T0 단순 디바운스(byu-ecen220) → T1 에지 검출 → T2 패턴 분류 세 단계로 이어지는 학습 체인의 중간 계단. 더블 클릭 창 타이머와 짧은 클릭 타이머를 FSM 안에서 어떻게 공유·분리하는지를 가르치는 대표 예제(내 판단).
- 난이도: 3 / 단계: T1-T2 / 상태: ready
- 심사: 2026-11-05 /verify(14차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(byu-ecen220-lab08-debounce-basys3·doyk0215-2d-labyrinth-on-fpga 모두 rechecked_at 없음) + 새로움 2(더블 클릭 감지 FSM 아이디어 카탈로그 없음; doyk0215는 긴 누름만, byu-ecen220은 단순 디바운스만, 멀티 클릭 분류 조합 없음) + 적합성 3(Basys3 버튼 1개로 충분, 2단계 FSM ~5상태×2, 타이머 2개(10ms·500ms) XC7A35T FF 여유, 7세그 연동으로 보드 없이 시뮬레이션 검증 가능) + 완결성 2(o_single·o_double·o_long 1클럭 펄스 출력 범위 명확, 2단계 FSM TB 작성 가능, 클릭 창 타이머 공유 설계 근거 제시 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득.
- 차단조건재심사: 2026-11-05, /verify(17차), 모든 WebFetch PROVENANCE_REQUIRED 차단(17차 연속). 근거 카드 총 2건(byu-ecen220-lab08-debounce-basys3, doyk0215-2d-labyrinth-on-fpga, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 사이클 2번째 → ready 승격.

## I-089 FPGA 버튼 디바운스 비교 테스트벤치 — 카운터·FSM·SR래치 3방식 타이밍 비교 (T0-T1)

- 내 판단: 같은 채터 파형에 대해 ① 단순 카운터(nandland-project4-debounce-switch) ② FSM+타이머(byu-ecen220-lab08-debounce-basys3) ③ SR 래치 방식(설계 직접 작성) 세 모듈을 단일 테스트벤치로 비교. 10 ms 채터 버스트 → 15 ms 안정 → 1 ms 추가 채터 패턴에서 각 모듈의 출력 타이밍 차이를 $display로 출력. 어느 방식이 가장 빠르고 어느 방식이 가장 보수적인지 사이클 수로 측정.
- 조합: [nandland-project4-debounce-switch, byu-ecen220-lab08-debounce-basys3]
- 근거 카드: [nandland-project4-debounce-switch, byu-ecen220-lab08-debounce-basys3]
- 근거 URL: [https://nandland.com/project-4-debounce-a-switch/, https://ecen220wiki.groups.et.byu.net/labs/lab-08/]
- 새로움의 근거: 카탈로그에 디바운스 3방식을 같은 테스트벤치로 비교하는 아이디어 없음. 기존 카드들은 각자 단일 방식을 다루며 비교 연구 조합 없음.
- Basys3 적합성의 근거: 순수 Verilog 시뮬레이션으로 보드 없이 검증 가능(iverilog/verilator). RTL 약 200줄 이내. 비교 출력을 7세그에 연결하면 T1 보드 실험도 가능.
- 내 판단: S4 제약 역전 사례 — FPGA는 세 모듈이 동일 클럭에서 병렬 동작하므로 비교 테스트벤치 작성이 MCU에서보다 훨씬 간단. 디바운스 방식 선택의 근거를 실측 사이클 수로 보여주는 교육 가치가 높음(내 판단). 하네스 CI의 iverilog에서 바로 실행 가능.
- 난이도: 2 / 단계: T0-T1 / 상태: ready
- 심사: 2026-11-05 /verify(14차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(nandland-project4-debounce-switch·byu-ecen220-lab08-debounce-basys3 모두 rechecked_at 없음) + 새로움 2(디바운스 3방식을 같은 테스트벤치로 비교하는 아이디어 카탈로그 없음; 기존 카드들은 각자 단일 방식만 다룸) + 적합성 3(순수 Verilog 시뮬레이션으로 보드 없이 iverilog/verilator 검증 가능, RTL ~200줄 이내, 하네스 CI 직접 실행 가능) + 완결성 2(3방식 모듈 + 단일 테스트벤치 범위 명확, 10ms 채터→15ms 안정→1ms 추가 채터 패턴 명세, $display 사이클 수 비교 출력 TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득, SR래치 방식 RTL 상세 명세화.
- 차단조건재심사: 2026-11-05, /verify(17차), 모든 WebFetch PROVENANCE_REQUIRED 차단(17차 연속). 근거 카드 총 2건(nandland-project4-debounce-switch, byu-ecen220-lab08-debounce-basys3, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.
- 차단조건재심사: 2026-11-05 /verify(25차), 모든 WebFetch PROVENANCE_REQUIRED 차단(25차 연속). 근거 카드 총 2건(nandland-project4-debounce-switch, byu-ecen220-lab08-debounce-basys3, rechecked_at 불문) → 근거 2 + 새로움 2(디바운스 3방식을 같은 테스트벤치로 비교하는 아이디어 카탈로그 없음) + 적합성 3(순수 Verilog 시뮬레이션으로 보드 없이 iverilog/verilator 검증 가능, RTL ~200줄 이내, 하네스 CI 직접 실행 가능) + 완결성 2(3방식 모듈 + 단일 테스트벤치 범위 명확, $display 사이클 수 비교 출력 TB 작성 가능) = 9점 ≥ 7 → ready 승격. 25차 1번째. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-090 BRAM 더블 버퍼 DMA + VGA 라인 스트리밍 (S2 조합: DMA + 디스플레이)

- 내 판단: Basys3 BRAM 2개를 핑퐁(더블 버퍼)으로 쓰고, AXI CDMA가 한쪽 BRAM에 픽셀 데이터를 채우는 동안 VGA 스캔라인 컨트롤러가 반대쪽 BRAM에서 읽는 구조. MicroBlaze V는 CDMA를 버퍼 번갈아가며 트리거만 하면 테어링 없는 프레임 출력이 가능.
- id: I-090
- 조합: [AXI-CDMA, BRAM-double-buffer, video-vga, AXI4-Lite]
- 근거 카드: [xilinx-xup-cdma-lab7, digilent-forum-21706-basys3-mb-io]
- 근거 URL: [https://xilinx.github.io/xup_embedded_system_design_flow/lab7.html]
- 새로움의 근거: 카탈로그에 AXI CDMA + VGA 더블 버퍼 조합 아이디어 없음. 기존 VGA 카드들은 BRAM 단일 버퍼 또는 OV7670 직결 방식이고, CDMA 하드웨어 블록 복사를 VGA 파이프라인에 연결하는 패턴 없음.
- Basys3 적합성의 근거: Basys3 BRAM 50블록 × 18Kb = 225Kb 가용. 320×240 1bpp 흑백 = 9.375Kb(1블록 미만), 320×240 8bpp = 75Kb(5블록). AXI CDMA는 DDR 없이 BRAM-to-BRAM 전송 가능(free_slots 2슬롯). VGA 타이밍 카운터는 T2 수준 기존 RTL 재사용.
- 난이도: 3 / 단계: T3 / 상태: ready
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(AXI CDMA+VGA 더블 버퍼 조합 없음) + 적합성 2(BRAM 계산 명시, DDR 불필요) + 완결성 1(CDMA 슬롯 2개 배정 범위 미결) = 5점. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 2건(xilinx-xup-cdma-lab7, digilent-forum-21706-basys3-mb-io, rechecked_at 불문) → 근거 2 + 새로움 2 + 적합성 2 + 완결성 1 = 7점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.
- 차단조건재심사: 2026-11-05 /verify(25차), 모든 WebFetch PROVENANCE_REQUIRED 차단(25차 연속). 근거 카드 총 2건(xilinx-xup-cdma-lab7, digilent-forum-21706-basys3-mb-io, rechecked_at 불문) → 근거 2 + 새로움 2(AXI CDMA+VGA 더블 버퍼 조합 카탈로그 없음) + 적합성 2(BRAM 50블록×18Kb=225Kb, 320×240 8bpp=75Kb=5블록 여유, DDR 불필요) + 완결성 1(CDMA 슬롯 2개 배정 범위 미결이나 TB 구조 명확) = 7점 ≥ 7 → ready 승격. 25차 2번째 (사이클 상한 채움). WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-091 인터럽트 없는 폴링 DMA 엔진 순수 FSM — CPU 오프로드 블록 복사 (S2 조합: DMA + 베어메탈)

- 내 판단: MicroBlaze V BSP의 `XAxiDma_SimpleTransfer()` 폴링 루프를 커스텀 AXI4-Lite FSM으로 대체. 소스 주소·목적 주소·바이트 수 레지스터를 소프트웨어가 쓰면 FSM이 AXI 버스트 전송 후 DONE 플래그를 올린다. 인터럽트 없이 폴링만으로 MicroBlaze V CPU를 DMA 완료 대기에서 해방시키는 최소 구현.
- id: I-091
- 조합: [AXI4-Lite, BRAM, custom-DMA-FSM, comm-uart(디버그)]
- 근거 카드: [digilent-forum-21706-basys3-mb-io, billauer-mb-dma-250mbps, xilinx-xup-cdma-lab7]
- 근거 URL: [https://billauer.co.il/blog/?p=1898]
- 새로움의 근거: 카탈로그에 커스텀 DMA FSM(IP 없이 순수 RTL) 아이디어 없음. billauer 블로그의 Linux AXI DMA 버그 경험을 베어메탈 FSM으로 단순화해 재현 가능한 T3 패턴을 만드는 접근(S6 교훈 역용).
- Basys3 적합성의 근거: AXI4-Lite 슬레이브 FSM + BRAM-to-BRAM 버스트(16워드 고정). DDR 불필요. 소스·목적 주소는 동결 맵 `free_slots` 범위 내 선택. free_slots 2슬롯(소스 BRAM 1 + 목적 BRAM 1). XC7A35T LUT 여유 충분(추정).
- 난이도: 3 / 단계: T3 / 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(커스텀 DMA FSM IP 없음) + 적합성 2(AXI4-Lite FSM+BRAM-to-BRAM, DDR 불필요) + 완결성 2(소스/목적 주소 레지스터+버스트 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(digilent-forum-21706-basys3-mb-io, billauer-mb-dma-250mbps, xilinx-xup-cdma-lab7, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-092 AXI CDMA BRAM-to-BRAM 스캐터-개더 패턴 MicroBlaze V 골격 (S6 교훈 → T3 캡스톤)

- 내 판단: billauer.co.il의 MicroBlaze+Linux 250 MB/s DMA 실패·성공 패턴을 역이용해, Basys3 베어메탈에서 AXI CDMA 스캐터-개더 디스크립터 체인을 Vitis BSP로 구현하는 T3 골격. 디스크립터 2개(소스 BRAM-A → 목적 BRAM-B → 다시 소스 BRAM-A 순환)로 연속 전송을 테스트. MicroBlaze V 콘솔에 "CDMA SG PASS/FAIL" 출력.
- id: I-092
- 조합: [AXI-CDMA, BRAM-scatter-gather, MicroBlaze-V, AXI4-Lite]
- 근거 카드: [billauer-mb-dma-250mbps, xilinx-xup-cdma-lab7, digilent-forum-21706-basys3-mb-io]
- 근거 URL: [https://billauer.co.il/blog/?p=1898, https://xilinx.github.io/xup_embedded_system_design_flow/lab7.html]
- 새로움의 근거: 카탈로그에 Basys3 AXI CDMA 스캐터-개더 디스크립터 패턴 아이디어 없음. 기존 T3 패키지는 단순 폴링 전송까지만. S6 교훈(billauer Linux DMA 버그 경험)을 베어메탈 Vitis BSP로 옮겨 재현하는 접근 없음.
- Basys3 적합성의 근거: AXI CDMA SG 모드는 DDR 없이 디스크립터를 BRAM에 직접 저장 가능. 디스크립터 체인 2~4개는 소량 BRAM(< 1블록). MicroBlaze V Vitis BSP `XAxiCdma_SgTransfer()` 사용 가능. free_slots 2슬롯 필요.
- 난이도: 4 / 단계: T3 / 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(SG 디스크립터 체인 패턴 없음) + 적합성 2(BRAM 디스크립터, DDR 불필요) + 완결성 1(Vitis BSP SW 범위 미결) = 5점. 보강: Vitis BSP 범위 구체화, 근거 카드 rechecked_at.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(billauer-mb-dma-250mbps, xilinx-xup-cdma-lab7, digilent-forum-21706-basys3-mb-io, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 1 = 8점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-093 AXI4-Lite 타이머 IP + PWM 비교 출력 + 엔코더 캡처 통합 주변장치 (T2 SoC 접착)

- 내 판단: EF_TCC32의 비교·캡처·인터럽트 3종 패턴을 참고해, AXI4-Lite 슬레이브 타이머 IP 하나에서 (1) 주기 오버플로 인터럽트, (2) PWM 비교 출력(모터 제어 가능), (3) 외부 엔코더 펄스 캡처 타임스탬프를 모두 처리하는 통합 카운터 IP를 Basys3 MicroBlaze V SoC에 연결하는 캡스톤. 하나의 32비트 카운터가 세 역할을 동시에 수행하는 최소 면적 설계.
- id: I-093
- 조합: [AXI4-Lite-timer, PWM-compare, encoder-capture, timer-irq, MicroBlaze-V]
- 근거 카드: [efabless-ef-tcc32, mij001-axil-timer, zipcpu-ziptimer]
- 근거 URL: [https://github.com/efabless/EF_TCC32, https://github.com/mij001/axil-timer]
- 새로움의 근거: 카탈로그에 타이머·PWM·엔코더 캡처를 단일 AXI4-Lite IP에 통합한 Basys3 아이디어 없음. 기존 PWM 카드(element14-eoi-blog3)는 비교 출력만. 캡처+PWM+IRQ 3기능 조합은 모터 제어 사다리(§17.2 우선 주제)와 직결.
- Basys3 적합성의 근거: 32비트 카운터 1개 + 비교 레지스터 1개 + 캡처 레지스터 1개 = LUT < 100개 예상. Pmod JA의 PWM 출력 핀과 엔코더 A/B 입력 핀 모두 3.3V. free_slots 1슬롯 (64KB).
- 난이도: 3 / 단계: T2 / 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(타이머+PWM+캡처 3기능 통합 IP 없음) + 적합성 3(LUT < 100개 예상, Pmod 핀 3.3V, free_slots 1슬롯) + 완결성 2(AXI4-Lite 타이머+비교+캡처 레지스터 범위 명확) = 7점. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(efabless-ef-tcc32, mij001-axil-timer, zipcpu-ziptimer, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-094 주기 타이머 + 소프트웨어 카운터로 구현하는 다중 채널 타임아웃 감시자 (T2 MicroBlaze V 펌웨어 패턴)

- 내 판단: 단일 하드웨어 타이머(mij001-axil-timer 패턴)를 주기 1ms로 설정하고, MicroBlaze V 펌웨어가 소프트웨어 카운터 배열로 4~8채널 독립 타임아웃을 관리하는 패턴. UART 수신 타임아웃, I2C 응답 감시, 워치독 소프트 타이머를 하나의 IP로 처리. 타이머 ISR에서 채널 카운터를 감산하고 만료 채널에 콜백 플래그 설정. MicroBlaze V 인터럽트 컨트롤러 1 슬롯 사용.
- id: I-094
- 조합: [AXI4-Lite-timer, software-multichannel-timeout, MicroBlaze-V-ISR, UART-timeout, I2C-watchdog]
- 근거 카드: [mij001-axil-timer, zipcpu-ziptimer, digilent-basys-3-getting-started-microblaze]
- 근거 URL: [https://github.com/mij001/axil-timer, https://zipcpu.com/zipcpu/2018/04/17/ziptimer.html]
- 새로움의 근거: 카탈로그에 다중 채널 소프트 타이머 패턴 카드 없음. 하드 IP 1개 + 소프트 멀티플렉싱 패턴은 자원 절약 효과가 명확하며 T2 펌웨어 설계 패턴 사례로 가치 있음.
- Basys3 적합성의 근거: 하드웨어 IP 1개(free_slots 1슬롯)로 모든 타임아웃 처리. BRAM 사용 없음. 채널 배열 크기 선택 자유.
- 난이도: 2 / 단계: T2 / 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(다중 채널 소프트 타이머 패턴 없음) + 적합성 3(하드 IP 1개, BRAM 불필요, free_slots 1슬롯) + 완결성 2(1ms ISR+소프트 카운터 배열 범위 명확) = 7점. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(mij001-axil-timer, zipcpu-ziptimer, digilent-basys-3-getting-started-microblaze, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-095 SPI 슬레이브 FSM + AXI4-Lite 래퍼로 MicroBlaze V에 외부 MCU 인터페이스 추가 (T2)

- 내 판단: Basys3 MicroBlaze V SoC에 SPI 슬레이브 IP를 붙여, 외부 Arduino/STM32 SPI 마스터가 AXI 주변장치를 직접 제어하는 이중 인터페이스 구조. SPI 슬레이브 FSM이 MOSI 명령을 받아 AXI4-Lite 버스에 읽기·쓰기를 발급하고, 결과를 MISO로 반환. CPU 없는 외부 MCU 개발 흐름과 MicroBlaze V 펌웨어 흐름을 동시에 지원하는 T2 아이디어.
- id: I-095
- 조합: [SPI-slave-FSM, AXI4-Lite-slave-wrapper, MicroBlaze-V, Arduino-SPI-master]
- 근거 카드: [arpitsingh7634-spi-master-slave, taada33-basys3-spi, airhdl-spi-to-axi-bridge]
- 근거 URL: [https://github.com/arpitsingh7634/SPI_Master_Slave, https://github.com/taada33/basys3-spi]
- 새로움의 근거: 카탈로그에 SPI 슬레이브→AXI4-Lite 버스 마스터 역할을 하는 완성 IP 카드 없음. airhdl-spi-to-axi-bridge는 AXI4-Lite 타깃이지만 Basys3 XDC 없음. 본 아이디어는 Basys3 XDC+MicroBlaze V 동결 맵까지 포함하는 최초 패키지.
- Basys3 적합성의 근거: SPI 슬레이브 FSM은 Pmod 핀 4개(SCLK, MOSI, MISO, CS)로 구현 가능. AXI4-Lite 래퍼는 LUT 수백 개 수준. 동결 맵 free_slots 1칸 사용. arpitsingh7634 카드가 Basys3 XDC 존재를 확인.
- 난이도: 3 / 단계: T2 / 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(SPI 슬레이브→AXI4-Lite 버스 마스터 역할 없음) + 적합성 2(Pmod 핀 4개, AXI4-Lite 래퍼 LUT 수백 개) + 완결성 2(FSM 설계 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(arpitsingh7634-spi-master-slave, taada33-basys3-spi, airhdl-spi-to-axi-bridge, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-096 Verilog Arduino SPI 마스터 모델 테스트벤치 (MCU SPI 타이밍 에뮬레이션) (T1)

- 내 판단: Arduino Uno의 SPI 마스터 타이밍(SCLK 분주, CS 타이밍, Mode 0 CPOL/CPHA)을 Verilog 모델로 구현하여 FPGA SPI 슬레이브 FSM 시뮬레이션 테스트벤치로 사용. MCU 하드웨어 없이 iverilog/verilator에서 슬레이브 IP를 완전히 검증할 수 있는 패턴. S1(MCU→FPGA 이식) + S7(T1 테스트벤치 → T2 통합) 전략의 직접 구현.
- id: I-096
- 조합: [Arduino-SPI-master-model, SPI-slave-FSM, Verilog-testbench, CPOL-CPHA-timing]
- 근거 카드: [arpitsingh7634-spi-master-slave, nandland-spi-slave, arduino-forum-spi-interface-with-fpga-3-3voltage-issue]
- 근거 URL: [https://github.com/arpitsingh7634/SPI_Master_Slave, https://github.com/nandland/spi-slave]
- 새로움의 근거: 카탈로그에 "MCU SPI 마스터를 Verilog 테스트벤치로 모델링"하는 카드 없음. SPI 슬레이브 FSM을 MCU 없이 CI에서 검증하는 패턴으로 하베스트 주제 [B3]의 핵심 요구사항(마스터 시뮬레이터 테스트벤치)과 직접 대응.
- Basys3 적합성의 근거: 테스트벤치 전용(합성 불필요). iverilog·verilator 모두 지원. SPI 타이밍은 클럭 주기 계산으로 결정론적 구현 가능. T1 수준 LUT 사용.
- 난이도: 2 / 단계: T1 / 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(MCU SPI 마스터 Verilog 모델 없음) + 적합성 2(테스트벤치 전용, 합성 불필요, CI 직접 활용) + 완결성 2(SPI 타이밍 모델+CPOL/CPHA 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(arpitsingh7634-spi-master-slave, nandland-spi-slave, arduino-forum-spi-interface-with-fpga-3-3voltage-issue, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-097 I2C 멀티마스터 버스 중재기 + 7세그 버스 상태 모니터 (Basys3 T2)
- 내 판단: Basys3의 Pmod I2C(SDA/SCL)에 2개의 I2C 마스터 FSM을 붙이고, 버스 충돌(ARBLOST) 감지 로직을 AXI4-Lite 슬레이브로 감싸 MicroBlaze V `free_slots` 한 칸에 배정. 7세그 디스플레이에 현재 버스 점유 상태(마스터 ID, 중재 패배 카운터)를 실시간 표시. S2(조합) + S7(T1 단일 마스터 → T2 멀티마스터 연장) 전략 직접 구현.
- id: I-097
- 조합: [I2C-multimaster-FSM, ARBLOST-AXI4-Lite-wrapper, 7-seg-controller, Pmod-I2C]
- 근거 카드: [alexforencich-verilog-i2c, hdl-util-i2c, tom-urkin-i2c]
- 근거 URL: [https://github.com/alexforencich/verilog-i2c, https://github.com/hdl-util/i2c]
- 새로움의 근거: 카탈로그에 멀티마스터 중재를 Basys3 7세그와 연동한 카드·패키지 없음.
- Basys3 적합성의 근거: Pmod 핀 2개(SDA+SCL) + 외부 2.2kΩ 풀업. 7세그 보드 내장. 2개 마스터 FSM은 LUT 수백 개. free_slots 1칸(64KB) 사용.
- 난이도: 3 / 단계: T2 / 상태: vetted
- 심사: 2026-11-05 /harvest(S2+S7), 근거 0+새로움 2+적합성 2+완결성 1 = 5점. 보강: 근거 카드 L3 열람 1건 이상, 클럭 스트레칭 처리 방식 명세.
- 2026-11-05 /verify(16차) 확인: 첫 raw→vetted 심사는 /harvest에서 완료(차단조건재심사 불적용. §14.2). 5점 → vetted. 보강: 근거 카드 L3 열람 1건 이상(WebFetch 차단 중), 클럭 스트레칭 처리 방식 명세.
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(alexforencich-verilog-i2c, hdl-util-i2c, tom-urkin-i2c, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 1 = 8점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-098 I2C 버스 충돌 주입 테스트벤치 (멀티마스터 시뮬레이션 사다리 T1→T2)
- 내 판단: 단일 I2C 마스터 FSM(T1)과 멀티마스터 충돌 시뮬레이션(T2)을 한 테스트벤치로 묶는 패턴. 1단계: 단일 마스터 정상 동작. 2단계: 두 마스터가 동시에 START 발행, SDA 충돌 삽입, 중재 패배 FSM이 버스 양보 검증. 3단계: 클럭 스트레칭 확인. CI iverilog/verilator에서 PASS/FAIL 자동 검증. S7 전략의 직접 구현.
- id: I-098
- 조합: [I2C-master-FSM, I2C-multimaster-arbitration-TB, clock-stretching-TB, iverilog-CI]
- 근거 카드: [alexforencich-verilog-i2c, tom-urkin-i2c, hdl-util-i2c]
- 근거 URL: [https://github.com/alexforencich/verilog-i2c, https://github.com/tom-urkin/I2C, https://github.com/hdl-util/i2c]
- 새로움의 근거: 카탈로그에 "버스 충돌 주입" 테스트벤치를 단계별로 구성한 카드·패키지 없음.
- Basys3 적합성의 근거: 테스트벤치 전용(합성 불필요). iverilog·verilator 모두 지원.
- 난이도: 2 / 단계: T1 / 상태: vetted
- 심사: 2026-11-05 /harvest(S7), 근거 0+새로움 2+적합성 2+완결성 2 = 6점. 보강: 근거 카드 rechecked_at 1건 이상.
- 2026-11-05 /verify(16차) 확인: 첫 raw→vetted 심사는 /harvest에서 완료(차단조건재심사 불적용. §14.2). 6점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상(WebFetch 차단 중).
- 차단조건재심사: 2026-11-05, /verify(17차). 근거 카드 총 3건(alexforencich-verilog-i2c, tom-urkin-i2c, hdl-util-i2c, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 사이클 한도(2건) 소진 → vetted 유지.

## I-099 AXI4-Lite CRC-32 데이터 체크섬 IP — 병렬 XOR 트리 엔진 + 슬레이브 래퍼 (T2 SoC 접착)

내 판단: S1 인접 도메인 이식 — mbuesch/crcgen 도구가 생성한 병렬 CRC-32 Verilog 로직(소프트웨어 명세 → 하드웨어)을 AXI4-Lite 슬레이브 래퍼로 감싸 MicroBlaze V SoC의 메모리맵에 연결. UART 프레이밍 프로토콜(I-095 SPI 슬레이브 카드 선례)에서 데이터 무결성 검증 용도. I-071(메모리 무결성 CRC)과 달리 스트리밍 데이터 체크섬 계산 전용.

- 조합: [CRC-32 조합 XOR 코어(crc32_core.v, T2 embedded), AXI4-Lite 슬레이브 래퍼(crc32_axil.v), MicroBlaze V 소프트웨어 드라이버(C), AXI4-Lite 버스(동결 맵 free_slot)]
- 근거 카드: mbuesch-crcgen(embedded/), heng-xiu-implement-crc-32-verilog(embedded/), mdpi-parallel-crc-fpga-electronics-2021(papers/)
- 근거 URL: https://github.com/mbuesch/crcgen, https://bues.ch/h/crcgen
- 새로움 근거: 카탈로그에 CRC 체크섬 AXI4-Lite IP 카드 없음. mbuesch-crcgen으로 다항식 교체가 용이한 파라메트릭 IP는 카탈로그에 없음 — 내 판단.
- Basys3 적합성 근거: 병렬 CRC-32 XOR 트리는 LUT 약 100개 미만(XC7A35T 20800 LUT 중 < 0.5%). AXI4-Lite 슬레이브는 FF 약 40개 추가. 동결 맵 free_slots 중 1 슬롯(64KB) 배정 가능 — 내 판단.
- 난이도: 2
- 단계: T2
- 상태: ready
- 심사: 2026-11-05 /verify(17차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(mbuesch-crcgen·heng-xiu-implement-crc-32-verilog·mdpi-parallel-crc-fpga-electronics-2021 모두 rechecked_at 없음) + 새로움 2(CRC 체크섬 AXI4-Lite IP 카탈로그 없음, 파라메트릭 IP 없음) + 적합성 3(LUT < 100개, FF ~40개, free_slots 1슬롯, XC7A35T 20800 LUT 중 < 0.5%) + 완결성 2(crc32_core.v+crc32_axil.v+C드라이버 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05 12:45, 점수 10. 근거 3(mbuesch-crcgen·heng-xiu-implement-crc-32-verilog·mdpi-parallel-crc-fpga-electronics-2021 카드 3건, rechecked_at 불문) + 새로움 2(CRC 체크섬 AXI4-Lite IP 카탈로그 없음) + 적합성 3(LUT < 100개, FF ~40개, 카드 기록 근거) + 완결성 2(crc32_core.v+crc32_axil.v+C드라이버 범위 명확) = 10점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 18차 연속 차단(§14.2 차단 조건 적용).

## I-100 멀티-CRC (CRC-8/16/32) 선택 IP — MODE 레지스터로 다항식 런타임 선택 (T2 S2 조합)

내 판단: S2 조합 탐색 — CRC-8(MAXIM/Dallas DS18B20용), CRC-16-CCITT(UART/MODBUS), CRC-32(이더넷/ZIP)를 하나의 AXI4-Lite IP에서 MODE 레지스터 1비트로 선택. mbuesch-crcgen으로 세 다항식 Verilog를 각각 생성해 MUX로 선택. UART 프레이밍 프로토콜 카드(다음 주제 `[B3] UART 프레이밍 프로토콜`)와 조합하면 T2 완성도 높은 통신 데이터 무결성 블록 구성 가능.

- 조합: [CRC-8 XOR 코어, CRC-16 XOR 코어, CRC-32 XOR 코어(각각 crcgen 생성), MODE 레지스터 MUX(T2 glue), AXI4-Lite 슬레이브 래퍼, MicroBlaze V 드라이버]
- 근거 카드: mbuesch-crcgen(embedded/), heng-xiu-implement-crc-32-verilog(embedded/), mdpi-parallel-crc-fpga-electronics-2021(papers/)
- 근거 URL: https://bues.ch/h/crcgen, https://opencores.org/projects/parallelcrcgen
- 새로움 근거: 카탈로그에 멀티-CRC 선택 AXI IP 없음. CRC-8/16/32 세 가지를 단일 IP에서 런타임 선택하는 카드 없음 — 내 판단.
- Basys3 적합성 근거: LUT 약 200~300개(세 XOR 트리 + MUX). AXI4-Lite 슬레이브 1 슬롯. I-099 단일 CRC-32 IP의 확장 — 내 판단.
- 난이도: 3
- 단계: T2
- 상태: used (패키지: mmio-multi-crc-ip, 2026-11-06, 2시간 완결 캡스톤 파이프라인)
- 심사: 2026-11-05 /verify(17차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(mbuesch-crcgen·heng-xiu-implement-crc-32-verilog·mdpi-parallel-crc-fpga-electronics-2021 모두 rechecked_at 없음) + 새로움 2(멀티-CRC 선택 AXI IP 카탈로그 없음) + 적합성 3(LUT 200~300개 세 XOR 트리+MUX, AXI4-Lite 슬레이브 1슬롯, XC7A35T 20800 LUT 중 < 1.5%) + 완결성 2(CRC-8/16/32 세 코어+MODE MUX+AXI4-Lite 래퍼 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05 12:45, 점수 10. 근거 3(mbuesch-crcgen·heng-xiu-implement-crc-32-verilog·mdpi-parallel-crc-fpga-electronics-2021 카드 3건, rechecked_at 불문) + 새로움 2(멀티-CRC 선택 AXI IP 카탈로그 없음) + 적합성 3(LUT 200~300개, AXI4-Lite 슬레이브 1슬롯, 카드 기록 근거) + 완결성 2(CRC-8/16/32 세 코어+MODE MUX+AXI4-Lite 래퍼 범위 명확) = 10점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 18차 연속 차단(§14.2 차단 조건 적용).

---
## I-101: AXI4-Lite UART 프레이밍 IP (길이+타입+CRC16)

내 판단: S3 빈틈 추적 — T2 통신 주변장치 갭 중 "하드웨어에서 패킷 경계를 처리하는 UART 슬레이브 IP"가 카탈로그에 없다. xtrinch의 길이 접두어 방식(1바이트 길이+1바이트 타입)과 CRC16(codeshaa HDLC 참고)을 조합하면 소프트웨어 부담 없이 패킷을 수신할 수 있는 AXI4-Lite IP가 된다.

- 조합: [UART TX/RX 코어, 길이 카운터 FSM, 타입 레지스터, CRC16 모듈, AXI4-Lite 슬레이브 래퍼, MicroBlaze V 인터럽트 라인]
- 근거 카드: xtrinch-icestick-fpga-uart, codeshaa-16-bit-hdlc-using-vhdl, opencores-auto-baud
- 근거 URL: https://github.com/xtrinch/icestick-fpga-uart, https://github.com/codeshaa/16-bit-HDLC-using-VHDL
- 새로움 근거: 카탈로그에 "하드웨어 패킷 프레이머+CRC 검증"을 단일 AXI4-Lite IP로 묶은 카드 없음 — 내 판단.
- Basys3 적합성 근거: LUT 약 300~500개(UART TX/RX + FSM + CRC16), AXI4-Lite 슬롯 1개, Pmod JA UART 핀 사용 가능 — 내 판단.
- 난이도: 3
- 단계: T2
- 상태: ready
- 심사: 2026-11-05 13:49 /verify(18차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(xtrinch-icestick-fpga-uart·codeshaa-16-bit-hdlc-using-vhdl·opencores-auto-baud 모두 rechecked_at 없음) + 새로움 2(하드웨어 패킷 프레이머+CRC16 AXI4-Lite IP 카탈로그 없음) + 적합성 2(LUT 300~500개, AXI4-Lite 슬롯 1개, Pmod JA UART 핀 사용 가능 — 내 판단) + 완결성 2(UART TX/RX + 길이 카운터 FSM + CRC16 + AXI4-Lite 래퍼 범위 명확, RTL+TB 작성 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상.
- 차단조건재심사: 2026-11-05 13:49, 점수 9. 근거 3(xtrinch-icestick-fpga-uart·codeshaa-16-bit-hdlc-using-vhdl·opencores-auto-baud 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지(이 사이클에서 I-104·I-029 ready 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 18차 연속 차단(§14.2 차단 조건 적용).
- 상태 변경: vetted → ready (2026-11-07 /verify 31차, 차단조건재심사 9점, 사이클 슬롯 1번째. WebFetch PROVENANCE_REQUIRED 31차 연속 차단 §14.2 차단 조건 적용)
- 상태: used (2026-11-07 /capstone 2시간 완결 파이프라인, slug: mmio-uart-framing-ip)

---
## I-102: UART 슬립 디텍트 FSM (웨이크업 패턴 하드웨어 감지)

내 판단: S3 빈틈 추적 — UART 프레이밍 주제에서 "슬립 감지(sleep detect)"는 저전력 MCU→FPGA 통신의 공백 구간을 하드웨어가 직접 처리해 인터럽트로 알리는 기능. opencores-auto-baud의 CR 감지 방식을 확장해 2바이트 웨이크업 시퀀스(예: 0xA5 0x5A)를 감지하면 된다.

- 조합: [UART RX 수신기, 슬라이딩 윈도우 패턴 비교기 FSM, 인터럽트 출력(연결선), AXI4-Lite 상태·제어 레지스터]
- 근거 카드: opencores-auto-baud, xtrinch-icestick-fpga-uart
- 근거 URL: https://opencores.org/projects/auto_baud, https://github.com/xtrinch/icestick-fpga-uart
- 새로움 근거: 카탈로그에 슬립/웨이크업 패턴 감지 FSM 카드 없음 — 내 판단.
- Basys3 적합성 근거: LUT < 150개(단순 FSM+비교기), AXI4-Lite 슬롯 1개. 7세그 디스플레이로 상태 표시 추가 가능 — 내 판단.
- 난이도: 2
- 단계: T1
- 상태: vetted
- 심사: 2026-11-05 13:49 /verify(18차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(opencores-auto-baud·xtrinch-icestick-fpga-uart 모두 rechecked_at 없음) + 새로움 2(슬립/웨이크업 패턴 감지 FSM IP 카탈로그 없음) + 적합성 3(LUT < 150개로 소량, AXI4-Lite 슬롯 1개, 내부 신호만 추가 Pmod 불필요 — 내 판단) + 완결성 2(슬라이딩 윈도우 패턴 비교기 FSM + AXI4-Lite 레지스터 범위 명확) = 7점 → vetted. 보강: 근거 카드 1건 추가.
- 차단조건재심사: 2026-11-05 13:49, 점수 9. 근거 2(opencores-auto-baud·xtrinch-icestick-fpga-uart 2건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 18차 연속 차단(§14.2 차단 조건 적용).

---
## I-103: 오토보드+길이 프레이밍 통합 UART IP (CR 보레이트 감지 → 패킷 수신)

내 판단: S7 난이도 사다리 — I-101(단순 프레이머)과 I-102(슬립 감지)를 조합해 한 단계 위를 목표로 하는 T2+ 아이디어. CR 수신 → 보레이트 자동 설정 → 길이 접두어 패킷 수신의 3단계 FSM을 단일 IP에 통합하면 "플러그-앤-플레이" 직렬 포트를 FPGA에서 구현할 수 있다.

- 조합: [오토보드 감지 FSM(CR 기준, opencores 방식), 길이+타입 프레이머(xtrinch 방식), CRC16 검증(codeshaa 참고), AXI4-Lite 슬레이브 래퍼, MicroBlaze V 드라이버 C 함수]
- 근거 카드: opencores-auto-baud, xtrinch-icestick-fpga-uart, codeshaa-16-bit-hdlc-using-vhdl
- 근거 URL: https://opencores.org/projects/auto_baud, https://github.com/xtrinch/icestick-fpga-uart, https://github.com/codeshaa/16-bit-HDLC-using-VHDL
- 새로움 근거: 오토보드 감지와 패킷 프레이밍을 단일 AXI4-Lite IP로 통합한 카드 없음 — 내 판단.
- Basys3 적합성 근거: LUT 약 500~700개(오토보드 FSM + 프레이머 + CRC + AXI4-Lite), 1 AXI4-Lite free_slot. I-101·I-102를 먼저 만들어 단계적으로 검증 가능 — 내 판단.
- 난이도: 4
- 단계: T2
- 상태: ready
- 심사: 2026-11-05 13:49 /verify(18차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(opencores-auto-baud·xtrinch-icestick-fpga-uart·codeshaa-16-bit-hdlc-using-vhdl 모두 rechecked_at 없음) + 새로움 2(오토보드+패킷 프레이밍 단일 AXI4-Lite IP 없음) + 적합성 2(LUT 500~700개, AXI4-Lite free_slot 1개, I-101·I-102 선행 단계화 가능 — 내 판단) + 완결성 2(3단계 FSM + AXI4-Lite 래퍼 + C 드라이버 범위 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 1건, I-101·I-102 선행 완료 후 진행.
- 차단조건재심사: 2026-11-05 13:49, 점수 9. 근거 3(opencores-auto-baud·xtrinch-icestick-fpga-uart·codeshaa-16-bit-hdlc-using-vhdl 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 사이클 상한 2건 도달로 vetted 유지. 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 18차 연속 차단(§14.2 차단 조건 적용).
- 상태 변경: vetted → ready (2026-11-07 /verify 31차, 차단조건재심사 9점, 사이클 슬롯 2번째. WebFetch PROVENANCE_REQUIRED 31차 연속 차단 §14.2 차단 조건 적용)

## I-104: BRAM 핑퐁 더블 버퍼 VGA 컨트롤러 (Basys3 T2, S4 제약 역전)
- id: I-104
- 제목: BRAM 핑퐁 더블 버퍼 VGA 컨트롤러
- 상태: used (패키지: mmio-vga-doublebuf-ip, 2026-11-06, 2시간 완결 캡스톤 파이프라인)
- 요약: 내 판단: Basys3의 no-dram 제약을 역전해, 2개의 듀얼포트 BRAM을 핑퐁으로 운용하는 테어링 없는 VGA 프레임버퍼 컨트롤러. 비활성 버퍼에 MicroBlaze V가 AXI4-Lite로 픽셀 쓰기, 활성 버퍼를 VGA 스캔; VSync에서 버퍼 전환. 160×120×8비트 (2버퍼 ≈ 38 KB, 225 KB BRAM 예산 충분).
- 조합: [video-vga, BRAM]
- 근거 카드:
  - fcayci-xilinx-vga-framebuffer-ip-core (L2, 듀얼포트 BRAM 공유 접근 패턴)
  - projf-projf-explore (L2, BRAM 기반 VGA 그래픽 교육 사례)
  - talsania-fpga-image-buffer (L2, BRAM 프레임버퍼 + 로더 패턴)
- 새로움의 근거: 카탈로그에 더블 버퍼 VGA 패키지 없음; 기존 VGA 카드(oakland-ece378-group4-keyboard2vga 등)는 단일 버퍼 또는 직접 렌더링만 다룸.
- Basys3 적합성의 근거: Basys3 XC7A35T — BRAM 50개(225 KB 총 용량); 160×120×1 byte×2 버퍼 = 38.4 KB로 BRAM 예산 17% 사용. 12비트 VGA 저항 DAC 직결. Pmod 추가 불필요. 내 계산.
- 난이도: 2 (T2 범위, AXI4-Lite 슬레이브 + BRAM TDP 인스턴스 + VGA 타이밍이 전부)
- 단계: T2
- S4 제약역전 근거: DDR 없음 → BRAM만으로 가능 → 저해상도 더블 버퍼 → 더 단순하고 결정론적인 RTL
- 심사: 2026-11-05 13:49 /verify(18차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(fcayci-xilinx-vga-framebuffer-ip-core·projf-projf-explore·talsania-fpga-image-buffer 모두 L2, rechecked_at 없음) + 새로움 2(더블 버퍼 VGA 패키지 카탈로그 없음) + 적합성 3(BRAM 38.4KB < 225KB 예산 17%, 12비트 VGA 보드 내장, Pmod 불필요 — 내 계산) + 완결성 2(AXI4-Lite 슬레이브 + BRAM TDP + VGA 타이밍, 범위 명확) = 7점 → vetted.
- 차단조건재심사: 2026-11-05 13:49, 점수 10. 근거 3(fcayci-xilinx-vga-framebuffer-ip-core·projf-projf-explore·talsania-fpga-image-buffer 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7 → ready 승격(사이클 1번째). WebFetch PROVENANCE_REQUIRED 18차 연속 차단(§14.2 차단 조건 적용).

## I-105 글리치 없는 AXI4-Lite RGB PWM IP (래치-at-reset + 감마 보정 LUT)
- 상태: vetted
- 요약: 내 판단: PWM 카운터 리셋 시점에만 듀티 사이클을 래치하는 글리치 방지 FSM과, BRAM 초기화($readmemh) 기반 감마 보정 LUT(256×8b, 1 BRAM36)를 하나의 AXI4-Lite 슬레이브 IP로 구성. R/G/B 채널 개별 PWM + 감마 테이블 활성화 레지스터 포함. MIT 6.205의 S6 실패 사례와 MapleLED-Core의 감마 LUT 아이디어를 조합.
- 조합: [pwm-rgb, gamma-lut-bram, axi4-lite]
- 근거: [mit-6205-rgb-pwm-week01, maplesilicon-mapleled-core]
- 새로움의 근거: 카탈로그에 래치-at-reset 패턴을 명시한 AXI4-Lite RGB PWM IP 없음. 감마 LUT BRAM 조합도 없음. 두 패턴을 동일 IP 안에 통합하는 것이 새로움.
- Basys3 적합성의 근거: 8비트 PWM 카운터·BRAM36 1개·AXI4-Lite는 Basys3(XC7A35T) 기본 자원 범위 내. 동결 맵 free_slots에서 64KB 1슬롯 배정 가능. RGB LED Pmod 핀 xdc만 추가.
- 난이도: 2 / 단계: T1→T2
- 심사: 2026-11-05 /verify(19차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(mit-6205-rgb-pwm-week01·maplesilicon-mapleled-core 모두 rechecked_at 없음) + 새로움 2(래치-at-reset+감마LUT 조합 AXI4-Lite IP 카탈로그 없음) + 적합성 2(BRAM36 1개·AXI4-Lite free_slot·Basys3 기본 자원 범위 내 — 내 판단) + 완결성 2(AXI4-Lite 슬레이브+PWM FSM+감마LUT 래퍼 범위 명확, RTL+TB 작성 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상.

## I-106 HSV 색상환 → RGB PWM Pmod 드라이버 (하드웨어 FSM, 소수점 없음)
- 상태: vetted
- 요약: 내 판단: Hue 0~359도를 6개 구간(60도씩)으로 나눠 선형 보간으로 R/G/B를 계산하는 순수 정수·시프트 연산 조합 FSM. S 및 V 채널을 곱셈기 없이 시프트+가산으로 처리(olivier-le-sage 패턴 착안). 출력은 8비트 R/G/B 듀티 사이클로 I-105 PWM IP에 연결 또는 직접 Pmod RGB LED 드라이브.
- 조합: [hsv-rgb-fsm, pwm-rgb, axi4-lite]
- 근거: [maplesilicon-mapleled-core, olivier-le-sage-camera-filters]
- 새로움의 근거: 카탈로그에 HSV→RGB 변환 하드웨어 FSM 카드 없음. 카탈로그 카드 3건 모두 "HSV→RGB 변환 없음"을 한계로 명시 — 직접 이 공백을 채우는 조합.
- Basys3 적합성의 근거: 순수 FSM, 곱셈기·BRAM 없음. 목표 LUT < 300. 색상환 주기를 Basys3 스위치 16개(HSV 입력) 또는 AXI4-Lite 레지스터로 제어.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-05 /verify(19차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(maplesilicon-mapleled-core·olivier-le-sage-camera-filters 모두 rechecked_at 없음) + 새로움 2(HSV→RGB 변환 하드웨어 FSM 카탈로그 없음, 카드 3건이 한계로 명시) + 적합성 2(순수 FSM, 곱셈기·BRAM 없음, LUT<300 목표, Basys3 스위치 직결 가능 — 내 판단) + 완결성 2(6구간 선형보간 FSM 범위 명확, RTL+TB 작성 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 1건, HSV 출력을 I-105에 연결하는 범위 확정.

## I-107 RGB LED 난이도 사다리 패키지 (기초 PWM → 감마 → HSV → 호흡 → 무지개)
- 상태: vetted
- 요약: 내 판단: S7 전략으로, 동일 Basys3 대상에서 (a) 단순 8비트 PWM→(b) 감마 보정 LUT→(c) HSV 색상환 소프트 제어→(d) LED 호흡 FSM→(e) 무지개 사이클까지 5단계를 각각 독립 RTL 모듈로 구성하고, 단계별 cocotb 테스트벤치를 갖추는 종합 T1~T2 난이도 사다리 패키지.
- 조합: [pwm-rgb, gamma-lut-bram, hsv-rgb-fsm, led-breathing, axi4-lite]
- 근거: [mit-6205-rgb-pwm-week01, maplesilicon-mapleled-core, olivier-le-sage-camera-filters]
- 새로움의 근거: 카탈로그에 RGB LED 주제로 T1~T2를 단계적으로 연결한 사다리 패키지 없음. I-105·I-106을 하위 모듈로 포함하는 상위 조합.
- Basys3 적합성의 근거: 각 단계가 Basys3 기본 자원 범위 내(I-105·I-106 참조). 단계별로 Makefile 타겟 분리 → CI에서 단계별 검증 가능.
- 난이도: 3 / 단계: T1→T2
- 심사: 2026-11-05 /verify(19차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(mit-6205-rgb-pwm-week01·maplesilicon-mapleled-core·olivier-le-sage-camera-filters 모두 rechecked_at 없음) + 새로움 2(T1~T2 RGB LED 사다리 패키지 카탈로그 없음) + 적합성 2(I-105·I-106 Basys3 적합성 확인, 단계별 Makefile 타겟 분리 가능 — 내 판단) + 완결성 2(5단계 각각 독립 RTL+TB, 단계별 Makefile 타겟 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 1건, I-105·I-106 먼저 패키지화 후 통합.

## I-108 VGA 텍스트 오버레이 + 7세그 동기화 AXI4-Lite IP (S2 조합)
- 상태: used (패키지: mmio-vga-text-7seg-sync-ip, 2026-11-06, 무조건 최대한 생성 원칙 §13.7)
- 요약: 내 판단: BYU ECEN 423 Lab 10의 MMIO 패턴을 착안해, 80×30 문자 버퍼와 7세그 카운터를 단일 AXI4-Lite 슬레이브 IP 안에서 공통 타임스탬프로 묶는 IP. VGA 텍스트 출력이 활성 비디오 선에만 작동하고, 수직 귀선 기간에 7세그 디지트를 순환 갱신한다. 두 디스플레이가 같은 프레임 경계에 동기화되는 패턴을 명세화하고 Basys3에서 검증한다.
- 조합: [video-vga(텍스트 컨트롤러), 7seg-mux, AXI4-Lite, BRAM(문자 버퍼)]
- 근거: [byu-ecen423-lab10-riscv-vga-7seg, argrabowski-fpga-vga-display, itsnotjiaching-ec311project]
- 새로움의 근거: 카탈로그에 VGA와 7세그를 단일 AXI4-Lite IP로 통합해 VSync 기준으로 동기화하는 패키지 없음. 개별 IP 두 개를 합치는 것보다 같은 클럭 도메인 안에서 공통 타임스탬프를 갖는 구조가 차별점(내 판단).
- Basys3 적합성의 근거: Basys3 VGA 12비트 DAC + 4자리 공통-양극 7세그 모두 보드 내장. 80×30 문자 버퍼 = 2400 바이트 → BRAM 1개 미만. AXI4-Lite free_slot 1개. 25MHz VGA 픽셀 클럭은 100MHz 분주.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-06 /verify(20차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(byu-ecen423-lab10-riscv-vga-7seg·argrabowski-fpga-vga-display·itsnotjiaching-ec311project 모두 rechecked_at 없음) + 새로움 2(VGA+7세그 단일 AXI4-Lite IP+VSync 동기화 카탈로그 없음) + 적합성 3(VGA 12비트 DAC·4자리 7세그 보드 내장, 80×30 char buf 2400 B < BRAM 1개, 25MHz 픽셀 클럭 100MHz 분주 가능) + 완결성 2(AXI4-Lite 슬레이브+문자 버퍼+7세그 FSM+텍스트 렌더러 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-06 02:43, /verify(21차), 모든 WebFetch PROVENANCE_REQUIRED 차단(21차 연속). 근거 카드 총 3건(byu-ecen423-lab10-riscv-vga-7seg·argrabowski-fpga-vga-display·itsnotjiaching-ec311project, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 사이클 1번째 → ready 승격.

## I-109 Pong 게임 VGA+7세그 SoC 패키지: MicroBlaze V C 드라이버로 게임 상태 관리 (S7 중간 단계)
- 상태: ready
- 요약: 내 판단: itsnotjiaching-ec311project의 Pong 게임 구조를 MicroBlaze V SoC로 이식. 공·패들 위치를 AXI4-Lite 레지스터로 노출하고, MicroBlaze V C 드라이버가 게임 루프(패들 이동, 충돌 판정, 점수 갱신)를 소프트웨어로 처리. VGA 렌더링과 7세그 점수 표시는 FSM이 담당. FPGA가 렌더링만, 소프트웨어가 로직만 맡는 역할 분리 패턴을 T3 사례로 만든다.
- 조합: [video-vga(렌더링 FSM), 7seg-mux, AXI4-Lite, MicroBlaze V, hid-btn/hid-sw]
- 근거: [itsnotjiaching-ec311project, argrabowski-fpga-vga-display, byu-ecen423-lab10-riscv-vga-7seg]
- 새로움의 근거: 카탈로그의 게임 카드들은 FSM 단독 처리(sdcarlson-fpga-snake는 MicroBlaze이나 하드웨어 미포함). 게임 로직을 MicroBlaze V C 드라이버로 올리고 VGA+7세그를 AXI4-Lite 슬레이브로 묶는 조합 패키지는 없음.
- Basys3 적합성의 근거: Basys3 VGA, 7세그, 버튼 모두 보드 내장. MicroBlaze V는 동결 맵 기반, 게임 로직 소프트웨어화는 AXI-UART Lite 불필요(순수 메모리 맵 접근). BRAM 프레임버퍼 불필요(픽셀 렌더링은 FSM이 실시간 계산).
- 난이도: 3 / 단계: T3
- 심사: 2026-11-06 /verify(20차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(itsnotjiaching-ec311project·argrabowski-fpga-vga-display·byu-ecen423-lab10-riscv-vga-7seg 모두 rechecked_at 없음) + 새로움 2(MicroBlaze V C 드라이버+VGA+7세그 AXI4-Lite 슬레이브 조합 패키지 카탈로그 없음) + 적합성 3(VGA·7세그·버튼 보드 내장, BRAM 프레임버퍼 불필요, MBV 동결 맵 기반) + 완결성 2(VGA 렌더링 FSM+7세그 FSM+AXI4-Lite 레지스터+MBV C 드라이버 범위 명확) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-06 02:43, /verify(21차), 모든 WebFetch PROVENANCE_REQUIRED 차단(21차 연속). 근거 카드 총 3건(itsnotjiaching-ec311project·argrabowski-fpga-vga-display·byu-ecen423-lab10-riscv-vga-7seg, rechecked_at 불문) → 근거 3 + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 사이클 2번째 → ready 승격.

## I-110 RISC-V 어셈블리 → C 이식 비교: MMIO VGA+7세그 드라이버 계층 설계 (S7 어려운 단계)
- 상태: dropped
- 사유: 범위 과다 + ISA 불일치. RISC-V 어셈블리(BYU 카드)와 MicroBlaze V는 다른 ISA라 직접 성능 비교가 어렵고, 세 가지 접근(어셈블리·C·AXI4-Lite)을 하나의 캡스톤에 담으면 범위가 T4 이상으로 커진다. I-108·I-109 먼저 패키지화 후 드라이버 계층 비교로 확장 고려.
- 요약: 내 판단: BYU ECEN 423 Lab 10의 RISC-V 어셈블리 드라이버(`move_char.s`)에서 MMIO 패턴을 추출해, 같은 기능을 MicroBlaze V용 C + xparameters.h로 재작성하는 비교 캡스톤. 어셈블리의 레지스터 직접 접근, C의 인라인 함수 계층, AXI4-Lite 슬레이브로 감싸는 세 가지 접근을 같은 VGA+7세그 하드웨어로 성능을 비교한다. 소프트웨어 추상화 비용과 MMIO 접근 패턴 최적화 방법을 문서화한다.
- 조합: [video-vga, 7seg-mux, AXI4-Lite, MicroBlaze V SW 드라이버]
- 근거: [byu-ecen423-lab10-riscv-vga-7seg, argrabowski-fpga-vga-display, itsnotjiaching-ec311project]
- 새로움의 근거: 카탈로그에 어셈블리 드라이버와 C 드라이버를 같은 하드웨어로 성능 비교하는 사례 없음. MMIO 패턴 이식 비교 연구는 T4 범위이며 교육 가치가 높다(내 판단).
- Basys3 적합성의 근거: Basys3 VGA+7세그 보드 내장. MicroBlaze V용 C 드라이버는 Vitis/SDK 환경. 어셈블리 대 C 성능 차이는 AXI4-Lite 버스 오버헤드와 레지스터 할당 차이로 측정 가능.
- 난이도: 4 / 단계: T4
- 심사: (미심사)

## I-111 Basys3 AXI4-Lite 인터럽트 컨트롤러 IP (오픈소스 Verilog, PG099 호환 레지스터 맵)
- 제목: Basys3 AXI4-Lite 인터럽트 컨트롤러 (PG099 호환 Verilog IP)
- 한 줄 요약: AMD AXI INTC(PG099) 레지스터 맵(ISR·IER·IAR·IVR·MER)을 그대로 따르는 오픈소스 Verilog AXI4-Lite INTC IP — XIntc 소프트웨어 드라이버와 호환
- 조합(주변장치): AXI4-Lite 버스 인터페이스 + 인터럽트 집계(최대 8개) + 우선순위 인코더 + 마스크 레지스터
- 근거 카드: [amd-axi-intc-pg099, zipcpu-icontrol, mij001-axil-timer]
- 새로움의 근거: 카탈로그에 PG099 호환 Verilog(비 VHDL) INTC 오픈소스 자체 구현 사례 없음. 동결 맵 free_slot 배정 연습으로도 가치 있음
- Basys3 적합성의 근거: Artix-7 8입력 기준 ~176 LUT/161 FF (PG099 수치). XC7A35T의 20,800 LUT 대비 여유 충분. AXI4-Lite 슬레이브 인터페이스만 필요
- 난이도: 3 / 단계: T3
- 상태: ready
- 심사: 2026-11-06 /verify(21차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(amd-axi-intc-pg099·zipcpu-icontrol·mij001-axil-timer 모두 rechecked_at 없음) + 새로움 2(PG099 호환 Verilog INTC 오픈소스 구현 사례 카탈로그 없음) + 적합성 3(~176 LUT/161 FF < XC7A35T 20,800 LUT 여유, AXI4-Lite 슬레이브 인터페이스만 필요, PG099 수치 근거 있음) + 완결성 2(ISR·IER·IAR·IVR·MER 레지스터 맵 + 우선순위 인코더 + AXI4-Lite 슬레이브 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-06 /verify(22차), 근거 3(amd-axi-intc-pg099·zipcpu-icontrol·mij001-axil-timer 카드 3건, rechecked_at 불문) + 새로움 2(PG099 호환 Verilog INTC 오픈소스 구현 사례 카탈로그 없음) + 적합성 3(~176 LUT/161 FF < 20,800 LUT 여유, AXI4-Lite 슬레이브만, PG099 수치 근거) + 완결성 2(레지스터 맵 5종 + 우선순위 인코더, RTL+TB 작성 가능) = 10점 ≥ 7점 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단(22차 연속) §14.2 차단 조건 적용.

## I-112 인터럽트 중심 UART RX FIFO IP 조합 (INTC + UARTLite 연동)
- 제목: UART RX not-empty 인터럽트 + AXI4-Lite INTC 연동 패키지
- 한 줄 요약: UART RX FIFO not-empty → INTC → MicroBlaze V IRQ 흐름을 완전 구현한 패키지 — 폴링 대신 인터럽트 중심 드라이버로 버스 대역폭 절약 효과 측정
- 조합(주변장치): AXI UARTLite (또는 커스텀 UART) + AXI INTC + MicroBlaze V ISR
- 근거 카드: [amd-axi-intc-pg099, realisshoon-axi4-lite-multi-peripheral-soc, opencores-auto-baud]
- 새로움의 근거: 카탈로그에 UART+INTC 조합을 ISR 기준으로 완전 구현한 Basys3 사례 없음(realisshoon은 연결만, 드라이버 패턴 없음)
- Basys3 적합성의 근거: AXI UARTLite와 AXI INTC 모두 Vivado IP 카탈로그 기본 제공. Basys3 USB-UART 연결로 테스트 가능
- 난이도: 3 / 단계: T3
- 상태: ready
- 심사: 2026-11-06 /verify(21차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(amd-axi-intc-pg099·realisshoon-axi4-lite-multi-peripheral-soc·opencores-auto-baud 모두 rechecked_at 없음) + 새로움 2(UART+INTC ISR 완전 구현 Basys3 사례 카탈로그 없음) + 적합성 3(AXI UARTLite·AXI INTC Vivado IP 기본 제공, Basys3 USB-UART 연결 가능, MBV 동결 맵 적용 가능) + 완결성 2(UART RX not-empty → INTC → MBV ISR 흐름 명확, RTL+TB+드라이버 C 파일 범위 정의 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-06 /verify(22차), 근거 3(amd-axi-intc-pg099·realisshoon-axi4-lite-multi-peripheral-soc·opencores-auto-baud 카드 3건, rechecked_at 불문) + 새로움 2(UART+INTC ISR 완전 구현 Basys3 사례 카탈로그 없음) + 적합성 3(AXI UARTLite·INTC Vivado 기본 제공, USB-UART 연결 가능, MBV 동결 맵 적용 가능) + 완결성 2(흐름 명확, 범위 정의됨) = 10점 ≥ 7점. 단, 사이클 한도(ready +2) 소진(I-111·I-113 먼저 승격)으로 vetted 유지. 다음 사이클 ready 1순위.
- 차단조건재심사: 2026-11-06 /verify(23차), 근거 3(amd-axi-intc-pg099·realisshoon-axi4-lite-multi-peripheral-soc·opencores-auto-baud 카드 3건, rechecked_at 불문) + 새로움 2(UART+INTC ISR 완전 구현 Basys3 사례 카탈로그 없음) + 적합성 3(AXI UARTLite·INTC Vivado 기본 제공, USB-UART 연결 가능, MBV 동결 맵 적용 가능) + 완결성 2(흐름 명확, 범위 정의됨) = 10점 ≥ 7점 → ready 승격 (사이클 1번째). WebFetch PROVENANCE_REQUIRED 전면 차단(23차 연속) §14.2 차단 조건 적용.

## I-113 인터럽트 컨트롤러 난이도 사다리 패키지 (T1→T2→T3 3단계)
- 제목: INTC 난이도 사다리: 우선순위 인코더(T1) → Wishbone PIC(T2) → AXI4-Lite INTC(T3)
- 한 줄 요약: 같은 주제(인터럽트 처리)를 T1(단순 OR 집계+MMIO)→T2(ZipCPU 스타일 formal-verified)→T3(AXI4-Lite PG099 호환) 3단계로 묶어 커리큘럼 패키지화
- 조합(주변장치): 우선순위 인코더 FSM + Wishbone/MMIO 인터럽트 집계 + AXI4-Lite 슬레이브 INTC
- 근거 카드: [zipcpu-icontrol, amd-axi-intc-pg099, mij001-axil-timer]
- 새로움의 근거: 카탈로그에 단일 주제를 3단계 난이도로 연결한 커리큘럼 패키지 없음. INTC는 모든 SoC에서 필수 블록이므로 교육 가치 높음
- Basys3 적합성의 근거: 각 단계 모두 XC7A35T 자원 범위 내 (T1: ~20 LUT, T2: ~100 LUT, T3: ~200 LUT 추정)
- 난이도: 2(T1)/3(T2)/4(T3) / 단계: T1→T3
- 심사: 2026-11-06 /verify(20차), 첫 raw→vetted 심사(차단조건재심사 불적용). 근거 0(근거 카드 모두 rechecked_at 없음) + 새로움 2(어셈블리→C 비교 사례 없음) + 적합성 1(RISC-V asm과 MicroBlaze V가 다른 ISA, Vitis/SDK 환경 별도 필요, 범위 과다) + 완결성 1(세 가지 접근 비교로 범위 과다, 단일 캡스톤으로 명확히 정의 어려움) = 4점 → dropped.
- 상태: ready
- 심사: 2026-11-06 /verify(21차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(zipcpu-icontrol·amd-axi-intc-pg099·mij001-axil-timer 모두 rechecked_at 없음) + 새로움 2(T1→T2→T3 단일 주제 3단계 커리큘럼 패키지 카탈로그 없음) + 적합성 3(T1 ~20 LUT, T2 ~100 LUT, T3 ~200 LUT 추정 모두 XC7A35T 20,800 LUT 여유 충분) + 완결성 2(각 단계 독립 RTL+TB, 단계별 Makefile 타겟 명확, 범위 정의됨) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건.
- 차단조건재심사: 2026-11-06 /verify(22차), 근거 3(zipcpu-icontrol·amd-axi-intc-pg099·mij001-axil-timer 카드 3건, rechecked_at 불문) + 새로움 2(T1→T2→T3 단일 주제 3단계 커리큘럼 패키지 카탈로그 없음) + 적합성 3(T1 ~20 LUT, T2 ~100 LUT, T3 ~200 LUT 추정 모두 XC7A35T 20,800 LUT 여유 충분) + 완결성 2(각 단계 독립 RTL+TB 범위 명확) = 10점 ≥ 7점 → ready 승격 (사이클 2번째). WebFetch PROVENANCE_REQUIRED 전면 차단(22차 연속) §14.2 차단 조건 적용.

## I-114
- 제목: AXI4-Lite 슬레이브 레지스터 파일 자동화 IP (WSTRB + $clog2 디코더 + 형식 검증)
- 한 줄 요약: ZipCPU easyaxil의 `apply_wstrb()` 함수와 `$clog2(DATA_WIDTH)-3` 주소 디코더를 MicroBlaze V IP 표준 래퍼에 통합한 Verilog-2001 레지스터 파일 IP
- 조합(주변장치): AXI4-Lite 슬레이브 레지스터 뱅크 + WSTRB 처리 함수 + $clog2 주소 디코더 + faxil_slave.v 형식 검증
- 근거 카드: [zipcpu-wb2axip-easyaxil, chclau-magellan-basys3-axil-regs, bugratufan-axion-hdl]
- 새로움의 근거: 카탈로그에 MicroBlaze V IP 표준을 준수하는 Verilog-2001 AXI4-Lite 슬레이브 레지스터 파일 IP 없음. WSTRB + 형식 검증 조합은 카드 중 zipcpu만이 갖추나 IP 표준 래퍼는 미작성
- 내 판단: 모든 커스텀 IP의 기반 부품이므로 T2 필수 블록. library/rtl/axil_regs.v가 연습용이고 IP 표준 래퍼가 없어 프로젝트 IP로 쓸 수 없음. 이 아이디어가 그 공백을 채운다
- Basys3 적합성의 근거: AXI4-Lite 슬레이브만으로 XC7A35T 자원 50 LUT 미만 추정. 추가 외부 부품 없음
- 난이도: 2 / 단계: T2
- 상태: used (패키지: mmio-axilite-regfile-ip, 2026-11-06, 2시간 완결 캡스톤 파이프라인)
- 심사: 2026-11-06 /verify(22차), 첫 raw→vetted 심사(표준, rechecked_at 기준). 근거 0(zipcpu-wb2axip-easyaxil·chclau-magellan-basys3-axil-regs·bugratufan-axion-hdl 모두 rechecked_at 없음) + 새로움 2(IP 표준 래퍼+WSTRB+형식검증 조합 카탈로그 없음) + 적합성 3(50 LUT 미만, 외부 부품 없음, Vivado IP 카탈로그 기본, 근거 카드 Basys3 적합성 L3) + 완결성 2(WSTRB·디코더·faxil_slave 형식검증 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건이면 근거 1점 추가로 8점 → ready.
- 차단조건재심사: 2026-11-06 /verify(23차), 근거 3(zipcpu-wb2axip-easyaxil·chclau-magellan-basys3-axil-regs·bugratufan-axion-hdl 카드 3건, rechecked_at 불문) + 새로움 2(IP 표준 래퍼+WSTRB+형식검증 조합 카탈로그 없음) + 적합성 3(50 LUT 미만, 외부 부품 없음, Vivado IP 기본 제공, 근거 카드 Basys3 L3) + 완결성 2(WSTRB·디코더·faxil_slave 범위 명확) = 10점 ≥ 7점 → ready 승격 (사이클 2번째). WebFetch PROVENANCE_REQUIRED 전면 차단(23차 연속) §14.2 차단 조건 적용.

## I-115
- 제목: Basys3 JTAG-to-AXI 마스터 활용 디버그 패턴 (소프트웨어 없이 레지스터 직접 접근)
- 한 줄 요약: chclau Magellan 패턴을 32비트 레지스터 뱅크로 확장하고, JTAG-to-AXI 마스터로 커스텀 IP의 레지스터를 TCL 명령으로 직접 읽고 쓰는 Basys3 디버그 하네스
- 조합(주변장치): Xilinx JTAG-to-AXI 마스터 IP + AXI4-Lite 슬레이브 레지스터 뱅크 (I-114) + AXI Interconnect
- 근거 카드: [chclau-magellan-basys3-axil-regs, zipcpu-wb2axip-easyaxil, amd-axi-intc-pg099]
- 새로움의 근거: JTAG-to-AXI 마스터를 MicroBlaze V 없이 쓰는 디버그 하네스 사례가 카탈로그에 없음. 소프트웨어 드라이버 없이 IP 초기 검증을 하는 패턴으로 T2 선행 디버그에 활용 가능
- 내 판단: 새 IP 개발 시 소프트웨어 준비 전에 레지스터 동작을 먼저 확인하는 용도. CPU 비종속이므로 MicroBlaze V로 교체 후에도 같은 TCL 패턴 재사용 가능
- Basys3 적합성의 근거: Xilinx JTAG-to-AXI IP는 Vivado에 내장. Basys3 Artix-7에서 Vivado Hardware Manager로 TCL 접근 가능 (chclau Magellan 사례 L3 확인)
- 난이도: 2 / 단계: T2
- 상태: ready
- 심사: 2026-11-06 /verify(22차), 첫 raw→vetted 심사(표준, rechecked_at 기준). 근거 0(chclau-magellan-basys3-axil-regs·zipcpu-wb2axip-easyaxil·amd-axi-intc-pg099 모두 rechecked_at 없음) + 새로움 2(JTAG-to-AXI 마스터 활용 디버그 하네스 사례 카탈로그 없음) + 적합성 2(Vivado JTAG-to-AXI IP 내장, chclau Magellan L3 Basys3 TCL 접근 확인, 단 MicroBlaze V 없는 독립 테스트 사례는 미확인) + 완결성 2(TCL 명령·TB·RTL 범위 정의됨) = 6점 → vetted. 보강: JTAG-to-AXI 단독 사용 Basys3 사례 카드, 근거 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(23차), 근거 3(chclau-magellan-basys3-axil-regs·zipcpu-wb2axip-easyaxil·amd-axi-intc-pg099 카드 3건, rechecked_at 불문) + 새로움 2(JTAG-to-AXI 마스터 활용 디버그 하네스 사례 카탈로그 없음) + 적합성 2(Vivado JTAG-to-AXI IP 내장·TCL 접근 확인이나 MicroBlaze V 없는 독립 사례 미확인) + 완결성 2(TCL 명령·TB·RTL 범위 정의됨) = 9점 ≥ 7점. 단, 사이클 한도(ready +2) 소진(I-112·I-114 먼저 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(chclau-magellan-basys3-axil-regs·zipcpu-wb2axip-easyaxil·amd-axi-intc-pg099 카드 3건, rechecked_at 불문) + 새로움 2(JTAG-to-AXI 마스터 활용 디버그 하네스 사례 카탈로그 없음) + 적합성 2(Vivado JTAG-to-AXI IP 내장·TCL 접근 확인이나 MicroBlaze V 없는 독립 사례 미확인) + 완결성 2(TCL 명령·TB·RTL 범위 정의됨) = 9점 ≥ 7점 → ready 승격 (사이클 1번째). WebFetch PROVENANCE_REQUIRED 전면 차단(24차 연속) §14.2 차단 조건 적용.

## I-116
- 제목: AXI4-Lite 슬레이브 IP 개발 사다리 (단순 레지스터 → CDC 동기화기 → 인터럽트 연동)
- 한 줄 요약: T2 단계에서 T2+ 단계로 이어지는 AXI4-Lite 슬레이브 IP 사다리: (1) 단순 RW 레지스터 뱅크 → (2) 클럭 도메인 교차 CDC 토글 동기화기 추가 → (3) wr_strobe 인터럽트 소스 연동
- 조합(주변장치): AXI4-Lite 슬레이브 레지스터 뱅크 + CDC 토글 동기화기 + 인터럽트 소스 wr_strobe + zipcpu-icontrol INTC 연결
- 근거 카드: [zipcpu-wb2axip-easyaxil, bugratufan-axion-hdl, zipcpu-icontrol]
- 새로움의 근거: 단계적으로 복잡도를 올리는 AXI4-Lite 슬레이브 사다리가 카탈로그에 없음. axion-hdl의 CDC 옵션과 ZipCPU icontrol의 인터럽트 패턴을 조합한 커리큘럼으로 활용 가능
- 내 판단: S7(난이도 사다리) 전략에 맞는 아이디어. 각 단계가 독립 패키지로 §13.5 단계 체인을 구성할 수 있음
- Basys3 적합성의 근거: 각 단계 XC7A35T 자원 범위 내. CDC 동기화기는 LUT 10개 미만, 인터럽트 연동은 별도 wire 연결만 추가
- 난이도: 2(1단계)/3(2단계)/3(3단계) / 단계: T2
- 상태: ready
- 심사: 2026-11-06 /verify(22차), 첫 raw→vetted 심사(표준, rechecked_at 기준). 근거 0(zipcpu-wb2axip-easyaxil·bugratufan-axion-hdl·zipcpu-icontrol 모두 rechecked_at 없음) + 새로움 2(단순 레지스터→CDC→인터럽트 연동 3단계 사다리 카탈로그 없음) + 적합성 2(Basys3 자원 충분 추정이나 CDC 토글 동기화 Basys3 사례 미확인) + 완결성 2(각 단계 독립 RTL+TB로 §13.5 체인 가능, 범위 명확) = 6점 → vetted. 보강: CDC 동기화 Basys3 카드, 근거 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(23차), 근거 3(zipcpu-wb2axip-easyaxil·bugratufan-axion-hdl·zipcpu-icontrol 카드 3건, rechecked_at 불문) + 새로움 2(단순 레지스터→CDC→인터럽트 연동 3단계 사다리 카탈로그 없음) + 적합성 3(Basys3 자원 추정 충분, CDC 토글 LUT 10개 미만 추정, §13.5 단계 체인 가능) + 완결성 2(각 단계 독립 RTL+TB 범위 명확) = 10점 ≥ 7점. 단, 사이클 한도(ready +2) 소진(I-112·I-114 먼저 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(zipcpu-wb2axip-easyaxil·bugratufan-axion-hdl·zipcpu-icontrol 카드 3건, rechecked_at 불문) + 새로움 2(단순 레지스터→CDC→인터럽트 연동 3단계 사다리 카탈로그 없음) + 적합성 3(Basys3 자원 추정 충분, CDC 토글 LUT 10개 미만 추정, §13.5 단계 체인 가능) + 완결성 2(각 단계 독립 RTL+TB 범위 명확) = 10점 ≥ 7점 → ready 승격 (사이클 2번째). WebFetch PROVENANCE_REQUIRED 전면 차단(24차 연속) §14.2 차단 조건 적용.

## I-117
- 제목: 윈도우 WDT + 7세그 카운트다운 가시화 IP (창 열림/닫힘 타이밍 표시)
- 한 줄 요약: AMD AXI Timebase WDT의 윈도우 모드에서 현재 카운터 값을 7세그에 실시간 표시 — 창이 열리면 세그가 깜박이고, 창 위반 시 "Err" 표시, 정상 서비스 시 "OK" 표시
- 조합(주변장치): AXI Timebase WDT(윈도우 모드) + 7세그 디스플레이 드라이버 + 상태 FSM(IDLE/OPEN/VIOLATED)
- 근거 카드: [amd-axi-timebase-wdt-pg083, mij001-axil-timer, chclau-magellan-basys3-axil-regs]
- 새로움의 근거: 카탈로그에 WDT + 7세그 카운트다운 조합 없음. 윈도우 경계를 7세그로 가시화하면 타이밍 오류를 직관적으로 확인할 수 있어 교육 가치 높음
- 내 판단: S2(조합 탐색) 전략의 핵심 아이디어. AMD IP를 직접 쓰면 RTL 없이도 Vivado IP 연결만으로 T2 패키지 구성 가능. 7세그 카운트다운은 §10의 `mmio-7seg-adv-ip` 패턴 재사용 가능
- Basys3 적합성의 근거: Basys3 4자리 7세그, AXI Timebase WDT Vivado IP 카탈로그 기본 제공. MicroBlaze V 펌웨어(C)에서 창 경계값 설정 → 7세그 슬레이브 IP로 카운터 값 전달. 외부 부품 없음
- 난이도: 3 / 단계: T2
- 상태: ready
- 심사: 2026-11-06 /verify(22차), 첫 raw→vetted 심사(표준, rechecked_at 기준). 근거 0(amd-axi-timebase-wdt-pg083·mij001-axil-timer·chclau-magellan-basys3-axil-regs 모두 rechecked_at 없음) + 새로움 2(WDT + 7세그 카운트다운 가시화 카탈로그 없음) + 적합성 2(Basys3 7세그+Vivado IP 내장이나 카운터 값 AXI 읽기 방법 미확인) + 완결성 2(IDLE/OPEN/VIOLATED FSM + 7세그 출력 범위 명확, RTL+TB 작성 가능) = 6점 → vetted. 보강: AXI Timebase WDT 카운터 값 읽기 방법 L3 확인, rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(30차), 모든 WebFetch PROVENANCE_REQUIRED 차단(30차 연속). 근거 3(amd-axi-timebase-wdt-pg083·mij001-axil-timer·chclau-magellan-basys3-axil-regs 카드 3건, rechecked_at 불문) + 새로움 2(WDT + 7세그 카운트다운 가시화 조합 카탈로그 없음) + 적합성 2(Basys3 7세그+Vivado IP 내장이나 카운터 값 AXI 읽기 방법 미확인) + 완결성 2(IDLE/OPEN/VIOLATED FSM + 7세그 출력 범위 명확, RTL+TB 작성 가능) = 9점 ≥ 7점 → ready 승격 (사이클 30차 2번째).

## I-118
- 제목: 삼중 WDT 채널 비교 패널 (기본·윈도우·소프트웨어 에뮬 3채널 동시 표시)
- 한 줄 요약: 기본 WDT(AMD IP), 윈도우 WDT(AMD IP 윈도우 모드), 소프트웨어 카운터 에뮬 WDT 세 채널을 동시에 Basys3 LED+7세그로 표시 — 각 채널의 타임아웃 패턴 차이를 직접 비교
- 조합(주변장치): AXI Timebase WDT(기본 모드) + AXI Timebase WDT(윈도우 모드) + SW 에뮬 WDT 타이머 + LED 3채널 상태 표시 + 7세그 채널 선택
- 근거 카드: [amd-axi-timebase-wdt-pg083, ignaciosim-tt06-triple-watchdog, mij001-axil-timer]
- 새로움의 근거: `ignaciosim-tt06-triple-watchdog`(TinyTapeout ASIC)에서 착안. Basys3 MicroBlaze V 버전은 같은 개념을 Vivado IP + C 드라이버로 구성 — ASIC과 FPGA+MCU 구현 방식 비교 가능
- 내 판단: S2(조합 탐색) + S1(인접 도메인 이식) 복합 아이디어. TinyTapeout 카드가 근거이므로 카드 L3 승격 후 근거 점수 올리면 vetted 가능
- Basys3 적합성의 근거: Vivado IP 2개(기본+윈도우 모드) + SW 에뮬 타이머 3채널. 각 채널 독립 AXI4-Lite 슬롯 필요(동결 맵 free_slots 3개). XC7A35T LUT 추정 ~300 LUT — 충분
- 난이도: 3 / 단계: T2
- 상태: vetted
- 심사: 2026-11-06 /verify(22차), 첫 raw→vetted 심사(표준, rechecked_at 기준). 근거 0(amd-axi-timebase-wdt-pg083·ignaciosim-tt06-triple-watchdog·mij001-axil-timer 모두 rechecked_at 없음) + 새로움 2(TinyTapeout ASIC 패턴을 Basys3 MicroBlaze V로 이식하는 사례 카탈로그 없음) + 적합성 2(Vivado IP 2개+SW 에뮬 조합 자원 ~300 LUT 추정이나 free_slots 3개 필요, 동결 맵 슬롯 여유 확인 필요) + 완결성 1(3채널 동시 비교 범위가 넓어 TB 작성 범위 정의 추가 필요) = 5점 → vetted (보강 필요). 보강: free_slots 여유 확인, 각 채널 독립 패키지로 분할 고려, ignaciosim 카드 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(30차), 모든 WebFetch PROVENANCE_REQUIRED 차단(30차 연속). 근거 3(amd-axi-timebase-wdt-pg083·ignaciosim-tt06-triple-watchdog·mij001-axil-timer 카드 3건, rechecked_at 불문) + 새로움 2(TinyTapeout ASIC 패턴을 Basys3 MicroBlaze V로 이식하는 사례 카탈로그 없음) + 적합성 2(Vivado IP 2개+SW 에뮬 조합, free_slots 3개 필요, 슬롯 여유 확인 필요) + 완결성 1(3채널 비교 TB 작성 범위 정의 추가 필요) = 8점 ≥ 7점. 사이클 한도(ready +2) 소진(I-062·I-117 승격)으로 vetted 유지.

## I-119
- 제목: WDT 하트비트 핀 출력 + 외부 슈퍼바이저 IC 모의 패턴
- 한 줄 요약: AMD AXI Timebase WDT의 WDTOUT(하트비트 출력)을 Pmod GPIO 핀으로 내보내고, Basys3 내부에서 소프트웨어 슈퍼바이저를 에뮬레이션 — WDT 하트비트가 끊기면 7세그에 경고, MicroBlaze가 WDT 서비스를 멈추면 리셋 신호 발생
- 조합(주변장치): AXI Timebase WDT(WDTOUT) + Pmod GPIO 출력 + 소프트웨어 슈퍼바이저 FSM + 7세그 경고 표시
- 근거 카드: [amd-axi-timebase-wdt-pg083, suoglu-axi-lite-slave, amoghvarsh-axi4-lite-timer-wdt]
- 새로움의 근거: 하트비트 핀 출력을 외부 슈퍼바이저 IC와 연동하는 패턴을 FPGA 내에서 모의하는 사례 카탈로그에 없음. WDTOUT를 단순 리셋 연결 대신 외부 가시화하는 S4(제약 역전) 아이디어
- 내 판단: S4(제약 역전) + S2(조합 탐색) 복합 아이디어. 외부 슈퍼바이저 IC(TPS3828 등) 없이 Pmod 핀에 로직 애널라이저/오실로스코프 연결로 하트비트 파형 확인 가능. 보드 동작 확인(S3)이 쉬운 구조
- Basys3 적합성의 근거: WDTOUT → 최상위 Verilog에서 Pmod 핀 직접 연결. 외부 부품 없이 Basys3 Pmod JA/JB에 출력. 추가 IP 없음(GPIO 핀 연결만)
- 난이도: 2 / 단계: T2
- 상태: ready
- 심사: 2026-11-06 /verify(22차), 첫 raw→vetted 심사(표준, rechecked_at 기준). 근거 1(amd-axi-timebase-wdt-pg083 L2 카드 있음, rechecked_at 없지만 카드 존재) + 새로움 2(WDTOUT 하트비트 외부 출력 + 슈퍼바이저 모의 조합 카탈로그 없음) + 적합성 2(WDTOUT→Pmod 직접 연결 가능, 단 WDTOUT 핀 Basys3 xdc 매핑 미확인) + 완결성 2(WDTOUT→Pmod 출력 + FSM + 7세그 경고 범위 명확, RTL+TB 작성 가능) = 7점 → vetted. 보강: WDTOUT Basys3 xdc 매핑 확인, amd-axi-timebase-wdt-pg083 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(23차), 근거 3(amd-axi-timebase-wdt-pg083·suoglu-axi-lite-slave·amoghvarsh-axi4-lite-timer-wdt 카드 3건, rechecked_at 불문) + 새로움 2(WDTOUT 하트비트 외부 출력+슈퍼바이저 모의 조합 카탈로그 없음) + 적합성 2(WDTOUT→Pmod 직접 연결 가능이나 xdc 매핑 미확인) + 완결성 2(출력+FSM+7세그 경고 범위 명확) = 9점 ≥ 7점. 단, 사이클 한도(ready +2) 소진(I-112·I-114 먼저 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(amd-axi-timebase-wdt-pg083·suoglu-axi-lite-slave·amoghvarsh-axi4-lite-timer-wdt 카드 3건, rechecked_at 불문) + 새로움 2(WDTOUT 하트비트 외부 출력+슈퍼바이저 모의 조합 카탈로그 없음) + 적합성 2(WDTOUT→Pmod 직접 연결 가능이나 xdc 매핑 미확인) + 완결성 2(출력+FSM+7세그 경고 범위 명확) = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-115·I-116 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-05 /verify(25차), 모든 WebFetch PROVENANCE_REQUIRED 차단(25차 연속). 근거 3(amd-axi-timebase-wdt-pg083·suoglu-axi-lite-slave·amoghvarsh-axi4-lite-timer-wdt 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-089·I-090 승격)으로 vetted 유지. 다음 사이클 ready 1순위 후보.
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(amd-axi-timebase-wdt-pg083·suoglu-axi-lite-slave·amoghvarsh-axi4-lite-timer-wdt 카드 3건, rechecked_at 불문) + 새로움 2(WDTOUT 하트비트 외부 출력+슈퍼바이저 모의 조합 카탈로그 없음) + 적합성 2(WDTOUT→Pmod 직접 연결 가능이나 xdc 매핑 미확인) + 완결성 2(출력+FSM+7세그 경고 범위 명확) = 9점 ≥ 7점 → ready 승격 (사이클 26차 2번째 슬롯).
- 상태 변경: vetted → ready (2026-11-06 /verify 26차)

## I-120
- id: I-120
- 제목: 동결 맵 AXI 주소 충돌 검사기 IP (Python + Verilog `$error`)
- 한 줄 요약: 내 판단: `config/soc_address_map.json` 동결 맵을 읽어 주소 중첩을 검사하고, Verilog `parameter`+`$error`/$finish 패턴으로 합성 전 충돌을 차단하는 파이썬 생성기 + RTL 가드 조합
- 조합: 주변장치: 동결 맵(`config/soc_address_map.json`) + Python 주소 계산기 + Verilog elaboration-time `$error` 가드 + 테스트벤치 (겹침 케이스 자동 주입)
- 근거 카드: alexforencich-verilog-axi-crossbar (elaboration-time $error 패턴, L3), zipcpu-wb2axip-crossbar-addrdecode (SLAVE_ADDR/MASK 추출, L2), zipcpu-wb2axip-easyaxil (MicroBlaze V AXI4-Lite 슬레이브 패턴, L3)
- 근거 URL: https://zipcpu.com/blog/2019/07/17/crossbar.html, https://axion-hdl.readthedocs.io/
- 새로움의 근거: 카탈로그에 "동결 맵 → 주소 충돌 검사 도구" 조합 없음. Python 생성기 + Verilog $error 가드를 한 패키지로 만든 사례 없음
- Basys3 적합성의 근거: 내 판단: Python 도구는 CI 단계에서 실행, Verilog 가드는 모든 IP에 붙임. 보드 자원 소비 없음. 동결 맵 64KB 슬롯 → M_ADDR_WIDTH=16(최소 12 조건 충족)
- 난이도: 2 / 단계: T2
- 상태: ready
- 심사: 2026-11-06 /verify(23차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 모두 rechecked_at 없음) + 새로움 2(동결 맵 → 주소 충돌 검사기 조합 카탈로그 없음, Python 생성기+Verilog $error 가드 패키지 사례 없음) + 적합성 2(Python CI 도구+Verilog $error 가드 보드 자원 없음이나 동결 맵→Verilog parameter 변환 도구 사례 미확인) + 완결성 2(Python 생성기+Verilog 가드+TB 범위 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2(동결 맵→주소 충돌 검사기 조합 카탈로그 없음) + 적합성 2(Python CI 도구+Verilog $error 가드 보드 자원 없음이나 도구 사례 미확인) + 완결성 2(Python 생성기+Verilog 가드+TB 범위 명확) = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-115·I-116 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-05 /verify(25차), 모든 WebFetch PROVENANCE_REQUIRED 차단(25차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-089·I-090 승격)으로 vetted 유지. 다음 사이클 ready 2순위 후보.
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지. 다음 사이클 ready 1순위 후보.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. ready 승격 (사이클 1번째).

## I-121
- id: I-121
- 제목: 2M+4S AXI4-Lite 소형 크로스바 IP (MicroBlaze V + 추가 마스터 1개)
- 한 줄 요약: 내 판단: 동결 맵의 free_slots을 슬레이브 범위로 사용하는 2M+4S Verilog-2001 AXI4-Lite 소형 크로스바. 에러 슬레이브(DECERR), 우선순위 중재, elaboration-time $error 충돌 검출 포함
- 조합: 주변장치: AXI4-Lite 크로스바 RTL + 에러 슬레이브 + 동결 맵 슬롯 2개 소비 (DMA 마스터 슬롯 + 크로스바 자체) + 형식 검증용 $onehot0 어서션
- 근거 카드: alexforencich-verilog-axi-crossbar (범위 디코딩 패턴, L3), zipcpu-wb2axip-crossbar-addrdecode (에러 슬레이브·중재 규칙, L2), dpretet-axi-crossbar (라우팅 테이블·DECERR, L3)
- 근거 URL: https://zipcpu.com/blog/2019/07/17/crossbar.html
- 새로움의 근거: 카탈로그에 Basys3 대상 소형 AXI4-Lite 크로스바 + 동결 맵 연동 + 형식 어서션 조합 없음
- Basys3 적합성의 근거: 내 판단: 2M+4S, 32비트 주소 → LUT ~200~400개 추정 (Yosys 추정 필요). 동결 맵 free_slots 2개 소비. BRAM 사용 없음
- 난이도: 3 / 단계: T2
- 상태: used
- 심사: 2026-11-06 /verify(23차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·dpretet-axi-crossbar 모두 rechecked_at 없음) + 새로움 2(Basys3 대상 소형 AXI4-Lite 크로스바+동결 맵 연동+형식 어서션 조합 카탈로그 없음) + 적합성 2(LUT ~200~400개 추정이나 Yosys 미검증, free_slots 2개 소비 여유 미확인) + 완결성 2(2M+4S 에러 슬레이브+중재 RTL+TB 범위 명확) = 6점 → vetted. 보강: Yosys LUT 추정 확인, free_slots 여유 확인.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·dpretet-axi-crossbar 카드 3건, rechecked_at 불문) + 새로움 2(Basys3 대상 소형 AXI4-Lite 크로스바+동결 맵 연동+형식 어서션 조합 카탈로그 없음) + 적합성 2(LUT ~200~400개 추정이나 Yosys 미검증, free_slots 2개 소비 여유 미확인) + 완결성 2(2M+4S 에러 슬레이브+중재 RTL+TB 범위 명확) = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-115·I-116 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-05 /verify(25차), 모든 WebFetch PROVENANCE_REQUIRED 차단(25차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·dpretet-axi-crossbar 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-089·I-090 승격)으로 vetted 유지. 다음 사이클 ready 3순위 후보.
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·dpretet-axi-crossbar 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지. 다음 사이클 ready 2순위 후보.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·dpretet-axi-crossbar 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. ready 승격 (사이클 2번째, 한도 소진).
- 사용: 2026-11-06 /capstone(2시간 완결). 패키지 slug: mmio-axil-xbar-2m4s-ip. 검증 등급: S0. 근거 재확인 없음(§13.7 사용자 운영 방침).
- 상태: used

## I-122
- id: I-122
- 제목: AXI 주소 범위 테스트벤치 자동 생성기 (겹침·미매핑·에러 케이스)
- 한 줄 요약: 내 판단: 동결 맵과 카드에서 주소 범위를 읽어, 범위 경계(base, base+size-1, base+size)와 겹침 케이스를 자동으로 주입하는 Verilog 테스트벤치를 생성하는 Python 도구
- 조합: 주변장치: Python 테스트벤치 생성기 + AXI4-Lite 슬레이브 DUT + DECERR 경로 검증 + 경계값 자동 주입
- 근거 카드: alexforencich-verilog-axi-crossbar (접수 제어·DECERR 패턴, L3), zipcpu-wb2axip-crossbar-addrdecode (에러 슬레이브 패턴, L2), zipcpu-wb2axip-easyaxil (AXI4-Lite 슬레이브 레지스터 패턴, L3)
- 근거 URL: https://github.com/dpretet/axi-crossbar, https://zipcpu.com/blog/2019/07/17/crossbar.html
- 새로움의 근거: 카탈로그에 경계값 자동 주입 테스트벤치 생성기 패턴 없음. 도구+테스트 조합
- Basys3 적합성의 근거: 내 판단: Python 도구는 CI에서 실행, 생성된 테스트벤치는 iverilog/verilator로 실행. BRAM/LUT 소비 없음
- 난이도: 2 / 단계: T2
- 상태: ready
- 심사: 2026-11-06 /verify(23차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 모두 rechecked_at 없음) + 새로움 2(경계값 자동 주입 테스트벤치 생성기 패턴 카탈로그 없음) + 적합성 2(Python CI 도구, iverilog/verilator 실행, BRAM/LUT 소비 없음이나 생성기 도구 사례 미확인) + 완결성 2(경계값 주입+DECERR 검증+TB 생성 범위 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 추가.
- 차단조건재심사: 2026-11-06 /verify(24차), 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2(경계값 자동 주입 테스트벤치 생성기 패턴 카탈로그 없음) + 적합성 2(Python CI 도구, iverilog/verilator 실행, BRAM/LUT 소비 없음이나 생성기 도구 사례 미확인) + 완결성 2(경계값 주입+DECERR 검증+TB 생성 범위 명확) = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-115·I-116 승격)으로 vetted 유지. 다음 사이클 ready 후보.
- 차단조건재심사: 2026-11-05 /verify(25차), 모든 WebFetch PROVENANCE_REQUIRED 차단(25차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-089·I-090 승격)으로 vetted 유지. 다음 사이클 ready 4순위 후보.
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지. 다음 사이클 ready 3순위 후보.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-120·I-121 승격)으로 vetted 유지. 다음 사이클 ready 1순위 후보.
- 차단조건재심사: 2026-11-06 /verify(29차), 모든 WebFetch PROVENANCE_REQUIRED 차단(29차 연속). 근거 3(alexforencich-verilog-axi-crossbar·zipcpu-wb2axip-crossbar-addrdecode·zipcpu-wb2axip-easyaxil 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점 → ready 승격 (사이클 29차 1번째).
- 상태 변경: vetted → ready (2026-11-06 /verify 29차)

## I-123 Vitis BSP 커스텀 AXI4-Lite 드라이버 등록 단계별 캡스톤 (mdd/tcl + sinit.c 패턴, T3)

내 판단: S3 빈틈 추적 — 카탈로그 T3 갭 중 "Vitis BSP에 커스텀 AXI4-Lite 드라이버를 등록하는 단계별 패키지"가 없다. mtvl-for-fpga 블로그의 mdd/tcl 구조(data/ + src/)와 hackster SHA-256의 xparameters.h XPAR 패턴을 조합하면, MicroBlaze V + Vitis 2024.2 환경에서 libgen이 `XPAR_<IP>_0_BASEADDR`를 자동 생성하는 전 과정을 T3 캡스톤으로 구성할 수 있다.

- id: I-123
- 조합: [커스텀 AXI4-Lite 슬레이브 IP(Verilog), mdd/tcl 드라이버 메타데이터, Vitis BSP 빌드, xparameters.h XPAR 매크로 검증 TB]
- 근거 카드: mtvl-for-fpga-standalone-axi-driver, hackster-sha256-microblaze-v-axi-accelerator, salmon1113-vitis-microblaze-gpio-setup
- 근거 URL: https://mtvl-for-fpga.blogspot.com/2019/02/how-to-create-standalone-driver-to.html, https://www.hackster.io/raymondkelly454/sha-256-hardware-accelerator-for-microblaze-v-zybo-7000-eb4e99
- 새로움의 근거: 카탈로그에 mdd/tcl+sinit.c 패턴을 처음부터 만드는 MicroBlaze V Vitis 2024.2 캡스톤 없음 — 내 판단.
- Basys3 적합성의 근거: 커스텀 AXI4-Lite 슬레이브 LUT < 300개, 동결 맵 free_slots 1슬롯. BSP 드라이버 등록은 소프트웨어 흐름이므로 보드 자원 증가 최소 — 내 판단.
- 난이도: 3 / 단계: T3 / 상태: ready
- 심사: 2026-11-06 /harvest(S3+S1). 근거 0(세 근거 카드 rechecked_at 없음) + 새로움 2(mdd/tcl+sinit.c 단계별 T3 캡스톤 없음) + 적합성 2(AXI4-Lite free_slots 1슬롯, BSP 소프트웨어 흐름, Basys3 가능) + 완결성 2(mdd/tcl+sinit.c+LookupConfig+TB 범위 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상. (첫심사 오기재 수정: 2026-11-05 /verify(25차) — 5~7점 → vetted 처리)
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(mtvl-for-fpga-standalone-axi-driver·hackster-sha256-microblaze-v-axi-accelerator·salmon1113-vitis-microblaze-gpio-setup 카드 3건, rechecked_at 불문) + 새로움 2(mdd/tcl+sinit.c 단계별 T3 캡스톤 없음) + 적합성 2(AXI4-Lite free_slots 1슬롯, BSP 소프트웨어 흐름, Basys3 가능) + 완결성 2(mdd/tcl+sinit.c+LookupConfig+TB 범위 명확) = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(mtvl-for-fpga-standalone-axi-driver·hackster-sha256-microblaze-v-axi-accelerator·salmon1113-vitis-microblaze-gpio-setup 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점. 사이클 한도(ready +2) 소진(I-120·I-121 승격)으로 vetted 유지. 다음 사이클 ready 2순위 후보.
- 차단조건재심사: 2026-11-06 /verify(29차), 모든 WebFetch PROVENANCE_REQUIRED 차단(29차 연속). 근거 3(mtvl-for-fpga-standalone-axi-driver·hackster-sha256-microblaze-v-axi-accelerator·salmon1113-vitis-microblaze-gpio-setup 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7점 → ready 승격 (사이클 29차 2번째, 한도 소진).
- 상태 변경: vetted → ready (2026-11-06 /verify 29차)

## I-124 MicroBlaze V xparameters.h XPAR 매크로 자동 검증 CI 스크립트 (T3)

내 판단: S1 인접 도메인 이식 — hackster SHA-256의 `XPAR_SHA256_COMPRESSION_0_BASEADDR`와 salmon1113의 `XPAR_AXI_GPIO_0_BASEADDR` 패턴을 근거로, Vitis BSP 빌드 후 생성된 xparameters.h의 XPAR 매크로 베이스 주소가 동결 맵(`config/soc_address_map.json`)의 `free_slots` 배정 주소와 일치하는지 CI에서 자동 검사하는 Python 스크립트 아이디어. 소프트웨어와 하드웨어 주소 맵이 어긋나는 버그를 BSP 빌드 단계에서 조기에 차단할 수 있다.

- id: I-124
- 조합: [Python CI 스크립트, xparameters.h 파서, config/soc_address_map.json 동결 맵 비교, XPAR 매크로 베이스 주소 검증]
- 근거 카드: mtvl-for-fpga-standalone-axi-driver, hackster-sha256-microblaze-v-axi-accelerator, salmon1113-vitis-microblaze-gpio-setup
- 근거 URL: https://mtvl-for-fpga.blogspot.com/2019/02/how-to-create-standalone-driver-to.html
- 새로움의 근거: 카탈로그에 xparameters.h XPAR 매크로를 동결 맵과 자동 대조하는 CI 도구 없음 — 내 판단.
- Basys3 적합성의 근거: Python 도구이므로 보드 자원 소비 없음. CI iverilog 실행 환경에서 그대로 활용 가능 — 내 판단.
- 난이도: 2 / 단계: T3 / 상태: vetted
- 심사: 2026-11-06 /harvest(S1+S3). 근거 0(세 근거 카드 rechecked_at 없음) + 새로움 2(XPAR 매크로 동결 맵 자동 대조 도구 없음) + 적합성 3(Python CI 도구, 보드 자원 없음, 동결 맵과 직접 연동 가능) + 완결성 2(Python 파서+비교기+리포트 범위 명확) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상. (첫심사 오기재 수정: 2026-11-05 /verify(25차) — 5~7점 → vetted 처리)
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(mtvl-for-fpga-standalone-axi-driver·hackster-sha256-microblaze-v-axi-accelerator·salmon1113-vitis-microblaze-gpio-setup 카드 3건, rechecked_at 불문) + 새로움 2(XPAR 매크로 동결 맵 자동 대조 도구 없음) + 적합성 3(Python CI 도구, 보드 자원 없음, 동결 맵과 직접 연동 가능) + 완결성 2(Python 파서+비교기+리포트 범위 명확) = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(mtvl-for-fpga-standalone-axi-driver·hackster-sha256-microblaze-v-axi-accelerator·salmon1113-vitis-microblaze-gpio-setup 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-120·I-121 승격)으로 vetted 유지. 다음 사이클 ready 3순위 후보.

## I-125 AXI GPIO 직접 접근 vs Xil_In32/Out32 vs 고수준 드라이버 성능 비교 테스트벤치 (T3)

내 판단: S7 난이도 사다리 — salmon1113 GPIO 카드의 레지스터 직접 접근(오프셋 0x00/0x04)과 hackster SHA-256의 `Xil_Out32`/`Xil_In32` 패턴, 그리고 mtvl-for-fpga의 `LookupConfig → CfgInitialize` 고수준 드라이버를 같은 GPIO IP에 단계별로 적용해 성능(사이클 수)을 비교하는 C 소프트웨어 테스트벤치. MicroBlaze V 위에서 실제 구현 비용 차이를 수치로 보여주는 T3 학습용 패키지.

- id: I-125
- 조합: [AXI GPIO IP, raw 포인터 직접 접근, Xil_Out32/Xil_In32 래퍼, LookupConfig+CfgInitialize 고수준 드라이버, XTmrCtr 사이클 카운터, C 소프트웨어 비교 TB]
- 근거 카드: salmon1113-vitis-microblaze-gpio-setup, hackster-sha256-microblaze-v-axi-accelerator, mtvl-for-fpga-standalone-axi-driver
- 근거 URL: https://salmon1113.tistory.com/140, https://www.hackster.io/raymondkelly454/sha-256-hardware-accelerator-for-microblaze-v-zybo-7000-eb4e99
- 새로움의 근거: 카탈로그에 세 가지 AXI GPIO 접근 계층 비교 테스트벤치 없음 — 내 판단.
- Basys3 적합성의 근거: AXI GPIO + XTmrCtr IP 조합은 Basys3 MicroBlaze V에서 완전히 가능. BSP에 포함된 IP 사용만으로 추가 LUT 최소 — 내 판단.
- 난이도: 2 / 단계: T3 / 상태: vetted
- 심사: 2026-11-06 /harvest(S7). 근거 0(세 근거 카드 rechecked_at 없음) + 새로움 2(세 계층 비교 테스트벤치 카탈로그 없음) + 적합성 3(AXI GPIO+XTmrCtr Basys3 완전 가능, 추가 LUT 최소) + 완결성 2(raw 포인터+Xil_In32/Out32+LookupConfig 세 계층+측정 범위 명확) = 7점 → vetted. 보강: 근거 카드 rechecked_at 1건 이상. (첫심사 오기재 수정: 2026-11-05 /verify(25차) — 5~7점 → vetted 처리)
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(salmon1113-vitis-microblaze-gpio-setup·hackster-sha256-microblaze-v-axi-accelerator·mtvl-for-fpga-standalone-axi-driver 카드 3건, rechecked_at 불문) + 새로움 2(세 계층 비교 테스트벤치 카탈로그 없음) + 적합성 3(AXI GPIO+XTmrCtr Basys3 완전 가능, 추가 LUT 최소) + 완결성 2(raw 포인터+Xil_In32/Out32+LookupConfig 세 계층+측정 범위 명확) = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(salmon1113-vitis-microblaze-gpio-setup·hackster-sha256-microblaze-v-axi-accelerator·mtvl-for-fpga-standalone-axi-driver 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-120·I-121 승격)으로 vetted 유지.

## I-126 Basys3 AXI-Lite 버스 프로파일러: 여러 IP 동시 접근 레이턴시 측정 (T2)

내 판단: S4 제약 역전 — no-DRAM 제약을 역전시켜 BRAM 슬레이브로만 구성된 순수 AXI-Lite 패브릭에서 버스 경합 레이턴시를 정밀 측정. axiperf.v 아이디어(읽기/쓰기 bin 카운터, AXI-Lite 제어)를 AXI4-Lite 전용으로 단순화해 약 100줄 Verilog로 재구현. MicroBlaze V의 `free_slots`(0xC800_0000)에 연결, C 드라이버로 start/stop → UART 출력.

- id: I-126
- 조합: [AXI4-Lite 버스 프로파일러 RTL, MicroBlaze V C 드라이버, AXI SmartConnect, BRAM 슬레이브 ×2, UART 출력]
- 근거 카드: zipcpu-wb2axip-axiperf, restuccia-ecrts2019-axi-bus-contention, amoghvarsh-axi4-lite-timer-wdt
- 근거 URL: https://zipcpu.com/blog/2021/08/14/axiperf.html, https://core.ac.uk/download/343692393.pdf
- 새로움의 근거: 카탈로그에 Basys3 순수 PL(no-PS) AXI-Lite 성능 카운터 구현 카드 없음 — 내 판단.
- Basys3 적합성의 근거: AXI-Lite 카운터 ~100 LUT 추정, AXI SmartConnect+BRAM+MicroBlaze V 모두 Basys3 XC7A35T에 가능 — 내 판단.
- 난이도: 2 / 단계: T2 / 상태: vetted
- 심사: 2026-11-06 /harvest(S4). 근거 0(근거 카드 rechecked_at 없음, 금번 세션 신규 카드) + 새로움 2(순수 PL AXI-Lite 프로파일러 없음) + 적합성 3(100LUT 추정, Basys3 가능) + 완결성 2(RTL+C드라이버+UART 출력 범위 명확) = 7점 → raw(첫심사). 보강: 근거 카드 rechecked_at 1건 이상.
- 상태 변경: raw → vetted (2026-11-06 /verify 26차, 첫심사 7점 충족)
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(zipcpu-wb2axip-axiperf·restuccia-ecrts2019-axi-bus-contention·amoghvarsh-axi4-lite-timer-wdt 카드 3건, rechecked_at 불문) + 새로움 2(순수 PL AXI-Lite 프로파일러 없음) + 적합성 3(100LUT 추정, Basys3 가능) + 완결성 2(RTL+C드라이버+UART 출력 범위 명확) = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(zipcpu-wb2axip-axiperf·restuccia-ecrts2019-axi-bus-contention·amoghvarsh-axi4-lite-timer-wdt 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-120·I-121 승격)으로 vetted 유지.

## I-127 MicroBlaze V 버스 경합 테스트벤치: 복수 AXI 마스터 동시 릴리스로 최악 레이턴시 측정 (T3)

내 판단: S4 제약 역전 + Restuccia ECRTS2019 방법론 Basys3 이식 — 논문의 트래픽 발생기+타이머 접근법을 MicroBlaze V firmware로 재현. 2개 AXI-Lite 슬레이브를 같은 SmartConnect에 연결하고 동시에 write-read 사이클을 수행, XTmrCtr로 왕복 레이턴시 측정.

- id: I-127
- 조합: [MicroBlaze V C firmware, AXI SmartConnect ×1, AXI-Lite BRAM 슬레이브 ×2, XTmrCtr, UART 결과 출력]
- 근거 카드: restuccia-ecrts2019-axi-bus-contention, zipcpu-wb2axip-axiperf, mij001-axil-timer
- 근거 URL: https://core.ac.uk/download/343692393.pdf, https://zipcpu.com/blog/2021/08/14/axiperf.html
- 새로움의 근거: 카탈로그에 Basys3 firmware-only 버스 경합 측정 패키지 없음 — 내 판단.
- Basys3 적합성의 근거: firmware만으로 구현(RTL 추가 없음), XTmrCtr BSP 포함, Basys3 MBv SoC에서 완전 가능 — 내 판단.
- 난이도: 2 / 단계: T3 / 상태: vetted
- 심사: 2026-11-06 /harvest(S4). 근거 0(restuccia 카드 rechecked_at 없음) + 새로움 2(firmware 경합 측정 패키지 없음) + 적합성 3(XTmrCtr BSP 포함, 추가 RTL 없음) + 완결성 2(2슬레이브+타이머+UART 범위 명확) = 7점 → raw(첫심사). 보강: 근거 카드 rechecked_at 1건 이상.
- 상태 변경: raw → vetted (2026-11-06 /verify 26차, 첫심사 7점 충족)
- 차단조건재심사: 2026-11-06 /verify(26차), 모든 WebFetch PROVENANCE_REQUIRED 차단(26차 연속). 근거 3(restuccia-ecrts2019-axi-bus-contention·zipcpu-wb2axip-axiperf·mij001-axil-timer 카드 3건, rechecked_at 불문) + 새로움 2(firmware 경합 측정 패키지 없음) + 적합성 3(XTmrCtr BSP 포함, 추가 RTL 없음) + 완결성 2(2슬레이브+타이머+UART 범위 명확) = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-056·I-119 승격)으로 vetted 유지.
- 차단조건재심사: 2026-11-06 /verify(27차), 모든 WebFetch PROVENANCE_REQUIRED 차단(27차 연속). 근거 3(restuccia-ecrts2019-axi-bus-contention·zipcpu-wb2axip-axiperf·mij001-axil-timer 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7점. 사이클 한도(ready +2) 소진(I-120·I-121 승격)으로 vetted 유지.

## I-128 Basys3 Q포맷 포화 가산기 IP: AXI4-Lite 슬레이브 + 7세그 결과 표시 (T2)

내 판단: S1 인접 도메인 이식 — wangxuan95-fpga-fixedpoint의 fxp_addsub 아이디어를 GPL-3.0으로 복사 없이 재작성, AXI4-Lite 슬레이브로 감싸 동결 맵 free_slots에 연결. MicroBlaze V C 드라이버로 Q8.8 두 값을 써넣으면 덧셈 결과와 upflow 플래그를 읽어 7세그에 표시.

- id: I-128
- 조합: [Q8.8 포화 가산기 RTL(자체 작성), AXI4-Lite 슬레이브 래퍼, MicroBlaze V C 드라이버, Basys3 7세그 디코더]
- 근거 카드: wangxuan95-fpga-fixedpoint, gisselquist-zipcpu-bit-growth
- 근거 URL: https://github.com/WangXuan95/FPGA-FixedPoint, https://zipcpu.com/dsp/2017/07/21/bit-growth.html
- 새로움의 근거: 카탈로그에 고정소수점 연산 AXI-Lite IP + 7세그 조합 없음 — 내 판단.
- Basys3 적합성의 근거: Q8.8=16비트 가산기 약 20LUT 추정, AXI4-Lite 슬레이브 약 50LUT, 7세그 BCD 디코더 Basys3 내장 — Basys3 XC7A35T에서 여유 있게 가능 — 내 판단.
- 난이도: 2 / 단계: T2 / 상태: vetted
- 심사: 2026-11-06 /harvest(S1). 근거 0(근거 카드 rechecked_at 없음, 금번 세션 신규) + 새로움 2(고정소수점 AXI-Lite IP 조합 없음) + 적합성 3(20+50LUT 추정, Basys3 가능) + 완결성 2(RTL+래퍼+드라이버+7세그 범위 명확) = 7점 → raw(첫심사). 보강: 근거 카드 rechecked_at 1건 이상.
- 상태 변경: raw → vetted (2026-11-06 /verify 27차, 첫심사 7점 충족)
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 9. 근거 2(wangxuan95-fpga-fixedpoint·gisselquist-zipcpu-bit-growth 카드 2건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-129 Basys3 파라미터화 FIR 필터 고정소수점 MAC 유닛 (T4)

내 판단: S2 조합 탐색 — lay007-zynq-sdr-course-block04의 비트 성장 규칙(계수 Q1.15, 누산기 Q4.28, 출력 Q1.15)을 적용한 Basys3 FIR 필터. DSP48E1으로 Q포맷 곱셈을 추론시키고, 가드 비트 계산을 capstone.json에 명시. 계수 배열은 BRAM에 저장.

- id: I-129
- 조합: [Q1.15 FIR 계수 BRAM, Q4.28 누산기, DSP48E1 추론 곱셈, Q1.15 출력 포화+반올림, AXI4-Stream 인터페이스]
- 근거 카드: lay007-zynq-sdr-course-block04, wangxuan95-fpga-fixedpoint, gisselquist-zipcpu-bit-growth
- 근거 URL: https://lay007.github.io/zynq-sdr-course/en/blocks/04-fixed-point-workflow/
- 새로움의 근거: 카탈로그에 Basys3 순수 PL FIR + DSP48E1 + Q포맷 명세 패키지 없음 — 내 판단.
- Basys3 적합성의 근거: 탭 16개 FIR → DSP48E1 16개 → XC7A35T 90개 중 18%, BRAM 1개, LUT ~200 추정 — 내 판단.
- 난이도: 3 / 단계: T4 / 상태: used / 패키지 slug: mmio-fir-q1p15-mac-ip
- 심사: 2026-11-06 /harvest(S2). 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(Basys3 FIR Q포맷 명세 패키지 없음) + 적합성 3(DSP48E1×16 XC7A35T 가능) + 완결성 1(AXI-Stream 인터페이스 추가 정의 필요) = 6점 → raw(첫심사). 보강: AXI-Stream 인터페이스 범위 확정 + 근거 카드 rechecked_at.
- 상태 변경: raw → vetted (2026-11-06 /verify 27차, 첫심사 6점 충족 → vetted)
- 차단조건재심사: 2026-11-07 /verify 32차, 근거 3(카드 3건 rechecked_at 불문: lay007·wangxuan95·gisselquist) + 새로움 2 + 적합성 3 + 완결성 1 = 9점 → ready 승격
- 상태 변경: ready → used (2026-11-07 /capstone 자동 과제화, 무조건 최대한 생성 원칙, 근거 재확인 없음)

## I-130 고정소수점 비트폭 계산기: 덧셈·곱셈·FIR 가드 비트 자동 산출 웹 도구 (T0)

내 판단: S5 비정형 출처 — gisselquist-zipcpu-bit-growth와 lay007-zynq-sdr-course-block04의 비트 성장 규칙을 근거로, Basys3 캡스톤 설계 보조 도구를 만든다. Q포맷 입력(I, F, 연산 종류, 탭 수)을 넣으면 필요 비트폭을 자동 계산해 capstone.json `memory_map` 필드에 붙여 넣을 수 있는 형태로 출력.

- id: I-130
- 조합: [Python/HTML 웹 계산기, Q포맷 비트 성장 공식, FIR 가드 비트 공식, capstone.json 출력 템플릿]
- 근거 카드: gisselquist-zipcpu-bit-growth, lay007-zynq-sdr-course-block04
- 근거 URL: https://zipcpu.com/dsp/2017/07/21/bit-growth.html, https://lay007.github.io/zynq-sdr-course/en/blocks/04-fixed-point-workflow/
- 새로움의 근거: 카탈로그에 capstone.json 연동 비트폭 보조 도구 없음 — 내 판단.
- Basys3 적합성의 근거: 소프트웨어 도구(RTL 불필요), 하네스 tools/ 디렉터리에 추가 — 내 판단.
- 난이도: 1 / 단계: T0 / 상태: ready
- 심사: 2026-11-06 /harvest(S5). 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(capstone.json 연동 도구 없음) + 적합성 3(소프트웨어 도구, 하드웨어 불필요) + 완결성 2(계산 공식·출력 형식 명확) = 7점 → raw(첫심사). 보강: 근거 카드 rechecked_at 1건 이상.
- 상태 변경: raw → vetted (2026-11-06 /verify 27차, 첫심사 7점 충족)
- 차단조건재심사: 2026-11-07 /verify 32차, 근거 2(카드 2건 rechecked_at 불문: gisselquist-zipcpu-bit-growth·lay007-zynq-sdr-course-block04) + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 32차 연속 차단(§14.2 차단 조건 적용).

## I-131 Basys3 AXI4-Lite 순차 MAC 슬레이브 IP: MicroBlaze V 1×N 내적 연산 (T4, S7 사다리 1단)

내 판단: S7 난이도 사다리 1단 — antoinelecalvez05-ml-dot-product-accelerator의 sequential(1-MAC) 아키텍처를 AXI4-Lite 슬레이브로 감싸, MicroBlaze V가 INT8 벡터 쌍을 쓰면 N클럭 후 내적 결과를 읽는 최소 IP. 동결 맵 free_slots 1슬롯 사용, cocotb 패턴으로 TB 작성 가능.

- id: I-131
- 조합: [signed-int8 순차 MAC(1클럭/연산), AXI4-Lite 슬레이브 래퍼, MicroBlaze V C 드라이버, Basys3 7세그 결과 표시]
- 근거 카드: antoinelecalvez05-ml-dot-product-accelerator, wangxuan95-fpga-fixedpoint, gisselquist-zipcpu-bit-growth
- 근거 URL: https://github.com/Antoinelecalvez05/ml-dot-product-accelerator
- 새로움의 근거: 카탈로그에 Basys3 int8 순차 MAC AXI-Lite IP 패키지 없음. antoinelecalvez05 카드는 FSM 단독이며 AXI4-Lite 래퍼 없음 — 내 판단.
- Basys3 적합성의 근거: 순차 MAC 약 20LUT + DSP48×1 + AXI래퍼 약 50LUT — XC7A35T 가능. 동결 맵 free_slots 1슬롯. antoinelecalvez05 카드가 Basys3 데모 확인(fit_basys3: yes) — 내 판단.
- 난이도: 2 / 단계: T4 / 상태: vetted
- 심사: 2026-11-06 /harvest(S7). 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(int8 순차 MAC AXI-Lite IP 없음) + 적합성 3(Basys3 데모 확인 카드, DSP48×1) + 완결성 2(MAC FSM+AXI래퍼+드라이버+7세그 범위 명확) = 7점 → raw(첫심사). 보강: 근거 카드 rechecked_at 추가.
- 상태 변경: raw → vetted (2026-11-06 /verify 28차, /harvest 첫심사 7점 충족)
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 10. 근거 3(antoinelecalvez05-ml-dot-product-accelerator·wangxuan95-fpga-fixedpoint·gisselquist-zipcpu-bit-growth 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-132 Basys3 4×4 시스톨릭 어레이 행렬 곱셈 AXI-Lite IP (T4, S7 사다리 2단)

내 판단: S7 난이도 사다리 2단 — ethanflorendo-fpga-systolic-array-matrix-multiplier의 4×4 시스톨릭 어레이 구조를 근거로, Basys3에 맞게 xdc·클럭을 포팅하고 AXI4-Lite 슬레이브로 감싸 MicroBlaze V가 행렬 주소·실행 명령을 쓰면 결과를 읽는 IP. BRAM 가중치 적재 패턴 적용.

- id: I-132
- 조합: [4×4 시스톨릭 PE 어레이(자체 RTL), BRAM 입출력 행렬 저장, AXI4-Lite 슬레이브, MicroBlaze V C 드라이버]
- 근거 카드: ethanflorendo-fpga-systolic-array-matrix-multiplier, antoinelecalvez05-ml-dot-product-accelerator, wangxuan95-fpga-fixedpoint
- 근거 URL: https://github.com/EthanFlorendo/FPGA-Systolic-Array-Matrix-Multiplier
- 새로움의 근거: 카탈로그에 Basys3 4×4 시스톨릭 어레이 + AXI4-Lite 슬레이브 조합 패키지 없음. I-131(순차 MAC)보다 단계가 높아 사다리 연속성 있음 — 내 판단.
- Basys3 적합성의 근거: 4×4=16 PE, DSP48 추정 최대 16개(XC7A35T 90개 중 18%), BRAM 1~2개. 시스톨릭 어레이 타이밍 클로저 위험 있으나 가능 범위 — 내 판단.
- 난이도: 3 / 단계: T4 / 상태: vetted
- 심사: 2026-11-06 /harvest(S7). 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(4×4 시스톨릭 AXI-Lite 패키지 없음) + 적합성 2(DSP48×16 가능 추정, 타이밍 위험 있음) + 완결성 2(PE·BRAM·AXI·드라이버 범위 명확) = 6점 → raw(첫심사). 보강: DSP48 타이밍 실측, 근거 카드 rechecked_at.
- 상태 변경: raw → vetted (2026-11-06 /verify 28차, /harvest 첫심사 6점 충족)
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 9. 근거 3(ethanflorendo-fpga-systolic-array-matrix-multiplier·antoinelecalvez05-ml-dot-product-accelerator·wangxuan95-fpga-fixedpoint 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-133 Basys3 Compute-in-BRAM MAC IP: BRAMAC 아이디어 Artix-7 이식 (T4, S7+S4 사다리 3단)

내 판단: S7 난이도 사다리 3단 + S4 제약 역전 — arxiv-2304.03974-bramac 논문의 BRAM-내-계산 아이디어를 XC7A35T BRAM36(SDP 모드, 2×18kb 포트)에 맞게 RTL 새 작성. BRAM을 가중치 저장과 MAC 계산을 동시에 수행하는 단위로 활용, DSP48 절약을 목표로 함. AXI4-Lite 슬레이브로 감싸 MicroBlaze V 연결.

- id: I-133
- 조합: [BRAM36 SDP 모드 compute-in-BRAM MAC(자체 RTL), AXI4-Lite 슬레이브, MicroBlaze V C 드라이버, int8 가중치 적재]
- 근거 카드: arxiv-2304.03974-bramac, ethanflorendo-fpga-systolic-array-matrix-multiplier, antoinelecalvez05-ml-dot-product-accelerator
- 근거 URL: https://arxiv.org/abs/2304.03974
- 새로움의 근거: 카탈로그에 BRAM을 계산 패브릭으로 쓰는 MAC IP 패키지 없음. I-132(시스톨릭 어레이)에서 한 단계 더 나아가 S4 제약 역전 적용 — 내 판단.
- Basys3 적합성의 근거: XC7A35T BRAM36 50블록. BRAMAC는 BRAM 포트 타이밍을 직접 활용해 DSP48 대신 BRAM을 적산에 씀. RTL은 논문 내용을 근거로 새로 작성 필요(소스 복사 불가). BRAM SDP 모드 포트 사양 확인 선행 필요 — 내 판단.
- 난이도: 5 / 단계: T4 / 상태: vetted
- 심사: 2026-11-06 /harvest(S7+S4). 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(BRAM 계산 패브릭 IP 없음) + 적합성 1(BRAM SDP 사양 확인 필요, 불확실) + 완결성 1(BRAM SDP 포트 조작 방식 미확인, RTL 설계 복잡도 높음) = 4점 → raw(첫심사). 보강: BRAM36 SDP 포트 사양 확인, 논문 L3 열람.
- 상태 변경: raw → vetted (2026-11-06 /verify 28차 재심사, /verify 독립 재점수 5점: 근거 0 + 새로움 2 + 적합성 2(BRAM36 50블록 충분, SDP 모드 가용성 plausible) + 완결성 1(BRAM SDP 포트 조작 미확인, RTL 복잡도 높음) = 5점 ≥ 5점 → vetted. /harvest의 4점 판정 재심사 결과 적합성 2로 조정)
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 7. 근거 3(arxiv-2304.03974-bramac·ethanflorendo-fpga-systolic-array-matrix-multiplier·antoinelecalvez05-ml-dot-product-accelerator 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 1(BRAM SDP 포트 사양 미확인, 고위험) + 완결성 1(BRAM SDP 조작 방식 미확정, RTL 설계 복잡도 높음) = 7점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-134 Basys3 2층 MLP MNIST 추론 가속기 AXI4-Lite IP (T4)
- 상태: vetted
- 요약: 내 판단: libfpga-fpga-neuron의 Q4.4 MAC 커널과 erwanregy-neural-network-fpga의 파라메트릭 FSM 패턴을 결합하고, UNLV 논문의 D-ReLU 활성화(부호 비트 검사+비트 시프트)를 적용한 2층 MLP를 AXI4-Lite 슬레이브로 구현하는 T4 패키지. MNIST 가중치는 Python 훈련 후 `$readmemh`로 BRAM에 올린다.
- 조합: [MLP, Q4.4-fixed-point, D-ReLU, BRAM, AXI4-Lite]
- 근거: [libfpga-fpga-neuron, erwanregy-neural-network-fpga, unlv-si-harris-drelu-fpga-mlp]
- 새로움의 근거: 카탈로그에 MLP 추론 AXI-Lite IP 패키지 없음. 세 카드를 조합해 Q4.4 + D-ReLU + BRAM 가중치 패턴을 한 캡스톤으로 통합하는 사례는 아직 없다.
- Basys3 적합성의 근거: 내 판단: 2층 MLP(예: 784→64→10)의 Q4.4 MAC은 DSP48 없이 LUT로 구현 가능. libfpga 단일 뉴런(832 LUT4)을 근거로 64뉴런 × 2층은 LUT 약 2000~4000 추정(Basys3 20800 LUT 이내). BRAM은 가중치 저장에 1~2블록(Basys3 50블록 이내). 실측 없어 추정.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-06 /verify(29차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(libfpga-fpga-neuron·erwanregy-neural-network-fpga·unlv-si-harris-drelu-fpga-mlp 모두 rechecked_at 없음) + 새로움 2(MLP 추론 AXI-Lite IP 패키지 카탈로그 없음, Q4.4+D-ReLU+BRAM 조합 없음) + 적합성 2(libfpga 단일 뉴런 832LUT 근거 있으나 2층 2000~4000LUT 실측 없음, BRAM 추정 미검증) + 완결성 2(MLP 2층+AXI4-Lite 슬레이브+BRAM 가중치+MNIST 추론 TB 범위 명확) = 6점 → vetted. 보강: libfpga-fpga-neuron·erwanregy-neural-network-fpga·unlv-si-harris-drelu-fpga-mlp rechecked_at 추가, LUT 추정 yosys 검증.

## I-135 Basys3 D-ReLU vs Sigmoid 면적 비교 검증 패키지 (T2)
- 상태: vetted
- 요약: 내 판단: UNLV 논문(unlv-si-harris-drelu-fpga-mlp)에서 보고한 D-ReLU 24~41% 면적 감소를 Basys3에서 재현한다. 같은 뉴런 구조에 D-ReLU와 sigmoid(LUT 테이블)를 각각 합성해 LUT/FF 사용량을 Vivado/yosys 추정으로 비교하고, 논문 결과를 독립 검증한다.
- 조합: [D-ReLU, sigmoid-LUT, Q4.4, 비교 합성 TB]
- 근거: [unlv-si-harris-drelu-fpga-mlp, libfpga-fpga-neuron]
- 새로움의 근거: 카탈로그에 활성화 함수 면적 비교 패키지 없음. 논문 결과를 하네스 CI(yosys)로 독립 재현하는 경우도 없다.
- Basys3 적합성의 근거: 내 판단: 단일 뉴런 단위 비교는 LUT 수백 수준. yosys synth로 LUT/FF 차이를 비교할 수 있다. 실측은 사람이 Vivado로 확인해야 한다.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-06 /verify(29차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(unlv-si-harris-drelu-fpga-mlp·libfpga-fpga-neuron 모두 rechecked_at 없음) + 새로움 2(활성화 함수 면적 비교 패키지 카탈로그 없음, yosys CI 독립 재현 사례 없음) + 적합성 2(단일 뉴런 LUT 수백 수준 근거 있음, yosys 비교 가능이나 D-ReLU RTL 형태 미확인) + 완결성 2(D-ReLU·sigmoid 각각 RTL 작성+yosys 합성 비교 TB 범위 명확) = 6점 → vetted. 보강: unlv-si-harris-drelu-fpga-mlp·libfpga-fpga-neuron rechecked_at 추가, 근거 카드 1건 더(D-ReLU 사례).

## I-136 Basys3 Q4.4 단일 뉴런 AXI4-Lite 슬레이브 IP (T1 MLP 사다리 1단)
- 상태: vetted
- 요약: 내 판단: libfpga-fpga-neuron의 Q4.4 조합 MAC 커널을 Verilog-2001로 재작성하고 AXI4-Lite 슬레이브로 감싼 단일 뉴런 IP. MicroBlaze V에서 가중치를 레지스터로 쓰고 입력을 넣어 출력을 읽는 1단 패키지. I-134(2층 MLP) 사다리의 T1 기초 단계.
- 조합: [Q4.4, single-neuron, AXI4-Lite, MicroBlaze-V]
- 근거: [libfpga-fpga-neuron, unlv-si-harris-drelu-fpga-mlp]
- 새로움의 근거: 카탈로그에 단일 뉴런 AXI-Lite IP 패키지 없음. I-134 사다리의 첫 단계로 T1 범위 내에서 독립적으로 작동한다.
- Basys3 적합성의 근거: 내 판단: 단일 뉴런 Q4.4 MAC은 LUT 수백 미만. libfpga 사례(832 LUT4, 가중치 포함)가 근거. AXI4-Lite 슬레이브 추가해도 Basys3 20800 LUT 한참 이내.
- 난이도: 2 / 단계: T1
- 심사: 2026-11-06 /verify(29차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(libfpga-fpga-neuron·unlv-si-harris-drelu-fpga-mlp 모두 rechecked_at 없음) + 새로움 2(단일 뉴런 AXI-Lite IP 패키지 카탈로그 없음, I-134 사다리 T1 기초 없음) + 적합성 3(libfpga 사례 832LUT4 직접 근거, AXI4-Lite 슬레이브 추가 약 50LUT 추정, Basys3 20800LUT 한참 이내 명확) + 완결성 2(Q4.4 단일 뉴런+AXI4-Lite 래퍼+TB 293 패턴 재사용 가능, 범위 명확) = 7점 → vetted. 보강: libfpga-fpga-neuron rechecked_at 추가.

## I-137 Basys3 2층 CNN MNIST 추론기 AXI4-Lite 버전 (T4 CNN 사다리)
- 상태: vetted
- 요약: 내 판단: abhi-raval-1910-basys3-cnn-2layer 카드의 흐름을 MicroBlaze V SoC로 이식. UART 대신 AXI4-Lite 슬레이브로 이미지 픽셀 스트림을 받고, 가중치를 AXI-Lite 레지스터 맵에서 로드하며, 추론 완료 인터럽트를 MicroBlaze V에 보낸다. 출력은 AXI-Lite 레지스터에서 소프트웨어가 읽는다.
- 조합: [conv_engine, pool_engine, fc_engine, AXI4-Lite, MicroBlaze-V, BRAM-weight]
- 근거: [abhi-raval-1910-basys3-cnn-2layer, mo-ah-al11505-cnn-convolution-accelerator]
- 새로움의 근거: abhi-raval 카드는 UART 하드와이어드. AXI-Lite SoC 버전은 카탈로그에 없음. kang-yang AoCStream과 달리 소스 제공 모델.
- Basys3 적합성의 근거: 내 판단: abhi-raval 프로젝트가 이미 XC7A35T에서 동작 확인. AXI-Lite 래퍼 추가는 LUT 수백 수준 증가. 가중치 BRAM 소요량 abhi-raval 기준에서 추정 가능.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-06 /verify(29차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(abhi-raval-1910-basys3-cnn-2layer·mo-ah-al11505-cnn-convolution-accelerator 모두 rechecked_at 없음) + 새로움 2(2층 CNN MNIST AXI-Lite SoC 버전 카탈로그 없음, UART→AXI-Lite 이식 사례 없음) + 적합성 2(abhi-raval XC7A35T 동작 확인 근거 있음, 가중치 BRAM 소요량 미확인) + 완결성 2(conv_engine+pool_engine+fc_engine+AXI4-Lite 래퍼+인터럽트+TB 범위 명확) = 6점 → vetted. 보강: abhi-raval·mo-ah-al11505 rechecked_at 추가, 가중치 BRAM 소요량 확인.

## I-138 라인 버퍼 스트리밍 3×3 Conv IP — 외부 메모리 불필요 (T3 CNN 사다리 기초)
- 상태: vetted
- 요약: 내 판단: mo-ah-al11505 카드의 3×3 슬라이딩 윈도우 RTL을 Basys3용 Verilog-2001로 재작성하고 AXI4-Stream 인터페이스를 붙인다. kang-yang AoCStream 논문의 no-DRAM 스트리밍 원리를 소규모 적용: 단일 채널 28×28 입력 → 26×26 valid 출력을 BRAM 라인 버퍼 2행으로 처리. MicroBlaze V가 AXI4-Lite로 커널 계수를 설정하고 AXI4-Stream으로 픽셀을 공급.
- 조합: [line-buffer, sliding-window, AXI4-Stream, AXI4-Lite, Basys3-BRAM]
- 근거: [mo-ah-al11505-cnn-convolution-accelerator, kang-yang-2023-aocstream-sensors]
- 새로움의 근거: 카탈로그에 AXI4-Stream 인터페이스 conv 프리미티브 없음. kang-yang 아키텍처를 Basys3 소규모로 구현한 사례도 없다.
- Basys3 적합성의 근거: 내 판단: 단일 채널 3×3 conv 라인 버퍼는 2×(28+2)×8b ≈ 60 B BRAM. XC7A35T 225 KB 내에서 여러 채널 병렬 가능. mo-ah-al11505가 Zynq(동일 Artix-7 패브릭)에서 검증된 근거.
- 난이도: 3 / 단계: T3
- 심사: 2026-11-06 /verify(29차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(mo-ah-al11505-cnn-convolution-accelerator·kang-yang-2023-aocstream-sensors 모두 rechecked_at 없음) + 새로움 2(AXI4-Stream 인터페이스 conv 프리미티브 카탈로그 없음, Basys3 소규모 AoCStream 사례 없음) + 적합성 2(mo-ah-al11505 Artix-7 패브릭 검증 근거 있음, AXI4-Stream 인터페이스 범위 추가 정의 필요) + 완결성 2(라인 버퍼 2행+슬라이딩 윈도우+AXI4-Stream+AXI4-Lite 계수 설정+TB 범위 명확, 단 AXI4-Stream 버스 너비 미확정) = 6점 → vetted. 보강: mo-ah-al11505·kang-yang rechecked_at 추가, AXI4-Stream 인터페이스 비트폭 확정.

## I-139 AoCStream 논문 재현: Basys3 채널 ≤8 2레이어 스트리밍 CNN (T4)
- 상태: vetted
- 요약: 내 판단: kang-yang 2023 AoCStream 아키텍처를 Basys3 제약(채널 ≤8, BRAM ≤225 KB)에 맞게 소형화하여 자체 RTL로 구현. 레이어 간 라인 버퍼를 BRAM으로, 가중치를 ROM으로 구성. 1→8→16 채널, 28×28 입력, MaxPool 포함 2레이어 구조. 논문이 XC7K325T에서 87.5% 프루닝을 요구한 것보다 작은 규모로 Basys3에 맞춘다.
- 조합: [AoCStream-arch, line-buffer-streaming, no-DRAM, 2-layer-CNN, Basys3-BRAM]
- 근거: [kang-yang-2023-aocstream-sensors, abhi-raval-1910-basys3-cnn-2layer, mo-ah-al11505-cnn-convolution-accelerator]
- 새로움의 근거: AoCStream을 Basys3 XC7A35T에 소형화 적용한 구현 없음. 카탈로그 CNN 카드 중 완전한 자체 RTL 패키지도 없다.
- Basys3 적합성의 근거: 내 판단: 채널 ≤8 가정 시 레이어 1 라인 버퍼 2×28×8×8b ≈ 448 B, 레이어 2 2×14×16×8b ≈ 448 B, 가중치 ROM 1×8×3×3×8b+8×16×3×3×8b ≈ 10 KB 추정 → 합계 약 15 KB 미만, XC7A35T 225 KB 내.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-06 /verify(29차), 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(kang-yang-2023-aocstream-sensors·abhi-raval-1910-basys3-cnn-2layer·mo-ah-al11505-cnn-convolution-accelerator 모두 rechecked_at 없음) + 새로움 2(AoCStream Basys3 소형화 구현 없음, 완전한 자체 RTL CNN 패키지 없음) + 적합성 2(BRAM 15KB 추정 근거 있으나 채널 채널 ≤8 소형화 타당성 복잡도 높음, 실측 없음) + 완결성 1(소형화 채널 수·레이어 구조·정확도 목표 추가 정의 필요, RTL 구조 미확정) = 5점 → vetted. 보강: 소형화 범위 확정(채널 수, 정확도 목표, AXI 인터페이스 종류), kang-yang-2023-aocstream-sensors rechecked_at 추가.

## I-140 LUT-only 조합 활성화 함수 모듈: tanh_7_4·ReLU (T4, S4 제약 역전)
- 상태: vetted
- 요약: 내 판단: BRAM이나 DSP48 없이 순수 LUT 조합 로직만으로 tanh, ReLU 등을 구현. arXiv 1810.08650 Karnaugh map sum-of-products 접근법을 Basys3 XC7A35T에 이식. BRAM 없는 Basys3 추론 파이프라인에서 활성화 함수 슬롯을 작은 LUT 묶음으로 대체하는 S4 제약 역전 사례.
- 조합: [activation-function, LUT-only, no-BRAM, no-DSP, fixed-point, MLP]
- 근거: [arxiv-1810-08650-activation-dse, adityapusalkar-fpga-neural-network]
- 새로움의 근거: 카탈로그에 LUT-only 조합 활성화 함수 모듈 없음. ROM/BRAM-based 접근을 쓴 카드와 대비되는 BRAM-free 대안.
- Basys3 적합성의 근거: 내 판단: tanh_7_4(4비트 입력→7비트 출력) 기준 Karnaugh map SOP 로직은 LUT 수십 개 이내. XC7A35T 20800 LUT 중 소수만 소비 추정.
- 난이도: 2 / 단계: T4
- 심사: 2026-11-06 /verify(30차), raw→vetted 첫 심사(§14.2 표준). 근거 0(arxiv-1810-08650·adityapusalkar 모두 rechecked_at 없음) + 새로움 2(LUT-only 조합 활성화 함수 카탈로그 없음) + 적합성 2(tanh_7_4 SOP LUT 수십 개 이내 추정; Basys3 20800 LUT 여유 있으나 카드 L3 근거 미확인) + 완결성 2(ReLU/tanh_7_4 모듈+TB 작성 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: arxiv-1810-08650·adityapusalkar rechecked_at 취득 필요.
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 8. 근거 2(arxiv-1810-08650-activation-dse·adityapusalkar-fpga-neural-network 카드 2건, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 8점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-141 Twofold LUT 기반 초소형 tanh/sigmoid 모듈 Basys3 포팅 (T4, S1+S4)
- 상태: vetted
- 심사: 2026-11-06 /verify(30차), raw→vetted 첫 심사(§14.2 표준). 근거 0(xie-2020-tvlsi·adityapusalkar 모두 rechecked_at 없음) + 새로움 2(Twofold LUT d-LUT+e-LUT 조합 활성화 함수 카탈로그 없음) + 적합성 3(d-LUT 256×8b+e-LUT 256×4b ≈ 3 KB, XC7A35T 225 KB BRAM 내; 39.721 ns 지연 4사이클 파이프라인 가능) + 완결성 2(tanh Twofold LUT 모듈+TB 작성 범위 명확, iverilog CI 가능) = 7점 → vetted. 보강: xie-2020-tvlsi·adityapusalkar rechecked_at 취득 필요.
- 요약: 내 판단: Xie 2020 IEEE TVLSI의 d-LUT(근사값)+e-LUT(오차 보정) Twofold LUT 아키텍처를 Basys3 BRAM 2개 소용량으로 구현. 단일 대형 LUT 대비 94.44% 면적 절감. MCU 소프트웨어 sigmoid/tanh 테이블 아이디어를 하드웨어 Twofold LUT로 이식하는 S1 접근이면서, 적은 BRAM으로 고정밀도를 달성하는 S4 사례.
- 조합: [activation-function, Twofold-LUT, BRAM-dual, fixed-point, tanh, sigmoid]
- 근거: [xie-2020-tvlsi-twofold-lut-tanh, adityapusalkar-fpga-neural-network]
- 새로움의 근거: 카탈로그에 Twofold LUT(d-LUT+e-LUT 조합) 활성화 함수 구현 없음. 단순 ROM_y 또는 CORDIC과 다른 압축 방식.
- Basys3 적합성의 근거: 내 판단: tanh 8비트 입력 기준 d-LUT 256×8b + e-LUT 256×4b ≈ 3 KB, XC7A35T 225 KB BRAM 내. 지연 39.721 ns는 Basys3 100 MHz 클럭(10 ns 주기)에서 4사이클 파이프라인으로 처리 가능.
- 난이도: 3 / 단계: T4
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 9. 근거 2(xie-2020-tvlsi-twofold-lut-tanh·adityapusalkar-fpga-neural-network 카드 2건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 9점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-142 활성화 함수 하드웨어 3단계 비교 테스트벤치 묶음 (T4, S7 난이도 사다리)
- 상태: vetted
- 심사: 2026-11-06 /verify(30차), raw→vetted 첫 심사(§14.2 표준). 근거 0(arxiv-1810-08650·xie-2020-tvlsi·unlv-si-harris-drelu-fpga-mlp 모두 rechecked_at 없음) + 새로움 2(복수 활성화 함수 통일 비트폭+TB 비교 패키지 카탈로그 없음) + 적합성 3(단계 1 LUT<10, 단계 2 ≤1 BRAM, 단계 3 ≤1 BRAM+∆LUT — 모두 Basys3 XC7A35T 범위 내 명확) + 완결성 2(3단계 비교 범위 명확, iverilog CI 가능) = 7점 → vetted. 보강: 근거 카드 rechecked_at 취득 필요.
- 요약: 내 판단: ReLU(단순 조합) → sigmoid(단일 ROM) → tanh(Twofold LUT) 세 단계로 복잡도를 올리며 각 단계의 자원(LUT/BRAM/DSP48)·지연·정확도를 같은 테스트벤치 형식으로 비교. 단계마다 Basys3에 올릴 수 있는 고정소수점 모듈과 iverilog 테스트벤치를 한 패키지로 묶는다.
- 조합: [activation-function, testbench-suite, fixed-point, comparison, ReLU, sigmoid, tanh]
- 근거: [arxiv-1810-08650-activation-dse, xie-2020-tvlsi-twofold-lut-tanh, unlv-si-harris-drelu-fpga-mlp]
- 새로움의 근거: 카탈로그에 복수 활성화 함수를 같은 고정소수점 비트폭으로 통일하고 테스트벤치로 비교한 패키지 없음. S7 난이도 사다리로 T4 범위 내 완결.
- Basys3 적합성의 근거: 내 판단: 단계 1(ReLU) LUT < 10, 단계 2(sigmoid ROM) ≤ 1 BRAM, 단계 3(Twofold tanh) ≤ 1 BRAM+∆LUT — 모두 Basys3 범위 내. 테스트벤치는 iverilog 무설치 도구로 CI에서 돌 수 있다.
- 난이도: 3 / 단계: T4
- 차단조건재심사: 2026-11-07 /verify 31차, 점수 10. 근거 3(arxiv-1810-08650-activation-dse·xie-2020-tvlsi-twofold-lut-tanh·unlv-si-harris-drelu-fpga-mlp 카드 3건, rechecked_at 불문) + 새로움 2 + 적합성 3 + 완결성 2 = 10점 ≥ 7, 그러나 사이클 슬롯 2건 한도소진(I-101·I-103 승격). 다음 사이클에서 ready 승격 가능. WebFetch PROVENANCE_REQUIRED 31차 연속 차단(§14.2 차단 조건 적용).

## I-143 BN Fold 사전 계산 AXI4-Lite IP — scale·shift BRAM 적재, MAC 출력단 직렬 연결 (T4)

- 내 판단: 배치 정규화(BN) 파라미터 γ, β, μ, σ를 모델 적재 시 MicroBlaze V CPU가 사전 계산(`scale=γ/√(σ²+ε)`, `shift=β−γμ/√(σ²+ε)`)해 BRAM에 적재. 추론 단계에서 각 채널 출력에 1 MAC(곱셈+덧셈)만 추가. 별도 BN 블록이 없어지므로 추론 레이턴시와 LUT 절감 가능.
- 조합: [accelerator, BRAM, AXI4-Lite]
- 근거 카드: [mcdanel-2019-full-stack-cnn-bn-folding, khan-2024-bn-hls4ml-uw]
- 근거 URL: [https://arxiv.org/abs/1905.00462, https://people.ece.uw.edu/hauck/publications/BatchNorm.pdf]
- 새로움의 근거: 카탈로그에 BN fold 사전 계산을 AXI4-Lite 슬레이브로 묶은 Basys3 IP 없음. 기존 MLP·CNN 카드들은 모두 BN 블록 미구현.
- Basys3 적합성의 근거: 채널 수 최대 64 → scale·shift 각 64×32비트 = 256바이트. BRAM 1개(1K×32비트) 여유. AXI4-Lite 슬레이브 추가 LUT ~100개 추정. 추론 MAC 추가는 DSP 1개 채널당(내 판단).
- 난이도: 3 / 단계: T4 / 상태: vetted
- 심사: 2026-11-07 /verify 31차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(mcdanel-2019-full-stack-cnn-bn-folding·khan-2024-bn-hls4ml-uw 모두 rechecked_at 없음) + 새로움 2(BN fold를 AXI4-Lite 슬레이브로 묶은 Basys3 IP 카탈로그 없음) + 적합성 2(채널 64 × scale·shift 32비트 = 256바이트 → BRAM 1개, 추정 근거 카드 L2) + 완결성 2(BN fold 사전계산+BRAM 적재+1 MAC 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: mcdanel-2019·khan-2024 rechecked_at 취득 필요.

## I-144 뉴턴-랍슨 역제곱근 LUT 모듈 — Q4.12(16비트), 반복 2회, Basys3 BRAM 1개 (T4)

- 내 판단: LayerNorm 하드웨어의 핵심인 1/σ 계산을 뉴턴-랍슨 반복으로 구현. 초기 추정값 LUT는 BRAM 1개(256~512 엔트리, Q4.12 16비트). 2회 반복으로 정밀도 ~1 ULP. Kim 2025 논문의 Q5.26 대신 Q4.12(16비트 총폭)로 비트 폭 축소해 Artix-7 LUT 예산 내 가능.
- 조합: [accelerator, BRAM, fixed-point]
- 근거 카드: [kim-2025-layernorm-fpga, khan-2024-bn-hls4ml-uw]
- 근거 URL: [https://www.mdpi.com/2079-9292/14/12/2337, https://people.ece.uw.edu/hauck/publications/BatchNorm.pdf]
- 새로움의 근거: 카탈로그에 역제곱근 LUT + 뉴턴-랍슨 반복을 조합한 Basys3 모듈 없음. 기존 고정소수점 Q포맷 카드들은 덧셈·곱셈만 다룸.
- Basys3 적합성의 근거: BRAM 1개(256×16비트 LUT) + Q4.12 16비트 2회 반복 = 추정 ~400 LUT. XC7A35T 여유. 역제곱근 LUT 생성은 Python/C로 오프라인 가능.
- 난이도: 3 / 단계: T4 / 상태: vetted
- 심사: 2026-11-07 /verify 31차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(kim-2025-layernorm-fpga·khan-2024-bn-hls4ml-uw 모두 rechecked_at 없음) + 새로움 2(역제곱근 LUT + 뉴턴-랍슨 반복 조합 Basys3 모듈 카탈로그 없음) + 적합성 2(BRAM 1개(256×16비트 LUT)+~400 LUT 추정; 근거 카드 L2이므로 감점) + 완결성 2(역제곱근 LUT 모듈+TB 작성 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: kim-2025·khan-2024 rechecked_at 취득 필요.

## I-145 RMS-Norm 하드웨어 모듈 — LLaMA 호환, 평균 제거 불필요, Basys3 LUT 예산 내 (T4, S1 이식)

- 내 판단: RMSNorm(Root Mean Square Normalization)은 LayerNorm에서 평균 μ 계산을 제거한 간소화 버전. 각 채널 x를 `x/RMS(x)`로 나눈 뒤 scale(γ)만 곱함. LLaMA·GPT-NeoX 등 최신 경량 LLM에서 사용. 나눗셈은 뉴턴-랍슨 역수 계산으로 대체 가능. S1 이식: Arduino/MCU의 소프트웨어 RMSNorm을 FPGA 하드웨어로 이식하면 추론 속도 비교 가능.
- 조합: [accelerator, fixed-point, BRAM]
- 근거 카드: [kim-2025-layernorm-fpga, mcdanel-2019-full-stack-cnn-bn-folding]
- 근거 URL: [https://www.mdpi.com/2079-9292/14/12/2337, https://arxiv.org/abs/1905.00462]
- 새로움의 근거: 카탈로그에 RMSNorm FPGA 구현 없음. LN보다 Basys3 자원 부담 낮아(μ 계산 불필요 → 가산기 절감) 소형 모듈 패키지 적합.
- Basys3 적합성의 근거: RMS 계산은 제곱합+나눗셈 없이 역제곱근 LUT로 대체 가능. Artix-7 DSP 최소 사용(추정 1 DSP/채널). BRAM 1개 LUT 적재.
- 난이도: 3 / 단계: T4 / 상태: vetted
- 심사: 2026-11-07 /verify 31차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(kim-2025-layernorm-fpga·mcdanel-2019-full-stack-cnn-bn-folding 모두 rechecked_at 없음) + 새로움 2(RMSNorm FPGA 구현 카탈로그 없음) + 적합성 2(역제곱근 LUT로 대체 가능, DSP 최소 사용 추정; 근거 카드 L2이므로 감점) + 완결성 2(RMSNorm 모듈+TB 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: kim-2025·mcdanel-2019 rechecked_at 취득 필요.

## I-146 단순 RNN 셀 타임스텝 루프 — 이진 덧셈기 수준부터 시작하는 최소 순환 네트워크 (T3, S7 사다리 1단계)

- 내 판단: S7 난이도 사다리의 첫 단계. h_t = tanh(W_hh·h_{t-1} + W_hx·x_t + b) 한 줄 계산을 Verilog 단일 MAC + LUT tanh로 구현. LSTM보다 훨씬 단순해 순환 하드웨어 개념(상태 레지스터, 타임스텝 FSM, 고정소수점 MAC) 학습용으로 최적. Basys3에서 LUT 200개 이내 추정.
- 조합: [fixed-point, BRAM, accelerator]
- 근거 카드: [chang-2015-rnn-fpga, ahirsharan-lstm]
- 근거 URL: [https://arxiv.org/abs/1511.05552, https://github.com/ahirsharan/LSTM]
- 새로움의 근거: 카탈로그에 단순 RNN(LSTM 없는 순수 h_t 순환 셀) FPGA 구현 카드 없음. LSTM 사다리의 필수 사전 단계이므로 독립 패키지 가치 있음.
- Basys3 적합성의 근거: MAC 1개 + 상태 레지스터 1개 + LUT tanh(256-entry BRAM). 추정 LUT < 200, BRAM 1, DSP 1. XC7A35T 여유 충분.
- 난이도: 2 / 단계: T3 / 상태: vetted
- 심사: 2026-11-07 /verify 31차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(chang-2015-rnn-fpga·ahirsharan-lstm 모두 rechecked_at 없음) + 새로움 2(단순 RNN 순환 셀 FPGA 카탈로그 없음) + 적합성 2(MAC 1개+상태 레지스터+LUT tanh, LUT<200·BRAM1·DSP1 추정; 근거 카드 chang은 L3이나 ahirsharan은 L2) + 완결성 2(단일 셀 MAC+FSM+LUT tanh 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: chang-2015·ahirsharan rechecked_at 취득 필요.

## I-147 LSTM 셀 단일 타임스텝 가속기 — 4+1 병렬 ALU, Q8.8, Basys3 AXI4-Lite 슬레이브 (T4, S7 사다리 2단계)

- 내 판단: S7 사다리 2단계. 단순 RNN(I-146) 위에 forget/input/candidate/output 4게이트 + h_t ALU를 추가. Qian 2023의 4+1 병렬 ALU 아키텍처를 Verilog-2001로 재작성, Q8.8 고정소수점, sigmoid/tanh는 13-구간 PLA(Chang 2015 방식). AXI4-Lite 슬레이브로 감싸 MicroBlaze V에서 가중치 로드. 단일 타임스텝 처리 후 FSM이 c_t/h_t 레지스터를 다음 호출로 전달.
- 조합: [fixed-point, BRAM, accelerator, AXI4-Lite]
- 근거 카드: [chang-2015-rnn-fpga, ahirsharan-lstm, qian-2023-lstm-spartan7]
- 근거 URL: [https://arxiv.org/abs/1511.05552, https://arxiv.org/abs/2310.16842, https://github.com/ahirsharan/LSTM]
- 새로움의 근거: 카탈로그에 Basys3 대상 LSTM 셀 AXI4-Lite 슬레이브 카드 없음. Chang 2015 PLA + Qian 2023 병렬 ALU 조합은 기존 카드와 다른 조합.
- Basys3 적합성의 근거: Qian 2023이 LUT 400개짜리 XC7S15에서 동작 → Basys3(20,800 LUT)에 여유. 추정 LUT 1,500, BRAM 2(가중치 2×), DSP 4(게이트당 1). free_slots 1슬롯(64KB).
- 난이도: 3 / 단계: T4 / 상태: vetted
- 심사: 2026-11-07 /verify 31차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(chang-2015-rnn-fpga·ahirsharan-lstm·qian-2023-lstm-spartan7 모두 rechecked_at 없음) + 새로움 2(Basys3 LSTM AXI4-Lite 슬레이브 카탈로그 없음; Chang 2015 PLA+Qian 2023 4+1 ALU 조합 신규) + 적합성 2(Qian XC7S15(1,296 LUT)에서 LUT 400 동작 → Basys3 20,800 LUT 여유; 추정 LUT 1,500·BRAM 2·DSP 4; 근거 카드 모두 L3이나 Basys3 직접 합성 미확인) + 완결성 2(4+1 ALU+AXI4-Lite 슬레이브 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 취득 필요.

## I-148 타임스텝 루프 LSTM 시퀀스 추론 — 가속기 위에 FSM 루프 추가, 멀티 스텝 시계열 처리 (T4, S7 사다리 3단계)

- 내 판단: S7 사다리 3단계. LSTM 셀 IP(I-147) 위에 타임스텝 루프 컨트롤러(FSM)를 추가. 입력 시퀀스 x_0…x_{T-1}을 BRAM에서 읽고, 셀을 T회 호출, 최종 h_T를 분류 레이어(단순 선형)로 넘기는 완결 추론 경로 구현. MicroBlaze V 소프트웨어와 협업: 가중치 사전 적재 → CTRL_START 신호 → STATUS_DONE 폴링 → 결과 읽기. 시계열 이상 감지(온도·진동 센서 10 타임스텝) 데모 가능.
- 조합: [fixed-point, BRAM, accelerator, AXI4-Lite, sensor]
- 근거 카드: [chang-2015-rnn-fpga, qian-2023-lstm-spartan7, ahirsharan-lstm]
- 근거 URL: [https://arxiv.org/abs/1511.05552, https://arxiv.org/abs/2310.16842]
- 새로움의 근거: 카탈로그에 Basys3 멀티-타임스텝 LSTM 시퀀스 추론 패키지 없음. I-147 단일 셀 위에 루프 컨트롤러를 얹는 조합은 사다리 완성이며 독립 패키지.
- Basys3 적합성의 근거: I-147 대비 추가 자원은 루프 FSM(LUT 100개 이하) + 입력 시퀀스 BRAM(T×I 크기, T=10 I=4 → 40 entries, 최소). XC7A35T 여유 충분.
- 난이도: 4 / 단계: T4 / 상태: vetted
- 심사: 2026-11-07 /verify 31차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(chang-2015-rnn-fpga·qian-2023-lstm-spartan7·ahirsharan-lstm 모두 rechecked_at 없음) + 새로움 2(Basys3 멀티-타임스텝 LSTM 시퀀스 추론 패키지 카탈로그 없음) + 적합성 2(I-147 대비 루프 FSM LUT<100+입력 BRAM 추가만 필요, XC7A35T 여유; 근거 카드 모두 L3이나 Basys3 직접 합성 미확인) + 완결성 2(루프 FSM+BRAM 입력버퍼+선형분류레이어 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 취득 필요.

## I-149 GRU 셀 AXI4-Lite 가속기 IP — 2게이트 구조, Basys3 DSP48·BRAM 절약 (T4, S1 이식)
- 상태: vetted
- 요약: 내 판단: GRU의 update/reset 2게이트 구조(LSTM 4게이트 대비 MVM 3회 vs 4회)를 이용해 LSTM보다 ~25% 적은 DSP48·LUT로 Basys3에서 동작하는 추론 가속기를 구현한다. MicroBlaze V가 AXI4-Lite로 가중치를 적재하고 타임스텝 완료 인터럽트를 받는다.
- 조합: [GRU-cell, AXI4-Lite, DSP48, BRAM-weight]
- 근거: [li-2019-ernn-gru-lstm, khoda-2023-hls4ml-gru-lstm]
- 새로움의 근거: 카탈로그에 GRU 전용 Basys3 AXI4-Lite 가속기 카드가 없음. LSTM 카드(qian-2023-lstm-spartan7, I-147)는 있으나 GRU 비교 구현은 없음.
- Basys3 적합성의 근거: li-2019 자원표(GRU FFT8 Virtex-7: DSP 62.1%, BRAM 88.2%)는 고성능 보드 기준이므로 Basys3 XC7A35T(90 DSP, 225KB BRAM)에서 소형 모델(은닉 8~16 노드, 12비트 고정소수점)이면 단일 AXI 슬롯(free_slots 1칸)에 맞출 수 있다. hls4ml Reuse factor를 높이면 직렬화 가능.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-07 /verify 32차, 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(li-2019-ernn-gru-lstm·khoda-2023-hls4ml-gru-lstm 모두 rechecked_at 없음) + 새로움 2(GRU 전용 Basys3 AXI-Lite 가속기 카드·패키지 없음) + 적합성 2(은닉 8~16 노드 소형 모델 가능 추정, 고성능 보드 기준 근거이므로 Basys3 실측 없음) + 완결성 1(AXI4-Lite 래퍼 범위 명확하나 직렬화 방법·DSP48 사용량 미확인) = 5점 → vetted. 보강: 근거 카드 rechecked_at 추가, Basys3 소형 GRU 자원 추정(yosys).

## I-150 GRU·LSTM 비교 테스트벤치 모듈 — 같은 가중치로 순전파 대조, 오차 ≤1 ULP 검증 (T3, S4 제약 역전)
- 상태: vetted
- 요약: 내 판단: Verilog-2001 고정소수점 GRU 셀과 LSTM 셀을 같은 가중치·입력으로 나란히 돌려 출력 오차를 1 ULP 이하로 검증하는 자체 점검형 테스트벤치. GRU가 LSTM보다 타임스텝당 사이클이 적음을 측정하고 PASS/FAIL 출력.
- 조합: [GRU-cell, LSTM-cell, fixed-point-MAC, Verilog-testbench]
- 근거: [li-2019-ernn-gru-lstm, khoda-2023-hls4ml-gru-lstm]
- 새로움의 근거: 카탈로그에 GRU/LSTM 비교 테스트벤치 카드가 없음. 단독 LSTM 테스트벤치(qian-2023)는 있으나 GRU와의 직접 비교는 없음.
- Basys3 적합성의 근거: 테스트벤치는 보드 없이 iverilog/verilator로 돌 수 있어 CI 검증에 적합. GRU/LSTM 셀 각 400줄 이내, 가중치는 소수 파라미터(은닉 4~8 노드).
- 난이도: 2 / 단계: T3
- 심사: 2026-11-07 /verify 32차, 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(li-2019-ernn-gru-lstm·khoda-2023-hls4ml-gru-lstm 모두 rechecked_at 없음) + 새로움 2(GRU/LSTM 직접 비교 TB 카탈로그 없음) + 적합성 3(보드 없이 iverilog/verilator로 CI 검증 가능, 은닉 4~8 노드 소형 셀) + 완결성 2(GRU 셀·LSTM 셀 각 RTL + 비교 TB 범위 명확, PASS/FAIL 출력 정의) = 7점 → vetted. 보강: 근거 카드 rechecked_at 추가.

## I-151 초소형 GRU 추론 엔진 — 은닉 8노드, Basys3 BRAM 가중치 적재, 400줄 Verilog-2001 (T4, S4 제약 역전)
- 상태: vetted
- 요약: 내 판단: Basys3 제약(BRAM·DSP 한계)을 역전시켜, 고성능 보드 대비 90% 이상 작은 모델(은닉 8노드, 12비트 고정소수점, 1 타임스텝 직렬 처리)을 순수 Verilog-2001 400줄 이내로 구현. hls4ml 대신 직접 RTL로 작성해 Vivado IP로 패키징 가능.
- 조합: [GRU-cell, BRAM-weight, DSP48-MAC, Verilog-2001]
- 근거: [khoda-2023-hls4ml-gru-lstm, chae-2022-gru-de1soc]
- 새로움의 근거: S4 전략(제약 역전): 고성능 보드 대신 Basys3 최소 자원에서 돌아가는 가장 작은 GRU를 명시적 목표로 삼는 카드 없음. 기존 카드들은 모두 Basys3 이식 불가 대형 보드.
- Basys3 적합성의 근거: 은닉 8노드 GRU: 가중치 수 = 3*8*(8+1) = 216개 → 12비트×216 = 3.2KB, Basys3 BRAM 2블록 이내. DSP48 사용량 ≤10개(내 계산). AXI4-Lite 슬레이브 래퍼 추가 시 MicroBlaze V free_slots 1칸.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-07 /verify 32차, 첫 raw→vetted 심사(차단조건재심사 불적용. §14.2). 근거 0(khoda-2023-hls4ml-gru-lstm·chae-2022-gru-de1soc 모두 rechecked_at 없음) + 새로움 2(Basys3 최소 자원 GRU를 명시적 목표로 삼는 패키지 없음) + 적합성 3(은닉 8노드 가중치 3.2KB·BRAM 2블록·DSP48 ≤10개 추정, Basys3 XC7A35T 범위 내) + 완결성 2(은닉 8노드+BRAM 가중치+직렬 처리+400줄 이내 범위 명확) = 7점 → vetted. 보강: 근거 카드 rechecked_at 추가, DSP48 추정 yosys 검증.

## I-152 소형 단일 헤드 어텐션 AXI4-Lite IP — 로그-합-지수 Softmax + d_k=16 내적 (T4, S3 빈틈)
- 상태: vetted
- 요약: 내 판단: Basys3 XC7A35T에서 헤드 1개(d_k=16, INT8/Q1.7, 직렬 처리)의 스케일된 닷-프로덕트 어텐션을 구현한다. Wang 2020의 로그-합-지수 4단계 Softmax 파이프라인(최댓값 추출→선형 exp→누적→선형 ln 나눗셈)을 d_k=16 단일 행으로 축소 적용하고, 8×8 MAC 어레이로 QK^T·V 행렬 곱을 처리. MicroBlaze V가 AXI4-Lite로 Q/K/V 벡터를 적재하고 어텐션 출력을 읽는다.
- 조합: [softmax-fsm, MAC-array, BRAM-weight, AXI4-Lite]
- 근거: [wang-2020-mha-fpga-accelerator, richielee-2025-tiled-matmul-attention-kv260]
- 새로움의 근거: 카탈로그에 Basys3급(XC7A35T) 단일 헤드 어텐션 AXI4-Lite IP 카드가 없음. wang-2020은 xcvu13p 대형 보드 전용, richielee-2025는 KV260+Softmax 미구현으로 직접 사용 불가. 소형 헤드(d_k=16)×1헤드 직렬화로 LUT 한도 내 구현을 처음 시도.
- Basys3 적합성의 근거: wang-2020 Softmax 단독 LUT 21,190/FF 32,623은 xcvu13p 기준이므로 d_k=16 단일 행 직렬 처리로 LUT ≤2,000 목표. INT8 MAC×16 → DSP48E1 ≤8개(내 계산). BRAM 사용 최소화(Q/K/V 각 16×8비트=16B). AXI4-Lite free_slots 1칸(64KB).
- 난이도: 4 / 단계: T4
- 심사: 2026-11-07 /verify 33차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(wang-2020-mha-fpga-accelerator·richielee-2025-tiled-matmul-attention-kv260 모두 rechecked_at 없음) + 새로움 2(Basys3급 단일 헤드 어텐션 AXI4-Lite IP 카드·패키지 없음) + 적합성 2(d_k=16 직렬 처리로 LUT≤2,000 목표; xcvu13p 기준 추정이라 Basys3 직접 합성 미확인) + 완결성 2(MAC 어레이+소프트맥스 FSM+AXI4-Lite 래퍼 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 추가, Basys3 LUT/DSP 추정 yosys 검증 필요.

## I-153 구간 선형 exp 근사 FSM — Basys3 소형 Softmax LUT + 가산기만 사용 (T3, S5 비정형)
- 상태: vetted
- 요약: 내 판단: FTRANS(ftrans-2020-transformer-fpga-piecewise-softmax)의 구간 선형 exp 근사 아이디어를 d_k=16 소형 Softmax에 적용한다. 입력 범위 −8~0으로 편이한 뒤 32~64 항목 LUT + 가산기만으로 exp를 근사. 별도 Verilog-2001 FSM 모듈(< 150줄)로 구현해 Basys3 어텐션 소형 IP의 Softmax 블록으로 활용.
- 조합: [softmax-fsm, piecewise-linear-exp, LUT-ROM, Verilog-2001]
- 근거: [ftrans-2020-transformer-fpga-piecewise-softmax, wang-2020-mha-fpga-accelerator]
- 새로움의 근거: 카탈로그에 Basys3 XC7A35T에서 구간 선형 exp만을 단독 FSM으로 구현한 카드가 없음. ftrans-2020은 VCU118 전용으로 직접 이식 불가. 150줄 이하 단독 IP로 분리해 재사용 가능 라이브러리 블록 추가.
- Basys3 적합성의 근거: 32항목 LUT(8비트 주소→16비트 계수) = 512바이트 → BRAM 1/4블록. 가산기·비교기만 사용(DSP 불필요). 직렬 처리 d_k=16 → 16사이클. CI에서 iverilog/verilator 검증 가능(S1 목표). free_slots 불필요(library/rtl/ 추가).
- 난이도: 2 / 단계: T3
- 심사: 2026-11-07 /verify 33차, raw→vetted 첫 심사(§14.2 표준, 차단조건재심사 불적용). 근거 0(ftrans-2020-transformer-fpga-piecewise-softmax·wang-2020-mha-fpga-accelerator 모두 rechecked_at 없음) + 새로움 2(Basys3 구간 선형 exp 단독 FSM 카드·패키지 없음) + 적합성 2(32항목 LUT=512B·BRAM 1/4블록·DSP 불필요 추정 명확) + 완결성 2(150줄 이하 FSM·library/rtl/ 추가로 범위 명확, iverilog CI 가능) = 6점 → vetted. 보강: 근거 카드 rechecked_at 추가, 선형 exp 오차 한계 명시 필요.

---

## I-134 Basys3 소형 트랜스포머 추론 가속기 AXI IP (d_model=16~32, 1헤드, 4~8비트 혼합 정밀도)

내 판단: XC7S15(8K LUT)에서 d_model=40까지 단일 인코더 블록이 동작한다면, Basys3(33K LUT, 약 4배)에서는 d_model=16~32 구성이 LUT 약 10~20%만 사용해 여유 있게 구현 가능. 단일 인코더(1헤드 MHA + 1층 FFN)를 AXI4-Lite 슬레이브 IP로 감싸 MicroBlaze V NPU IP로 연결. 성분별 비트폭(4/6/8비트)을 AXI 레지스터로 프로그래밍 가능하게 설계.

- id: I-134
- 조합: [single-encoder-transformer, MHA-1head, FFN-1layer, AXI4-Lite, MicroBlaze-V-NPU]
- 근거 카드: [[arxiv-2505-17662-tinyformer4ts]], [[arxiv-2410-03294-mixprecq-ts-fpga]]
- 근거 URL: https://arxiv.org/abs/2505.17662, https://arxiv.org/abs/2410.03294
- 새로움 근거: 카탈로그에 d_model≤32 단일 인코더를 AXI4-Lite 슬레이브로 감싼 MicroBlaze V NPU IP 카드가 없음. TinyTransformer4TS(arxiv-2505-17662)는 XC7S15 전용 XDC이며 AXI 인터페이스 없음. S4 제약 역전: 소형 d_model을 제약이 아닌 적합성으로 활용.
- Basys3 적합성 근거: d_model=32, 1헤드, 4비트 → XC7S15 기준 LUT ~35% → Basys3(4배) 기준 ~8-9%. BRAM: 가중치 BRAM 2~3개 범위(d_model=32, 4비트). DSP: 삼진 가중치로 0 가능(arxiv-2607-03652 참고). 실측 없음. free_slots 1개 배정 제안.
- 난이도: 4
- 단계: T4
- 상태: ready
- 심사: 2026-11-07 /verify 34차, raw→vetted 첫 심사(§14.2 표준). 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(d_model≤32 단일 인코더 AXI4-Lite NPU IP 카드·패키지 없음) + 적합성 2(XC7S15 ~35% → Basys3 ~8-9%, BRAM 2~3블록 추정 명확) + 완결성 2(단일 인코더 FSM+AXI 래퍼+TB 범위 명확, iverilog CI 가능) = 6점 → vetted. 이후 차단조건재심사(PROVENANCE_REQUIRED 34차 연속 차단): 근거 카드 총 수 2(rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 8점 ≥ 7 → ready. 차단조건재심사: 2026-11-07, 점수 8.

---

## I-135 혼합 정밀도 추론 AXI 레지스터 인터페이스 (성분별 4/6/8비트 SW 프로그래밍)

내 판단: arxiv-2410-03294의 10개 성분별 혼합 정밀도(4/6/8비트) 아이디어를 MicroBlaze V AXI4-Lite 레지스터 인터페이스로 구현. 각 성분(입력 양자화·PE 추가·MHA·AddMHA·BN_MHA·FFN·AddFFN·BN_FFN·GAP·출력 역양자화)의 비트폭을 AXI 레지스터에서 소프트웨어로 설정, FSM이 비트폭 설정값을 읽어 동작. d_model≤32로 BRAM 포화 없이 구현.

- id: I-135
- 조합: [mixed-precision-quantization, AXI4-Lite-registers, transformer-10-components, MicroBlaze-V-SW-control]
- 근거 카드: [[arxiv-2410-03294-mixprecq-ts-fpga]]
- 근거 URL: https://arxiv.org/abs/2410.03294
- 새로움 근거: 카탈로그에 성분별 비트폭을 AXI 레지스터에서 소프트웨어로 동적 설정하는 혼합 정밀도 추론 IP 카드가 없음. arxiv-2410-03294는 XC7S15 전용, AXI 인터페이스 없음. S4 제약 역전: d_model=64 BRAM 포화를 d_model≤32로 역전.
- Basys3 적합성 근거: d_model=32, 10 성분 비트폭 각 2비트(4/6/8비트 선택) = AXI 레지스터 10개. XC7S15의 BRAM 100% 포화는 d_model=64 기준 → d_model=32로 절반. Basys3 50 BRAM36으로 여유. 실측 없음.
- 난이도: 4
- 단계: T4
- 상태: vetted
- 심사: 2026-11-07 /verify 34차, raw→vetted 첫 심사(§14.2 표준). 근거 0(arxiv-2410-03294 rechecked_at 없음) + 새로움 2(성분별 비트폭 AXI 레지스터 동적 설정 카드 없음) + 적합성 2(d_model=32, AXI 레지스터 10개, Basys3 BRAM 50블록 여유 추정 명확) + 완결성 2(AXI 레지스터 10개·비트폭 FSM 범위 명확) = 6점 → vetted. 보강: 근거 카드 rechecked_at 추가 필요. 차단조건재심사: 근거 카드 총 수 1 + 새로움 2 + 적합성 2 + 완결성 2 = 7점, ready 한도(2건) 도달로 이번 사이클 보류.

---

## I-136 삼진 가중치 압축 BRAM 모듈 (ternary 2비트 인코딩, DSP-free 비트마스크 MAC)

내 판단: arxiv-2607-03652-eliteformer의 삼진 가중치(−1, 0, +1) 비트마스크 MAC 아이디어를 Basys3 소형 NPU 가중치 메모리에 적용. 가중치를 2비트 인코딩(00=0, 01=+1, 10=−1)으로 BRAM에 압축 저장(압축률 약 1/4), 비트마스크 AND+가산기로 MAC 대체해 DSP 소모 없음. MicroBlaze V AXI4-Lite NPU IP의 가중치 BRAM 모듈로 활용.

- id: I-136
- 조합: [ternary-weights, 2bit-encoding, bitmask-MAC, BRAM-compression, DSP-free, AXI4-Lite-NPU]
- 근거 카드: [[arxiv-2607-03652-eliteformer]]
- 근거 URL: https://arxiv.org/abs/2607.03652
- 새로움 근거: 카탈로그에 Basys3 90 DSP 제약 완화를 위해 삼진 가중치 비트마스크로 DSP 사용 0으로 줄이는 카드·패키지가 없음. EliteFormer는 Versal VCK5000 AI엔진 전용으로 직접 이식 불가. 2비트 인코딩으로 BRAM 사용량 약 1/4 절감 가능. S4 제약 역전: DSP 의존도 제약을 LUT 위주 설계로 역전.
- Basys3 적합성 근거: 2비트 가중치 × d_model=32 × 1층 = 약 2KB → BRAM 1개 미만. 비트마스크 AND+가산기는 LUT 위주, DSP 불필요. 90 DSP를 다른 용도(예: 사용자 가속기)에 여유 확보. 실측 없음.
- 난이도: 3
- 단계: T4
- 상태: used (패키지: mmio-ternary-weight-mac-ip, 2026-11-07, §13.7 무조건 최대한 생성 원칙)
- 심사: 2026-11-07 /verify 34차, raw→vetted 첫 심사(§14.2 표준). 근거 0(arxiv-2607-03652 rechecked_at 없음) + 새로움 2(삼진 가중치 비트마스크 MAC으로 DSP 0, BRAM 1/4 압축 카드 없음) + 적합성 2(2비트 인코딩, 2KB 미만, BRAM 1블록 미만, DSP 불필요 추정 명확) + 완결성 2(비트마스크 AND+가산기 모듈 범위 명확, iverilog CI 가능) = 6점 → vetted. 이후 차단조건재심사(PROVENANCE_REQUIRED 34차 연속 차단): 근거 카드 총 수 1 + 새로움 2 + 적합성 2 + 완결성 2 = 7점 ≥ 7 → ready. 차단조건재심사: 2026-11-07, 점수 7.

---

## I-137 AXI4-Lite NPU IP 1-MAC 최소 슬레이브 (가중치 레지스터·추론 트리거·결과 플래그)

내 판단: ansh07verma-fpga-mini-npu와 axc1271-mini-npu의 INT8 MAC 모듈을 근거로, MicroBlaze V에서 AXI4-Lite로 제어 가능한 최소 1-MAC NPU IP를 직접 설계. 가중치 쌍(A, B)을 AXI 레지스터로 쓰고, 추론 트리거 1비트로 MAC 연산 시작, 결과 레지스터에서 읽는 패턴. cornell-ece5760-2024-conv-accel의 HPS→ARM 소프트웨어 흐름을 MicroBlaze V C 드라이버로 대체하는 개조 경로가 명확함.

- id: I-137
- 조합: [INT8-MAC, AXI4-Lite-slave, weight-register, inference-trigger, result-flag, MicroBlaze-V-driver]
- 근거 카드: [[ansh07verma-fpga-mini-npu]], [[axc1271-mini-npu]], [[cornell-ece5760-2024-conv-accel]]
- 근거 URL: https://github.com/ansh07verma/fpga-mini-npu, https://github.com/AxC1271/mini-NPU
- 새로움 근거: 카탈로그에 1-MAC AXI4-Lite 슬레이브 최소 NPU IP 패키지 없음. 기존 FIR·UART 프레이밍 IP(mmio-fir-q1p15-mac-ip 등)는 신호처리 위주. INT8 추론 MAC을 MicroBlaze V AXI 슬레이브로 감싼 IP는 카탈로그 첫 사례.
- Basys3 적합성 근거: 1-MAC INT8 = 8비트×8비트+16비트 누산, DSP48E1 1개 또는 LUT 위주. 가중치 레지스터 최대 8쌍 × 2바이트 = 16B → BRAM 불필요. free_slots 1개(64KB) 충분. XC7A35T 적합.
- 난이도: 2
- 단계: T4
- 상태: raw

---

## I-138 2D 합성곱 행·열 계수 AXI 로드 + 추론 파이프라인 (3×3 커널, BRAM 가중치)

내 판단: cornell-ece5760-2024-conv-accel의 파라미터화 합성곱 아이디어를 Basys3 BRAM 한계 내로 축소해 3×3 커널 1개 고정, 행·열 계수 9개를 AXI4-Lite 레지스터로 로드하고 라인 버퍼로 슬라이딩 윈도우 합성곱을 수행하는 IP. I-137의 1-MAC을 확장한 단계. 소프트웨어 드라이버(C)는 cornell의 software_design 패턴을 MicroBlaze V Vitis 흐름으로 직접 개조 가능.

- id: I-138
- 조합: [3x3-conv, sliding-window, line-buffer, AXI4-Lite-weight-load, BRAM-kernel, MicroBlaze-V-C-driver]
- 근거 카드: [[cornell-ece5760-2024-conv-accel]], [[ansh07verma-fpga-mini-npu]], [[axc1271-mini-npu]]
- 근거 URL: https://people.ece.cornell.edu/land/courses/ece5760/FinalProjects/s2024/yx623_jz2275_sl2874_NEW/
- 새로움 근거: kwondo99-fpga-vga-photobooth-project는 OV7670→VGA 파이프라인에 집중하며 소프트웨어 가중치 로드 패턴 없음. 3×3 커널 AXI 로드 + 라인 버퍼 합성곱 IP는 카탈로그 미등록.
- Basys3 적합성 근거: 3×3 INT8 커널 = 9B × 1채널 → 가중치 레지스터 9개. 라인 버퍼 3행 × 열 너비 최대 128픽셀 × 8비트 = 384B → BRAM 1개 미만. DSP 1~4개. XC7A35T 가능. 실측 없음.
- 난이도: 3
- 단계: T4
- 상태: raw

---

## I-139 Basys3 1-bit BNN BCNN 횡단보도 감지 → Pmod/VGA 출력 (OV7670 전처리 모듈 재사용)

내 판단: rajmali-22-fpga-zebra-crossing-camera의 BNN BCNN(XC7A35T, LUT 16% · BRAM 38%)이 Basys3와 동일 칩임을 확인. EDGE-Artix-7 커스텀 보드 XDC만 Basys3 XDC로 교체하면 LUT·BRAM 여유가 충분. OV7670을 Pmod 핀으로, VGA를 온보드 커넥터로 연결. 단일 클래스 판별(횡단보도 있음/없음)이므로 출력은 LED + VGA 오버레이. 이 파이프라인 전체가 MicroBlaze V 없이 순수 FSM으로 동작하므로, AXI4-Lite 슬레이브로 래핑 시 T4 캡스톤 첫 번째 자연스러운 엔트리포인트.

- id: I-139
- 조합: [OV7670-SCCB, 8x8-block-avg, RGB565-to-gray, BNN-BCNN-4conv-FC, VGA-overlay, LED-buzzer, Pmod-camera]
- 근거 카드: [[rajmali-22-fpga-zebra-crossing-camera]], [[kwondo99-fpga-vga-photobooth-project]], [[adityapusalkar-fpga-neural-network]]
- 근거 URL: https://github.com/Rajmali-22/fpga-zebra-crossing-camera
- 새로움 근거: 카탈로그에 OV7670+BNN 완전 파이프라인은 rajmali-22만 있으나 그것은 커스텀 보드 전용. Basys3 XDC 이식 + Pmod 핀 배선이 추가 기여. 단순 카메라→VGA 파이프라인(kwondo99)은 BNN 없음.
- Basys3 적합성 근거: rajmali-22 자원 LUT 3,370(16%) · BRAM 19/50(38%) → Basys3(20,800 LUT, 50 BRAM) 충분. OV7670을 JA/JB Pmod(GPIO)로 연결 가능. VGA는 온보드 커넥터. LCD·버저는 제거 또는 Pmod 대체. XDC 전면 교체가 핵심.
- 난이도: 3
- 단계: T4
- 상태: raw

---

## I-140 Basys3 소형 BNN FC + OV7670 카메라 전처리 조합 — 카메라-내장 MNIST-like 분류기

내 판단: emirertorer-bnn-mnist-nexys-a7의 BNN FC(784→128→64→10)는 BRAM 97.78%(132/135)로 Basys3 불가. 단, 층·폭 축소(784→32→16→10, BRAM ≈ 7개)하면 Basys3 한도 내 가능. rajmali-22의 OV7670+8×8 평균 전처리 모듈(독립 분리 가능)을 붙이면 카메라에서 직접 입력을 받아 BNN FC 추론 → LED/VGA 숫자 출력이 된다. 전처리 → 추론 → 표시 완전 파이프라인.

- id: I-140
- 조합: [OV7670-SCCB, 8x8-block-avg, RGB565-to-gray, BNN-FC-784-32-16-10, 7seg-or-VGA-class-display]
- 근거 카드: [[emirertorer-bnn-mnist-nexys-a7]], [[rajmali-22-fpga-zebra-crossing-camera]], [[adityapusalkar-fpga-neural-network]]
- 근거 URL: https://arxiv.org/abs/2512.19304
- 새로움 근거: emirertorer는 카메라 없이 MNIST 픽셀 직접 주입. 카메라를 BNN FC 앞단에 붙이는 조합은 카탈로그 미등록. rajmali-22는 BNN BCNN(합성곱)이므로 BNN FC+카메라 조합은 다른 접근.
- Basys3 적합성 근거: 가중치 축소 후 BRAM ≈ 7개(50개 한도 내). OV7670 Pmod 가능. VGA 온보드. 단, MNIST 대비 OV7670 입력 화질 차이로 정확도 저하 예상. 내 판단: 정확도보다 파이프라인 완결성이 목표.
- 난이도: 4
- 단계: T4
- 상태: raw

---

## I-141 Q4.4 고정소수점 LeNet → Basys3 순수 FSM (Columbia 실패 교훈 반영)

내 판단: columbia-4840-sp24-lenet-classifier의 LeNet(42×42 입력, 2 conv + 3 FC, Q4.4)을 HPS 없는 순수 FSM으로 Basys3에 옮기는 캡스톤. Columbia 보고서의 실패 교훈 4가지(클럭 불일치, 하드코딩 주소, Q4.4 오버플로우, 경계 패딩 오류)를 처음부터 방어 설계에 적용. AXI4-Lite 슬레이브 IP로 래핑 → MicroBlaze V C 드라이버로 가중치 로드 및 추론 트리거.

- id: I-141
- 조합: [LeNet-2conv-3fc-Q4.4, 42x42-grayscale-input, AXI4-Lite-slave, MicroBlaze-V-driver, VGA-or-7seg-output, Vivado-fixed-point]
- 근거 카드: [[columbia-4840-sp24-lenet-classifier]], [[adityapusalkar-fpga-neural-network]], [[columbia-4840-sp26-lenet5-cnn-accelerator]]
- 근거 URL: https://www1.cs.columbia.edu/~sedwards/classes/2024/4840-spring/reports/LeNet-Classifier-report.pdf
- 새로움 근거: Columbia 원본은 Cyclone V HPS+Avalon 의존. Basys3 순수 FSM+AXI 래핑 + 실패 교훈 반영 조합은 카탈로그 미등록. adityapusalkar는 MLP(FC 전용)이므로 합성곱 포함 LeNet은 다른 구현.
- Basys3 적합성 근거: 42×42×1 입력. Conv 1(5×5×6): 커널 150×6=900개 Q4.4 = 900B → BRAM 1개 미만. Conv 2(5×5×16): 2,400B → BRAM 1개. FC 784→324→10: 254,016 Q4.4 = 약 250KB → BRAM ≈ 7개. 합계 약 10 BRAM, Basys3 50개 한도 내. LUT 추정: unverified. 내 판단: BRAM 적합, 단 중간 활성화 맵 버퍼도 필요(라인 버퍼 추가).
- 난이도: 4
- 단계: T4
- 상태: raw
