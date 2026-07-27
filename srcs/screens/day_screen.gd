extends Node2D
class_name DayScreen

signal screen_change_requested

const DayPlayerScript: Script = preload(
	"res://srcs/day/day_player.gd"
)
const DayNavigationScript: Script = preload(
	"res://srcs/day/day_navigation.gd"
)

const VIEWPORT_SIZE: Vector2 = Vector2(720.0, 1280.0)
const MAP_SIZE: Vector2 = Vector2(1200.0, 1920.0)
const DEFAULT_CAMERA_POSITION: Vector2 = Vector2(360.0, 640.0)
const PLAYER_START_POSITION: Vector2 = Vector2(360.0, 620.0)
const DRAG_THRESHOLD: float = 8.0

const HUD_HEIGHT: float = 112.0
const MOUSE_POINTER_ID: int = -1
const NO_POINTER_ID: int = -2

const MAP_COLOR: Color = Color("b9b7ad")
const GRID_COLOR: Color = Color("aaa89f")
const HUD_COLOR: Color = Color("35291f")
const HUD_TEXT_COLOR: Color = Color("fff4d6")

const FACILITIES: Array[Dictionary] = [
	{
		"name": "IngredientBox",
		"label": "재료",
		"position": Vector2(120.0, 300.0),
		"size": Vector2(140.0, 96.0),
		"color": Color("79986b"),
		"collision": true,
	},
	{
		"name": "RicePot",
		"label": "밥통",
		"position": Vector2(320.0, 300.0),
		"size": Vector2(120.0, 96.0),
		"color": Color("c6a477"),
		"collision": true,
	},
	{
		"name": "MackerelStation",
		"label": "고등어 조리대",
		"position": Vector2(540.0, 300.0),
		"size": Vector2(180.0, 96.0),
		"color": Color("7197ad"),
		"collision": true,
	},
	{
		"name": "Entrance",
		"label": "입구",
		"position": Vector2(120.0, 860.0),
		"size": Vector2(140.0, 80.0),
		"color": Color("c98e64"),
		"collision": false,
	},
	{
		"name": "Seat1",
		"label": "좌석 1",
		"position": Vector2(500.0, 840.0),
		"size": Vector2(120.0, 100.0),
		"color": Color("a57853"),
		"collision": true,
	},
	{
		"name": "EggStation",
		"label": "계란 조리대",
		"position": Vector2(940.0, 340.0),
		"size": Vector2(180.0, 96.0),
		"color": Color("c8b25b"),
		"collision": true,
	},
	{
		"name": "Seat2",
		"label": "좌석 2",
		"position": Vector2(900.0, 920.0),
		"size": Vector2(120.0, 100.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
	{
		"name": "StaffPad",
		"label": "점원 패드",
		"position": Vector2(900.0, 1420.0),
		"size": Vector2(180.0, 100.0),
		"color": Color("8a769d"),
		"collision": true,
	},
]

var _world: Node2D
var _player: DayPlayer
var _camera: Camera2D
var _navigation: DayNavigation
var _active_pointer_id: int = NO_POINTER_ID
var _gesture_start: Vector2 = Vector2.ZERO
var _gesture_last: Vector2 = Vector2.ZERO
var _gesture_is_drag: bool = false


func _ready() -> void:
	name = "DayScreen"
	_build_world()
	_build_fixed_ui()
	_reset_camera()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _exit_tree() -> void:
	if _player != null:
		_player.clear_path()
	_active_pointer_id = NO_POINTER_ID


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			_begin_pointer(touch_event.index, touch_event.position)
			if _active_pointer_id == touch_event.index:
				get_viewport().set_input_as_handled()
		else:
			var was_active_touch: bool = (
				_active_pointer_id == touch_event.index
			)
			_end_pointer(touch_event.index, touch_event.position)
			if was_active_touch:
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event
		if _active_pointer_id == drag_event.index:
			_move_pointer(drag_event.index, drag_event.position)
			get_viewport().set_input_as_handled()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		var mouse_button: InputEventMouseButton = event
		if mouse_button.pressed:
			_begin_pointer(MOUSE_POINTER_ID, mouse_button.position)
			if _active_pointer_id == MOUSE_POINTER_ID:
				get_viewport().set_input_as_handled()
		else:
			var was_active_mouse: bool = (
				_active_pointer_id == MOUSE_POINTER_ID
			)
			_end_pointer(MOUSE_POINTER_ID, mouse_button.position)
			if was_active_mouse:
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if _active_pointer_id == MOUSE_POINTER_ID:
			var mouse_motion: InputEventMouseMotion = event
			_move_pointer(MOUSE_POINTER_ID, mouse_motion.position)
			get_viewport().set_input_as_handled()


func get_player() -> DayPlayer:
	return _player


func get_stage_camera() -> Camera2D:
	return _camera


func get_play_area_rect() -> Rect2:
	return Rect2(
		Vector2(0.0, HUD_HEIGHT),
		Vector2(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y - HUD_HEIGHT)
	)


func screen_to_world(screen_position: Vector2) -> Vector2:
	return (
		_camera.position
		+ screen_position
		- VIEWPORT_SIZE * 0.5
	)


func request_player_move_to_world(
	world_destination: Vector2
) -> bool:
	var path: PackedVector2Array = _navigation.find_path(
		_player.position,
		world_destination
	)
	if path.is_empty():
		_player.clear_path()
		return false
	return _player.follow_path(path)


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	_add_map_background()
	_add_map_boundaries()
	for facility: Dictionary in FACILITIES:
		_add_facility(facility)

	_player = DayPlayerScript.new()
	_player.move_speed = DayPlayer.DEFAULT_MOVE_SPEED
	_player.position = PLAYER_START_POSITION
	_world.add_child(_player)

	_camera = Camera2D.new()
	_camera.name = "StageCamera"
	_camera.position = DEFAULT_CAMERA_POSITION
	_camera.position_smoothing_enabled = false
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(MAP_SIZE.x)
	_camera.limit_bottom = int(MAP_SIZE.y)
	_camera.enabled = true
	_world.add_child(_camera)

	_navigation = DayNavigationScript.new()
	_navigation.configure(
		MAP_SIZE,
		DayPlayer.COLLISION_RADIUS,
		_get_navigation_obstacle_rects()
	)


func _add_map_background() -> void:
	var background: Polygon2D = Polygon2D.new()
	background.name = "MapBackground"
	background.color = MAP_COLOR
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(MAP_SIZE.x, 0.0),
		MAP_SIZE,
		Vector2(0.0, MAP_SIZE.y),
	])
	background.z_index = -10
	_world.add_child(background)

	for x_position: float in range(0, int(MAP_SIZE.x) + 1, 120):
		_add_grid_line(
			Vector2(x_position, 0.0),
			Vector2(x_position, MAP_SIZE.y)
		)
	for y_position: float in range(0, int(MAP_SIZE.y) + 1, 120):
		_add_grid_line(
			Vector2(0.0, y_position),
			Vector2(MAP_SIZE.x, y_position)
		)


func _add_grid_line(start: Vector2, end: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.width = 2.0
	line.default_color = GRID_COLOR
	line.points = PackedVector2Array([start, end])
	line.z_index = -9
	_world.add_child(line)


func _add_map_boundaries() -> void:
	const WALL_THICKNESS: float = 64.0
	_add_static_collision(
		"BoundaryTop",
		Vector2(MAP_SIZE.x * 0.5, -WALL_THICKNESS * 0.5),
		Vector2(MAP_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)
	)
	_add_static_collision(
		"BoundaryBottom",
		Vector2(
			MAP_SIZE.x * 0.5,
			MAP_SIZE.y + WALL_THICKNESS * 0.5
		),
		Vector2(MAP_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)
	)
	_add_static_collision(
		"BoundaryLeft",
		Vector2(-WALL_THICKNESS * 0.5, MAP_SIZE.y * 0.5),
		Vector2(WALL_THICKNESS, MAP_SIZE.y)
	)
	_add_static_collision(
		"BoundaryRight",
		Vector2(
			MAP_SIZE.x + WALL_THICKNESS * 0.5,
			MAP_SIZE.y * 0.5
		),
		Vector2(WALL_THICKNESS, MAP_SIZE.y)
	)


func _add_facility(facility: Dictionary) -> void:
	var facility_node: Node2D = Node2D.new()
	facility_node.name = String(facility["name"])
	facility_node.position = facility["position"]
	_world.add_child(facility_node)

	var facility_size: Vector2 = facility["size"]
	var visual: Polygon2D = Polygon2D.new()
	visual.name = "Visual"
	visual.color = facility["color"]
	visual.polygon = _rectangle_polygon(facility_size)
	facility_node.add_child(visual)

	var label: Label = Label.new()
	label.name = "Label"
	label.position = -facility_size * 0.5
	label.size = facility_size
	label.text = String(facility["label"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("35291f"))
	label.add_theme_font_size_override("font_size", 18)
	facility_node.add_child(label)

	if bool(facility["collision"]):
		_add_static_collision(
			"%sCollision" % facility["name"],
			facility["position"],
			facility_size
		)


func _get_navigation_obstacle_rects() -> Array[Rect2]:
	var obstacle_rects: Array[Rect2] = []
	for facility: Dictionary in FACILITIES:
		if not bool(facility["collision"]):
			continue
		var facility_size: Vector2 = facility["size"]
		obstacle_rects.append(
			Rect2(
				Vector2(facility["position"]) - facility_size * 0.5,
				facility_size
			)
		)
	return obstacle_rects


func _add_static_collision(
	body_name: String,
	body_position: Vector2,
	body_size: Vector2
) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = body_name
	body.position = body_position
	body.collision_layer = 1
	body.collision_mask = 1
	_world.add_child(body)

	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = body_size
	collision_shape.shape = rectangle
	body.add_child(collision_shape)


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])


func _build_fixed_ui() -> void:
	var fixed_ui: CanvasLayer = CanvasLayer.new()
	fixed_ui.name = "FixedUI"
	add_child(fixed_ui)

	_add_hud(fixed_ui)


func _add_hud(fixed_ui: CanvasLayer) -> void:
	var hud: ColorRect = ColorRect.new()
	hud.name = "HUD"
	hud.position = Vector2.ZERO
	hud.size = Vector2(VIEWPORT_SIZE.x, HUD_HEIGHT)
	hud.color = HUD_COLOR
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fixed_ui.add_child(hud)

	var day: int = int(GameManager.state.get("day", 1))
	var time_remaining: float = float(
		GameManager.state.get("service_time_remaining", 0.0)
	)
	var currency: int = int(GameManager.state.get("currency", 0))
	var ready_inventory: Dictionary = _get_ready_inventory()

	_add_hud_label(
		hud,
		"DayLabel",
		"Day %d" % day,
		Rect2(24.0, 14.0, 180.0, 42.0),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	_add_hud_label(
		hud,
		"TimeLabel",
		_format_time(time_remaining),
		Rect2(270.0, 14.0, 180.0, 42.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_add_hud_label(
		hud,
		"CurrencyLabel",
		"%d문" % currency,
		Rect2(516.0, 14.0, 180.0, 42.0),
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	_add_hud_label(
		hud,
		"InventoryLabel",
		"밥 %d  |  고등어 %d" % [
			int(ready_inventory.get("rice", 0)),
			int(ready_inventory.get("mackerel", 0)),
		],
		Rect2(24.0, 62.0, 672.0, 36.0),
		HORIZONTAL_ALIGNMENT_CENTER,
		22
	)


func _add_hud_label(
	parent: Control,
	label_name: String,
	label_text: String,
	label_rect: Rect2,
	alignment: HorizontalAlignment,
	font_size: int = 26
) -> void:
	var label: Label = Label.new()
	label.name = label_name
	label.position = label_rect.position
	label.size = label_rect.size
	label.text = label_text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)


func _begin_pointer(pointer_id: int, position: Vector2) -> void:
	if _active_pointer_id != NO_POINTER_ID:
		return
	if not get_play_area_rect().has_point(position):
		return

	_active_pointer_id = pointer_id
	_gesture_start = position
	_gesture_last = position
	_gesture_is_drag = false


func _move_pointer(pointer_id: int, position: Vector2) -> void:
	if pointer_id != _active_pointer_id:
		return

	var movement: Vector2 = position - _gesture_last
	_gesture_last = position
	if not _gesture_is_drag:
		if position.distance_to(_gesture_start) < DRAG_THRESHOLD:
			return
		_gesture_is_drag = true

	_camera.position = _clamp_camera_position(
		_camera.position - movement
	)


func _end_pointer(pointer_id: int, position: Vector2) -> void:
	if pointer_id != _active_pointer_id:
		return

	var was_drag: bool = _gesture_is_drag
	_active_pointer_id = NO_POINTER_ID
	_gesture_is_drag = false
	if was_drag or not get_play_area_rect().has_point(position):
		return
	request_player_move_to_world(screen_to_world(position))


func _reset_camera() -> void:
	if _camera == null:
		return
	_camera.position = _clamp_camera_position(DEFAULT_CAMERA_POSITION)


func _clamp_camera_position(target_position: Vector2) -> Vector2:
	var half_visible: Vector2 = VIEWPORT_SIZE * 0.5
	var min_position: Vector2 = half_visible
	var max_position: Vector2 = MAP_SIZE - half_visible
	if max_position.x < min_position.x:
		min_position.x = MAP_SIZE.x * 0.5
		max_position.x = min_position.x
	if max_position.y < min_position.y:
		min_position.y = MAP_SIZE.y * 0.5
		max_position.y = min_position.y

	return Vector2(
		clampf(target_position.x, min_position.x, max_position.x),
		clampf(target_position.y, min_position.y, max_position.y)
	)


func _on_viewport_size_changed() -> void:
	if _camera == null:
		return
	_camera.position = _clamp_camera_position(_camera.position)


func _get_ready_inventory() -> Dictionary:
	var inventory: Variant = GameManager.state.get("inventory", {})
	if not inventory is Dictionary:
		return {}
	var ready_inventory: Variant = inventory.get("ready", {})
	if not ready_inventory is Dictionary:
		return {}
	return ready_inventory


func _format_time(seconds: float) -> String:
	var total_seconds: int = maxi(0, int(ceilf(seconds)))
	@warning_ignore("integer_division")
	var minutes: int = total_seconds / 60
	var remaining_seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]
