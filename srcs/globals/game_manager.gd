extends Node

signal state_changed

const SAVE_VERSION: int = 1

const SCREEN_DAY: String = "day"
const SCREEN_DAWN: String = "dawn"

const MENU_MACKEREL: String = "mackerel"
const MENU_EGG: String = "egg"
const CARRIED_KIND_PLATE: String = "plate"
const CARRIED_KIND_ORDER_PREP: String = "order_prep"

const CUSTOMER_ENTERING: String = "entering"
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


func try_assign_customer_to_seat(
	customer_id: String,
	seat_id: String
) -> bool:
	_ensure_day_runtime_state()
	var day_runtime: Dictionary = state["day_runtime"]
	var customers: Dictionary = day_runtime["customers"]
	if not customers.has(customer_id) or seat_id.is_empty():
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
	state_changed.emit()
	return true


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
	if is_player_carrying_item():
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

	order["status"] = ORDER_READY_TO_SERVE
	state["day_runtime"]["carried_item"] = {
		"kind": CARRIED_KIND_PLATE,
		"menu": MENU_MACKEREL,
		"count": 1,
		"customer_id": customer_id,
	}
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
	payments[customer_id] = {
		"customer_id": customer_id,
		"amount": MACKEREL_PRICE,
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
		"next_customer_id": 1,
		"customers": {},
		"seat_assignments": {},
		"orders": {},
		"payments": {},
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
