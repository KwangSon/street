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


func test_builds_mobile_layout_for_720_by_1280() -> void:
	var screen: DayScreen = await _create_screen()

	assert_eq(DayScreen.VIEWPORT_SIZE, Vector2(720.0, 1280.0))
	assert_eq(DayScreen.MAP_SIZE, Vector2(1200.0, 1920.0))
	assert_not_null(screen.get_node("World/Player"))
	assert_not_null(screen.get_node("World/StageCamera"))
	assert_not_null(screen.get_node("FixedUI/HUD"))
	assert_not_null(screen.get_node("FixedUI/DirectionButtons/UpButton"))
	assert_not_null(
		screen.get_node("World/MackerelStation")
	)


func test_touch_button_moves_only_while_pressed() -> void:
	var screen: DayScreen = await _create_screen()
	var right_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_RIGHT
	).get_center()

	screen._input(_touch_event(1, right_center, true))
	assert_eq(screen.get_player().get_movement_input(), Vector2.RIGHT)

	screen._input(_touch_event(1, right_center, false))
	assert_eq(
		screen.get_player().get_movement_input(),
		Vector2.ZERO
	)


func test_mouse_click_uses_same_direction_button_contract() -> void:
	var screen: DayScreen = await _create_screen()
	var left_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_LEFT
	).get_center()

	screen._input(_mouse_button_event(left_center, true))
	assert_eq(screen.get_player().get_movement_input(), Vector2.LEFT)

	screen._input(_mouse_button_event(left_center, false))
	assert_eq(
		screen.get_player().get_movement_input(),
		Vector2.ZERO
	)


func test_keyboard_event_does_not_move_player() -> void:
	var screen: DayScreen = await _create_screen()
	var keyboard_event: InputEventKey = InputEventKey.new()
	keyboard_event.keycode = KEY_RIGHT
	keyboard_event.pressed = true

	screen._input(keyboard_event)

	assert_eq(
		screen.get_player().get_movement_input(),
		Vector2.ZERO
	)


func test_diagonal_is_normalized_and_uses_horizontal_tie_facing() -> void:
	var screen: DayScreen = await _create_screen()
	var up_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_UP
	).get_center()
	var right_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_RIGHT
	).get_center()

	screen._input(_touch_event(1, up_center, true))
	screen._input(_touch_event(2, right_center, true))

	assert_almost_eq(
		screen.get_player().get_movement_input().length(),
		1.0,
		0.001
	)
	assert_eq(
		screen.get_player().get_facing_direction(),
		DayPlayer.FACING_RIGHT
	)


func test_opposite_directions_cancel_each_other() -> void:
	var screen: DayScreen = await _create_screen()
	var left_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_LEFT
	).get_center()
	var right_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_RIGHT
	).get_center()

	screen._input(_touch_event(1, left_center, true))
	screen._input(_touch_event(2, right_center, true))

	assert_eq(
		screen.get_player().get_movement_input(),
		Vector2.ZERO
	)


func test_ui_drag_does_not_move_camera() -> void:
	var screen: DayScreen = await _create_screen()
	var original_position: Vector2 = screen.get_stage_camera().position
	var button_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_RIGHT
	).get_center()

	screen._input(_touch_event(1, button_center, true))
	screen._input(
		_touch_drag_event(1, button_center + Vector2(-200.0, 0.0))
	)

	assert_eq(screen.get_stage_camera().position, original_position)


func test_play_area_drag_moves_and_clamps_camera() -> void:
	var screen: DayScreen = await _create_screen()
	var drag_start: Vector2 = Vector2(500.0, 500.0)

	screen._input(_touch_event(1, drag_start, true))
	screen._input(
		_touch_drag_event(1, drag_start + Vector2(-2000.0, -2000.0))
	)

	assert_eq(
		screen.get_stage_camera().position,
		Vector2(840.0, 1280.0)
	)


func test_mouse_drag_moves_camera() -> void:
	var screen: DayScreen = await _create_screen()
	var drag_start: Vector2 = Vector2(500.0, 500.0)
	var original_position: Vector2 = screen.get_stage_camera().position

	screen._input(_mouse_button_event(drag_start, true))
	screen._input(
		_mouse_motion_event(drag_start + Vector2(-160.0, 0.0))
	)
	screen._input(_mouse_button_event(drag_start, false))

	assert_ne(screen.get_stage_camera().position, original_position)


func test_multitouch_moves_player_while_dragging_camera() -> void:
	var screen: DayScreen = await _create_screen()
	var right_center: Vector2 = screen.get_direction_button_rect(
		DayScreen.DIRECTION_RIGHT
	).get_center()
	var drag_start: Vector2 = Vector2(500.0, 500.0)
	var original_camera_position: Vector2 = (
		screen.get_stage_camera().position
	)

	screen._input(_touch_event(1, right_center, true))
	screen._input(_touch_event(2, drag_start, true))
	screen._input(
		_touch_drag_event(2, drag_start + Vector2(-160.0, 0.0))
	)

	assert_eq(screen.get_player().get_movement_input(), Vector2.RIGHT)
	assert_ne(screen.get_stage_camera().position, original_camera_position)


func test_player_cannot_cross_facility_collision() -> void:
	var screen: DayScreen = await _create_screen()
	var player: DayPlayer = screen.get_player()
	player.position = Vector2(320.0, 430.0)
	player.set_movement_input(Vector2.UP)

	await wait_physics_frames(40)

	assert_gte(player.position.y, 375.0)


func test_player_cannot_cross_map_boundary() -> void:
	var screen: DayScreen = await _create_screen()
	var player: DayPlayer = screen.get_player()
	player.position = Vector2(
		DayPlayer.COLLISION_RADIUS + 2.0,
		700.0
	)
	player.set_movement_input(Vector2.LEFT)

	await wait_physics_frames(20)

	assert_gte(
		player.position.x,
		DayPlayer.COLLISION_RADIUS - 1.0
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
