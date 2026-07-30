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
	assert_not_null(screen.get_node("FixedUI/HUD"))
	assert_null(screen.get_node_or_null("FixedUI/DirectionButtons"))


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
	var customer: DayCustomer = (
		screen.get_customer_manager().get_customer("customer_1")
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
