## Card and penalty data loader.
##
## Reads cards from one CSV (type,category,text) and penalty groups from
## another (group,label). User uploads are copied to user:// so the game
## owns its copy. Falls back to the bundled defaults on startup when no
## upload exists.
extends Node

# Loads truths, dares, and pass options.
# Truths and dares come from ONE csv: type,category,text.
# Default file is res://data/cards.csv. Uploaded files are copied into
# user:// so the game owns them — the original can move or change freely.

const PASS_PATH := "res://data/pass_options.csv"

# Where uploaded copies live. Fixed names so we always know what to load.
const CARDS_CUSTOM_PATH := "user://custom_cards.csv"
const PASS_CUSTOM_PATH  := "user://custom_penalties.csv"

const VALID_TYPES      := ["truth", "dare"]
const VALID_CATEGORIES := ["sober", "tipsy", "drunk", "wasted"]

var truths: Array[Dictionary] = []
var dares: Array[Dictionary] = []
var pass_groups: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	# Prefer the user's own copy if one exists. Otherwise fall back to defaults.
	var cards_path := CARDS_CUSTOM_PATH
	if not FileAccess.file_exists(cards_path):
		cards_path = Design.DEFAULT_CARDS_PATH
	_load_cards(cards_path)

	var pass_path := PASS_CUSTOM_PATH
	if not FileAccess.file_exists(pass_path):
		pass_path = PASS_PATH
	_load_pass_options(pass_path)


# Load a specific cards file. Copies it to user:// so the original can move.
# Returns true on success.
func load_cards(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("CSV not found: " + path)
		return false
	var t: Array[Dictionary] = []
	var d: Array[Dictionary] = []
	if not _parse_cards(path, t, d):
		return false
	if t.is_empty() and d.is_empty():
		push_warning("CSV had no valid rows: " + path)
		return false
	if not _copy_to_user(path, CARDS_CUSTOM_PATH):
		return false
	truths = t
	dares = d
	SaveManager.set_cards_display_path(path)
	return true


# Load a specific penalty CSV. Copies it to user:// so the original can move.
func load_pass_options(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("CSV not found: " + path)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	# Peek at the header to catch a cards CSV mistakenly uploaded as a penalty CSV.
	var header := f.get_line()
	if header.findn("type") != -1 or header.findn("category") != -1:
		push_warning("Not a penalty CSV (header looks like a cards file): " + path)
		f.close()
		return false
	var new_groups: Dictionary = {}
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges().is_empty():
			continue
		var cols := _parse_line(line)
		if cols.size() < 2:
			continue
		var group := cols[0].strip_edges()
		var label := cols[1].strip_edges()
		if group.to_lower().begins_with("header") or group.to_lower() == "group":
			continue
		if not new_groups.has(group):
			if new_groups.size() >= Design.MAX_PENALTY_GROUPS:
				continue
			new_groups[group] = []
		if new_groups[group].size() >= Design.MAX_PENALTY_OPTIONS_GROUP:
			continue
		new_groups[group].append(label)
	f.close()
	if new_groups.is_empty():
		return false
	if not _copy_to_user(path, PASS_CUSTOM_PATH):
		return false
	pass_groups = new_groups
	SaveManager.set_pass_display_path(path)
	return true


func reset_to_default() -> void:
	_delete_user_file(CARDS_CUSTOM_PATH)
	SaveManager.clear_cards_display_path()
	_load_cards(Design.DEFAULT_CARDS_PATH)


func reset_pass_options_to_default() -> void:
	_delete_user_file(PASS_CUSTOM_PATH)
	SaveManager.clear_pass_display_path()
	_load_pass_options(PASS_PATH)


func get_prompts_by_type(kind: String) -> Array[Dictionary]:
	return truths if kind == "truth" else dares


# ---------- internals ----------

func _load_cards(path: String) -> void:
	truths.clear()
	dares.clear()
	if not FileAccess.file_exists(path):
		push_warning("Cards CSV not found: " + path)
		return
	var t: Array[Dictionary] = []
	var d: Array[Dictionary] = []
	_parse_cards(path, t, d)
	truths = t
	dares = d


func _parse_cards(path: String, out_truths: Array[Dictionary], out_dares: Array[Dictionary]) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open: " + path)
		return false
	f.get_line()  # skip header
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges().is_empty():
			continue
		var cols := _parse_line(line)
		if cols.size() < 3:
			continue
		var kind := cols[0].strip_edges().to_lower()
		var cat  := cols[1].strip_edges().to_lower()
		# Skip header-ish rows that users paste from the format example.
		if kind.begins_with("header") or kind == "type":
			continue
		if not kind in VALID_TYPES:
			continue
		if not cat in VALID_CATEGORIES:
			continue
		var entry := {
			"category": cat,
			"text": cols[2],
		}
		if kind == "truth":
			out_truths.append(entry)
		else:
			out_dares.append(entry)
	f.close()
	return true


func _load_pass_options(path: String) -> void:
	pass_groups.clear()
	if not FileAccess.file_exists(path):
		push_warning("CSV not found: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open: " + path)
		return
	f.get_line()
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges().is_empty():
			continue
		var cols := _parse_line(line)
		if cols.size() < 2:
			continue
		var group := cols[0].strip_edges()
		var label := cols[1].strip_edges()
		if group.to_lower().begins_with("header") or group.to_lower() == "group":
			continue
		if not pass_groups.has(group):
			if pass_groups.size() >= Design.MAX_PENALTY_GROUPS:
				continue
			pass_groups[group] = []
		if pass_groups[group].size() >= Design.MAX_PENALTY_OPTIONS_GROUP:
			continue
		pass_groups[group].append(label)
	f.close()


func _copy_to_user(src: String, dst: String) -> bool:
	var f_in := FileAccess.open(src, FileAccess.READ)
	if f_in == null:
		push_error("Cannot read: " + src)
		return false
	var content := f_in.get_buffer(f_in.get_length())
	f_in.close()
	var f_out := FileAccess.open(dst, FileAccess.WRITE)
	if f_out == null:
		push_error("Cannot write: " + dst)
		return false
	f_out.store_buffer(content)
	f_out.close()
	return true


func _delete_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _parse_line(line: String) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	var in_quotes := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if in_quotes:
			if c == "\"":
				if i + 1 < line.length() and line[i + 1] == "\"":
					cur += "\""
					i += 1
				else:
					in_quotes = false
			else:
				cur += c
		else:
			if c == "\"":
				in_quotes = true
			elif c == ",":
				out.append(cur)
				cur = ""
			else:
				cur += c
		i += 1
	out.append(cur)
	return out
