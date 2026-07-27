extends Node2D

const DayScreenScript: Script = preload(
	"res://srcs/screens/day_screen.gd"
)


func _ready() -> void:
	var manual_state: Dictionary = GameManager.create_default_game_state()
	manual_state["screen"] = GameManager.SCREEN_DAY
	manual_state["phase"] = GameManager.PHASE_SERVICE
	manual_state["day"] = 1
	manual_state["service_time_remaining"] = 330.0
	manual_state["currency"] = 0
	manual_state["inventory"]["ready"]["rice"] = 20
	manual_state["inventory"]["ready"]["mackerel"] = 20

	if not GameManager.apply_loaded_game_state(manual_state):
		push_error("Could not apply the manual DayScreen game state.")
		return

	var day_screen: Node = DayScreenScript.new()
	add_child(day_screen)
