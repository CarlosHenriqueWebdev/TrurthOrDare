## Runtime state for a game session.
##
## Tracks the player list, current turn, round counter, and the currently
## rolled prompt. Owns the chance model: per-player truth/dare balance and
## per-round category escalation. Fires state_changed when anything moves.
extends Node

signal state_changed

# Category progression is now driven by OddsCalculator — a Gaussian curve
# sweeping four tiers from round 1 (mostly sober) to the final round
# (mostly drunk/wasted). This array maps the curve's level indices to
# the category names used throughout the rest of the code.
const LEVEL_CATEGORIES: Array[String] = ["sober", "tipsy", "drunk", "wasted"]

const TYPE_BALANCE_FACTOR := 0.05
const TYPE_CHANCE_MIN := 0.2
const TYPE_CHANCE_MAX := 0.8

# How far one "luck unit" pushes the curve position. A full +1.0 bonus
# (level-1 penalty, "−2 luck") shifts t by 0.15 — noticeable but not
# jarring. Stacked bonuses accumulate, clamped at the curve ends.
const PENALTY_LUCK_CURVE_OFFSET := 0.15

# Endless-mode progression window. After this many rounds the curve
# pins at its hardest tier. Arbitrary but short enough that a normal
# session sees the whole progression.
const ENDLESS_PROGRESSION_ROUNDS := 20

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
var _last_type_by_player: Dictionary = {}   # player -> "truth" | "dare"
var _same_type_streak: Dictionary = {}      # player -> consecutive count of same type
var _pending_escalation: Dictionary = {}    # player -> float bonus, consumed on next draw
var _last_rolled_weights: Dictionary = {}   # weights used for the currently displayed card
var _last_rolled_bonus: float = 0.0         # escalation bonus applied to the current card


# --- Session persistence ---

# Serialise the full runtime state into a plain Dictionary. Used by
# SessionState to persist a resumable snapshot after each turn.
# Note: _used_truth_ids / _used_dare_ids have integer keys, which don't
# round-trip cleanly through ConfigFile. They're stored as index arrays
# and rebuilt on restore.
func to_snapshot() -> Dictionary:
	var t_indices: Array = _used_truth_ids.keys()
	var d_indices: Array = _used_dare_ids.keys()
	return {
		"players": players.duplicate(),
		"current_index": current_index,
		"cards_played": cards_played,
		"game_over": game_over,
		"current_type": current_type,
		"current_category": current_category,
		"current_text": current_text,
		"current_long_text": current_long_text,
		"truths": DataManager.truths.duplicate(true),
		"dares": DataManager.dares.duplicate(true),
		"used_truth_indices": t_indices,
		"used_dare_indices": d_indices,
		"last_type_by_player": _last_type_by_player.duplicate(),
		"same_type_streak": _same_type_streak.duplicate(),
		"pending_escalation": _pending_escalation.duplicate(),
		"last_rolled_weights": _last_rolled_weights.duplicate(),
		"last_rolled_bonus": _last_rolled_bonus,
		"player_stats": _player_stats.duplicate(true),
	}


# Restore the runtime state from a snapshot Dictionary. The deck itself
# is overwritten so the resume uses the exact cards the match started
# with, even if the CSVs on disk have changed since.
func from_snapshot(data: Dictionary) -> void:
	players.assign(data.get("players", []))
	current_index = int(data.get("current_index", 0))
	cards_played = int(data.get("cards_played", 0))
	game_over = bool(data.get("game_over", false))
	current_type = str(data.get("current_type", "truth"))
	current_category = str(data.get("current_category", "sober"))
	current_text = str(data.get("current_text", ""))
	current_long_text = str(data.get("current_long_text", ""))

	DataManager.truths.assign(data.get("truths", []))
	DataManager.dares.assign(data.get("dares", []))

	_used_truth_ids.clear()
	for i in data.get("used_truth_indices", []):
		_used_truth_ids[int(i)] = true
	_used_dare_ids.clear()
	for i in data.get("used_dare_indices", []):
		_used_dare_ids[int(i)] = true

	_last_type_by_player = data.get("last_type_by_player", {})
	_same_type_streak = data.get("same_type_streak", {})
	_pending_escalation = data.get("pending_escalation", {})
	_last_rolled_weights = data.get("last_rolled_weights", {})
	_last_rolled_bonus = float(data.get("last_rolled_bonus", 0.0))
	_player_stats = data.get("player_stats", {})

	state_changed.emit()


# Called after each state change. Writes the snapshot — or clears it if
# the game just ended, so Home doesn't offer to Continue a dead match.
func _save_session() -> void:
	if game_over:
		SessionState.clear()
	else:
		SessionState.save(to_snapshot())


func start_game(player_names: Array[String]) -> void:
	players = player_names.duplicate()
	current_index = 0
	cards_played = 0
	game_over = false
	_player_stats.clear()
	_used_truth_ids.clear()
	_used_dare_ids.clear()
	_last_type_by_player.clear()
	_same_type_streak.clear()
	_pending_escalation.clear()
	_last_rolled_weights.clear()
	_last_rolled_bonus = 0.0
	for p in players:
		_player_stats[p] = {"truths": 0, "dares": 0}
	_roll_prompt()
	state_changed.emit()
	_save_session()


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
		_save_session()
		return
	current_index += 1
	if current_index >= players.size():
		current_index = 0
	_roll_prompt()
	state_changed.emit()
	_save_session()


func stats_for(player_name: String) -> Dictionary:
	return _player_stats.get(player_name, {"truths": 0, "dares": 0})


# Called by Game when the player confirms a penalty. The level is turned
# into an escalation bonus that will apply to that player's next card draw,
# then be cleared. Levels stack additively if the same player skips twice
# in a row before drawing.
func apply_penalty_level(player: String, level: int) -> void:
	var bonus := _level_to_bonus(level)
	if bonus == 0.0:
		return
	_pending_escalation[player] = _pending_escalation.get(player, 0.0) + bonus


static func _level_to_bonus(level: int) -> float:
	# Matches the "luck" names shown on the penalty buttons:
	#   1 (easiest) → +1.0  hardest cards later
	#   2           → +0.5
	#   3           →  0.0  baseline
	#   4 (hardest) → -0.5  easier cards later
	match level:
		1: return  1.0
		2: return  0.5
		4: return -0.5
		_: return  0.0


func truth_chance_for_current() -> float:
	return 1.0 - dare_chance_for_current()


func dare_chance_for_current() -> float:
	if players.is_empty():
		return 0.5
	return _dare_chance_for_player(current_player())


func _dare_chance_for_player(player: String) -> float:
	if SaveManager.get_streak_balance():
		# Streak-based: the longer you've been on one type, the more likely
		# the other type becomes. +10% per consecutive same-type draw.
		var last: String = _last_type_by_player.get(player, "")
		var streak: int = int(_same_type_streak.get(player, 0))
		if last == "truth":
			return clampf(0.5 + streak * 0.10, TYPE_CHANCE_MIN, TYPE_CHANCE_MAX)
		if last == "dare":
			return clampf(0.5 - streak * 0.10, TYPE_CHANCE_MIN, TYPE_CHANCE_MAX)
		return 0.5
	# Fallback: imbalance-based (legacy behaviour).
	var s: Dictionary = _player_stats.get(player, {"truths": 0, "dares": 0})
	var imbalance: int = s["truths"] - s["dares"]
	return clampf(0.5 + imbalance * TYPE_BALANCE_FACTOR, TYPE_CHANCE_MIN, TYPE_CHANCE_MAX)


# Number of rounds over which the curve sweeps from easy to hard.
#   limited → the user's Match Max Rounds (exact)
#   endless → a fixed window (ENDLESS_PROGRESSION_ROUNDS)
#   default → estimated from deck size / player count, floor of 5
func total_rounds_for_odds() -> int:
	match SaveManager.get_game_mode():
		"limited":
			return maxi(SaveManager.get_match_max_rounds(), 1)
		"endless":
			return ENDLESS_PROGRESSION_ROUNDS
		_:
			if players.is_empty():
				return 15
			var deck := DataManager.truths.size() + DataManager.dares.size()
			@warning_ignore("integer_division")
			var est := deck / players.size()
			return maxi(est, 5)


# Position on the difficulty curve, 0.0 → 1.0, ignoring pending luck.
func curve_base_t() -> float:
	var total := total_rounds_for_odds()
	if total <= 1:
		return 0.0
	return clampf(float(current_round() - 1) / float(total - 1), 0.0, 1.0)


# Luck offset for the current player, in curve units.
func curve_luck_offset() -> float:
	if players.is_empty():
		return 0.0
	var bonus: float = _pending_escalation.get(current_player(), 0.0)
	return bonus * PENALTY_LUCK_CURVE_OFFSET


func _curve_odds_as_probabilities(t: float) -> Dictionary:
	var odds := OddsCalculator.get_odds(current_round(), total_rounds_for_odds(), t)
	var out := {}
	for i in LEVEL_CATEGORIES.size():
		out[LEVEL_CATEGORIES[i]] = odds[i] / 100.0
	return out


# Category probabilities for the current roll, luck included.
func category_weights() -> Dictionary:
	var t := clampf(curve_base_t() + curve_luck_offset(), 0.0, 1.0)
	return _curve_odds_as_probabilities(t)


func category_percentages() -> Dictionary:
	# Prefer the weights that produced the current card — they include any
	# penalty escalation the current player had pending at roll time.
	var weights := _last_rolled_weights if not _last_rolled_weights.is_empty() else category_weights()
	return _weights_to_percentages(weights)


# Baseline (no luck) — used by the footer for the "before" column.
func category_percentages_baseline() -> Dictionary:
	return _weights_to_percentages(_curve_odds_as_probabilities(curve_base_t()))


# Human-readable luck tag for the card currently on screen.
# Empty string when no penalty was applied.
#   bonus +1.0  →  "-2"   (level 1 penalty, easy → much harder next card)
#   bonus +0.5  →  "-1"
#   bonus -0.5  →  "+1"   (level 4 penalty, harsh → easier next card)
#   bonus  0.0  →  ""
func current_luck_label() -> String:
	if _last_rolled_bonus == 0.0:
		return ""
	var luck := int(round(-_last_rolled_bonus * 2.0))
	return "+%d" % luck if luck > 0 else str(luck)


func _weights_to_percentages(weights: Dictionary) -> Dictionary:
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


# True when the current mode doesn't consume cards from the deck —
# both Endless and Limited recycle the pool instead of exhausting it.
func is_deck_recycling() -> bool:
	return SaveManager.get_game_mode() in ["limited", "endless"]


func is_game_complete() -> bool:
	var mode := SaveManager.get_game_mode()
	if mode == "endless":
		return false
	if mode == "limited":
		# Cap is in rounds — one round = players.size() turns.
		if players.is_empty():
			return false
		var cap_turns := SaveManager.get_match_max_rounds() * players.size()
		return cards_played >= cap_turns
	# default mode: end when the deck runs out
	var t_total := DataManager.truths.size()
	var d_total := DataManager.dares.size()
	if t_total + d_total == 0:
		return true
	return _used_truth_ids.size() >= t_total and _used_dare_ids.size() >= d_total

func cards_remaining() -> int:
	if is_endless():
		return -1  # -1 signals "unlimited" to the UI
	var mode := SaveManager.get_game_mode()
	if mode == "limited":
		if players.is_empty():
			return 0
		var total_turns := SaveManager.get_match_max_rounds() * players.size()
		# -1 because the current card has already been drawn.
		return maxi(total_turns - cards_played - 1, 0)
	return (DataManager.truths.size() - _used_truth_ids.size()) \
		+ (DataManager.dares.size() - _used_dare_ids.size())


# Current round number, 1-based. Clamped to the limited-mode cap so the
# game-over state doesn't overshoot the displayed max by one.
func current_round() -> int:
	if players.is_empty():
		return 1
	@warning_ignore("integer_division")
	var r := cards_played / players.size()
	var value := 1 + r
	if SaveManager.get_game_mode() == "limited":
		value = mini(value, SaveManager.get_match_max_rounds())
	return value

func _has_unused(kind: String) -> bool:
	if is_deck_recycling():
		return DataManager.get_prompts_by_type(kind).size() > 0
	var pool := DataManager.get_prompts_by_type(kind)
	var used := _used_ids_for(kind)
	return used.size() < pool.size()


func _used_ids_for(kind: String) -> Dictionary:
	return _used_truth_ids if kind == "truth" else _used_dare_ids


func _pick_prompt(kind: String, category: String) -> Dictionary:
	var pool := DataManager.get_prompts_by_type(kind)
	if pool.is_empty():
		return {}
	var used := _used_ids_for(kind)

	# Shuffle-bag behaviour. In recycling modes (endless / limited) the
	# deck is treated as a bag we draw from without replacement; once
	# every card has been drawn the bag refreshes and we start a new
	# loop. In default mode this branch never fires — the game ends
	# before the deck can exhaust.
	if used.size() >= pool.size() and is_deck_recycling():
		used.clear()

	# Preferred: matching category, unused
	var candidates: Array[int] = []
	for i in pool.size():
		if used.has(i):
			continue
		if pool[i].get("category", "") == category:
			candidates.append(i)

	# Fallback: any unused card
	if candidates.is_empty():
		for i in pool.size():
			if used.has(i):
				continue
			candidates.append(i)

	if candidates.is_empty():
		return {}

	var idx: int = candidates[randi() % candidates.size()]
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

	var s: Dictionary = _player_stats[player]
	if current_type == "truth":
		s["truths"] += 1
	else:
		s["dares"] += 1

	_record_type_streak(player, current_type)


func _roll_type(player: String) -> String:
	var t_avail := _has_unused("truth")
	var d_avail := _has_unused("dare")
	if not t_avail and not d_avail:
		return "truth"
	if not t_avail:
		return "dare"
	if not d_avail:
		return "truth"

	var dare_chance := _dare_chance_for_player(player)
	return "dare" if randf() < dare_chance else "truth"


func _record_type_streak(player: String, type: String) -> void:
	# Same type as last draw → streak +1. Different type → streak reset to 0.
	# _last_type_by_player always records the new type, regardless.
	var last: String = _last_type_by_player.get(player, "")
	if last == type:
		_same_type_streak[player] = int(_same_type_streak.get(player, 0)) + 1
	else:
		_same_type_streak[player] = 0
	_last_type_by_player[player] = type


func _roll_category() -> String:
	var player := current_player()
	var bonus: float = _pending_escalation.get(player, 0.0)

	# Snapshot the weights actually used for this card, luck included.
	# `category_weights` reads `_pending_escalation` internally.
	var weights := category_weights()
	_last_rolled_weights = weights.duplicate()
	_last_rolled_bonus = bonus

	# Consume the pending bonus — it applies only to this one draw.
	if bonus != 0.0:
		_pending_escalation.erase(player)

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
