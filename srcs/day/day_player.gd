extends CharacterBody2D
class_name DayPlayer

const DEFAULT_MOVE_SPEED: float = 240.0
const COLLISION_RADIUS: float = 28.0
const ARRIVAL_DISTANCE: float = 4.0

const FACING_UP: StringName = &"up"
const FACING_DOWN: StringName = &"down"
const FACING_LEFT: StringName = &"left"
const FACING_RIGHT: StringName = &"right"

const BODY_COLOR: Color = Color("d9783d")
const DIRECTION_COLOR: Color = Color("fff4d6")

var move_speed: float = DEFAULT_MOVE_SPEED
var _facing_direction: StringName = FACING_DOWN
var _direction_marker: Polygon2D
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false


func _ready() -> void:
	name = "Player"
	collision_layer = 1
	collision_mask = 1
	_build_collision()
	_build_placeholder_visual()
	_update_direction_marker()


func _physics_process(delta: float) -> void:
	_advance_reached_waypoints()
	if not _has_destination:
		velocity = Vector2.ZERO
		return

	var next_waypoint: Vector2 = _path[_path_index]
	var waypoint_offset: Vector2 = next_waypoint - position
	var movement_direction: Vector2 = waypoint_offset.normalized()
	velocity = movement_direction * minf(
		move_speed,
		waypoint_offset.length() / maxf(delta, 0.0001)
	)
	_update_facing_direction(movement_direction)
	move_and_slide()
	_advance_reached_waypoints()


func follow_path(path: PackedVector2Array) -> bool:
	clear_path()
	if path.is_empty():
		return false

	_path = path.duplicate()
	_path_index = 0
	_destination = _path[_path.size() - 1]
	_has_destination = true
	_advance_reached_waypoints()
	return _has_destination


func clear_path() -> void:
	_path = PackedVector2Array()
	_path_index = 0
	_has_destination = false
	velocity = Vector2.ZERO


func has_destination() -> bool:
	return _has_destination


func get_destination() -> Vector2:
	return _destination


func get_current_path() -> PackedVector2Array:
	return _path.duplicate()


func get_facing_direction() -> StringName:
	return _facing_direction


func _advance_reached_waypoints() -> void:
	while (
		_has_destination
		and _path_index < _path.size()
		and position.distance_to(_path[_path_index])
		<= ARRIVAL_DISTANCE
	):
		_path_index += 1

	if _has_destination and _path_index >= _path.size():
		_has_destination = false
		velocity = Vector2.ZERO


func _update_facing_direction(input_vector: Vector2) -> void:
	if absf(input_vector.x) >= absf(input_vector.y):
		_facing_direction = (
			FACING_RIGHT if input_vector.x > 0.0 else FACING_LEFT
		)
	else:
		_facing_direction = (
			FACING_DOWN if input_vector.y > 0.0 else FACING_UP
		)
	_update_direction_marker()


func _build_collision() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return

	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = COLLISION_RADIUS
	collision_shape.shape = circle
	add_child(collision_shape)


func _build_placeholder_visual() -> void:
	if get_node_or_null("Body") != null:
		return

	var body: Polygon2D = Polygon2D.new()
	body.name = "Body"
	body.color = BODY_COLOR
	body.polygon = PackedVector2Array([
		Vector2(0.0, -36.0),
		Vector2(30.0, -4.0),
		Vector2(24.0, 32.0),
		Vector2(-24.0, 32.0),
		Vector2(-30.0, -4.0),
	])
	add_child(body)

	_direction_marker = Polygon2D.new()
	_direction_marker.name = "DirectionMarker"
	_direction_marker.color = DIRECTION_COLOR
	_direction_marker.polygon = PackedVector2Array([
		Vector2(0.0, -29.0),
		Vector2(9.0, -13.0),
		Vector2(-9.0, -13.0),
	])
	add_child(_direction_marker)

	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-36.0, 37.0)
	name_label.size = Vector2(72.0, 28.0)
	name_label.text = "주인"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("35291f"))
	name_label.add_theme_font_size_override("font_size", 18)
	add_child(name_label)


func _update_direction_marker() -> void:
	if _direction_marker == null:
		return

	match _facing_direction:
		FACING_UP:
			_direction_marker.rotation = 0.0
		FACING_RIGHT:
			_direction_marker.rotation = PI * 0.5
		FACING_DOWN:
			_direction_marker.rotation = PI
		FACING_LEFT:
			_direction_marker.rotation = -PI * 0.5
