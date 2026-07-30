extends Node2D
class_name DawnScreen

signal screen_change_requested

const DayPlayerScript: Script = preload(
	"res://srcs/day/day_player.gd"
)
const DayInteractionControllerScript: Script = preload(
	"res://srcs/day/day_interaction_controller.gd"
)
const DawnPurchasePadScript: Script = preload(
	"res://srcs/dawn/dawn_purchase_pad.gd"
)

const VIEWPORT_SIZE: Vector2 = Vector2(720.0, 1280.0)
const HUD_HEIGHT: float = 112.0
const ACTION_PANEL_TOP: float = 1000.0
const DRAG_THRESHOLD: float = 8.0
const MOUSE_POINTER_ID: int = -1
const NO_POINTER_ID: int = -2

const BACKGROUND_COLOR: Color = Color("565d68")
const FLOOR_COLOR: Color = Color("b8a98f")
const HUD_COLOR: Color = Color("252b35")
const TEXT_COLOR: Color = Color("fff4d6")
const PLAYER_START_POSITION: Vector2 = Vector2(360.0, 820.0)

var _world: Node2D
var _player: DayPlayer
var _interaction_controller: DayInteractionController
var _rice_purchase_pad: DawnPurchasePad
var _mackerel_purchase_pad: DawnPurchasePad
var _currency_label: Label
var _purchase_label: Label
var _status_label: Label
var _refund_button: Button
var _active_pointer_id: int = NO_POINTER_ID
var _gesture_start: Vector2 = Vector2.ZERO
var _gesture_last: Vector2 = Vector2.ZERO
var _gesture_is_drag: bool = false


func _ready() -> void:
	name = "DawnScreen"
	GameManager.ensure_dawn_runtime_state()
	_build_world()
	_build_fixed_ui()
	if not GameManager.state_changed.is_connected(
		_on_game_state_changed
	):
		GameManager.state_changed.connect(_on_game_state_changed)
	_refresh_ui()


func _exit_tree() -> void:
	if _player != null:
		_player.clear_path()
	_active_pointer_id = NO_POINTER_ID


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			_begin_pointer(touch_event.index, touch_event.position)
		else:
			_end_pointer(touch_event.index, touch_event.position)
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event
		_move_pointer(drag_event.index, drag_event.position)
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		var mouse_button: InputEventMouseButton = event
		if mouse_button.pressed:
			_begin_pointer(
				MOUSE_POINTER_ID,
				mouse_button.position
			)
		else:
			_end_pointer(
				MOUSE_POINTER_ID,
				mouse_button.position
			)
	elif event is InputEventMouseMotion:
		var mouse_motion: InputEventMouseMotion = event
		_move_pointer(MOUSE_POINTER_ID, mouse_motion.position)


func get_player() -> DayPlayer:
	return _player


func get_rice_purchase_pad() -> DawnPurchasePad:
	return _rice_purchase_pad


func get_mackerel_purchase_pad() -> DawnPurchasePad:
	return _mackerel_purchase_pad


func get_refund_button() -> Button:
	return _refund_button


func request_player_move(screen_position: Vector2) -> bool:
	if not _is_play_position(screen_position):
		return false
	var destination: Vector2 = Vector2(
		clampf(
			screen_position.x,
			DayPlayer.COLLISION_RADIUS,
			VIEWPORT_SIZE.x - DayPlayer.COLLISION_RADIUS
		),
		clampf(
			screen_position.y,
			HUD_HEIGHT + DayPlayer.COLLISION_RADIUS,
			ACTION_PANEL_TOP - DayPlayer.COLLISION_RADIUS
		)
	)
	return _player.follow_path(
		PackedVector2Array([destination])
	)


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	var background: Polygon2D = Polygon2D.new()
	background.name = "Background"
	background.color = BACKGROUND_COLOR
	background.polygon = PackedVector2Array([
		Vector2(0.0, HUD_HEIGHT),
		Vector2(VIEWPORT_SIZE.x, HUD_HEIGHT),
		Vector2(VIEWPORT_SIZE.x, ACTION_PANEL_TOP),
		Vector2(0.0, ACTION_PANEL_TOP),
	])
	background.z_index = -10
	_world.add_child(background)

	var market_floor: Polygon2D = Polygon2D.new()
	market_floor.name = "MarketFloor"
	market_floor.color = FLOOR_COLOR
	market_floor.polygon = PackedVector2Array([
		Vector2(40.0, 180.0),
		Vector2(680.0, 180.0),
		Vector2(680.0, 940.0),
		Vector2(40.0, 940.0),
	])
	market_floor.z_index = -9
	_world.add_child(market_floor)

	_rice_purchase_pad = DawnPurchasePadScript.new()
	_rice_purchase_pad.name = "RicePurchasePad"
	_rice_purchase_pad.configure("rice")
	_rice_purchase_pad.position = Vector2(210.0, 480.0)
	_world.add_child(_rice_purchase_pad)

	_mackerel_purchase_pad = DawnPurchasePadScript.new()
	_mackerel_purchase_pad.name = "MackerelPurchasePad"
	_mackerel_purchase_pad.configure("mackerel")
	_mackerel_purchase_pad.position = Vector2(510.0, 480.0)
	_world.add_child(_mackerel_purchase_pad)

	_player = DayPlayerScript.new()
	_player.position = PLAYER_START_POSITION
	_world.add_child(_player)

	_interaction_controller = (
		DayInteractionControllerScript.new()
	)
	_interaction_controller.name = "InteractionController"
	_interaction_controller.configure(_player)
	_interaction_controller.register_interactable(
		_rice_purchase_pad
	)
	_interaction_controller.register_interactable(
		_mackerel_purchase_pad
	)
	_world.add_child(_interaction_controller)


func _build_fixed_ui() -> void:
	var fixed_ui: CanvasLayer = CanvasLayer.new()
	fixed_ui.name = "FixedUI"
	add_child(fixed_ui)

	var hud: ColorRect = ColorRect.new()
	hud.name = "HUD"
	hud.position = Vector2.ZERO
	hud.size = Vector2(VIEWPORT_SIZE.x, HUD_HEIGHT)
	hud.color = HUD_COLOR
	hud.mouse_filter = Control.MOUSE_FILTER_STOP
	fixed_ui.add_child(hud)

	var title_label: Label = _add_label(
		hud,
		"TitleLabel",
		"Day %d 새벽 시장" % (
			int(GameManager.state.get("day", 1)) + 1
		),
		Rect2(24.0, 14.0, 360.0, 42.0),
		26,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	_currency_label = _add_label(
		hud,
		"CurrencyLabel",
		"",
		Rect2(480.0, 14.0, 216.0, 42.0),
		26,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	_currency_label.add_theme_color_override("font_color", TEXT_COLOR)
	_purchase_label = _add_label(
		hud,
		"PurchaseLabel",
		"",
		Rect2(24.0, 61.0, 672.0, 36.0),
		20,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_purchase_label.add_theme_color_override("font_color", TEXT_COLOR)

	var action_panel: ColorRect = ColorRect.new()
	action_panel.name = "ActionPanel"
	action_panel.position = Vector2(0.0, ACTION_PANEL_TOP)
	action_panel.size = Vector2(
		VIEWPORT_SIZE.x,
		VIEWPORT_SIZE.y - ACTION_PANEL_TOP
	)
	action_panel.color = HUD_COLOR
	action_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	fixed_ui.add_child(action_panel)

	_status_label = _add_label(
		action_panel,
		"StatusLabel",
		"구매 패드에 머물면 1초마다 한 묶음을 삽니다.",
		Rect2(30.0, 20.0, 660.0, 58.0),
		20,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_status_label.add_theme_color_override("font_color", TEXT_COLOR)

	_refund_button = Button.new()
	_refund_button.name = "RefundButton"
	_refund_button.position = Vector2(42.0, 104.0)
	_refund_button.size = Vector2(290.0, 82.0)
	_refund_button.text = "구매 전액 되돌리기"
	_refund_button.add_theme_font_size_override("font_size", 21)
	_refund_button.pressed.connect(_on_refund_pressed)
	action_panel.add_child(_refund_button)

	var prepare_button: Button = Button.new()
	prepare_button.name = "PrepareButton"
	prepare_button.position = Vector2(388.0, 104.0)
	prepare_button.size = Vector2(290.0, 82.0)
	prepare_button.text = "준비 단계 구현 중"
	prepare_button.disabled = true
	prepare_button.add_theme_font_size_override("font_size", 21)
	action_panel.add_child(prepare_button)


func _add_label(
	parent: Control,
	label_name: String,
	label_text: String,
	label_rect: Rect2,
	font_size: int,
	alignment: HorizontalAlignment
) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.position = label_rect.position
	label.size = label_rect.size
	label.text = label_text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _begin_pointer(pointer_id: int, position: Vector2) -> void:
	if _active_pointer_id != NO_POINTER_ID:
		return
	if not _is_play_position(position):
		return
	_active_pointer_id = pointer_id
	_gesture_start = position
	_gesture_last = position
	_gesture_is_drag = false


func _move_pointer(pointer_id: int, position: Vector2) -> void:
	if pointer_id != _active_pointer_id:
		return
	_gesture_last = position
	if _gesture_start.distance_to(position) >= DRAG_THRESHOLD:
		_gesture_is_drag = true


func _end_pointer(pointer_id: int, position: Vector2) -> void:
	if pointer_id != _active_pointer_id:
		return
	_move_pointer(pointer_id, position)
	var should_move: bool = (
		not _gesture_is_drag
		and _is_play_position(position)
	)
	_active_pointer_id = NO_POINTER_ID
	_gesture_is_drag = false
	if should_move:
		request_player_move(position)


func _is_play_position(position: Vector2) -> bool:
	return (
		position.x >= 0.0
		and position.x <= VIEWPORT_SIZE.x
		and position.y >= HUD_HEIGHT
		and position.y < ACTION_PANEL_TOP
	)


func _on_game_state_changed() -> void:
	_refresh_ui()


func _on_refund_pressed() -> void:
	if GameManager.refund_market_purchases():
		_status_label.text = "이번 시장 구매를 모두 되돌렸습니다."
	else:
		_status_label.text = "되돌릴 구매가 없습니다."
	_refresh_ui(false)


func _refresh_ui(reset_status: bool = true) -> void:
	if _currency_label == null:
		return
	var purchases: Dictionary = GameManager.get_market_purchases()
	_currency_label.text = "%d문" % int(
		GameManager.state.get("currency", 0)
	)
	_purchase_label.text = "구매: 쌀 %d · 고등어 %d" % [
		int(purchases.get("rice", 0)),
		int(purchases.get("mackerel", 0)),
	]
	var total_purchased: int = (
		int(purchases.get("rice", 0))
		+ int(purchases.get("mackerel", 0))
	)
	_refund_button.disabled = total_purchased <= 0
	if reset_status:
		_status_label.text = (
			"구매 패드에 머물면 1초마다 한 묶음을 삽니다."
		)
