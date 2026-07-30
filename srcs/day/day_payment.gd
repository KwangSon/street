extends DayInteractable
class_name DayPayment

signal payment_collected(customer_id: String)

const INTERACTION_RANGE: float = 72.0
const COIN_COLOR: Color = Color("d7aa37")
const HIGHLIGHT_COLOR: Color = Color("fff0a6")
const TEXT_COLOR: Color = Color("35291f")

var _customer_id: String = ""
var _amount: int = 0
var _highlight: Line2D


func configure(
	customer_id: String,
	amount: int,
	payment_position: Vector2
) -> void:
	_customer_id = customer_id
	_amount = amount
	position = payment_position
	name = "Payment_%s" % customer_id


func _ready() -> void:
	var coin: Polygon2D = Polygon2D.new()
	coin.name = "Coin"
	coin.color = COIN_COLOR
	coin.polygon = PackedVector2Array([
		Vector2(0.0, -24.0),
		Vector2(20.0, -12.0),
		Vector2(20.0, 12.0),
		Vector2(0.0, 24.0),
		Vector2(-20.0, 12.0),
		Vector2(-20.0, -12.0),
	])
	add_child(coin)

	var label: Label = Label.new()
	label.name = "AmountLabel"
	label.position = Vector2(-42.0, 27.0)
	label.size = Vector2(84.0, 28.0)
	label.text = "%d문" % _amount
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 17)
	add_child(label)

	_highlight = Line2D.new()
	_highlight.name = "InteractionHighlight"
	_highlight.width = 5.0
	_highlight.default_color = HIGHLIGHT_COLOR
	_highlight.closed = true
	_highlight.points = PackedVector2Array([
		Vector2(0.0, -34.0),
		Vector2(30.0, -17.0),
		Vector2(30.0, 17.0),
		Vector2(0.0, 34.0),
		Vector2(-30.0, 17.0),
		Vector2(-30.0, -17.0),
	])
	_highlight.visible = false
	add_child(_highlight)


func get_interaction_priority(_player: DayPlayer) -> int:
	return DayInteractionController.PRIORITY_COIN


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	var payment: Dictionary = GameManager.get_customer_payment(
		_customer_id
	)
	if (
		String(payment.get("status", ""))
		!= GameManager.PAYMENT_WAITING
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
	if GameManager.collect_customer_payment(_customer_id):
		payment_collected.emit(_customer_id)


func set_interaction_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted
