extends "res://srcs/day/day_interactable.gd"
class_name MackerelStation

enum StationState {
	IDLE,
	CRAFTING,
	READY,
	SOLD_OUT,
}

enum SessionMode {
	NONE,
	WORK,
	COLLECT,
}

const DEFAULT_CRAFT_DURATION: float = 3.2
const INTERACTION_MARGIN: float = 36.0
const INTERACTION_PRIORITY_CRAFT: int = (
	DayInteractionController.PRIORITY_INGREDIENT
)
const INTERACTION_PRIORITY_READY: int = (
	DayInteractionController.PRIORITY_COMPLETED_ITEM
)
const HIGHLIGHT_COLOR: Color = Color("f2c94c")
const PLATE_COLOR: Color = Color("e8eef2")
const STATUS_COLOR: Color = Color("35291f")
const SOLD_OUT_COLOR: Color = Color("c74f3f")

var craft_duration: float = DEFAULT_CRAFT_DURATION
var facility_size: Vector2 = Vector2(180.0, 96.0)
var base_color: Color = Color("7197ad")

var _station_state: StationState = StationState.IDLE
var _session_mode: SessionMode = SessionMode.NONE
var _craft_progress: float = 0.0
var _ingredients_reserved: bool = false
var _player_active: bool = false

var _highlight: Line2D
var _progress_bar: ProgressBar
var _status_label: Label
var _plate_count_label: Label
var _plate_visual: Polygon2D


func _ready() -> void:
	_build_visual()
	if not GameManager.state_changed.is_connected(
		_on_game_state_changed
	):
		GameManager.state_changed.connect(_on_game_state_changed)
	_refresh_visual()


func configure(size: Vector2, color: Color) -> void:
	facility_size = size
	base_color = color


func get_station_state() -> StationState:
	return _station_state


func get_craft_progress() -> float:
	return _craft_progress


func is_crafting_reserved() -> bool:
	return _ingredients_reserved


func get_interaction_priority(_player: DayPlayer) -> int:
	if (
		GameManager.get_completed_plate_count(
			GameManager.MENU_MACKEREL
		) > 0
	):
		return INTERACTION_PRIORITY_READY
	return INTERACTION_PRIORITY_CRAFT


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	var half_size: Vector2 = facility_size * 0.5
	var local_offset: Vector2 = player_position - global_position
	return (
		absf(local_offset.x)
		<= half_size.x + INTERACTION_MARGIN + extra_margin
		and absf(local_offset.y)
		<= half_size.y + INTERACTION_MARGIN + extra_margin
	)


func get_interaction_distance_squared(
	player_position: Vector2
) -> float:
	var half_size: Vector2 = facility_size * 0.5
	var local_offset: Vector2 = (
		(player_position - global_position).abs() - half_size
	)
	var outside_offset: Vector2 = Vector2(
		maxf(local_offset.x, 0.0),
		maxf(local_offset.y, 0.0)
	)
	return outside_offset.length_squared()


func interaction_entered(player: DayPlayer) -> void:
	_player_active = true
	if GameManager.is_player_carrying_item():
		_session_mode = SessionMode.NONE
	elif (
		GameManager.get_completed_plate_count(
			GameManager.MENU_MACKEREL
		) > 0
	):
		_session_mode = SessionMode.COLLECT
		if GameManager.try_take_completed_plate(
			GameManager.MENU_MACKEREL
		):
			player.set_carried_item(GameManager.get_carried_item())
	else:
		_session_mode = SessionMode.WORK
		_try_start_craft()
	_refresh_visual()


func interaction_tick(player: DayPlayer, delta: float) -> void:
	if (
		not _player_active
		or _session_mode != SessionMode.WORK
		or GameManager.is_player_carrying_item()
	):
		return
	if not _ingredients_reserved and not _try_start_craft():
		_refresh_visual()
		return

	_craft_progress += maxf(delta, 0.0)
	var safe_duration: float = maxf(craft_duration, 0.001)
	while (
		_ingredients_reserved
		and _craft_progress >= safe_duration
	):
		_craft_progress -= safe_duration
		_ingredients_reserved = false
		GameManager.add_completed_plate(
			GameManager.MENU_MACKEREL
		)
		if not _try_start_craft():
			_craft_progress = 0.0
			break
	player.set_carried_item(GameManager.get_carried_item())
	_refresh_visual()


func interaction_exited(_player: DayPlayer) -> void:
	_player_active = false
	_session_mode = SessionMode.NONE
	_refresh_visual()


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted


func _try_start_craft() -> bool:
	if _ingredients_reserved:
		return true
	if GameManager.is_player_carrying_item():
		return false
	if not GameManager.try_consume_ready_ingredients(
		GameManager.MENU_MACKEREL
	):
		return false
	_ingredients_reserved = true
	_refresh_visual()
	return true


func _resolve_station_state() -> StationState:
	if _ingredients_reserved:
		return StationState.CRAFTING
	if (
		GameManager.get_completed_plate_count(
			GameManager.MENU_MACKEREL
		) > 0
	):
		return StationState.READY
	if GameManager.can_consume_ready_ingredients(
		GameManager.MENU_MACKEREL
	):
		return StationState.IDLE
	return StationState.SOLD_OUT


func _refresh_visual() -> void:
	_station_state = _resolve_station_state()
	if _progress_bar == null:
		return

	var safe_duration: float = maxf(craft_duration, 0.001)
	_progress_bar.value = clampf(
		_craft_progress / safe_duration,
		0.0,
		1.0
	)
	_progress_bar.visible = _ingredients_reserved

	var plate_count: int = GameManager.get_completed_plate_count(
		GameManager.MENU_MACKEREL
	)
	_plate_visual.visible = plate_count > 0
	_plate_count_label.visible = plate_count > 0
	_plate_count_label.text = "완성 %d" % plate_count

	match _station_state:
		StationState.IDLE:
			_status_label.text = "접근하면 제작"
			_status_label.add_theme_color_override(
				"font_color",
				STATUS_COLOR
			)
		StationState.CRAFTING:
			_status_label.text = (
				"제작 중"
				if _player_active
				else "제작 일시정지"
			)
			_status_label.add_theme_color_override(
				"font_color",
				STATUS_COLOR
			)
		StationState.READY:
			_status_label.text = "접시 준비"
			_status_label.add_theme_color_override(
				"font_color",
				STATUS_COLOR
			)
		StationState.SOLD_OUT:
			_status_label.text = "품절"
			_status_label.add_theme_color_override(
				"font_color",
				SOLD_OUT_COLOR
			)


func _build_visual() -> void:
	var body: Polygon2D = Polygon2D.new()
	body.name = "Visual"
	body.color = base_color
	body.polygon = _rectangle_polygon(facility_size)
	add_child(body)

	var label: Label = Label.new()
	label.name = "Label"
	label.position = -facility_size * 0.5
	label.size = facility_size
	label.text = "고등어 조리대"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", STATUS_COLOR)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 6.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = _rectangle_outline(facility_size + Vector2(12.0, 12.0))
	_highlight.visible = false
	add_child(_highlight)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "CraftProgress"
	_progress_bar.position = Vector2(-90.0, -78.0)
	_progress_bar.size = Vector2(180.0, 18.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_bar)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(-90.0, 52.0)
	_status_label.size = Vector2(180.0, 30.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	add_child(_status_label)

	_plate_visual = Polygon2D.new()
	_plate_visual.name = "CompletedPlate"
	_plate_visual.position = Vector2(62.0, -10.0)
	_plate_visual.color = PLATE_COLOR
	_plate_visual.polygon = PackedVector2Array([
		Vector2(-24.0, -10.0),
		Vector2(24.0, -10.0),
		Vector2(30.0, 0.0),
		Vector2(24.0, 10.0),
		Vector2(-24.0, 10.0),
		Vector2(-30.0, 0.0),
	])
	add_child(_plate_visual)

	_plate_count_label = Label.new()
	_plate_count_label.name = "PlateCountLabel"
	_plate_count_label.position = Vector2(24.0, -2.0)
	_plate_count_label.size = Vector2(76.0, 26.0)
	_plate_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plate_count_label.add_theme_color_override(
		"font_color",
		STATUS_COLOR
	)
	_plate_count_label.add_theme_font_size_override("font_size", 14)
	add_child(_plate_count_label)


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])


func _rectangle_outline(size: Vector2) -> PackedVector2Array:
	return _rectangle_polygon(size)


func _on_game_state_changed() -> void:
	_refresh_visual()
