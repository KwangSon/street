# Street

에도 시대풍 가판 초밥집에서 직접 장사를 시작하고, 직원과 시설을 늘려 가게를 자동화하는 세로형 2D 모바일 타이쿤이다.

| 항목 | 내용 |
|---|---|
| 게임명 | **Street** |
| 저장소명 | **`street`** |
| 엔진 | Godot 4.7 |
| 화면 | 720 × 1280 세로형 쿼터뷰 2D |
| MVP | Stage 01을 완주할 수 있는 내부용 버티컬 슬라이스 |
| 문서 버전 | v0.1 |
| 기준일 | 2026-07-27 |

## 현재 구현 상태

현재 저장소에는 실행·저장 로드, 낮 화면 이동, 손님의 주문→제작→서빙→식사→결제→퇴장 반복 흐름, 첫 조리대 강화와 좌석 2 해금까지 담당하는 코드 기반이 구현돼 있다.

- `srcs/main.tscn`: 기존 부트스트랩 장면
- `srcs/main.gd`: `state["screen"]`을 읽어 화면을 교체하는 진입점
- `srcs/screens/loading_screen.gd`: 로컬 JSON 로드, 첫 게임 생성, 손상 데이터 복구 UI
- `srcs/screens/day_screen.gd`: 코드 기반 회색 맵, 고정 HUD, 탭 이동, 드래그 카메라와 낮 영업 시설 연결
- `srcs/day/day_customer.gd`: 손님의 좌석 이동과 주문 말풍선
- `srcs/day/day_customer_manager.gd`: 손님 생성, 좌석 예약, 최대 3명 FIFO 대기열과 고등어 주문 생성
- `srcs/day/day_customer_order_target.gd`: 손님 접근 시 주문 한 건 수령
- `srcs/day/day_preparation_source.gd`: 고등어 상자와 밥통의 순차 재료 수령
- `srcs/day/day_payment.gd`: 좌석 옆 엽전 표시와 접근 회수
- `srcs/day/day_seat_purchase_pad.gd`: 24문 체류 결제와 좌석 2 설치
- `srcs/day/day_upgrade_pad.gd`: 1초 체류 결제로 고등어 조리대 Lv.2를 구매하는 패드
- `srcs/day/day_interaction_controller.gd`: 접근 대상의 우선순위·거리 선택과 진입·이탈 처리
- `srcs/day/mackerel_station.gd`: 준비가 끝난 주문의 제작 진행, 일시정지와 접시 완성
- `srcs/day/day_navigation.gd`: 시설을 우회하는 40px A* 이동 경로
- `srcs/day/day_player.gd`: 주인공 이동, 4방향 표시, 충돌과 운반 접시 표시
- `srcs/globals/game_manager.gd`: `state`와 첫날 기본 상태를 맡는 오토로드
- `srcs/globals/save_manager.gd`: `user://save.json` 읽기·쓰기·백업을 맡는 오토로드
- `project.godot`: Godot 4.7 모바일 프로젝트 설정
- 실행용 메인 장면이 `project.godot`에 등록돼 있다.
- GUT 9.7.1과 `tests/` 자동 발견 설정이 구성돼 있다.
- 좌석 1이 차 있으면 3초 간격으로 최대 3명이 입구에 대기한다. 결제 손님이 퇴장하면 대기열의 첫 손님이 좌석으로 이동하고 새 손님이 맨 뒤를 채운다.
- 낮 영업의 고등어 1접시는 `손님 주문 수령 → 고등어 상자 → 밥통 → 고등어 조리대` 순서로 만든다. 조리대에 바로 접근하면 제작되지 않는다.
- 12문을 모아 구매 패드에 1초 머물면 고등어 조리대가 Lv.2가 된다. 제작시간은 3.2초에서 3.0초로 줄고, 강화 뒤 생성된 주문의 판매가는 6문에서 7문으로 오른다.
- 24문을 모아 좌석 구매 패드에 1초 머물면 좌석 2가 즉시 설치된다. 대기열의 첫 손님이 새 좌석에 우선 배정되고 이후 두 손님의 주문을 동시에 받을 수 있다.
- 새벽 화면, 점원, 영업 종료와 정산은 아직 구현하지 않았다. Main은 목적 화면을 만들 수 없으면 현재 화면을 유지하고 오류를 기록한다.

## 개발 원칙

- 게임 로직, UI, 노드 구성, 밸런스 데이터는 GDScript 중심으로 작성한다.
- 새 `.tscn` 파일은 만들기 전에 사용자 승인을 받는다. 기존 `srcs/main.tscn`은 부트스트랩으로 유지한다.
- Day, 영업 단계, 시간과 타이머, 통화, 재고, 해금 및 진행도 같은 전역 상태는 `GameManager`가 소유한다.
- `SaveManager`는 `GameManager`의 확정된 상태를 단계 경계에서 저장하고 복구한다.
- 화면은 `GameManager.state`를 변경하고 인자 없는 `screen_change_requested`를 보낸다. 다음 화면의 선택과 생성은 `Main`만 담당한다.
- 플레이 영역을 탭하면 해당 월드 위치로 이동하고 드래그하면 카메라가 움직인다. PC 검증에서는 마우스 클릭과 드래그를 사용하며 키보드 이동은 제공하지 않는다.
- 게임 DB에는 xlsx, JSON, `.tres` 파이프라인을 도입하지 않는다. 로컬 저장은 승인된 예외로 `user://save.json`을 사용한다.
- 확정된 게임 동작과 MVP 범위는 `docs/`를 기준으로 구현한다.

자세한 에이전트 작업 규칙은 [AGENTS.md](AGENTS.md)를 따른다.

## 저장소 구조

```text
street/
├── addons/gut/        # GUT 테스트 프레임워크
├── assets/            # 아트·오디오 원본 및 게임 에셋
├── docs/              # 확정 기획과 수용 기준
├── srcs/
│   ├── day/
│   │   ├── day_customer.gd
│   │   ├── day_customer_manager.gd
│   │   ├── day_customer_order_target.gd
│   │   ├── day_interactable.gd
│   │   ├── day_interaction_controller.gd
│   │   ├── day_navigation.gd
│   │   ├── day_payment.gd
│   │   ├── day_player.gd
│   │   ├── day_preparation_source.gd
│   │   ├── day_seat_purchase_pad.gd
│   │   ├── day_upgrade_pad.gd
│   │   └── mackerel_station.gd
│   ├── globals/
│   │   ├── game_manager.gd
│   │   └── save_manager.gd
│   ├── screens/
│   │   ├── day_screen.gd
│   │   └── loading_screen.gd
│   ├── main.gd        # 부트스트랩 스크립트
│   └── main.tscn      # 기존 부트스트랩 장면
├── tests/             # GUT 프로젝트 테스트
├── .gutconfig.json
└── project.godot
```

## 시작하기

Godot 4.7.x가 필요하다. 현재 개발 환경에서 확인한 버전은 4.7.1이다. 아래 명령은 저장소 루트에 Godot 실행 파일 또는 심볼릭 링크가 `./godot`으로 준비돼 있다고 가정한다.

```bash
# 엔진 버전 확인
./godot --version

# 에디터 열기
./godot --editor --path "$PWD"

# 임포트 갱신과 GDScript·리소스 검증
./godot --headless --editor --path "$PWD" --quit
```

다음 명령으로 `tests/` 아래의 GUT 테스트를 실행한다.

```bash
./godot --headless -s --path "$PWD" addons/gut/gut_cmdln.gd \
  -gdir=res://tests -gexit
```

## 문서 상태 표기

- **확정**: MVP 제작 중 임의로 바꾸지 않는 제품 결정
- **초기값**: 플레이테스트로 조정할 수 있는 수치
- **제외**: 현재 MVP에 넣지 않는 항목

수치보다 범위와 완료 조건을 우선한다. 수치를 변경해도 핵심 루프, MVP 포함·제외 범위, 마일스톤 통과 조건은 PM 검토 없이 변경하지 않는다.

## 문서 읽는 순서

1. [00_overview.md](docs/00_overview.md) — 제품 정의와 성공 기준
2. [01_core_loop.md](docs/01_core_loop.md) — 영업 중 반복 플레이
3. [02_day_cycle.md](docs/02_day_cycle.md) — 첫날 예외와 이후 하루 구조
4. [03_stage_01.md](docs/03_stage_01.md) — 강가 가판대의 실제 진행
5. [04_progression_economy.md](docs/04_progression_economy.md) — 성장과 경제 초기값
6. [05_content_list.md](docs/05_content_list.md) — 필요한 콘텐츠 총량
7. [06_art_direction.md](docs/06_art_direction.md) — 2D 프리렌더 제작 기준
8. [07_mvp_scope.md](docs/07_mvp_scope.md) — 포함·제외 범위와 수용 기준
9. [08_schedule.md](docs/08_schedule.md) — 10일 프로토타입과 후속 4주 일정
10. [09_risks.md](docs/09_risks.md) — 위험, 조기 경보, 대응책
11. [10_implementation_order.md](docs/10_implementation_order.md) — 코드 구현 순서와 근무일별 통과 조건

## 이번 버전의 확정 결정

| 항목 | 결정 |
|---|---|
| 장르 | 캐주얼 모바일 타이쿤 |
| 배경 | 역사 고증 시뮬레이션이 아닌 밝은 에도 시대풍 |
| 핵심 모티브 | Eatventure식 직접 이동, 접근 자동 작업, 직원 자동화 |
| 화면 | 세로형 쿼터뷰 2D, 경계 안에서 수동 카메라 이동 |
| 조작 | 플레이 영역 탭으로 이동, 드래그로 카메라 이동, 작업은 접근 시 자동 |
| 기술 | Godot 2D + Blender 프리렌더 PNG 스프라이트 |
| 캐릭터 방향 | 4방향 |
| 첫날 | 아침부터 준비된 재료로 바로 영업 |
| 둘째 날 이후 | 저녁 정산 → 새벽 구매 → 재료 손질 → 다음 날 영업 |
| 전투 | 없음 |
| MVP 정의 | 스토어 출시판이 아닌, 첫 스테이지를 완주할 수 있는 내부용 버티컬 슬라이스 |

## 변경 관리

다음 항목을 바꾸려면 관련 문서를 함께 갱신한다.

- 판매가·비용 변경: `04_progression_economy.md`
- 해금 순서 변경: `03_stage_01.md`, `04_progression_economy.md`
- 콘텐츠 추가: `05_content_list.md`, `07_mvp_scope.md`, `08_schedule.md`
- 하루 길이 변경: `02_day_cycle.md`, `03_stage_01.md`
- 아트 프레임 또는 방향 추가: `05_content_list.md`, `06_art_direction.md`, `08_schedule.md`

한 기능을 추가할 때는 같은 중요도의 기존 기능을 제거하거나 일정을 재산정한다.
