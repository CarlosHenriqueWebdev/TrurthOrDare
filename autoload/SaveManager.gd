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


func set_audio(key: String, value: bool) -> void:
	_config.set_value("audio", key, value)
	_save()
