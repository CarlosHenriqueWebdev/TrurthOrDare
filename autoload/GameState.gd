## Runtime state for a game session.
##
## Tracks the player list, current turn, round counter, and the currently
## rolled prompt. Owns the chance model: per-player truth/dare balance and
## per-round category escalation. Fires state_changed when anything moves.
extends Node

signal state_changed

const BASE_CATEGORY_WEIGHTS := {
	"sober": 0.4,
	"tipsy": 0.3,
	"drunk": 0.2,
	"wasted": 0.1,
}

const CATEGORY_ESCALATION := {
	"sober": -0.01,
	"tipsy": 0.0,
	"drunk": 0.005,
	"wasted": 0.005,
}

const CATEGORY_MIN_WEIGHT := 0.05
const CATEGORY_MAX_WEIGHT := 0.5

const TYPE_BALANCE_FACTOR := 0.05
const TYPE_CHANCE_MIN := 0.2
const TYPE_CHANCE_MAX := 0.8

var players: Array[String] = []
var current_index: int = 0
var cards_played: int = 0
var game_over: bool = false

var current_type: String = "truth"
var current_category: String = "sober"
var current_text: String = ""
var current_long_text: String = ""

var _player_stats: Dictionary = {}
var _used_truth_ids: Dictionary = {}
var _used_dare_ids: Dictionary = {}


func start_game(player_names: Array[String]) -> void:
	players = player_names.duplicate()
	current_index = 0
	cards_played = 0
	game_over = false
	_player_stats.clear()
	_used_truth_ids.clear()
	_used_dare_ids.clear()
	for p in players:
		_player_stats[p] = {"truths": 0, "dares": 0}
	_roll_prompt()
	state_changed.emit()


func restart() -> void:
	start_game(players)


func current_player() -> String:
	if players.is_empty():
		return ""
	return players[current_index]


func advance() -> void:
	if players.is_empty():
		return
	if game_over:
		return
	cards_played += 1
	# If the next roll would end the game, keep the current player's turn
	# so the game-over screen doesn't show a different name.
	if is_game_complete():
		game_over = true
		current_text = ""
		current_long_text = ""
		state_changed.emit()
		return
	current_index += 1
	if current_index >= players.size():
		current_index = 0
	_roll_prompt()
	state_changed.emit()


func stats_for(player_name: String) -> Dictionary:
	return _player_stats.get(player_name, {"truths": 0, "dares": 0})


func truth_chance_for_current() -> float:
	return 1.0 - dare_chance_for_current()


func dare_chance_for_current() -> float:
	if players.is_empty():
		return 0.5
	var s: Dictionary = _player_stats.get(current_player(), {"truths": 0, "dares": 0})
	var imbalance: int = s["truths"] - s["dares"]
	return clampf(0.5 + imbalance * TYPE_BALANCE_FACTOR, TYPE_CHANCE_MIN, TYPE_CHANCE_MAX)


func category_weights() -> Dictionary:
	var r := _effective_round()
	var out := {}
	for cat in BASE_CATEGORY_WEIGHTS.keys():
		var w: float = BASE_CATEGORY_WEIGHTS[cat] + CATEGORY_ESCALATION.get(cat, 0.0) * r
		out[cat] = clampf(w, CATEGORY_MIN_WEIGHT, CATEGORY_MAX_WEIGHT)
	return out


func category_percentages() -> Dictionary:
	var weights := category_weights()
	var total := 0.0
	for w in weights.values():
		total += w
	if total <= 0.0:
		return {"sober": 25, "tipsy": 25, "drunk": 25, "wasted": 25}
	var out := {}
	for cat in weights.keys():
		out[cat] = int(round(weights[cat] / total * 100.0))
	return out


func is_endless() -> bool:
	return SaveManager.get_endless_mode()


func is_game_complete() -> bool:
	if is_endless():
		return false
	var t_total := DataManager.truths.size()
	var d_total := DataManager.dares.size()
	if t_total + d_total == 0:
		return true
	return _used_truth_ids.size() >= t_total and _used_dare_ids.size() >= d_total


func cards_remaining() -> int:
	if is_endless():
		return -1  # -1 signals "unlimited" to the UI
	return (DataManager.truths.size() - _used_truth_ids.size()) \
		+ (DataManager.dares.size() - _used_dare_ids.size())


func _effective_round() -> int:
	if players.is_empty():
		return 1
	# Integer division is intentional — we want the whole-round count.
	@warning_ignore("integer_division")
	var r := cards_played / players.size()
	return 1 + r


func _has_unused(kind: String) -> bool:
	if is_endless():
		return DataManager.get_prompts_by_type(kind).size() > 0
	var pool := DataManager.get_prompts_by_type(kind)
	var used := _used_ids_for(kind)
	return used.size() < pool.size()


func _used_ids_for(kind: String) -> Dictionary:
	return _used_truth_ids if kind == "truth" else _used_dare_ids


func _pick_prompt(kind: String, category: String) -> Dictionary:
	var pool := DataManager.get_prompts_by_type(kind)
	var used := _used_ids_for(kind)
	var endless := is_endless()

	# Preferred: matching category (unused in normal mode, any in endless)
	var candidates: Array[int] = []
	for i in pool.size():
		if not endless and used.has(i):
			continue
		if pool[i].get("category", "") == category:
			candidates.append(i)

	# Fallback: any card (unused in normal mode)
	if candidates.is_empty():
		for i in pool.size():
			if not endless and used.has(i):
				continue
			candidates.append(i)

	if candidates.is_empty():
		return {}

	var idx: int = candidates[randi() % candidates.size()]
	if not endless:
		used[idx] = true
	return pool[idx]


func _roll_prompt() -> void:
	var player := current_player()
	if player.is_empty():
		return

	if is_game_complete():
		game_over = true
		current_text = ""
		current_long_text = ""
		return

	current_type = _roll_type(player)
	current_category = _roll_category()

	var entry := _pick_prompt(current_type, current_category)
	if entry.is_empty():
		var other := "dare" if current_type == "truth" else "truth"
		entry = _pick_prompt(other, current_category)
		if not entry.is_empty():
			current_type = other

	if entry.is_empty():
		game_over = true
		current_text = ""
		current_long_text = ""
		return

	current_text = entry.get("text", "")
	current_long_text = entry.get("long_text", "")

	var s: Dictionary = _player_stats[player]
	if current_type == "truth":
		s["truths"] += 1
	else:
		s["dares"] += 1


func _roll_type(player: String) -> String:
	var t_avail := _has_unused("truth")
	var d_avail := _has_unused("dare")
	if not t_avail and not d_avail:
		return "truth"
	if not t_avail:
		return "dare"
	if not d_avail:
		return "truth"

	var s: Dictionary = _player_stats.get(player, {"truths": 0, "dares": 0})
	var imbalance: int = s["truths"] - s["dares"]
	var dare_chance: float = clampf(0.5 + imbalance * TYPE_BALANCE_FACTOR, TYPE_CHANCE_MIN, TYPE_CHANCE_MAX)
	return "dare" if randf() < dare_chance else "truth"


func _roll_category() -> String:
	var weights := category_weights()
	var total := 0.0
	for w in weights.values():
		total += w
	if total <= 0.0:
		return "sober"
	var r := randf() * total
	var acc := 0.0
	for cat in weights.keys():
		acc += weights[cat]
		if r <= acc:
			return cat
	return "sober"
