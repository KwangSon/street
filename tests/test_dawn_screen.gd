extends GutTest

const DawnScreenScript: Script = preload(
	"res://srcs/screens/dawn_screen.gd"
)
const TEST_PATH: String = "user://street_test_dawn.json"


func before_each() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["screen"] = GameManager.SCREEN_DAWN
	GameManager.state["phase"] = GameManager.PHASE_MARKET
	GameManager.state["currency"] = 10
	GameManager.state["inventory"]["raw"] = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	GameManager.ensure_dawn_runtime_state()
	_cleanup_test_files()


func after_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func test_signal_has_no_arguments() -> void:
	var screen: Node = DawnScreenScript.new()
	var signal_arguments: Array = []
	for signal_data: Dictionary in screen.get_signal_list():
		if signal_data["name"] == "screen_change_requested":
			signal_arguments = signal_data["args"]
			break

	assert_eq(signal_arguments.size(), 0)
	screen.free()


func test_builds_portrait_market_with_locked_egg_purchase_pad() -> void:
	var screen: DawnScreen = await _create_screen()

	assert_eq(DawnScreen.VIEWPORT_SIZE, Vector2(720.0, 1280.0))
	assert_not_null(screen.get_node("World/Player"))
	assert_not_null(screen.get_node("World/InteractionController"))
	assert_not_null(screen.get_rice_purchase_pad())
	assert_not_null(screen.get_mackerel_purchase_pad())
	assert_not_null(screen.get_egg_purchase_pad())
	assert_false(screen.get_egg_purchase_pad().visible)
	assert_not_null(screen.get_node("FixedUI/HUD"))
	assert_not_null(screen.get_node("FixedUI/ActionPanel"))
	assert_true(
		screen.get_node(
			"FixedUI/ActionPanel/PrepareButton"
		).disabled
	)
	assert_false(
		screen.get_preparation_station("rice", 0).visible
	)
	assert_false(
		screen.get_preparation_station("egg", 0).visible
	)


func test_tap_moves_player_but_drag_does_not() -> void:
	var screen: DawnScreen = await _create_screen()
	var destination: Vector2 = Vector2(360.0, 700.0)

	screen._input(_touch_event(1, destination, true))
	screen._input(_touch_event(1, destination, false))
	assert_true(screen.get_player().has_destination())
	assert_eq(screen.get_player().get_destination(), destination)

	screen.get_player().clear_path()
	var drag_start: Vector2 = Vector2(300.0, 700.0)
	screen._input(_touch_event(2, drag_start, true))
	screen._input(
		_touch_drag_event(
			2,
			drag_start + Vector2(20.0, 0.0)
		)
	)
	screen._input(
		_touch_event(
			2,
			drag_start + Vector2(20.0, 0.0),
			false
		)
	)
	assert_false(screen.get_player().has_destination())


func test_rice_pad_buys_bundle_after_one_second() -> void:
	var screen: DawnScreen = await _create_screen()
	screen.get_player().position = (
		screen.get_rice_purchase_pad().position
	)

	await wait_physics_frames(70)

	assert_eq(GameManager.state["currency"], 6)
	assert_eq(GameManager.state["inventory"]["raw"]["rice"], 5)
	assert_eq(GameManager.get_market_purchases()["rice"], 5)
	assert_eq(
		screen.get_node("FixedUI/HUD/CurrencyLabel").text,
		"6문"
	)


func test_mackerel_pad_repeats_each_second_until_funds_run_out() -> void:
	var screen: DawnScreen = await _create_screen()
	screen.get_player().position = (
		screen.get_mackerel_purchase_pad().position
	)

	await wait_physics_frames(130)

	assert_eq(GameManager.state["currency"], 4)
	assert_eq(
		GameManager.state["inventory"]["raw"]["mackerel"],
		5
	)
	assert_eq(GameManager.get_market_purchases()["mackerel"], 5)


func test_refund_button_restores_all_market_purchases() -> void:
	var screen: DawnScreen = await _create_screen()
	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))
	assert_false(screen.get_refund_button().disabled)

	screen.get_refund_button().pressed.emit()

	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.state["inventory"]["raw"]["rice"], 0)
	assert_eq(
		GameManager.state["inventory"]["raw"]["mackerel"],
		0
	)
	assert_true(screen.get_refund_button().disabled)
	assert_string_contains(
		screen.get_node(
			"FixedUI/ActionPanel/StatusLabel"
		).text,
		"모두 되돌렸습니다"
	)


func test_unlocked_egg_purchase_and_preparation_reaches_day_two() -> void:
	GameManager.state["progression"]["egg_station_level"] = 1
	GameManager.state["currency"] = 18
	var screen: DawnScreen = await _create_screen()
	var player: DayPlayer = screen.get_player()

	assert_true(screen.get_egg_purchase_pad().visible)
	player.position = screen.get_egg_purchase_pad().position
	await wait_physics_frames(70)

	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.state["inventory"]["raw"]["egg"], 5)
	assert_eq(GameManager.get_market_purchases()["egg"], 5)
	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))
	assert_false(screen.get_prepare_button().disabled)
	screen.get_prepare_button().pressed.emit()

	assert_eq(GameManager.state["phase"], GameManager.PHASE_PREP)
	assert_true(screen.get_preparation_station("egg", 0).visible)
	for material_id: String in ["rice", "mackerel", "egg"]:
		for step_index: int in range(4):
			var station: DawnPreparationStation = (
				screen.get_preparation_station(
					material_id,
					step_index
				)
			)
			station.interaction_entered(player)
			station.interaction_tick(player, 1.1)

	assert_eq(GameManager.state["inventory"]["ready"]["egg"], 5)
	assert_false(screen.get_prepare_button().disabled)
	screen.get_prepare_button().pressed.emit()

	assert_eq(GameManager.state["day"], 2)
	assert_eq(GameManager.state["screen"], GameManager.SCREEN_DAY)
	assert_eq(GameManager.state["inventory"]["ready"]["egg"], 5)


func test_prepare_button_confirms_market_without_saving() -> void:
	var screen: DawnScreen = await _create_screen()
	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))
	assert_false(screen.get_prepare_button().disabled)

	screen.get_prepare_button().pressed.emit()

	assert_eq(GameManager.state["phase"], GameManager.PHASE_PREP)
	assert_false(screen.get_rice_purchase_pad().visible)
	assert_false(screen.get_mackerel_purchase_pad().visible)
	assert_true(screen.get_preparation_station("rice", 0).visible)
	assert_false(screen.get_refund_button().visible)
	assert_eq(screen.get_prepare_button().text, "준비 완료 · Day 시작")
	assert_true(screen.get_prepare_button().disabled)
	assert_false(FileAccess.file_exists(TEST_PATH))


func test_preparation_stations_enforce_order_and_start_day_two() -> void:
	GameManager.state["inventory"]["ready"] = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))
	assert_true(GameManager.confirm_market_purchases())
	var screen: DawnScreen = await _create_screen()
	var player: DayPlayer = screen.get_player()

	var wrong_station: DawnPreparationStation = (
		screen.get_preparation_station("rice", 1)
	)
	wrong_station.interaction_entered(player)
	wrong_station.interaction_tick(player, 1.1)
	assert_eq(GameManager.get_dawn_prep_next_step("rice"), 0)

	for material_id: String in ["rice", "mackerel"]:
		for step_index: int in range(4):
			var station: DawnPreparationStation = (
				screen.get_preparation_station(
					material_id,
					step_index
				)
			)
			station.interaction_entered(player)
			station.interaction_tick(player, 1.1)
			assert_eq(
				GameManager.get_dawn_prep_next_step(
					material_id
				),
				step_index + 1
			)

	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 5)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		5
	)
	assert_false(screen.get_prepare_button().disabled)
	watch_signals(screen)

	screen.get_prepare_button().pressed.emit()

	assert_eq(GameManager.state["day"], 2)
	assert_eq(GameManager.state["screen"], GameManager.SCREEN_DAY)
	assert_eq(GameManager.state["phase"], GameManager.PHASE_SERVICE)
	assert_signal_emitted(screen, "screen_change_requested")
	assert_false(FileAccess.file_exists(TEST_PATH))


func _create_screen() -> DawnScreen:
	var screen: DawnScreen = DawnScreenScript.new()
	add_child_autofree(screen)
	await wait_process_frames(1)
	return screen


func _touch_event(
	pointer_id: int,
	position: Vector2,
	pressed: bool
) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = pointer_id
	event.position = position
	event.pressed = pressed
	return event


func _touch_drag_event(
	pointer_id: int,
	position: Vector2
) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = pointer_id
	event.position = position
	return event


func _cleanup_test_files() -> void:
	_remove_file(TEST_PATH)
	_remove_file(TEST_PATH + SaveManager.TEMP_SUFFIX)
	_remove_file(TEST_PATH + SaveManager.CORRUPT_SUFFIX)


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
