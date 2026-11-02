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
- 상태: vetted
- 요약: 내 판단: 12.288 MHz MCLK에서 BCLK/LRCLK를 파생하고 I2S 프레임을 만드는 송신기를 작성하고, 테스트벤치가 비율과 프레임 정렬을 PASS/FAIL로 검사하는 T2 패키지. 실패 사례의 교훈을 검증 항목으로 바꾼다.
- 조합: [audio-i2s, MMCM clocking]
- 근거: [digilent-forum-pmodamp3-basys3-i2s, columbia-4840-audio-visualizer]
- 새로움의 근거: 기존 카드·패키지에 I2S 없음. 포럼 스레드의 비트 카운터 비동기 문제를 테스트로 고정한다는 관점.
- Basys3 적합성의 근거: Pmod 한 포트(JA)로 MCLK/LRCK/SCLK/SDIN 4신호 필요(Pmod I2S2 매뉴얼 L3, 큐 참조). MMCM 사용 가능은 포럼 스레드 사례.
- 난이도: 3 / 단계: T2
- 심사: 2026-11-02 /verify, 근거 1(포럼 카드 재열람 실패, Columbia만 재열람) + 새로움 2 + 적합성 1(Basys3 사례는 포럼 카드뿐이라 미대조) + 완결성 2 = 6점. 보강: 포럼 스레드 재열람, Pmod I2S2 매뉴얼 카드화.

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

## I-005 프레임 버퍼 없는 색 추적: 9분할 카운트 → 레인/점프 신호 (합성 픽셀 스트림 테스트벤치)
- 상태: raw
- 요약: 내 판단: RGB565 픽셀 스트림(HREF/VSYNC/PCLK)을 받아 녹색 임계 후 화면 9분할 픽셀 수를 세고, 2비트 레인 + 1비트 점프를 내는 스트리밍 파이프라인. 테스트벤치가 합성 카메라 모델로 프레임을 만들어 PASS/FAIL로 검증하고, 출력은 LED·7세그에 표시하는 T4 패키지.
- 조합: [camera, 7-segment/LED]
- 근거: [mit-6111-2021-team04-temple-run, columbia-4840-cameracontrol, shubhayu-das-vl504-project]
- 새로움의 근거: 기존 카드·패키지에 카메라 조합 없음. 프레임 버퍼 없이 BRAM 제약을 우회(S4)하고, 실제 카메라 없이 검증 가능한 점이 다름.
- Basys3 적합성의 근거: 스트리밍이라 BRAM 불필요. 카메라 8비트+제어 신호는 Pmod 3개 규모로 추정(VL504 배선표는 미열람이라 핀 수는 unverified). 실측 없음.
- 난이도: 3 / 단계: T4
- 심사: (대기)

## I-006 OV7670 SCCB 설정 송신기 + 캡처 프런트엔드 자체 점검 (카메라 모델)
- 상태: raw
- 요약: 내 판단: 설정 ROM을 SCCB로 순서대로 쓰는 송신기와 PCLK 도메인 캡처 모듈을 쓰고, 테스트벤치의 SCCB 슬레이브 모델이 ACK/레지스터 기록을 검사하며 이어서 픽셀 바이트 쌍 결합과 프레임 완료 신호를 검사하는 T2 패키지. 클럭 도메인을 PCLK/시스템 2개로 줄여 Columbia 보고서의 실패 요인을 피한다.
- 조합: [camera, comm-i2c(SCCB)]
- 근거: [shubhayu-das-vl504-project, columbia-4840-cameracontrol, mit-6111-2021-team04-temple-run]
- 새로움의 근거: SD 패키지와 같은 "모델 기반 자체 점검" 방식을 카메라 설정에 적용. 카탈로그에 SCCB/I2C 패키지 없음.
- Basys3 적합성의 근거: SCCB 두 선 + 캡처 입력은 Pmod 범위. 4.7K 풀업 필요는 westonb README 서술(큐 참조, 카드 미작성). 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: (대기)

## I-007 PS/2 키보드 수신기 + 스캔코드→ASCII 자체 점검 (장치 모델 테스트벤치)
- 상태: raw
- 요약: 내 판단: PS/2 프레임(시작·8데이터·홀수 패리티·정지)을 받는 수신기와 make/break(F0)·확장(E0) 시퀀스 해석기를 쓰고, 테스트벤치의 PS/2 장치 모델이 일반 키·뗌·확장 키·패리티 오류 프레임을 보내 ASCII 바이트 출력과 중복 입력 없음을 PASS/FAIL로 검사하는 T1~T2 패키지. 출력은 UART로 낸다.
- 조합: [hid-ps2, comm-uart]
- 근거: [digilent-basys-3-keyboard, oakland-ece378-group4-keyboard2vga]
- 새로움의 근거: 카탈로그에 입력 장치 패키지 없음. Group4 보고서의 뗌 코드 미시뮬레이션으로 글자가 두 번 찍힌 실패를 테스트 항목으로 고정한다는 관점(S6).
- Basys3 적합성의 근거: Basys3 매뉴얼상 PS/2 에뮬레이션 신호 2개와 USB-UART 사용, 내부 풀업 필요(매뉴얼 L3). 별도 Pmod 불필요. 실측 없음.
- 난이도: 2 / 단계: T1
- 심사: (대기)

## I-008 PS/2 마우스 초기화·패킷 디코더 → 커서 좌표 + VGA 오버레이 (프레임 버퍼 없음)
- 상태: raw
- 요약: 내 판단: 마우스 식별(AA→00)과 데이터 보고 활성화(F4) 시퀀스를 보내는 호스트 FSM, 3바이트 패킷 디코더(부호 확장·화면 경계 클램프), 커서만 그리는 VGA 오버레이를 쓰고, 테스트벤치의 마우스 모델이 시퀀스와 패킷을 보내 좌표를 검사하는 T2 패키지. 그림판 프레임 버퍼를 빼서 BRAM 부담을 없앤다.
- 조합: [hid-ps2, video-vga]
- 근거: [oakland-ece378-group7-paintervga, digilent-basys-3-keyboard]
- 새로움의 근거: 카탈로그에 마우스·커서 패키지 없음. Group7의 프레임 버퍼 방식 대신 오버레이만 두는 제약 역전(S4)에 가까운 변형.
- Basys3 적합성의 근거: 마우스 사용 가능과 허브 미지원(키보드와 동시 불가)은 매뉴얼·포럼 기준. VGA 12비트·640×480 25 MHz 예시는 매뉴얼 L3. VGA 구현 카드는 Group7(Nexys4)뿐이라 Basys3 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: (대기)

## I-009 센서 허브 IP 자체 점검: HC-SR04 + DHT11 + I2C(MPU-6050) 장치 모델 테스트벤치
- 상태: raw
- 요약: 내 판단: 트리거/에코 측정 FSM, DHT11 단선 프로토콜 수신 FSM, I2C 마스터(레지스터 읽기)를 레지스터 맵 하나로 묶은 센서 허브를 쓰고, 테스트벤치의 센서 모델(초음파 에코 지연, DHT11 40비트 응답과 체크섬 오류, MPU-6050 레지스터 ACK)이 값을 돌려주면 허브 레지스터 값과 오류 플래그를 PASS/FAIL로 검사하는 T2 패키지.
- 조합: [sensor(HC-SR04), sensor(DHT11/1-wire), comm-i2c, 7seg]
- 근거: [lauriela8-fpga-multi-module-system, hackster-basys3-hcsr04-distance, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: SD(I-003)·카메라(I-006)·PS/2(I-007) 모델 기반 점검 방식을 센서 3종에 적용. 카탈로그에 센서 허브·1-wire·I2C 센서 패키지 없음.
- Basys3 적합성의 근거: 센서 신호 3~4핀은 Pmod 범위, 시계 100 MHz 카운터로 충분(글 서술). HC-SR04 5V echo는 레벨 변환 필요(내 판단, 근거 카드의 한계 항목). 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: (대기)

## I-010 CAN 노드 IP 자체 점검: 비트 타이밍·중재 모델 테스트벤치 + 센서 값 CAN 송출
- 상태: raw
- 요약: 내 판단: 고정 ID 송신, ID 필터 수신, 비트 타이밍 분주를 레지스터로 둔 CAN 노드 IP를 자체 RTL로 쓰고, 노드 2~3개를 모델링한 테스트벤치로 중재·클럭 오차를 확인한 뒤 센서 허브(I-009) 값을 프레임으로 내보낸다.
- 조합: [comm-can, sensor]
- 근거: [wangxuan95-fpga-can, dpiegdon-verilog-can]
- 새로움의 근거: 카탈로그에 CAN 패키지·통신 버스 패키지 없음. 근거 카드가 2건뿐이라 심사에서 근거 점수가 낮을 수 있음.
- Basys3 적합성의 근거: TX/RX 2핀과 100 MHz 분주로 충분(wangxuan95 README의 clk/분주값 식). PHY는 5 V 전원이라 전원 분리·레벨 확인 필요(README 기준).
- 난이도: 3 / 단계: T2
- 심사: (대기)

## I-011 모터 IP 입문 세트: AXI-Lite PWM(서보·DC) + 직교 엔코더 카운터 자체 점검
- 상태: raw
- 요약: 내 판단: PERIOD/COMPARATOR/COUNTER PWM 레지스터와 4배 해독 엔코더 위치·속도 레지스터를 IP 표준 래퍼 두 개로 쓰고, 테스트벤치에서 AXI 쓰기 후 PWM 듀티와 모델 모터 엔코더 펄스가 레지스터 값과 맞는지 PASS/FAIL로 검사하는 T2~T3 패키지. 모터 제어 사다리(A 트랙) 입문 단계의 기반 IP.
- 조합: [actuator-servo, PWM, 엔코더(sensor), comm-i2c 제외]
- 근거: [element14-eoi-blog3-custom-ip-pwm, suoglu-axi-lite-slave, digilent-basys-3-getting-started-microblaze]
- 새로움의 근거: 카탈로그에 PWM·엔코더 IP 패키지 없음. 지금까지 패키지는 SD·센서·통신 중심이고 액추에이터 계열이 비어 있음(내 판단).
- Basys3 적합성의 근거: 카운터와 비교기뿐이라 LUT 소량(suoglu Custom 슬레이브 49 LUT / 83 FF는 README 수치, 참고용), 핀은 Pmod 몇 개로 충분(내 추정). 모터 전원은 분리, 5V 엔코더는 레벨 변환 필요(전기 규칙).
- 난이도: 2 / 단계: T3
- 심사: (대기)

## I-012 UART 메모리 브리지 IP: PC 명령으로 AXI4-Lite 읽기/쓰기, 주변장치 IP 시험 겸 디버그
- 상태: raw
- 요약: 내 판단: 바이트 프로토콜(주소·길이·데이터)을 해석해 AXI4-Lite 마스터 트랜잭션을 만드는 FSM IP. CPU 없이도 PC에서 GPIO·PWM 등 슬레이브 레지스터를 읽고 쓸 수 있고, 테스트벤치에서는 UART 바이트열을 주입해 슬레이브 모델의 레지스터 값이 맞는지 PASS/FAIL로 검사하는 T2.
- 조합: [comm-uart, debug, AXI4-Lite 마스터]
- 근거: [symbiflow-arch-defs-picosoc-basys3, yosyshq-picorv32-picosoc, morsucci-wireless-fpga-debugger]
- 새로움의 근거: 카탈로그의 UART 사례는 센서·통신 중심이고 "UART로 버스 마스터를 구동하는 시험용 브리지"는 없음. 카드들은 UART를 CPU 콘솔로만 씀(내 판단).
- Basys3 적합성의 근거: 115200 baud UART(symbiflow 카드 README 서술)와 분주 레지스터 구조(yosyshq 카드)로 소형 FSM 가능, 핀은 USB-UART 기본 경로 사용(내 추정). BRAM 불필요.
- 난이도: 3 / 단계: T2
- 심사: (대기)

## I-013 속도 PI 폐루프 IP: 엔코더 창 계수 + 에지 간격 측정 + PI 하드웨어 FSM + PWM, 모델 모터 자체 점검
- 상태: raw
- 요약: 내 판단: 엔코더 속도를 10 ms 창 카운트와 에지 간격(주기) 두 방식으로 읽고, 고정소수점 PI를 하드웨어 FSM으로 돌려 PWM 듀티를 갱신하는 IP. 테스트벤치는 1차 지연 모델 모터가 엔코더 펄스를 만들게 하고 계단 지령에 대한 속도가 목표 오차 내로 수렴하는지 PASS/FAIL로 검사하는 T3
- 조합: [직교 엔코더(sensor), PWM(actuator), PI 제어 FSM]
- 근거: [columbia-4840-dc-motor-controller, unipi-se-custom-peripheral-pwm, codeproject-de10-nano-self-balancing-robot]
- 새로움의 근거: I-011은 PWM과 엔코더 계수를 따로 다루고 폐루프 제어는 없다. Columbia 카드는 PI를 소프트웨어(C)로 돌리고 저속 창 계수 분해능이 낮은 점이 한계라, 하드웨어 PI와 이중 속도 측정을 묶은 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 곱셈 몇 개와 카운터뿐이라 DSP·LUT 부담이 작을 것(내 추정, 자원 수치는 카드에 없음). 100 MHz에서 25 kHz PWM은 4000 카운트(내 계산). 모터 전원 분리, 엔코더 5V면 레벨 변환.
- 난이도: 3 / 단계: T3
- 심사: (대기)

## I-014 모터 안전 래퍼 IP: 과전류 입력·데드타임·활성화 게이트를 PWM 출력 앞에 두는 보호 블록 자체 점검
- 상태: raw
- 요약: 내 판단: PWM 출력 앞단에서 H-브리지 상보 신호에 데드타임을 넣고, 외부 과전류 입력이 걸리면 활성화를 끄고 래치된 상태 비트로 남기는 IP. 테스트벤치는 상·하 스위치가 동시에 켜지지 않는지(슛스루 없음)와 과전류 시 출력 차단을 PASS/FAIL로 검사하는 T2
- 조합: [PWM(actuator), 과전류 센서 입력(sensor), 데드타임 FSM]
- 근거: [embeddedts-fpga-pwm-hbridge-quadrature, tinredmc-ultralitebldc, lange-fpga-foc-motor-control-hackaday, ti-drv8833-datasheet, toshiba-tb6612fng-datasheet, markdannemiller-ttu-lab1-bc5-hardware-guide]
- 새로움의 근거: 카드들에서 과전류 보호는 embeddedts에만, 데드타임은 BLDC 두 카드에서 모두 언급되지 않았다(미구현 또는 미기재). 안전 블록 단독 패키지는 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 카운터·비교기 수준이라 소량 LUT(embeddedts 133 LUT 코어가 참고, 내 추정), 핀은 Pmod로 충분. 모터 전원 분리 규칙과 직결.
- 난이도: 2 / 단계: T2
- 심사: (대기)

## I-015 다축 모션 제어 IP: 채널당 엔코더·PID·PWM 한 벌 + 공통 제어 주기 트리거 자체 점검
- 상태: raw
- 요약: 내 판단: 2채널 속도 PID를 공통 1 kHz 트리거로 동기시키는 IP를 자체 RTL로 쓰고, 모델 모터 테스트벤치로 채널 간 지터와 출력 포화를 점검한다.
- 조합: [직교 엔코더(sensor), PWM(actuator), PID FSM, 공통 트리거]
- 근거: [iccas-2003-general-purpose-pid-motion-controller-fpga, ieek-2009-dc-servo-speed-control-fpga, deepc94-pid-fpga-vhdl, columbia-4840-dc-motor-controller]
- 새로움의 근거: 기존 I-013은 단일 채널. 카드 중 다채널과 공통 트리거를 다룬 것은 ICCAS 2003뿐이다(내 판단).
- Basys3 적합성의 근거: 채널당 카운터·곱셈 몇 개 수준(내 추정, 자원 수치는 카드에 없음). 핀은 Pmod 2~3개로 가능(내 추정).
- 난이도: 4 / 단계: T4
- 심사: (대기)

## I-016 엔코더 난이도 사다리: 손 엔코더 → 4체배 속도 IP → 불가능 전이 진단
- 상태: raw
- 요약: 내 판단: 하나의 4체배 디코더 RTL에 방향·위치·고정 창 속도·불가능 전이 오류 카운터를 담고, 슬라이드 스위치 모사 테스트벤치로 정/역방향과 글리치 주입을 자체 점검하는 IP를 만든다.
- 조합: [직교 엔코더(sensor), 7세그 표시, AXI4-Lite 카운터 레지스터]
- 근거: [element14-arty-s7-artybot-axi-speed-sensing-ip, wdevore-tinyfpga-quadrature-decoder-gist, ubc-elex2117-lab6-quadrature-encoder]
- 새로움의 근거: 기존 카드는 홀 1상 계수, 4체배 표시, 전이표 실습으로 갈라져 있고 오류 전이 진단을 레지스터로 노출한 것은 없다(내 판단).
- Basys3 적합성의 근거: 카운터 몇 개 수준(내 추정, 자원 수치 없음). 엔코더 2핀은 Pmod JA에서 3.3V로 가능, 5V 엔코더는 레벨 변환 필요.
- 난이도: 2 / 단계: T2
- 심사: (대기)

## I-017 PID 계단 응답 캡처·이득 조정 IP: 레지스터로 이득 쓰기 + 응답 로그 BRAM 캡처 + 와인드업 보호 자체 점검
- 상태: raw
- 요약: 내 판단: 속도 PID의 KP/KI/KD를 AXI4-Lite 레지스터로 런타임 변경하고, 계단 입력 후 측정값을 작은 BRAM 버퍼에 담아 읽어 가는 IP. 테스트벤치는 모델 모터로 포화 시 적분 정지(와인드업 없음)와 정착값 오차를 PASS/FAIL로 검사하는 T4.
- 조합: [직교 엔코더(sensor), PWM(actuator), PID FSM, 응답 캡처 BRAM]
- 근거: [hakan-demirli-pid-fpga, microchip-an532-dc-servo-pid, 1runxu-520-pid-fpga, deepc94-pid-fpga-vhdl]
- 새로움의 근거: 카드들은 이득 변경(hakan), 안티 와인드업(AN532), 모듈 분해(1runxu)로 갈라져 있고 응답 캡처를 IP 기능으로 둔 것은 없다. 와인드업 보호가 없는 사례(hakan)와 있는 사례(AN532)를 한 시험으로 비교 가능(내 판단).
- Basys3 적합성의 근거: BRAM 소량(예: 1K×16 한 개, 내 추정)과 곱셈기 몇 개, 핀은 Pmod 2개. 자원 수치는 카드에 없음.
- 난이도: 3 / 단계: T4
- 심사: (대기)

## I-018 스텝모터 가감속 IP: 단위시간당 스텝 누산기 FSM + 스텝 손실 시험 시나리오
- 상태: raw
- 요약: 내 판단: 이동 스텝 수, 최대 속도, 가속도를 AXI4-Lite 레지스터로 받아 사다리꼴 프로파일 스텝 펄스를 만드는 IP. 덧셈과 비교만 쓰고, 테스트벤치는 가속/등속/감속 구간 스텝 수 합과 짧은 이동(삼각형 프로파일)을 비교한다. 28BYJ-48 풀/하프스텝 패턴과 STEP/DIR 출력 모드를 레지스터로 고른다.
- 조합: [스텝 펄스 FSM(actuator-servo), 4선 시퀀서(ULN2003), STEP/DIR 출력(A4988), 상태 레지스터]
- 근거: [stepmotion-vp-steps-per-time, eeict-2011-xpisid00-stepper-linear-speed-controller, opencores-roboarm-stepper], https://www.machinedesign.com/archive/avoiding-step-loss
- 새로움의 근거: 기존 카드는 4선 시퀀서만(opencores-roboarm-stepper), 소프트웨어 계산 의존(eeict 논문), MCU 구현(stepmotion)으로 갈라져 있다. 이를 곱셈 없는 하드웨어 누산기로 묶고, 스텝 손실 원인(공진 구간 통과, 시작 주파수 제한)을 시험 시나리오로 옮긴 조합은 카탈로그에 없다(내 판단).
- Basys3 적합성의 근거: 누산기 32비트와 덧셈 2개 규모라 LUT 소량, BRAM 불필요(내 추정, 소스에 자원 수치 없음). 핀은 Pmod 1개(4선 또는 STEP/DIR/EN), 5V 모듈은 레벨 변환·모터 전원 분리 필요.
- 난이도: 2 / 단계: T2
- 심사: (대기)

## I-019 IMU 자세 추정 사다리: I2C 읽기 → 상보 필터 IP → (선택) 칼만 비교, 합성 센서 모델 테스트벤치
- 상태: raw
- 요약: 내 판단: MPU-6050 원시값(가속도·각속도)을 AXI4-Lite 레지스터로 받아 고정소수점 상보 필터로 롤·피치를 내는 IP. 테스트벤치는 알려진 각도의 합성 센서 값(중력 벡터 + 자이로 편향)을 주입해 수렴을 자체 점검한다.
- 조합: [I2C 센서(MPU-6050), 고정소수점 필터 FSM, AXI4-Lite 레지스터, 7세그 각도 표시]
- 근거: [columbia-4840-spring-2026-ahrs, pmc4628004-microblaze-gps-ins-virtex6, ammar-bin-amir-arty-a7-i2c-mpu-6050]
- 새로움의 근거: 기존 카드는 I2C 읽기만(ammar), 칼만 필터 하드웨어(columbia), 소프트웨어 칼만(pmc4628004)으로 갈라져 있고, 곱셈기 소수로 끝나는 상보 필터를 레지스터 IP와 합성 센서 시험으로 묶은 것은 없다(내 판단).
- Basys3 적합성의 근거: 상보 필터는 곱셈 몇 개로 가능(내 추정, 카드에 자원 수치 없음). 칼만 176개 곱셈기 설계는 시분할이 필요할 수 있어 제외. I2C 2핀은 Pmod 3.3V, GY-521 모듈은 3.3V 로직 확인 필요.
- 난이도: 3 / 단계: T4
- 심사: (대기)
