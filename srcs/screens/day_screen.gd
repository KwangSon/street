extends Node2D
class_name DayScreen

signal screen_change_requested

const DayPlayerScript: Script = preload(
	"res://srcs/day/day_player.gd"
)
const DayNavigationScript: Script = preload(
	"res://srcs/day/day_navigation.gd"
)
const DayInteractionControllerScript: Script = preload(
	"res://srcs/day/day_interaction_controller.gd"
)
const CookingCounterScript: Script = preload(
	"res://srcs/day/cooking_counter.gd"
)
const DayCustomerManagerScript: Script = preload(
	"res://srcs/day/day_customer_manager.gd"
)
const DayPreparationSourceScript: Script = preload(
	"res://srcs/day/day_preparation_source.gd"
)
const DayServerScript: Script = preload(
	"res://srcs/day/day_server.gd"
)
const DayChefScript: Script = preload(
	"res://srcs/day/day_chef.gd"
)

const VIEWPORT_SIZE: Vector2 = Vector2(720.0, 1280.0)
const MAP_SIZE: Vector2 = Vector2(1200.0, 1920.0)
const STAGE_TWO_MAP_SIZE: Vector2 = Vector2(1600.0, 2400.0)
const DEFAULT_CAMERA_POSITION: Vector2 = Vector2(360.0, 640.0)
const PLAYER_START_POSITION: Vector2 = Vector2(360.0, 620.0)
const STAGE_TWO_DEFAULT_CAMERA_POSITION: Vector2 = Vector2(
	500.0,
	700.0
)
const STAGE_TWO_PLAYER_START_POSITION: Vector2 = Vector2(
	500.0,
	720.0
)
const DRAG_THRESHOLD: float = 8.0
const EARLY_CLOSE_HOLD_DURATION: float = 2.0

const HUD_HEIGHT: float = 112.0
const MOUSE_POINTER_ID: int = -1
const NO_POINTER_ID: int = -2

const MAP_COLOR: Color = Color("b9b7ad")
const STAGE_TWO_MAP_COLOR: Color = Color("c7c1b2")
const GRID_COLOR: Color = Color("aaa89f")
const HUD_COLOR: Color = Color("35291f")
const HUD_TEXT_COLOR: Color = Color("fff4d6")
const SETTLEMENT_BACKGROUND_COLOR: Color = Color("2b211b")
const SETTLEMENT_PANEL_COLOR: Color = Color("ead8b7")
const SETTLEMENT_TEXT_COLOR: Color = Color("35291f")
const SEAT_2_ID: String = "seat_2"
const SEAT_2_POSITION: Vector2 = Vector2(900.0, 920.0)
const SEAT_2_TARGET: Vector2 = Vector2(900.0, 830.0)
const SEAT_3_ID: String = "seat_3"
const SEAT_3_POSITION: Vector2 = Vector2(500.0, 1120.0)
const SEAT_3_TARGET: Vector2 = Vector2(500.0, 1030.0)
const SEAT_4_ID: String = "seat_4"
const SEAT_4_POSITION: Vector2 = Vector2(900.0, 1200.0)
const SEAT_4_TARGET: Vector2 = Vector2(900.0, 1110.0)
const SERVER_START_POSITION: Vector2 = Vector2(900.0, 1320.0)
const CHEF_START_POSITION: Vector2 = Vector2(760.0, 620.0)
const STAGE_TWO_SERVER_START_POSITION: Vector2 = Vector2(
	1280.0,
	1500.0
)
const STAGE_TWO_CHEF_START_POSITION: Vector2 = Vector2(
	900.0,
	640.0
)
const STAGE_TWO_ENTRANCE_POSITION: Vector2 = Vector2(160.0, 1120.0)
const STAGE_TWO_SEAT_1_TARGET: Vector2 = Vector2(620.0, 950.0)
const STAGE_TWO_SEAT_2_TARGET: Vector2 = Vector2(1050.0, 950.0)
const STAGE_TWO_SEAT_3_TARGET: Vector2 = Vector2(620.0, 1250.0)
const STAGE_TWO_SEAT_4_TARGET: Vector2 = Vector2(1050.0, 1250.0)

const FACILITIES: Array[Dictionary] = [
	{
		"name": "FishStation",
		"label": "생선류",
		"position": Vector2(120.0, 300.0),
		"size": Vector2(140.0, 96.0),
		"color": Color("79986b"),
		"collision": true,
	},
	{
		"name": "RiceStation",
		"label": "밥",
		"position": Vector2(320.0, 300.0),
		"size": Vector2(140.0, 96.0),
		"color": Color("c6a477"),
		"collision": true,
	},
	{
		"name": "OtherStation",
		"label": "기타요리",
		"position": Vector2(760.0, 300.0),
		"size": Vector2(160.0, 96.0),
		"color": Color("d7bd61"),
		"collision": true,
	},
	{
		"name": "CookingCounter",
		"label": "조리대",
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
		"name": "Seat2",
		"label": "좌석 2",
		"position": SEAT_2_POSITION,
		"size": Vector2(120.0, 100.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
	{
		"name": "Seat3",
		"label": "좌석 3",
		"position": SEAT_3_POSITION,
		"size": Vector2(120.0, 100.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
	{
		"name": "Seat4",
		"label": "좌석 4",
		"position": SEAT_4_POSITION,
		"size": Vector2(120.0, 100.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
]

const STAGE_TWO_FACILITIES: Array[Dictionary] = [
	{
		"name": "LocationSign",
		"label": "Stage 2 · 넓은 점포",
		"position": Vector2(800.0, 170.0),
		"size": Vector2(360.0, 72.0),
		"color": Color("e2c17c"),
		"collision": false,
	},
	{
		"name": "FishStation",
		"label": "생선류",
		"position": Vector2(160.0, 340.0),
		"size": Vector2(160.0, 104.0),
		"color": Color("79986b"),
		"collision": true,
	},
	{
		"name": "RiceStation",
		"label": "밥",
		"position": Vector2(430.0, 340.0),
		"size": Vector2(160.0, 104.0),
		"color": Color("c6a477"),
		"collision": true,
	},
	{
		"name": "CookingCounter",
		"label": "조리대",
		"position": Vector2(720.0, 340.0),
		"size": Vector2(210.0, 104.0),
		"color": Color("7197ad"),
		"collision": true,
	},
	{
		"name": "OtherStation",
		"label": "기타요리",
		"position": Vector2(1060.0, 340.0),
		"size": Vector2(190.0, 104.0),
		"color": Color("d7bd61"),
		"collision": true,
	},
	{
		"name": "Entrance",
		"label": "넓은 입구",
		"position": STAGE_TWO_ENTRANCE_POSITION,
		"size": Vector2(180.0, 96.0),
		"color": Color("c98e64"),
		"collision": false,
	},
	{
		"name": "Seat1",
		"label": "좌석 1",
		"position": Vector2(620.0, 1040.0),
		"size": Vector2(140.0, 112.0),
		"color": Color("a57853"),
		"collision": true,
	},
	{
		"name": "Seat2",
		"label": "좌석 2",
		"position": Vector2(1050.0, 1040.0),
		"size": Vector2(140.0, 112.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
	{
		"name": "Seat3",
		"label": "좌석 3",
		"position": Vector2(620.0, 1340.0),
		"size": Vector2(140.0, 112.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
	{
		"name": "Seat4",
		"label": "좌석 4",
		"position": Vector2(1050.0, 1340.0),
		"size": Vector2(140.0, 112.0),
		"color": Color("8d6b51"),
		"collision": true,
	},
]

var _world: Node2D
var _map_size: Vector2 = MAP_SIZE
var _facilities: Array[Dictionary] = FACILITIES
var _default_camera_position: Vector2 = DEFAULT_CAMERA_POSITION
var _player_start_position: Vector2 = PLAYER_START_POSITION
var _entrance_position: Vector2 = Vector2(120.0, 860.0)
var _queue_positions: Array[Vector2] = [
	Vector2(190.0, 860.0),
	Vector2(260.0, 860.0),
	Vector2(330.0, 860.0),
]
var _seat_targets: Dictionary = {
	"seat_1": Vector2(500.0, 750.0),
	SEAT_2_ID: SEAT_2_TARGET,
	SEAT_3_ID: SEAT_3_TARGET,
	SEAT_4_ID: SEAT_4_TARGET,
}
var _server_start_position: Vector2 = SERVER_START_POSITION
var _chef_start_position: Vector2 = CHEF_START_POSITION
var _player: DayPlayer
var _camera: Camera2D
var _navigation: DayNavigation
var _interaction_controller: DayInteractionController
var _cooking_counter: CookingCounter
var _customer_manager: DayCustomerManager
var _ingredient_box: DayPreparationSource
var _egg_box: DayPreparationSource
var _rice_pot: DayPreparationSource
var _server: DayServer
var _chef: DayChef
var _inventory_label: Label
var _currency_label: Label
var _time_label: Label
var _early_close_button: Button
var _settlement_panel: ColorRect
var _settlement_summary_label: Label
var _settlement_progress_label: Label
var _settlement_continue_button: Button
var _stage_two_purchase_button: Button
var _employee_button: Button
var _employee_panel: ColorRect
var _employee_summary_label: Label
var _chef_hire_button: Button
var _service_hire_button: Button
var _upgrade_button: Button
var _upgrade_panel: ColorRect
var _upgrade_summary_label: Label
var _seat_upgrade_button: Button
var _mackerel_upgrade_button: Button
var _egg_upgrade_button: Button
var _active_pointer_id: int = NO_POINTER_ID
var _gesture_start: Vector2 = Vector2.ZERO
var _gesture_last: Vector2 = Vector2.ZERO
var _gesture_is_drag: bool = false
var _early_close_holding: bool = false
var _early_close_progress: float = 0.0


func _ready() -> void:
	name = "DayScreen"
	GameManager.ensure_day_runtime_state()
	_configure_stage_layout()
	_build_world()
	_build_fixed_ui()
	_refresh_inventory_hud()
	if not GameManager.state_changed.is_connected(
		_on_game_state_changed
	):
		GameManager.state_changed.connect(_on_game_state_changed)
	if not GameManager.service_time_changed.is_connected(
		_on_service_time_changed
	):
		GameManager.service_time_changed.connect(
			_on_service_time_changed
		)
	_reset_camera()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _process(delta: float) -> void:
	GameManager.tick_service_time(delta)
	GameManager.try_close_exhausted_service()
	_tick_early_close_hold(delta)
	GameManager.try_begin_settlement()


func _exit_tree() -> void:
	if _player != null:
		_player.clear_path()
	_active_pointer_id = NO_POINTER_ID
	_early_close_holding = false
	_early_close_progress = 0.0


func _input(event: InputEvent) -> void:
	if (
		String(GameManager.state.get("screen", ""))
		!= GameManager.SCREEN_DAY
		or String(GameManager.state.get("phase", ""))
		!= GameManager.PHASE_SERVICE
	):
		return
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


func get_interaction_controller() -> DayInteractionController:
	return _interaction_controller


func get_cooking_counter() -> CookingCounter:
	return _cooking_counter


func get_customer_manager() -> DayCustomerManager:
	return _customer_manager


func get_ingredient_box() -> DayPreparationSource:
	return _ingredient_box


func get_egg_box() -> DayPreparationSource:
	return _egg_box


func get_rice_pot() -> DayPreparationSource:
	return _rice_pot


func get_server() -> DayServer:
	return _server


func get_chef() -> DayChef:
	return _chef


func get_employee_button() -> Button:
	return _employee_button


func get_employee_panel() -> ColorRect:
	return _employee_panel


func get_chef_hire_button() -> Button:
	return _chef_hire_button


func get_service_hire_button() -> Button:
	return _service_hire_button


func get_upgrade_button() -> Button:
	return _upgrade_button


func get_upgrade_panel() -> ColorRect:
	return _upgrade_panel


func get_seat_upgrade_button() -> Button:
	return _seat_upgrade_button


func get_mackerel_upgrade_button() -> Button:
	return _mackerel_upgrade_button


func get_egg_upgrade_button() -> Button:
	return _egg_upgrade_button


func get_early_close_button() -> Button:
	return _early_close_button


func get_early_close_hold_progress() -> float:
	return _early_close_progress


func get_settlement_panel() -> ColorRect:
	return _settlement_panel


func get_settlement_continue_button() -> Button:
	return _settlement_continue_button


func get_stage_two_purchase_button() -> Button:
	return _stage_two_purchase_button


func get_current_map_size() -> Vector2:
	return _map_size


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


func _configure_stage_layout() -> void:
	if GameManager.get_current_stage() != GameManager.STAGE_TWO:
		return
	_map_size = STAGE_TWO_MAP_SIZE
	_facilities = STAGE_TWO_FACILITIES
	_default_camera_position = STAGE_TWO_DEFAULT_CAMERA_POSITION
	_player_start_position = STAGE_TWO_PLAYER_START_POSITION
	_entrance_position = STAGE_TWO_ENTRANCE_POSITION
	_queue_positions = [
		Vector2(250.0, 1120.0),
		Vector2(340.0, 1120.0),
		Vector2(430.0, 1120.0),
	]
	_seat_targets = {
		"seat_1": STAGE_TWO_SEAT_1_TARGET,
		SEAT_2_ID: STAGE_TWO_SEAT_2_TARGET,
		SEAT_3_ID: STAGE_TWO_SEAT_3_TARGET,
		SEAT_4_ID: STAGE_TWO_SEAT_4_TARGET,
	}
	_server_start_position = STAGE_TWO_SERVER_START_POSITION
	_chef_start_position = STAGE_TWO_CHEF_START_POSITION


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	_add_map_background()
	_add_map_boundaries()
	for facility: Dictionary in _facilities:
		if not _should_build_facility(String(facility["name"])):
			continue
		_add_facility(facility)

	_player = DayPlayerScript.new()
	_player.move_speed = DayPlayer.DEFAULT_MOVE_SPEED
	_player.position = _player_start_position
	_world.add_child(_player)
	_player.set_carried_item(GameManager.get_carried_item())

	_interaction_controller = DayInteractionControllerScript.new()
	_interaction_controller.name = "InteractionController"
	_interaction_controller.configure(_player)
	_interaction_controller.register_interactable(_cooking_counter)
	_interaction_controller.register_interactable(_ingredient_box)
	_interaction_controller.register_interactable(_rice_pot)
	if _egg_box != null:
		_interaction_controller.register_interactable(_egg_box)
	_world.add_child(_interaction_controller)

	_customer_manager = DayCustomerManagerScript.new()
	_customer_manager.name = "CustomerManager"
	_customer_manager.configure(
		_entrance_position,
		_get_unlocked_seat_targets(),
		_queue_positions
	)
	_customer_manager.interactable_created.connect(
		_on_customer_interactable_created
	)
	_world.add_child(_customer_manager)

	_camera = Camera2D.new()
	_camera.name = "StageCamera"
	_camera.position = _default_camera_position
	_camera.position_smoothing_enabled = false
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_map_size.x)
	_camera.limit_bottom = int(_map_size.y)
	_camera.enabled = true
	_world.add_child(_camera)

	_navigation = DayNavigationScript.new()
	_navigation.configure(
		_map_size,
		DayPlayer.COLLISION_RADIUS,
		_get_navigation_obstacle_rects()
	)
	_sync_employees()


func _add_map_background() -> void:
	var background: Polygon2D = Polygon2D.new()
	background.name = "MapBackground"
	background.color = (
		STAGE_TWO_MAP_COLOR
		if GameManager.get_current_stage() == GameManager.STAGE_TWO
		else MAP_COLOR
	)
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(_map_size.x, 0.0),
		_map_size,
		Vector2(0.0, _map_size.y),
	])
	background.z_index = -10
	_world.add_child(background)

	for x_position: float in range(0, int(_map_size.x) + 1, 120):
		_add_grid_line(
			Vector2(x_position, 0.0),
			Vector2(x_position, _map_size.y)
		)
	for y_position: float in range(0, int(_map_size.y) + 1, 120):
		_add_grid_line(
			Vector2(0.0, y_position),
			Vector2(_map_size.x, y_position)
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
		Vector2(_map_size.x * 0.5, -WALL_THICKNESS * 0.5),
		Vector2(
			_map_size.x + WALL_THICKNESS * 2.0,
			WALL_THICKNESS
		)
	)
	_add_static_collision(
		"BoundaryBottom",
		Vector2(
			_map_size.x * 0.5,
			_map_size.y + WALL_THICKNESS * 0.5
		),
		Vector2(
			_map_size.x + WALL_THICKNESS * 2.0,
			WALL_THICKNESS
		)
	)
	_add_static_collision(
		"BoundaryLeft",
		Vector2(-WALL_THICKNESS * 0.5, _map_size.y * 0.5),
		Vector2(WALL_THICKNESS, _map_size.y)
	)
	_add_static_collision(
		"BoundaryRight",
		Vector2(
			_map_size.x + WALL_THICKNESS * 0.5,
			_map_size.y * 0.5
		),
		Vector2(WALL_THICKNESS, _map_size.y)
	)


func _add_facility(facility: Dictionary) -> void:
	var facility_node: Node2D
	var facility_name: String = String(facility["name"])
	if facility_name == "CookingCounter":
		var menu_station: CookingCounter = CookingCounterScript.new()
		menu_station.configure(
			facility["size"],
			facility["color"],
			GameManager.MENU_MACKEREL
		)
		_cooking_counter = menu_station
		facility_node = menu_station
	elif facility_name in [
		"FishStation",
		"OtherStation",
		"RiceStation",
	]:
		var preparation_source: DayPreparationSource = (
			DayPreparationSourceScript.new()
		)
		var source_kind: DayPreparationSource.SourceKind = (
			DayPreparationSource.SourceKind.FISH
			if facility_name == "FishStation"
			else DayPreparationSource.SourceKind.OTHER
			if facility_name == "OtherStation"
			else DayPreparationSource.SourceKind.RICE
		)
		preparation_source.configure(
			source_kind,
			facility["size"],
			facility["color"],
			String(facility["label"])
		)
		if facility_name == "FishStation":
			_ingredient_box = preparation_source
		elif facility_name == "OtherStation":
			_egg_box = preparation_source
		else:
			_rice_pot = preparation_source
		facility_node = preparation_source
	else:
		facility_node = Node2D.new()
	facility_node.name = String(facility["name"])
	facility_node.position = facility["position"]
	_world.add_child(facility_node)

	var facility_size: Vector2 = facility["size"]
	if (
		facility_node != _cooking_counter
		and facility_node != _ingredient_box
		and facility_node != _egg_box
		and facility_node != _rice_pot
	):
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
		label.add_theme_color_override(
			"font_color",
			Color("35291f")
		)
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
	for facility: Dictionary in _facilities:
		if (
			not bool(facility["collision"])
			or not _should_build_facility(
				String(facility["name"])
			)
		):
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
	_add_employee_ui(fixed_ui)
	_add_upgrade_ui(fixed_ui)
	_add_settlement_ui(fixed_ui)


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
		"S%d · Day %d" % [
			GameManager.get_current_stage(),
			day,
		],
		Rect2(144.0, 14.0, 120.0, 42.0),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	_time_label = _add_hud_label(
		hud,
		"TimeLabel",
		_format_time(time_remaining),
		Rect2(270.0, 14.0, 180.0, 42.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_currency_label = _add_hud_label(
		hud,
		"CurrencyLabel",
		"%d문" % currency,
		Rect2(516.0, 14.0, 180.0, 42.0),
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	_inventory_label = _add_hud_label(
		hud,
		"InventoryLabel",
		"%s  |  %s" % [
			_format_ready_inventory_entry(
				"밥",
				"rice",
				ready_inventory
			),
			_format_ready_inventory_entry(
				"고등어",
				GameManager.MENU_MACKEREL,
				ready_inventory
			),
		],
		Rect2(24.0, 62.0, 672.0, 36.0),
		HORIZONTAL_ALIGNMENT_CENTER,
		22
	)

	_early_close_button = Button.new()
	_early_close_button.name = "EarlyCloseButton"
	_early_close_button.position = Vector2(560.0, 62.0)
	_early_close_button.size = Vector2(136.0, 46.0)
	_early_close_button.focus_mode = Control.FOCUS_NONE
	_early_close_button.add_theme_font_size_override("font_size", 14)
	_early_close_button.button_down.connect(
		_on_early_close_button_down
	)
	_early_close_button.button_up.connect(
		_on_early_close_button_up
	)
	hud.add_child(_early_close_button)
	_refresh_early_close_button()


func _add_hud_label(
	parent: Control,
	label_name: String,
	label_text: String,
	label_rect: Rect2,
	alignment: HorizontalAlignment,
	font_size: int = 26
) -> Label:
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
	return label


func _add_employee_ui(fixed_ui: CanvasLayer) -> void:
	_employee_button = Button.new()
	_employee_button.name = "EmployeeButton"
	_employee_button.position = Vector2(16.0, 1188.0)
	_employee_button.size = Vector2(150.0, 70.0)
	_employee_button.text = "직원 고용"
	_employee_button.focus_mode = Control.FOCUS_NONE
	_employee_button.add_theme_font_size_override("font_size", 20)
	_employee_button.pressed.connect(_on_employee_button_pressed)
	fixed_ui.add_child(_employee_button)

	_employee_panel = ColorRect.new()
	_employee_panel.name = "EmployeePanel"
	_employee_panel.position = Vector2(42.0, 650.0)
	_employee_panel.size = Vector2(636.0, 500.0)
	_employee_panel.color = SETTLEMENT_PANEL_COLOR
	_employee_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	fixed_ui.add_child(_employee_panel)

	var title: Label = Label.new()
	title.position = Vector2(30.0, 22.0)
	title.size = Vector2(470.0, 54.0)
	title.text = "직원 고용 · 주급"
	title.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	title.add_theme_font_size_override("font_size", 30)
	_employee_panel.add_child(title)

	var close_button: Button = Button.new()
	close_button.name = "CloseButton"
	close_button.position = Vector2(538.0, 18.0)
	close_button.size = Vector2(70.0, 58.0)
	close_button.text = "닫기"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_on_employee_close_pressed)
	_employee_panel.add_child(close_button)

	_employee_summary_label = Label.new()
	_employee_summary_label.name = "SummaryLabel"
	_employee_summary_label.position = Vector2(30.0, 86.0)
	_employee_summary_label.size = Vector2(576.0, 92.0)
	_employee_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_employee_summary_label.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	_employee_summary_label.add_theme_font_size_override(
		"font_size",
		18
	)
	_employee_panel.add_child(_employee_summary_label)

	_chef_hire_button = Button.new()
	_chef_hire_button.name = "ChefHireButton"
	_chef_hire_button.position = Vector2(30.0, 194.0)
	_chef_hire_button.size = Vector2(576.0, 112.0)
	_chef_hire_button.focus_mode = Control.FOCUS_NONE
	_chef_hire_button.add_theme_font_size_override("font_size", 20)
	_chef_hire_button.pressed.connect(_on_chef_hire_pressed)
	_employee_panel.add_child(_chef_hire_button)

	_service_hire_button = Button.new()
	_service_hire_button.name = "ServiceHireButton"
	_service_hire_button.position = Vector2(30.0, 326.0)
	_service_hire_button.size = Vector2(576.0, 112.0)
	_service_hire_button.focus_mode = Control.FOCUS_NONE
	_service_hire_button.add_theme_font_size_override(
		"font_size",
		20
	)
	_service_hire_button.pressed.connect(
		_on_service_hire_pressed
	)
	_employee_panel.add_child(_service_hire_button)
	_employee_panel.visible = false
	_refresh_employee_ui()


func _add_upgrade_ui(fixed_ui: CanvasLayer) -> void:
	_upgrade_button = Button.new()
	_upgrade_button.name = "UpgradeButton"
	_upgrade_button.position = Vector2(554.0, 1188.0)
	_upgrade_button.size = Vector2(150.0, 70.0)
	_upgrade_button.text = "해금"
	_upgrade_button.focus_mode = Control.FOCUS_NONE
	_upgrade_button.add_theme_font_size_override("font_size", 20)
	_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	fixed_ui.add_child(_upgrade_button)

	_upgrade_panel = ColorRect.new()
	_upgrade_panel.name = "UpgradePanel"
	_upgrade_panel.position = Vector2(42.0, 530.0)
	_upgrade_panel.size = Vector2(636.0, 620.0)
	_upgrade_panel.color = SETTLEMENT_PANEL_COLOR
	_upgrade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	fixed_ui.add_child(_upgrade_panel)

	var title: Label = Label.new()
	title.position = Vector2(30.0, 22.0)
	title.size = Vector2(470.0, 54.0)
	title.text = "해금 · 업그레이드"
	title.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	title.add_theme_font_size_override("font_size", 30)
	_upgrade_panel.add_child(title)

	var close_button: Button = Button.new()
	close_button.name = "CloseButton"
	close_button.position = Vector2(538.0, 18.0)
	close_button.size = Vector2(70.0, 58.0)
	close_button.text = "닫기"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_on_upgrade_close_pressed)
	_upgrade_panel.add_child(close_button)

	_upgrade_summary_label = Label.new()
	_upgrade_summary_label.name = "SummaryLabel"
	_upgrade_summary_label.position = Vector2(30.0, 82.0)
	_upgrade_summary_label.size = Vector2(576.0, 66.0)
	_upgrade_summary_label.text = (
		"구매 즉시 좌석이 활성화되고 메뉴 성능과 주문 후보가 갱신됩니다."
	)
	_upgrade_summary_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	_upgrade_summary_label.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	_upgrade_summary_label.add_theme_font_size_override(
		"font_size",
		18
	)
	_upgrade_panel.add_child(_upgrade_summary_label)

	_seat_upgrade_button = _add_upgrade_option_button(
		_upgrade_panel,
		"SeatUpgradeButton",
		Vector2(30.0, 158.0),
		_on_seat_upgrade_pressed
	)
	_mackerel_upgrade_button = _add_upgrade_option_button(
		_upgrade_panel,
		"MackerelUpgradeButton",
		Vector2(30.0, 294.0),
		_on_mackerel_upgrade_pressed
	)
	_egg_upgrade_button = _add_upgrade_option_button(
		_upgrade_panel,
		"EggUpgradeButton",
		Vector2(30.0, 430.0),
		_on_egg_upgrade_pressed
	)
	_upgrade_panel.visible = false
	_refresh_upgrade_ui()


func _add_upgrade_option_button(
	parent: Control,
	button_name: String,
	button_position: Vector2,
	pressed_callback: Callable
) -> Button:
	var button: Button = Button.new()
	button.name = button_name
	button.position = button_position
	button.size = Vector2(576.0, 116.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(pressed_callback)
	parent.add_child(button)
	return button


func _add_settlement_ui(fixed_ui: CanvasLayer) -> void:
	_settlement_panel = ColorRect.new()
	_settlement_panel.name = "SettlementPanel"
	_settlement_panel.position = Vector2.ZERO
	_settlement_panel.size = VIEWPORT_SIZE
	_settlement_panel.color = SETTLEMENT_BACKGROUND_COLOR
	_settlement_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	fixed_ui.add_child(_settlement_panel)

	var content: ColorRect = ColorRect.new()
	content.name = "Content"
	content.position = Vector2(54.0, 84.0)
	content.size = Vector2(612.0, 1080.0)
	content.color = SETTLEMENT_PANEL_COLOR
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settlement_panel.add_child(content)

	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.position = Vector2(30.0, 34.0)
	title.size = Vector2(552.0, 70.0)
	title.text = "오늘의 영업 정산"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	title.add_theme_font_size_override("font_size", 36)
	content.add_child(title)

	_settlement_summary_label = Label.new()
	_settlement_summary_label.name = "SummaryLabel"
	_settlement_summary_label.position = Vector2(54.0, 132.0)
	_settlement_summary_label.size = Vector2(504.0, 570.0)
	_settlement_summary_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_TOP
	)
	_settlement_summary_label.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	_settlement_summary_label.add_theme_font_size_override(
		"font_size",
		25
	)
	content.add_child(_settlement_summary_label)

	_settlement_progress_label = Label.new()
	_settlement_progress_label.name = "ProgressLabel"
	_settlement_progress_label.position = Vector2(54.0, 724.0)
	_settlement_progress_label.size = Vector2(504.0, 170.0)
	_settlement_progress_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_settlement_progress_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	_settlement_progress_label.add_theme_color_override(
		"font_color",
		SETTLEMENT_TEXT_COLOR
	)
	_settlement_progress_label.add_theme_font_size_override(
		"font_size",
		22
	)
	content.add_child(_settlement_progress_label)

	_stage_two_purchase_button = Button.new()
	_stage_two_purchase_button.name = "StageTwoPurchaseButton"
	_stage_two_purchase_button.position = Vector2(66.0, 900.0)
	_stage_two_purchase_button.size = Vector2(480.0, 76.0)
	_stage_two_purchase_button.add_theme_font_size_override(
		"font_size",
		21
	)
	_stage_two_purchase_button.pressed.connect(
		_on_stage_two_purchase_pressed
	)
	content.add_child(_stage_two_purchase_button)

	_settlement_continue_button = Button.new()
	_settlement_continue_button.name = "ContinueButton"
	_settlement_continue_button.position = Vector2(66.0, 988.0)
	_settlement_continue_button.size = Vector2(480.0, 70.0)
	_settlement_continue_button.text = "새벽 장보기로"
	_settlement_continue_button.add_theme_font_size_override(
		"font_size",
		27
	)
	_settlement_continue_button.pressed.connect(
		_on_settlement_continue_pressed
	)
	content.add_child(_settlement_continue_button)

	_refresh_settlement_ui()


func _begin_pointer(pointer_id: int, position: Vector2) -> void:
	if _active_pointer_id != NO_POINTER_ID:
		return
	if _is_fixed_bottom_ui_point(position):
		return
	if not get_play_area_rect().has_point(position):
		return

	_active_pointer_id = pointer_id
	_gesture_start = position
	_gesture_last = position
	_gesture_is_drag = false


func _is_fixed_bottom_ui_point(screen_position: Vector2) -> bool:
	for control: Control in [
		_employee_button,
		_upgrade_button,
	]:
		if (
			control != null
			and control.visible
			and Rect2(
				control.position,
				control.size
			).has_point(screen_position)
		):
			return true
	for panel: Control in [_employee_panel, _upgrade_panel]:
		if (
			panel != null
			and panel.visible
			and Rect2(
				panel.position,
				panel.size
			).has_point(screen_position)
		):
			return true
	return false


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
	_camera.position = _clamp_camera_position(
		_default_camera_position
	)


func _clamp_camera_position(target_position: Vector2) -> Vector2:
	var half_visible: Vector2 = VIEWPORT_SIZE * 0.5
	var min_position: Vector2 = half_visible
	var max_position: Vector2 = _map_size - half_visible
	if max_position.x < min_position.x:
		min_position.x = _map_size.x * 0.5
		max_position.x = min_position.x
	if max_position.y < min_position.y:
		min_position.y = _map_size.y * 0.5
		max_position.y = min_position.y

	return Vector2(
		clampf(target_position.x, min_position.x, max_position.x),
		clampf(target_position.y, min_position.y, max_position.y)
	)


func _on_viewport_size_changed() -> void:
	if _camera == null:
		return
	_camera.position = _clamp_camera_position(_camera.position)


func _on_game_state_changed() -> void:
	_install_unlocked_seats()
	_sync_employees()
	_refresh_inventory_hud()
	_refresh_currency_hud()
	_refresh_employee_ui()
	_refresh_upgrade_ui()
	_refresh_early_close_button()
	_refresh_settlement_ui()
	if _player != null:
		_player.set_carried_item(GameManager.get_carried_item())


func _on_service_time_changed(time_remaining: float) -> void:
	if _time_label != null:
		_time_label.text = _format_time(time_remaining)
	_refresh_early_close_button()


func _on_early_close_button_down() -> void:
	if not GameManager.is_accepting_customers():
		return
	_early_close_holding = true
	_early_close_progress = 0.0
	_refresh_early_close_button()


func _on_early_close_button_up() -> void:
	if not _early_close_holding:
		return
	_early_close_holding = false
	_early_close_progress = 0.0
	_refresh_early_close_button()


func _tick_early_close_hold(delta: float) -> void:
	if not _early_close_holding:
		return
	if not GameManager.is_accepting_customers():
		_early_close_holding = false
		_early_close_progress = 0.0
		_refresh_early_close_button()
		return
	_early_close_progress = minf(
		_early_close_progress + maxf(delta, 0.0),
		EARLY_CLOSE_HOLD_DURATION
	)
	if _early_close_progress >= EARLY_CLOSE_HOLD_DURATION:
		_early_close_holding = false
		GameManager.request_early_close()
	_refresh_early_close_button()


func _refresh_early_close_button() -> void:
	if _early_close_button == null:
		return
	var is_service: bool = (
		String(GameManager.state.get("screen", ""))
		== GameManager.SCREEN_DAY
		and String(GameManager.state.get("phase", ""))
		== GameManager.PHASE_SERVICE
	)
	_early_close_button.visible = is_service
	if not is_service:
		_early_close_holding = false
		_early_close_progress = 0.0
		return
	var is_accepting: bool = GameManager.is_accepting_customers()
	_early_close_button.disabled = not is_accepting
	if not is_accepting:
		_early_close_button.text = "마감 대기"
	elif _early_close_holding:
		var remaining: float = maxf(
			EARLY_CLOSE_HOLD_DURATION - _early_close_progress,
			0.0
		)
		_early_close_button.text = "마감 %.1f초" % remaining
	else:
		_early_close_button.text = "조기 마감"


func _on_settlement_continue_pressed() -> void:
	if GameManager.request_dawn_after_settlement():
		screen_change_requested.emit()


func _on_stage_two_purchase_pressed() -> void:
	if GameManager.try_purchase_stage_two_location():
		screen_change_requested.emit()


func _on_employee_button_pressed() -> void:
	if _employee_panel == null:
		return
	if _upgrade_panel != null:
		_upgrade_panel.visible = false
	_employee_panel.visible = not _employee_panel.visible
	_refresh_employee_ui()


func _on_employee_close_pressed() -> void:
	if _employee_panel != null:
		_employee_panel.visible = false


func _on_chef_hire_pressed() -> void:
	GameManager.try_hire_employee(GameManager.STAFF_ROLE_CHEF)
	_refresh_employee_ui()


func _on_service_hire_pressed() -> void:
	GameManager.try_hire_employee(GameManager.STAFF_ROLE_SERVICE)
	_refresh_employee_ui()


func _on_upgrade_button_pressed() -> void:
	if _upgrade_panel == null:
		return
	if _employee_panel != null:
		_employee_panel.visible = false
	_upgrade_panel.visible = not _upgrade_panel.visible
	_refresh_upgrade_ui()


func _on_upgrade_close_pressed() -> void:
	if _upgrade_panel != null:
		_upgrade_panel.visible = false


func _on_seat_upgrade_pressed() -> void:
	GameManager.try_purchase_next_seat()
	_refresh_upgrade_ui()


func _on_mackerel_upgrade_pressed() -> void:
	GameManager.try_purchase_menu_station_upgrade(
		GameManager.MENU_MACKEREL
	)
	_refresh_upgrade_ui()


func _on_egg_upgrade_pressed() -> void:
	GameManager.try_purchase_menu_station_upgrade(
		GameManager.MENU_EGG
	)
	_refresh_upgrade_ui()


func _on_customer_interactable_created(
	interactable: DayInteractable
) -> void:
	_interaction_controller.register_interactable(interactable)


func _install_unlocked_seats() -> void:
	if _world == null:
		return
	var unlocked_seats: int = GameManager.get_unlocked_seat_count()
	var seat_data: Dictionary = {
		2: {
			"name": "Seat2",
			"id": SEAT_2_ID,
			"target": _seat_targets[SEAT_2_ID],
		},
		3: {
			"name": "Seat3",
			"id": SEAT_3_ID,
			"target": _seat_targets[SEAT_3_ID],
		},
		4: {
			"name": "Seat4",
			"id": SEAT_4_ID,
			"target": _seat_targets[SEAT_4_ID],
		},
	}
	var installed_any: bool = false
	for seat_number: int in range(2, unlocked_seats + 1):
		var current_seat: Dictionary = seat_data[seat_number]
		var facility_name: String = String(current_seat["name"])
		if _world.get_node_or_null(facility_name) != null:
			continue
		for facility: Dictionary in _facilities:
			if String(facility["name"]) != facility_name:
				continue
			_add_facility(facility)
			installed_any = true
			break
		if _customer_manager != null:
			_customer_manager.add_seat(
				String(current_seat["id"]),
				Vector2(current_seat["target"])
			)
	if installed_any and _navigation != null:
		_navigation.configure(
			_map_size,
			DayPlayer.COLLISION_RADIUS,
			_get_navigation_obstacle_rects()
		)


func _install_server_if_hired() -> void:
	if (
		_world == null
		or not GameManager.is_server_hired()
		or _server != null
		or _navigation == null
		or _customer_manager == null
	):
		return
	_server = DayServerScript.new()
	var station_positions: Dictionary = {
		GameManager.MENU_MACKEREL: _cooking_counter.position,
		GameManager.MENU_EGG: _cooking_counter.position,
	}
	_server.configure(
		_server_start_position,
		station_positions,
		_customer_manager,
		_navigation
	)
	_world.add_child(_server)


func _install_chef_if_hired() -> void:
	if (
		_world == null
		or not GameManager.is_employee_hired(
			GameManager.STAFF_ROLE_CHEF
		)
		or _chef != null
		or _navigation == null
	):
		return
	_chef = DayChefScript.new()
	_chef.configure(
		_chef_start_position,
		{
			GameManager.KITCHEN_STATION_FISH:
				_ingredient_box.position,
			GameManager.KITCHEN_STATION_RICE:
				_rice_pot.position,
			GameManager.KITCHEN_STATION_OTHER:
				_egg_box.position,
			GameManager.KITCHEN_STATION_COUNTER:
				_cooking_counter.position,
		},
		_navigation
	)
	_world.add_child(_chef)


func _sync_employees() -> void:
	_install_server_if_hired()
	_install_chef_if_hired()
	if (
		_server != null
		and not GameManager.is_employee_hired(
			GameManager.STAFF_ROLE_SERVICE
		)
	):
		_server.queue_free()
		_server = null
	if (
		_chef != null
		and not GameManager.is_employee_hired(
			GameManager.STAFF_ROLE_CHEF
		)
	):
		_chef.queue_free()
		_chef = null


func _get_unlocked_seat_targets() -> Dictionary:
	var seat_targets: Dictionary = {
		"seat_1": _seat_targets["seat_1"],
	}
	if GameManager.get_unlocked_seat_count() >= 2:
		seat_targets[SEAT_2_ID] = _seat_targets[SEAT_2_ID]
	if GameManager.get_unlocked_seat_count() >= 3:
		seat_targets[SEAT_3_ID] = _seat_targets[SEAT_3_ID]
	if GameManager.get_unlocked_seat_count() >= 4:
		seat_targets[SEAT_4_ID] = _seat_targets[SEAT_4_ID]
	return seat_targets


func _should_build_facility(facility_name: String) -> bool:
	if facility_name == "Seat2":
		return GameManager.get_unlocked_seat_count() >= 2
	if facility_name == "Seat3":
		return GameManager.get_unlocked_seat_count() >= 3
	if facility_name == "Seat4":
		return GameManager.get_unlocked_seat_count() >= 4
	return true


func _refresh_inventory_hud() -> void:
	if _inventory_label == null:
		return
	var ready_inventory: Dictionary = _get_ready_inventory()
	if GameManager.is_menu_unlocked(GameManager.MENU_EGG):
		_inventory_label.text = "%s | %s | %s" % [
			_format_ready_inventory_entry(
				"밥",
				"rice",
				ready_inventory
			),
			_format_ready_inventory_entry(
				"고등어",
				GameManager.MENU_MACKEREL,
				ready_inventory
			),
			_format_ready_inventory_entry(
				"계란",
				GameManager.MENU_EGG,
				ready_inventory
			),
		]
	else:
		_inventory_label.text = "%s  |  %s" % [
			_format_ready_inventory_entry(
				"밥",
				"rice",
				ready_inventory
			),
			_format_ready_inventory_entry(
				"고등어",
				GameManager.MENU_MACKEREL,
				ready_inventory
			),
		]


func _format_ready_inventory_entry(
	display_name: String,
	material_id: String,
	ready_inventory: Dictionary
) -> String:
	var total_count: int = int(
		ready_inventory.get(material_id, 0)
	)
	var reserved_count: int = (
		GameManager.get_reserved_ready_count(material_id)
	)
	if reserved_count > 0:
		return "%s %d · 예약 %d" % [
			display_name,
			total_count,
			reserved_count,
		]
	return "%s %d" % [display_name, total_count]


func _refresh_currency_hud() -> void:
	if _currency_label == null:
		return
	_currency_label.text = "%d문" % int(
		GameManager.state.get("currency", 0)
	)


func _refresh_employee_ui() -> void:
	if _employee_button == null or _employee_panel == null:
		return
	var is_service_phase: bool = (
		String(GameManager.state.get("screen", ""))
		== GameManager.SCREEN_DAY
		and String(GameManager.state.get("phase", ""))
		== GameManager.PHASE_SERVICE
	)
	_employee_button.visible = is_service_phase
	if not is_service_phase:
		_employee_panel.visible = false
		return

	var chef_hired: bool = GameManager.is_employee_hired(
		GameManager.STAFF_ROLE_CHEF
	)
	var service_hired: bool = GameManager.is_employee_hired(
		GameManager.STAFF_ROLE_SERVICE
	)
	var hired_count: int = int(chef_hired) + int(service_hired)
	_employee_button.text = "직원 %d/2" % hired_count
	_employee_summary_label.text = (
		"첫 주급은 고용할 때 선불입니다. 이후 7일마다 자동 지급되며, "
		+ "지급할 돈이 부족하면 해당 직원이 퇴사합니다."
	)
	_refresh_employee_role_button(
		_chef_hire_button,
		GameManager.STAFF_ROLE_CHEF,
		"주방장",
		"주문 음식 자동 조리 · 조리대에 완성"
	)
	_refresh_employee_role_button(
		_service_hire_button,
		GameManager.STAFF_ROLE_SERVICE,
		"접객",
		"주문 접수 · 조리대 수령/서빙 · 돈 계산"
	)


func _refresh_employee_role_button(
	button: Button,
	role_id: String,
	role_name: String,
	description: String
) -> void:
	var hired: bool = GameManager.is_employee_hired(role_id)
	var weekly_wage: int = (
		GameManager.get_employee_weekly_wage(role_id)
	)
	if hired:
		button.text = "%s · 고용 중\n%s\n다음 주급 Day %d · %d문" % [
			role_name,
			description,
			GameManager.get_employee_next_wage_day(role_id),
			weekly_wage,
		]
		button.disabled = true
		return
	button.text = "%s 고용\n%s\n첫 주급 %d문 선불" % [
		role_name,
		description,
		weekly_wage,
	]
	button.disabled = not GameManager.can_afford_day_growth_purchase(
		weekly_wage
	)


func _refresh_upgrade_ui() -> void:
	if _upgrade_button == null or _upgrade_panel == null:
		return
	var is_service_phase: bool = (
		String(GameManager.state.get("screen", ""))
		== GameManager.SCREEN_DAY
		and String(GameManager.state.get("phase", ""))
		== GameManager.PHASE_SERVICE
	)
	_upgrade_button.visible = is_service_phase
	if not is_service_phase:
		_upgrade_panel.visible = false
		return

	var unlocked_menu_count: int = (
		1
		+ int(GameManager.is_menu_unlocked(GameManager.MENU_EGG))
	)
	_upgrade_button.text = "해금·성장"
	if GameManager.get_current_stage() == GameManager.STAGE_ONE:
		_upgrade_summary_label.text = (
			"좌석 %d/4 · 메뉴 %d/2\n"
			+ "새 장소 %d문 · 하루 정산 후 구매"
		) % [
			GameManager.get_unlocked_seat_count(),
			unlocked_menu_count,
			GameManager.STAGE_TWO_LOCATION_COST,
		]
	else:
		_upgrade_summary_label.text = (
			"Stage 2 · 좌석 %d/4 · 메뉴 %d/2\n"
			+ "넓은 점포의 시설을 다시 확장합니다."
		) % [
			GameManager.get_unlocked_seat_count(),
			unlocked_menu_count,
		]
	_refresh_seat_upgrade_button()
	_refresh_menu_upgrade_button(
		_mackerel_upgrade_button,
		GameManager.MENU_MACKEREL
	)
	_refresh_menu_upgrade_button(
		_egg_upgrade_button,
		GameManager.MENU_EGG
	)


func _refresh_seat_upgrade_button() -> void:
	var current_seats: int = GameManager.get_unlocked_seat_count()
	if current_seats >= GameManager.MAX_SEATS:
		_seat_upgrade_button.text = (
			"좌석 4/4 · 설치 완료\n동시 손님 4명"
		)
		_seat_upgrade_button.disabled = true
		return

	var next_seat: int = current_seats + 1
	var purchase_cost: int = GameManager.get_next_seat_cost()
	if not GameManager.is_next_seat_purchase_available():
		_seat_upgrade_button.text = (
			"좌석 %d 잠김\n%s"
			% [next_seat, GameManager.DAY_TWO_GROWTH_MESSAGE]
		)
		_seat_upgrade_button.disabled = true
		return
	_seat_upgrade_button.text = _format_upgrade_purchase_text(
		"좌석 %d 해금" % next_seat,
		"구매 즉시 좌석 활성화",
		purchase_cost
	)
	_seat_upgrade_button.disabled = (
		not GameManager.can_afford_day_growth_purchase(
			purchase_cost
		)
	)


func _refresh_menu_upgrade_button(
	button: Button,
	menu_id: String
) -> void:
	var current_level: int = GameManager.get_menu_station_level(
		menu_id
	)
	var max_level: int = GameManager.get_menu_station_max_level(
		menu_id
	)
	var menu_name: String = GameManager.get_menu_display_name(menu_id)
	if current_level >= max_level:
		button.text = "%s 메뉴 Lv.%d · 완료\n제작 %.1f초 · 판매 %d문" % [
			menu_name,
			current_level,
			GameManager.get_menu_craft_duration(menu_id),
			GameManager.get_menu_sale_price(menu_id),
		]
		button.disabled = true
		return
	if not GameManager.is_menu_station_purchase_available(menu_id):
		button.text = "%s 메뉴 잠김\n%s" % [
			menu_name,
			GameManager.DAY_TWO_GROWTH_MESSAGE,
		]
		button.disabled = true
		return

	var purchase_cost: int = (
		GameManager.get_menu_station_upgrade_cost(menu_id)
	)
	var title: String = (
		"%s 메뉴 해금" % menu_name
		if current_level <= 0
		else "%s 메뉴 Lv.%d" % [
			menu_name,
			current_level + 1,
		]
	)
	var description: String = (
		"재고가 있으면 신규 손님이 바로 주문"
		if current_level <= 0
		else "제작 시간 감소 · 판매가 상승"
	)
	button.text = _format_upgrade_purchase_text(
		title,
		description,
		purchase_cost
	)
	button.disabled = not GameManager.can_afford_day_growth_purchase(
		purchase_cost
	)


func _format_upgrade_purchase_text(
	title: String,
	description: String,
	purchase_cost: int
) -> String:
	if GameManager.is_day_growth_purchase_reserve_blocked(
		purchase_cost
	):
		return "%s\n%s\n%s" % [
			title,
			description,
			GameManager.OPERATING_RESERVE_MESSAGE,
		]
	var currency: int = int(GameManager.state.get("currency", 0))
	if currency < purchase_cost:
		return "%s\n%s\n%d문 필요 · 보유 %d문" % [
			title,
			description,
			purchase_cost,
			currency,
		]
	return "%s\n%s\n%d문" % [
		title,
		description,
		purchase_cost,
	]


func _refresh_settlement_ui() -> void:
	if _settlement_panel == null:
		return
	var is_settlement: bool = (
		String(GameManager.state.get("screen", ""))
		== GameManager.SCREEN_DAY
		and String(GameManager.state.get("phase", ""))
		== GameManager.PHASE_SETTLEMENT
	)
	_settlement_panel.visible = is_settlement
	if not is_settlement:
		return
	var summary: Dictionary = GameManager.get_settlement_summary()
	var plates_sold_value: Variant = summary.get(
		"plates_sold",
		{}
	)
	var plates_sold: Dictionary = (
		plates_sold_value
		if plates_sold_value is Dictionary
		else {}
	)
	var waste_value: Variant = summary.get("waste", {})
	var waste: Dictionary = (
		waste_value
		if waste_value is Dictionary
		else {}
	)
	_settlement_summary_label.text = (
		"Stage %d · Day %d\n\n"
		+ "총매출  %d문\n"
		+ "판매 접시  %d개\n"
		+ "  · 고등어 %d개\n"
		+ "  · 계란 %d개\n\n"
		+ "기다리다 떠난 손님  %d명\n\n"
		+ "폐기 재료\n"
		+ "  · 밥 %d / 고등어 %d / 계란 %d\n"
		+ "폐기 원가  %.1f문"
	) % [
		GameManager.get_current_stage(),
		int(summary.get("day", 1)),
		int(summary.get("revenue", 0)),
		int(summary.get("total_plates", 0)),
		int(plates_sold.get("mackerel", 0)),
		int(plates_sold.get("egg", 0)),
		int(summary.get("departed_customers", 0)),
		int(waste.get("rice", 0)),
		int(waste.get("mackerel", 0)),
		int(waste.get("egg", 0)),
		float(summary.get("waste_cost", 0.0)),
	]
	var chef_status: String = (
		"고용"
		if GameManager.is_employee_hired(
			GameManager.STAFF_ROLE_CHEF
		)
		else "미고용"
	)
	var service_status: String = (
		"고용"
		if GameManager.is_employee_hired(
			GameManager.STAFF_ROLE_SERVICE
		)
		else "미고용"
	)
	if GameManager.get_current_stage() == GameManager.STAGE_ONE:
		_settlement_progress_label.text = (
			"오늘 성장: 고등어 Lv.%d · 계란 Lv.%d · 좌석 %d\n"
			+ "주방장 %s · 접객 %s\n\n"
			+ "새 장소 %d문 · 보유 %d문\n"
			+ "이전하면 메뉴 해금과 레벨만 유지됩니다"
		) % [
			GameManager.get_mackerel_station_level(),
			GameManager.get_egg_station_level(),
			GameManager.get_unlocked_seat_count(),
			chef_status,
			service_status,
			GameManager.STAGE_TWO_LOCATION_COST,
			int(GameManager.state.get("currency", 0)),
		]
		_stage_two_purchase_button.visible = true
		_stage_two_purchase_button.disabled = (
			not GameManager.can_purchase_stage_two_location()
		)
		var shortfall: int = (
			GameManager.get_stage_two_purchase_shortfall()
		)
		_stage_two_purchase_button.text = (
			"새 장소로 이전 · %d문\n메뉴·레벨만 유지"
			% GameManager.STAGE_TWO_LOCATION_COST
			if shortfall == 0
			else "새 장소 %d문 · %d문 부족" % [
				GameManager.STAGE_TWO_LOCATION_COST,
				shortfall,
			]
		)
		_settlement_continue_button.position = Vector2(66.0, 988.0)
		_settlement_continue_button.size = Vector2(480.0, 70.0)
	else:
		_settlement_progress_label.text = (
			"오늘 성장: 고등어 Lv.%d · 계란 Lv.%d · 좌석 %d\n"
			+ "주방장 %s · 접객 %s\n\n"
			+ "내일 약 %d~%d명 예상\n"
			+ "내일 장사할 재료를 사러 갑니다"
		) % [
			GameManager.get_mackerel_station_level(),
			GameManager.get_egg_station_level(),
			GameManager.get_unlocked_seat_count(),
			chef_status,
			service_status,
			int(summary.get("next_customer_min", 18)),
			int(summary.get("next_customer_max", 22)),
		]
		_stage_two_purchase_button.visible = false
		_settlement_continue_button.position = Vector2(66.0, 930.0)
		_settlement_continue_button.size = Vector2(480.0, 92.0)


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
