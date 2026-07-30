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
const MackerelStationScript: Script = preload(
	"res://srcs/day/mackerel_station.gd"
)
const DayCustomerManagerScript: Script = preload(
	"res://srcs/day/day_customer_manager.gd"
)
const DayPreparationSourceScript: Script = preload(
	"res://srcs/day/day_preparation_source.gd"
)
const DayUpgradePadScript: Script = preload(
	"res://srcs/day/day_upgrade_pad.gd"
)
const DaySeatPurchasePadScript: Script = preload(
	"res://srcs/day/day_seat_purchase_pad.gd"
)
const DayStaffHirePadScript: Script = preload(
	"res://srcs/day/day_staff_hire_pad.gd"
)
const DayServerScript: Script = preload(
	"res://srcs/day/day_server.gd"
)

const VIEWPORT_SIZE: Vector2 = Vector2(720.0, 1280.0)
const MAP_SIZE: Vector2 = Vector2(1200.0, 1920.0)
const DEFAULT_CAMERA_POSITION: Vector2 = Vector2(360.0, 640.0)
const PLAYER_START_POSITION: Vector2 = Vector2(360.0, 620.0)
const DRAG_THRESHOLD: float = 8.0
const EARLY_CLOSE_HOLD_DURATION: float = 2.0

const HUD_HEIGHT: float = 112.0
const MOUSE_POINTER_ID: int = -1
const NO_POINTER_ID: int = -2

const MAP_COLOR: Color = Color("b9b7ad")
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
const STAFF_PAD_POSITION: Vector2 = Vector2(900.0, 1420.0)
const SERVER_START_POSITION: Vector2 = Vector2(900.0, 1320.0)

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
		"name": "EggBox",
		"label": "계란 바구니",
		"position": Vector2(760.0, 300.0),
		"size": Vector2(140.0, 96.0),
		"color": Color("d7bd61"),
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

var _world: Node2D
var _player: DayPlayer
var _camera: Camera2D
var _navigation: DayNavigation
var _interaction_controller: DayInteractionController
var _mackerel_station: MackerelStation
var _egg_station: MackerelStation
var _customer_manager: DayCustomerManager
var _ingredient_box: DayPreparationSource
var _egg_box: DayPreparationSource
var _rice_pot: DayPreparationSource
var _mackerel_upgrade_pad: DayUpgradePad
var _egg_upgrade_pad: DayUpgradePad
var _seat_purchase_pad: DaySeatPurchasePad
var _staff_hire_pad: DayStaffHirePad
var _server: DayServer
var _inventory_label: Label
var _currency_label: Label
var _time_label: Label
var _early_close_button: Button
var _settlement_panel: ColorRect
var _settlement_summary_label: Label
var _settlement_progress_label: Label
var _settlement_continue_button: Button
var _active_pointer_id: int = NO_POINTER_ID
var _gesture_start: Vector2 = Vector2.ZERO
var _gesture_last: Vector2 = Vector2.ZERO
var _gesture_is_drag: bool = false
var _early_close_holding: bool = false
var _early_close_progress: float = 0.0


func _ready() -> void:
	name = "DayScreen"
	GameManager.ensure_day_runtime_state()
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


func get_mackerel_station() -> MackerelStation:
	return _mackerel_station


func get_egg_station() -> MackerelStation:
	return _egg_station


func get_customer_manager() -> DayCustomerManager:
	return _customer_manager


func get_ingredient_box() -> DayPreparationSource:
	return _ingredient_box


func get_egg_box() -> DayPreparationSource:
	return _egg_box


func get_rice_pot() -> DayPreparationSource:
	return _rice_pot


func get_mackerel_upgrade_pad() -> DayUpgradePad:
	return _mackerel_upgrade_pad


func get_egg_upgrade_pad() -> DayUpgradePad:
	return _egg_upgrade_pad


func get_seat_purchase_pad() -> DaySeatPurchasePad:
	return _seat_purchase_pad


func get_staff_hire_pad() -> DayStaffHirePad:
	return _staff_hire_pad


func get_server() -> DayServer:
	return _server


func get_early_close_button() -> Button:
	return _early_close_button


func get_early_close_hold_progress() -> float:
	return _early_close_progress


func get_settlement_panel() -> ColorRect:
	return _settlement_panel


func get_settlement_continue_button() -> Button:
	return _settlement_continue_button


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
		if not _should_build_facility(String(facility["name"])):
			continue
		_add_facility(facility)

	_mackerel_upgrade_pad = DayUpgradePadScript.new()
	_mackerel_upgrade_pad.name = "MackerelUpgradePad"
	_mackerel_upgrade_pad.configure(GameManager.MENU_MACKEREL)
	_mackerel_upgrade_pad.position = Vector2(540.0, 465.0)
	_world.add_child(_mackerel_upgrade_pad)

	_egg_upgrade_pad = DayUpgradePadScript.new()
	_egg_upgrade_pad.name = "EggUpgradePad"
	_egg_upgrade_pad.configure(GameManager.MENU_EGG)
	_egg_upgrade_pad.position = Vector2(940.0, 500.0)
	_world.add_child(_egg_upgrade_pad)

	_seat_purchase_pad = DaySeatPurchasePadScript.new()
	_seat_purchase_pad.name = "Seat2PurchasePad"
	_seat_purchase_pad.position = Vector2(620.0, 580.0)
	_world.add_child(_seat_purchase_pad)

	_staff_hire_pad = DayStaffHirePadScript.new()
	_staff_hire_pad.name = "StaffHirePad"
	_staff_hire_pad.position = STAFF_PAD_POSITION
	_world.add_child(_staff_hire_pad)

	_player = DayPlayerScript.new()
	_player.move_speed = DayPlayer.DEFAULT_MOVE_SPEED
	_player.position = PLAYER_START_POSITION
	_world.add_child(_player)
	_player.set_carried_item(GameManager.get_carried_item())

	_interaction_controller = DayInteractionControllerScript.new()
	_interaction_controller.name = "InteractionController"
	_interaction_controller.configure(_player)
	_interaction_controller.register_interactable(_mackerel_station)
	_interaction_controller.register_interactable(_ingredient_box)
	_interaction_controller.register_interactable(_rice_pot)
	if _egg_station != null:
		_interaction_controller.register_interactable(_egg_station)
	if _egg_box != null:
		_interaction_controller.register_interactable(_egg_box)
	_interaction_controller.register_interactable(
		_mackerel_upgrade_pad
	)
	_interaction_controller.register_interactable(_egg_upgrade_pad)
	_interaction_controller.register_interactable(
		_seat_purchase_pad
	)
	_interaction_controller.register_interactable(
		_staff_hire_pad
	)
	_world.add_child(_interaction_controller)

	_customer_manager = DayCustomerManagerScript.new()
	_customer_manager.name = "CustomerManager"
	_customer_manager.configure(
		Vector2(120.0, 860.0),
		_get_unlocked_seat_targets(),
		[
			Vector2(190.0, 860.0),
			Vector2(260.0, 860.0),
			Vector2(330.0, 860.0),
		]
	)
	_customer_manager.interactable_created.connect(
		_on_customer_interactable_created
	)
	_world.add_child(_customer_manager)

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
	_install_server_if_hired()


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
	var facility_node: Node2D
	var facility_name: String = String(facility["name"])
	if facility_name in ["MackerelStation", "EggStation"]:
		var menu_station: MackerelStation = MackerelStationScript.new()
		var station_menu_id: String = (
			GameManager.MENU_EGG
			if facility_name == "EggStation"
			else GameManager.MENU_MACKEREL
		)
		menu_station.configure(
			facility["size"],
			facility["color"],
			station_menu_id
		)
		if station_menu_id == GameManager.MENU_EGG:
			_egg_station = menu_station
		else:
			_mackerel_station = menu_station
		facility_node = menu_station
	elif facility_name in ["IngredientBox", "EggBox", "RicePot"]:
		var preparation_source: DayPreparationSource = (
			DayPreparationSourceScript.new()
		)
		var source_kind: DayPreparationSource.SourceKind = (
			DayPreparationSource.SourceKind.MACKEREL
			if facility_name == "IngredientBox"
			else DayPreparationSource.SourceKind.EGG
			if facility_name == "EggBox"
			else DayPreparationSource.SourceKind.RICE
		)
		preparation_source.configure(
			source_kind,
			facility["size"],
			facility["color"],
			String(facility["label"])
		)
		if facility_name == "IngredientBox":
			_ingredient_box = preparation_source
		elif facility_name == "EggBox":
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
		facility_node != _mackerel_station
		and facility_node != _egg_station
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
	for facility: Dictionary in FACILITIES:
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
		"Day %d" % day,
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
		"밥 %d  |  고등어 %d" % [
			int(ready_inventory.get("rice", 0)),
			int(ready_inventory.get("mackerel", 0)),
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

	_settlement_continue_button = Button.new()
	_settlement_continue_button.name = "ContinueButton"
	_settlement_continue_button.position = Vector2(66.0, 930.0)
	_settlement_continue_button.size = Vector2(480.0, 92.0)
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


func _on_game_state_changed() -> void:
	_install_unlocked_seats()
	_install_egg_facilities_if_unlocked()
	_install_server_if_hired()
	_refresh_inventory_hud()
	_refresh_currency_hud()
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
			"target": SEAT_2_TARGET,
		},
		3: {
			"name": "Seat3",
			"id": SEAT_3_ID,
			"target": SEAT_3_TARGET,
		},
		4: {
			"name": "Seat4",
			"id": SEAT_4_ID,
			"target": SEAT_4_TARGET,
		},
	}
	var installed_any: bool = false
	for seat_number: int in range(2, unlocked_seats + 1):
		var current_seat: Dictionary = seat_data[seat_number]
		var facility_name: String = String(current_seat["name"])
		if _world.get_node_or_null(facility_name) != null:
			continue
		for facility: Dictionary in FACILITIES:
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
			MAP_SIZE,
			DayPlayer.COLLISION_RADIUS,
			_get_navigation_obstacle_rects()
		)


func _install_egg_facilities_if_unlocked() -> void:
	if (
		_world == null
		or not GameManager.is_menu_unlocked(GameManager.MENU_EGG)
	):
		return
	var installed_any: bool = false
	for facility_name: String in ["EggBox", "EggStation"]:
		if _world.get_node_or_null(facility_name) != null:
			continue
		for facility: Dictionary in FACILITIES:
			if String(facility["name"]) != facility_name:
				continue
			_add_facility(facility)
			installed_any = true
			break
	if not installed_any:
		return
	if _interaction_controller != null:
		if _egg_box != null:
			_interaction_controller.register_interactable(_egg_box)
		if _egg_station != null:
			_interaction_controller.register_interactable(_egg_station)
	if _navigation != null:
		_navigation.configure(
			MAP_SIZE,
			DayPlayer.COLLISION_RADIUS,
			_get_navigation_obstacle_rects()
		)
	if _server != null and _egg_station != null:
		_server.set_station_position(
			GameManager.MENU_EGG,
			_egg_station.position
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
		GameManager.MENU_MACKEREL: _mackerel_station.position,
	}
	if _egg_station != null:
		station_positions[GameManager.MENU_EGG] = _egg_station.position
	_server.configure(
		SERVER_START_POSITION,
		station_positions,
		_customer_manager,
		_navigation
	)
	_world.add_child(_server)


func _get_unlocked_seat_targets() -> Dictionary:
	var seat_targets: Dictionary = {
		"seat_1": Vector2(500.0, 750.0),
	}
	if GameManager.get_unlocked_seat_count() >= 2:
		seat_targets[SEAT_2_ID] = SEAT_2_TARGET
	if GameManager.get_unlocked_seat_count() >= 3:
		seat_targets[SEAT_3_ID] = SEAT_3_TARGET
	if GameManager.get_unlocked_seat_count() >= 4:
		seat_targets[SEAT_4_ID] = SEAT_4_TARGET
	return seat_targets


func _should_build_facility(facility_name: String) -> bool:
	if facility_name == "Seat2":
		return GameManager.get_unlocked_seat_count() >= 2
	if facility_name == "Seat3":
		return GameManager.get_unlocked_seat_count() >= 3
	if facility_name == "Seat4":
		return GameManager.get_unlocked_seat_count() >= 4
	if facility_name in ["EggBox", "EggStation"]:
		return GameManager.is_menu_unlocked(GameManager.MENU_EGG)
	return true


func _refresh_inventory_hud() -> void:
	if _inventory_label == null:
		return
	var ready_inventory: Dictionary = _get_ready_inventory()
	if GameManager.is_menu_unlocked(GameManager.MENU_EGG):
		_inventory_label.text = "밥 %d | 고등어 %d | 계란 %d" % [
			int(ready_inventory.get("rice", 0)),
			int(ready_inventory.get("mackerel", 0)),
			int(ready_inventory.get("egg", 0)),
		]
	else:
		_inventory_label.text = "밥 %d  |  고등어 %d" % [
			int(ready_inventory.get("rice", 0)),
			int(ready_inventory.get("mackerel", 0)),
		]


func _refresh_currency_hud() -> void:
	if _currency_label == null:
		return
	_currency_label.text = "%d문" % int(
		GameManager.state.get("currency", 0)
	)


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
		"Day %d\n\n"
		+ "총매출  %d문\n"
		+ "판매 접시  %d개\n"
		+ "  · 고등어 %d개\n"
		+ "  · 계란 %d개\n\n"
		+ "기다리다 떠난 손님  %d명\n\n"
		+ "폐기 재료\n"
		+ "  · 밥 %d / 고등어 %d / 계란 %d\n"
		+ "폐기 원가  %.1f문"
	) % [
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
	_settlement_progress_label.text = (
		"오늘 성장: 고등어 Lv.%d · 계란 Lv.%d · 좌석 %d · 점원 %s\n\n"
		+ "내일 약 %d~%d명 예상\n"
		+ "내일 장사할 재료를 사러 갑니다"
	) % [
		GameManager.get_mackerel_station_level(),
		GameManager.get_egg_station_level(),
		GameManager.get_unlocked_seat_count(),
		"고용" if GameManager.is_server_hired() else "미고용",
		int(summary.get("next_customer_min", 18)),
		int(summary.get("next_customer_max", 22)),
	]


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
