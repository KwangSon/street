extends Node2D
class_name DayCustomerManager

signal interactable_created(interactable: DayInteractable)

const DayCustomerScript: Script = preload(
	"res://srcs/day/day_customer.gd"
)
const DayPaymentScript: Script = preload(
	"res://srcs/day/day_payment.gd"
)
const DEFAULT_SPAWN_INTERVAL: float = 3.0

var spawn_interval: float = DEFAULT_SPAWN_INTERVAL

var _entrance_position: Vector2 = Vector2.ZERO
var _seat_targets: Dictionary = {}
var _queue_targets: Array[Vector2] = []
var _customers: Dictionary = {}
var _payments: Dictionary = {}
var _spawn_time_remaining: float = DEFAULT_SPAWN_INTERVAL
var _dismissing_unordered_customers: bool = false


func configure(
	entrance_position: Vector2,
	seat_targets: Dictionary,
	queue_targets: Array[Vector2] = []
) -> void:
	_entrance_position = entrance_position
	_seat_targets = seat_targets.duplicate(true)
	_queue_targets = queue_targets.duplicate()


func _ready() -> void:
	_spawn_time_remaining = spawn_interval
	if not GameManager.state_changed.is_connected(
		_on_game_state_changed
	):
		GameManager.state_changed.connect(_on_game_state_changed)
	if GameManager.is_accepting_customers():
		call_deferred("_spawn_customer")
	else:
		call_deferred("_dismiss_unordered_customers")


func _process(delta: float) -> void:
	if not GameManager.is_accepting_customers():
		return
	if GameManager.get_customer_queue().size() >= (
		GameManager.MAX_CUSTOMER_QUEUE
	):
		return
	_spawn_time_remaining -= maxf(delta, 0.0)
	if _spawn_time_remaining > 0.0:
		return
	_spawn_time_remaining = maxf(spawn_interval, 0.01)
	_spawn_customer()


func get_customer(customer_id: String) -> DayCustomer:
	return _customers.get(customer_id) as DayCustomer


func get_customer_count() -> int:
	return _customers.size()


func get_payment(customer_id: String) -> DayPayment:
	return _payments.get(customer_id) as DayPayment


func add_seat(seat_id: String, seat_target: Vector2) -> bool:
	if seat_id.is_empty() or _seat_targets.has(seat_id):
		return false
	_seat_targets[seat_id] = seat_target
	while (
		_has_available_seat()
		and not GameManager.get_customer_queue().is_empty()
	):
		var queue_size_before: int = (
			GameManager.get_customer_queue().size()
		)
		_promote_next_customer()
		if (
			GameManager.get_customer_queue().size()
			>= queue_size_before
		):
			break
	if _has_available_seat():
		_spawn_customer()
	return true


func has_seat(seat_id: String) -> bool:
	return _seat_targets.has(seat_id)


func _spawn_customer() -> void:
	if not GameManager.is_accepting_customers():
		return
	if (
		not _has_available_seat()
		and GameManager.get_customer_queue().size()
		>= GameManager.MAX_CUSTOMER_QUEUE
	):
		return

	var customer_id: String = GameManager.create_day_customer()
	var seat_id: String = _find_available_seat_id()
	var joins_queue: bool = seat_id.is_empty()
	if joins_queue:
		if not GameManager.try_enqueue_day_customer(customer_id):
			return
	elif not GameManager.try_assign_customer_to_seat(
		customer_id,
		seat_id
	):
		return

	var customer: DayCustomer = DayCustomerScript.new()
	customer.configure(
		customer_id,
		_entrance_position
	)
	if joins_queue:
		var queue_index: int = (
			GameManager.get_customer_queue().find(customer_id)
		)
		customer.move_to_queue(_get_queue_target(queue_index))
	else:
		customer.assign_seat(Vector2(_seat_targets[seat_id]))
	customer.reached_seat.connect(_on_customer_reached_seat)
	customer.finished_eating.connect(_on_customer_finished_eating)
	customer.exited.connect(_on_customer_exited)
	_customers[customer_id] = customer
	add_child(customer)
	interactable_created.emit(customer.get_order_target())


func _find_available_seat_id() -> String:
	var seat_ids: Array = _seat_targets.keys()
	seat_ids.sort()
	var day_runtime: Dictionary = GameManager.state["day_runtime"]
	var seat_assignments: Dictionary = (
		day_runtime["seat_assignments"]
	)
	for seat_id_value: Variant in seat_ids:
		var seat_id: String = String(seat_id_value)
		if not seat_assignments.has(seat_id):
			return seat_id
	return ""


func _has_available_seat() -> bool:
	return not _find_available_seat_id().is_empty()


func _get_queue_target(queue_index: int) -> Vector2:
	if (
		queue_index >= 0
		and queue_index < _queue_targets.size()
	):
		return _queue_targets[queue_index]
	return _entrance_position + Vector2(
		60.0 * float(queue_index + 1),
		0.0
	)


func _refresh_queue_targets() -> void:
	var customer_queue: Array[String] = (
		GameManager.get_customer_queue()
	)
	for queue_index: int in range(customer_queue.size()):
		var customer: DayCustomer = get_customer(
			customer_queue[queue_index]
		)
		if customer != null:
			customer.move_to_queue(
				_get_queue_target(queue_index)
			)


func _promote_next_customer() -> void:
	var customer_queue: Array[String] = (
		GameManager.get_customer_queue()
	)
	if customer_queue.is_empty():
		return
	var seat_id: String = _find_available_seat_id()
	if seat_id.is_empty():
		return
	var customer_id: String = customer_queue[0]
	if not GameManager.try_assign_customer_to_seat(
		customer_id,
		seat_id
	):
		return
	var customer: DayCustomer = get_customer(customer_id)
	if customer != null:
		customer.assign_seat(Vector2(_seat_targets[seat_id]))
	_refresh_queue_targets()


func _on_customer_reached_seat(customer_id: String) -> void:
	if not GameManager.mark_customer_seated(
		customer_id,
		GameManager.MENU_MACKEREL
	):
		push_error(
			"Could not create order for seated customer: %s"
			% customer_id
		)


func _on_customer_finished_eating(customer_id: String) -> void:
	if not GameManager.mark_customer_finished_eating(
		customer_id
	):
		push_error(
			"Could not finish meal for customer: %s"
			% customer_id
		)
		return

	var customer: DayCustomer = get_customer(customer_id)
	var payment_data: Dictionary = (
		GameManager.get_customer_payment(customer_id)
	)
	var payment: DayPayment = DayPaymentScript.new()
	payment.configure(
		customer_id,
		int(payment_data["amount"]),
		customer.position + Vector2(100.0, 40.0)
	)
	payment.payment_collected.connect(_on_payment_collected)
	_payments[customer_id] = payment
	add_child(payment)
	interactable_created.emit(payment)


func _on_payment_collected(customer_id: String) -> void:
	var payment: DayPayment = get_payment(customer_id)
	if payment != null:
		_payments.erase(customer_id)
		payment.queue_free()
	var customer: DayCustomer = get_customer(customer_id)
	if customer != null:
		customer.start_leaving(_entrance_position)


func _on_customer_exited(customer_id: String) -> void:
	if not GameManager.finish_customer_exit(customer_id):
		push_error(
			"Could not finish customer exit: %s" % customer_id
		)
		return
	var customer: DayCustomer = get_customer(customer_id)
	_customers.erase(customer_id)
	if customer != null:
		customer.queue_free()
	if not GameManager.is_accepting_customers():
		return
	if _customers.is_empty():
		_spawn_customer()
	else:
		_promote_next_customer()
		_spawn_time_remaining = maxf(spawn_interval, 0.01)


func _on_game_state_changed() -> void:
	if not GameManager.is_accepting_customers():
		_dismiss_unordered_customers()


func _dismiss_unordered_customers() -> void:
	if _dismissing_unordered_customers:
		return
	_dismissing_unordered_customers = true
	var customer_ids: Array[String] = []
	for customer_id_value: Variant in _customers.keys():
		customer_ids.append(String(customer_id_value))
	for customer_id: String in customer_ids:
		if not GameManager.dismiss_unordered_customer(customer_id):
			continue
		var customer: DayCustomer = get_customer(customer_id)
		if customer != null:
			customer.start_leaving(_entrance_position)
	_dismissing_unordered_customers = false
