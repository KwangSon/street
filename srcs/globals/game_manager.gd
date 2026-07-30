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

const MACKEREL_PRICE: int = 6
const MACKEREL_STATION_P0_MAX_LEVEL: int = 2
const SECOND_SEAT_COST: int = 24
const P0_MAX_SEATS: int = 2
const SERVER_HIRE_COST: int = 45
const OPERATING_RESERVE: int = 10
const OPERATING_RESERVE_MESSAGE: String = (
	"내일 장사 밑천 10문은 남겨두어야 합니다."
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
const MAX_CUSTOMER_QUEUE: int = 3

const PREP_NEED_MACKEREL: String = "need_mackerel"
const PREP_NEED_RICE: String = "need_rice"
const PREP_READY_TO_COOK: String = "ready_to_cook"
const PREP_COOKING: String = "cooking"

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
	_ensure_day_runtime_state()
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

	customer["state"] = CUSTOMER_LEAVING
	day_runtime["customer_queue"].erase(customer_id)
	var day_stats: Dictionary = state.get("day_stats", {})
	if not state.has("day_stats"):
		state["day_stats"] = day_stats
	day_stats["departed_customers"] = (
		int(day_stats.get("departed_customers", 0)) + 1
	)
	state_changed.emit()
	return true


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
		or material_id not in ["rice", "mackerel"]
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
	return (
		int(prepared.get("rice", 0)) >= 5
		and int(prepared.get("mackerel", 0)) >= 5
	)


func complete_dawn_and_start_day() -> bool:
	if not can_finish_dawn_preparation():
		return false
	state["day"] = int(state.get("day", 1)) + 1
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
	if not _is_menu_unlocked(menu_id):
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
		"price": get_mackerel_sale_price(),
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
		if String(order.get("status", "")) == ORDER_WAITING:
			waiting_orders.append(order.duplicate(true))
	waiting_orders.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return String(first["customer_id"]) < String(
				second["customer_id"]
			)
	)
	return waiting_orders


func try_accept_waiting_order(customer_id: String) -> bool:
	_ensure_day_runtime_state()
	if is_player_carrying_item() or has_station_item():
		return false

	var day_runtime: Dictionary = state["day_runtime"]
	var orders: Dictionary = day_runtime["orders"]
	if not orders.has(customer_id):
		return false
	var order: Dictionary = orders[customer_id]
	if (
		String(order.get("status", "")) != ORDER_WAITING
		or String(order.get("menu", "")) != MENU_MACKEREL
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
	customer["state"] = CUSTOMER_WAITING_FOR_FOOD
	day_runtime["carried_item"] = {
		"kind": CARRIED_KIND_ORDER_PREP,
		"menu": MENU_MACKEREL,
		"count": 1,
		"customer_id": customer_id,
		"step": PREP_NEED_MACKEREL,
	}
	state_changed.emit()
	return true


func try_collect_mackerel_for_order() -> bool:
	var carried_item: Dictionary = get_carried_item()
	if not _is_prep_at_step(
		carried_item,
		PREP_NEED_MACKEREL
	):
		return false

	var ready_inventory: Dictionary = _get_ready_inventory()
	if (
		int(ready_inventory.get("mackerel", 0)) < 1
		or int(ready_inventory.get("rice", 0)) < 1
	):
		return false

	ready_inventory["mackerel"] = (
		int(ready_inventory["mackerel"]) - 1
	)
	carried_item["step"] = PREP_NEED_RICE
	state["day_runtime"]["carried_item"] = carried_item
	state_changed.emit()
	return true


func try_collect_rice_for_order() -> bool:
	var carried_item: Dictionary = get_carried_item()
	if not _is_prep_at_step(carried_item, PREP_NEED_RICE):
		return false

	var ready_inventory: Dictionary = _get_ready_inventory()
	if int(ready_inventory.get("rice", 0)) < 1:
		return false

	ready_inventory["rice"] = int(ready_inventory["rice"]) - 1
	carried_item["step"] = PREP_READY_TO_COOK
	state["day_runtime"]["carried_item"] = carried_item
	state_changed.emit()
	return true


func try_start_active_order_craft() -> bool:
	var carried_item: Dictionary = get_carried_item()
	var prep_step: String = String(carried_item.get("step", ""))
	if prep_step == PREP_COOKING:
		return true
	if not _is_prep_at_step(
		carried_item,
		PREP_READY_TO_COOK
	):
		return false

	carried_item["step"] = PREP_COOKING
	state["day_runtime"]["carried_item"] = carried_item
	state_changed.emit()
	return true


func complete_active_order_craft() -> bool:
	var carried_item: Dictionary = get_carried_item()
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
	if is_server_hired() and has_station_item():
		return false

	order["status"] = ORDER_READY_TO_SERVE
	var completed_plate: Dictionary = {
		"kind": CARRIED_KIND_PLATE,
		"menu": MENU_MACKEREL,
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
	):
		return false

	var amount: int = int(payment.get("amount", 0))
	if amount <= 0:
		return false
	state["currency"] = int(state.get("currency", 0)) + amount
	payment["status"] = PAYMENT_COLLECTED
	order["status"] = ORDER_PAID
	customer["state"] = CUSTOMER_LEAVING
	_record_mackerel_sale(amount)
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


func get_mackerel_station_level() -> int:
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return 1
	return clampi(
		int(progression_value.get("mackerel_station_level", 1)),
		1,
		MACKEREL_STATION_LEVELS.size()
	)


func get_mackerel_craft_duration() -> float:
	var tuning: Dictionary = MACKEREL_STATION_LEVELS[
		get_mackerel_station_level()
	]
	return float(tuning["craft_duration"])


func get_mackerel_sale_price() -> int:
	var tuning: Dictionary = MACKEREL_STATION_LEVELS[
		get_mackerel_station_level()
	]
	return int(tuning["sale_price"])


func get_mackerel_upgrade_cost() -> int:
	var level: int = get_mackerel_station_level()
	if level >= MACKEREL_STATION_P0_MAX_LEVEL:
		return 0
	var tuning: Dictionary = MACKEREL_STATION_LEVELS[level]
	return int(tuning["upgrade_cost"])


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
	var current_level: int = get_mackerel_station_level()
	if current_level >= MACKEREL_STATION_P0_MAX_LEVEL:
		return false
	if not state.has("progression"):
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var upgrade_cost: int = get_mackerel_upgrade_cost()
	var currency: int = int(state.get("currency", 0))
	if not can_afford_day_growth_purchase(upgrade_cost):
		return false

	var progression: Dictionary = progression_value
	state["currency"] = currency - upgrade_cost
	progression["mackerel_station_level"] = current_level + 1
	state_changed.emit()
	return true


func get_unlocked_seat_count() -> int:
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return 1
	return clampi(
		int(progression_value.get("seats", 1)),
		1,
		P0_MAX_SEATS
	)


func get_second_seat_cost() -> int:
	if get_unlocked_seat_count() >= P0_MAX_SEATS:
		return 0
	return SECOND_SEAT_COST


func try_purchase_second_seat() -> bool:
	if get_unlocked_seat_count() >= P0_MAX_SEATS:
		return false
	if not state.has("progression"):
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var currency: int = int(state.get("currency", 0))
	if not can_afford_day_growth_purchase(SECOND_SEAT_COST):
		return false

	var progression: Dictionary = progression_value
	state["currency"] = currency - SECOND_SEAT_COST
	progression["seats"] = P0_MAX_SEATS
	state_changed.emit()
	return true


func is_server_hired() -> bool:
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	return bool(progression_value.get("server_hired", false))


func get_server_hire_cost() -> int:
	return 0 if is_server_hired() else SERVER_HIRE_COST


func try_hire_server() -> bool:
	if is_server_hired() or not state.has("progression"):
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	var currency: int = int(state.get("currency", 0))
	if not can_afford_day_growth_purchase(SERVER_HIRE_COST):
		return false

	var progression: Dictionary = progression_value
	state["currency"] = currency - SERVER_HIRE_COST
	progression["server_hired"] = true
	progression["server_speed_level"] = maxi(
		1,
		int(progression.get("server_speed_level", 0))
	)
	state_changed.emit()
	return true


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
	if not is_server_hired():
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

	station_item["reserved_by"] = "server"
	order["reserved_by"] = "server"
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
		!= "server"
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
		!= "server"
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
		== "server"
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
		if String(order.get("reserved_by", "")) == "server":
			order.erase("reserved_by")
			changed = true
	if changed:
		state_changed.emit()
	return changed


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
		},
		"prepared": {
			"rice": 0,
			"mackerel": 0,
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
		for material_id: String in ["rice", "mackerel"]:
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
			carried_menu_string != MENU_MACKEREL
			or customer_id.is_empty()
			or prep_step not in [
				PREP_NEED_MACKEREL,
				PREP_NEED_RICE,
				PREP_READY_TO_COOK,
				PREP_COOKING,
			]
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


func _is_menu_unlocked(menu_id: String) -> bool:
	if menu_id == MENU_MACKEREL:
		return true
	if menu_id != MENU_EGG:
		return false
	var progression_value: Variant = state.get("progression", {})
	if not progression_value is Dictionary:
		return false
	return int(progression_value.get("egg_station_level", 0)) > 0


func _is_prep_at_step(
	carried_item: Dictionary,
	expected_step: String
) -> bool:
	return (
		String(carried_item.get("kind", ""))
		== CARRIED_KIND_ORDER_PREP
		and String(carried_item.get("menu", ""))
		== MENU_MACKEREL
		and int(carried_item.get("count", 0)) == 1
		and not String(
			carried_item.get("customer_id", "")
		).is_empty()
		and String(carried_item.get("step", ""))
		== expected_step
	)


func _record_mackerel_sale(amount: int) -> void:
	var day_stats: Dictionary = state.get("day_stats", {})
	if not state.has("day_stats"):
		state["day_stats"] = day_stats
	var day_plates: Dictionary = day_stats.get("plates_sold", {})
	day_stats["plates_sold"] = day_plates
	day_plates[MENU_MACKEREL] = (
		int(day_plates.get(MENU_MACKEREL, 0)) + 1
	)
	day_stats["revenue"] = int(day_stats.get("revenue", 0)) + amount

	var totals: Dictionary = state.get("totals", {})
	if not state.has("totals"):
		state["totals"] = totals
	var total_plates: Dictionary = totals.get("plates_sold", {})
	totals["plates_sold"] = total_plates
	total_plates[MENU_MACKEREL] = (
		int(total_plates.get(MENU_MACKEREL, 0)) + 1
	)
	totals["revenue"] = int(totals.get("revenue", 0)) + amount
	totals["highest_daily_revenue"] = maxi(
		int(totals.get("highest_daily_revenue", 0)),
		int(day_stats["revenue"])
	)
