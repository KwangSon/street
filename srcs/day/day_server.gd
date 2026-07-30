extends Node2D
class_name DayServer

enum ServerState {
	IDLE,
	MOVING_TO_STATION,
	MOVING_TO_CUSTOMER,
}

const MOVE_SPEED: float = 260.0
const ARRIVAL_DISTANCE: float = 6.0
const BODY_COLOR: Color = Color("bd765f")
const APRON_COLOR: Color = Color("fff4d6")
const TEXT_COLOR: Color = Color("35291f")

var _server_state: ServerState = ServerState.IDLE
var _customer_id: String = ""
var _station_position: Vector2 = Vector2.ZERO
var _customer_manager: DayCustomerManager
var _navigation: DayNavigation
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _plate_visual: Node2D


func configure(
	start_position: Vector2,
	station_position: Vector2,
	customer_manager: DayCustomerManager,
	navigation: DayNavigation
) -> void:
	position = start_position
	_station_position = station_position
	_customer_manager = customer_manager
	_navigation = navigation


func _ready() -> void:
	name = "Server"
	z_index = 4
	_build_visual()
	if not GameManager.state_changed.is_connected(
		_refresh_visual
	):
		GameManager.state_changed.connect(_refresh_visual)
	_refresh_visual()


func _process(delta: float) -> void:
	match _server_state:
		ServerState.IDLE:
			_find_next_plate()
		ServerState.MOVING_TO_STATION:
			if _advance_path(delta):
				_collect_reserved_plate()
		ServerState.MOVING_TO_CUSTOMER:
			if _advance_path(delta):
				_serve_customer()


func get_server_state() -> ServerState:
	return _server_state


func get_customer_id() -> String:
	return _customer_id


func is_carrying_plate() -> bool:
	return not GameManager.get_server_carried_item().is_empty()


func _find_next_plate() -> void:
	var reserved_customer_id: String = (
		GameManager.try_reserve_ready_plate_for_server()
	)
	if reserved_customer_id.is_empty():
		return
	_customer_id = reserved_customer_id
	if not _start_path(_station_position):
		GameManager.cancel_server_plate_delivery(_customer_id)
		_reset_to_idle()
		return
	_server_state = ServerState.MOVING_TO_STATION


func _collect_reserved_plate() -> void:
	if not GameManager.try_server_collect_reserved_plate(
		_customer_id
	):
		GameManager.cancel_server_plate_delivery(_customer_id)
		_reset_to_idle()
		return
	var customer: DayCustomer = _customer_manager.get_customer(
		_customer_id
	)
	if customer == null or not _start_path(customer.position):
		GameManager.cancel_server_plate_delivery(_customer_id)
		_reset_to_idle()
		return
	_server_state = ServerState.MOVING_TO_CUSTOMER
	_refresh_visual()


func _serve_customer() -> void:
	if not GameManager.try_server_serve_order(_customer_id):
		GameManager.cancel_server_plate_delivery(_customer_id)
	_reset_to_idle()


func _start_path(destination: Vector2) -> bool:
	if _navigation == null:
		return false
	_path = _navigation.find_path(position, destination)
	_path_index = 0
	return not _path.is_empty()


func _advance_path(delta: float) -> bool:
	if _path_index >= _path.size():
		return true
	var waypoint: Vector2 = _path[_path_index]
	var distance: float = position.distance_to(waypoint)
	var travel: float = MOVE_SPEED * maxf(delta, 0.0)
	if distance <= maxf(travel, ARRIVAL_DISTANCE):
		position = waypoint
		_path_index += 1
		return _path_index >= _path.size()
	position += position.direction_to(waypoint) * travel
	return false


func _reset_to_idle() -> void:
	_server_state = ServerState.IDLE
	_customer_id = ""
	_path = PackedVector2Array()
	_path_index = 0
	_refresh_visual()


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

	var apron: Polygon2D = Polygon2D.new()
	apron.name = "Apron"
	apron.color = APRON_COLOR
	apron.polygon = PackedVector2Array([
		Vector2(-15.0, -4.0),
		Vector2(15.0, -4.0),
		Vector2(18.0, 24.0),
		Vector2(-18.0, 24.0),
	])
	add_child(apron)

	var label: Label = Label.new()
	label.name = "NameLabel"
	label.position = Vector2(-40.0, 32.0)
	label.size = Vector2(80.0, 26.0)
	label.text = "점원"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 17)
	add_child(label)

	_plate_visual = Node2D.new()
	_plate_visual.name = "CarriedPlate"
	_plate_visual.position = Vector2(0.0, -48.0)
	add_child(_plate_visual)

	var plate: Polygon2D = Polygon2D.new()
	plate.color = Color("f4ead7")
	plate.polygon = PackedVector2Array([
		Vector2(-24.0, -7.0),
		Vector2(24.0, -7.0),
		Vector2(18.0, 7.0),
		Vector2(-18.0, 7.0),
	])
	_plate_visual.add_child(plate)

	var topping: Polygon2D = Polygon2D.new()
	topping.color = Color("6f8fa3")
	topping.polygon = PackedVector2Array([
		Vector2(-13.0, -11.0),
		Vector2(13.0, -11.0),
		Vector2(16.0, 1.0),
		Vector2(-16.0, 1.0),
	])
	_plate_visual.add_child(topping)


func _refresh_visual() -> void:
	if _plate_visual != null:
		_plate_visual.visible = is_carrying_plate()
