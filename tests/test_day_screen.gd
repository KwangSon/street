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
	assert_not_null(screen.get_node("FixedUI/HUD"))
	assert_null(screen.get_node_or_null("FixedUI/DirectionButtons"))


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
