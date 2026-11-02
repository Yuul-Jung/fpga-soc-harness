# 수집 주제 목록

자동 수집 모드가 위에서부터 `[ ]` 항목을 하나씩 소비한다. 끝나면 `[x]`로 바꾼다.

- [x] Basys3 오디오·I2S 주변장치 (Pmod I2S2, PWM 오디오)
- [x] Basys3 SD 카드 (SPI 모드) 저장장치
- [x] Basys3 카메라 (OV7670, SCCB) 파이프라인
- [x] Basys3 PS/2·USB HID 키보드/마우스 입력
- [x] Basys3 UART/SPI/I2C 센서 허브 (Arduino 모듈 우선)
- [ ] Basys3 이더넷·Bluetooth·CAN 통신 (Pmod 기반)
- [ ] MicroBlaze/MicroBlaze V Basys3 사용자 AXI 주변장치
- [ ] PicoRV32 Basys3 SoC (PicoSoC 포팅 사례) — 제작은 보류, 자료는 수집하고 개조 메모로 MicroBlaze V 기준에 연결 (config/project_profile.json cpu_tracks)
- [ ] Intel/Altera 캡스톤: DE10-Nano·DE1-SoC 주변장치 프로젝트
- [ ] Lattice iCE40/ECP5 RISC-V SoC 주변장치
- [ ] 한국어 FPGA 종합설계·캡스톤 보고서

## 모터 제어 사다리 (A 트랙, 2026-11-02 추가, 위에서부터 소비)
- [ ] 입문: Basys3 서보·DC 모터 PWM 구동과 H-브리지 모듈(TB6612, L298N, DRV8833) 인터페이스, 모터 전원 분리·역기전력 보호
- [ ] 입문: 직교 엔코더 디코더 RTL(4배 해독, 입력 거르기)과 속도·위치 측정 사례 (Verilog, FPGA)
- [ ] 중급: FPGA 정수·고정소수점 PID 속도·위치 제어 (엔코더 + PWM), 계단 응답 측정과 이득 조정
- [ ] 중급: 스텝모터 제어 FSM (28BYJ-48/ULN2003, A4988/DRV8825) 가속 곡선·원점 찾기
- [ ] 고급: IMU(MPU-6050/6500) 자세 추정 상보·칼만 필터를 FPGA/소프트코어로 (I2C 읽기, 고정소수점)
- [ ] 고급: 2륜 자가 균형 로봇 (IMU + 엔코더 + PID) FPGA 구현 사례
- [ ] 전문: 도립진자(Inverted Pendulum) 제어 FPGA 구현 사례 (상태 되먹임, LQR)
- [ ] 전문: 적응 제어·자동 튜닝 PID (릴레이 피드백, 모델 기준 적응) 하드웨어 구현
- [ ] 최상: BLDC/PMSM 홀센서·FOC 입문 FPGA 구현 (3상 PWM, 전류 센싱, 데드타임)
- [ ] 입출력 조합: 마이크·가속도·카메라 입력 + 도트 매트릭스(MAX7219)·음성(DFPlayer)·영상 출력 모듈 조합 사례
- [ ] CPU 중립화 개조: PicoRV32·VexRiscv·NEORV32 SoC의 주변장치 레지스터·인터럽트·부트 흐름 중 AXI4-Lite IP 표준 래퍼로 옮길 수 있는 부분 (전략 S1)
