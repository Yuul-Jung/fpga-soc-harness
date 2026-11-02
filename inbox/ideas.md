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
- 상태: raw
- 요약: 내 판단: Pmod AMP2 PWM 출력으로 사각파→사인표→음계→BRAM 곡 재생까지 FSM으로 만들고, 재생 중 음높이를 VGA 막대로 보여주는 T1~T2 패키지.
- 조합: [audio-pwm, video-vga, BRAM]
- 근거: [zipcpu-pmodamp2-project-ladder, columbia-4840-audio-visualizer]
- 새로움의 근거: 카탈로그에 오디오+VGA 조합 패키지 없음(현재 카드 3건, 패키지는 mmio-uart-gpio-skeleton뿐). 
- Basys3 적합성의 근거: PWM 1핀 + Pmod 헤더 + VGA는 Basys3 기본 자원. 곡 데이터는 BRAM 소량. 근거는 사다리 글(9단계 BRAM 곡)이며 Basys3 실측은 없음.
- 난이도: 2 / 단계: T2
- 심사: (/verify가 기록)

## I-002 I2S 클럭 체크 하네스: MMCM→MCLK→I2S 송신기 자체 점검 테스트벤치
- 상태: raw
- 요약: 내 판단: 12.288 MHz MCLK에서 BCLK/LRCLK를 파생하고 I2S 프레임을 만드는 송신기를 작성하고, 테스트벤치가 비율과 프레임 정렬을 PASS/FAIL로 검사하는 T2 패키지. 실패 사례의 교훈을 검증 항목으로 바꾼다.
- 조합: [audio-i2s, MMCM clocking]
- 근거: [digilent-forum-pmodamp3-basys3-i2s, columbia-4840-audio-visualizer]
- 새로움의 근거: 기존 카드·패키지에 I2S 없음. 포럼 스레드의 비트 카운터 비동기 문제를 테스트로 고정한다는 관점.
- Basys3 적합성의 근거: Pmod 한 포트(JA)로 MCLK/LRCK/SCLK/SDIN 4신호 필요(Pmod I2S2 매뉴얼 L3, 큐 참조). MMCM 사용 가능은 포럼 스레드 사례.
- 난이도: 3 / 단계: T2
- 심사: (/verify가 기록)

## I-003 SD SPI 초기화·블록 읽기 자체 점검 패키지 (카드 모델 테스트벤치)
- 상태: raw
- 요약: 내 판단: Pmod SD용 SPI 마스터와 초기화 FSM(CMD0/8/55+41/58)을 쓰고, 테스트벤치 안의 간이 SD 카드 모델이 응답하게 해 초기화 성공과 512바이트 블록 읽기를 PASS/FAIL로 검사하는 T1~T2 패키지. 마지막에 UART로 첫 16바이트를 출력.
- 조합: [storage-sd, comm-spi, comm-uart]
- 근거: [element14-security-camera-2-sd-card-interfacing, wangxuan95-fpga-sdcard-file, zipcpu-sdspi]
- 새로움의 근거: 카탈로그의 SD 관련 카드만 있고 SD 패키지는 없음. 근거 글은 쓰기만 다루므로 읽기 경로 + 카드 모델 검증이라는 관점이 다름.
- Basys3 적합성의 근거: Pmod MicroSD 4신호(CS/MOSI/MISO/SCK)로 Pmod 한 포트면 충분, 3.3V(공식 매뉴얼 L3). 100MHz 클럭에서 분주기로 400kHz 초기화 클럭 생성 가능은 element14 글 서술 기준. 실측 없음.
- 난이도: 3 / 단계: T2
- 심사: (/verify가 기록)

## I-004 SD 이미지 → VGA 슬라이드쇼 (BRAM 라인 버퍼)
- 상태: raw
- 요약: 내 판단: SD 카드의 원시 섹터(헤더 없는 저해상도 이미지)를 읽어 BRAM 라인 버퍼로 VGA에 표시하는 T2 패키지. no-dram 제약을 저해상도·스트리밍으로 우회한다.
- 조합: [storage-sd, video-vga, BRAM]
- 근거: [wangxuan95-fpga-sdcard-file, columbia-4840-audio-visualizer]
- 새로움의 근거: 카탈로그에 SD+VGA 조합 없음.
- Basys3 적합성의 근거: Basys3 VGA 12비트와 BRAM 용량 범위 내 저해상도 가능하다는 추정. 근거 카드에 Basys3 실측 없음 — 보강 필요(VGA 카드 필요).
- 난이도: 4 / 단계: T2
- 심사: (/verify가 기록)
