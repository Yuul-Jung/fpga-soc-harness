---
name: mtvl-for-fpga-standalone-axi-driver
url: https://mtvl-for-fpga.blogspot.com/2019/02/how-to-create-standalone-driver-to.html
source_type: article
vendor: amd
board: [Artix-7]
fit_basys3: needs-port
cpu: MicroBlaze
language: C
tools: [Vivado, Xilinx SDK]
bus: AXI4-Lite
peripherals: [comm-uart]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://mtvl-for-fpga.blogspot.com/2019/02/how-to-create-standalone-driver-to.html, https://mtvl-for-fpga.blogspot.com/2019/01/how-to-create-low-level-software.html]
---

## 요약
Xilinx SDK 환경에서 사용자 정의 AXI 주변장치용 독립형(standalone) 소프트웨어 드라이버를 만드는 전 과정을 다루는 블로그 시리즈. 드라이버 디렉터리 구조, MDD/TCL 메타데이터 파일, xparameters.h 자동 생성 원리, Config/Instance 구조체 패턴, sinit.c 초기화 흐름을 단계별로 설명한다.

## 구조
- **드라이버 디렉터리 레이아웃**
  - `data/` — `<ip>.mdd`(드라이버 정의), `<ip>.tcl`(파라미터 추출) 파일
  - `src/` — 주 C 소스(`.c`), 헤더(`.h`), Makefile; 선택적으로 `sinit.c`(설정 조회)
  - 도구(libgen)가 IP 패키지에 연결된 드라이버를 BSP에 자동으로 포함시킨다
- **MDD 파일**: IP의 이름과 버전, 지원 프로세서, 옵션(MSS 파라미터 접속점)을 선언하는 Xilinx 전용 키워드 문서
- **TCL 파일**: libgen이 BSP 생성 시 호출하는 Tcl 스크립트. 두 핵심 명령:
  - `xdefine_include_file`: IP 파라미터 → `xparameters.h` 선언문(예: `XPAR_<IP>_0_BASEADDR`)
  - `xdefine_config_file`: 동일 파라미터 → `<ip>_g.c` 구성 테이블(인스턴스별 1행)
  - TCL에서 사용하는 IP 이름이 C 코드의 접두사가 되므로 대소문자와 철자를 정확히 맞춰야 한다
- **저수준 접근**: IP 베이스 주소 매크로를 `unsigned int *` 포인터에 할당해 오프셋으로 레지스터를 직접 R/W. 비트 패턴을 사용한 커밋 펄스(오프셋 0x0C의 bit24) 등 IP별 프로토콜은 하드코딩
- **드라이버 아키텍처(고수준 패턴)**:
  - `<ip>_Config` 구조체: 도구가 채우는 하드웨어 파라미터(BaseAddr, 클럭 등)
  - `<ip>` 인스턴스 구조체: 런타임 상태 (복수 인스턴스 지원)
  - `sinit.c`: `LookupConfig(DeviceId)` → `CfgInitialize(&Inst, Cfg)` 순서; IsReady 플래그로 중복 초기화 방지
  - 공개 API는 On/Off/Blink 등 액션 함수; 레지스터 접근은 내부에 숨김
- **시뮬레이션 통합**: Vivado 행동 시뮬레이션(XSIM)에 ELF를 연결("Associate ELF Files")해 소프트웨어 흐름을 RTL과 함께 검증

## 검증·재현성
- 단계별 스크린샷 포함 블로그 포스트. 실제 하드웨어 테스트 증거는 없고 XSIM 시뮬레이션으로 소프트웨어 시퀀스 검증.
- 도구가 Xilinx SDK(레거시)라 Vitis 2024.2에서는 프로젝트 생성 UI가 다르지만 MDD/TCL 파일 구조와 libgen 호출 방식은 동일하다(검색 요약 기준, unverified: Vitis 대응 여부 미직접 확인).

## 한계·위험
- Xilinx SDK 기준 작성(2019). Vitis Classic 및 Vitis Unified IDE로 전환 시 BSP 생성 명령·UI가 달라질 수 있다.
- 도구 IP 마법사가 생성한 `<ip>.h` 파일(레지스터 오프셋, 읽기·쓰기 매크로)을 그대로 활용하는 패턴은 나오지 않는다.
- MDD 키워드 완전한 문법은 별도 Xilinx 문서 참조 필요(이 글에서는 구체적 MDD 내용을 보여주지 않음).
- 라이선스 미명시(블로그 포스트).

## 재사용 메모
- 내 판단: 우리 시리즈에서 커스텀 AXI IP 소프트웨어 드라이버 등록 절차(T3→T4 사이의 갭)를 직접 채우는 가장 명확한 자료. xparameters.h 자동 생성 원리를 이해하는 데 필수적.
- 개조: MicroBlaze V(Vitis 2024.2) 기준으로, XSA 내보내기→Vitis 플랫폼 생성→BSP 빌드 단계에서 동결 맵 IP는 libgen이 `XPAR_<IP>_0_BASEADDR` 형태로 자동 생성한다. 커스텀 IP 패키징 시 `component.xml`의 IP 이름이 접두사가 되므로 IP 표준(`config/ip_standard.json`)의 레지스터 맵과 일치시켜야 한다. sinit.c → LookupConfig → CfgInitialize 패턴은 IP 표준의 `driver_init()` 함수 구조와 직접 대응된다.
