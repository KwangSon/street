extends GutTest


func before_each() -> void:
	GameManager.state = {}


func after_each() -> void:
	GameManager.state = {}


func test_default_state_starts_first_day_service() -> void:
	var state: Dictionary = GameManager.create_default_game_state()

	assert_eq(state["save_version"], GameManager.SAVE_VERSION)
	assert_eq(state["screen"], GameManager.SCREEN_DAY)
	assert_eq(state["phase"], GameManager.PHASE_SERVICE)
	assert_eq(state["day"], 1)
	assert_eq(state["currency"], 0)
	assert_eq(state["inventory"]["ready"]["rice"], 20)
	assert_eq(state["inventory"]["ready"]["mackerel"], 20)


func test_apply_loaded_state_deep_copies_and_preserves_extra_keys() -> void:
	var source_state: Dictionary = GameManager.create_default_game_state()
	source_state["future_data"] = {"value": 7}

	assert_true(GameManager.apply_loaded_game_state(source_state))
	source_state["future_data"]["value"] = 99

	assert_eq(GameManager.state["future_data"]["value"], 7)


func test_apply_loaded_state_normalizes_json_numbers() -> void:
	var source_state: Dictionary = GameManager.create_default_game_state()
	source_state["save_version"] = 1.0
	source_state["day"] = 2.0

	assert_true(GameManager.apply_loaded_game_state(source_state))
	assert_eq(typeof(GameManager.state["save_version"]), TYPE_INT)
	assert_eq(typeof(GameManager.state["day"]), TYPE_INT)
	assert_eq(GameManager.state["day"], 2)


func test_apply_loaded_state_rejects_missing_required_key() -> void:
	var source_state: Dictionary = GameManager.create_default_game_state()
	source_state.erase("screen")

	assert_false(GameManager.apply_loaded_game_state(source_state))
	assert_true(GameManager.state.is_empty())


func test_apply_loaded_state_rejects_invalid_screen_phase_pair() -> void:
	var source_state: Dictionary = GameManager.create_default_game_state()
	source_state["screen"] = GameManager.SCREEN_DAWN
	source_state["phase"] = GameManager.PHASE_SERVICE

	assert_false(GameManager.apply_loaded_game_state(source_state))
	assert_true(GameManager.state.is_empty())


func test_apply_loaded_state_rejects_fractional_day() -> void:
	var source_state: Dictionary = GameManager.create_default_game_state()
	source_state["day"] = 1.5

	assert_false(GameManager.apply_loaded_game_state(source_state))
	assert_true(GameManager.state.is_empty())
