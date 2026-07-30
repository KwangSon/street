extends GutTest

const DayPlayerScript: Script = preload(
	"res://srcs/day/day_player.gd"
)
const MackerelStationScript: Script = preload(
	"res://srcs/day/mackerel_station.gd"
)


func before_each() -> void:
	GameManager.state = GameManager.create_default_game_state()


func after_each() -> void:
	GameManager.state = {}


func test_entering_station_reserves_both_ingredients() -> void:
	var fixture: Dictionary = await _create_fixture()
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)

	assert_true(station.is_crafting_reserved())
	assert_eq(
		station.get_station_state(),
		MackerelStation.StationState.CRAFTING
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 19)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		19
	)


func test_crafting_twenty_plates_never_over_consumes() -> void:
	var fixture: Dictionary = await _create_fixture(0.01)
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)
	station.interaction_tick(player, 0.21)

	assert_eq(
		GameManager.get_completed_plate_count(
			GameManager.MENU_MACKEREL
		),
		20
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 0)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		0
	)
	assert_false(station.is_crafting_reserved())
	assert_eq(
		station.get_station_state(),
		MackerelStation.StationState.READY
	)


func test_leaving_pauses_and_reentering_resumes_reserved_craft() -> void:
	var ready_inventory: Dictionary = (
		GameManager.state["inventory"]["ready"]
	)
	ready_inventory["rice"] = 1
	ready_inventory["mackerel"] = 1
	var fixture: Dictionary = await _create_fixture(0.1)
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)
	station.interaction_tick(player, 0.04)
	var paused_progress: float = station.get_craft_progress()
	station.interaction_exited(player)
	station.interaction_tick(player, 1.0)

	assert_almost_eq(
		station.get_craft_progress(),
		paused_progress,
		0.0001
	)
	assert_true(station.is_crafting_reserved())

	station.interaction_entered(player)
	station.interaction_tick(player, 0.07)

	assert_eq(
		GameManager.get_completed_plate_count(
			GameManager.MENU_MACKEREL
		),
		1
	)
	assert_false(station.is_crafting_reserved())
	assert_eq(ready_inventory["rice"], 0)
	assert_eq(ready_inventory["mackerel"], 0)


func test_ready_plate_is_picked_up_before_new_craft() -> void:
	GameManager.add_completed_plate(GameManager.MENU_MACKEREL)
	var fixture: Dictionary = await _create_fixture()
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)

	assert_eq(
		GameManager.get_completed_plate_count(
			GameManager.MENU_MACKEREL
		),
		0
	)
	assert_eq(
		player.get_carried_item()["menu"],
		GameManager.MENU_MACKEREL
	)
	assert_true(player.get_node("CarriedItem").visible)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 20)
	assert_false(station.is_crafting_reserved())


func test_carrying_plate_prevents_new_craft() -> void:
	GameManager.add_completed_plate(GameManager.MENU_MACKEREL)
	assert_true(
		GameManager.try_take_completed_plate(
			GameManager.MENU_MACKEREL
		)
	)
	var fixture: Dictionary = await _create_fixture()
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)

	assert_false(station.is_crafting_reserved())
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 20)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		20
	)


func _create_fixture(
	craft_duration: float = MackerelStation.DEFAULT_CRAFT_DURATION
) -> Dictionary:
	var fixture_root: Node2D = Node2D.new()
	add_child_autofree(fixture_root)

	var player: DayPlayer = DayPlayerScript.new()
	fixture_root.add_child(player)

	var station: MackerelStation = MackerelStationScript.new()
	station.craft_duration = craft_duration
	fixture_root.add_child(station)
	await wait_process_frames(1)
	return {
		"player": player,
		"station": station,
	}
