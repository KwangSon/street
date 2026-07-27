extends GutTest

const MainScript: Script = preload("res://srcs/main.gd")
const ScreenStubScript: Script = preload(
	"res://tests/fixtures/screen_stub.gd"
)
const TEST_PATH: String = "user://street_test_main.json"


func before_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func after_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func test_main_starts_with_one_loading_screen() -> void:
	var main: Node = _create_main()
	add_child_autofree(main)

	assert_is(main.get_current_screen(), LoadingScreen)
	assert_eq(main.get_child_count(), 1)


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
	assert_eq(main.get_child_count(), 1)


func test_unimplemented_screen_keeps_loading_screen() -> void:
	var saved_state: Dictionary = GameManager.create_default_game_state()
	assert_eq(SaveManager.save_game_state(saved_state, TEST_PATH), OK)

	var main: Node = _create_main()
	add_child_autofree(main)
	await wait_process_frames(3)

	assert_is(main.get_current_screen(), LoadingScreen)
	assert_eq(main.get_child_count(), 1)
	assert_push_error("Screen is not implemented yet: day")


func test_unknown_screen_keeps_current_screen() -> void:
	_write_text(TEST_PATH, "{not valid json")
	var main: Node = _create_main()
	add_child_autofree(main)
	await wait_process_frames(3)
	var original_screen: Node = main.get_current_screen()

	GameManager.state = {"screen": "unknown"}
	original_screen.screen_change_requested.emit()

	assert_same(main.get_current_screen(), original_screen)
	assert_eq(main.get_child_count(), 1)
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
	assert_eq(main.get_child_count(), 1)


func _create_main() -> Node:
	var main: Node = MainScript.new()
	main.set("loading_save_path", TEST_PATH)
	return main


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
