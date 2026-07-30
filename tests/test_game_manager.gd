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
	assert_true(state["day_runtime"]["customer_queue"].is_empty())
	assert_true(state["day_runtime"]["seat_assignments"].is_empty())
	assert_true(state["day_runtime"]["orders"].is_empty())
	assert_true(state["day_runtime"]["payments"].is_empty())
	assert_true(state["day_runtime"]["station_item"].is_empty())
	assert_true(
		state["day_runtime"]["server_carried_item"].is_empty()
	)
	assert_true(state["day_runtime"]["accepting_customers"])


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


func test_apply_loaded_state_preserves_egg_and_four_seat_growth() -> void:
	var source_state: Dictionary = GameManager.create_default_game_state()
	source_state["day"] = 3
	source_state["progression"]["egg_station_level"] = 3
	source_state["progression"]["seats"] = 4

	assert_true(GameManager.apply_loaded_game_state(source_state))
	assert_eq(GameManager.get_egg_station_level(), 3)
	assert_eq(GameManager.get_egg_craft_duration(), 3.2)
	assert_eq(GameManager.get_egg_sale_price(), 15)
	assert_eq(GameManager.get_unlocked_seat_count(), 4)


func test_apply_loaded_state_adds_missing_day_runtime() -> void:
	var source_state: Dictionary = (
		GameManager.create_default_game_state()
	)
	source_state.erase("day_runtime")
	source_state["future_data"] = {"keep": true}

	assert_true(GameManager.apply_loaded_game_state(source_state))
	assert_true(GameManager.state["day_runtime"]["orders"].is_empty())
	assert_true(GameManager.state["future_data"]["keep"])


func test_service_timer_closes_customer_entry_at_zero() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["service_time_remaining"] = 0.05

	assert_true(GameManager.tick_service_time(0.02))
	assert_almost_eq(
		GameManager.state["service_time_remaining"],
		0.03,
		0.0001
	)
	assert_true(GameManager.is_accepting_customers())

	assert_true(GameManager.tick_service_time(0.05))
	assert_eq(GameManager.state["service_time_remaining"], 0.0)
	assert_false(GameManager.is_accepting_customers())
	assert_false(
		GameManager.state["day_runtime"]["accepting_customers"]
	)
	assert_false(GameManager.tick_service_time(1.0))


func test_service_timer_does_not_run_outside_day_service() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["phase"] = GameManager.PHASE_SETTLEMENT

	assert_false(GameManager.tick_service_time(10.0))
	assert_eq(GameManager.state["service_time_remaining"], 330.0)


func test_early_close_sets_timer_to_zero_and_closes_entry() -> void:
	GameManager.state = GameManager.create_default_game_state()

	assert_true(GameManager.request_early_close())
	assert_eq(GameManager.state["service_time_remaining"], 0.0)
	assert_false(GameManager.is_accepting_customers())
	assert_false(GameManager.request_early_close())


func test_exhausted_service_closes_only_without_active_order() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var ready_inventory: Dictionary = (
		GameManager.state["inventory"]["ready"]
	)
	ready_inventory["rice"] = 0
	ready_inventory["mackerel"] = 0

	assert_true(GameManager.try_close_exhausted_service())
	assert_false(GameManager.is_accepting_customers())

	GameManager.state = GameManager.create_default_game_state()
	ready_inventory = GameManager.state["inventory"]["ready"]
	ready_inventory["rice"] = 0
	ready_inventory["mackerel"] = 0
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

	assert_false(GameManager.try_close_exhausted_service())
	assert_true(GameManager.is_accepting_customers())
	assert_eq(GameManager.state["service_time_remaining"], 330.0)


func test_dismissing_unordered_customer_releases_reserved_seat() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var customer_id: String = GameManager.create_day_customer()
	assert_true(
		GameManager.try_assign_customer_to_seat(
			customer_id,
			"seat_1"
		)
	)

	assert_true(GameManager.dismiss_unordered_customer(customer_id))
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_LEAVING
	)
	assert_true(
		GameManager.state["day_runtime"]["seat_assignments"].is_empty()
	)
	assert_eq(GameManager.state["day_stats"]["departed_customers"], 1)
	assert_false(GameManager.dismiss_unordered_customer(customer_id))


func test_closing_dismisses_queued_customer_as_departed() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var customer_id: String = GameManager.create_day_customer()
	assert_true(GameManager.try_enqueue_day_customer(customer_id))
	GameManager.state["service_time_remaining"] = 0.0
	assert_false(GameManager.tick_service_time(0.1))

	assert_false(GameManager.is_accepting_customers())
	assert_true(GameManager.dismiss_queued_customer(customer_id))
	assert_true(GameManager.get_customer_queue().is_empty())
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_LEAVING
	)
	assert_eq(GameManager.state["day_stats"]["departed_customers"], 1)
	assert_false(GameManager.dismiss_queued_customer(customer_id))


func test_settlement_finalizes_sales_departures_and_waste_once() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["service_time_remaining"] = 0.0
	GameManager.state["day_runtime"]["accepting_customers"] = false
	GameManager.state["inventory"]["ready"] = {
		"rice": 4,
		"mackerel": 3,
		"egg": 2,
	}
	GameManager.state["inventory"]["raw"] = {
		"rice": 1,
		"mackerel": 2,
		"egg": 3,
	}
	GameManager.state["day_stats"]["plates_sold"] = {
		"mackerel": 2,
		"egg": 1,
	}
	GameManager.state["day_stats"]["revenue"] = 27
	GameManager.state["day_stats"]["departed_customers"] = 2

	assert_true(GameManager.try_begin_settlement())
	assert_eq(GameManager.state["phase"], GameManager.PHASE_SETTLEMENT)
	var summary: Dictionary = GameManager.get_settlement_summary()
	assert_eq(summary["revenue"], 27)
	assert_eq(summary["total_plates"], 3)
	assert_eq(summary["plates_sold"]["mackerel"], 2)
	assert_eq(summary["plates_sold"]["egg"], 1)
	assert_eq(summary["departed_customers"], 2)
	assert_eq(
		summary["waste"],
		{
			"rice": 5,
			"mackerel": 5,
			"egg": 5,
		}
	)
	assert_almost_eq(summary["waste_cost"], 18.0, 0.0001)
	assert_eq(
		GameManager.state["inventory"]["ready"],
		{
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		}
	)
	assert_eq(
		GameManager.state["inventory"]["raw"],
		{
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		}
	)
	assert_eq(
		GameManager.state["totals"]["waste"],
		{
			"rice": 5,
			"mackerel": 5,
			"egg": 5,
		}
	)
	assert_false(GameManager.try_begin_settlement())
	assert_eq(
		GameManager.state["totals"]["waste"]["rice"],
		5
	)

	assert_true(GameManager.request_dawn_after_settlement())
	assert_eq(GameManager.state["screen"], GameManager.SCREEN_DAWN)
	assert_eq(GameManager.state["phase"], GameManager.PHASE_MARKET)
	assert_eq(
		GameManager.get_market_purchases(),
		{
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		}
	)
	assert_false(GameManager.request_dawn_after_settlement())


func test_market_bundles_purchase_and_refund_exactly() -> void:
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

	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_eq(GameManager.state["currency"], 6)
	assert_eq(GameManager.state["inventory"]["raw"]["rice"], 5)
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))
	assert_eq(GameManager.state["currency"], 0)
	assert_eq(
		GameManager.state["inventory"]["raw"]["mackerel"],
		5
	)
	assert_false(GameManager.try_purchase_market_bundle("rice"))
	assert_false(GameManager.try_purchase_market_bundle("unknown"))
	assert_eq(
		GameManager.get_market_purchases(),
		{
			"rice": 5,
			"mackerel": 5,
			"egg": 0,
		}
	)

	assert_true(GameManager.refund_market_purchases())
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.state["inventory"]["raw"]["rice"], 0)
	assert_eq(
		GameManager.state["inventory"]["raw"]["mackerel"],
		0
	)
	assert_eq(
		GameManager.get_market_purchases(),
		{
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		}
	)
	assert_false(GameManager.refund_market_purchases())


func test_market_purchase_rejects_non_market_phase() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["screen"] = GameManager.SCREEN_DAWN
	GameManager.state["phase"] = GameManager.PHASE_PREP
	GameManager.state["currency"] = 10
	GameManager.ensure_dawn_runtime_state()

	assert_false(GameManager.try_purchase_market_bundle("rice"))
	assert_false(GameManager.refund_market_purchases())
	assert_eq(GameManager.state["currency"], 10)


func test_unlocked_egg_can_be_bought_refunded_and_prepared() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["progression"]["egg_station_level"] = 1
	GameManager.state["screen"] = GameManager.SCREEN_DAWN
	GameManager.state["phase"] = GameManager.PHASE_MARKET
	GameManager.state["currency"] = 18
	GameManager.state["inventory"]["ready"] = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	GameManager.state["inventory"]["raw"] = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	GameManager.ensure_dawn_runtime_state()

	assert_true(GameManager.try_purchase_market_bundle("egg"))
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.state["inventory"]["raw"]["egg"], 5)
	assert_true(GameManager.refund_market_purchases())
	assert_eq(GameManager.state["currency"], 18)
	assert_eq(GameManager.state["inventory"]["raw"]["egg"], 0)

	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))
	assert_true(GameManager.try_purchase_market_bundle("egg"))
	assert_eq(GameManager.state["currency"], 0)
	assert_true(GameManager.confirm_market_purchases())
	for material_id: String in ["rice", "mackerel", "egg"]:
		for step_index: int in range(4):
			assert_true(
				GameManager.try_complete_dawn_prep_step(
					material_id,
					step_index
				)
			)
	assert_eq(GameManager.state["inventory"]["ready"]["egg"], 5)
	assert_eq(GameManager.get_dawn_prepared()["egg"], 5)
	assert_true(GameManager.can_finish_dawn_preparation())


func test_locked_egg_cannot_be_bought_at_dawn() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["screen"] = GameManager.SCREEN_DAWN
	GameManager.state["phase"] = GameManager.PHASE_MARKET
	GameManager.state["currency"] = 100
	GameManager.ensure_dawn_runtime_state()

	assert_false(GameManager.try_purchase_market_bundle("egg"))
	assert_eq(GameManager.state["currency"], 100)
	assert_eq(GameManager.state["inventory"]["raw"]["egg"], 0)


func test_dawn_preparation_requires_order_and_starts_day_two() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["screen"] = GameManager.SCREEN_DAWN
	GameManager.state["phase"] = GameManager.PHASE_MARKET
	GameManager.state["currency"] = 10
	GameManager.state["inventory"]["ready"] = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	GameManager.state["inventory"]["raw"] = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	GameManager.state["progression"]["seats"] = 2
	GameManager.ensure_dawn_runtime_state()
	assert_true(GameManager.try_purchase_market_bundle("rice"))
	assert_true(GameManager.try_purchase_market_bundle("mackerel"))

	assert_true(GameManager.can_confirm_market_purchases())
	assert_true(GameManager.confirm_market_purchases())
	assert_eq(GameManager.state["phase"], GameManager.PHASE_PREP)
	assert_false(GameManager.refund_market_purchases())
	assert_false(
		GameManager.try_complete_dawn_prep_step("rice", 1)
	)

	for step_index: int in range(4):
		assert_true(
			GameManager.try_complete_dawn_prep_step(
				"rice",
				step_index
			)
		)
	for step_index: int in range(4):
		assert_true(
			GameManager.try_complete_dawn_prep_step(
				"mackerel",
				step_index
			)
		)

	assert_eq(
		GameManager.get_dawn_prepared(),
		{
			"rice": 5,
			"mackerel": 5,
			"egg": 0,
		}
	)
	assert_eq(GameManager.state["inventory"]["raw"]["rice"], 0)
	assert_eq(
		GameManager.state["inventory"]["raw"]["mackerel"],
		0
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 5)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		5
	)
	assert_true(GameManager.can_finish_dawn_preparation())
	assert_true(GameManager.complete_dawn_and_start_day())
	assert_eq(GameManager.state["day"], 2)
	assert_eq(GameManager.state["screen"], GameManager.SCREEN_DAY)
	assert_eq(GameManager.state["phase"], GameManager.PHASE_SERVICE)
	assert_eq(GameManager.state["service_time_remaining"], 300.0)
	assert_eq(GameManager.state["progression"]["seats"], 2)
	assert_eq(GameManager.state["day_stats"]["revenue"], 0)
	assert_true(GameManager.state["day_runtime"]["customers"].is_empty())
	assert_true(
		GameManager.state["day_runtime"]["accepting_customers"]
	)
	assert_false(GameManager.state.has("dawn_runtime"))
	assert_false(GameManager.complete_dawn_and_start_day())


func test_settlement_waits_until_existing_order_is_cleared() -> void:
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
	GameManager.state["service_time_remaining"] = 0.0
	GameManager.state["day_runtime"]["accepting_customers"] = false

	assert_false(GameManager.try_begin_settlement())
	assert_eq(GameManager.state["phase"], GameManager.PHASE_SERVICE)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 20)


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


func test_mackerel_upgrade_keeps_ten_mon_operating_reserve() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 11

	assert_false(GameManager.try_purchase_mackerel_station_upgrade())
	assert_eq(GameManager.get_mackerel_station_level(), 1)
	assert_eq(GameManager.state["currency"], 11)

	GameManager.state["currency"] = 21
	assert_true(
		GameManager.is_day_growth_purchase_reserve_blocked(12)
	)
	assert_false(GameManager.try_purchase_mackerel_station_upgrade())
	assert_eq(GameManager.get_mackerel_station_level(), 1)
	assert_eq(GameManager.state["currency"], 21)

	GameManager.state["currency"] = 22
	assert_true(GameManager.try_purchase_mackerel_station_upgrade())
	assert_eq(GameManager.get_mackerel_station_level(), 2)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_mackerel_craft_duration(), 3.0)
	assert_eq(GameManager.get_mackerel_sale_price(), 7)
	assert_eq(GameManager.get_mackerel_upgrade_cost(), 0)

	assert_false(GameManager.try_purchase_mackerel_station_upgrade())
	assert_eq(GameManager.get_mackerel_station_level(), 2)
	assert_eq(GameManager.state["currency"], 10)


func test_upgraded_station_order_pays_seven() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 22
	assert_true(GameManager.try_purchase_mackerel_station_upgrade())
	var customer_id: String = _create_ready_plate_order()

	assert_eq(
		GameManager.get_day_order(customer_id)["price"],
		7
	)
	assert_true(GameManager.try_serve_order(customer_id))
	assert_true(GameManager.mark_customer_finished_eating(customer_id))
	assert_eq(GameManager.get_customer_payment(customer_id)["amount"], 7)
	assert_true(GameManager.collect_customer_payment(customer_id))
	assert_eq(GameManager.state["currency"], 17)
	assert_eq(GameManager.state["day_stats"]["revenue"], 7)


func test_egg_station_unlock_and_upgrades_use_documented_costs() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 89

	assert_true(
		GameManager.is_day_growth_purchase_reserve_blocked(80)
	)
	assert_false(GameManager.try_purchase_egg_station_upgrade())
	assert_eq(GameManager.get_egg_station_level(), 0)
	assert_eq(GameManager.state["currency"], 89)

	GameManager.state["currency"] = 100
	assert_false(GameManager.try_purchase_egg_station_upgrade())
	assert_eq(GameManager.state["currency"], 100)

	GameManager.state["day"] = 2
	GameManager.state["currency"] = 90
	assert_true(GameManager.try_purchase_egg_station_upgrade())
	assert_eq(GameManager.get_egg_station_level(), 1)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_egg_craft_duration(), 4.0)
	assert_eq(GameManager.get_egg_sale_price(), 10)
	assert_eq(GameManager.get_egg_upgrade_cost(), 40)

	GameManager.state["currency"] = 50
	assert_true(GameManager.try_purchase_egg_station_upgrade())
	assert_eq(GameManager.get_egg_station_level(), 2)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_egg_craft_duration(), 3.6)
	assert_eq(GameManager.get_egg_sale_price(), 12)
	assert_eq(GameManager.get_egg_upgrade_cost(), 90)

	GameManager.state["currency"] = 100
	assert_true(GameManager.try_purchase_egg_station_upgrade())
	assert_eq(GameManager.get_egg_station_level(), 3)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_egg_craft_duration(), 3.2)
	assert_eq(GameManager.get_egg_sale_price(), 15)
	assert_eq(GameManager.get_egg_upgrade_cost(), 0)
	assert_false(GameManager.try_purchase_egg_station_upgrade())


func test_unlocked_egg_order_consumes_egg_and_pays_egg_price() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["day"] = 2
	GameManager.state["currency"] = 90
	assert_true(GameManager.try_purchase_egg_station_upgrade())
	GameManager.state["inventory"]["ready"] = {
		"rice": 5,
		"mackerel": 0,
		"egg": 5,
	}
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
			GameManager.MENU_EGG
		)
	)
	assert_eq(GameManager.get_day_order(customer_id)["price"], 10)

	assert_true(GameManager.try_accept_waiting_order(customer_id))
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_EGG
	)
	assert_false(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_egg_for_order())
	assert_eq(GameManager.state["inventory"]["ready"]["egg"], 4)
	assert_true(GameManager.try_collect_rice_for_order())
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 4)
	assert_false(
		GameManager.try_start_active_order_craft(
			GameManager.MENU_MACKEREL
		)
	)
	assert_true(
		GameManager.try_start_active_order_craft(
			GameManager.MENU_EGG
		)
	)
	assert_true(
		GameManager.complete_active_order_craft(
			GameManager.MENU_EGG
		)
	)
	assert_eq(
		GameManager.get_carried_item()["menu"],
		GameManager.MENU_EGG
	)
	assert_true(GameManager.try_serve_order(customer_id))
	assert_true(GameManager.mark_customer_finished_eating(customer_id))
	assert_true(GameManager.collect_customer_payment(customer_id))
	assert_eq(GameManager.state["currency"], 20)
	assert_eq(GameManager.state["day_stats"]["plates_sold"]["egg"], 1)
	assert_eq(GameManager.state["day_stats"]["revenue"], 10)
	assert_eq(GameManager.state["totals"]["plates_sold"]["egg"], 1)


func test_unlocked_menu_immediately_uses_seventy_thirty_mix() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["day"] = 2
	GameManager.state["progression"]["egg_station_level"] = 1
	GameManager.state["inventory"]["ready"] = {
		"rice": 20,
		"mackerel": 20,
		"egg": 20,
	}
	var menu_counts: Dictionary = {
		GameManager.MENU_MACKEREL: 0,
		GameManager.MENU_EGG: 0,
	}

	for customer_number: int in range(1, 11):
		var menu_id: String = GameManager.choose_menu_for_customer(
			"customer_%d" % customer_number
		)
		menu_counts[menu_id] = int(menu_counts[menu_id]) + 1

	assert_eq(menu_counts[GameManager.MENU_MACKEREL], 7)
	assert_eq(menu_counts[GameManager.MENU_EGG], 3)


func test_upgrade_rejects_missing_progression_data() -> void:
	GameManager.state = {
		"currency": 22,
	}

	assert_false(GameManager.try_purchase_mackerel_station_upgrade())
	assert_eq(GameManager.state["currency"], 22)


func test_second_seat_costs_twenty_four_and_unlocks_assignment() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var customer_id: String = GameManager.create_day_customer()
	GameManager.state["currency"] = 23

	assert_false(
		GameManager.try_assign_customer_to_seat(
			customer_id,
			"seat_2"
		)
	)
	assert_false(GameManager.try_purchase_second_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 1)
	assert_eq(GameManager.state["currency"], 23)

	GameManager.state["currency"] = 33
	assert_true(
		GameManager.is_day_growth_purchase_reserve_blocked(24)
	)
	assert_false(GameManager.try_purchase_second_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 1)
	assert_eq(GameManager.state["currency"], 33)

	GameManager.state["currency"] = 34
	assert_true(GameManager.try_purchase_second_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 2)
	assert_eq(GameManager.get_second_seat_cost(), 0)
	assert_eq(GameManager.state["currency"], 10)
	assert_true(
		GameManager.try_assign_customer_to_seat(
			customer_id,
			"seat_2"
		)
	)
	assert_false(GameManager.try_purchase_second_seat())
	assert_false(
		GameManager.try_assign_customer_to_seat(
			GameManager.create_day_customer(),
			"seat_3"
		)
	)


func test_third_and_fourth_seats_purchase_in_order() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 34
	assert_eq(GameManager.get_next_seat_cost(), 24)
	assert_true(GameManager.try_purchase_next_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 2)
	assert_eq(GameManager.get_next_seat_cost(), 65)

	GameManager.state["currency"] = 100
	assert_false(GameManager.is_next_seat_purchase_available())
	assert_false(GameManager.try_purchase_next_seat())
	assert_eq(GameManager.state["currency"], 100)

	GameManager.state["currency"] = 74
	assert_true(
		GameManager.is_day_growth_purchase_reserve_blocked(65)
	)
	assert_false(GameManager.try_purchase_next_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 2)

	GameManager.state["day"] = 2
	GameManager.state["currency"] = 75
	assert_true(GameManager.try_purchase_next_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 3)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_next_seat_cost(), 140)

	var third_customer: String = GameManager.create_day_customer()
	assert_true(
		GameManager.try_assign_customer_to_seat(
			third_customer,
			"seat_3"
		)
	)

	GameManager.state["currency"] = 150
	assert_true(GameManager.try_purchase_next_seat())
	assert_eq(GameManager.get_unlocked_seat_count(), 4)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_next_seat_cost(), 0)

	var fourth_customer: String = GameManager.create_day_customer()
	assert_true(
		GameManager.try_assign_customer_to_seat(
			fourth_customer,
			"seat_4"
		)
	)
	assert_false(GameManager.try_purchase_next_seat())


func test_server_costs_forty_five_and_serves_reserved_plate() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 44

	assert_false(GameManager.try_hire_server())
	assert_false(GameManager.is_server_hired())
	assert_eq(GameManager.state["currency"], 44)

	GameManager.state["currency"] = 54
	assert_true(
		GameManager.is_day_growth_purchase_reserve_blocked(45)
	)
	assert_false(GameManager.try_hire_server())
	assert_false(GameManager.is_server_hired())
	assert_eq(GameManager.state["currency"], 54)

	GameManager.state["currency"] = 55
	assert_true(GameManager.try_hire_server())
	assert_true(GameManager.is_server_hired())
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(GameManager.get_server_hire_cost(), 0)
	assert_false(GameManager.try_hire_server())

	var customer_id: String = _create_ready_plate_order()
	assert_false(GameManager.is_player_carrying_item())
	assert_eq(
		GameManager.get_station_item()["customer_id"],
		customer_id
	)
	assert_false(GameManager.try_serve_order(customer_id))

	assert_eq(
		GameManager.try_reserve_ready_plate_for_server(),
		customer_id
	)
	assert_eq(
		GameManager.get_station_item()["reserved_by"],
		"server"
	)
	assert_true(
		GameManager.try_reserve_ready_plate_for_server().is_empty()
	)
	assert_true(
		GameManager.try_server_collect_reserved_plate(customer_id)
	)
	assert_true(GameManager.get_station_item().is_empty())
	assert_eq(
		GameManager.get_server_carried_item()["customer_id"],
		customer_id
	)
	assert_false(GameManager.try_server_serve_order("customer_other"))
	assert_true(GameManager.try_server_serve_order(customer_id))
	assert_true(GameManager.get_server_carried_item().is_empty())
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_EATING
	)


func test_growth_purchases_are_blocked_after_service() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["phase"] = GameManager.PHASE_SETTLEMENT
	GameManager.state["currency"] = 200

	assert_false(GameManager.try_purchase_mackerel_station_upgrade())
	assert_false(GameManager.try_purchase_second_seat())
	assert_false(GameManager.try_purchase_next_seat())
	assert_false(GameManager.try_purchase_egg_station_upgrade())
	assert_false(GameManager.try_hire_server())
	assert_eq(GameManager.state["currency"], 200)
	assert_eq(GameManager.get_mackerel_station_level(), 1)
	assert_eq(GameManager.get_unlocked_seat_count(), 1)
	assert_false(GameManager.is_server_hired())


func test_cancelled_server_delivery_returns_plate_to_station() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 55
	assert_true(GameManager.try_hire_server())
	var customer_id: String = _create_ready_plate_order()
	assert_eq(
		GameManager.try_reserve_ready_plate_for_server(),
		customer_id
	)
	assert_true(
		GameManager.try_server_collect_reserved_plate(customer_id)
	)

	assert_true(
		GameManager.cancel_server_plate_delivery(customer_id)
	)
	assert_true(GameManager.get_server_carried_item().is_empty())
	assert_eq(
		GameManager.get_station_item()["customer_id"],
		customer_id
	)
	assert_eq(
		String(
			GameManager.get_day_order(customer_id).get(
				"reserved_by",
				""
			)
		),
		""
	)


func test_only_matching_customer_receives_finished_plate() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var customer_id: String = _create_ready_plate_order()

	assert_false(GameManager.try_serve_order("customer_other"))
	assert_true(GameManager.try_serve_order(customer_id))
	assert_false(GameManager.is_player_carrying_item())
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_EATING
	)
	assert_eq(
		GameManager.get_day_order(customer_id)["status"],
		GameManager.ORDER_EATING
	)

	assert_true(GameManager.mark_customer_finished_eating(customer_id))
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_WAITING_FOR_PAYMENT
	)
	assert_eq(
		GameManager.get_day_order(customer_id)["status"],
		GameManager.ORDER_WAITING_FOR_PAYMENT
	)
	assert_false(GameManager.mark_customer_finished_eating(customer_id))

	var payment: Dictionary = GameManager.get_customer_payment(
		customer_id
	)
	assert_eq(payment["amount"], GameManager.MACKEREL_PRICE)
	assert_eq(payment["status"], GameManager.PAYMENT_WAITING)
	assert_true(GameManager.collect_customer_payment(customer_id))
	assert_eq(GameManager.state["currency"], 6)
	assert_eq(
		GameManager.state["day_stats"]["plates_sold"]["mackerel"],
		1
	)
	assert_eq(GameManager.state["day_stats"]["revenue"], 6)
	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_LEAVING
	)
	assert_eq(
		GameManager.state["day_runtime"]["seat_assignments"][
			"seat_1"
		],
		customer_id
	)
	assert_true(GameManager.finish_customer_exit(customer_id))
	assert_true(GameManager.get_day_customer(customer_id).is_empty())
	assert_true(GameManager.get_day_order(customer_id).is_empty())
	assert_true(
		GameManager.get_customer_payment(customer_id).is_empty()
	)
	assert_true(
		GameManager.state["day_runtime"]["seat_assignments"].is_empty()
	)


func test_twenty_mackerel_sales_leave_no_stale_runtime_state() -> void:
	GameManager.state = GameManager.create_default_game_state()

	for sale_index: int in range(20):
		var customer_id: String = _create_ready_plate_order()
		assert_true(
			GameManager.try_serve_order(customer_id),
			"sale %d should serve" % sale_index
		)
		assert_true(
			GameManager.mark_customer_finished_eating(customer_id),
			"sale %d should finish eating" % sale_index
		)
		assert_true(
			GameManager.collect_customer_payment(customer_id),
			"sale %d should collect payment" % sale_index
		)
		assert_true(
			GameManager.finish_customer_exit(customer_id),
			"sale %d should release seat" % sale_index
		)

	assert_eq(GameManager.state["currency"], 120)
	assert_eq(
		GameManager.state["day_stats"]["plates_sold"]["mackerel"],
		20
	)
	assert_eq(GameManager.state["day_stats"]["revenue"], 120)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		0
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 0)
	assert_false(GameManager.is_player_carrying_item())
	assert_true(GameManager.get_day_customer_ids().is_empty())
	assert_true(GameManager.state["day_runtime"]["orders"].is_empty())
	assert_true(
		GameManager.state["day_runtime"]["payments"].is_empty()
	)
	assert_true(
		GameManager.state["day_runtime"]["seat_assignments"].is_empty()
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


func test_customer_queue_is_fifo_and_limited_to_three() -> void:
	GameManager.state = GameManager.create_default_game_state()
	var customer_ids: Array[String] = []
	for _index: int in range(4):
		customer_ids.append(GameManager.create_day_customer())

	assert_true(GameManager.try_enqueue_day_customer(customer_ids[0]))
	assert_true(GameManager.try_enqueue_day_customer(customer_ids[1]))
	assert_true(GameManager.try_enqueue_day_customer(customer_ids[2]))
	assert_false(
		GameManager.try_enqueue_day_customer(customer_ids[3])
	)
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_1",
			"customer_2",
			"customer_3",
		]
	)
	assert_false(
		GameManager.try_enqueue_day_customer(customer_ids[1])
	)

	assert_true(
		GameManager.try_assign_customer_to_seat(
			customer_ids[0],
			"seat_1"
		)
	)
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_2",
			"customer_3",
		]
	)
	assert_true(GameManager.try_enqueue_day_customer(customer_ids[3]))
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_2",
			"customer_3",
			"customer_4",
		]
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


func test_kitchen_has_four_fixed_stations_and_menu_routes() -> void:
	assert_eq(
		GameManager.KITCHEN_STATIONS,
		[
			GameManager.KITCHEN_STATION_FISH,
			GameManager.KITCHEN_STATION_RICE,
			GameManager.KITCHEN_STATION_OTHER,
			GameManager.KITCHEN_STATION_COUNTER,
		]
	)
	assert_eq(
		GameManager.get_menu_kitchen_route(
			GameManager.MENU_MACKEREL
		),
		[
			GameManager.KITCHEN_STATION_FISH,
			GameManager.KITCHEN_STATION_RICE,
			GameManager.KITCHEN_STATION_COUNTER,
		]
	)
	assert_eq(
		GameManager.get_menu_kitchen_route(GameManager.MENU_EGG),
		[
			GameManager.KITCHEN_STATION_OTHER,
			GameManager.KITCHEN_STATION_RICE,
			GameManager.KITCHEN_STATION_COUNTER,
		]
	)


func test_employee_hire_prepays_wage_and_renews_every_seven_days() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 125

	assert_true(
		GameManager.try_hire_employee(GameManager.STAFF_ROLE_CHEF)
	)
	assert_true(
		GameManager.try_hire_employee(
			GameManager.STAFF_ROLE_SERVICE
		)
	)
	assert_eq(GameManager.state["currency"], 20)
	assert_eq(
		GameManager.get_employee_next_wage_day(
			GameManager.STAFF_ROLE_CHEF
		),
		8
	)

	GameManager.state["day"] = 8
	GameManager.state["currency"] = 60
	var wage_result: Dictionary = (
		GameManager.process_due_weekly_wages()
	)

	assert_eq(wage_result["paid"], [GameManager.STAFF_ROLE_CHEF])
	assert_eq(
		wage_result["departed"],
		[GameManager.STAFF_ROLE_SERVICE]
	)
	assert_eq(GameManager.state["currency"], 0)
	assert_true(
		GameManager.is_employee_hired(GameManager.STAFF_ROLE_CHEF)
	)
	assert_false(GameManager.is_server_hired())
	assert_eq(
		GameManager.get_employee_next_wage_day(
			GameManager.STAFF_ROLE_CHEF
		),
		15
	)


func test_chef_follows_recipe_route_and_finishes_at_counter() -> void:
	GameManager.state = GameManager.create_default_game_state()
	GameManager.state["currency"] = 70
	assert_true(
		GameManager.try_hire_employee(GameManager.STAFF_ROLE_CHEF)
	)
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
	assert_false(GameManager.is_player_carrying_item())
	assert_eq(
		GameManager.get_chef_next_station_id(),
		GameManager.KITCHEN_STATION_FISH
	)
	assert_true(
		GameManager.try_chef_process_station(
			GameManager.KITCHEN_STATION_FISH
		)
	)
	assert_true(
		GameManager.try_chef_process_station(
			GameManager.KITCHEN_STATION_RICE
		)
	)
	assert_true(GameManager.try_chef_start_counter_work())
	assert_true(GameManager.complete_chef_order_at_counter())
	assert_eq(
		GameManager.get_day_order(customer_id)["status"],
		GameManager.ORDER_READY_TO_SERVE
	)
	assert_eq(
		GameManager.get_station_item()["customer_id"],
		customer_id
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


func _create_ready_plate_order() -> String:
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
	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_rice_for_order())
	assert_true(GameManager.try_start_active_order_craft())
	assert_true(GameManager.complete_active_order_craft())
	return customer_id
