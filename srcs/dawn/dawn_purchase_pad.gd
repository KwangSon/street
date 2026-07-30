extends DayInteractable
class_name DawnPurchasePad

const PURCHASE_DURATION: float = 1.0
const INTERACTION_MARGIN: float = 30.0
const PAD_SIZE: Vector2 = Vector2(220.0, 150.0)
const HIGHLIGHT_COLOR: Color = Color("f2c94c")
const TEXT_COLOR: Color = Color("35291f")
const RICE_COLOR: Color = Color("c6a477")
const MACKEREL_COLOR: Color = Color("7197ad")

var _material_id: String = ""
var _player_active: bool = false
var _purchase_progress: float = 0.0

var _highlight: Line2D
var _title_label: Label
var _status_label: Label
var _progress_bar: ProgressBar


func configure(material_id: String) -> void:
	_material_id = material_id


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
		String(GameManager.state.get("screen", ""))
		!= GameManager.SCREEN_DAWN
		or String(GameManager.state.get("phase", ""))
		!= GameManager.PHASE_MARKET
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
	_refresh_visual()


func interaction_tick(_player: DayPlayer, delta: float) -> void:
	if not _player_active:
		return
	_purchase_progress += maxf(delta, 0.0)
	if _purchase_progress < PURCHASE_DURATION:
		_refresh_visual()
		return
	if GameManager.try_purchase_market_bundle(_material_id):
		_purchase_progress -= PURCHASE_DURATION
	else:
		_purchase_progress = 0.0
	_refresh_visual()


func interaction_exited(_player: DayPlayer) -> void:
	_player_active = false
	_purchase_progress = 0.0
	_refresh_visual()


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted


func get_material_id() -> String:
	return _material_id


func _build_visual() -> void:
	var body: Polygon2D = Polygon2D.new()
	body.name = "Visual"
	body.color = (
		RICE_COLOR if _material_id == "rice" else MACKEREL_COLOR
	)
	body.polygon = _rectangle_polygon(PAD_SIZE)
	add_child(body)

	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 7.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = _rectangle_polygon(
		PAD_SIZE + Vector2(14.0, 14.0)
	)
	_highlight.visible = false
	add_child(_highlight)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(-106.0, -64.0)
	_title_label.size = Vector2(212.0, 54.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", TEXT_COLOR)
	_title_label.add_theme_font_size_override("font_size", 24)
	add_child(_title_label)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(-106.0, -11.0)
	_status_label.size = Vector2(212.0, 48.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", TEXT_COLOR)
	_status_label.add_theme_font_size_override("font_size", 17)
	add_child(_status_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "PurchaseProgress"
	_progress_bar.position = Vector2(-94.0, 48.0)
	_progress_bar.size = Vector2(188.0, 16.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_bar)


func _refresh_visual() -> void:
	if _title_label == null:
		return
	var bundle: Dictionary = GameManager.get_market_bundle(
		_material_id
	)
	var purchases: Dictionary = GameManager.get_market_purchases()
	var material_name: String = (
		"쌀" if _material_id == "rice" else "고등어"
	)
	_title_label.text = "%s %d인분" % [
		material_name,
		int(bundle.get("amount", 0)),
	]
	_status_label.text = "%d문 · 구매 %d" % [
		int(bundle.get("cost", 0)),
		int(purchases.get(_material_id, 0)),
	]
	_progress_bar.value = clampf(
		_purchase_progress / PURCHASE_DURATION,
		0.0,
		1.0
	)
	_progress_bar.visible = _player_active


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
