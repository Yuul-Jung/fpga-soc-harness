---
name: mit-6111-2021-team04-temple-run
url: https://fpga.mit.edu/videos/2021/team04/report.pdf
source_type: report
vendor: amd
board: [Nexys4 DDR]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [Vivado 2019.1/2019.2]
bus: none
peripherals: [camera, video-vga]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2026-11-02 /verify 재열람 시도 실패(WebFetch 권한 요청 미응답) — 이번 사이클 미대조, rechecked_at 미기록
sources: [https://fpga.mit.edu/videos/2021/team04/report.pdf]
---

## 요약
MIT 6.111(2021) 팀 보고서. OV7670으로 사람의 좌우 이동과 점프를 인식해 Temple Run형 게임을 조작한다. 인식 파이프라인은 프레임 버퍼 없이 스트리밍으로 처리하고, 프레임 버퍼는 카메라 디버그 화면에만 쓴다.

## 구조
- 카메라: OV7670(RGB 5:6:5), 초기화에 ESP8266을 사용(보고서 서술). 카메라는 바닥 근처에서 뒤쪽 녹색 배경을 향함.
- 파이프라인(보고서 서술): Camera Read(HREF/VSYNC로 X/Y 추적, 바이트 2개를 픽셀로 결합) → Vision Process(녹색 채널 임계, 화면 9분할, 분할당 7픽셀 이상이면 활성, 2비트 레인 + 1비트 점프) → Vision Debouncer(점프를 750 ms 이상 연장, 카메라 클럭과 65 MHz 도메인 동기화) → 게임 FSM(장애물 생성, LFSR 난수, 사망 판정) → VGA 그리기.
- 해상도: 카메라 원본 640x480, 320x240도 "허용 가능"이라 서술. 최종 빌드의 해상도는 unverified: 보고서에 불명확.

## 검증·재현성
- 자원: 두 ILA를 켠 상태에서 BRAM 약 67 타일, 장치의 약 50%(보고서 서술). Vivado가 보고한 총 4266 타일은 저자도 설명하지 못함. LUT/FF/타이밍: unverified: 보고서에 없음.
- 보고서가 제시한 계산: 640x480x16비트 프레임 버퍼는 약 4,800 Kbit로 장치의 4,860 Kbit에 근접. 이 값은 보고서 원문 수치이며 Nexys4 DDR의 XC7A100T 기준으로 읽힌다(Basys3 용량은 unverified).
- 소스 저장소, 테스트벤치: unverified: 보고서 본문에서 링크를 확인하지 못함.

## 한계·위험
- 교훈(보고서): BRAM 부족의 원인이 ILA 2개와 1024x768 배경 이미지였음. 자원 사용 보고서를 먼저 확인했다면 바로 알았을 것이라고 서술. 팀원 간 Vivado 버전(2019.1/2019.2)이 달라 공유 IP 합성 실패.
- 조명, 옷 색, 카메라 높이가 임계 처리에 영향. 착지가 너무 빨라 점프 신호를 연장해 해결.
- 라이선스 정보 없음 → unknown. 코드 미열람.

## 재사용 메모
- 내 판단: S4(제약 역전) 사례. Basys3(BRAM 용량은 unverified: 공식 자료 미열람)에서는 640x480 프레임 버퍼가 불가능하므로 "프레임 버퍼 없는 색 임계 + 분할 카운트" 구조가 정확히 맞는 선택지다.
- 내 판단: 레인/점프 인식 출력을 2비트+1비트 신호로 정의해 두면 카메라 없는 테스트벤치(합성 픽셀 스트림)로 PASS/FAIL 검증하는 캡스톤으로 만들 수 있다.
