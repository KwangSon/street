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


func test_station_does_not_craft_without_order_and_collected_food() -> void:
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


func test_station_rejects_order_before_mackerel_and_rice() -> void:
	var customer_id: String = _create_waiting_order()
	assert_true(GameManager.try_accept_waiting_order(customer_id))
	var fixture: Dictionary = await _create_fixture()
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)

	assert_false(station.is_crafting_reserved())
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_MACKEREL
	)


func test_collected_mackerel_and_rice_start_single_craft() -> void:
	var customer_id: String = _prepare_order_for_cooking()
	var fixture: Dictionary = await _create_fixture(0.1)
	var station: MackerelStation = fixture["station"]
	var player: DayPlayer = fixture["player"]

	station.interaction_entered(player)

	assert_true(station.is_crafting_reserved())
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_COOKING
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 19)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		19
	)

	station.interaction_tick(player, 0.11)

	assert_false(station.is_crafting_reserved())
	assert_eq(
		GameManager.get_carried_item()["kind"],
		GameManager.CARRIED_KIND_PLATE
	)
	assert_eq(
		GameManager.get_carried_item()["customer_id"],
		customer_id
	)
	assert_eq(
		GameManager.get_day_order(customer_id)["status"],
		GameManager.ORDER_READY_TO_SERVE
	)


func test_leaving_pauses_and_reentering_resumes_same_order() -> void:
	var customer_id: String = _prepare_order_for_cooking()
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

	assert_false(station.is_crafting_reserved())
	assert_eq(
		GameManager.get_carried_item()["customer_id"],
		customer_id
	)
	assert_eq(
		GameManager.get_carried_item()["kind"],
		GameManager.CARRIED_KIND_PLATE
	)


func _create_waiting_order() -> String:
	var customer_id: String = GameManager.create_day_customer()
	assert_true(
		GameManager.try_assign_customer_to_seat(
			customer_id,
			"seat_1"
		)
	)
	assert_true(
		GameManager.mark_customer_seated(
			customer_id,
			GameManager.MENU_MACKEREL
		)
	)
	return customer_id


func _prepare_order_for_cooking() -> String:
	var customer_id: String = _create_waiting_order()
	assert_true(GameManager.try_accept_waiting_order(customer_id))
	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_rice_for_order())
	return customer_id


func _create_fixture(
	craft_duration: float = MackerelStation.DEFAULT_CRAFT_DURATION
) -> Dictionary:
	var fixture_root: Node2D = Node2D.new()
	add_child_autofree(fixture_root)

	var player: DayPlayer = DayPlayerScript.new()
	fixture_root.add_child(player)

	var station: MackerelStation = MackerelStationScript.new()
	station.use_game_manager_tuning = false
	station.craft_duration = craft_duration
	fixture_root.add_child(station)
	await wait_process_frames(1)
	return {
		"player": player,
		"station": station,
	}
