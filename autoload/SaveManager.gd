extends Node

# Persists player list + audio prefs to user://save.cfg.
# Register as autoload BEFORE AudioManager.

const SAVE_PATH := "user://save.cfg"

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(SAVE_PATH)  # silently no-ops if missing


func _save() -> void:
	_config.save(SAVE_PATH)


# --- Players ---

func get_players() -> Array[String]:
	var raw: Variant = _config.get_value("players", "list", [])
	var out: Array[String] = []
	if raw is Array:
		for p in raw:
			out.append(str(p))
	return out


func set_players(players: Array[String]) -> void:
	_config.set_value("players", "list", players)
	_save()


# --- Audio ---

func get_audio(key: String, default_value: bool) -> bool:
	return bool(_config.get_value("audio", key, default_value))


# --- CSV display paths (for showing the user what they uploaded) ---

func get_cards_display_path() -> String:
	return str(_config.get_value("csv", "cards_display", ""))


func set_cards_display_path(path: String) -> void:
	_config.set_value("csv", "cards_display", path)
	_save()


func clear_cards_display_path() -> void:
	_config.set_value("csv", "cards_display", "")
	_save()


func get_pass_display_path() -> String:
	return str(_config.get_value("csv", "penalty_display", ""))


func set_pass_display_path(path: String) -> void:
	_config.set_value("csv", "penalty_display", path)
	_save()


func clear_pass_display_path() -> void:
	_config.set_value("csv", "penalty_display", "")
	_save()


# --- Gameplay ---

func get_endless_mode() -> bool:
	return bool(_config.get_value("gameplay", "endless", false))


func set_endless_mode(value: bool) -> void:
	_config.set_value("gameplay", "endless", value)
	_save()


func set_audio(key: String, value: bool) -> void:
	_config.set_value("audio", key, value)
	_save()
