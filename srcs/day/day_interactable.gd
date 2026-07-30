extends Node2D
class_name DayInteractable


func get_interaction_priority(_player: DayPlayer) -> int:
	return 0


func is_player_in_range(
	_player_position: Vector2,
	_extra_margin: float = 0.0
) -> bool:
	return false


func get_interaction_distance_squared(
	_player_position: Vector2
) -> float:
	return INF


func interaction_entered(_player: DayPlayer) -> void:
	pass


func interaction_tick(_player: DayPlayer, _delta: float) -> void:
	pass


func interaction_exited(_player: DayPlayer) -> void:
	pass


func set_interaction_highlighted(_highlighted: bool) -> void:
	pass
