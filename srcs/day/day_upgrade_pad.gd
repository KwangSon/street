extends DayInteractable
class_name DayUpgradePad

const PURCHASE_DURATION: float = 1.0
const INTERACTION_MARGIN: float = 28.0
const PAD_SIZE: Vector2 = Vector2(180.0, 86.0)
const PAD_COLOR: Color = Color("92734f")
const COMPLETE_COLOR: Color = Color("66865e")
const HIGHLIGHT_COLOR: Color = Color("f2c94c")
const TEXT_COLOR: Color = Color("fff4d6")
const BLOCKED_COLOR: Color = Color("ffd1c7")

var _player_active: bool = false
var _purchase_progress: float = 0.0
var _attempted: bool = false

var _body: Polygon2D
var _highlight: Line2D
var _title_label: Label
var _status_label: Label
var _progress_bar: ProgressBar


func _ready() -> void:
	_build_visual()
	if not GameManager.state_changed.is_connected(
		_refresh_visual
	):
		GameManager.state_changed.connect(_refresh_visual)
	_refresh_visual()


func get_interaction_priority(_player: DayPlayer) -> int:
	return DayInteractionController.PRIORITY_PURCHASE_PAD


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	if (
		GameManager.get_mackerel_station_level()
		>= GameManager.MACKEREL_STATION_P0_MAX_LEVEL
		or GameManager.is_player_carrying_item()
	):
		return false
	var half_size: Vector2 = PAD_SIZE * 0.5
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
	var half_size: Vector2 = PAD_SIZE * 0.5
	var local_offset: Vector2 = (
		(player_position - global_position).abs() - half_size
	)
	return Vector2(
		maxf(local_offset.x, 0.0),
		maxf(local_offset.y, 0.0)
	).length_squared()


func interaction_entered(_player: DayPlayer) -> void:
	_player_active = true
	_purchase_progress = 0.0
	_attempted = false
	_refresh_visual()


func interaction_tick(_player: DayPlayer, delta: float) -> void:
	if (
		not _player_active
		or _attempted
		or GameManager.is_player_carrying_item()
	):
		return
	_purchase_progress += maxf(delta, 0.0)
	if _purchase_progress < PURCHASE_DURATION:
		_refresh_visual()
		return

	_purchase_progress = PURCHASE_DURATION
	_attempted = true
	GameManager.try_purchase_mackerel_station_upgrade()
	_player_active = false
	_refresh_visual()


func interaction_exited(_player: DayPlayer) -> void:
	_player_active = false
	_purchase_progress = 0.0
	_attempted = false
	_refresh_visual()


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted


func get_purchase_progress() -> float:
	return _purchase_progress


func _build_visual() -> void:
	_body = Polygon2D.new()
	_body.name = "Visual"
	_body.polygon = _rectangle_polygon(PAD_SIZE)
	add_child(_body)

	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 6.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = _rectangle_polygon(
		PAD_SIZE + Vector2(12.0, 12.0)
	)
	_highlight.visible = false
	add_child(_highlight)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(-88.0, -38.0)
	_title_label.size = Vector2(176.0, 34.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", TEXT_COLOR)
	_title_label.add_theme_font_size_override("font_size", 17)
	add_child(_title_label)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(-88.0, -4.0)
	_status_label.size = Vector2(176.0, 32.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	add_child(_status_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "PurchaseProgress"
	_progress_bar.position = Vector2(-80.0, 29.0)
	_progress_bar.size = Vector2(160.0, 12.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_bar)


func _refresh_visual() -> void:
	if _body == null:
		return
	var completed: bool = (
		GameManager.get_mackerel_station_level()
		>= GameManager.MACKEREL_STATION_P0_MAX_LEVEL
	)
	_body.color = COMPLETE_COLOR if completed else PAD_COLOR
	_title_label.text = (
		"고등어 조리대 Lv.2"
		if not completed
		else "조리대 Lv.2 완료"
	)

	var upgrade_cost: int = GameManager.get_mackerel_upgrade_cost()
	var currency: int = int(GameManager.state.get("currency", 0))
	if completed:
		_status_label.text = "제작 3.0초 · 판매 7문"
		_status_label.add_theme_font_size_override("font_size", 15)
		_status_label.add_theme_color_override(
			"font_color",
			TEXT_COLOR
		)
	elif GameManager.is_day_growth_purchase_reserve_blocked(
		upgrade_cost
	):
		_status_label.text = GameManager.OPERATING_RESERVE_MESSAGE
		_status_label.add_theme_font_size_override("font_size", 12)
		_status_label.add_theme_color_override(
			"font_color",
			BLOCKED_COLOR
		)
	elif currency < upgrade_cost:
		_status_label.text = "%d문 필요 · 보유 %d문" % [
			upgrade_cost,
			currency,
		]
		_status_label.add_theme_font_size_override("font_size", 15)
		_status_label.add_theme_color_override(
			"font_color",
			BLOCKED_COLOR
		)
	else:
		_status_label.text = "%d문 · 1초 머물기" % upgrade_cost
		_status_label.add_theme_font_size_override("font_size", 15)
		_status_label.add_theme_color_override(
			"font_color",
			TEXT_COLOR
		)
	_progress_bar.value = clampf(
		_purchase_progress / PURCHASE_DURATION,
		0.0,
		1.0
	)
	_progress_bar.visible = _player_active and not completed


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
