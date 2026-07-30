extends DayInteractable
class_name DayPreparationSource

enum SourceKind {
	MACKEREL,
	RICE,
}

const INTERACTION_MARGIN: float = 36.0
const HIGHLIGHT_COLOR: Color = Color("f2c94c")
const TEXT_COLOR: Color = Color("35291f")
const BLOCKED_COLOR: Color = Color("8f3d32")

var source_kind: SourceKind = SourceKind.MACKEREL
var facility_size: Vector2 = Vector2(140.0, 96.0)
var base_color: Color = Color("79986b")
var facility_label: String = "재료"

var _highlight: Line2D
var _status_label: Label


func configure(
	kind: SourceKind,
	size: Vector2,
	color: Color,
	label_text: String
) -> void:
	source_kind = kind
	facility_size = size
	base_color = color
	facility_label = label_text


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
	if not _is_current_step():
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
	return Vector2(
		maxf(local_offset.x, 0.0),
		maxf(local_offset.y, 0.0)
	).length_squared()


func interaction_entered(_player: DayPlayer) -> void:
	if source_kind == SourceKind.MACKEREL:
		GameManager.try_collect_mackerel_for_order()
	else:
		GameManager.try_collect_rice_for_order()


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted


func _is_current_step() -> bool:
	var carried_item: Dictionary = GameManager.get_carried_item()
	var current_step: String = String(
		carried_item.get("step", "")
	)
	if source_kind == SourceKind.MACKEREL:
		return current_step == GameManager.PREP_NEED_MACKEREL
	return current_step == GameManager.PREP_NEED_RICE


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
	label.text = facility_label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 6.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = _rectangle_polygon(
		facility_size + Vector2(12.0, 12.0)
	)
	_highlight.visible = false
	add_child(_highlight)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(
		-facility_size.x * 0.5,
		facility_size.y * 0.5 + 4.0
	)
	_status_label.size = Vector2(facility_size.x, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 15)
	add_child(_status_label)


func _refresh_visual() -> void:
	if _status_label == null:
		return
	var carried_item: Dictionary = GameManager.get_carried_item()
	var prep_step: String = String(carried_item.get("step", ""))
	var status_text: String
	var status_color: Color = TEXT_COLOR
	if source_kind == SourceKind.MACKEREL:
		if prep_step == GameManager.PREP_NEED_MACKEREL:
			status_text = "고등어 받기"
		elif prep_step in [
			GameManager.PREP_NEED_RICE,
			GameManager.PREP_READY_TO_COOK,
			GameManager.PREP_COOKING,
		]:
			status_text = "고등어 완료"
		else:
			status_text = "주문 필요"
	else:
		if prep_step == GameManager.PREP_NEED_RICE:
			status_text = "밥 받기"
		elif prep_step == GameManager.PREP_NEED_MACKEREL:
			status_text = "고등어 먼저"
			status_color = BLOCKED_COLOR
		elif prep_step in [
			GameManager.PREP_READY_TO_COOK,
			GameManager.PREP_COOKING,
		]:
			status_text = "밥 완료"
		else:
			status_text = "주문 필요"
	_status_label.text = status_text
	_status_label.add_theme_color_override(
		"font_color",
		status_color
	)


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
