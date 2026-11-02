---
name: ammar-bin-amir-arty-a7-i2c-mpu-6050
url: https://github.com/Ammar-Bin-Amir/ARTY_A7_I2C_MPU-6050
source_type: repo
vendor: amd
board: [Arty A7-100T]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified
tools: []
bus: none
peripherals: [sensor, comm-i2c, MPU-6050]
stage: T2
license: unknown
stats: {stars: 2, commits: 9}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://github.com/Ammar-Bin-Amir/ARTY_A7_I2C_MPU-6050]
unverified: HDL 언어, I2C 클럭, 읽는 레지스터, 출력 방식, 테스트벤치 내용, Makefile 타깃, 라이선스, 최신 커밋 SHA (src/tb 하위 경로 열람 불가)
---

## 요약
Arty A7-100T(Artix-7)에서 FPGA를 I2C 마스터로 두고 MPU-6050(자이로·가속도·온도) 데이터를 실시간으로 받는 프로젝트. README는 방향성과 참고 링크 위주로 짧다.

## 구조
- 폴더: `constr/`, `src/`, `tb/`, `Makefile`, `README.md`(루트에서 확인). 토픽에 rtl-design, fpga-testing.
- README 참고 링크: MPU-6050 튜토리얼, InvenSense 데이터시트, 레지스터 맵 문서, Arty A7-100 제약 파일.
- 세부 모듈·레지스터는 읽지 않았다(unverified).

## 검증·재현성
- `tb/`와 `Makefile`이 있어 시뮬레이션 흐름이 있을 가능성이 있으나 내용은 미확인.

## 한계·위험
- 본문이 얕아 사양 추출 불가. 라이선스 unknown.

## 재사용 메모
- 내 판단: 고급 사다리(IMU 자세 추정, topics.md)의 I2C 읽기 입구 후보. Artix-7 동일 계열이라 보드만 Basys3 xdc로 바꾸면 되는 구조로 보이나, 코드 확인 전에는 단정하지 않는다. 소스 사양(주소 0x68, 읽기 순서)은 공식 데이터시트로 따로 확인해야 한다.
- 개조: I2C 마스터+MPU-6050 읽기 FSM을 AXI4-Lite IP 표준 래퍼(레지스터: CTRL, STATUS, ACCEL/GYRO 값, 오류)의 자체 RTL로 새로 쓴다. 라이선스 확인 필요.
