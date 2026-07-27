extends Control
class_name LoadingScreen

signal screen_change_requested

const BACKGROUND_COLOR: Color = Color("f4ead7")
const TEXT_COLOR: Color = Color("35291f")

var save_path: String = SaveManager.SAVE_PATH
var _status_label: Label
var _new_game_button: Button
var _invalid_save_detected: bool = false
var _is_loading: bool = false


func _ready() -> void:
	name = "LoadingScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	call_deferred("_load_game_state")


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.color = BACKGROUND_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.custom_minimum_size = Vector2(480.0, 160.0)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(content)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "데이터를 불러오는 중..."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", TEXT_COLOR)
	_status_label.add_theme_font_size_override("font_size", 28)
	content.add_child(_status_label)

	_new_game_button = Button.new()
	_new_game_button.name = "NewGameButton"
	_new_game_button.text = "새 게임"
	_new_game_button.custom_minimum_size = Vector2(240.0, 64.0)
	_new_game_button.visible = false
	_new_game_button.pressed.connect(_on_new_game_pressed)
	content.add_child(_new_game_button)


func _load_game_state() -> void:
	if _is_loading:
		return
	_is_loading = true

	var load_result: Dictionary = SaveManager.load_game_state(save_path)
	var load_status: int = int(
		load_result.get("status", SaveManager.LoadStatus.IO_ERROR)
	)
	match load_status:
		SaveManager.LoadStatus.OK:
			var loaded_state: Dictionary = load_result.get("state", {})
			if not GameManager.apply_loaded_game_state(loaded_state):
				_show_recovery(
					"저장 데이터 형식이 올바르지 않습니다."
				)
				return
			_finish_loading()
		SaveManager.LoadStatus.NOT_FOUND:
			_create_and_save_new_game(false)
		SaveManager.LoadStatus.INVALID_JSON:
			_show_recovery("저장 JSON이 손상되었습니다.")
		SaveManager.LoadStatus.INVALID_DATA:
			_show_recovery("저장 데이터 형식이 올바르지 않습니다.")
		_:
			_show_io_error(
				String(
					load_result.get(
						"message",
						"저장 데이터를 읽을 수 없습니다."
					)
				)
			)


func _on_new_game_pressed() -> void:
	if _is_loading:
		return
	_is_loading = true
	_new_game_button.disabled = true
	_create_and_save_new_game(_invalid_save_detected)


func _create_and_save_new_game(backup_existing: bool) -> void:
	if backup_existing and FileAccess.file_exists(save_path):
		var backup_error: Error = SaveManager.backup_invalid_save(save_path)
		if backup_error != OK:
			_show_io_error("손상된 저장 파일을 백업할 수 없습니다.")
			return

	var default_state: Dictionary = GameManager.create_default_game_state()
	if not GameManager.apply_loaded_game_state(default_state):
		_show_io_error("새 게임 상태를 만들 수 없습니다.")
		return

	var save_error: Error = SaveManager.save_game_state(
		GameManager.state,
		save_path
	)
	if save_error != OK:
		_show_io_error("새 게임 데이터를 저장할 수 없습니다.")
		return

	_finish_loading()


func _finish_loading() -> void:
	_is_loading = false
	_status_label.text = "데이터 준비 완료"
	_new_game_button.visible = false
	screen_change_requested.emit()


func _show_recovery(message: String) -> void:
	_is_loading = false
	_invalid_save_detected = true
	_status_label.text = message
	_new_game_button.disabled = false
	_new_game_button.visible = true


func _show_io_error(message: String) -> void:
	_is_loading = false
	_status_label.text = message
	_new_game_button.visible = false
