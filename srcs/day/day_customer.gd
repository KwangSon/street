extends CharacterBody2D
class_name DayCustomer

signal reached_seat(customer_id: String)

const MOVE_SPEED: float = 160.0
const ARRIVAL_DISTANCE: float = 4.0
const BODY_COLOR: Color = Color("5f83a3")
const ORDER_BUBBLE_COLOR: Color = Color("fff4d6")
const TEXT_COLOR: Color = Color("35291f")

var _customer_id: String = ""
var _seat_target: Vector2 = Vector2.ZERO
var _moving_to_seat: bool = false
var _order_bubble: Node2D
var _order_label: Label


func configure(
	customer_id: String,
	start_position: Vector2,
	seat_target: Vector2
) -> void:
	_customer_id = customer_id
	position = start_position
	_seat_target = seat_target
	_moving_to_seat = true
	name = "Customer_%s" % customer_id


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	_build_visual()
	if not GameManager.state_changed.is_connected(
		_refresh_from_state
	):
		GameManager.state_changed.connect(_refresh_from_state)
	_refresh_from_state()


func _physics_process(delta: float) -> void:
	if not _moving_to_seat:
		velocity = Vector2.ZERO
		return

	var offset: Vector2 = _seat_target - position
	if offset.length() <= ARRIVAL_DISTANCE:
		position = _seat_target
		velocity = Vector2.ZERO
		_moving_to_seat = false
		reached_seat.emit(_customer_id)
		return

	velocity = offset.normalized() * minf(
		MOVE_SPEED,
		offset.length() / maxf(delta, 0.0001)
	)
	move_and_slide()


func get_customer_id() -> String:
	return _customer_id


func is_moving_to_seat() -> bool:
	return _moving_to_seat


func get_seat_target() -> Vector2:
	return _seat_target


func _build_visual() -> void:
	var body: Polygon2D = Polygon2D.new()
	body.name = "Body"
	body.color = BODY_COLOR
	body.polygon = PackedVector2Array([
		Vector2(0.0, -34.0),
		Vector2(26.0, -8.0),
		Vector2(22.0, 30.0),
		Vector2(-22.0, 30.0),
		Vector2(-26.0, -8.0),
	])
	add_child(body)

	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-40.0, 32.0)
	name_label.size = Vector2(80.0, 26.0)
	name_label.text = "손님"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	name_label.add_theme_font_size_override("font_size", 17)
	add_child(name_label)

	_order_bubble = Node2D.new()
	_order_bubble.name = "OrderBubble"
	_order_bubble.position = Vector2(0.0, -66.0)
	add_child(_order_bubble)

	var bubble: Polygon2D = Polygon2D.new()
	bubble.name = "Background"
	bubble.color = ORDER_BUBBLE_COLOR
	bubble.polygon = PackedVector2Array([
		Vector2(-42.0, -24.0),
		Vector2(42.0, -24.0),
		Vector2(42.0, 18.0),
		Vector2(8.0, 18.0),
		Vector2(0.0, 29.0),
		Vector2(-8.0, 18.0),
		Vector2(-42.0, 18.0),
	])
	_order_bubble.add_child(bubble)

	_order_label = Label.new()
	_order_label.name = "MenuLabel"
	_order_label.position = Vector2(-40.0, -21.0)
	_order_label.size = Vector2(80.0, 36.0)
	_order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_order_label.add_theme_color_override("font_color", TEXT_COLOR)
	_order_label.add_theme_font_size_override("font_size", 16)
	_order_bubble.add_child(_order_label)


func _refresh_from_state() -> void:
	if _order_bubble == null or _customer_id.is_empty():
		return
	var customer: Dictionary = GameManager.get_day_customer(
		_customer_id
	)
	var menu_id: String = String(customer.get("menu", ""))
	var waiting_for_order: bool = (
		String(customer.get("state", ""))
		== GameManager.CUSTOMER_WAITING_FOR_ORDER
	)
	_order_bubble.visible = waiting_for_order
	_order_label.text = "고등어" if (
		menu_id == GameManager.MENU_MACKEREL
	) else menu_id
