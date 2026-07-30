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

현재 저장소에는 실행·저장 로드, Day 1 낮 영업과 정산, 새벽 시장·배치 준비, Day 2 영업 전환까지 이어지는 P0 핵심 루프와 P0 이후의 좌석 3~4 및 계란 메뉴 전체 흐름이 구현돼 있다.

- `srcs/main.tscn`: 기존 부트스트랩 장면
- `srcs/main.gd`: `state["screen"]` 화면 교체, 낮 화면 좌측 상단 일시정지 메뉴, 단일 슬롯 새 게임, 낮 영업 30초 자동 저장을 맡는 진입점
- `srcs/screens/loading_screen.gd`: 로컬 JSON 로드, 첫 게임 생성, 손상 데이터 복구 UI
- `srcs/screens/day_screen.gd`: 코드 기반 회색 맵, 고정 HUD, 탭 이동, 드래그 카메라, 낮 영업 시설과 정산 한 화면
- `srcs/screens/dawn_screen.gd`: 코드 기반 새벽 시장, 탭 이동, 해금된 재료 구매 패드와 구매 되돌리기
- `srcs/dawn/dawn_purchase_pad.gd`: 1초마다 쌀·고등어·해금된 계란 5인분 묶음을 구매하는 패드
- `srcs/dawn/dawn_preparation_station.gd`: 쌀·고등어·구매한 계란 배치의 순차 1초 준비 시설
- `srcs/day/day_customer.gd`: 손님의 좌석 이동과 주문 말풍선
- `srcs/day/day_customer_manager.gd`: 손님 생성, 좌석 예약, 최대 3명 FIFO 대기열과 재고 기반 고등어·계란 주문 생성
- `srcs/day/day_customer_order_target.gd`: 손님 접근 시 주문 한 건 수령
- `srcs/day/day_preparation_source.gd`: 고등어·계란 재료와 밥통의 순차 재료 수령
- `srcs/day/day_payment.gd`: 좌석 옆 엽전 표시와 접근 회수
- `srcs/day/day_server.gd`: 완성품 예약, 조리대 이동, 주문 확인과 자동 서빙
- `srcs/day/day_seat_purchase_pad.gd`: 24·65·140문 순차 체류 결제와 좌석 2~4 설치
- `srcs/day/day_staff_hire_pad.gd`: 45문 체류 결제와 점원 한 명 고용
- `srcs/day/day_upgrade_pad.gd`: 1초 체류 결제로 고등어 Lv.2 및 계란 해금·Lv.3 강화를 구매하는 패드
- `srcs/day/day_interaction_controller.gd`: 접근 대상의 우선순위·거리 선택과 진입·이탈 처리
- `srcs/day/mackerel_station.gd`: 고등어·계란 조리대의 제작 진행, 일시정지와 주문별 접시 완성
- `srcs/day/day_navigation.gd`: 시설을 우회하는 40px A* 이동 경로
- `srcs/day/day_player.gd`: 주인공 이동, 4방향 표시, 충돌과 운반 접시 표시
- `srcs/globals/game_manager.gd`: `state`와 첫날 기본 상태를 맡는 오토로드
- `srcs/globals/save_manager.gd`: 단일 슬롯 `user://save.json` 읽기·쓰기·백업을 맡는 오토로드
- `project.godot`: Godot 4.7 모바일 프로젝트 설정
- `export_presets.cfg`: ARM64 Android 디버그 내보내기 설정
- 실행용 메인 장면이 `project.godot`에 등록돼 있다.
- GUT 9.7.1과 `tests/` 자동 발견 설정이 구성돼 있다.
- 낮 영업 화면 좌측 상단의 `메뉴`를 열면 전체 게임이 일시정지된다. 메뉴에서는 계속하기와 새 게임을 선택할 수 있으며, 새 게임은 현재 단일 저장 슬롯을 덮어쓴다는 확인 후 Day 1부터 시작한다. 새벽 시장에는 메뉴가 없다.
- 낮 영업 상태는 30초마다 같은 단일 슬롯에 자동 저장되고 낮 단계가 바뀔 때도 즉시 저장된다. 저장된 손님·주문·결제와 중단된 점원 배달은 화면 재생성 시 안전하게 복구한다. 새벽 시장과 준비 중에는 저장 파일을 갱신하지 않는다.
- 손님은 240px/s로 입장·퇴장하며, 좌석 1이 차 있으면 3초 간격으로 최대 3명이 입구에 대기한다. 결제 손님이 퇴장하면 대기열의 첫 손님이 좌석으로 이동하고 새 손님이 맨 뒤를 채운다.
- 낮 영업의 고등어 1접시는 `손님 주문 수령 → 고등어 상자 → 밥통 → 고등어 조리대` 순서로 만든다. 조리대에 바로 접근하면 제작되지 않는다.
- 고등어 조리대 Lv.2 강화 비용은 12문이다. 결제 가능한 잔액으로 구매 패드에 1초 머물면 제작시간이 3.2초에서 3.0초로 줄고, 이후 생성된 주문의 판매가는 6문에서 7문으로 오른다.
- 좌석 2의 비용은 24문이다. 결제 가능한 잔액으로 좌석 구매 패드에 1초 머물면 즉시 설치되고, 대기열의 첫 손님이 새 좌석에 우선 배정돼 이후 두 손님의 주문을 동시에 받을 수 있다.
- Day 2부터 같은 좌석 패드에서 좌석 3을 65문, 좌석 4를 140문에 순서대로 구매한다. 설치 즉시 충돌·이동 경로와 손님 배정에 반영된다.
- Day 2부터 계란 메뉴를 80문에 해금하고 40문, 90문을 지불해 조리대를 Lv.3까지 강화할 수 있다. 제작시간과 판매가는 Lv.1의 4.0초·10문에서 Lv.3의 3.2초·15문까지 변한다.
- 계란 해금 다음 새벽부터 5인분을 8문에 구매해 `바구니 → 화로 → 식히기 → 보관함` 순서로 준비한다. Day 3부터 재고가 있으면 손님의 약 30%가 계란을 주문하며, `계란 바구니 → 밥통 → 계란 조리대` 순서로 제작·서빙·결제한다.
- 점원 고용 비용은 45문이다. 결제 가능한 잔액으로 점원 패드에 1초 머물면 점원 한 명이 고용된다. 점원은 완성 접시를 예약하고 조리대에서 받아 주문 손님에게 자동 서빙하며, 주인공은 제작과 엽전 회수를 계속 맡는다.
- 영업 중 조리대 강화·좌석·점원을 구매할 때는 다음 날 쌀과 고등어 5인분을 살 수 있도록 최소 10문을 남긴다. 비용은 있지만 밑천이 부족하면 패드가 이유를 표시하고 결제하지 않는다.
- 영업 타이머가 0초가 되거나 `조기 마감`을 2초간 누르면 신규 손님과 주문 전 손님을 마감한다. 판매 재고와 진행 중 주문이 모두 없으면 자동으로 마감하며, 이미 생성된 주문의 제작·서빙·결제는 계속할 수 있다.
- 진행 중인 주문·접시·결제가 모두 끝나면 매출, 판매량, 이탈, 남은 재료와 폐기 원가를 확정하고 한 화면 정산을 표시한다.
- 정산의 다음 단계 버튼은 `state["screen"]="dawn"`으로 바꾸고 Main이 `DawnScreen`을 생성한다.
- 새벽 시장에서는 쌀 5인분을 4문, 고등어 5인분을 6문, 해금된 계란 5인분을 8문에 반복 구매하며 준비 확정 전에는 이번 구매를 전액 되돌릴 수 있다.
- 구매 확정 후 쌀은 `쌀가마 → 씻기 → 밥 짓기 → 밥통`, 고등어는 `생선 상자 → 세척 → 손질 → 얼음 상자`, 계란은 `바구니 → 화로 → 식히기 → 보관함` 순으로 배치 전체를 준비한다.
- 두 배치를 각각 5인분 이상 완료하면 인자 없는 화면 전환 신호로 `DayScreen`을 다시 생성하며, Day 2의 5분 영업 화면에 진입한 뒤 자동 저장을 재개한다.
- 상태 기반 P0 회귀는 Day 1의 20접시 판매·성장 구매부터 정산·시장·준비·Day 2 저장 재로드까지 3회 연속 검증한다.
- 화면 노드 회귀는 손님 10명의 착석·주문·식사·결제·퇴장과 같은 좌석 재사용 후 고객·대기열·주문·결제 상태가 남지 않는지 검증한다.
- 실제 이동 회귀는 고등어 4접시의 주문·재료·밥·조리·서빙·결제를 거쳐 운영자금 10문을 남기고 첫 조리대 강화를 60초 안에 구매하는지 검증한다.
- 성장 경로 회귀는 실제 이동으로 14접시를 판매하며 조리대 Lv.2와 좌석 2를 차례로 구매하고, 운영자금 10문을 남긴 첫 점원 고용이 게임 시간 5분 안에 가능한지 검증한다.
- ARM64 Android 디버그 APK를 생성·서명하고 Android 16 에뮬레이터에서 첫 실행, Day 1 진입과 탭 이동을 확인했다. 실제 Android 기기 실행과 3명 이상 플레이테스트도 완료해 2026-07-31 P0를 최종 승인했다.

## 개발 원칙

- 게임 로직, UI, 노드 구성, 밸런스 데이터는 GDScript 중심으로 작성한다.
- 새 `.tscn` 파일은 만들기 전에 사용자 승인을 받는다. 기존 `srcs/main.tscn`은 부트스트랩으로 유지한다.
- Day, 영업 단계, 시간과 타이머, 통화, 재고, 해금 및 진행도 같은 전역 상태는 `GameManager`가 소유한다.
- `SaveManager`는 `GameManager` 상태를 단일 슬롯에 기록하며, `Main`은 낮 영업 중 30초 주기와 낮 단계 경계에서 저장하고 복구한다. 새벽 시장에서는 저장하지 않는다.
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
│   ├── dawn/
│   │   ├── dawn_preparation_station.gd
│   │   └── dawn_purchase_pad.gd
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
│   │   ├── day_server.gd
│   │   ├── day_seat_purchase_pad.gd
│   │   ├── day_staff_hire_pad.gd
│   │   ├── day_upgrade_pad.gd
│   │   └── mackerel_station.gd
│   ├── globals/
│   │   ├── game_manager.gd
│   │   └── save_manager.gd
│   ├── screens/
│   │   ├── day_screen.gd
│   │   ├── dawn_screen.gd
│   │   └── loading_screen.gd
│   ├── main.gd        # 부트스트랩 스크립트
│   └── main.tscn      # 기존 부트스트랩 장면
├── tests/             # GUT 프로젝트 테스트
├── .gutconfig.json
├── export_presets.cfg # ARM64 Android 디버그 프리셋
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

Android SDK와 Godot 4.7.1 Android 내보내기 템플릿을 설치한 환경에서는 다음 명령으로 서명된 디버그 APK를 만든다. 생성물은 `build/` 아래에 놓이며 Git에 포함하지 않는다.

```bash
mkdir -p build/android
./godot --headless --path "$PWD" \
  --export-debug Android build/android/street-debug.apk
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
