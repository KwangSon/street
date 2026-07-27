extends GutTest

const LoadingScreenScript: Script = preload(
	"res://srcs/screens/loading_screen.gd"
)
const TEST_PATH: String = "user://street_test_loading_screen.json"


func before_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func after_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func test_signal_has_no_arguments() -> void:
	var screen: Node = LoadingScreenScript.new()
	var signal_arguments: Array = []
	for signal_data: Dictionary in screen.get_signal_list():
		if signal_data["name"] == "screen_change_requested":
			signal_arguments = signal_data["args"]
			break

	assert_eq(signal_arguments.size(), 0)
	screen.free()


func test_missing_save_creates_default_state_and_emits() -> void:
	var screen: Control = _create_loading_screen()
	watch_signals(screen)
	add_child_autofree(screen)

	await wait_process_frames(3)

	assert_signal_emit_count(screen, "screen_change_requested", 1)
	assert_eq(
		GameManager.state["screen"],
		GameManager.SCREEN_DAY
	)
	assert_true(FileAccess.file_exists(TEST_PATH))


func test_valid_save_is_loaded_with_extra_data() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	saved_state["future_data"] = {"value": "preserved"}
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var screen: Control = _create_loading_screen()
	watch_signals(screen)
	add_child_autofree(screen)
	await wait_process_frames(3)

	assert_signal_emit_count(screen, "screen_change_requested", 1)
	assert_eq(
		GameManager.state["future_data"]["value"],
		"preserved"
	)


func test_invalid_json_waits_for_new_game_choice() -> void:
	_write_text(TEST_PATH, "{not valid json")

	var screen: Control = _create_loading_screen()
	watch_signals(screen)
	add_child_autofree(screen)
	await wait_process_frames(3)

	var new_game_button: Button = screen.get_node(
		"Center/Content/NewGameButton"
	)
	assert_signal_emit_count(screen, "screen_change_requested", 0)
	assert_true(new_game_button.visible)
	assert_true(GameManager.state.is_empty())


func test_new_game_choice_backs_up_invalid_save_then_emits() -> void:
	_write_text(TEST_PATH, "{not valid json")

	var screen: Control = _create_loading_screen()
	watch_signals(screen)
	add_child_autofree(screen)
	await wait_process_frames(3)

	var new_game_button: Button = screen.get_node(
		"Center/Content/NewGameButton"
	)
	new_game_button.pressed.emit()
	await wait_process_frames(2)

	assert_signal_emit_count(screen, "screen_change_requested", 1)
	assert_true(
		FileAccess.file_exists(TEST_PATH + SaveManager.CORRUPT_SUFFIX)
	)
	assert_true(FileAccess.file_exists(TEST_PATH))
	assert_eq(
		GameManager.state["screen"],
		GameManager.SCREEN_DAY
	)


func test_invalid_required_state_stays_on_loading_screen() -> void:
	var invalid_state: Dictionary = {
		"save_version": 1,
		"screen": "unknown",
		"phase": "service",
		"day": 1,
	}
	assert_eq(SaveManager.save_game_state(invalid_state, TEST_PATH), OK)

	var screen: Control = _create_loading_screen()
	watch_signals(screen)
	add_child_autofree(screen)
	await wait_process_frames(3)

	var new_game_button: Button = screen.get_node(
		"Center/Content/NewGameButton"
	)
	assert_signal_emit_count(screen, "screen_change_requested", 0)
	assert_true(new_game_button.visible)


func _create_loading_screen() -> Control:
	var screen: Control = LoadingScreenScript.new()
	screen.set("save_path", TEST_PATH)
	return screen


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
