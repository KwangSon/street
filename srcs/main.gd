extends Node2D

const LoadingScreenScript: Script = preload(
	"res://srcs/screens/loading_screen.gd"
)

const VIEWPORT_SIZE: Vector2 = Vector2(720.0, 1280.0)
const DEFAULT_AUTOSAVE_INTERVAL_SECONDS: float = 30.0
const SCREEN_LOADING: String = "loading"
const SCREEN_DAY: String = "day"
const SCREEN_DAWN: String = "dawn"

const FUTURE_SCREEN_PATHS: Dictionary = {
	SCREEN_DAY: "res://srcs/screens/day_screen.gd",
	SCREEN_DAWN: "res://srcs/screens/dawn_screen.gd",
}

var loading_save_path: String = SaveManager.SAVE_PATH
var autosave_interval_seconds: float = (
	DEFAULT_AUTOSAVE_INTERVAL_SECONDS
)
var _current_screen: Node
var _current_screen_id: String = SCREEN_LOADING
var _is_transitioning: bool = false
var _screen_factories: Dictionary = {}
var _autosave_timer: Timer
var _game_menu_layer: CanvasLayer
var _game_menu_root: Control
var _menu_button: Button
var _menu_backdrop: ColorRect
var _menu_content: Control
var _confirmation_content: Control
var _save_status_label: Label
var _confirmation_status_label: Label
var _menu_open: bool = false
var _last_checkpoint_key: String = ""


func _ready() -> void:
	_build_game_menu()
	_build_autosave_timer()
	if not GameManager.state_changed.is_connected(
		_on_game_state_changed
	):
		GameManager.state_changed.connect(_on_game_state_changed)
	var loading_screen: Node = _create_loading_screen()
	_replace_screen(loading_screen, SCREEN_LOADING)


func _exit_tree() -> void:
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false


func get_current_screen() -> Node:
	return _current_screen


func get_menu_button() -> Button:
	return _menu_button


func get_menu_backdrop() -> ColorRect:
	return _menu_backdrop


func get_new_game_confirmation() -> Control:
	return _confirmation_content


func get_autosave_timer() -> Timer:
	return _autosave_timer


func get_save_status_label() -> Label:
	return _save_status_label


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

	_save_now()
	_replace_screen(next_screen, String(target_screen))
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


func _replace_screen(
	next_screen: Node,
	screen_id: String = ""
) -> bool:
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
	_current_screen_id = screen_id
	add_child(_current_screen)
	_refresh_menu_availability()
	if _is_day_screen():
		_save_now()
	return true


func _build_autosave_timer() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.name = "AutosaveTimer"
	_autosave_timer.wait_time = maxf(
		autosave_interval_seconds,
		0.05
	)
	_autosave_timer.one_shot = false
	_autosave_timer.autostart = false
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _build_game_menu() -> void:
	_game_menu_layer = CanvasLayer.new()
	_game_menu_layer.name = "GameMenu"
	_game_menu_layer.layer = 100
	_game_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_game_menu_layer)

	_game_menu_root = Control.new()
	_game_menu_root.name = "Root"
	_game_menu_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	_game_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_menu_layer.add_child(_game_menu_root)

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.position = Vector2(16.0, 16.0)
	_menu_button.size = Vector2(112.0, 54.0)
	_menu_button.text = "메뉴"
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.add_theme_font_size_override("font_size", 20)
	_menu_button.pressed.connect(_on_menu_button_pressed)
	_game_menu_root.add_child(_menu_button)

	_menu_backdrop = ColorRect.new()
	_menu_backdrop.name = "Backdrop"
	_menu_backdrop.position = Vector2.ZERO
	_menu_backdrop.size = VIEWPORT_SIZE
	_menu_backdrop.color = Color(0.08, 0.07, 0.06, 0.82)
	_menu_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_backdrop.visible = false
	_game_menu_root.add_child(_menu_backdrop)

	var panel: ColorRect = ColorRect.new()
	panel.name = "Panel"
	panel.position = Vector2(72.0, 220.0)
	panel.size = Vector2(576.0, 760.0)
	panel.color = Color("f4ead7")
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_backdrop.add_child(panel)

	_menu_content = Control.new()
	_menu_content.name = "MenuContent"
	_menu_content.position = Vector2.ZERO
	_menu_content.size = panel.size
	panel.add_child(_menu_content)

	var title: Label = _create_menu_label(
		"TitleLabel",
		"게임 메뉴",
		Rect2(48.0, 54.0, 480.0, 70.0),
		36
	)
	_menu_content.add_child(title)

	var pause_message: Label = _create_menu_label(
		"PauseMessage",
		"메뉴를 보는 동안 게임이 일시정지됩니다.",
		Rect2(48.0, 146.0, 480.0, 52.0),
		21
	)
	_menu_content.add_child(pause_message)

	_save_status_label = _create_menu_label(
		"SaveStatusLabel",
		"자동 저장: %d초마다 · 저장 슬롯 %d개" % [
			int(roundf(autosave_interval_seconds)),
			SaveManager.SAVE_SLOT_COUNT,
		],
		Rect2(48.0, 210.0, 480.0, 64.0),
		20
	)
	_menu_content.add_child(_save_status_label)

	var continue_button: Button = _create_menu_button(
		"ContinueButton",
		"계속하기",
		Vector2(88.0, 336.0)
	)
	continue_button.pressed.connect(_on_continue_pressed)
	_menu_content.add_child(continue_button)

	var new_game_button: Button = _create_menu_button(
		"NewGameButton",
		"새 게임",
		Vector2(88.0, 458.0)
	)
	new_game_button.pressed.connect(_on_new_game_pressed)
	_menu_content.add_child(new_game_button)

	_confirmation_content = Control.new()
	_confirmation_content.name = "NewGameConfirmation"
	_confirmation_content.position = Vector2.ZERO
	_confirmation_content.size = panel.size
	_confirmation_content.visible = false
	panel.add_child(_confirmation_content)

	var confirmation_title: Label = _create_menu_label(
		"TitleLabel",
		"새 게임을 시작할까요?",
		Rect2(48.0, 74.0, 480.0, 70.0),
		32
	)
	_confirmation_content.add_child(confirmation_title)

	var confirmation_message: Label = _create_menu_label(
		"MessageLabel",
		(
			"저장 슬롯은 하나입니다.\n"
			+ "현재 진행 상황을 지우고 Day 1부터 시작합니다."
		),
		Rect2(62.0, 184.0, 452.0, 130.0),
		22
	)
	confirmation_message.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	_confirmation_content.add_child(confirmation_message)

	_confirmation_status_label = _create_menu_label(
		"StatusLabel",
		"",
		Rect2(62.0, 318.0, 452.0, 56.0),
		18
	)
	_confirmation_content.add_child(_confirmation_status_label)

	var confirm_button: Button = _create_menu_button(
		"ConfirmButton",
		"새 게임 시작",
		Vector2(88.0, 420.0)
	)
	confirm_button.pressed.connect(
		_on_confirm_new_game_pressed
	)
	_confirmation_content.add_child(confirm_button)

	var cancel_button: Button = _create_menu_button(
		"CancelButton",
		"취소",
		Vector2(88.0, 542.0)
	)
	cancel_button.pressed.connect(
		_on_cancel_new_game_pressed
	)
	_confirmation_content.add_child(cancel_button)


func _create_menu_label(
	label_name: String,
	label_text: String,
	label_rect: Rect2,
	font_size: int
) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.position = label_rect.position
	label.size = label_rect.size
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override(
		"font_color",
		Color("35291f")
	)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _create_menu_button(
	button_name: String,
	button_text: String,
	button_position: Vector2
) -> Button:
	var button: Button = Button.new()
	button.name = button_name
	button.position = button_position
	button.size = Vector2(400.0, 88.0)
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 25)
	return button


func _on_menu_button_pressed() -> void:
	if (
		_menu_open
		or _current_screen == null
		or _current_screen is LoadingScreen
	):
		return
	_menu_open = true
	_set_new_game_confirmation_visible(false)
	_menu_backdrop.visible = true
	_menu_button.visible = false
	get_tree().paused = true
	_save_now()


func _on_continue_pressed() -> void:
	_close_game_menu()


func _on_new_game_pressed() -> void:
	_set_new_game_confirmation_visible(true)


func _on_cancel_new_game_pressed() -> void:
	_set_new_game_confirmation_visible(false)


func _on_confirm_new_game_pressed() -> void:
	var default_state: Dictionary = (
		GameManager.create_default_game_state()
	)
	if not GameManager.apply_loaded_game_state(default_state):
		_confirmation_status_label.text = (
			"새 게임 상태를 만들 수 없습니다."
		)
		return

	var save_error: Error = SaveManager.save_game_state(
		GameManager.state,
		loading_save_path
	)
	if save_error != OK:
		_confirmation_status_label.text = (
			"새 게임을 저장할 수 없습니다."
		)
		return

	_last_checkpoint_key = _get_checkpoint_key()
	_on_screen_change_requested()
	_close_game_menu()


func _close_game_menu() -> void:
	_menu_open = false
	_set_new_game_confirmation_visible(false)
	_menu_backdrop.visible = false
	_menu_button.visible = _is_day_screen()
	if get_tree() != null:
		get_tree().paused = false


func _set_new_game_confirmation_visible(
	confirmation_visible: bool
) -> void:
	_menu_content.visible = not confirmation_visible
	_confirmation_content.visible = confirmation_visible
	_confirmation_status_label.text = ""


func _on_autosave_timeout() -> void:
	_save_now()


func _on_game_state_changed() -> void:
	if not _is_day_screen():
		return
	var checkpoint_key: String = _get_checkpoint_key()
	if checkpoint_key == _last_checkpoint_key:
		return
	_last_checkpoint_key = checkpoint_key
	_save_now()


func _save_now() -> Error:
	if (
		not _is_day_screen()
		or GameManager.state.is_empty()
	):
		return ERR_UNAVAILABLE
	var save_error: Error = SaveManager.save_game_state(
		GameManager.state,
		loading_save_path
	)
	if _save_status_label != null:
		_save_status_label.text = (
			"자동 저장 완료 · %d초마다 · 저장 슬롯 %d개" % [
				int(roundf(autosave_interval_seconds)),
				SaveManager.SAVE_SLOT_COUNT,
			]
			if save_error == OK
			else "자동 저장에 실패했습니다."
		)
	return save_error


func _refresh_menu_availability() -> void:
	var day_screen: bool = _is_day_screen()
	_game_menu_root.visible = day_screen
	if not day_screen:
		_menu_open = false
		_menu_backdrop.visible = false
		_menu_button.visible = false
		if _autosave_timer != null:
			_autosave_timer.stop()
		return

	_menu_button.visible = not _menu_open
	_last_checkpoint_key = _get_checkpoint_key()
	if _autosave_timer != null:
		_autosave_timer.wait_time = maxf(
			autosave_interval_seconds,
			0.05
		)
		_autosave_timer.start()


func _is_day_screen() -> bool:
	return (
		_current_screen != null
		and not _current_screen is LoadingScreen
		and _current_screen_id == SCREEN_DAY
		and String(GameManager.state.get("screen", ""))
		== SCREEN_DAY
	)


func _get_checkpoint_key() -> String:
	return "%s:%s:%d" % [
		String(GameManager.state.get("screen", "")),
		String(GameManager.state.get("phase", "")),
		int(GameManager.state.get("day", 0)),
	]
