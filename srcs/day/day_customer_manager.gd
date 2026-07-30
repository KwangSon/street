extends Node2D
class_name DayCustomerManager

signal interactable_created(interactable: DayInteractable)

const DayCustomerScript: Script = preload(
	"res://srcs/day/day_customer.gd"
)
const DayPaymentScript: Script = preload(
	"res://srcs/day/day_payment.gd"
)

var _entrance_position: Vector2 = Vector2.ZERO
var _seat_targets: Dictionary = {}
var _customers: Dictionary = {}
var _payments: Dictionary = {}


func configure(
	entrance_position: Vector2,
	seat_targets: Dictionary
) -> void:
	_entrance_position = entrance_position
	_seat_targets = seat_targets.duplicate(true)


func _ready() -> void:
	call_deferred("_spawn_initial_customer")


func get_customer(customer_id: String) -> DayCustomer:
	return _customers.get(customer_id) as DayCustomer


func get_customer_count() -> int:
	return _customers.size()


func get_payment(customer_id: String) -> DayPayment:
	return _payments.get(customer_id) as DayPayment


func _spawn_initial_customer() -> void:
	if not GameManager.get_day_customer_ids().is_empty():
		return

	var customer_id: String = GameManager.create_day_customer()
	var seat_id: String = _find_available_seat_id()
	if seat_id.is_empty():
		return
	if not GameManager.try_assign_customer_to_seat(
		customer_id,
		seat_id
	):
		return

	var customer: DayCustomer = DayCustomerScript.new()
	customer.configure(
		customer_id,
		_entrance_position,
		Vector2(_seat_targets[seat_id])
	)
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
	call_deferred("_spawn_initial_customer")
