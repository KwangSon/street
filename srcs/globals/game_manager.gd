extends Node

signal state_changed
signal service_time_changed(time_remaining: float)

const SAVE_VERSION: int = 1

const SCREEN_DAY: String = "day"
const SCREEN_DAWN: String = "dawn"

const MENU_MACKEREL: String = "mackerel"
const MENU_EGG: String = "egg"
const CARRIED_KIND_PLATE: String = "plate"
const CARRIED_KIND_ORDER_PREP: String = "order_prep"

const KITCHEN_STATION_FISH: String = "fish"
const KITCHEN_STATION_RICE: String = "rice"
const KITCHEN_STATION_OTHER: String = "other"
const KITCHEN_STATION_COUNTER: String = "counter"
const KITCHEN_STATIONS: Array[String] = [
	KITCHEN_STATION_FISH,
	KITCHEN_STATION_RICE,
	KITCHEN_STATION_OTHER,
	KITCHEN_STATION_COUNTER,
]
const MENU_KITCHEN_ROUTES: Dictionary = {
	MENU_MACKEREL: [
		KITCHEN_STATION_FISH,
		KITCHEN_STATION_RICE,
		KITCHEN_STATION_COUNTER,
	],
	MENU_EGG: [
		KITCHEN_STATION_OTHER,
		KITCHEN_STATION_RICE,
		KITCHEN_STATION_COUNTER,
	],
}

const STAFF_ROLE_CHEF: String = "chef"
const STAFF_ROLE_SERVICE: String = "service"
const STAFF_ROLES: Array[String] = [
	STAFF_ROLE_CHEF,
	STAFF_ROLE_SERVICE,
]
const CHEF_WEEKLY_WAGE: int = 60
const SERVICE_WEEKLY_WAGE: int = 45
const WAGE_PERIOD_DAYS: int = 7

const CUSTOMER_ENTERING: String = "entering"
const CUSTOMER_WAITING_IN_QUEUE: String = "waiting_in_queue"
const CUSTOMER_MOVING_TO_SEAT: String = "moving_to_seat"
const CUSTOMER_WAITING_FOR_ORDER: String = "waiting_for_order"
const CUSTOMER_WAITING_FOR_FOOD: String = "waiting_for_food"
const CUSTOMER_EATING: String = "eating"
const CUSTOMER_WAITING_FOR_PAYMENT: String = "waiting_for_payment"
const CUSTOMER_LEAVING: String = "leaving"
const ORDER_WAITING: String = "waiting"
const ORDER_PREPARING: String = "preparing"
const ORDER_READY_TO_SERVE: String = "ready_to_serve"
const ORDER_EATING: String = "eating"
const ORDER_WAITING_FOR_PAYMENT: String = "waiting_for_payment"
const ORDER_PAID: String = "paid"
const PAYMENT_WAITING: String = "waiting"
const PAYMENT_COLLECTED: String = "collected"
const RESERVATION_SERVER: String = "server"
const SERVER_TASK_ORDER: String = "order"
const SERVER_TASK_PLATE: String = "plate"
const SERVER_TASK_PAYMENT: String = "payment"

const MACKEREL_PRICE: int = 6
const STAGE_ONE: int = 1
const STAGE_TWO: int = 2
const STAGE_TWO_LOCATION_COST: int = 500
const MACKEREL_STATION_P0_MAX_LEVEL: int = 2
const EGG_STATION_MAX_LEVEL: int = 3
const EGG_STATION_UNLOCK_COST: int = 80
const SECOND_SEAT_COST: int = 24
const THIRD_SEAT_COST: int = 65
const FOURTH_SEAT_COST: int = 140
const MAX_SEATS: int = 4
const SERVER_HIRE_COST: int = SERVICE_WEEKLY_WAGE
const OPERATING_RESERVE: int = 10
const OPERATING_RESERVE_MESSAGE: String = (
	"내일 장사 밑천 10문은 남겨두어야 합니다."
)
const DAY_TWO_GROWTH_MESSAGE: String = (
	"Day 2 영업부터 구매할 수 있습니다."
)
const MATERIAL_COST_PER_PORTION: Dictionary = {
	"rice": 0.8,
	"mackerel": 1.2,
	"egg": 1.6,
}
const MARKET_BUNDLES: Dictionary = {
	"rice": {
		"amount": 5,
		"cost": 4,
	},
	"mackerel": {
		"amount": 5,
		"cost": 6,
	},
	"egg": {
		"amount": 5,
		"cost": 8,
	},
}
const MACKEREL_STATION_LEVELS: Dictionary = {
	1: {
		"craft_duration": 3.2,
		"sale_price": 6,
		"upgrade_cost": 12,
	},
	2: {
		"craft_duration": 3.0,
		"sale_price": 7,
		"upgrade_cost": 28,
	},
	3: {
		"craft_duration": 2.7,
		"sale_price": 8,
		"upgrade_cost": 60,
	},
	4: {
		"craft_duration": 2.4,
		"sale_price": 10,
		"upgrade_cost": 120,
	},
	5: {
		"craft_duration": 2.1,
		"sale_price": 12,
		"upgrade_cost": 0,
	},
}
const EGG_STATION_LEVELS: Dictionary = {
	1: {
		"craft_duration": 4.0,
		"sale_price": 10,
		"upgrade_cost": 40,
	},
	2: {
		"craft_duration": 3.6,
		"sale_price": 12,
		"upgrade_cost": 90,
	},
	3: {
		"craft_duration": 3.2,
		"sale_price": 15,
		"upgrade_cost": 0,
	},
}
const SEAT_COSTS: Dictionary = {
	2: SECOND_SEAT_COST,
	3: THIRD_SEAT_COST,
	4: FOURTH_SEAT_COST,
}
const MAX_CUSTOMER_QUEUE: int = 3

const PREP_NEED_FISH: String = "need_mackerel"
const PREP_NEED_OTHER: String = "need_egg"
const PREP_NEED_RICE: String = "need_rice"
const PREP_READY_FOR_COUNTER: String = "ready_to_cook"
const PREP_COOKING: String = "cooking"
const PREP_NEED_MACKEREL: String = PREP_NEED_FISH
const PREP_NEED_EGG: String = PREP_NEED_OTHER
const PREP_READY_TO_COOK: String = PREP_READY_FOR_COUNTER

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
			"employees": {
				STAFF_ROLE_CHEF: _create_employee_state(
					STAFF_ROLE_CHEF
				),
				STAFF_ROLE_SERVICE: _create_employee_state(
					STAFF_ROLE_SERVICE
				),
			},
			"stall_tier": STAGE_ONE,
			"stage_completed": false,
		},
		"day_runtime": _create_default_day_runtime(),
		"day_stats": _create_default_day_stats(),
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
	_ensure_employee_state()
	_ensure_day_runtime_state()
	_clear_server_task_reservations(false)
	if String(state.get("screen", "")) == SCREEN_DAWN:
		_ensure_dawn_runtime_state()
	state_changed.emit()
	return true


func ensure_day_runtime_state() -> void:
	if _ensure_day_runtime_state():
		state_changed.emit()


func ensure_dawn_runtime_state() -> void:
	if _ensure_dawn_runtime_state():
		state_changed.emit()


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


func create_day_customer() -> String:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var next_customer_id: int = int(
		day_runtime["next_customer_id"]
	)
	var customer_id: String = "customer_%d" % next_customer_id
	day_runtime["next_customer_id"] = next_customer_id + 1

	var customers: Dictionary = day_runtime["customers"]
	customers[customer_id] = {
		"state": CUSTOMER_ENTERING,
		"seat_id": "",
		"menu": "",
	}
	state_changed.emit()
	return customer_id


func tick_service_time(delta: float) -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAY
		or String(state.get("phase", "")) != PHASE_SERVICE
	):
		return false
	var previous_time: float = maxf(
		float(state.get("service_time_remaining", 0.0)),
		0.0
	)
	if previous_time <= 0.0:
		_close_customer_entry()
		return false
	var next_time: float = maxf(
		previous_time - maxf(delta, 0.0),
		0.0
	)
	if is_equal_approx(previous_time, next_time):
		return false

	state["service_time_remaining"] = next_time
	service_time_changed.emit(next_time)
	if next_time <= 0.0:
		_close_customer_entry()
	return true


func is_accepting_customers() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAY
		or String(state.get("phase", "")) != PHASE_SERVICE
		or float(state.get("service_time_remaining", 0.0)) <= 0.0
	):
		return false
	_ensure_day_runtime_state()
	return bool(
		state["day_runtime"].get("accepting_customers", true)
	)


func request_early_close() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAY
		or String(state.get("phase", "")) != PHASE_SERVICE
		or not is_accepting_customers()
	):
		return false
	state["service_time_remaining"] = 0.0
	service_time_changed.emit(0.0)
	_close_customer_entry()
	return true


func try_close_exhausted_service() -> bool:
	if (
		not is_accepting_customers()
		or _has_saleable_ready_portion()
	):
		return false
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	if (
		not day_runtime["orders"].is_empty()
		or not day_runtime["station_item"].is_empty()
		or not day_runtime["server_carried_item"].is_empty()
		or is_player_carrying_item()
	):
		return false
	return request_early_close()


func dismiss_unordered_customer(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	var orders: Dictionary = day_runtime["orders"]
	if (
		not customers.has(customer_id)
		or orders.has(customer_id)
	):
		return false
	var customer: Dictionary = customers[customer_id]
	var customer_state: String = String(
		customer.get("state", "")
	)
	if customer_state not in [
		CUSTOMER_ENTERING,
		CUSTOMER_WAITING_IN_QUEUE,
		CUSTOMER_MOVING_TO_SEAT,
		CUSTOMER_WAITING_FOR_ORDER,
	]:
		return false

	day_runtime["customer_queue"].erase(customer_id)
	var seat_id: String = String(customer.get("seat_id", ""))
	var seat_assignments: Dictionary = day_runtime[
		"seat_assignments"
	]
	if (
		not seat_id.is_empty()
		and String(seat_assignments.get(seat_id, ""))
		== customer_id
	):
		seat_assignments.erase(seat_id)
	customer["state"] = CUSTOMER_LEAVING
	customer["seat_id"] = ""
	var day_stats: Dictionary = state.get("day_stats", {})
	if not state.has("day_stats"):
		state["day_stats"] = day_stats
	day_stats["departed_customers"] = (
		int(day_stats.get("departed_customers", 0)) + 1
	)
	state_changed.emit()
	return true


func dismiss_queued_customer(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	if not customers.has(customer_id):
		return false
	var customer: Dictionary = customers[customer_id]
	if (
		String(customer.get("state", ""))
		!= CUSTOMER_WAITING_IN_QUEUE
	):
		return false
	return dismiss_unordered_customer(customer_id)


func try_begin_settlement() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAY
		or String(state.get("phase", "")) != PHASE_SERVICE
		or float(state.get("service_time_remaining", 0.0)) > 0.0
		or not _is_day_service_drained()
	):
		return false

	var waste_result: Dictionary = _discard_remaining_inventory()
	var day_stats: Dictionary = state.get("day_stats", {})
	if not state.has("day_stats"):
		state["day_stats"] = day_stats
	day_stats["waste"] = waste_result["waste"].duplicate(true)
	day_stats["waste_cost"] = float(waste_result["cost"])

	var plates_sold_value: Variant = day_stats.get(
		"plates_sold",
		{}
	)
	var plates_sold: Dictionary = (
		plates_sold_value
		if plates_sold_value is Dictionary
		else {}
	)
	var total_plates: int = 0
	for plate_count: Variant in plates_sold.values():
		total_plates += int(plate_count)

	var totals: Dictionary = state.get("totals", {})
	if not state.has("totals"):
		state["totals"] = totals
	var total_waste_value: Variant = totals.get("waste", {})
	var total_waste: Dictionary = (
		total_waste_value
		if total_waste_value is Dictionary
		else {}
	)
	totals["waste"] = total_waste
	for material_id: String in MATERIAL_COST_PER_PORTION.keys():
		total_waste[material_id] = (
			int(total_waste.get(material_id, 0))
			+ int(waste_result["waste"].get(material_id, 0))
		)

	state["settlement_summary"] = {
		"day": int(state.get("day", 1)),
		"revenue": int(day_stats.get("revenue", 0)),
		"total_plates": total_plates,
		"plates_sold": plates_sold.duplicate(true),
		"departed_customers": int(
			day_stats.get("departed_customers", 0)
		),
		"waste": waste_result["waste"].duplicate(true),
		"waste_cost": float(waste_result["cost"]),
		"next_customer_min": 18,
		"next_customer_max": 22,
	}
	state["day_runtime"]["accepting_customers"] = false
	state["phase"] = PHASE_SETTLEMENT
	state_changed.emit()
	return true


func get_settlement_summary() -> Dictionary:
	var summary_value: Variant = state.get(
		"settlement_summary",
		{}
	)
	if not summary_value is Dictionary:
		return {}
	return Dictionary(summary_value).duplicate(true)


func get_current_stage() -> int:
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return STAGE_ONE
	return clampi(
		int(progression_value.get("stall_tier", STAGE_ONE)),
		STAGE_ONE,
		STAGE_TWO
	)


func can_purchase_stage_two_location() -> bool:
	return (
		get_current_stage() == STAGE_ONE
		and String(state.get("screen", "")) == SCREEN_DAY
		and String(state.get("phase", "")) == PHASE_SETTLEMENT
		and int(state.get("currency", 0))
		>= STAGE_TWO_LOCATION_COST
	)


func get_stage_two_purchase_shortfall() -> int:
	return maxi(
		0,
		STAGE_TWO_LOCATION_COST
		- int(state.get("currency", 0))
	)


func try_purchase_stage_two_location() -> bool:
	if not can_purchase_stage_two_location():
		return false

	var mackerel_level: int = get_mackerel_station_level()
	var egg_level: int = get_egg_station_level()
	var stage_two_state: Dictionary = create_default_game_state()
	var stage_two_progression: Dictionary = (
		stage_two_state["progression"]
	)
	stage_two_progression["stall_tier"] = STAGE_TWO
	stage_two_progression["mackerel_station_level"] = (
		mackerel_level
	)
	stage_two_progression["egg_station_level"] = egg_level
	state = stage_two_state
	state_changed.emit()
	service_time_changed.emit(
		float(state["service_time_remaining"])
	)
	return true


func request_dawn_after_settlement() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAY
		or String(state.get("phase", "")) != PHASE_SETTLEMENT
	):
		return false
	state["screen"] = SCREEN_DAWN
	state["phase"] = PHASE_MARKET
	state["dawn_runtime"] = _create_default_dawn_runtime()
	state_changed.emit()
	return true


func get_market_bundle(material_id: String) -> Dictionary:
	if not MARKET_BUNDLES.has(material_id):
		return {}
	return Dictionary(MARKET_BUNDLES[material_id]).duplicate(true)


func get_market_purchases() -> Dictionary:
	if String(state.get("screen", "")) != SCREEN_DAWN:
		return {
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		}
	_ensure_dawn_runtime_state()
	return Dictionary(
		state["dawn_runtime"]["purchased"]
	).duplicate(true)


func try_purchase_market_bundle(material_id: String) -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAWN
		or String(state.get("phase", "")) != PHASE_MARKET
		or not MARKET_BUNDLES.has(material_id)
		or (
			material_id == MENU_EGG
			and not is_menu_unlocked(MENU_EGG)
		)
	):
		return false
	_ensure_dawn_runtime_state()
	var bundle: Dictionary = MARKET_BUNDLES[material_id]
	var bundle_cost: int = int(bundle["cost"])
	var currency: int = int(state.get("currency", 0))
	if currency < bundle_cost:
		return false

	var raw_inventory: Dictionary = _get_raw_inventory()
	if raw_inventory.is_empty():
		return false
	var bundle_amount: int = int(bundle["amount"])
	var dawn_runtime: Dictionary = state["dawn_runtime"]
	var purchased: Dictionary = dawn_runtime["purchased"]
	state["currency"] = currency - bundle_cost
	raw_inventory[material_id] = (
		int(raw_inventory.get(material_id, 0)) + bundle_amount
	)
	purchased[material_id] = (
		int(purchased.get(material_id, 0)) + bundle_amount
	)
	dawn_runtime["spent"] = (
		int(dawn_runtime.get("spent", 0)) + bundle_cost
	)
	state_changed.emit()
	return true


func refund_market_purchases() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAWN
		or String(state.get("phase", "")) != PHASE_MARKET
	):
		return false
	_ensure_dawn_runtime_state()
	var dawn_runtime: Dictionary = state["dawn_runtime"]
	var spent: int = int(dawn_runtime.get("spent", 0))
	var purchased: Dictionary = dawn_runtime["purchased"]
	if spent <= 0 and _dictionary_int_total(purchased) <= 0:
		return false

	var raw_inventory: Dictionary = _get_raw_inventory()
	if raw_inventory.is_empty():
		return false
	for material_id: String in purchased.keys():
		raw_inventory[material_id] = maxi(
			0,
			int(raw_inventory.get(material_id, 0))
			- int(purchased.get(material_id, 0))
		)
		purchased[material_id] = 0
	state["currency"] = int(state.get("currency", 0)) + spent
	dawn_runtime["spent"] = 0
	state_changed.emit()
	return true


func can_confirm_market_purchases() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAWN
		or String(state.get("phase", "")) != PHASE_MARKET
	):
		return false
	var raw_inventory: Dictionary = _get_raw_inventory()
	return (
		int(raw_inventory.get("rice", 0)) >= 5
		and int(raw_inventory.get("mackerel", 0)) >= 5
	)


func confirm_market_purchases() -> bool:
	if not can_confirm_market_purchases():
		return false
	_ensure_dawn_runtime_state()
	state["dawn_runtime"]["market_confirmed"] = true
	state["phase"] = PHASE_PREP
	state_changed.emit()
	return true


func get_dawn_prep_next_step(material_id: String) -> int:
	if String(state.get("screen", "")) != SCREEN_DAWN:
		return 0
	_ensure_dawn_runtime_state()
	var prep_steps: Dictionary = state["dawn_runtime"]["prep_steps"]
	return int(prep_steps.get(material_id, 0))


func get_dawn_prepared() -> Dictionary:
	if String(state.get("screen", "")) != SCREEN_DAWN:
		return {
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		}
	_ensure_dawn_runtime_state()
	return Dictionary(
		state["dawn_runtime"]["prepared"]
	).duplicate(true)


func try_complete_dawn_prep_step(
	material_id: String,
	step_index: int
) -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAWN
		or String(state.get("phase", "")) != PHASE_PREP
		or material_id not in ["rice", "mackerel", "egg"]
		or (
			material_id == MENU_EGG
			and not is_menu_unlocked(MENU_EGG)
		)
		or step_index < 0
		or step_index >= 4
	):
		return false
	_ensure_dawn_runtime_state()
	var dawn_runtime: Dictionary = state["dawn_runtime"]
	var prep_steps: Dictionary = dawn_runtime["prep_steps"]
	if int(prep_steps.get(material_id, 0)) != step_index:
		return false
	var raw_inventory: Dictionary = _get_raw_inventory()
	var raw_amount: int = int(raw_inventory.get(material_id, 0))
	if raw_amount <= 0:
		return false
	var ready_inventory: Dictionary = {}
	if step_index == 3:
		ready_inventory = _get_ready_inventory()
		if ready_inventory.is_empty():
			return false

	prep_steps[material_id] = step_index + 1
	if step_index == 3:
		ready_inventory[material_id] = (
			int(ready_inventory.get(material_id, 0))
			+ raw_amount
		)
		raw_inventory[material_id] = 0
		dawn_runtime["prepared"][material_id] = (
			int(
				dawn_runtime["prepared"].get(
					material_id,
					0
				)
			)
			+ raw_amount
		)
	state_changed.emit()
	return true


func can_finish_dawn_preparation() -> bool:
	if (
		String(state.get("screen", "")) != SCREEN_DAWN
		or String(state.get("phase", "")) != PHASE_PREP
	):
		return false
	var prepared: Dictionary = get_dawn_prepared()
	var raw_inventory: Dictionary = _get_raw_inventory()
	return (
		int(prepared.get("rice", 0)) >= 5
		and int(prepared.get("mackerel", 0)) >= 5
		and int(raw_inventory.get("rice", 0)) == 0
		and int(raw_inventory.get("mackerel", 0)) == 0
		and int(raw_inventory.get("egg", 0)) == 0
	)


func complete_dawn_and_start_day() -> bool:
	if not can_finish_dawn_preparation():
		return false
	state["day"] = int(state.get("day", 1)) + 1
	process_due_weekly_wages()
	state["screen"] = SCREEN_DAY
	state["phase"] = PHASE_SERVICE
	state["service_time_remaining"] = 300.0
	state["day_runtime"] = _create_default_day_runtime()
	state["day_stats"] = _create_default_day_stats()
	state.erase("dawn_runtime")
	state_changed.emit()
	service_time_changed.emit(300.0)
	return true


func try_assign_customer_to_seat(
	customer_id: String,
	seat_id: String
) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	if (
		not customers.has(customer_id)
		or not _is_seat_unlocked(seat_id)
	):
		return false

	var seat_assignments: Dictionary = (
		day_runtime["seat_assignments"]
	)
	if seat_assignments.has(seat_id):
		return false

	var customer: Dictionary = customers[customer_id]
	if not String(customer.get("seat_id", "")).is_empty():
		return false

	customer["seat_id"] = seat_id
	customer["state"] = CUSTOMER_MOVING_TO_SEAT
	seat_assignments[seat_id] = customer_id
	var customer_queue: Array = day_runtime["customer_queue"]
	customer_queue.erase(customer_id)
	state_changed.emit()
	return true


func try_enqueue_day_customer(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	if not customers.has(customer_id):
		return false
	var customer: Dictionary = customers[customer_id]
	if (
		String(customer.get("state", ""))
		!= CUSTOMER_ENTERING
	):
		return false

	var customer_queue: Array = day_runtime["customer_queue"]
	if (
		customer_queue.size() >= MAX_CUSTOMER_QUEUE
		or customer_queue.has(customer_id)
	):
		return false
	customer_queue.append(customer_id)
	customer["state"] = CUSTOMER_WAITING_IN_QUEUE
	state_changed.emit()
	return true


func get_customer_queue() -> Array[String]:
	_ensure_day_runtime_state()
	var result: Array[String] = []
	var customer_queue: Array = (
		state["day_runtime"]["customer_queue"]
	)
	for customer_id: Variant in customer_queue:
		result.append(String(customer_id))
	return result


func mark_customer_seated(
	customer_id: String,
	menu_id: String
) -> bool:
	_ensure_day_runtime_state()
	if (
		not _is_menu_unlocked(menu_id)
		or not _has_unreserved_ingredients(menu_id)
	):
		return false

	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	if not customers.has(customer_id):
		return false

	var customer: Dictionary = customers[customer_id]
	var seat_id: String = String(customer.get("seat_id", ""))
	if (
		seat_id.is_empty()
		or String(customer.get("state", ""))
		!= CUSTOMER_MOVING_TO_SEAT
	):
		return false

	customer["state"] = CUSTOMER_WAITING_FOR_ORDER
	customer["menu"] = menu_id
	var orders: Dictionary = day_runtime["orders"]
	orders[customer_id] = {
		"customer_id": customer_id,
		"seat_id": seat_id,
		"menu": menu_id,
		"price": get_menu_sale_price(menu_id),
		"status": ORDER_WAITING,
	}
	state_changed.emit()
	return true


func get_day_customer(customer_id: String) -> Dictionary:
	_ensure_day_runtime_state()
	var customers: Dictionary = state["day_runtime"]["customers"]
	if not customers.has(customer_id):
		return {}
	return Dictionary(customers[customer_id]).duplicate(true)


func get_day_customer_ids() -> Array[String]:
	_ensure_day_runtime_state()
	var customer_ids: Array[String] = []
	var customers: Dictionary = state["day_runtime"]["customers"]
	for customer_id: Variant in customers.keys():
		customer_ids.append(String(customer_id))
	customer_ids.sort()
	return customer_ids


func get_waiting_orders() -> Array[Dictionary]:
	_ensure_day_runtime_state()
	var waiting_orders: Array[Dictionary] = []
	var orders: Dictionary = state["day_runtime"]["orders"]
	for customer_id: Variant in orders.keys():
		var order_value: Variant = orders[customer_id]
		if not order_value is Dictionary:
			continue
		var order: Dictionary = order_value
		if (
			String(order.get("status", "")) == ORDER_WAITING
			and String(order.get("reserved_by", "")).is_empty()
		):
			waiting_orders.append(order.duplicate(true))
	waiting_orders.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return String(first["customer_id"]) < String(
				second["customer_id"]
			)
	)
	return waiting_orders


func get_menu_kitchen_route(menu_id: String) -> Array[String]:
	var route: Array[String] = []
	var route_value: Variant = MENU_KITCHEN_ROUTES.get(menu_id, [])
	if not route_value is Array:
		return route
	for station_id: Variant in route_value:
		route.append(String(station_id))
	return route


func try_accept_waiting_order(customer_id: String) -> bool:
	return _try_accept_waiting_order(customer_id, "")


func try_server_accept_reserved_order(customer_id: String) -> bool:
	return _try_accept_waiting_order(
		customer_id,
		RESERVATION_SERVER
	)


func _try_accept_waiting_order(
	customer_id: String,
	required_reservation: String
) -> bool:
	_ensure_day_runtime_state()
	if is_player_carrying_item() or has_station_item():
		return false
	if (
		is_employee_hired(STAFF_ROLE_CHEF)
		and not get_chef_active_order().is_empty()
	):
		return false

	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	if not orders.has(customer_id):
		return false
	var order: Dictionary = orders[customer_id]
	var menu_id: String = String(order.get("menu", ""))
	if (
		String(order.get("status", "")) != ORDER_WAITING
		or String(order.get("reserved_by", ""))
		!= required_reservation
		or not is_menu_unlocked(menu_id)
	):
		return false

	var customers: Dictionary = day_runtime["customers"]
	if not customers.has(customer_id):
		return false
	var customer: Dictionary = customers[customer_id]
	if (
		String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_ORDER
	):
		return false

	order["status"] = ORDER_PREPARING
	order.erase("reserved_by")
	customer["state"] = CUSTOMER_WAITING_FOR_FOOD
	var route: Array[String] = get_menu_kitchen_route(menu_id)
	if route.is_empty():
		return false
	if is_employee_hired(STAFF_ROLE_CHEF):
		order["prepared_by"] = STAFF_ROLE_CHEF
		day_runtime["chef_order"] = {
			"customer_id": customer_id,
			"menu": menu_id,
			"route_index": 0,
		}
		state_changed.emit()
		return true
	day_runtime["carried_item"] = {
		"kind": CARRIED_KIND_ORDER_PREP,
		"menu": menu_id,
		"count": 1,
		"customer_id": customer_id,
		"route_index": 0,
		"step": _get_prep_step_for_station(route[0]),
	}
	state_changed.emit()
	return true


func try_collect_mackerel_for_order() -> bool:
	return try_process_kitchen_station(KITCHEN_STATION_FISH)


func try_collect_egg_for_order() -> bool:
	return try_process_kitchen_station(KITCHEN_STATION_OTHER)


func try_collect_rice_for_order() -> bool:
	return try_process_kitchen_station(KITCHEN_STATION_RICE)


func try_process_kitchen_station(station_id: String) -> bool:
	if station_id not in KITCHEN_STATIONS:
		return false
	var carried_item: Dictionary = get_carried_item()
	if (
		String(carried_item.get("kind", ""))
		!= CARRIED_KIND_ORDER_PREP
	):
		return false

	var menu_id: String = String(carried_item.get("menu", ""))
	var route: Array[String] = get_menu_kitchen_route(menu_id)
	var route_index: int = _get_carried_route_index(
		carried_item,
		route
	)
	if (
		route_index < 0
		or route_index >= route.size()
		or route[route_index] != station_id
	):
		return false
	if station_id == KITCHEN_STATION_COUNTER:
		return try_start_active_order_craft(menu_id)

	var material_id: String = _get_menu_station_material(
		menu_id,
		station_id
	)
	if material_id.is_empty():
		return false
	var ready_inventory: Dictionary = _get_ready_inventory()
	if not _has_route_materials_from(
		menu_id,
		route,
		route_index,
		ready_inventory
	):
		return false

	ready_inventory[material_id] = (
		int(ready_inventory[material_id]) - 1
	)
	route_index += 1
	carried_item["route_index"] = route_index
	carried_item["step"] = _get_prep_step_for_station(
		route[route_index]
	)
	state["day_runtime"]["carried_item"] = carried_item
	state_changed.emit()
	return true


func try_start_active_order_craft(menu_id: String = "") -> bool:
	var carried_item: Dictionary = get_carried_item()
	if (
		not menu_id.is_empty()
		and String(carried_item.get("menu", "")) != menu_id
	):
		return false
	var prep_step: String = String(carried_item.get("step", ""))
	if prep_step == PREP_COOKING:
		return true
	if is_counter_busy_by_chef() or has_station_item():
		return false
	if not _is_prep_at_step(
		carried_item,
		PREP_READY_FOR_COUNTER
	):
		return false
	var route: Array[String] = get_menu_kitchen_route(
		String(carried_item.get("menu", ""))
	)
	var route_index: int = _get_carried_route_index(
		carried_item,
		route
	)
	if (
		route_index < 0
		or route_index >= route.size()
		or route[route_index] != KITCHEN_STATION_COUNTER
	):
		return false

	carried_item["step"] = PREP_COOKING
	state["day_runtime"]["carried_item"] = carried_item
	state_changed.emit()
	return true


func complete_active_order_craft(menu_id: String = "") -> bool:
	var carried_item: Dictionary = get_carried_item()
	var carried_menu: String = String(carried_item.get("menu", ""))
	if not menu_id.is_empty() and carried_menu != menu_id:
		return false
	if not _is_prep_at_step(carried_item, PREP_COOKING):
		return false

	var customer_id: String = String(
		carried_item.get("customer_id", "")
	)
	var orders: Dictionary = state["day_runtime"]["orders"]
	if not orders.has(customer_id):
		return false
	var order: Dictionary = orders[customer_id]
	if String(order.get("status", "")) != ORDER_PREPARING:
		return false
	if has_station_item():
		return false

	order["status"] = ORDER_READY_TO_SERVE
	var completed_plate: Dictionary = {
		"kind": CARRIED_KIND_PLATE,
		"menu": carried_menu,
		"count": 1,
		"customer_id": customer_id,
	}
	if is_server_hired():
		completed_plate["reserved_by"] = ""
		state["day_runtime"]["station_item"] = completed_plate
		state["day_runtime"]["carried_item"] = {
			"kind": "",
			"menu": "",
			"count": 0,
		}
	else:
		state["day_runtime"]["carried_item"] = completed_plate
	state_changed.emit()
	return true


func get_day_order(customer_id: String) -> Dictionary:
	_ensure_day_runtime_state()
	var orders: Dictionary = state["day_runtime"]["orders"]
	if not orders.has(customer_id):
		return {}
	return Dictionary(orders[customer_id]).duplicate(true)


func try_serve_order(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	var customers: Dictionary = day_runtime["customers"]
	if (
		not orders.has(customer_id)
		or not customers.has(customer_id)
	):
		return false

	var order: Dictionary = orders[customer_id]
	var customer: Dictionary = customers[customer_id]
	var carried_item: Dictionary = day_runtime["carried_item"]
	if (
		String(order.get("status", ""))
		!= ORDER_READY_TO_SERVE
		or String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_FOOD
		or String(carried_item.get("kind", ""))
		!= CARRIED_KIND_PLATE
		or String(carried_item.get("customer_id", ""))
		!= customer_id
		or String(carried_item.get("menu", ""))
		!= String(order.get("menu", ""))
	):
		return false

	order["status"] = ORDER_EATING
	customer["state"] = CUSTOMER_EATING
	day_runtime["carried_item"] = {
		"kind": "",
		"menu": "",
		"count": 0,
	}
	state_changed.emit()
	return true


func mark_customer_finished_eating(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	var customers: Dictionary = day_runtime["customers"]
	if (
		not orders.has(customer_id)
		or not customers.has(customer_id)
	):
		return false

	var order: Dictionary = orders[customer_id]
	var customer: Dictionary = customers[customer_id]
	if (
		String(order.get("status", "")) != ORDER_EATING
		or String(customer.get("state", ""))
		!= CUSTOMER_EATING
	):
		return false

	order["status"] = ORDER_WAITING_FOR_PAYMENT
	customer["state"] = CUSTOMER_WAITING_FOR_PAYMENT
	var payments: Dictionary = day_runtime["payments"]
	var sale_price: int = int(
		order.get("price", MACKEREL_PRICE)
	)
	payments[customer_id] = {
		"customer_id": customer_id,
		"amount": sale_price,
		"status": PAYMENT_WAITING,
	}
	state_changed.emit()
	return true


func collect_customer_payment(customer_id: String) -> bool:
	return _collect_customer_payment(customer_id, "")


func try_server_collect_reserved_payment(
	customer_id: String
) -> bool:
	return _collect_customer_payment(
		customer_id,
		RESERVATION_SERVER
	)


func _collect_customer_payment(
	customer_id: String,
	required_reservation: String
) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	var orders: Dictionary = day_runtime["orders"]
	var payments: Dictionary = day_runtime["payments"]
	if (
		not customers.has(customer_id)
		or not orders.has(customer_id)
		or not payments.has(customer_id)
	):
		return false

	var customer: Dictionary = customers[customer_id]
	var order: Dictionary = orders[customer_id]
	var payment: Dictionary = payments[customer_id]
	if (
		String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_PAYMENT
		or String(order.get("status", ""))
		!= ORDER_WAITING_FOR_PAYMENT
		or String(payment.get("status", ""))
		!= PAYMENT_WAITING
		or String(payment.get("reserved_by", ""))
		!= required_reservation
	):
		return false

	var amount: int = int(payment.get("amount", 0))
	if amount <= 0:
		return false
	state["currency"] = int(state.get("currency", 0)) + amount
	payment.erase("reserved_by")
	payment["status"] = PAYMENT_COLLECTED
	order["status"] = ORDER_PAID
	customer["state"] = CUSTOMER_LEAVING
	_record_menu_sale(String(order.get("menu", "")), amount)
	state_changed.emit()
	return true


func finish_customer_exit(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	if not customers.has(customer_id):
		return false
	var customer: Dictionary = customers[customer_id]
	if (
		String(customer.get("state", ""))
		!= CUSTOMER_LEAVING
	):
		return false

	var seat_id: String = String(customer.get("seat_id", ""))
	var seat_assignments: Dictionary = (
		day_runtime["seat_assignments"]
	)
	day_runtime["customer_queue"].erase(customer_id)
	if (
		not seat_id.is_empty()
		and String(seat_assignments.get(seat_id, ""))
		== customer_id
	):
		seat_assignments.erase(seat_id)
	customers.erase(customer_id)
	day_runtime["orders"].erase(customer_id)
	day_runtime["payments"].erase(customer_id)
	state_changed.emit()
	return true


func get_customer_payment(customer_id: String) -> Dictionary:
	_ensure_day_runtime_state()
	var payments: Dictionary = state["day_runtime"]["payments"]
	if not payments.has(customer_id):
		return {}
	return Dictionary(payments[customer_id]).duplicate(true)


func get_waiting_payment_customer_ids() -> Array[String]:
	_ensure_day_runtime_state()
	var customer_ids: Array[String] = []
	var payments: Dictionary = state["day_runtime"]["payments"]
	for customer_id_value: Variant in payments.keys():
		var customer_id: String = String(customer_id_value)
		var payment_value: Variant = payments[customer_id]
		if (
			payment_value is Dictionary
			and String(payment_value.get("status", ""))
			== PAYMENT_WAITING
			and String(payment_value.get("reserved_by", "")).is_empty()
		):
			customer_ids.append(customer_id)
	customer_ids.sort()
	return customer_ids


func get_mackerel_station_level() -> int:
	return get_menu_station_level(MENU_MACKEREL)


func get_mackerel_craft_duration() -> float:
	return get_menu_craft_duration(MENU_MACKEREL)


func get_mackerel_sale_price() -> int:
	return get_menu_sale_price(MENU_MACKEREL)


func get_mackerel_upgrade_cost() -> int:
	return get_menu_station_upgrade_cost(MENU_MACKEREL)


func get_egg_station_level() -> int:
	return get_menu_station_level(MENU_EGG)


func get_egg_craft_duration() -> float:
	return get_menu_craft_duration(MENU_EGG)


func get_egg_sale_price() -> int:
	return get_menu_sale_price(MENU_EGG)


func get_egg_upgrade_cost() -> int:
	return get_menu_station_upgrade_cost(MENU_EGG)


func can_afford_day_growth_purchase(cost: int) -> bool:
	if (
		cost <= 0
		or String(state.get("screen", "")) != SCREEN_DAY
		or String(state.get("phase", "")) != PHASE_SERVICE
	):
		return false
	return (
		int(state.get("currency", 0)) - cost
		>= OPERATING_RESERVE
	)


func is_day_growth_purchase_reserve_blocked(cost: int) -> bool:
	var currency: int = int(state.get("currency", 0))
	return (
		cost > 0
		and String(state.get("screen", "")) == SCREEN_DAY
		and String(state.get("phase", "")) == PHASE_SERVICE
		and currency >= cost
		and not can_afford_day_growth_purchase(cost)
	)


func try_purchase_mackerel_station_upgrade() -> bool:
	return try_purchase_menu_station_upgrade(MENU_MACKEREL)


func try_purchase_egg_station_upgrade() -> bool:
	return try_purchase_menu_station_upgrade(MENU_EGG)


func get_unlocked_seat_count() -> int:
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return 1
	return clampi(
		int(progression_value.get("seats", 1)),
		1,
		MAX_SEATS
	)


func get_second_seat_cost() -> int:
	if get_unlocked_seat_count() != 1:
		return 0
	return SECOND_SEAT_COST


func try_purchase_second_seat() -> bool:
	if get_unlocked_seat_count() != 1:
		return false
	return try_purchase_next_seat()


func get_next_seat_cost() -> int:
	var next_seat_number: int = get_unlocked_seat_count() + 1
	if next_seat_number > MAX_SEATS:
		return 0
	return int(SEAT_COSTS.get(next_seat_number, 0))


func try_purchase_next_seat() -> bool:
	var current_seats: int = get_unlocked_seat_count()
	if (
		current_seats >= MAX_SEATS
		or not is_next_seat_purchase_available()
	):
		return false
	if not state.has("progression"):
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var purchase_cost: int = get_next_seat_cost()
	var currency: int = int(state.get("currency", 0))
	if not can_afford_day_growth_purchase(purchase_cost):
		return false

	var progression: Dictionary = progression_value
	state["currency"] = currency - purchase_cost
	progression["seats"] = current_seats + 1
	state_changed.emit()
	return true


func is_server_hired() -> bool:
	return is_employee_hired(STAFF_ROLE_SERVICE)


func is_employee_hired(role_id: String) -> bool:
	if role_id not in STAFF_ROLES:
		return false
	_ensure_employee_state()
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var employees_value: Variant = progression_value.get(
		"employees",
		{}
	)
	if not employees_value is Dictionary:
		return false
	var employee_value: Variant = employees_value.get(role_id, {})
	if not employee_value is Dictionary:
		return false
	return bool(employee_value.get("hired", false))


func get_server_hire_cost() -> int:
	return 0 if is_server_hired() else SERVER_HIRE_COST


func try_hire_server() -> bool:
	return try_hire_employee(STAFF_ROLE_SERVICE)


func get_employee_weekly_wage(role_id: String) -> int:
	if role_id == STAFF_ROLE_CHEF:
		return CHEF_WEEKLY_WAGE
	if role_id == STAFF_ROLE_SERVICE:
		return SERVICE_WEEKLY_WAGE
	return 0


func get_employee_next_wage_day(role_id: String) -> int:
	if not is_employee_hired(role_id):
		return 0
	var progression: Dictionary = state["progression"]
	var employees: Dictionary = progression["employees"]
	var employee: Dictionary = employees[role_id]
	return int(employee.get("next_wage_day", 0))


func try_hire_employee(role_id: String) -> bool:
	if (
		role_id not in STAFF_ROLES
		or is_employee_hired(role_id)
		or not state.has("progression")
	):
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var weekly_wage: int = get_employee_weekly_wage(role_id)
	var currency: int = int(state.get("currency", 0))
	if not can_afford_day_growth_purchase(weekly_wage):
		return false

	var progression: Dictionary = progression_value
	var employees: Dictionary = progression["employees"]
	var employee: Dictionary = employees[role_id]
	state["currency"] = currency - weekly_wage
	employee["hired"] = true
	employee["weekly_wage"] = weekly_wage
	employee["next_wage_day"] = (
		int(state.get("day", 1)) + WAGE_PERIOD_DAYS
	)
	if role_id == STAFF_ROLE_SERVICE:
		progression["server_hired"] = true
		progression["server_speed_level"] = maxi(
			1,
			int(progression.get("server_speed_level", 0))
		)
	state_changed.emit()
	return true


func process_due_weekly_wages() -> Dictionary:
	_ensure_employee_state()
	var result: Dictionary = {
		"paid": [],
		"departed": [],
		"total": 0,
	}
	var current_day: int = int(state.get("day", 1))
	var progression: Dictionary = state["progression"]
	var employees: Dictionary = progression["employees"]
	for role_id: String in STAFF_ROLES:
		var employee: Dictionary = employees[role_id]
		if (
			not bool(employee.get("hired", false))
			or int(employee.get("next_wage_day", 0))
			> current_day
		):
			continue
		var weekly_wage: int = get_employee_weekly_wage(role_id)
		var currency: int = int(state.get("currency", 0))
		if currency >= weekly_wage:
			state["currency"] = currency - weekly_wage
			employee["next_wage_day"] = (
				current_day + WAGE_PERIOD_DAYS
			)
			result["paid"].append(role_id)
			result["total"] = int(result["total"]) + weekly_wage
		else:
			employee["hired"] = false
			employee["next_wage_day"] = 0
			result["departed"].append(role_id)
	if not result["paid"].is_empty() or not result["departed"].is_empty():
		progression["server_hired"] = bool(
			employees[STAFF_ROLE_SERVICE].get("hired", false)
		)
		if result["departed"].has(STAFF_ROLE_SERVICE):
			_clear_server_task_reservations(false)
		state_changed.emit()
	return result


func has_station_item() -> bool:
	return not get_station_item().is_empty()


func get_station_item() -> Dictionary:
	_ensure_day_runtime_state()
	var station_item_value: Variant = state["day_runtime"].get(
		"station_item",
		{}
	)
	if not station_item_value is Dictionary:
		return {}
	return Dictionary(station_item_value).duplicate(true)


func get_server_carried_item() -> Dictionary:
	_ensure_day_runtime_state()
	var carried_value: Variant = state["day_runtime"].get(
		"server_carried_item",
		{}
	)
	if not carried_value is Dictionary:
		return {}
	return Dictionary(carried_value).duplicate(true)


func try_reserve_ready_plate_for_server() -> String:
	_ensure_day_runtime_state()
	if (
		not is_server_hired()
		or _has_server_task_reservation()
	):
		return ""
	var day_runtime: Dictionary = state["day_runtime"]
	var server_item: Dictionary = day_runtime["server_carried_item"]
	var station_item: Dictionary = day_runtime["station_item"]
	if not server_item.is_empty() or station_item.is_empty():
		return ""
	if not String(station_item.get("reserved_by", "")).is_empty():
		return ""

	var customer_id: String = String(
		station_item.get("customer_id", "")
	)
	var orders: Dictionary = day_runtime["orders"]
	var customers: Dictionary = day_runtime["customers"]
	if (
		customer_id.is_empty()
		or not orders.has(customer_id)
		or not customers.has(customer_id)
	):
		return ""
	var order: Dictionary = orders[customer_id]
	var customer: Dictionary = customers[customer_id]
	if (
		String(order.get("status", ""))
		!= ORDER_READY_TO_SERVE
		or String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_FOOD
		or String(station_item.get("menu", ""))
		!= String(order.get("menu", ""))
	):
		return ""

	station_item["reserved_by"] = RESERVATION_SERVER
	order["reserved_by"] = RESERVATION_SERVER
	state_changed.emit()
	return customer_id


func try_reserve_waiting_order_for_server() -> String:
	_ensure_day_runtime_state()
	if (
		not is_server_hired()
		or _has_server_task_reservation()
		or has_station_item()
		or (
			is_employee_hired(STAFF_ROLE_CHEF)
			and not get_chef_active_order().is_empty()
		)
		or (
			not is_employee_hired(STAFF_ROLE_CHEF)
			and is_player_carrying_item()
		)
	):
		return ""
	var waiting_orders: Array[Dictionary] = get_waiting_orders()
	if waiting_orders.is_empty():
		return ""
	var customer_id: String = String(
		waiting_orders[0].get("customer_id", "")
	)
	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	var customers: Dictionary = day_runtime["customers"]
	if (
		customer_id.is_empty()
		or not orders.has(customer_id)
		or not customers.has(customer_id)
	):
		return ""
	var order: Dictionary = orders[customer_id]
	var customer: Dictionary = customers[customer_id]
	if (
		String(order.get("status", "")) != ORDER_WAITING
		or not String(order.get("reserved_by", "")).is_empty()
		or String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_ORDER
	):
		return ""
	order["reserved_by"] = RESERVATION_SERVER
	state_changed.emit()
	return customer_id


func try_reserve_waiting_payment_for_server() -> String:
	_ensure_day_runtime_state()
	if (
		not is_server_hired()
		or _has_server_task_reservation()
	):
		return ""
	var waiting_payments: Array[String] = (
		get_waiting_payment_customer_ids()
	)
	if waiting_payments.is_empty():
		return ""
	var customer_id: String = waiting_payments[0]
	var day_runtime: Dictionary = state["day_runtime"]
	var payments: Dictionary = day_runtime["payments"]
	if not payments.has(customer_id):
		return ""
	var payment: Dictionary = payments[customer_id]
	if (
		String(payment.get("status", "")) != PAYMENT_WAITING
		or not String(payment.get("reserved_by", "")).is_empty()
	):
		return ""
	payment["reserved_by"] = RESERVATION_SERVER
	state_changed.emit()
	return customer_id


func try_server_collect_reserved_plate(
	customer_id: String
) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var server_item: Dictionary = day_runtime["server_carried_item"]
	var station_item: Dictionary = day_runtime["station_item"]
	if (
		not server_item.is_empty()
		or String(station_item.get("customer_id", ""))
		!= customer_id
		or String(station_item.get("reserved_by", ""))
		!= RESERVATION_SERVER
	):
		return false

	station_item.erase("reserved_by")
	day_runtime["server_carried_item"] = station_item
	day_runtime["station_item"] = {}
	state_changed.emit()
	return true


func try_server_serve_order(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	var customers: Dictionary = day_runtime["customers"]
	var server_item: Dictionary = day_runtime["server_carried_item"]
	if (
		not orders.has(customer_id)
		or not customers.has(customer_id)
	):
		return false
	var order: Dictionary = orders[customer_id]
	var customer: Dictionary = customers[customer_id]
	if (
		String(order.get("status", ""))
		!= ORDER_READY_TO_SERVE
		or String(order.get("reserved_by", ""))
		!= RESERVATION_SERVER
		or String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_FOOD
		or String(server_item.get("kind", ""))
		!= CARRIED_KIND_PLATE
		or String(server_item.get("customer_id", ""))
		!= customer_id
		or String(server_item.get("menu", ""))
		!= String(order.get("menu", ""))
	):
		return false

	order.erase("reserved_by")
	order["status"] = ORDER_EATING
	customer["state"] = CUSTOMER_EATING
	day_runtime["server_carried_item"] = {}
	state_changed.emit()
	return true


func cancel_server_plate_delivery(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var station_item: Dictionary = day_runtime["station_item"]
	var server_item: Dictionary = day_runtime["server_carried_item"]
	var changed: bool = false
	if (
		String(station_item.get("customer_id", ""))
		== customer_id
		and String(station_item.get("reserved_by", ""))
		== RESERVATION_SERVER
	):
		station_item["reserved_by"] = ""
		changed = true
	elif (
		String(server_item.get("customer_id", ""))
		== customer_id
		and station_item.is_empty()
	):
		server_item["reserved_by"] = ""
		day_runtime["station_item"] = server_item
		day_runtime["server_carried_item"] = {}
		changed = true

	var orders: Dictionary = day_runtime["orders"]
	if orders.has(customer_id):
		var order: Dictionary = orders[customer_id]
		if (
			String(order.get("reserved_by", ""))
			== RESERVATION_SERVER
		):
			order.erase("reserved_by")
			changed = true
	if changed:
		state_changed.emit()
	return changed


func cancel_server_task_reservation(
	task_kind: String,
	customer_id: String
) -> bool:
	if task_kind == SERVER_TASK_PLATE:
		return cancel_server_plate_delivery(customer_id)
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var task_records: Dictionary
	if task_kind == SERVER_TASK_ORDER:
		task_records = day_runtime["orders"]
	elif task_kind == SERVER_TASK_PAYMENT:
		task_records = day_runtime["payments"]
	else:
		return false
	if not task_records.has(customer_id):
		return false
	var task_record: Dictionary = task_records[customer_id]
	if (
		String(task_record.get("reserved_by", ""))
		!= RESERVATION_SERVER
	):
		return false
	task_record.erase("reserved_by")
	state_changed.emit()
	return true


func clear_server_task_reservations() -> bool:
	return _clear_server_task_reservations(true)


func _clear_server_task_reservations(emit_change: bool) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var changed: bool = false
	var station_item: Dictionary = day_runtime["station_item"]
	var server_item: Dictionary = day_runtime["server_carried_item"]
	if (
		not server_item.is_empty()
		and station_item.is_empty()
	):
		server_item.erase("reserved_by")
		day_runtime["station_item"] = server_item
		day_runtime["server_carried_item"] = {}
		changed = true
	elif (
		String(station_item.get("reserved_by", ""))
		== RESERVATION_SERVER
	):
		station_item.erase("reserved_by")
		changed = true

	for dictionary_key: String in ["orders", "payments"]:
		var task_records: Dictionary = day_runtime[dictionary_key]
		for task_record_value: Variant in task_records.values():
			if not task_record_value is Dictionary:
				continue
			var task_record: Dictionary = task_record_value
			if (
				String(task_record.get("reserved_by", ""))
				!= RESERVATION_SERVER
			):
				continue
			task_record.erase("reserved_by")
			changed = true
	if changed and emit_change:
		state_changed.emit()
	return changed


func _has_server_task_reservation() -> bool:
	var day_runtime: Dictionary = state["day_runtime"]
	var station_item: Dictionary = day_runtime["station_item"]
	if (
		String(station_item.get("reserved_by", ""))
		== RESERVATION_SERVER
		or not day_runtime["server_carried_item"].is_empty()
	):
		return true
	for dictionary_key: String in ["orders", "payments"]:
		var task_records: Dictionary = day_runtime[dictionary_key]
		for task_record_value: Variant in task_records.values():
			if (
				task_record_value is Dictionary
				and String(
					task_record_value.get("reserved_by", "")
				) == RESERVATION_SERVER
			):
				return true
	return false


func get_chef_active_order() -> Dictionary:
	_ensure_day_runtime_state()
	var chef_order_value: Variant = state["day_runtime"].get(
		"chef_order",
		{}
	)
	if not chef_order_value is Dictionary:
		return {}
	return Dictionary(chef_order_value).duplicate(true)


func try_chef_accept_waiting_order(
	preferred_customer_id: String = ""
) -> String:
	_ensure_day_runtime_state()
	if (
		not is_employee_hired(STAFF_ROLE_CHEF)
		or not get_chef_active_order().is_empty()
		or has_station_item()
	):
		return ""
	var waiting_orders: Array[Dictionary] = get_waiting_orders()
	if waiting_orders.is_empty():
		return ""
	var order_summary: Dictionary = waiting_orders[0]
	if not preferred_customer_id.is_empty():
		var found_preferred: bool = false
		for waiting_order: Dictionary in waiting_orders:
			if (
				String(waiting_order.get("customer_id", ""))
				== preferred_customer_id
			):
				order_summary = waiting_order
				found_preferred = true
				break
		if not found_preferred:
			return ""
	var customer_id: String = String(
		order_summary.get("customer_id", "")
	)
	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	var customers: Dictionary = day_runtime["customers"]
	if (
		not orders.has(customer_id)
		or not customers.has(customer_id)
	):
		return ""
	var order: Dictionary = orders[customer_id]
	var customer: Dictionary = customers[customer_id]
	var menu_id: String = String(order.get("menu", ""))
	var route: Array[String] = get_menu_kitchen_route(menu_id)
	if (
		route.is_empty()
		or String(order.get("status", "")) != ORDER_WAITING
		or String(customer.get("state", ""))
		!= CUSTOMER_WAITING_FOR_ORDER
	):
		return ""
	order["status"] = ORDER_PREPARING
	order["prepared_by"] = STAFF_ROLE_CHEF
	customer["state"] = CUSTOMER_WAITING_FOR_FOOD
	day_runtime["chef_order"] = {
		"customer_id": customer_id,
		"menu": menu_id,
		"route_index": 0,
	}
	state_changed.emit()
	return customer_id


func get_chef_next_station_id() -> String:
	var chef_order: Dictionary = get_chef_active_order()
	if chef_order.is_empty():
		return ""
	var route: Array[String] = get_menu_kitchen_route(
		String(chef_order.get("menu", ""))
	)
	var route_index: int = int(
		chef_order.get("route_index", -1)
	)
	if route_index < 0 or route_index >= route.size():
		return ""
	return route[route_index]


func is_counter_busy_by_chef() -> bool:
	var chef_order: Dictionary = get_chef_active_order()
	return bool(chef_order.get("counter_working", false))


func try_chef_start_counter_work() -> bool:
	_ensure_day_runtime_state()
	var chef_order: Dictionary = get_chef_active_order()
	var player_item: Dictionary = get_carried_item()
	if (
		chef_order.is_empty()
		or get_chef_next_station_id()
		!= KITCHEN_STATION_COUNTER
		or has_station_item()
		or String(player_item.get("step", "")) == PREP_COOKING
	):
		return false
	if bool(chef_order.get("counter_working", false)):
		return true
	chef_order["counter_working"] = true
	state["day_runtime"]["chef_order"] = chef_order
	state_changed.emit()
	return true


func try_chef_process_station(station_id: String) -> bool:
	_ensure_day_runtime_state()
	var chef_order: Dictionary = get_chef_active_order()
	if (
		chef_order.is_empty()
		or get_chef_next_station_id() != station_id
		or station_id == KITCHEN_STATION_COUNTER
	):
		return false
	var menu_id: String = String(chef_order.get("menu", ""))
	var material_id: String = _get_menu_station_material(
		menu_id,
		station_id
	)
	var ready_inventory: Dictionary = _get_ready_inventory()
	if (
		material_id.is_empty()
		or int(ready_inventory.get(material_id, 0)) < 1
	):
		return false
	ready_inventory[material_id] = (
		int(ready_inventory[material_id]) - 1
	)
	chef_order["route_index"] = (
		int(chef_order.get("route_index", 0)) + 1
	)
	state["day_runtime"]["chef_order"] = chef_order
	state_changed.emit()
	return true


func complete_chef_order_at_counter() -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var chef_order: Dictionary = get_chef_active_order()
	if (
		chef_order.is_empty()
		or get_chef_next_station_id()
		!= KITCHEN_STATION_COUNTER
		or not bool(chef_order.get("counter_working", false))
		or not day_runtime["station_item"].is_empty()
	):
		return false
	var customer_id: String = String(
		chef_order.get("customer_id", "")
	)
	var menu_id: String = String(chef_order.get("menu", ""))
	var orders: Dictionary = day_runtime["orders"]
	if not orders.has(customer_id):
		return false
	var order: Dictionary = orders[customer_id]
	if String(order.get("status", "")) != ORDER_PREPARING:
		return false
	order["status"] = ORDER_READY_TO_SERVE
	day_runtime["station_item"] = {
		"kind": CARRIED_KIND_PLATE,
		"menu": menu_id,
		"count": 1,
		"customer_id": customer_id,
		"reserved_by": "",
	}
	day_runtime["chef_order"] = {}
	state_changed.emit()
	return true


func try_player_collect_counter_plate() -> bool:
	_ensure_day_runtime_state()
	if is_player_carrying_item():
		return false
	var day_runtime: Dictionary = state["day_runtime"]
	var station_item: Dictionary = day_runtime["station_item"]
	if (
		station_item.is_empty()
		or not String(
			station_item.get("reserved_by", "")
		).is_empty()
	):
		return false
	station_item.erase("reserved_by")
	day_runtime["carried_item"] = station_item
	day_runtime["station_item"] = {}
	state_changed.emit()
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


func _is_seat_unlocked(seat_id: String) -> bool:
	if not seat_id.begins_with("seat_"):
		return false
	var seat_number_text: String = seat_id.trim_prefix("seat_")
	if not seat_number_text.is_valid_int():
		return false
	var seat_number: int = int(seat_number_text)
	return (
		seat_number >= 1
		and seat_number <= get_unlocked_seat_count()
	)


func _close_customer_entry() -> void:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	if not bool(day_runtime.get("accepting_customers", true)):
		return
	day_runtime["accepting_customers"] = false
	state_changed.emit()


func _is_day_service_drained() -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	return (
		day_runtime["customers"].is_empty()
		and day_runtime["customer_queue"].is_empty()
		and day_runtime["seat_assignments"].is_empty()
		and day_runtime["orders"].is_empty()
		and day_runtime["payments"].is_empty()
		and day_runtime["station_item"].is_empty()
		and day_runtime["server_carried_item"].is_empty()
		and day_runtime["chef_order"].is_empty()
		and not is_player_carrying_item()
	)


func _discard_remaining_inventory() -> Dictionary:
	var waste: Dictionary = {
		"rice": 0,
		"mackerel": 0,
		"egg": 0,
	}
	var inventory_value: Variant = state.get("inventory", {})
	if not inventory_value is Dictionary:
		return {
			"waste": waste,
			"cost": 0.0,
		}
	var inventory: Dictionary = inventory_value
	for inventory_group_id: String in ["ready", "raw"]:
		var group_value: Variant = inventory.get(
			inventory_group_id,
			{}
		)
		if not group_value is Dictionary:
			continue
		var inventory_group: Dictionary = group_value
		for material_id: String in MATERIAL_COST_PER_PORTION.keys():
			waste[material_id] = (
				int(waste[material_id])
				+ maxi(
					0,
					int(inventory_group.get(material_id, 0))
				)
			)
			inventory_group[material_id] = 0

	var waste_cost: float = 0.0
	for material_id: String in MATERIAL_COST_PER_PORTION.keys():
		waste_cost += (
			float(waste[material_id])
			* float(MATERIAL_COST_PER_PORTION[material_id])
		)
	return {
		"waste": waste,
		"cost": waste_cost,
	}


func _create_default_dawn_runtime() -> Dictionary:
	return {
		"purchased": {
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		},
		"spent": 0,
		"market_confirmed": false,
		"prep_steps": {
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		},
		"prepared": {
			"rice": 0,
			"mackerel": 0,
			"egg": 0,
		},
	}


func _ensure_dawn_runtime_state() -> bool:
	var changed: bool = false
	var dawn_runtime_value: Variant = state.get("dawn_runtime", {})
	if not dawn_runtime_value is Dictionary:
		dawn_runtime_value = {}
		changed = true
	var dawn_runtime: Dictionary = dawn_runtime_value
	if (
		not state.has("dawn_runtime")
		or state["dawn_runtime"] != dawn_runtime
	):
		state["dawn_runtime"] = dawn_runtime
		changed = true

	var purchased_value: Variant = dawn_runtime.get("purchased", {})
	if not purchased_value is Dictionary:
		purchased_value = {}
		changed = true
	var purchased: Dictionary = purchased_value
	for material_id: String in ["rice", "mackerel", "egg"]:
		var normalized_amount: int = maxi(
			0,
			int(purchased.get(material_id, 0))
		)
		if (
			not purchased.has(material_id)
			or int(purchased.get(material_id, 0))
			!= normalized_amount
		):
			purchased[material_id] = normalized_amount
			changed = true
	if (
		not dawn_runtime.has("purchased")
		or dawn_runtime["purchased"] != purchased
	):
		dawn_runtime["purchased"] = purchased
		changed = true

	var normalized_spent: int = maxi(
		0,
		int(dawn_runtime.get("spent", 0))
	)
	if (
		not dawn_runtime.has("spent")
		or int(dawn_runtime.get("spent", 0))
		!= normalized_spent
	):
		dawn_runtime["spent"] = normalized_spent
		changed = true
	if not dawn_runtime.has("market_confirmed"):
		dawn_runtime["market_confirmed"] = false
		changed = true
	elif typeof(dawn_runtime["market_confirmed"]) != TYPE_BOOL:
		dawn_runtime["market_confirmed"] = false
		changed = true

	for dictionary_key: String in ["prep_steps", "prepared"]:
		var dictionary_value: Variant = dawn_runtime.get(
			dictionary_key,
			{}
		)
		if not dictionary_value is Dictionary:
			dictionary_value = {}
			changed = true
		var normalized_dictionary: Dictionary = dictionary_value
		for material_id: String in ["rice", "mackerel", "egg"]:
			var normalized_value: int = maxi(
				0,
				int(
					normalized_dictionary.get(
						material_id,
						0
					)
				)
			)
			if dictionary_key == "prep_steps":
				normalized_value = mini(normalized_value, 4)
			if (
				not normalized_dictionary.has(material_id)
				or int(
					normalized_dictionary.get(material_id, 0)
				)
				!= normalized_value
			):
				normalized_dictionary[material_id] = (
					normalized_value
				)
				changed = true
		if (
			not dawn_runtime.has(dictionary_key)
			or dawn_runtime[dictionary_key]
			!= normalized_dictionary
		):
			dawn_runtime[dictionary_key] = normalized_dictionary
			changed = true
	return changed


func _create_default_day_stats() -> Dictionary:
	return {
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
		"waste_cost": 0.0,
	}


func _create_employee_state(role_id: String) -> Dictionary:
	return {
		"hired": false,
		"weekly_wage": get_employee_weekly_wage(role_id),
		"next_wage_day": 0,
	}


func _ensure_employee_state() -> bool:
	var changed: bool = false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		progression_value = {}
		state["progression"] = progression_value
		changed = true
	var progression: Dictionary = progression_value
	var employees_value: Variant = progression.get("employees", {})
	if not employees_value is Dictionary:
		employees_value = {}
		changed = true
	var employees: Dictionary = employees_value
	for role_id: String in STAFF_ROLES:
		var employee_value: Variant = employees.get(role_id, {})
		if not employee_value is Dictionary:
			employee_value = {}
			changed = true
		var employee: Dictionary = employee_value
		var legacy_hired: bool = (
			role_id == STAFF_ROLE_SERVICE
			and bool(progression.get("server_hired", false))
		)
		var hired: bool = bool(
			employee.get("hired", legacy_hired)
		) or legacy_hired
		var weekly_wage: int = get_employee_weekly_wage(role_id)
		var next_wage_day: int = maxi(
			0,
			int(
				employee.get(
					"next_wage_day",
					int(state.get("day", 1)) + WAGE_PERIOD_DAYS
					if hired
					else 0
				)
			)
		)
		var normalized_employee: Dictionary = {
			"hired": hired,
			"weekly_wage": weekly_wage,
			"next_wage_day": next_wage_day,
		}
		if employee != normalized_employee:
			changed = true
		employees[role_id] = normalized_employee
	if (
		not progression.has("employees")
		or progression["employees"] != employees
	):
		progression["employees"] = employees
		changed = true
	var service_hired: bool = bool(
		employees[STAFF_ROLE_SERVICE].get("hired", false)
	)
	if bool(progression.get("server_hired", false)) != service_hired:
		progression["server_hired"] = service_hired
		changed = true
	return changed


func _create_default_day_runtime() -> Dictionary:
	return {
		"next_customer_id": 1,
		"customers": {},
		"customer_queue": [],
		"seat_assignments": {},
		"orders": {},
		"payments": {},
		"station_item": {},
		"server_carried_item": {},
		"chef_order": {},
		"accepting_customers": true,
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
	var carried_kind_string: String = String(carried_kind)
	var carried_menu_string: String = String(carried_menu)
	if String(carried_kind) == "" or normalized_count == 0:
		carried_kind = ""
		carried_menu = ""
		normalized_count = 0
	elif carried_kind_string == CARRIED_KIND_PLATE:
		if not _is_known_menu(carried_menu_string):
			carried_kind = ""
			carried_menu = ""
			normalized_count = 0
			changed = true
	elif carried_kind_string == CARRIED_KIND_ORDER_PREP:
		var prep_step: String = String(
			carried_item.get("step", "")
		)
		var customer_id: String = String(
			carried_item.get("customer_id", "")
		)
		if (
			not _is_known_menu(carried_menu_string)
			or customer_id.is_empty()
			or prep_step not in [
				PREP_NEED_MACKEREL,
				PREP_NEED_EGG,
				PREP_NEED_RICE,
				PREP_READY_TO_COOK,
				PREP_COOKING,
			]
			or (
				carried_menu_string == MENU_MACKEREL
				and prep_step == PREP_NEED_EGG
			)
			or (
				carried_menu_string == MENU_EGG
				and prep_step == PREP_NEED_MACKEREL
			)
		):
			carried_kind = ""
			carried_menu = ""
			normalized_count = 0
			changed = true
	else:
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

	for dictionary_key: String in [
		"customers",
		"seat_assignments",
		"orders",
		"payments",
		"station_item",
		"server_carried_item",
		"chef_order",
	]:
		var dictionary_value: Variant = day_runtime.get(
			dictionary_key,
			{}
		)
		if not dictionary_value is Dictionary:
			day_runtime[dictionary_key] = {}
			changed = true
		elif not day_runtime.has(dictionary_key):
			day_runtime[dictionary_key] = dictionary_value
			changed = true

	var customer_queue_value: Variant = day_runtime.get(
		"customer_queue",
		[]
	)
	if not customer_queue_value is Array:
		customer_queue_value = []
		changed = true
	var customers_for_queue: Dictionary = day_runtime["customers"]
	var normalized_queue: Array = []
	for queued_customer_value: Variant in customer_queue_value:
		if normalized_queue.size() >= MAX_CUSTOMER_QUEUE:
			changed = true
			break
		if typeof(queued_customer_value) != TYPE_STRING:
			changed = true
			continue
		var queued_customer_id: String = String(
			queued_customer_value
		)
		if (
			not customers_for_queue.has(queued_customer_id)
			or normalized_queue.has(queued_customer_id)
		):
			changed = true
			continue
		normalized_queue.append(queued_customer_id)
	if (
		not day_runtime.has("customer_queue")
		or day_runtime["customer_queue"] != normalized_queue
	):
		day_runtime["customer_queue"] = normalized_queue
		changed = true

	var accepting_value: Variant = day_runtime.get(
		"accepting_customers",
		float(state.get("service_time_remaining", 0.0)) > 0.0
	)
	var normalized_accepting: bool = (
		bool(accepting_value)
		if typeof(accepting_value) == TYPE_BOOL
		else float(state.get("service_time_remaining", 0.0)) > 0.0
	)
	if (
		not day_runtime.has("accepting_customers")
		or day_runtime["accepting_customers"]
		!= normalized_accepting
	):
		day_runtime["accepting_customers"] = normalized_accepting
		changed = true

	var next_customer_value: Variant = day_runtime.get(
		"next_customer_id",
		1
	)
	if (
		not _is_integer_number(next_customer_value)
		or int(next_customer_value) < 1
	):
		day_runtime["next_customer_id"] = 1
		changed = true
	elif (
		not day_runtime.has("next_customer_id")
		or typeof(next_customer_value) != TYPE_INT
	):
		day_runtime["next_customer_id"] = int(next_customer_value)
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


func _has_saleable_ready_portion() -> bool:
	var ready_inventory: Dictionary = _get_ready_inventory()
	if int(ready_inventory.get("rice", 0)) <= 0:
		return false
	if int(ready_inventory.get("mackerel", 0)) > 0:
		return true
	return (
		_is_menu_unlocked(MENU_EGG)
		and int(ready_inventory.get("egg", 0)) > 0
	)


func _get_raw_inventory() -> Dictionary:
	var inventory_value: Variant = state.get("inventory", {})
	if not inventory_value is Dictionary:
		return {}
	var raw_value: Variant = inventory_value.get("raw", {})
	if not raw_value is Dictionary:
		return {}
	return raw_value


func _dictionary_int_total(values: Dictionary) -> int:
	var total: int = 0
	for value: Variant in values.values():
		total += maxi(0, int(value))
	return total


func _is_known_menu(menu_id: String) -> bool:
	return menu_id == MENU_MACKEREL or menu_id == MENU_EGG


func is_menu_unlocked(menu_id: String) -> bool:
	if menu_id == MENU_MACKEREL:
		return true
	if menu_id != MENU_EGG:
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	return int(progression_value.get("egg_station_level", 0)) > 0


func _is_menu_unlocked(menu_id: String) -> bool:
	return is_menu_unlocked(menu_id)


func _is_prep_at_step(
	carried_item: Dictionary,
	expected_step: String
) -> bool:
	return (
		String(carried_item.get("kind", ""))
		== CARRIED_KIND_ORDER_PREP
		and _is_known_menu(String(carried_item.get("menu", "")))
		and int(carried_item.get("count", 0)) == 1
		and not String(
			carried_item.get("customer_id", "")
		).is_empty()
		and String(carried_item.get("step", ""))
		== expected_step
	)


func _get_carried_route_index(
	carried_item: Dictionary,
	route: Array[String]
) -> int:
	var route_index_value: Variant = carried_item.get(
		"route_index",
		null
	)
	if (
		route_index_value != null
		and _is_integer_number(route_index_value)
	):
		return int(route_index_value)
	var prep_step: String = String(carried_item.get("step", ""))
	var expected_station: String = ""
	if prep_step == PREP_NEED_FISH:
		expected_station = KITCHEN_STATION_FISH
	elif prep_step == PREP_NEED_OTHER:
		expected_station = KITCHEN_STATION_OTHER
	elif prep_step == PREP_NEED_RICE:
		expected_station = KITCHEN_STATION_RICE
	elif prep_step in [PREP_READY_FOR_COUNTER, PREP_COOKING]:
		expected_station = KITCHEN_STATION_COUNTER
	return route.find(expected_station)


func _get_prep_step_for_station(station_id: String) -> String:
	if station_id == KITCHEN_STATION_FISH:
		return PREP_NEED_FISH
	if station_id == KITCHEN_STATION_OTHER:
		return PREP_NEED_OTHER
	if station_id == KITCHEN_STATION_RICE:
		return PREP_NEED_RICE
	if station_id == KITCHEN_STATION_COUNTER:
		return PREP_READY_FOR_COUNTER
	return ""


func _get_menu_station_material(
	menu_id: String,
	station_id: String
) -> String:
	if station_id == KITCHEN_STATION_RICE:
		return "rice"
	if station_id == KITCHEN_STATION_FISH:
		return menu_id if menu_id == MENU_MACKEREL else ""
	if station_id == KITCHEN_STATION_OTHER:
		return menu_id if menu_id == MENU_EGG else ""
	return ""


func _has_route_materials_from(
	menu_id: String,
	route: Array[String],
	start_index: int,
	ready_inventory: Dictionary
) -> bool:
	var required_materials: Dictionary = {}
	for route_index: int in range(start_index, route.size()):
		var material_id: String = _get_menu_station_material(
			menu_id,
			route[route_index]
		)
		if material_id.is_empty():
			continue
		required_materials[material_id] = (
			int(required_materials.get(material_id, 0)) + 1
		)
	for material_id: String in required_materials.keys():
		if (
			int(ready_inventory.get(material_id, 0))
			< int(required_materials[material_id])
		):
			return false
	return true


func get_menu_display_name(menu_id: String) -> String:
	if menu_id == MENU_MACKEREL:
		return "고등어"
	if menu_id == MENU_EGG:
		return "계란"
	return menu_id


func get_menu_station_level(menu_id: String) -> int:
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return 1 if menu_id == MENU_MACKEREL else 0
	var progression: Dictionary = progression_value
	if menu_id == MENU_MACKEREL:
		return clampi(
			int(progression.get("mackerel_station_level", 1)),
			1,
			MACKEREL_STATION_LEVELS.size()
		)
	if menu_id == MENU_EGG:
		return clampi(
			int(progression.get("egg_station_level", 0)),
			0,
			EGG_STATION_MAX_LEVEL
		)
	return 0


func get_menu_station_max_level(menu_id: String) -> int:
	if menu_id == MENU_MACKEREL:
		return MACKEREL_STATION_P0_MAX_LEVEL
	if menu_id == MENU_EGG:
		return EGG_STATION_MAX_LEVEL
	return 0


func get_menu_craft_duration(menu_id: String) -> float:
	var level: int = get_menu_station_level(menu_id)
	if menu_id == MENU_MACKEREL:
		return float(MACKEREL_STATION_LEVELS[level]["craft_duration"])
	if menu_id == MENU_EGG and level > 0:
		return float(EGG_STATION_LEVELS[level]["craft_duration"])
	return 0.0


func get_menu_sale_price(menu_id: String) -> int:
	var level: int = get_menu_station_level(menu_id)
	if menu_id == MENU_MACKEREL:
		return int(MACKEREL_STATION_LEVELS[level]["sale_price"])
	if menu_id == MENU_EGG and level > 0:
		return int(EGG_STATION_LEVELS[level]["sale_price"])
	return 0


func get_menu_station_upgrade_cost(menu_id: String) -> int:
	var level: int = get_menu_station_level(menu_id)
	var max_level: int = get_menu_station_max_level(menu_id)
	if max_level <= 0 or level >= max_level:
		return 0
	if menu_id == MENU_MACKEREL:
		return int(MACKEREL_STATION_LEVELS[level]["upgrade_cost"])
	if menu_id == MENU_EGG:
		if level == 0:
			return EGG_STATION_UNLOCK_COST
		return int(EGG_STATION_LEVELS[level]["upgrade_cost"])
	return 0


func try_purchase_menu_station_upgrade(menu_id: String) -> bool:
	var current_level: int = get_menu_station_level(menu_id)
	var max_level: int = get_menu_station_max_level(menu_id)
	if (
		max_level <= 0
		or current_level >= max_level
		or not is_menu_station_purchase_available(menu_id)
	):
		return false
	if not state.has("progression"):
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var upgrade_cost: int = get_menu_station_upgrade_cost(menu_id)
	var currency: int = int(state.get("currency", 0))
	if not can_afford_day_growth_purchase(upgrade_cost):
		return false

	var progression: Dictionary = progression_value
	state["currency"] = currency - upgrade_cost
	var progression_key: String = (
		"mackerel_station_level"
		if menu_id == MENU_MACKEREL
		else "egg_station_level"
	)
	progression[progression_key] = current_level + 1
	state_changed.emit()
	return true


func is_menu_station_purchase_available(menu_id: String) -> bool:
	return not (
		menu_id == MENU_EGG
		and get_menu_station_level(menu_id) == 0
		and int(state.get("day", 1)) < 2
	)


func is_next_seat_purchase_available() -> bool:
	var next_seat_number: int = get_unlocked_seat_count() + 1
	return next_seat_number <= 2 or int(state.get("day", 1)) >= 2


func choose_menu_for_customer(customer_id: String) -> String:
	var can_order_mackerel: bool = _has_unreserved_ingredients(
		MENU_MACKEREL
	)
	var can_order_egg: bool = (
		is_menu_unlocked(MENU_EGG)
		and _has_unreserved_ingredients(MENU_EGG)
	)
	if can_order_egg and _customer_prefers_egg(customer_id):
		return MENU_EGG
	if can_order_mackerel:
		return MENU_MACKEREL
	if can_order_egg:
		return MENU_EGG
	return ""


func _has_unreserved_ingredients(menu_id: String) -> bool:
	return (
		get_available_ready_count(menu_id) > 0
		and get_available_ready_count("rice") > 0
	)


func get_available_ready_count(material_id: String) -> int:
	var ready_inventory: Dictionary = _get_ready_inventory()
	return maxi(
		0,
		int(ready_inventory.get(material_id, 0))
		- get_reserved_ready_count(material_id)
	)


func get_reserved_ready_count(material_id: String) -> int:
	var reserved_inventory: Dictionary = _get_reserved_ready_inventory()
	return int(reserved_inventory.get(material_id, 0))


func _get_reserved_ready_inventory() -> Dictionary:
	var reserved_inventory: Dictionary = {
		"rice": 0,
		MENU_MACKEREL: 0,
		MENU_EGG: 0,
	}
	var day_runtime: Dictionary = state.get("day_runtime", {})
	var orders_value: Variant = day_runtime.get("orders", {})
	if orders_value is Dictionary:
		var orders: Dictionary = orders_value
		for order_value: Variant in orders.values():
			if not order_value is Dictionary:
				continue
			var order: Dictionary = order_value
			if String(order.get("status", "")) != ORDER_WAITING:
				continue
			reserved_inventory["rice"] = (
				int(reserved_inventory["rice"]) + 1
			)
			var order_menu: String = String(order.get("menu", ""))
			if reserved_inventory.has(order_menu):
				reserved_inventory[order_menu] = (
					int(reserved_inventory[order_menu]) + 1
				)
	var carried_item: Dictionary = get_carried_item()
	if (
		String(carried_item.get("kind", ""))
		== CARRIED_KIND_ORDER_PREP
	):
		var carried_step: String = String(
			carried_item.get("step", "")
		)
		if carried_step in [PREP_NEED_MACKEREL, PREP_NEED_EGG]:
			reserved_inventory["rice"] = (
				int(reserved_inventory["rice"]) + 1
			)
			var carried_menu: String = String(
				carried_item.get("menu", "")
			)
			if reserved_inventory.has(carried_menu):
				reserved_inventory[carried_menu] = (
					int(reserved_inventory[carried_menu]) + 1
				)
		elif carried_step == PREP_NEED_RICE:
			reserved_inventory["rice"] = (
				int(reserved_inventory["rice"]) + 1
			)
	var chef_order: Dictionary = get_chef_active_order()
	if not chef_order.is_empty():
		var chef_menu: String = String(
			chef_order.get("menu", "")
		)
		var chef_route: Array[String] = get_menu_kitchen_route(
			chef_menu
		)
		var chef_route_index: int = int(
			chef_order.get("route_index", 0)
		)
		for route_index: int in range(
			chef_route_index,
			chef_route.size()
		):
			var station_id: String = chef_route[route_index]
			if station_id == KITCHEN_STATION_RICE:
				reserved_inventory["rice"] = (
					int(reserved_inventory["rice"]) + 1
				)
			elif (
				station_id
				in [KITCHEN_STATION_FISH, KITCHEN_STATION_OTHER]
				and reserved_inventory.has(chef_menu)
			):
				reserved_inventory[chef_menu] = (
					int(reserved_inventory[chef_menu]) + 1
				)
	return reserved_inventory


func _customer_prefers_egg(customer_id: String) -> bool:
	var numeric_text: String = customer_id.trim_prefix("customer_")
	if not numeric_text.is_valid_int():
		return false
	return posmod(int(numeric_text) - 1, 10) in [0, 3, 6]


func _record_menu_sale(menu_id: String, amount: int) -> void:
	if not _is_known_menu(menu_id):
		return
	var day_stats: Dictionary = state.get("day_stats", {})
	if not state.has("day_stats"):
		state["day_stats"] = day_stats
	var day_plates: Dictionary = day_stats.get("plates_sold", {})
	day_stats["plates_sold"] = day_plates
	day_plates[menu_id] = (
		int(day_plates.get(menu_id, 0)) + 1
	)
	day_stats["revenue"] = int(day_stats.get("revenue", 0)) + amount

	var totals: Dictionary = state.get("totals", {})
	if not state.has("totals"):
		state["totals"] = totals
	var total_plates: Dictionary = totals.get("plates_sold", {})
	totals["plates_sold"] = total_plates
	total_plates[menu_id] = (
		int(total_plates.get(menu_id, 0)) + 1
	)
	totals["revenue"] = int(totals.get("revenue", 0)) + amount
	totals["highest_daily_revenue"] = maxi(
		int(totals.get("highest_daily_revenue", 0)),
		int(day_stats["revenue"])
	)
