---
name: automaticdai-rpi-object-detection
url: https://github.com/automaticdai/rpi-object-detection
source_type: repo
vendor: neutral
board: [RPi CM5, RPi CM4]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: Python
tools: [OpenCV, Picamera2, TFLite, YOLO11n]
bus: none
peripherals: [camera, sensor]
stage: T3
license: MIT
stats: {stars: 미확인, commits: 미확인, last_update: 2026-10}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
unverified_source_rev: 루트 README 열람; 커밋 SHA 미확인
sources: [https://github.com/automaticdai/rpi-object-detection]
---

## 요약

RPi CM4/CM5 + Picamera2 위에서 여러 추론 백엔드(YOLO11n, TFLite EfficientDet-Lite0, Haar, ORB, HSV 색상 추적)를 멀티스크립트로 비교하는 실습 모음. MIT 라이선스.

## 구조

- 단일 Python 스크립트 여러 개(모션 감지, 객체 추적, 얼굴 검출, 색상 추적).
- 공통 파이프라인: Picamera2.capture_array("main", format="RGB888") → OpenCV 처리 → cv2.imshow 또는 MJPEG 스트림.
- Picamera2 ZSL(Zero Shot Lag) 패턴: 미리 할당된 DMA 버퍼 4–6개를 계속 덮어쓰고, capture_array()는 최신 버퍼의 포인터를 반환. cvtColor 없이 RGB888을 직접 쓰면 비용 절감.
- 추론 성능(README 직접 기재): YOLO11n 2.1 FPS(CM5, Ubuntu 24.04 Python 3.12), 0.8 FPS(CM4, RPi OS Python 3.13). TFLite EfficientDet-Lite0 미측정.
- MJPEG 스트리밍 엔드포인트 포함. 인증 없음(문서 직접 서술).

## 검증·재현성

- CM5+Ubuntu 24.04, CM4+RPi OS에서 작동 확인(README 서술, 직접 재현 없음).
- 의존: `python3 -m pip install picamera2 opencv-python tflite-runtime ultralytics`.
- CI 없음.

## 한계·위험

- 카메라 1개만 동시 사용 가능.
- MJPEG 스트림에 인증 없음(운영 환경 주의).
- 조명·거리 변화에 민감(문서 직접 서술).
- CM5 2.1 FPS는 실시간이라 보기 어렵고, 더 큰 모델은 더 느림.
- 라이선스: MIT, 외부 모델(YOLO, TFLite 사전 학습 가중치)은 별도 라이선스 확인 필요.

## 재사용 메모

- Picamera2 ZSL DMA 버퍼 패턴과 "format="RGB888"으로 cvtColor 생략" 기법은 Basys3와의 카메라 브리지 설계 참고 자료로 유효. 개조: 카메라+추론을 RPi가 맡고 결과(바운딩박스 좌표, 클래스 1바이트)만 UART로 MicroBlaze V에 전달하는 역할 분리 구조로 옮길 수 있다. FPGA 측은 AXI-UART Lite로 수신해 VGA 오버레이 IP에 넘기는 T3 패키지로 이어진다(I-052 아이디어). 추론 코드·모델 가중치는 반입 금지(라이선스 혼재), 역할 분리 구조와 버퍼 패턴 설계 힌트로만 쓴다.
