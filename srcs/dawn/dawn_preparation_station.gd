extends DayInteractable
class_name DawnPreparationStation

const WORK_DURATION: float = 1.0
const INTERACTION_RANGE: float = 92.0
const STATION_SIZE: Vector2 = Vector2(140.0, 108.0)
const ACTIVE_COLOR: Color = Color("c69a63")
const LOCKED_COLOR: Color = Color("77736d")
const COMPLETE_COLOR: Color = Color("66865e")
const HIGHLIGHT_COLOR: Color = Color("f2c94c")
const TEXT_COLOR: Color = Color("fff4d6")

var _material_id: String = ""
var _step_index: int = 0
var _display_name: String = ""
var _player_active: bool = false
var _work_progress: float = 0.0

var _body: Polygon2D
var _highlight: Line2D
var _title_label: Label
var _status_label: Label
var _progress_bar: ProgressBar


func configure(
	material_id: String,
	step_index: int,
	display_name: String
) -> void:
	_material_id = material_id
	_step_index = step_index
	_display_name = display_name


func _ready() -> void:
	_build_visual()
	if not GameManager.state_changed.is_connected(
		_refresh_visual
	):
		GameManager.state_changed.connect(_refresh_visual)
	_refresh_visual()


func get_interaction_priority(_player: DayPlayer) -> int:
	return DayInteractionController.PRIORITY_INGREDIENT


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	if (
		String(GameManager.state.get("screen", ""))
		!= GameManager.SCREEN_DAWN
		or String(GameManager.state.get("phase", ""))
		!= GameManager.PHASE_PREP
		or GameManager.get_dawn_prep_next_step(_material_id)
		!= _step_index
	):
		return false
	return (
		global_position.distance_to(player_position)
		<= INTERACTION_RANGE + extra_margin
	)


func get_interaction_distance_squared(
	player_position: Vector2
) -> float:
	return global_position.distance_squared_to(player_position)


func interaction_entered(_player: DayPlayer) -> void:
	_player_active = true
	_work_progress = 0.0
	_refresh_visual()


func interaction_tick(_player: DayPlayer, delta: float) -> void:
	if not _player_active:
		return
	_work_progress += maxf(delta, 0.0)
	if _work_progress < WORK_DURATION:
		_refresh_visual()
		return
	_work_progress = WORK_DURATION
	GameManager.try_complete_dawn_prep_step(
		_material_id,
		_step_index
	)
	_player_active = false
	_refresh_visual()


func interaction_exited(_player: DayPlayer) -> void:
	_player_active = false
	_work_progress = 0.0
	_refresh_visual()


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted


func get_material_id() -> String:
	return _material_id


func get_step_index() -> int:
	return _step_index


func _build_visual() -> void:
	_body = Polygon2D.new()
	_body.name = "Visual"
	_body.polygon = _rectangle_polygon(STATION_SIZE)
	add_child(_body)

	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 6.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = _rectangle_polygon(
		STATION_SIZE + Vector2(12.0, 12.0)
	)
	_highlight.visible = false
	add_child(_highlight)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(-68.0, -47.0)
	_title_label.size = Vector2(136.0, 50.0)
	_title_label.text = _display_name
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", TEXT_COLOR)
	_title_label.add_theme_font_size_override("font_size", 18)
	add_child(_title_label)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(-68.0, 2.0)
	_status_label.size = Vector2(136.0, 34.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", TEXT_COLOR)
	_status_label.add_theme_font_size_override("font_size", 15)
	add_child(_status_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "WorkProgress"
	_progress_bar.position = Vector2(-60.0, 39.0)
	_progress_bar.size = Vector2(120.0, 12.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_bar)


func _refresh_visual() -> void:
	if _body == null:
		return
	var next_step: int = GameManager.get_dawn_prep_next_step(
		_material_id
	)
	var completed: bool = next_step > _step_index
	var active: bool = next_step == _step_index
	_body.color = (
		COMPLETE_COLOR
		if completed
		else ACTIVE_COLOR if active else LOCKED_COLOR
	)
	_status_label.text = (
		"완료"
		if completed
		else "1초 작업" if active else "이전 단계 필요"
	)
	_progress_bar.value = clampf(
		_work_progress / WORK_DURATION,
		0.0,
		1.0
	)
	_progress_bar.visible = _player_active and active


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
