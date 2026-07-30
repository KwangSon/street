extends Node

enum LoadStatus {
	OK,
	NOT_FOUND,
	INVALID_JSON,
	INVALID_DATA,
	IO_ERROR,
}

const SAVE_PATH: String = "user://save.json"
const SAVE_SLOT_COUNT: int = 1
const TEMP_SUFFIX: String = ".tmp"
const CORRUPT_SUFFIX: String = ".corrupt"


func load_game_state(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _load_result(
			LoadStatus.NOT_FOUND,
			{},
			"Save file does not exist."
		)

	var save_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if save_file == null:
		return _load_result(
			LoadStatus.IO_ERROR,
			{},
			"Could not open the save file for reading."
		)

	var json_text: String = save_file.get_as_text()
	var read_error: Error = save_file.get_error()
	save_file.close()
	if read_error != OK:
		return _load_result(
			LoadStatus.IO_ERROR,
			{},
			"Could not read the save file."
		)

	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(json_text)
	if parse_error != OK:
		return _load_result(
			LoadStatus.INVALID_JSON,
			{},
			"Save JSON could not be parsed."
		)
	if typeof(json.data) != TYPE_DICTIONARY:
		return _load_result(
			LoadStatus.INVALID_DATA,
			{},
			"Save JSON root must be an object."
		)

	var loaded_state: Dictionary = json.data
	return _load_result(
		LoadStatus.OK,
		loaded_state.duplicate(true),
		""
	)


func save_game_state(
		state: Dictionary,
		path: String = SAVE_PATH
) -> Error:
	if not _is_json_compatible(state):
		return ERR_INVALID_DATA

	var temporary_path: String = path + TEMP_SUFFIX
	var temporary_file: FileAccess = FileAccess.open(
		temporary_path,
		FileAccess.WRITE
	)
	if temporary_file == null:
		return FileAccess.get_open_error()

	temporary_file.store_string(JSON.stringify(state, "\t"))
	var write_error: Error = temporary_file.get_error()
	temporary_file.close()
	if write_error != OK:
		_remove_file_if_present(temporary_path)
		return write_error

	var temporary_absolute_path: String = ProjectSettings.globalize_path(
		temporary_path
	)
	var save_absolute_path: String = ProjectSettings.globalize_path(path)
	var rename_error: Error = DirAccess.rename_absolute(
		temporary_absolute_path,
		save_absolute_path
	)
	if rename_error == ERR_ALREADY_EXISTS:
		var remove_error: Error = DirAccess.remove_absolute(save_absolute_path)
		if remove_error != OK:
			_remove_file_if_present(temporary_path)
			return remove_error
		rename_error = DirAccess.rename_absolute(
			temporary_absolute_path,
			save_absolute_path
		)
	if rename_error != OK:
		_remove_file_if_present(temporary_path)
	return rename_error


func backup_invalid_save(path: String = SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND

	var backup_path: String = path + CORRUPT_SUFFIX
	var remove_error: Error = _remove_file_if_present(backup_path)
	if remove_error != OK:
		return remove_error

	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(backup_path)
	)


func _load_result(
		status: LoadStatus,
		state: Dictionary,
		message: String
) -> Dictionary:
	return {
		"status": status,
		"state": state,
		"message": message,
	}


func _is_json_compatible(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(float(value))
		TYPE_ARRAY:
			for item: Variant in value:
				if not _is_json_compatible(item):
					return false
			return true
		TYPE_DICTIONARY:
			var dictionary_value: Dictionary = value
			for key: Variant in dictionary_value:
				if typeof(key) != TYPE_STRING:
					return false
				if not _is_json_compatible(dictionary_value[key]):
					return false
			return true
		_:
			return false


func _remove_file_if_present(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
