extends GutTest

const TEST_PATH: String = "user://street_test_save_manager.json"


func before_each() -> void:
	_cleanup_test_files()


func after_each() -> void:
	_cleanup_test_files()


func test_load_reports_missing_file() -> void:
	var result: Dictionary = SaveManager.load_game_state(TEST_PATH)

	assert_eq(result["status"], SaveManager.LoadStatus.NOT_FOUND)
	assert_true(result["state"].is_empty())


func test_save_and_load_round_trip_dictionary() -> void:
	var state: Dictionary = GameManager.create_default_game_state()
	state["future_data"] = {
		"enabled": true,
		"values": [1, 2, 3],
	}

	assert_eq(SaveManager.save_game_state(state, TEST_PATH), OK)
	var result: Dictionary = SaveManager.load_game_state(TEST_PATH)

	assert_eq(result["status"], SaveManager.LoadStatus.OK)
	assert_eq(result["state"]["screen"], GameManager.SCREEN_DAY)
	assert_eq(result["state"]["future_data"]["enabled"], true)
	assert_eq(result["state"]["future_data"]["values"].size(), 3)


func test_second_save_replaces_first_save() -> void:
	var first_state: Dictionary = GameManager.create_default_game_state()
	var second_state: Dictionary = GameManager.create_default_game_state()
	second_state["day"] = 2

	assert_eq(SaveManager.save_game_state(first_state, TEST_PATH), OK)
	assert_eq(SaveManager.save_game_state(second_state, TEST_PATH), OK)

	var result: Dictionary = SaveManager.load_game_state(TEST_PATH)
	assert_eq(result["status"], SaveManager.LoadStatus.OK)
	assert_eq(int(result["state"]["day"]), 2)


func test_load_reports_invalid_json() -> void:
	_write_text(TEST_PATH, "{not valid json")

	var result: Dictionary = SaveManager.load_game_state(TEST_PATH)

	assert_eq(result["status"], SaveManager.LoadStatus.INVALID_JSON)


func test_load_rejects_non_dictionary_root() -> void:
	_write_text(TEST_PATH, "[1, 2, 3]")

	var result: Dictionary = SaveManager.load_game_state(TEST_PATH)

	assert_eq(result["status"], SaveManager.LoadStatus.INVALID_DATA)


func test_save_rejects_non_json_value() -> void:
	var invalid_state: Dictionary = {
		"position": Vector2.ONE,
	}

	assert_eq(
		SaveManager.save_game_state(invalid_state, TEST_PATH),
		ERR_INVALID_DATA
	)
	assert_false(FileAccess.file_exists(TEST_PATH))


func test_backup_moves_invalid_save() -> void:
	_write_text(TEST_PATH, "{not valid json")

	assert_eq(SaveManager.backup_invalid_save(TEST_PATH), OK)
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_true(
		FileAccess.file_exists(TEST_PATH + SaveManager.CORRUPT_SUFFIX)
	)


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
