extends "res://srcs/day/day_interactable.gd"
class_name MackerelStation

enum StationState {
	IDLE,
	CRAFTING,
	READY,
}

enum SessionMode {
	NONE,
	WORK,
}

const DEFAULT_CRAFT_DURATION: float = 3.2
const INTERACTION_MARGIN: float = 36.0
const HIGHLIGHT_COLOR: Color = Color("f2c94c")
const STATUS_COLOR: Color = Color("35291f")

var craft_duration: float = DEFAULT_CRAFT_DURATION
var use_game_manager_tuning: bool = true
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
var _title_label: Label


func _ready() -> void:
	if use_game_manager_tuning:
		craft_duration = GameManager.get_mackerel_craft_duration()
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
	return DayInteractionController.PRIORITY_DROP_OFF


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	var carried_item: Dictionary = GameManager.get_carried_item()
	var prep_step: String = String(
		carried_item.get("step", "")
	)
	if prep_step not in [
		GameManager.PREP_READY_TO_COOK,
		GameManager.PREP_COOKING,
	]:
		return false
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
	if _try_start_craft():
		_session_mode = SessionMode.WORK
	else:
		_session_mode = SessionMode.NONE
	player.set_carried_item(GameManager.get_carried_item())
	_refresh_visual()


func interaction_tick(player: DayPlayer, delta: float) -> void:
	if (
		not _player_active
		or _session_mode != SessionMode.WORK
	):
		return
	if not _ingredients_reserved and not _try_start_craft():
		_refresh_visual()
		return

	_craft_progress += maxf(delta, 0.0)
	var safe_duration: float = maxf(craft_duration, 0.001)
	if (
		_ingredients_reserved
		and _craft_progress >= safe_duration
	):
		_craft_progress = 0.0
		_ingredients_reserved = false
		_session_mode = SessionMode.NONE
		GameManager.complete_active_order_craft()
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
	if not GameManager.try_start_active_order_craft():
		return false
	_ingredients_reserved = true
	_refresh_visual()
	return true


func _resolve_station_state() -> StationState:
	if _ingredients_reserved:
		return StationState.CRAFTING
	var carried_item: Dictionary = GameManager.get_carried_item()
	if (
		String(carried_item.get("kind", ""))
		== GameManager.CARRIED_KIND_PLATE
	):
		return StationState.READY
	return StationState.IDLE


func _refresh_visual() -> void:
	_station_state = _resolve_station_state()
	if _progress_bar == null:
		return
	if use_game_manager_tuning and not _ingredients_reserved:
		craft_duration = GameManager.get_mackerel_craft_duration()
	_title_label.text = "고등어 조리대 Lv.%d" % (
		GameManager.get_mackerel_station_level()
	)

	var safe_duration: float = maxf(craft_duration, 0.001)
	_progress_bar.value = clampf(
		_craft_progress / safe_duration,
		0.0,
		1.0
	)
	_progress_bar.visible = _ingredients_reserved

	match _station_state:
		StationState.IDLE:
			var carried_item: Dictionary = (
				GameManager.get_carried_item()
			)
			var prep_step: String = String(
				carried_item.get("step", "")
			)
			if prep_step == GameManager.PREP_NEED_MACKEREL:
				_status_label.text = "고등어 먼저"
			elif prep_step == GameManager.PREP_NEED_RICE:
				_status_label.text = "밥 먼저"
			elif prep_step == GameManager.PREP_READY_TO_COOK:
				_status_label.text = "제작 준비"
			else:
				_status_label.text = "주문 필요"
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
			_status_label.text = "서빙하세요"
			_status_label.add_theme_color_override(
				"font_color",
				STATUS_COLOR
			)


func _build_visual() -> void:
	var body: Polygon2D = Polygon2D.new()
	body.name = "Visual"
	body.color = base_color
	body.polygon = _rectangle_polygon(facility_size)
	add_child(body)

	_title_label = Label.new()
	_title_label.name = "Label"
	_title_label.position = -facility_size * 0.5
	_title_label.size = facility_size
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override(
		"font_color",
		STATUS_COLOR
	)
	_title_label.add_theme_font_size_override("font_size", 18)
	add_child(_title_label)

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
