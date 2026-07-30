extends Node

signal state_changed

const SAVE_VERSION: int = 1

const SCREEN_DAY: String = "day"
const SCREEN_DAWN: String = "dawn"

const MENU_MACKEREL: String = "mackerel"
const MENU_EGG: String = "egg"
const CARRIED_KIND_PLATE: String = "plate"

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
		"day_runtime": _create_default_day_runtime(),
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
	_ensure_day_runtime_state()
	state_changed.emit()
	return true


func ensure_day_runtime_state() -> void:
	if _ensure_day_runtime_state():
		state_changed.emit()


func try_consume_ready_ingredients(menu_id: String) -> bool:
	_ensure_day_runtime_state()
	var recipe: Dictionary = _get_recipe(menu_id)
	if recipe.is_empty():
		return false

	var ready_inventory: Dictionary = _get_ready_inventory()
	if not _has_recipe_ingredients(ready_inventory, recipe):
		return false

	for ingredient_id: String in recipe:
		var required_amount: int = int(recipe[ingredient_id])
		ready_inventory[ingredient_id] = (
			int(ready_inventory[ingredient_id]) - required_amount
		)
	state_changed.emit()
	return true


func can_consume_ready_ingredients(menu_id: String) -> bool:
	var recipe: Dictionary = _get_recipe(menu_id)
	if recipe.is_empty():
		return false
	return _has_recipe_ingredients(_get_ready_inventory(), recipe)


func add_completed_plate(menu_id: String, amount: int = 1) -> void:
	if amount <= 0 or not _is_known_menu(menu_id):
		return
	_ensure_day_runtime_state()

	var completed_plates: Dictionary = (
		state["day_runtime"]["completed_plates"]
	)
	completed_plates[menu_id] = (
		int(completed_plates.get(menu_id, 0)) + amount
	)
	state_changed.emit()


func try_take_completed_plate(menu_id: String) -> bool:
	if not _is_known_menu(menu_id):
		return false
	_ensure_day_runtime_state()

	var day_runtime: Dictionary = state["day_runtime"]
	var carried_item: Dictionary = day_runtime["carried_item"]
	if (
		String(carried_item.get("kind", "")) != ""
		or int(carried_item.get("count", 0)) > 0
	):
		return false

	var completed_plates: Dictionary = day_runtime["completed_plates"]
	var plate_count: int = int(completed_plates.get(menu_id, 0))
	if plate_count <= 0:
		return false

	completed_plates[menu_id] = plate_count - 1
	day_runtime["carried_item"] = {
		"kind": CARRIED_KIND_PLATE,
		"menu": menu_id,
		"count": 1,
	}
	state_changed.emit()
	return true


func get_completed_plate_count(menu_id: String) -> int:
	_ensure_day_runtime_state()
	var completed_plates: Dictionary = (
		state["day_runtime"]["completed_plates"]
	)
	return int(completed_plates.get(menu_id, 0))


func get_carried_item() -> Dictionary:
	_ensure_day_runtime_state()
	return Dictionary(
		state["day_runtime"]["carried_item"]
	).duplicate(true)


func is_player_carrying_item() -> bool:
	var carried_item: Dictionary = get_carried_item()
	return (
		String(carried_item.get("kind", "")) != ""
		and int(carried_item.get("count", 0)) > 0
	)


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


func _create_default_day_runtime() -> Dictionary:
	return {
		"completed_plates": {
			MENU_MACKEREL: 0,
			MENU_EGG: 0,
		},
		"carried_item": {
			"kind": "",
			"menu": "",
			"count": 0,
		},
	}


func _ensure_day_runtime_state() -> bool:
	var changed: bool = false
	var day_runtime_value: Variant = state.get("day_runtime", {})
	if not day_runtime_value is Dictionary:
		day_runtime_value = {}
		changed = true
	var day_runtime: Dictionary = day_runtime_value
	if not state.has("day_runtime") or state["day_runtime"] != day_runtime:
		state["day_runtime"] = day_runtime
		changed = true

	var completed_value: Variant = day_runtime.get(
		"completed_plates",
		{}
	)
	if not completed_value is Dictionary:
		completed_value = {}
		changed = true
	var completed_plates: Dictionary = completed_value
	if (
		not day_runtime.has("completed_plates")
		or day_runtime["completed_plates"] != completed_plates
	):
		day_runtime["completed_plates"] = completed_plates
		changed = true

	for menu_id: String in [MENU_MACKEREL, MENU_EGG]:
		var plate_value: Variant = completed_plates.get(menu_id, 0)
		if (
			not _is_integer_number(plate_value)
			or int(plate_value) < 0
		):
			completed_plates[menu_id] = 0
			changed = true
		elif (
			not completed_plates.has(menu_id)
			or typeof(plate_value) != TYPE_INT
		):
			completed_plates[menu_id] = int(plate_value)
			changed = true

	var carried_value: Variant = day_runtime.get("carried_item", {})
	if not carried_value is Dictionary:
		carried_value = {}
		changed = true
	var carried_item: Dictionary = carried_value
	if (
		not day_runtime.has("carried_item")
		or day_runtime["carried_item"] != carried_item
	):
		day_runtime["carried_item"] = carried_item
		changed = true

	var carried_kind: Variant = carried_item.get("kind", "")
	var carried_menu: Variant = carried_item.get("menu", "")
	var carried_count: Variant = carried_item.get("count", 0)
	if typeof(carried_kind) != TYPE_STRING:
		carried_kind = ""
		changed = true
	if typeof(carried_menu) != TYPE_STRING:
		carried_menu = ""
		changed = true
	if (
		not _is_integer_number(carried_count)
		or int(carried_count) < 0
	):
		carried_count = 0
		changed = true

	var normalized_count: int = int(carried_count)
	if String(carried_kind) == "" or normalized_count == 0:
		carried_kind = ""
		carried_menu = ""
		normalized_count = 0
	elif (
		String(carried_kind) != CARRIED_KIND_PLATE
		or not _is_known_menu(String(carried_menu))
	):
		carried_kind = ""
		carried_menu = ""
		normalized_count = 0
		changed = true

	var normalized_carried: Dictionary = {
		"kind": String(carried_kind),
		"menu": String(carried_menu),
		"count": normalized_count,
	}
	for carried_key: Variant in carried_item.keys():
		if not normalized_carried.has(carried_key):
			normalized_carried[carried_key] = carried_item[carried_key]
	if carried_item != normalized_carried:
		day_runtime["carried_item"] = normalized_carried
		changed = true

	return changed


func _get_ready_inventory() -> Dictionary:
	var inventory_value: Variant = state.get("inventory", {})
	if not inventory_value is Dictionary:
		return {}
	var ready_value: Variant = inventory_value.get("ready", {})
	if not ready_value is Dictionary:
		return {}
	return ready_value


func _get_recipe(menu_id: String) -> Dictionary:
	match menu_id:
		MENU_MACKEREL:
			return {
				"rice": 1,
				"mackerel": 1,
			}
		MENU_EGG:
			return {
				"rice": 1,
				"egg": 1,
			}
		_:
			return {}


func _is_known_menu(menu_id: String) -> bool:
	return menu_id == MENU_MACKEREL or menu_id == MENU_EGG


func _has_recipe_ingredients(
	ready_inventory: Dictionary,
	recipe: Dictionary
) -> bool:
	if ready_inventory.is_empty():
		return false
	for ingredient_id: String in recipe:
		var required_amount: int = int(recipe[ingredient_id])
		if int(ready_inventory.get(ingredient_id, 0)) < required_amount:
			return false
	return true
