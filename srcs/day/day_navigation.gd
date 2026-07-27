extends RefCounted
class_name DayNavigation

const GRID_CELL_SIZE: float = 40.0
const INVALID_POINT_ID: Vector2i = Vector2i(-1, -1)

var _grid: AStarGrid2D
var _map_size: Vector2 = Vector2.ZERO
var _clearance: float = 0.0
var _obstacle_rects: Array[Rect2] = []


func configure(
	map_size: Vector2,
	clearance: float,
	obstacle_rects: Array[Rect2]
) -> void:
	_map_size = map_size
	_clearance = clearance
	_obstacle_rects = obstacle_rects.duplicate()

	var grid_size: Vector2i = Vector2i(
		ceili(_map_size.x / GRID_CELL_SIZE),
		ceili(_map_size.y / GRID_CELL_SIZE)
	)
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, grid_size)
	_grid.cell_size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
	_grid.offset = _grid.cell_size * 0.5
	_grid.diagonal_mode = (
		AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	)
	_grid.update()

	for y_position: int in range(grid_size.y):
		for x_position: int in range(grid_size.x):
			var point_id: Vector2i = Vector2i(x_position, y_position)
			var point_position: Vector2 = _grid.get_point_position(
				point_id
			)
			if not _is_position_clear(point_position):
				_grid.set_point_solid(point_id, true)


func find_path(
	start_position: Vector2,
	requested_destination: Vector2
) -> PackedVector2Array:
	if _grid == null:
		return PackedVector2Array()

	var clamped_destination: Vector2 = _clamp_to_map(
		requested_destination
	)
	var start_id: Vector2i = _find_nearest_walkable_id(
		_world_to_point_id(start_position),
		start_position
	)
	var target_id: Vector2i = _find_nearest_walkable_id(
		_world_to_point_id(clamped_destination),
		clamped_destination
	)
	if start_id == INVALID_POINT_ID or target_id == INVALID_POINT_ID:
		return PackedVector2Array()

	var path: PackedVector2Array = _grid.get_point_path(
		start_id,
		target_id
	)
	if path.is_empty():
		return path

	if (
		path[0].distance_to(start_position)
		<= GRID_CELL_SIZE
	):
		path.remove_at(0)

	var requested_id: Vector2i = _world_to_point_id(
		clamped_destination
	)
	var can_use_exact_destination: bool = (
		requested_id == target_id
		and _is_point_walkable(requested_id)
		and _is_position_clear(clamped_destination)
	)
	if can_use_exact_destination:
		if (
			path.is_empty()
			or not path[path.size() - 1].is_equal_approx(
				clamped_destination
			)
		):
			path.append(clamped_destination)
	elif path.is_empty():
		path.append(_grid.get_point_position(target_id))

	return path


func is_world_position_walkable(position: Vector2) -> bool:
	if _grid == null:
		return false
	var clamped_position: Vector2 = _clamp_to_map(position)
	if not clamped_position.is_equal_approx(position):
		return false
	return (
		_is_position_clear(position)
		and _is_point_walkable(_world_to_point_id(position))
	)


func _find_nearest_walkable_id(
	preferred_id: Vector2i,
	preferred_position: Vector2
) -> Vector2i:
	if _is_point_walkable(preferred_id):
		return preferred_id

	var nearest_id: Vector2i = INVALID_POINT_ID
	var nearest_distance_squared: float = INF
	var grid_size: Vector2i = _grid.region.size
	for y_position: int in range(grid_size.y):
		for x_position: int in range(grid_size.x):
			var candidate_id: Vector2i = Vector2i(
				x_position,
				y_position
			)
			if not _is_point_walkable(candidate_id):
				continue
			var candidate_position: Vector2 = (
				_grid.get_point_position(candidate_id)
			)
			var distance_squared: float = (
				candidate_position.distance_squared_to(
					preferred_position
				)
			)
			if distance_squared < nearest_distance_squared:
				nearest_id = candidate_id
				nearest_distance_squared = distance_squared
	return nearest_id


func _world_to_point_id(position: Vector2) -> Vector2i:
	var raw_id: Vector2i = Vector2i(
		floori(position.x / GRID_CELL_SIZE),
		floori(position.y / GRID_CELL_SIZE)
	)
	var grid_size: Vector2i = _grid.region.size
	return Vector2i(
		clampi(raw_id.x, 0, grid_size.x - 1),
		clampi(raw_id.y, 0, grid_size.y - 1)
	)


func _is_point_walkable(point_id: Vector2i) -> bool:
	return (
		_grid.is_in_boundsv(point_id)
		and not _grid.is_point_solid(point_id)
	)


func _is_position_clear(position: Vector2) -> bool:
	if (
		position.x < _clearance
		or position.y < _clearance
		or position.x > _map_size.x - _clearance
		or position.y > _map_size.y - _clearance
	):
		return false

	for obstacle_rect: Rect2 in _obstacle_rects:
		if obstacle_rect.grow(_clearance).has_point(position):
			return false
	return true


func _clamp_to_map(position: Vector2) -> Vector2:
	return Vector2(
		clampf(
			position.x,
			_clearance,
			_map_size.x - _clearance
		),
		clampf(
			position.y,
			_clearance,
			_map_size.y - _clearance
		)
	)
