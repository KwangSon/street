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
	assert_eq(state["day_runtime"]["carried_item"]["count"], 0)
	assert_true(state["day_runtime"]["customers"].is_empty())
	assert_true(state["day_runtime"]["seat_assignments"].is_empty())
	assert_true(state["day_runtime"]["orders"].is_empty())


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


func test_apply_loaded_state_adds_missing_day_runtime() -> void:
	var source_state: Dictionary = (
		GameManager.create_default_game_state()
	)
	source_state.erase("day_runtime")
	source_state["future_data"] = {"keep": true}

	assert_true(GameManager.apply_loaded_game_state(source_state))
	assert_true(GameManager.state["day_runtime"]["orders"].is_empty())
	assert_true(GameManager.state["future_data"]["keep"])


func test_order_requires_mackerel_then_rice_before_crafting() -> void:
	GameManager.state = GameManager.create_default_game_state()
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
	var ready_inventory: Dictionary = (
		GameManager.state["inventory"]["ready"]
	)

	assert_false(
		GameManager.try_collect_mackerel_for_order()
	)
	assert_true(GameManager.try_accept_waiting_order(customer_id))
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_MACKEREL
	)
	assert_false(GameManager.try_collect_rice_for_order())

	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_eq(ready_inventory["mackerel"], 19)
	assert_eq(ready_inventory["rice"], 20)
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_RICE
	)
	assert_true(GameManager.try_collect_rice_for_order())
	assert_eq(ready_inventory["rice"], 19)
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_READY_TO_COOK
	)
	assert_true(GameManager.try_start_active_order_craft())
	assert_true(GameManager.complete_active_order_craft())
	assert_eq(
		GameManager.get_carried_item()["kind"],
		GameManager.CARRIED_KIND_PLATE
	)
	assert_eq(
		GameManager.get_day_order(customer_id)["status"],
		GameManager.ORDER_READY_TO_SERVE
	)


func test_missing_rice_does_not_consume_mackerel() -> void:
	GameManager.state = GameManager.create_default_game_state()
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
	assert_true(GameManager.try_accept_waiting_order(customer_id))
	var ready_inventory: Dictionary = (
		GameManager.state["inventory"]["ready"]
	)
	ready_inventory["rice"] = 0

	assert_false(GameManager.try_collect_mackerel_for_order())
	assert_eq(ready_inventory["mackerel"], 20)
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_MACKEREL
	)


func test_customer_reserves_one_seat_and_creates_mackerel_order() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var first_customer_id: String = GameManager.create_day_customer()
	var second_customer_id: String = GameManager.create_day_customer()

	assert_eq(first_customer_id, "customer_1")
	assert_eq(second_customer_id, "customer_2")
	assert_true(
		GameManager.try_assign_customer_to_seat(
			first_customer_id,
			"seat_1"
		)
	)
	assert_false(
		GameManager.try_assign_customer_to_seat(
			second_customer_id,
			"seat_1"
		)
	)
	assert_true(
		GameManager.mark_customer_seated(
			first_customer_id,
			GameManager.MENU_MACKEREL
		)
	)

	var first_customer: Dictionary = (
		GameManager.get_day_customer(first_customer_id)
	)
	assert_eq(
		first_customer["state"],
		GameManager.CUSTOMER_WAITING_FOR_ORDER
	)
	assert_eq(first_customer["seat_id"], "seat_1")
	assert_eq(first_customer["menu"], GameManager.MENU_MACKEREL)
	var waiting_orders: Array[Dictionary] = (
		GameManager.get_waiting_orders()
	)
	assert_eq(waiting_orders.size(), 1)
	assert_eq(
		waiting_orders[0]["customer_id"],
		first_customer_id
	)


func test_locked_egg_menu_cannot_be_ordered() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var customer_id: String = GameManager.create_day_customer()
	assert_true(
		GameManager.try_assign_customer_to_seat(
			customer_id,
			"seat_1"
		)
	)

	assert_false(
		GameManager.mark_customer_seated(
			customer_id,
			GameManager.MENU_EGG
		)
	)
	assert_true(GameManager.get_waiting_orders().is_empty())
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_MOVING_TO_SEAT
	)


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
