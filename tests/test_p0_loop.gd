extends GutTest

const LOOP_COUNT: int = 3
const SALES_PER_LOOP: int = 20
const EXPECTED_REVENUE: int = 136
const EXPECTED_DAY_TWO_CURRENCY: int = 45
const TEST_PATH_PREFIX: String = "user://street_test_p0_loop_"


func before_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func after_each() -> void:
	GameManager.state = {}
	_cleanup_test_files()


func test_day_one_to_day_two_completes_three_times() -> void:
	for loop_index: int in range(LOOP_COUNT):
		GameManager.state = GameManager.create_default_game_state()

		for sale_index: int in range(SALES_PER_LOOP):
			_complete_one_mackerel_sale(
				loop_index,
				sale_index
			)
			_purchase_available_day_one_growth()

		assert_eq(
			GameManager.state["day_stats"]["plates_sold"][
				"mackerel"
			],
			SALES_PER_LOOP,
			"loop %d sold plates" % loop_index
		)
		assert_eq(
			GameManager.state["day_stats"]["revenue"],
			EXPECTED_REVENUE,
			"loop %d revenue" % loop_index
		)
		assert_eq(
			GameManager.get_mackerel_station_level(),
			2,
			"loop %d station level" % loop_index
		)
		assert_eq(
			GameManager.get_unlocked_seat_count(),
			2,
			"loop %d seat count" % loop_index
		)
		assert_true(
			GameManager.is_server_hired(),
			"loop %d server hired" % loop_index
		)
		assert_eq(
			GameManager.state["currency"],
			55,
			"loop %d currency before market" % loop_index
		)
		assert_true(
			GameManager.state["day_runtime"]["customers"].is_empty()
		)
		assert_true(
			GameManager.state["day_runtime"]["orders"].is_empty()
		)
		assert_true(
			GameManager.state["day_runtime"]["payments"].is_empty()
		)

		GameManager.state["service_time_remaining"] = 0.0
		GameManager.state["day_runtime"][
			"accepting_customers"
		] = false
		assert_true(GameManager.try_begin_settlement())
		assert_eq(
			GameManager.get_settlement_summary()["revenue"],
			EXPECTED_REVENUE
		)
		assert_eq(
			GameManager.get_settlement_summary()["waste_cost"],
			0.0
		)
		assert_true(GameManager.request_dawn_after_settlement())
		assert_true(GameManager.try_purchase_market_bundle("rice"))
		assert_true(
			GameManager.try_purchase_market_bundle("mackerel")
		)
		assert_true(GameManager.confirm_market_purchases())

		for material_id: String in ["rice", "mackerel"]:
			for step_index: int in range(4):
				assert_true(
					GameManager.try_complete_dawn_prep_step(
						material_id,
						step_index
					),
					"loop %d %s prep step %d" % [
						loop_index,
						material_id,
						step_index,
					]
				)
		assert_true(GameManager.complete_dawn_and_start_day())

		assert_eq(GameManager.state["day"], 2)
		assert_eq(GameManager.state["screen"], GameManager.SCREEN_DAY)
		assert_eq(
			GameManager.state["phase"],
			GameManager.PHASE_SERVICE
		)
		assert_eq(
			GameManager.state["currency"],
			EXPECTED_DAY_TWO_CURRENCY
		)
		assert_eq(
			GameManager.state["inventory"]["ready"]["rice"],
			5
		)
		assert_eq(
			GameManager.state["inventory"]["ready"]["mackerel"],
			5
		)
		assert_eq(
			GameManager.state["totals"]["plates_sold"][
				"mackerel"
			],
			SALES_PER_LOOP
		)
		assert_eq(
			GameManager.state["totals"]["revenue"],
			EXPECTED_REVENUE
		)

		var test_path: String = _test_path(loop_index)
		assert_eq(
			SaveManager.save_game_state(
				GameManager.state,
				test_path
			),
			OK
		)
		var load_result: Dictionary = SaveManager.load_game_state(
			test_path
		)
		assert_eq(load_result["status"], SaveManager.LoadStatus.OK)
		assert_true(
			GameManager.apply_loaded_game_state(
				load_result["state"]
			)
		)
		assert_eq(GameManager.state["day"], 2)
		assert_eq(
			int(
				GameManager.state["inventory"]["ready"]["rice"]
			),
			5
		)


func _complete_one_mackerel_sale(
	loop_index: int,
	sale_index: int
) -> void:
	var customer_id: String = GameManager.create_day_customer()
	assert_true(
		GameManager.try_assign_customer_to_seat(
			customer_id,
			"seat_1"
		),
		"loop %d sale %d assign" % [loop_index, sale_index]
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

	if GameManager.is_server_hired():
		assert_eq(
			GameManager.try_reserve_ready_plate_for_server(),
			customer_id
		)
		assert_true(
			GameManager.try_server_collect_reserved_plate(
				customer_id
			)
		)
		assert_true(GameManager.try_server_serve_order(customer_id))
	else:
		assert_true(GameManager.try_serve_order(customer_id))

	assert_true(GameManager.mark_customer_finished_eating(customer_id))
	assert_true(GameManager.collect_customer_payment(customer_id))
	assert_true(GameManager.finish_customer_exit(customer_id))


func _purchase_available_day_one_growth() -> void:
	if (
		GameManager.get_mackerel_station_level() == 1
		and GameManager.can_afford_day_growth_purchase(12)
	):
		assert_true(GameManager.try_purchase_mackerel_station_upgrade())
	if (
		GameManager.get_unlocked_seat_count() == 1
		and GameManager.can_afford_day_growth_purchase(24)
	):
		assert_true(GameManager.try_purchase_second_seat())
	if (
		not GameManager.is_server_hired()
		and GameManager.can_afford_day_growth_purchase(45)
	):
		assert_true(GameManager.try_hire_server())


func _test_path(loop_index: int) -> String:
	return "%s%d.json" % [TEST_PATH_PREFIX, loop_index]


func _cleanup_test_files() -> void:
	for loop_index: int in range(LOOP_COUNT):
		var test_path: String = _test_path(loop_index)
		_remove_file(test_path)
		_remove_file(test_path + SaveManager.TEMP_SUFFIX)
		_remove_file(test_path + SaveManager.CORRUPT_SUFFIX)


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
