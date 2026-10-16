## Persistence layer.
##
## Reads and writes user://save.cfg for player names, audio toggles,
## gameplay flags, and the display paths of uploaded CSVs. Register as
## an autoload before AudioManager so audio prefs load first.
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

# Game mode is one of "default", "limited", "endless".
#   default — play until the deck runs out (current behaviour)
#   limited — play until Match Max Turns is hit (placeholder for now)
#   endless — deck recycles, no natural end
func get_game_mode() -> String:
	var m := str(_config.get_value("gameplay", "game_mode", "default"))
	return m if m in ["default", "limited", "endless"] else "default"


func set_game_mode(mode: String) -> void:
	if not mode in ["default", "limited", "endless"]:
		mode = "default"
	_config.set_value("gameplay", "game_mode", mode)
	_save()


# Backwards-compat wrapper — existing callers keep working.
func get_endless_mode() -> bool:
	return get_game_mode() == "endless"


func set_endless_mode(value: bool) -> void:
	set_game_mode("endless" if value else "default")


# Round cap for the "limited" game mode. One round = every player has
# taken one turn, so the effective turn cap is value * players.size().
# Default 5 keeps the first experience short.
func get_match_max_rounds() -> int:
	return int(_config.get_value("gameplay", "match_max_rounds", 5))


func set_match_max_rounds(value: int) -> void:
	_config.set_value("gameplay", "match_max_rounds", maxi(1, value))
	_save()


# Streak balance: on by default. Adds +10% to the opposite type per
# consecutive same-type draw so a player doesn't see three truths in a row.
func get_streak_balance() -> bool:
	return bool(_config.get_value("gameplay", "streak_balance", true))


func set_streak_balance(value: bool) -> void:
	_config.set_value("gameplay", "streak_balance", value)
	_save()


func set_audio(key: String, value: bool) -> void:
	_config.set_value("audio", key, value)
	_save()
