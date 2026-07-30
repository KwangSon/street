extends GutTest

const DayScreenScript: Script = preload(
	"res://srcs/screens/day_screen.gd"
)


func before_each() -> void:
	GameManager.state = GameManager.create_default_game_state()


func after_each() -> void:
	GameManager.state = {}


func test_signal_has_no_arguments() -> void:
	var screen: Node = DayScreenScript.new()
	var signal_arguments: Array = []
	for signal_data: Dictionary in screen.get_signal_list():
		if signal_data["name"] == "screen_change_requested":
			signal_arguments = signal_data["args"]
			break

	assert_eq(signal_arguments.size(), 0)
	screen.free()


func test_builds_tap_movement_layout_without_direction_buttons() -> void:
	var screen: DayScreen = await _create_screen()

	assert_eq(DayScreen.VIEWPORT_SIZE, Vector2(720.0, 1280.0))
	assert_eq(DayScreen.MAP_SIZE, Vector2(1200.0, 1920.0))
	assert_not_null(screen.get_node("World/Player"))
	assert_not_null(screen.get_node("World/StageCamera"))
	assert_not_null(screen.get_node("World/InteractionController"))
	assert_not_null(screen.get_node("World/CustomerManager"))
	assert_not_null(screen.get_mackerel_station())
	assert_not_null(screen.get_mackerel_upgrade_pad())
	assert_not_null(screen.get_seat_purchase_pad())
	assert_not_null(screen.get_staff_hire_pad())
	assert_null(screen.get_server())
	assert_null(screen.get_node_or_null("World/Seat2"))
	assert_not_null(screen.get_node("FixedUI/HUD"))
	assert_not_null(screen.get_early_close_button())
	assert_eq(screen.get_early_close_button().text, "조기 마감")
	assert_null(screen.get_node_or_null("FixedUI/DirectionButtons"))


func test_upgrade_pad_explains_operating_reserve_block() -> void:
	GameManager.state["currency"] = 21
	var screen: DayScreen = await _create_screen()
	var pad: DayUpgradePad = screen.get_mackerel_upgrade_pad()
	screen.get_player().position = pad.position

	await wait_physics_frames(70)

	assert_eq(GameManager.get_mackerel_station_level(), 1)
	assert_eq(GameManager.state["currency"], 21)
	assert_string_contains(
		pad.get_node("StatusLabel").text,
		"밑천 10문"
	)


func test_upgrade_pad_buys_level_two_and_refreshes_screen() -> void:
	GameManager.state["currency"] = 22
	var screen: DayScreen = await _create_screen()
	var pad: DayUpgradePad = screen.get_mackerel_upgrade_pad()
	screen.get_player().position = pad.position

	await wait_physics_frames(70)

	assert_eq(GameManager.get_mackerel_station_level(), 2)
	assert_eq(GameManager.state["currency"], 10)
	assert_eq(screen.get_mackerel_station().craft_duration, 3.0)
	assert_eq(
		screen.get_mackerel_station().get_node("Label").text,
		"고등어 조리대 Lv.2"
	)
	assert_eq(
		screen.get_node("FixedUI/HUD/CurrencyLabel").text,
		"10문"
	)
	assert_string_contains(
		pad.get_node("StatusLabel").text,
		"판매 7문"
	)


func test_seat_pad_explains_operating_reserve_block() -> void:
	GameManager.state["currency"] = 33
	var screen: DayScreen = await _create_screen()
	var pad: DaySeatPurchasePad = screen.get_seat_purchase_pad()
	screen.get_player().position = pad.position

	await wait_physics_frames(70)

	assert_eq(GameManager.get_unlocked_seat_count(), 1)
	assert_eq(GameManager.state["currency"], 33)
	assert_null(screen.get_node_or_null("World/Seat2"))
	assert_string_contains(
		pad.get_node("StatusLabel").text,
		"밑천 10문"
	)


func test_seat_pad_installs_second_seat_and_promotes_fifo_queue() -> void:
	GameManager.state["currency"] = 34
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	customer_manager.spawn_interval = 0.01
	customer_manager._spawn_time_remaining = 0.01
	await wait_physics_frames(20)
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_2",
			"customer_3",
			"customer_4",
		]
	)

	var pad: DaySeatPurchasePad = screen.get_seat_purchase_pad()
	screen.get_player().position = pad.position
	await wait_physics_frames(70)

	assert_eq(GameManager.get_unlocked_seat_count(), 2)
	assert_eq(GameManager.state["currency"], 10)
	assert_not_null(screen.get_node_or_null("World/Seat2"))
	assert_true(customer_manager.has_seat("seat_2"))
	assert_eq(
		GameManager.state["day_runtime"]["seat_assignments"][
			"seat_2"
		],
		"customer_2"
	)
	assert_eq(
		customer_manager.get_customer(
			"customer_2"
		).get_seat_target(),
		DayScreen.SEAT_2_TARGET
	)
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_3",
			"customer_4",
			"customer_5",
		]
	)
	assert_string_contains(
		pad.get_node("StatusLabel").text,
		"동시 손님 2명"
	)

	assert_true(
		screen.request_player_move_to_world(
			DayScreen.SEAT_2_POSITION
		)
	)
	var seat_rect: Rect2 = Rect2(
		DayScreen.SEAT_2_POSITION - Vector2(60.0, 50.0),
		Vector2(120.0, 100.0)
	).grow(DayPlayer.COLLISION_RADIUS)
	assert_false(
		seat_rect.has_point(
			screen.get_player().get_destination()
		)
	)


func test_loaded_second_seat_exists_before_customer_spawn() -> void:
	GameManager.state["progression"]["seats"] = 2
	var screen: DayScreen = await _create_screen()

	assert_not_null(screen.get_node_or_null("World/Seat2"))
	assert_true(screen.get_customer_manager().has_seat("seat_2"))


func test_staff_pad_explains_operating_reserve_block() -> void:
	GameManager.state["currency"] = 54
	var screen: DayScreen = await _create_screen()
	var pad: DayStaffHirePad = screen.get_staff_hire_pad()
	screen.get_player().position = pad.position

	await wait_physics_frames(70)

	assert_false(GameManager.is_server_hired())
	assert_eq(GameManager.state["currency"], 54)
	assert_null(screen.get_server())
	assert_string_contains(
		pad.get_node("StatusLabel").text,
		"밑천 10문"
	)


func test_staff_pad_hires_one_server_and_refreshes_hud() -> void:
	GameManager.state["currency"] = 55
	var screen: DayScreen = await _create_screen()
	var pad: DayStaffHirePad = screen.get_staff_hire_pad()
	screen.get_player().position = pad.position

	await wait_physics_frames(70)

	assert_true(GameManager.is_server_hired())
	assert_eq(GameManager.state["currency"], 10)
	assert_not_null(screen.get_server())
	assert_eq(
		screen.get_node("FixedUI/HUD/CurrencyLabel").text,
		"10문"
	)
	assert_string_contains(
		pad.get_node("StatusLabel").text,
		"자동 서빙"
	)
	assert_false(GameManager.try_hire_server())


func test_hired_server_auto_serves_matching_plate_under_ten_seconds() -> void:
	GameManager.state["currency"] = 55
	assert_true(GameManager.try_hire_server())
	var screen: DayScreen = await _create_screen()
	var server: DayServer = screen.get_server()
	assert_not_null(server)
	var customer: DayCustomer = (
		screen.get_customer_manager().get_customer("customer_1")
	)
	customer.position = customer.get_seat_target()
	await wait_physics_frames(2)

	assert_true(GameManager.try_accept_waiting_order("customer_1"))
	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_rice_for_order())
	assert_true(GameManager.try_start_active_order_craft())
	assert_true(GameManager.complete_active_order_craft())
	assert_true(GameManager.has_station_item())
	assert_false(GameManager.is_player_carrying_item())

	var serving_frames: int = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_day_customer(
						"customer_1"
					).get("state", "")
				)
				== GameManager.CUSTOMER_EATING
			),
		600
	)

	assert_lte(serving_frames, 600)
	assert_false(GameManager.has_station_item())
	assert_true(GameManager.get_server_carried_item().is_empty())
	assert_eq(server.get_server_state(), DayServer.ServerState.IDLE)


func test_timer_expiry_stops_spawns_and_dismisses_unordered_customers() -> void:
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	customer_manager.spawn_interval = 0.01
	customer_manager._spawn_time_remaining = 0.01
	await wait_physics_frames(20)
	assert_eq(GameManager.get_customer_queue().size(), 3)

	GameManager.state["service_time_remaining"] = 0.01
	await wait_physics_frames(5)

	assert_false(GameManager.is_accepting_customers())
	assert_true(GameManager.get_customer_queue().is_empty())
	assert_eq(
		GameManager.state["day_stats"]["departed_customers"],
		4
	)
	assert_eq(
		screen.get_node("FixedUI/HUD/TimeLabel").text,
		"00:00"
	)
	var next_customer_id: int = int(
		GameManager.state["day_runtime"]["next_customer_id"]
	)
	await wait_physics_frames(180)
	assert_eq(
		GameManager.state["day_runtime"]["next_customer_id"],
		next_customer_id
	)


func test_timer_expiry_keeps_existing_order_playable() -> void:
	var screen: DayScreen = await _create_screen()
	var customer: DayCustomer = (
		screen.get_customer_manager().get_customer("customer_1")
	)
	customer.position = customer.get_seat_target()
	await wait_physics_frames(2)
	assert_eq(
		GameManager.get_day_customer("customer_1")["state"],
		GameManager.CUSTOMER_WAITING_FOR_ORDER
	)

	GameManager.state["service_time_remaining"] = 0.01
	await wait_physics_frames(5)

	assert_false(GameManager.is_accepting_customers())
	assert_true(GameManager.try_accept_waiting_order("customer_1"))
	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_rice_for_order())
	assert_true(GameManager.try_start_active_order_craft())
	assert_true(GameManager.complete_active_order_craft())


func test_early_close_requires_two_second_hold() -> void:
	var screen: DayScreen = await _create_screen()
	var close_button: Button = screen.get_early_close_button()

	close_button.button_down.emit()
	await wait_physics_frames(60)
	close_button.button_up.emit()

	assert_true(GameManager.is_accepting_customers())
	assert_gt(GameManager.state["service_time_remaining"], 0.0)
	assert_eq(screen.get_early_close_hold_progress(), 0.0)
	assert_eq(close_button.text, "조기 마감")

	close_button.button_down.emit()
	await wait_physics_frames(125)

	assert_false(GameManager.is_accepting_customers())
	assert_eq(GameManager.state["service_time_remaining"], 0.0)
	assert_true(close_button.disabled)
	assert_eq(close_button.text, "마감 대기")


func test_empty_inventory_automatically_opens_settlement() -> void:
	GameManager.state["inventory"]["ready"]["rice"] = 0
	GameManager.state["inventory"]["ready"]["mackerel"] = 0

	var screen: DayScreen = await _create_screen()
	await wait_process_frames(2)

	assert_eq(GameManager.state["phase"], GameManager.PHASE_SETTLEMENT)
	assert_true(screen.get_settlement_panel().visible)
	assert_false(GameManager.is_accepting_customers())


func test_empty_closed_service_opens_settlement_summary() -> void:
	GameManager.state["service_time_remaining"] = 0.0
	GameManager.state["day_runtime"]["accepting_customers"] = false
	GameManager.state["day_stats"]["plates_sold"]["mackerel"] = 2
	GameManager.state["day_stats"]["revenue"] = 12
	GameManager.state["day_stats"]["departed_customers"] = 1

	var screen: DayScreen = await _create_screen()
	await wait_process_frames(1)

	assert_eq(GameManager.state["phase"], GameManager.PHASE_SETTLEMENT)
	assert_true(screen.get_settlement_panel().visible)
	var summary_text: String = screen.get_node(
		"FixedUI/SettlementPanel/Content/SummaryLabel"
	).text
	assert_string_contains(summary_text, "총매출  12문")
	assert_string_contains(summary_text, "판매 접시  2개")
	assert_string_contains(summary_text, "떠난 손님  1명")
	assert_string_contains(summary_text, "밥 20 / 고등어 20")
	assert_string_contains(summary_text, "폐기 원가  40.0문")
	assert_false(screen.get_player().has_destination())
	screen._input(_touch_event(1, Vector2(400.0, 600.0), true))
	screen._input(_touch_event(1, Vector2(400.0, 600.0), false))
	assert_false(screen.get_player().has_destination())


func test_settlement_continue_requests_dawn_without_signal_argument() -> void:
	GameManager.state["service_time_remaining"] = 0.0
	GameManager.state["day_runtime"]["accepting_customers"] = false
	var screen: DayScreen = await _create_screen()
	await wait_process_frames(1)
	watch_signals(screen)

	screen.get_settlement_continue_button().pressed.emit()

	assert_eq(GameManager.state["screen"], GameManager.SCREEN_DAWN)
	assert_eq(GameManager.state["phase"], GameManager.PHASE_MARKET)
	assert_signal_emitted(screen, "screen_change_requested")


func test_initial_customer_reserves_seat_and_shows_order() -> void:
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)

	assert_eq(customer_manager.get_customer_count(), 1)
	assert_eq(
		GameManager.state["day_runtime"]["seat_assignments"][
			"seat_1"
		],
		"customer_1"
	)

	await wait_physics_frames(180)

	var customer_state: Dictionary = (
		GameManager.get_day_customer("customer_1")
	)
	assert_eq(
		customer_state["state"],
		GameManager.CUSTOMER_WAITING_FOR_ORDER
	)
	assert_eq(customer_state["menu"], GameManager.MENU_MACKEREL)
	var customer: DayCustomer = customer_manager.get_customer(
		"customer_1"
	)
	assert_false(customer.is_moving_to_seat())
	assert_true(customer.get_node("OrderBubble").visible)
	assert_eq(
		customer.get_node("OrderBubble/MenuLabel").text,
		"고등어"
	)


func test_screen_customer_queue_stops_at_three_waiting() -> void:
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	customer_manager.spawn_interval = 0.01
	customer_manager._spawn_time_remaining = 0.01

	await wait_physics_frames(20)

	assert_eq(customer_manager.get_customer_count(), 4)
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_2",
			"customer_3",
			"customer_4",
		]
	)
	assert_eq(
		GameManager.get_day_customer("customer_2")["state"],
		GameManager.CUSTOMER_WAITING_IN_QUEUE
	)
	assert_eq(
		customer_manager.get_customer(
			"customer_2"
		).get_queue_target(),
		Vector2(190.0, 860.0)
	)
	assert_null(customer_manager.get_customer("customer_5"))


func test_station_approach_without_order_does_not_start_crafting() -> void:
	var screen: DayScreen = await _create_screen()
	var station: MackerelStation = screen.get_mackerel_station()
	screen.get_player().position = Vector2(
		station.position.x,
		station.position.y + 80.0
	)

	await wait_physics_frames(2)

	assert_ne(
		screen.get_interaction_controller().get_current_target(),
		station
	)
	assert_false(station.is_crafting_reserved())
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 20)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		20
	)
	assert_eq(
		screen.get_node(
			"FixedUI/HUD/InventoryLabel"
		).text,
		"밥 20  |  고등어 20"
	)


func test_order_mackerel_rice_station_sequence_starts_crafting() -> void:
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	var customer: DayCustomer = customer_manager.get_customer(
		"customer_1"
	)
	customer.position = customer.get_seat_target()
	await wait_physics_frames(2)

	screen.get_player().position = customer.position
	await wait_physics_frames(2)
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_MACKEREL
	)

	var ingredient_box: DayPreparationSource = (
		screen.get_ingredient_box()
	)
	screen.get_player().position = (
		ingredient_box.position + Vector2(0.0, 80.0)
	)
	await wait_physics_frames(2)
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_NEED_RICE
	)
	assert_eq(
		GameManager.state["inventory"]["ready"]["mackerel"],
		19
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 20)

	var rice_pot: DayPreparationSource = screen.get_rice_pot()
	screen.get_player().position = (
		rice_pot.position + Vector2(0.0, 80.0)
	)
	await wait_physics_frames(2)
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_READY_TO_COOK
	)
	assert_eq(GameManager.state["inventory"]["ready"]["rice"], 19)

	var station: MackerelStation = screen.get_mackerel_station()
	screen.get_player().position = (
		station.position + Vector2(0.0, 80.0)
	)
	await wait_physics_frames(2)

	assert_eq(
		screen.get_interaction_controller().get_current_target(),
		station
	)
	assert_true(station.is_crafting_reserved())
	assert_eq(
		GameManager.get_carried_item()["step"],
		GameManager.PREP_COOKING
	)


func test_matching_plate_is_served_and_customer_finishes_eating() -> void:
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	customer_manager.spawn_interval = 0.01
	customer_manager._spawn_time_remaining = 0.01
	await wait_physics_frames(20)
	var customer: DayCustomer = (
		customer_manager.get_customer("customer_1")
	)
	customer.position = customer.get_seat_target()
	customer.eating_duration = 0.1
	await wait_physics_frames(2)

	assert_true(GameManager.try_accept_waiting_order("customer_1"))
	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_rice_for_order())
	assert_true(GameManager.try_start_active_order_craft())
	assert_true(GameManager.complete_active_order_craft())

	screen.get_player().position = customer.position
	await wait_physics_frames(2)

	assert_eq(
		GameManager.get_day_customer("customer_1")["state"],
		GameManager.CUSTOMER_EATING
	)
	assert_false(GameManager.is_player_carrying_item())
	assert_eq(
		customer.get_node("OrderBubble/MenuLabel").text,
		"냠냠"
	)

	await wait_physics_frames(10)

	assert_eq(
		GameManager.get_day_customer("customer_1")["state"],
		GameManager.CUSTOMER_WAITING_FOR_PAYMENT
	)
	assert_eq(
		customer.get_node("OrderBubble/MenuLabel").text,
		"계산"
	)

	var payment: DayPayment = customer_manager.get_payment(
		"customer_1"
	)
	assert_not_null(payment)
	screen.get_player().position = payment.position
	await wait_physics_frames(2)

	assert_eq(GameManager.state["currency"], 6)
	assert_true(customer.is_moving_to_exit())
	assert_null(customer_manager.get_payment("customer_1"))

	customer.position = customer.get_exit_target()
	await wait_physics_frames(3)
	await wait_process_frames(1)

	assert_true(
		GameManager.get_day_customer("customer_1").is_empty()
	)
	assert_not_null(customer_manager.get_customer("customer_2"))
	assert_eq(
		GameManager.state["day_runtime"]["seat_assignments"][
			"seat_1"
		],
		"customer_2"
	)
	assert_eq(
		GameManager.get_customer_queue(),
		[
			"customer_3",
			"customer_4",
			"customer_5",
		]
	)
	assert_eq(
		GameManager.get_day_customer("customer_2")["state"],
		GameManager.CUSTOMER_MOVING_TO_SEAT
	)


func test_ten_customers_reuse_seat_without_runtime_leaks() -> void:
	var screen: DayScreen = await _create_screen()
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	customer_manager.spawn_interval = 999.0
	customer_manager._spawn_time_remaining = 999.0

	for customer_number: int in range(1, 11):
		var customer_id: String = "customer_%d" % customer_number
		var appeared_frames: int = await _wait_for_condition(
			func() -> bool:
				return customer_manager.get_customer(
					customer_id
				) != null,
			30
		)
		assert_lte(
			appeared_frames,
			30,
			"%s should enter" % customer_id
		)
		await _complete_screen_customer_sale(
			screen,
			customer_id,
			customer_number == 10
		)

	await wait_process_frames(2)

	assert_eq(GameManager.state["phase"], GameManager.PHASE_SETTLEMENT)
	assert_eq(
		GameManager.get_settlement_summary()["total_plates"],
		10
	)
	assert_eq(GameManager.get_settlement_summary()["revenue"], 60)
	assert_eq(GameManager.state["currency"], 60)
	assert_true(
		GameManager.state["day_runtime"]["customers"].is_empty()
	)
	assert_true(GameManager.get_customer_queue().is_empty())
	assert_true(
		GameManager.state["day_runtime"]["seat_assignments"].is_empty()
	)
	assert_true(
		GameManager.state["day_runtime"]["orders"].is_empty()
	)
	assert_true(
		GameManager.state["day_runtime"]["payments"].is_empty()
	)
	assert_eq(customer_manager.get_customer_count(), 0)


func test_first_sale_completes_with_real_movement_under_thirty_seconds() -> void:
	var screen: DayScreen = await _create_screen()
	var elapsed_frames: int = 0

	var waited_frames: int = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_day_customer(
						"customer_1"
					).get("state", "")
				)
				== GameManager.CUSTOMER_WAITING_FOR_ORDER
			),
		240
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 240)

	var customer: DayCustomer = (
		screen.get_customer_manager().get_customer("customer_1")
	)
	assert_true(
		screen.request_player_move_to_world(customer.position)
	)
	waited_frames = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_carried_item().get("step", "")
				)
				== GameManager.PREP_NEED_MACKEREL
			),
		120
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 120)

	assert_true(
		screen.request_player_move_to_world(
			screen.get_ingredient_box().position
		)
	)
	waited_frames = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_carried_item().get("step", "")
				)
				== GameManager.PREP_NEED_RICE
			),
		240
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 240)

	assert_true(
		screen.request_player_move_to_world(
			screen.get_rice_pot().position
		)
	)
	waited_frames = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_carried_item().get("step", "")
				)
				== GameManager.PREP_READY_TO_COOK
			),
		180
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 180)

	assert_true(
		screen.request_player_move_to_world(
			screen.get_mackerel_station().position
		)
	)
	waited_frames = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_carried_item().get("kind", "")
				)
				== GameManager.CARRIED_KIND_PLATE
			),
		420
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 420)

	assert_true(
		screen.request_player_move_to_world(customer.position)
	)
	waited_frames = await _wait_for_condition(
		func() -> bool:
			return (
				String(
					GameManager.get_day_customer(
						"customer_1"
					).get("state", "")
				)
				== GameManager.CUSTOMER_EATING
			),
		240
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 240)

	waited_frames = await _wait_for_condition(
		func() -> bool:
			return (
				screen.get_customer_manager().get_payment(
					"customer_1"
				)
				!= null
			),
		180
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 180)
	var payment: DayPayment = (
		screen.get_customer_manager().get_payment("customer_1")
	)
	assert_not_null(payment)
	if payment == null:
		return

	assert_true(
		screen.request_player_move_to_world(payment.position)
	)
	waited_frames = await _wait_for_condition(
		func() -> bool:
			return int(GameManager.state.get("currency", 0)) == 6,
		180
	)
	elapsed_frames += waited_frames
	assert_lte(waited_frames, 180)

	assert_lte(elapsed_frames, 30 * 60)
	assert_eq(GameManager.state["currency"], 6)
	assert_eq(
		GameManager.state["day_stats"]["plates_sold"]["mackerel"],
		1
	)


func test_touch_tap_sets_world_destination() -> void:
	var screen: DayScreen = await _create_screen()
	var tap_position: Vector2 = Vector2(460.0, 640.0)

	screen._input(_touch_event(1, tap_position, true))
	screen._input(_touch_event(1, tap_position, false))

	assert_true(screen.get_player().has_destination())
	assert_eq(
		screen.get_player().get_destination(),
		Vector2(460.0, 640.0)
	)


func test_mouse_click_uses_same_tap_contract() -> void:
	var screen: DayScreen = await _create_screen()
	var click_position: Vector2 = Vector2(460.0, 640.0)

	screen._input(_mouse_button_event(click_position, true))
	screen._input(_mouse_button_event(click_position, false))

	assert_true(screen.get_player().has_destination())
	assert_eq(
		screen.get_player().get_destination(),
		Vector2(460.0, 640.0)
	)


func test_keyboard_event_does_not_set_destination() -> void:
	var screen: DayScreen = await _create_screen()
	var keyboard_event: InputEventKey = InputEventKey.new()
	keyboard_event.keycode = KEY_RIGHT
	keyboard_event.pressed = true

	screen._input(keyboard_event)

	assert_false(screen.get_player().has_destination())


func test_hud_tap_does_not_set_destination() -> void:
	var screen: DayScreen = await _create_screen()
	var hud_position: Vector2 = Vector2(360.0, 60.0)

	screen._input(_touch_event(1, hud_position, true))
	screen._input(_touch_event(1, hud_position, false))

	assert_false(screen.get_player().has_destination())


func test_movement_below_drag_threshold_is_a_tap() -> void:
	var screen: DayScreen = await _create_screen()
	var start_position: Vector2 = Vector2(460.0, 640.0)
	var end_position: Vector2 = start_position + Vector2(7.0, 0.0)

	screen._input(_touch_event(1, start_position, true))
	screen._input(_touch_drag_event(1, end_position))
	screen._input(_touch_event(1, end_position, false))

	assert_true(screen.get_player().has_destination())
	assert_eq(
		screen.get_player().get_destination(),
		Vector2(467.0, 640.0)
	)


func test_drag_moves_camera_without_creating_destination() -> void:
	var screen: DayScreen = await _create_screen()
	var drag_start: Vector2 = Vector2(500.0, 500.0)
	var original_camera_position: Vector2 = (
		screen.get_stage_camera().position
	)

	screen._input(_touch_event(1, drag_start, true))
	screen._input(
		_touch_drag_event(1, drag_start + Vector2(-160.0, 0.0))
	)
	screen._input(
		_touch_event(
			1,
			drag_start + Vector2(-160.0, 0.0),
			false
		)
	)

	assert_ne(screen.get_stage_camera().position, original_camera_position)
	assert_false(screen.get_player().has_destination())


func test_drag_keeps_existing_player_destination() -> void:
	var screen: DayScreen = await _create_screen()
	assert_true(
		screen.request_player_move_to_world(Vector2(650.0, 620.0))
	)
	var existing_destination: Vector2 = (
		screen.get_player().get_destination()
	)
	var drag_start: Vector2 = Vector2(500.0, 500.0)

	screen._input(_touch_event(1, drag_start, true))
	screen._input(
		_touch_drag_event(1, drag_start + Vector2(-160.0, 0.0))
	)
	screen._input(
		_touch_event(
			1,
			drag_start + Vector2(-160.0, 0.0),
			false
		)
	)

	assert_true(screen.get_player().has_destination())
	assert_eq(
		screen.get_player().get_destination(),
		existing_destination
	)


func test_new_tap_replaces_existing_destination() -> void:
	var screen: DayScreen = await _create_screen()
	assert_true(
		screen.request_player_move_to_world(Vector2(650.0, 620.0))
	)
	var new_tap: Vector2 = Vector2(420.0, 720.0)

	screen._input(_touch_event(1, new_tap, true))
	screen._input(_touch_event(1, new_tap, false))

	assert_eq(
		screen.get_player().get_destination(),
		Vector2(420.0, 720.0)
	)


func test_mouse_drag_moves_camera_without_retargeting() -> void:
	var screen: DayScreen = await _create_screen()
	var drag_start: Vector2 = Vector2(500.0, 500.0)
	var original_camera_position: Vector2 = (
		screen.get_stage_camera().position
	)

	screen._input(_mouse_button_event(drag_start, true))
	screen._input(
		_mouse_motion_event(drag_start + Vector2(-160.0, 0.0))
	)
	screen._input(
		_mouse_button_event(
			drag_start + Vector2(-160.0, 0.0),
			false
		)
	)

	assert_ne(screen.get_stage_camera().position, original_camera_position)
	assert_false(screen.get_player().has_destination())


func test_tap_after_camera_drag_uses_current_world_position() -> void:
	var screen: DayScreen = await _create_screen()
	var drag_start: Vector2 = Vector2(500.0, 500.0)
	screen._input(_touch_event(1, drag_start, true))
	screen._input(
		_touch_drag_event(1, drag_start + Vector2(-160.0, 0.0))
	)
	screen._input(
		_touch_event(
			1,
			drag_start + Vector2(-160.0, 0.0),
			false
		)
	)

	var screen_center: Vector2 = DayScreen.VIEWPORT_SIZE * 0.5
	screen._input(_touch_event(2, screen_center, true))
	screen._input(_touch_event(2, screen_center, false))

	assert_eq(
		screen.get_player().get_destination(),
		screen.get_stage_camera().position
	)


func test_additional_pointer_is_ignored_during_gesture() -> void:
	var screen: DayScreen = await _create_screen()
	var first_tap: Vector2 = Vector2(460.0, 640.0)
	var second_tap: Vector2 = Vector2(600.0, 700.0)

	screen._input(_touch_event(1, first_tap, true))
	screen._input(_touch_event(2, second_tap, true))
	screen._input(_touch_event(2, second_tap, false))
	assert_false(screen.get_player().has_destination())

	screen._input(_touch_event(1, first_tap, false))
	assert_eq(
		screen.get_player().get_destination(),
		Vector2(460.0, 640.0)
	)


func test_path_routes_around_facility() -> void:
	var screen: DayScreen = await _create_screen()

	assert_true(
		screen.request_player_move_to_world(Vector2(320.0, 180.0))
	)

	var path: PackedVector2Array = (
		screen.get_player().get_current_path()
	)
	var routes_around_rice_pot: bool = false
	for waypoint: Vector2 in path:
		if waypoint.x <= 220.0 or waypoint.x >= 420.0:
			routes_around_rice_pot = true
			break
	assert_true(routes_around_rice_pot)


func test_facility_tap_uses_nearest_walkable_destination() -> void:
	var screen: DayScreen = await _create_screen()
	var facility_center: Vector2 = Vector2(320.0, 300.0)

	assert_true(screen.request_player_move_to_world(facility_center))

	var expanded_facility: Rect2 = Rect2(
		Vector2(260.0, 252.0),
		Vector2(120.0, 96.0)
	).grow(DayPlayer.COLLISION_RADIUS)
	assert_false(
		expanded_facility.has_point(
			screen.get_player().get_destination()
		)
	)


func test_player_reaches_tapped_destination_and_stops() -> void:
	var screen: DayScreen = await _create_screen()
	var destination: Vector2 = Vector2(480.0, 620.0)
	assert_true(screen.request_player_move_to_world(destination))

	await wait_physics_frames(60)

	assert_false(screen.get_player().has_destination())
	assert_lt(
		screen.get_player().position.distance_to(destination),
		DayPlayer.ARRIVAL_DISTANCE + 1.0
	)


func test_requested_destination_is_clamped_inside_map() -> void:
	var screen: DayScreen = await _create_screen()
	assert_true(
		screen.request_player_move_to_world(Vector2(5000.0, 5000.0))
	)

	var destination: Vector2 = screen.get_player().get_destination()
	assert_gte(destination.x, DayPlayer.COLLISION_RADIUS)
	assert_gte(destination.y, DayPlayer.COLLISION_RADIUS)
	assert_lte(
		destination.x,
		DayScreen.MAP_SIZE.x - DayPlayer.COLLISION_RADIUS
	)
	assert_lte(
		destination.y,
		DayScreen.MAP_SIZE.y - DayPlayer.COLLISION_RADIUS
	)


func _create_screen() -> DayScreen:
	var screen: DayScreen = DayScreenScript.new()
	add_child_autofree(screen)
	await wait_process_frames(1)
	return screen


func _complete_screen_customer_sale(
	screen: DayScreen,
	customer_id: String,
	close_after_payment: bool
) -> void:
	var customer_manager: DayCustomerManager = (
		screen.get_customer_manager()
	)
	var customer: DayCustomer = customer_manager.get_customer(
		customer_id
	)
	assert_not_null(customer)
	if customer == null:
		return
	customer.eating_duration = 0.01
	customer.position = customer.get_seat_target()
	await wait_physics_frames(2)

	assert_eq(
		GameManager.get_day_customer(customer_id)["state"],
		GameManager.CUSTOMER_WAITING_FOR_ORDER
	)
	assert_true(GameManager.try_accept_waiting_order(customer_id))
	assert_true(GameManager.try_collect_mackerel_for_order())
	assert_true(GameManager.try_collect_rice_for_order())
	assert_true(GameManager.try_start_active_order_craft())
	assert_true(GameManager.complete_active_order_craft())
	assert_true(GameManager.try_serve_order(customer_id))

	var payment_frames: int = await _wait_for_condition(
		func() -> bool:
			return customer_manager.get_payment(customer_id) != null,
		30
	)
	assert_lte(payment_frames, 30)
	var payment: DayPayment = customer_manager.get_payment(
		customer_id
	)
	assert_not_null(payment)
	if payment == null:
		return
	screen.get_player().position = payment.position
	await wait_physics_frames(2)

	assert_null(customer_manager.get_payment(customer_id))
	assert_true(customer.is_moving_to_exit())
	if close_after_payment:
		assert_true(GameManager.request_early_close())
	customer.position = customer.get_exit_target()
	await wait_physics_frames(3)
	await wait_process_frames(1)

	assert_true(GameManager.get_day_customer(customer_id).is_empty())
	assert_null(customer_manager.get_customer(customer_id))


func _wait_for_condition(
	condition: Callable,
	max_frames: int
) -> int:
	for elapsed_frames: int in range(max_frames + 1):
		if bool(condition.call()):
			return elapsed_frames
		await get_tree().physics_frame
	return max_frames + 1


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


func _mouse_button_event(
	position: Vector2,
	pressed: bool
) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = pressed
	return event


func _mouse_motion_event(position: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = position
	return event
