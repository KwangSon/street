extends DayInteractable
class_name DayCustomerOrderTarget

const INTERACTION_RANGE: float = 82.0
const HIGHLIGHT_COLOR: Color = Color("f2c94c")

var _customer_id: String = ""
var _highlight: Line2D


func configure(customer_id: String) -> void:
	_customer_id = customer_id


func _ready() -> void:
	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 5.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = PackedVector2Array([
		Vector2(-38.0, -42.0),
		Vector2(38.0, -42.0),
		Vector2(38.0, 38.0),
		Vector2(-38.0, 38.0),
	])
	_highlight.visible = false
	add_child(_highlight)


func get_interaction_priority(_player: DayPlayer) -> int:
	return DayInteractionController.PRIORITY_ORDER_CUSTOMER


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	var customer: Dictionary = GameManager.get_day_customer(
		_customer_id
	)
	if (
		String(customer.get("state", ""))
		!= GameManager.CUSTOMER_WAITING_FOR_ORDER
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
	GameManager.try_accept_waiting_order(_customer_id)


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted
