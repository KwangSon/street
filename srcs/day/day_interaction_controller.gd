extends Node
class_name DayInteractionController

const EXIT_MARGIN: float = 20.0
const PRIORITY_PURCHASE_PAD: int = 100
const PRIORITY_COIN: int = 200
const PRIORITY_INGREDIENT: int = 300
const PRIORITY_COMPLETED_ITEM: int = 400
const PRIORITY_ORDER_CUSTOMER: int = 500
const PRIORITY_DROP_OFF: int = 600

var _player: DayPlayer
var _interactables: Array[DayInteractable] = []
var _current_target: DayInteractable


func configure(player: DayPlayer) -> void:
	_player = player


func register_interactable(interactable: DayInteractable) -> void:
	if interactable == null or _interactables.has(interactable):
		return
	_interactables.append(interactable)


func get_current_target() -> DayInteractable:
	return _current_target


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_clear_current_target()
		return

	var next_target: DayInteractable = _select_target()
	if next_target != _current_target:
		_change_target(next_target)
	if _current_target != null:
		_current_target.interaction_tick(_player, delta)


func _exit_tree() -> void:
	_clear_current_target()


func _select_target() -> DayInteractable:
	var selected: DayInteractable
	var selected_priority: int = -1
	var selected_distance: float = INF
	for interactable: DayInteractable in _interactables:
		if interactable == null or not is_instance_valid(interactable):
			continue
		var extra_margin: float = (
			EXIT_MARGIN if interactable == _current_target else 0.0
		)
		if not interactable.is_player_in_range(
			_player.position,
			extra_margin
		):
			continue

		var priority: int = interactable.get_interaction_priority(
			_player
		)
		var distance: float = (
			interactable.get_interaction_distance_squared(
				_player.position
			)
		)
		if (
			priority > selected_priority
			or (
				priority == selected_priority
				and distance < selected_distance
			)
		):
			selected = interactable
			selected_priority = priority
			selected_distance = distance
	return selected


func _change_target(next_target: DayInteractable) -> void:
	if _current_target != null:
		_current_target.set_interaction_highlighted(false)
		_current_target.interaction_exited(_player)

	_current_target = next_target
	if _current_target != null:
		_current_target.set_interaction_highlighted(true)
		_current_target.interaction_entered(_player)


func _clear_current_target() -> void:
	if _current_target == null:
		return
	if is_instance_valid(_current_target):
		_current_target.set_interaction_highlighted(false)
		if _player != null and is_instance_valid(_player):
			_current_target.interaction_exited(_player)
	_current_target = null
