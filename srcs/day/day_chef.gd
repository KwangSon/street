extends Node2D
class_name DayChef

enum ChefState {
	IDLE,
	MOVING_TO_STATION,
	WORKING_AT_COUNTER,
}

const MOVE_SPEED: float = 230.0
const ARRIVAL_DISTANCE: float = 6.0
const BODY_COLOR: Color = Color("628c73")
const APRON_COLOR: Color = Color("fff4d6")
const TEXT_COLOR: Color = Color("35291f")

var _chef_state: ChefState = ChefState.IDLE
var _station_positions: Dictionary = {}
var _navigation: DayNavigation
var _target_station_id: String = ""
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _craft_progress: float = 0.0


func configure(
	start_position: Vector2,
	station_positions: Dictionary,
	navigation: DayNavigation
) -> void:
	position = start_position
	_station_positions = station_positions.duplicate(true)
	_navigation = navigation


func _ready() -> void:
	name = "Chef"
	z_index = 4
	_build_visual()


func _process(delta: float) -> void:
	if not GameManager.is_employee_hired(
		GameManager.STAFF_ROLE_CHEF
	):
		return
	match _chef_state:
		ChefState.IDLE:
			_start_next_step()
		ChefState.MOVING_TO_STATION:
			if _advance_path(delta):
				_reach_station()
		ChefState.WORKING_AT_COUNTER:
			_tick_counter_work(delta)


func get_chef_state() -> ChefState:
	return _chef_state


func get_target_station_id() -> String:
	return _target_station_id


func _start_next_step() -> void:
	if GameManager.get_chef_active_order().is_empty():
		return
	var station_id: String = (
		GameManager.get_chef_next_station_id()
	)
	if (
		station_id.is_empty()
		or not _station_positions.has(station_id)
	):
		return
	_target_station_id = station_id
	if not _start_path(Vector2(_station_positions[station_id])):
		_target_station_id = ""
		return
	_chef_state = ChefState.MOVING_TO_STATION


func _reach_station() -> void:
	if _target_station_id == GameManager.KITCHEN_STATION_COUNTER:
		if GameManager.try_chef_start_counter_work():
			_craft_progress = 0.0
			_chef_state = ChefState.WORKING_AT_COUNTER
			return
		_reset_to_idle()
		return
	GameManager.try_chef_process_station(_target_station_id)
	_reset_to_idle()


func _tick_counter_work(delta: float) -> void:
	var chef_order: Dictionary = GameManager.get_chef_active_order()
	if chef_order.is_empty():
		_reset_to_idle()
		return
	var menu_id: String = String(chef_order.get("menu", ""))
	var craft_duration: float = maxf(
		GameManager.get_menu_craft_duration(menu_id),
		0.001
	)
	_craft_progress += maxf(delta, 0.0)
	if _craft_progress < craft_duration:
		return
	if GameManager.complete_chef_order_at_counter():
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
	_chef_state = ChefState.IDLE
	_target_station_id = ""
	_path = PackedVector2Array()
	_path_index = 0
	_craft_progress = 0.0


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
	label.text = "주방장"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 17)
	add_child(label)
