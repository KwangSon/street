extends DayInteractable

var interaction_priority: int = 0
var interaction_range: float = 100.0
var enter_count: int = 0
var exit_count: int = 0
var highlighted: bool = false


func get_interaction_priority(_player: DayPlayer) -> int:
	return interaction_priority


func is_player_in_range(
	player_position: Vector2,
	extra_margin: float = 0.0
) -> bool:
	return (
		global_position.distance_to(player_position)
		<= interaction_range + extra_margin
	)


func get_interaction_distance_squared(
	player_position: Vector2
) -> float:
	return global_position.distance_squared_to(player_position)


func interaction_entered(_player: DayPlayer) -> void:
	enter_count += 1


func interaction_exited(_player: DayPlayer) -> void:
	exit_count += 1


func set_interaction_highlighted(value: bool) -> void:
	highlighted = value
