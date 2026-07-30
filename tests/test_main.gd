extends GutTest

const MainScript: Script = preload("res://srcs/main.gd")
const DayScreenScript: Script = preload(
	"res://srcs/screens/day_screen.gd"
)
const DawnScreenScript: Script = preload(
	"res://srcs/screens/dawn_screen.gd"
)
const ScreenStubScript: Script = preload(
	"res://tests/fixtures/screen_stub.gd"
)
const TEST_PATH: String = "user://street_test_main.json"


func before_each() -> void:
	get_tree().paused = false
	GameManager.state = {}
	_cleanup_test_files()


func after_each() -> void:
	get_tree().paused = false
	GameManager.state = {}
	_cleanup_test_files()


func test_main_starts_with_one_loading_screen() -> void:
	var main: Node = _create_main()
	add_child_autofree(main)

	assert_is(main.get_current_screen(), LoadingScreen)
	assert_eq(_count_screen_children(main), 1)
	assert_false(main.get_menu_button().visible)


func test_main_reads_game_state_after_no_argument_signal() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	main._screen_factories[GameManager.SCREEN_DAY] = func() -> Node:
		return ScreenStubScript.new()
	add_child_autofree(main)
	await wait_process_frames(3)

	assert_eq(
		main.get_current_screen().get_script(),
		ScreenStubScript
	)
	assert_eq(_count_screen_children(main), 1)


func test_main_creates_day_screen_after_loading() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	add_child_autofree(main)
	await wait_process_frames(3)

	assert_eq(main.get_current_screen().get_script(), DayScreenScript)
	assert_eq(_count_screen_children(main), 1)


func test_main_creates_dawn_screen_from_market_state() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	saved_state["screen"] = GameManager.SCREEN_DAWN
	saved_state["phase"] = GameManager.PHASE_MARKET
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	add_child_autofree(main)
	await wait_process_frames(3)

	assert_eq(main.get_current_screen().get_script(), DawnScreenScript)
	assert_eq(_count_screen_children(main), 1)
	assert_false(main.get_menu_button().visible)
	assert_true(main.get_autosave_timer().is_stopped())


func test_unknown_screen_keeps_current_screen() -> void:
	_write_text(TEST_PATH, "{not valid json")
	var main: Node = _create_main()
	add_child_autofree(main)
	await wait_process_frames(3)
	var original_screen: Node = main.get_current_screen()

	GameManager.state = {"screen": "unknown"}
	original_screen.screen_change_requested.emit()

	assert_same(main.get_current_screen(), original_screen)
	assert_eq(_count_screen_children(main), 1)
	assert_push_error("Unknown screen in game state: unknown")


func test_old_screen_cannot_trigger_second_transition() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var factory_call_count: Array[int] = [0]
	var main: Node = _create_main()
	main._screen_factories[GameManager.SCREEN_DAY] = func() -> Node:
		factory_call_count[0] += 1
		return ScreenStubScript.new()
	add_child_autofree(main)
	await wait_process_frames(3)

	var old_screen: Node = main.get_current_screen()
	old_screen.screen_change_requested.emit()
	old_screen.screen_change_requested.emit()
	await wait_process_frames(1)

	assert_eq(factory_call_count[0], 2)
	assert_eq(_count_screen_children(main), 1)


func test_menu_button_is_top_left_and_pauses_until_continue() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	main._screen_factories[GameManager.SCREEN_DAY] = func() -> Node:
		return ScreenStubScript.new()
	add_child_autofree(main)
	await wait_process_frames(3)

	var menu_button: Button = main.get_menu_button()
	assert_true(menu_button.visible)
	assert_eq(menu_button.position, Vector2(16.0, 16.0))
	assert_false(main.get_menu_backdrop().visible)

	menu_button.pressed.emit()

	assert_true(get_tree().paused)
	assert_true(main.get_menu_backdrop().visible)
	assert_false(main.get_current_screen().can_process())

	var continue_button: Button = main.get_menu_backdrop().get_node(
		"Panel/MenuContent/ContinueButton"
	)
	continue_button.pressed.emit()

	assert_false(get_tree().paused)
	assert_false(main.get_menu_backdrop().visible)
	assert_true(main.get_current_screen().can_process())


func test_new_game_confirmation_overwrites_the_single_save_slot() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	saved_state["day"] = 3
	saved_state["currency"] = 147
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	main._screen_factories[GameManager.SCREEN_DAY] = func() -> Node:
		return ScreenStubScript.new()
	add_child_autofree(main)
	await wait_process_frames(3)

	main.get_menu_button().pressed.emit()
	var new_game_button: Button = main.get_menu_backdrop().get_node(
		"Panel/MenuContent/NewGameButton"
	)
	new_game_button.pressed.emit()
	assert_true(main.get_new_game_confirmation().visible)

	var confirm_button: Button = (
		main.get_new_game_confirmation().get_node("ConfirmButton")
	)
	confirm_button.pressed.emit()
	await wait_process_frames(1)

	assert_false(get_tree().paused)
	assert_eq(int(GameManager.state["day"]), 1)
	assert_eq(int(GameManager.state["currency"]), 0)
	assert_eq(SaveManager.SAVE_SLOT_COUNT, 1)
	var loaded_result: Dictionary = SaveManager.load_game_state(
		TEST_PATH
	)
	assert_eq(loaded_result["status"], SaveManager.LoadStatus.OK)
	assert_eq(int(loaded_result["state"]["day"]), 1)
	assert_eq(int(loaded_result["state"]["currency"]), 0)


func test_periodic_autosave_replaces_the_single_slot() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	main.set("autosave_interval_seconds", 0.05)
	main._screen_factories[GameManager.SCREEN_DAY] = func() -> Node:
		return ScreenStubScript.new()
	add_child_autofree(main)
	await wait_process_frames(3)

	GameManager.state["currency"] = 73
	await wait_seconds(0.12)

	var loaded_result: Dictionary = SaveManager.load_game_state(
		TEST_PATH
	)
	assert_eq(loaded_result["status"], SaveManager.LoadStatus.OK)
	assert_eq(int(loaded_result["state"]["currency"]), 73)
	assert_false(main.get_autosave_timer().is_stopped())


func test_dawn_market_has_no_menu_or_periodic_save() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	saved_state["screen"] = GameManager.SCREEN_DAWN
	saved_state["phase"] = GameManager.PHASE_MARKET
	saved_state["currency"] = 11
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	main.set("autosave_interval_seconds", 0.05)
	add_child_autofree(main)
	await wait_process_frames(3)

	assert_false(main.get_menu_button().visible)
	assert_true(main.get_autosave_timer().is_stopped())
	GameManager.state["currency"] = 77
	await wait_seconds(0.12)

	var loaded_result: Dictionary = SaveManager.load_game_state(
		TEST_PATH
	)
	assert_eq(loaded_result["status"], SaveManager.LoadStatus.OK)
	assert_eq(int(loaded_result["state"]["currency"]), 11)


func _create_main() -> Node:
	var main: Node = MainScript.new()
	main.set("loading_save_path", TEST_PATH)
	return main


func _count_screen_children(main: Node) -> int:
	var screen_count: int = 0
	for child: Node in main.get_children():
		if child == main.get_autosave_timer():
			continue
		if child.name == "GameMenu":
			continue
		screen_count += 1
	return screen_count


func _write_text(path: String, content: String) -> void:
	var test_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(test_file)
	test_file.store_string(content)
	test_file.close()


func _cleanup_test_files() -> void:
	_remove_file(TEST_PATH)
	_remove_file(TEST_PATH + SaveManager.TEMP_SUFFIX)
	_remove_file(TEST_PATH + SaveManager.CORRUPT_SUFFIX)


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
