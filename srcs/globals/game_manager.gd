extends Node

const SAVE_VERSION: int = 1

const SCREEN_DAY: String = "day"
const SCREEN_DAWN: String = "dawn"

const PHASE_SERVICE: String = "service"
const PHASE_SETTLEMENT: String = "settlement"
const PHASE_MARKET: String = "market"
const PHASE_PREP: String = "prep"
const PHASE_STAGE_COMPLETE: String = "stage_complete"

const VALID_PHASES_BY_SCREEN: Dictionary = {
	SCREEN_DAY: [
		PHASE_SERVICE,
		PHASE_SETTLEMENT,
		PHASE_STAGE_COMPLETE,
	],
	SCREEN_DAWN: [
		PHASE_MARKET,
		PHASE_PREP,
	],
}

var state: Dictionary = {}


func create_default_game_state() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"screen": SCREEN_DAY,
		"phase": PHASE_SERVICE,
		"day": 1,
		"service_time_remaining": 330.0,
		"currency": 0,
		"inventory": {
			"ready": {
				"rice": 20,
				"mackerel": 20,
				"egg": 0,
			},
			"raw": {
				"rice": 0,
				"mackerel": 0,
				"egg": 0,
			},
		},
		"progression": {
			"mackerel_station_level": 1,
			"egg_station_level": 0,
			"seats": 1,
			"server_hired": false,
			"server_speed_level": 0,
			"stall_tier": 1,
			"stage_completed": false,
		},
		"day_stats": {
			"plates_sold": {
				"mackerel": 0,
				"egg": 0,
			},
			"revenue": 0,
			"departed_customers": 0,
			"waste": {
				"rice": 0,
				"mackerel": 0,
				"egg": 0,
			},
		},
		"totals": {
			"plates_sold": {
				"mackerel": 0,
				"egg": 0,
			},
			"revenue": 0,
			"waste": {
				"rice": 0,
				"mackerel": 0,
				"egg": 0,
			},
			"highest_daily_revenue": 0,
		},
	}


func apply_loaded_game_state(data: Dictionary) -> bool:
	if not _is_valid_loaded_game_state(data):
		return false

	var loaded_state: Dictionary = data.duplicate(true)
	loaded_state["save_version"] = int(loaded_state["save_version"])
	loaded_state["day"] = int(loaded_state["day"])
	state = loaded_state
	return true


func _is_valid_loaded_game_state(data: Dictionary) -> bool:
	var required_keys: Array[String] = [
		"save_version",
		"screen",
		"phase",
		"day",
	]
	for required_key: String in required_keys:
		if not data.has(required_key):
			return false

	if not _is_integer_number(data["save_version"]):
		return false
	if int(data["save_version"]) != SAVE_VERSION:
		return false

	if typeof(data["screen"]) != TYPE_STRING:
		return false
	if typeof(data["phase"]) != TYPE_STRING:
		return false
	if not _is_integer_number(data["day"]) or int(data["day"]) < 1:
		return false

	var screen: String = data["screen"]
	var phase: String = data["phase"]
	if not VALID_PHASES_BY_SCREEN.has(screen):
		return false

	var valid_phases: Array = VALID_PHASES_BY_SCREEN[screen]
	return phase in valid_phases


func _is_integer_number(value: Variant) -> bool:
	var value_type: int = typeof(value)
	if value_type == TYPE_INT:
		return true
	if value_type != TYPE_FLOAT:
		return false

	var float_value: float = float(value)
	return is_finite(float_value) and float_value == floor(float_value)
