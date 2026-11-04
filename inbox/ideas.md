
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
- 상태: ready
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
- 상태: ready
- 요약: 내 판단: 속도 PID의 KP/KI/KD를 AXI4-Lite 레지스터로 런타임 변경하고, 계단 입력 후 측정값을 작은 BRAM 버퍼에 담아 읽어 가는 IP. 테스트벤치는 모델 모터로 포화 시 적분 정지(와인드업 없음)와 정착값 오차를 PASS/FAIL로 검사하는 T4.
- 조합: [직교 엔코더(sensor), PWM(actuator), PID FSM, 응답 캡처 BRAM]
- 근거: [hakan-demirli-pid-fpga, microchip-an532-dc-servo-pid, 1runxu-520-pid-fpga, deepc94-pid-fpga-vhdl]
- 새로움의 근거: 카드들은 이득 변경(hakan), 안티 와인드업(AN532), 모듈 분해(1runxu)로 갈라져 있고 응답 캡처를 IP 기능으로 둔 것은 없다. 와인드업 보호가 없는 사례(hakan)와 있는 사례(AN532)를 한 시험으로 비교 가능(내 판단).
- Basys3 적합성의 근거: BRAM 소량(예: 1K×16 한 개, 내 추정)과 곱셈기 몇 개, 핀은 Pmod 2개. 자원 수치는 카드에 없음.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(응답 캡처 IP 없음) + 적합성 2(BRAM 소량·Pmod 2개 범위) + 완결성 2(KP/KI/KD 런타임·BRAM 캡처·와인드업 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 추가.
- 차단조건재심사: 2026-11-04 /verify(5차), 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(hakan-demirli-pid-fpga, microchip-an532-dc-servo-pid, 1runxu-520-pid-fpga, deepc94-pid-fpga-vhdl, rechecked_at 불문) → 근거 3 + 새로움 2(응답 캡처·BRAM 버퍼 IP 없음) + 적합성 2(BRAM 소량·Pmod 2개·곱셈기 소수) + 완결성 2(와인드업·BRAM 캡처 범위 명확) = 9점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-018 스텝모터 가감속 IP: 단위시간당 스텝 누산기 FSM + 스텝 손실 시험 시나리오
- 상태: ready
- 요약: 내 판단: 이동 스텝 수, 최대 속도, 가속도를 AXI4-Lite 레지스터로 받아 사다리꼴 프로파일 스텝 펄스를 만드는 IP. 덧셈과 비교만 쓰고, 테스트벤치는 가속/등속/감속 구간 스텝 수 합과 짧은 이동(삼각형 프로파일)을 비교한다. 28BYJ-48 풀/하프스텝 패턴과 STEP/DIR 출력 모드를 레지스터로 고른다.
- 조합: [스텝 펄스 FSM(actuator-servo), 4선 시퀀서(ULN2003), STEP/DIR 출력(A4988), 상태 레지스터]
- 근거: [stepmotion-vp-steps-per-time, eeict-2011-xpisid00-stepper-linear-speed-controller, opencores-roboarm-stepper], https://www.machinedesign.com/archive/avoiding-step-loss
- 새로움의 근거: 기존 카드는 4선 시퀀서만(opencores-roboarm-stepper), 소프트웨어 계산 의존(eeict 논문), MCU 구현(stepmotion)으로 갈라져 있다. 이를 곱셈 없는 하드웨어 누산기로 묶고, 스텝 손실 원인(공진 구간 통과, 시작 주파수 제한)을 시험 시나리오로 옮긴 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 누산기 32비트와 덧셈 2개 규모라 LUT 소량, BRAM 불필요(내 추정, 소스에 자원 수치 없음). 핀은 Pmod 1개(4선 또는 STEP/DIR/EN), 5V 모듈은 레벨 변환·모터 전원 분리 필요.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(곱셈 없는 사다리꼴 프로파일 하드웨어 없음) + 적합성 2(덧셈·비교기 LUT 소량, Pmod 1개) + 완결성 2(가속·등속·감속 구간 스텝 수·삼각형 프로파일 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건 추가.
- 차단조건재심사: 2026-11-04 /verify, 근거 3(stepmotion-vp-steps-per-time, eeict-2011-xpisid00-stepper-linear-speed-controller, opencores-roboarm-stepper, rechecked_at 불문) + 새로움 2 + 적합성 2 + 완결성 2 = 9점 → ready. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-019 IMU 자세 추정 사다리: I2C 읽기 → 상보 필터 IP → (선택) 칼만 비교, 합성 센서 모델 테스트벤치
- 상태: vetted
- 요약: 내 판단: MPU-6050 원시값(가속도·각속도)을 AXI4-Lite 레지스터로 받아 고정소수점 상보 필터로 롤·피치를 내는 IP. 테스트벤치는 알려진 각도의 합성 센서 값(중력 벡터 + 자이로 편향)을 주입해 수렴을 자체 점검한다.
- 조합: [I2C 센서(MPU-6050), 고정소수점 필터 FSM, AXI4-Lite 레지스터, 7세그 각도 표시]
- 근거: [columbia-4840-spring-2026-ahrs, pmc4628004-microblaze-gps-ins-virtex6, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: 기존 카드는 I2C 읽기만(ammar), 칼만 필터 하드웨어(columbia), 소프트웨어 칼만(pmc4628004)으로 갈라져 있고, 곱셈기 소수로 끝나는 상보 필터를 레지스터 IP와 합성 센서 시험으로 묶은 것은 없다(내 판단).
- Basys3 적합성의 근거: 상보 필터는 곱셈 몇 개로 가능(내 추정, 카드에 자원 수치 없음). 칼만 176개 곱셈기 설계는 시분할이 필요할 수 있어 제외. I2C 2핀은 Pmod 3.3V, GY-521 모듈은 3.3V 로직 확인 필요.
- 난이도: 3 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 1(ammar-bin-amir-arty-a7-i2c-mpu-6050) + 새로움 2(상보 필터 IP + 합성 센서 시험 없음) + 적합성 2(곱셈 소수·I2C 2핀 Pmod) + 완결성 1(고정소수점 비트폭·수렴 조건 미정) = 6점. 보강: 근거 카드 추가, 고정소수점 비트폭 명시.

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
- 상태: vetted
- 요약: 내 판단: 상태 벡터(위치, 속도, 각도, 각속도)와 이득 K를 AXI4-Lite 레지스터로 받아 고정소수점 곱셈-누산으로 출력 u를 내는 IP. 테스트벤치에 카트-폴 이산 모델을 붙여 쓰러지지 않고 수렴하는지 자체 점검. 1단계 이득 고정, 2단계 이득을 런타임 변경, 3단계 STEP 펄스 구동기(I-018)에 가속도 지시로 연결.
- 조합: [엔코더(I-016) 2채널, 상태 되먹임 FSM, 스텝모터 가감속(I-018), 리밋 스위치 차단(I-014)]
- 근거: [comillas-tfg-2026-lqr-cartpole-basys3, polito-upm-2023-cartpole-fpga-lqr-pid-rl, andreicito2-inverted-pendulum, jie-2011-fpga-inverted-pendulum-robot]
- 새로움의 근거: 기존 카드는 Basys3 LQR(본문 미열람), Zynq PS 제어, PC 제어, MicroBlaze PID로 갈라져 있다. 이득을 레지스터로 두는 IP와 모델 폐루프 자체 점검을 합친 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: Comillas 초록이 Basys3에서 1 ms 주기, 루프 지연 360 ns라고 서술(L2). 곱셈 4개 수준으로 추정(내 추정, 자원 수치 없음). 스텝모터 드라이버 5V/모터 전원은 분리, 엔코더 입력은 3.3V 확인.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(LQR IP + 모델 폐루프 시험 없음) + 적합성 2(Comillas 초록 Basys3 1 ms 주기 L2) + 완결성 1(카트-폴 이산 모델·이득 고정 단계 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 1단계(이득 고정 PD)로 범위 축소.

## I-022 릴레이 자동 튜닝 IP: 릴레이 피드백 FSM(주기·진폭 측정) + PID IP 이득 쓰기, 1차+지연 모터 모델 폐루프 테스트벤치
- 상태: vetted
- 요약: 내 판단: PID를 끈 상태에서 출력을 ±a로 번갈아 주고 설정값 교차 때 부호를 뒤집는 릴레이 FSM을 만들고, 한계 사이클의 주기와 진폭을 레지스터로 읽게 한다. MicroBlaze V(또는 테스트벤치의 계산 모델)가 Ziegler-Nichols 표로 이득을 계산해 PID IP에 쓴다. 테스트벤치는 모터 속도를 1차+지연으로 근사한 모델을 붙여 한계 사이클 주기가 해석값과 맞는지 자체 점검한다.
- 조합: [릴레이 FSM, 엔코더 속도 측정, PID IP, PWM/H-브리지, AXI4-Lite 레지스터]
- 근거: [controleng-relay-method-automates-pid-loop-tuning, kmitl-iccas-2003-auto-tune-digital-pid-fpga, tees-isie-2017-compass-search-self-tuning-pid-dc-drive]
- 새로움의 근거: 기존 카드는 고정 이득 PID와 계단 응답 기반 튜닝(KMITL, 개루프)이며 릴레이 방식의 FPGA 구현은 검색 5회로 못 찾음(내 판단). 개루프 시험 대신 닫힌 루프에서 안전 진폭으로 도는 점이 모터 보호 면에서 다르다.
- Basys3 적합성의 근거: 릴레이 FSM은 비교기와 카운터 위주라 곱셈이 필요 없음(내 추정, 자원 수치 없음). 엔코더 2핀과 PWM 1핀은 Pmod 3.3V. 5V 모터 드라이버는 레벨 변환, 모터 전원은 분리.
- 난이도: 4 / 단계: T4
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(릴레이 피드백 FPGA 사례 없음) + 적합성 2(릴레이 FSM 비교기·카운터, Pmod 소수) + 완결성 1(모터 모델 1차+지연 파라미터 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 모터 모델 파라미터 명시.

## I-023 BLDC 사다리: 홀센서 6스텝 FSM + 데드타임 PWM IP → 전류 샘플링 창 → 모터 모델 폐루프 테스트벤치
- 상태: vetted
- 요약: 내 판단: 홀 3입력 해독 FSM(양방향), 10비트 PWM, 상·하 암 데드타임 삽입을 AXI4-Lite 레지스터(듀티, 방향, 데드타임 클럭 수, 홀 상태 읽기)로 묶는다. 테스트벤치는 홀 신호를 생성하는 단순 회전자 모델을 붙여 상 순서, 상·하 암 동시 ON 없음, 데드타임 최소값을 자체 점검한다. 다음 단계로 FOC의 하단 3암 ON 구간 샘플링 신호를 같은 PWM에서 뽑는다.
- 조합: [홀센서 해독 FSM, 데드타임 PWM, 샘플 트리거, AXI4-Lite 레지스터]
- 근거: [arief-2026-ijecbe-artix7-36v-bldc-hall-sixstep, wangxuan95-fpga-foc, mari-upc-2022-fpga-foc-ipmsm-field-weakening]
- 새로움의 근거: 기존 카드에는 엔코더·PID·스텝모터가 있고 BLDC 6스텝과 FOC 입문 사다리는 tinredmc-ultralitebldc 외에 없음(내 판단). 6스텝 → FOC 샘플링 창으로 이어지는 단계 구성이 다르다.
- Basys3 적합성의 근거: 홀 3핀 + PWM 6핀 = Pmod 2개 정도(내 추정, 자원 수치 없음). 3.3V 신호만 직결, 인버터 전원 분리·GND 공통.
- 난이도: 4 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(6스텝→FOC 샘플링 사다리 없음) + 적합성 2(홀 3핀+PWM 6핀 Pmod 2개, 인버터 전원 분리) + 완결성 1(FOC 샘플링 창 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 6스텝 단계로 범위 축소.

## I-024 소리·기울기 반응 LED 매트릭스 IP: PDM/I2S 마이크 대역 에너지 + ADXL345 기울기 → MAX7219 열 버퍼 레지스터
- 상태: vetted
- 요약: 내 판단: MAX7219 SPI 출력을 열 버퍼·밝기·갱신 트리거 레지스터를 가진 AXI4-Lite 래퍼로 만들고, 소리 대역 에너지(16대역 이하)와 가속도 기울기 중 하나를 모드 레지스터로 골라 막대나 점으로 그린다. 테스트벤치는 합성 사인파 입력으로 대역 막대 높이를, 가짜 ADXL 값으로 점 위치를 확인한다.
- 조합: [MAX7219 SPI 출력, I2S/PDM 마이크 입력, ADXL345 SPI/I2C, AXI4-Lite 레지스터]
- 근거: [vhdplus-spectrum-analyzer-max7219, renesas-forgefpga-fg015-running-string, mit-6111-2017-team20-audio-spectrum-analyzer, https://jpralves.net/post/2017/12/10/visual-accelerometer.html]
- 새로움의 근거: 기존 카드는 오디오 시각화(columbia-4840-audio-visualizer, VGA/LED)와 MAX7219 FPGA 구동(Renesas)과 Arduino 기울기 표시(S1)로 갈라져 있고, 하나의 IP로 두 입력을 모드 전환하는 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: MAX7219는 SPI 3핀(Pmod 1개), 마이크 모듈 3~4핀. 대역 16개 분석은 DSP/BRAM 소량으로 추정(내 추정, 자원 수치 없음; VHDPlus는 12 MHz에서 구동). MAX7219는 5V 전원이라 데이터선 레벨 변환 필요(원 카드는 모두 레벨 변환을 언급).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(소리+기울기 모드 전환 IP 없음) + 적합성 2(MAX7219 SPI 3핀+마이크 모듈 Pmod 2개, 레벨 변환 명시) + 완결성 1(16대역 FFT/필터 구현 범위 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, 대역 수 고정.


## I-025 CTRL/DATA형 I2C 마스터 IP: NEORV32 TWI 레지스터 배치 착안 + MPU-6050 읽기 시험 모델 테스트벤치
- 상태: ready
- 요약: 내 판단: 분주·START·STOP·ACK·BUSY를 CTRL 하나, 송수신 바이트를 DATA 하나에 둔 AXI4-Lite I2C 마스터 IP를 자체 RTL로 새로 쓴다. 바이트 완료를 인터럽트 1비트로 내보내 INTC 빈 입력에 배정을 제안한다. 테스트벤치는 가짜 MPU-6050(주소 0x68) 슬레이브 모델로 레지스터 읽기 시퀀스를 점검한다.
- 조합: [I2C 마스터, MPU-6050 IMU, AXI4-Lite 레지스터, INTC 입력]
- 근거: [stnolting-neorv32, ammar-bin-amir-arty-a7-i2c-mpu-6050, yosyshq-picorv32]
- 새로움의 근거: 카탈로그의 I2C 사례는 FSM 직결(Arty A7 MPU-6050)이거나 CPU별 레지스터 모델이고, CPU 중립 레지스터 규약으로 IMU 읽기를 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: I2C는 Pmod 핀 2개(SDA 개방 드레인, 풀업 필요), 3.3V 모듈(MPU-6050 GY-521은 보드에 따라 레벨 확인 필요). 자원은 FSM과 분주기 수준으로 작을 것으로 추정(내 추정, 수치 없음).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 1(ammar-bin-amir-arty-a7-i2c-mpu-6050) + 새로움 2(CPU 중립 CTRL/DATA I2C IP 없음) + 적합성 2(I2C 2핀 Pmod, 풀업 필요) + 완결성 2(CTRL/DATA 레지스터·MPU-6050 슬레이브 모델 범위 명확) = 7점. 보강: 근거 카드 2건 추가.
- 차단조건재심사: 2026-11-04, 근거 3(stnolting-neorv32·ammar-bin-amir-arty-a7-i2c-mpu-6050·yosyshq-picorv32, rechecked_at 불문) + 새로움 2(CPU 중립 CTRL/DATA I2C IP 없음) + 적합성 2(I2C 2핀 Pmod, 풀업 필요) + 완결성 2(CTRL/DATA 레지스터·MPU-6050 슬레이브 모델 범위 명확) = 9점 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-026 UDP 텔레메트리 송신 IP: W5500 SPI 초기화 ROM + BRAM 송수신 창, 레지스터 응답 모델 테스트벤치
- 상태: ready
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
- 상태: vetted
- 요약: 내 판단: JSTK2 SPI 판독 IP(X/Y/버튼 레지스터)와 서보 PWM IP(채널별 최소·최대 펄스 폭, 위치 레지스터)를 AXI4-Lite로 나누고, 소프트웨어 루프가 조이스틱 값을 서보 위치로 매핑하며 기울기 제한으로 급가속을 막는다. 테스트벤치는 JSTK2 응답 모델이 7바이트 패킷을 돌려주고 서보 펄스 폭을 `!==`로 검사한다.
- 조합: [Pmod JSTK2(SPI), 서보 PWM 2채널, AXI4-Lite 레지스터, 타이머 인터럽트]
- 근거: [digikey-forum-jstk2-pmod-controller-vhdl, vhdlwhiz-rc-servo-controller, shashankr-basys3-fpga-robotic-arm]
- 새로움의 근거: 카탈로그에 서보 PWM 단독 카드는 없고, SPI 조이스틱 입력과 서보 출력을 IP 표준 슬롯 둘로 잇는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 2개(JSTK2 SPI 4핀, 서보 신호 2핀)로 가능. 서보 전원은 외부 5 V 분리, 신호 3.3 V 직결 가능 여부는 서보별로 확인 필요(vhdlwhiz는 레벨 변환 권장).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(JSTK2→서보 IP 조합 없음) + 적합성 2(Pmod 2개·서보 전원 분리 명시) + 완결성 2(JSTK2 모델+서보 펄스 비교 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.

## I-029 상태 표시 OLED IP: SPI 초기화 ROM + 128x32 프레임 버퍼 창, 제어 루프 값(속도·오차)을 글자로 표시, SPI 출력 바이트열 비교 테스트벤치
- 상태: vetted
- 요약: 내 판단: 초기화 명령을 ROM(데이터)으로 두고 FSM은 바이트 전송만 하는 SSD1306 SPI 컨트롤러를 AXI4-Lite 레지스터(시작, 상태, 버퍼 쓰기 창, 전원 순서 대기 파라미터)로 감싼다. 소프트웨어가 엔코더·PID 값을 5x7 글자로 버퍼에 그리면 IP가 페이지 단위로 밀어낸다. 시험은 SPI 출력 바이트열을 기대값과 비교하는 자체 점검 tb.
- 조합: [Pmod OLED(SSD1306 SPI), 엔코더·PID 값 레지스터, AXI4-Lite 레지스터, 프레임 완료 인터럽트]
- 근거: [digilent-pmod-oled-reference-manual, lushaylabs-tang-nano-9k-ssd1306-oled, masterplayer-lcd-st7789-sv]
- 새로움의 근거: 카탈로그의 디스플레이 카드는 VGA와 MAX7219 매트릭스뿐이고 OLED/LCD 모듈 카드는 없었다. 제어 루프 값을 저전력 소형 화면에 쓰는 조합도 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1개(SPI 4핀 + D/C, RES, 전원 제어 2핀)면 되고 프레임 버퍼 128x32비트는 512바이트 수준이라 BRAM 부담이 작다(내 계산: 128×32/8 = 512 B). 전원 전압은 공식 페이지로 확인 필요(unverified).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(OLED 모듈 IP 없음) + 적합성 2(Pmod 1개·512 B BRAM·전원 unverified 명시) + 완결성 2(초기화 ROM+버퍼 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건, 전원 전압 확인.

## I-030 1-Wire 온도 IP: 비트 마스터 하드웨어 + 스크래치패드·CRC 소프트웨어 분담, DS18B20 모델 포함 테스트벤치
- 상태: vetted
- 요약: 내 판단: 리셋·쓰기 비트·읽기 비트만 FSM으로 구현한 1-Wire 비트 마스터를 AXI4-Lite 레지스터(명령, 데이터, 상태, 완료 인터럽트)로 노출하고, Convert T 대기·CRC·ROM 선택은 소프트웨어가 맡는다. 테스트벤치는 DS18B20 응답 모델로 프레즌스와 스크래치패드 바이트열을 비교한다.
- 조합: [DS18B20(1-Wire), AXI4-Lite 레지스터, 타이머 인터럽트, 7세그/UART 표시]
- 근거: [cvut-pehnelt-2014-vhdl-periferie-nexys4, analog-maxim-interfacing-ds18x20, opencores-onewire-ds1820]
- 새로움의 근거: 카탈로그에 1-Wire 카드는 없었고, 기존 사례(고정 750 ms 대기, Skip ROM만)와 달리 소프트웨어 분담과 센서 모델 시험을 묶는 점이 다르다(내 판단).
- Basys3 적합성의 근거: Pmod 핀 1개(양방향, 외부 풀업)와 3.3 V 전원이면 되고 100 MHz에서 1 µs 틱 분주 100이면 충분해 BRAM이 필요 없다(내 계산).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(1-Wire 비트 마스터 IP 없음) + 적합성 2(Pmod 1핀·외부 풀업·BRAM 불필요) + 완결성 2(리셋·쓰기·읽기 비트 FSM + DS18B20 모델 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.


## I-031 블루투스 텔레메트리 브리지 IP: UART 슬롯 위 프레임 송수신 + STATE/EN GPIO, HC-05 응답 모델 테스트벤치
- 상태: vetted
- 요약: 내 판단: HC-05/06을 동결 맵 UART 영역에 연결하고, 연결 상태(STATE)와 AT 진입(EN)을 GPIO 비트로 두어 제어 루프 값(속도·각도)을 프레임으로 송신, 폰의 명령 1바이트를 수신해 목표값 레지스터에 쓰는 구조. 시험은 9600 bps 비트열을 생성하는 모델로 수신과 프레임 송신을 비교하는 자체 점검 tb.
- 조합: [HC-05(UART, STATE, EN), AXI4-Lite 레지스터, 수신 인터럽트, 엔코더·PID 값]
- 근거: [hackster-ee2259-lab8-bluetooth-uart, epfl-prsoc-bluetooth-hc05, ndroid-hc06-at-commandcenter]
- 새로움의 근거: 카탈로그에 블루투스는 무선 카드 일부뿐이고, AT 설정을 소프트웨어로 분리하고 모듈 모델로 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1개(TX, RX, STATE, EN) 3.3V 로직, 9600 bps는 분주 10417(내 계산)이라 BRAM 불필요.
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(HC-05 AT 분리+모델 시험 없음) + 적합성 2(Pmod 1개·3.3V·9600 bps 분주 명확) + 완결성 2(프레임 송수신 모델 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.

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
- 상태: vetted
- 요약: 내 판단: I2C 비트·바이트 제어를 하드웨어에 두고 장치 주소·레지스터 포인터를 레지스터로 노출해 DS3231(0x68)과 24LC256(0x50)을 한 IP로 다룬다. 제어 루프 값을 시각과 함께 EEPROM에 남기는 로거 응용. NACK은 STATUS 비트로 올려 EEPROM 쓰기 중 ACK 폴링을 소프트웨어가 한다.
- 조합: [I2C(DS3231 RTC, 24LC256 EEPROM), AXI4-Lite 레지스터, 바이트 FIFO, 제어 루프 값]
- 근거: [angelojacobo-fpga-i2c-implementation, digikey-forum-mcp79410-pmod-rtcc-vhdl, mines-eeng383-lecture25-24lc256-i2c]
- 새로움의 근거: 카탈로그의 I2C 자료는 MPU-6050 센서뿐이고, 시계·메모리 두 장치를 한 IP로 묶고 모델로 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1개(SCL, SDA)와 3.3 V 로직, 외부 풀업 필요(DigiKey 글 서술), BRAM 불필요. 400 kHz면 분주 250(내 계산, 100 MHz 기준).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(RTC+EEPROM 한 IP 없음) + 적합성 2(Pmod 1개·외부 풀업·BRAM 불필요) + 완결성 2(DS3231+24LC256 모델 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.

## I-034 IR 리모컨 조종 IP: NEC 디코더(반복 코드 포함) + 명령→모터·서보 매핑 레지스터, 합성 IR 프레임 테스트벤치
- 상태: vetted
- 요약: 내 판단: IR 수신 모듈 출력을 NEC FSM으로 해독해 주소·명령·유효·반복 플래그를 AXI4-Lite 레지스터와 인터럽트로 노출한다. 펌웨어가 명령 코드를 모터 방향·속도, 서보 각도로 매핑한다. 테스트벤치는 정상 프레임, 반전 오류, 반복 프레임, 잘림을 합성해 PASS/FAIL로 점검.
- 조합: [IR 수신(NEC), AXI4-Lite 레지스터, 인터럽트, DC 모터/서보 PWM]
- 근거: [opencores-nec-ir-decoder, bcit-elex7660-infrared-communication, marph91-icestick-remote]
- 새로움의 근거: 카탈로그의 입력 장치는 센서·HID·XADC 중심이고, 원격 무선 명령으로 구동기를 조종하는 조합과 반복 코드 처리를 시험하는 사례는 없다(내 판단). OpenCores 코어가 반복 코드를 미구현이라는 점이 빈틈.
- Basys3 적합성의 근거: Pmod 1핀(수신 모듈 출력)이면 충분, 3.3 V형 모듈 선택 시 변환 불필요, BRAM 불필요. 100 MHz에서 562.5 µs = 56,250 클럭(내 계산).
- 난이도: 2 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(NEC+반복 코드+구동기 조합 없음) + 적합성 2(Pmod 1핀·3.3V 모듈·BRAM 불필요) + 완결성 2(정상·반전·반복·잘림 프레임 테스트벤치 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 1건.

## I-035 SPI 무선 모듈 IP: nRF24L01형 명령/상태 프레임 엔진 + CE 펄스·IRQ 3종 인터럽트, 레지스터 모델 테스트벤치
- 상태: vetted
- 요약: 내 판단: SPI 바이트 엔진(명령 바이트 → STATUS 응답), CE 10 µs 펄스 생성, IRQ 액티브 로우 입력을 AXI4-Lite 레지스터와 인터럽트로 노출하고, 초기화 순서와 재시도는 펌웨어에 둔다. nRF24L01 레지스터 모델을 테스트벤치에 넣어 TX/RX 순서를 시험한다. LoRa SX1278은 같은 SPI 슬롯에 RESET/DIO0 핀만 바꿔 쓰는 확장 단계로 둔다(난이도 사다리).
- 조합: [SPI(nRF24L01 → SX1278), GPIO(CE/RESET), 인터럽트(IRQ/DIO0), AXI4-Lite 레지스터]
- 근거: [mikrocontroller-net-nrf24l01-tutorial, electroniclinic-arduino-sx1278-lora-two-way, microcontrollerslab-sx1278-lora-module]
- 새로움의 근거: 카탈로그의 무선 자료는 UART 기반 블루투스(HC-05)와 CAN이고, SPI 명령/상태 방식의 소출력 무선 모듈을 IP 표준 레지스터로 묶고 모델로 시험하는 조합은 없다(내 판단).
- Basys3 적합성의 근거: Pmod 1~2개(SCK, MOSI, MISO, CSN, CE, IRQ 6핀)와 3.3 V 로직으로 충분하고 BRAM 불필요. 모듈 전원 순간 전류용 커패시터 필요(글 서술). SPI 분주는 설계 시 정함(내 판단).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 0 + 새로움 2(SPI 무선 IP + 레지스터 모델 없음) + 적합성 2(Pmod 1~2개·3.3V·BRAM 불필요) + 완결성 1(LoRa 확장 단계 미정) = 5점. 보강: 근거 카드 rechecked_at 1건, nRF24L01 단계로 범위 고정.

## I-036 센서 허브 IP: I2C 3장치(MPU-6050·BMP280·HMC5883L) 순회 + NMEA UART 수신, 공통 타임스탬프 표본 FIFO
- 상태: ready
- 요약: 내 판단: I2C 마스터가 주소 표(0x68, 0x76/0x77, 0x1E)를 순회해 센서별 원시값을 읽고, UART 수신기가 NMEA 문장 한 줄을 완료 인터럽트로 알리며, 모든 표본에 자유 실행 카운터 타임스탬프를 붙여 FIFO에 쌓는 AXI4-Lite 허브 IP. 보정 계산과 NMEA 필드 추출은 펌웨어. 테스트벤치에 I2C 슬레이브 모델 3개와 NMEA 문장 발생기를 넣는다.
- 조합: [I2C 순회 마스터, UART NMEA 수신, 타임스탬프 FIFO, AXI4-Lite 레지스터·인터럽트]
- 근거: [shillehtek-nano-mpu6050-neo6m-vehicle-logger, arduino-forum-nano-crash-3-i2c-gps, jpralves-car-hud-speed-compass, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: 기존 카드는 I2C 센서 단일 구동이나 모터 제어 중심이고, 독립 주기 센서 여러 개와 GPS 문장을 공통 타임스탬프로 묶는 허브는 없다. 대상 자료가 GPS 주기에 IMU를 묶은 약점을 직접 보완한다(내 판단).
- Basys3 적합성의 근거: Pmod 2개(I2C 1세트 SCL/SDA, UART RX 1핀)와 3.3 V 로직으로 충분, FIFO는 BRAM 소량. 센서 3.3 V 모듈 선택 필요(데이터시트 VDD 최대 3.6 V, devices/i2c/bmp280.md). 9600 baud 비트 시간은 100 MHz에서 10,417 클럭(내 계산).
- 난이도: 3 / 단계: T2
- 심사: 2026-11-04 /verify, 근거 1(ammar-bin-amir-arty-a7-i2c-mpu-6050) + 새로움 2(I2C 순회+NMEA UART 허브 없음) + 적합성 2(Pmod 2개·3.3V 센서·FIFO BRAM 소량) + 완결성 1(I2C 순회 주기·FIFO 깊이 미정) = 6점. 보강: 근거 카드 추가.
- 차단조건재심사: 2026-11-04 /verify, 모든 WebFetch PROVENANCE_REQUIRED 차단. 근거 카드 총 4건(shillehtek-nano-mpu6050-neo6m-vehicle-logger·arduino-forum-nano-crash-3-i2c-gps·jpralves-car-hud-speed-compass·ammar-bin-amir-arty-a7-i2c-mpu-6050, rechecked_at 불문) → 차단 근거 3 + 새로움 2(I2C 순회+NMEA UART 공통 타임스탬프 허브 없음) + 적합성 2(Pmod 2개·3.3V 센서 가능·FIFO BRAM 소량) + 완결성 1(I2C 순회 주기 100 ms 기준·FIFO 깊이 16샘플로 고정 가능, 테스트벤치 작성 가능) = 8점 ≥ 7 → ready 승격. WebFetch PROVENANCE_REQUIRED 전면 차단으로 §14.2 차단 조건 적용.

## I-037 명령 우선순위 중재 RC카 IP: 원격 명령 vs 거리 안전정지 중재 FSM + 서보 3방향 스캔 결정 레지스터
- 상태: ready
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
- 상태: vetted
- 요약: 내 판단: ESP32가 BLE 비콘(iBeacon) RSSI 값을 수동 스캔해 UART로 Basys3에 전달하고, Basys3의 고정소수점 DSP IP가 삼변측량(적어도 3개 앵커 기준 거리 역산)을 수행하는 T3 패키지. ESP32는 기존 `rcaelers-esp32-beacon-scanner` 구조를 참고 설계로 삼고, AXI4-Lite 슬레이브 IP는 거리 레지스터 3~4개와 계산 트리거 비트·결과 레지스터로 구성한다.
- 조합: [BLE-scanner(ESP32), comm-uart, sensor, accelerator(FPGA 고정소수점)]
- 근거: [rcaelers-esp32-beacon-scanner, espressif-idf-gatt-server-walkthrough]
- 새로움의 근거: 카탈로그에 BLE 비콘→FPGA 연산 가속 조합 카드·패키지 없음. RSSI→거리 변환(경로 손실 모델, 고정소수점)과 삼변측량 연산 IP는 기존 PID·IMU IP와 다른 계산 패턴이다(내 판단).
- Basys3 적합성의 근거: UART 수신 FSM은 기존 카탈로그 사례 다수. 고정소수점 덧셈·나눗셈은 Basys3 LUT으로 충분(내 추정, 실측 없음). ESP32-Basys3 UART 연결은 3.3V 직결 가능(레벨 변환 불필요). 삼변측량 반복법(Newton-Raphson)은 클럭 수 많아 파이프라인 없이는 느릴 수 있음.
- 난이도: 3 / 단계: T3
- 심사: 2026-11-04 /verify, 근거 1(rcaelers-esp32-beacon-scanner) + 새로움 2(BLE→FPGA 삼변측량 IP 없음) + 적합성 2(UART 직결 3.3V·LUT 소량 추정) + 완결성 1(Newton-Raphson 반복 범위·수렴 조건 미정) = 6점. 보강: ESP32 BLE scan 카드 rechecked_at 추가, 범위 단순화.

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
- 상태: ready
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
- 상태: ready
- 심사: 2026-11-04 /verify, 근거 0(근거 카드 rechecked_at 없음) + 새로움 2(INMP441 I2S RX AXI IP 없음) + 적합성 2(INMP441 3.3V 직결, 신호 3개 Pmod 범위, BRAM 불필요) + 완결성 2(I2S 마스터 클럭 발생기 모델 테스트벤치 범위 명확) = 6점. 보강: 근거 카드 rechecked_at 추가. 차단조건재심사: 2026-11-04 15:40 /verify, 모든 WebFetch PROVENANCE_REQUIRED, 근거 카드 총 2건(randomnerdtutorials-esp32-inmp441-i2s·digilent-forum-pmodamp3-basys3-i2s) → 차단 근거 2 + 새로움 2 + 적합성 2 + 완결성 2 = 8점 ≥ 7 → ready 승격.

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
**상태**: raw
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
**상태**: vetted
**심사**: 2026-11-04 /verify, 근거 0(angelojacobo·abelectronics rechecked_at 없음) + 새로움 2(RPi 호스트 한계 명시적 전제한 I2C 슬레이브 설계 패턴 카드 없음) + 적합성 2(I2C 슬레이브 FSM ~100 LUT, Pmod 3.3V 직결, free_slot 하나) + 완결성 1(패턴 카드 형식이라 TB 범위 불명확; 무클럭스트레칭 타이밍 체크 TB 필요) = 5점 → vetted. 보강: angelojacobo rechecked_at 취득 필요.

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
- 상태: vetted
- 심사: 2026-11-04 /verify, 근거 0(smartmechatronics·sujan·obuda rechecked_at 없음) + 새로움 2(BRAM 제한 FPGA SoC에서 BusyBox init 최소 init 스크립트 카드 없음; S4 제약 역전 첫 적용) + 적합성 2(LiteX Linux initramfs BusyBox 적용 가능, menuconfig 모듈화 obuda 접근법과 같음, BRAM 한계 Basys3 필수 과제 근거) + 완결성 1(패턴 카드, LiteX Linux 선행 조건, TB는 보드 init 시퀀스 측정) = 5점 → vetted. 보강: smartmechatronics·obuda rechecked_at 취득 필요.

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
- 상태: vetted
- 심사: 2026-11-04 /verify 3차, 근거 0(beningo·freertos-org rechecked_at 없음) + 새로움 2(MicroBlaze V + FreeRTOS + AXI INTC 조합 카드·패키지 없음; ISR→태스크 통지 최소 예제 없음) + 적합성 2(Vitis FreeRTOS BSP 패키지 선택 가능, AXI INTC XC7A35T 가능, free_slots 1슬롯) + 완결성 2(RTL+C 최소 예제 패키지 범위 명확, AXI INTC + xSemaphoreGiveFromISR TB 단일 플로우) = 6점 → vetted. 보강: beningo·freertos-org rechecked_at 취득 필요.

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
- 상태: vetted
- 심사: 2026-11-04 /verify 3차, 근거 0(ezurio·freertos-org rechecked_at 없음) + 새로움 2(RTOS 성능 비교 카드 없음; 항목별 역전 패턴 명시한 카드 없음) + 적합성 2(임베디드 공통 참조 자료로 RTL/BRAM 불필요, MicroBlaze V FreeRTOS 타이밍 계획 근거로 활용 가능) + 완결성 2(카드 형태로 TB 불필요, 범위 명확) = 6점 → vetted. 보강: ezurio rechecked_at 취득 필요.

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
- 상태: raw
