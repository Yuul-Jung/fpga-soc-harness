# ipcheck/ — 사용자 RTL 검증 다리

사용자(정병우)의 MicroBlaze V SoC 실습용 사용자 RTL을 이 저장소의 CI(iverilog·verilator·yosys)로 린트·시뮬레이션·합성하는 자리다. 사용자 환경에는 Verilog 시뮬레이터가 없어 지금까지 Python 모델로만 확인했다(HARNESS §17.3).

**이 폴더는 공개 저장소에 있다.** 여기에 올린 RTL은 공개된다.

## 들어오는 조건 (HARNESS §16.3 G4)
`tools/ipcheck.py`가 아래를 모두 만족하는 IP만 돌린다. 하나라도 빠지면 `gated`로 건너뛰며 통과로 세지 않는다.

| 조건 | 내용 |
|---|---|
| 라이선스 | `ipcheck.json`의 `license`가 `config/policy.json`의 permissive 목록(MIT 등) |
| LICENSE 파일 | `ipcheck/<이름>/LICENSE` 전문 동봉 |
| 사용자 승인 | `ipcheck.json`에 `approved_by_user: "YYYY-MM-DD"` (사용자가 직접 올리거나 승인한 날) |

에이전트는 사용자 승인 없이 사용자 RTL을 이 폴더에 넣지 않는다. 현재 들어 있는 IP는 없다.

## 구성
```
ipcheck/<이름>/
  ipcheck.json   {"top":"axi4lite_seg7","rtl":["rtl/....v"],"tb":["tb/....v"],"license":"MIT","approved_by_user":"2026-11-06"}
  LICENSE
  rtl/  tb/      테스트벤치는 자체 점검형: 통과 PASS, 실패 FAIL 로 시작하는 줄 (비교는 !==)
```
IP는 `config/ip_standard.json`(관리 영역 0xFFF0–0xFFFC)과 동결 주소맵(`config/soc_address_map.json`)을 따라야 한다.

## 실행
`python3 tools/ipcheck.py` → `build/ipcheck.json`. 도구가 없으면 해당 단계는 `skipped`(§13.4). 합성 수치는 yosys 추정이며 Vivado 기준이 아니다. 보드 동작(S3)은 사용자만 올린다.
