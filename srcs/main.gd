extends Node2D

const LoadingScreenScript: Script = preload(
	"res://srcs/screens/loading_screen.gd"
)

const SCREEN_LOADING: String = "loading"
const SCREEN_DAY: String = "day"
const SCREEN_DAWN: String = "dawn"

const FUTURE_SCREEN_PATHS: Dictionary = {
	SCREEN_DAY: "res://srcs/screens/day_screen.gd",
	SCREEN_DAWN: "res://srcs/screens/dawn_screen.gd",
}

var loading_save_path: String = SaveManager.SAVE_PATH
var _current_screen: Node
var _is_transitioning: bool = false
var _screen_factories: Dictionary = {}


func _ready() -> void:
	var loading_screen: Node = _create_loading_screen()
	_replace_screen(loading_screen)


func get_current_screen() -> Node:
	return _current_screen


func _on_screen_change_requested() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	var target_screen: Variant = GameManager.state.get("screen")
	if typeof(target_screen) != TYPE_STRING:
		push_error("Game state does not contain a valid screen value.")
		_is_transitioning = false
		return

	var next_screen: Node = _create_screen(String(target_screen))
	if next_screen == null:
		_is_transitioning = false
		return

	_replace_screen(next_screen)
	_is_transitioning = false


func _create_screen(screen_id: String) -> Node:
	if screen_id == SCREEN_LOADING:
		return _create_loading_screen()

	if _screen_factories.has(screen_id):
		var factory: Callable = _screen_factories[screen_id]
		var factory_result: Variant = factory.call()
		if factory_result is Node:
			return factory_result
		push_error("Screen factory did not return a Node: %s" % screen_id)
		return null

	if not FUTURE_SCREEN_PATHS.has(screen_id):
		push_error("Unknown screen in game state: %s" % screen_id)
		return null

	var screen_path: String = FUTURE_SCREEN_PATHS[screen_id]
	if not ResourceLoader.exists(screen_path):
		push_error("Screen is not implemented yet: %s" % screen_id)
		return null

	var screen_script: Script = load(screen_path)
	if screen_script == null or not screen_script.can_instantiate():
		push_error("Screen script cannot be instantiated: %s" % screen_path)
		return null

	var screen_instance: Variant = screen_script.new()
	if not screen_instance is Node:
		push_error("Screen script did not create a Node: %s" % screen_path)
		return null
	return screen_instance


func _create_loading_screen() -> Node:
	var loading_screen: Node = LoadingScreenScript.new()
	loading_screen.set("save_path", loading_save_path)
	return loading_screen


func _replace_screen(next_screen: Node) -> bool:
	if next_screen == null:
		return false
	if not next_screen.has_signal("screen_change_requested"):
		push_error("Screen is missing screen_change_requested signal.")
		next_screen.queue_free()
		return false

	var transition_callable: Callable = Callable(
		self,
		"_on_screen_change_requested"
	)
	next_screen.connect("screen_change_requested", transition_callable)

	var previous_screen: Node = _current_screen
	if previous_screen != null:
		if previous_screen.is_connected(
				"screen_change_requested",
				transition_callable
		):
			previous_screen.disconnect(
				"screen_change_requested",
				transition_callable
			)
		remove_child(previous_screen)
		previous_screen.queue_free()

	_current_screen = next_screen
	add_child(_current_screen)
	return true
