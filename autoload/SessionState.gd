## Persistent mid-game snapshot.
##
## Written by GameState after every successful turn. Read by Game on
## startup so the user can resume a match exactly where they left off,
## even after the app is force-closed. Cleared by:
##   - GameState when a match ends (game_over)
##   - PlayerSetup when the user presses START GAME (explicit new match)
##
## Schema version is checked on load — if it doesn't match, the stale
## session is dropped rather than risking a bad resume after a code
## change that alters the snapshot shape.
extends Node

const SESSION_PATH := "user://session.cfg"
const SCHEMA_VERSION := 1

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(SESSION_PATH)  # silently no-ops if missing


func has_session() -> bool:
	return _config.has_section_key("session", "schema_version")


func save(data: Dictionary) -> void:
	_config.clear()
	_config.set_value("session", "schema_version", SCHEMA_VERSION)
	for key in data.keys():
		_config.set_value("session", key, data[key])
	_config.save(SESSION_PATH)


func load_data() -> Dictionary:
	var out: Dictionary = {}
	if not has_session():
		return out
	var stored_version := int(_config.get_value("session", "schema_version", 0))
	if stored_version != SCHEMA_VERSION:
		# Snapshot shape changed between builds — drop rather than guess.
		clear()
		return {}
	for key in _config.get_section_keys("session"):
		if key == "schema_version":
			continue
		out[key] = _config.get_value("session", key)
	return out


func clear() -> void:
	_config.clear()
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
