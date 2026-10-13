extends Node

# Loads truths, dares, and pass options from CSVs in res://data/.
# Exposes:
#   truths / dares    -> Array[Dictionary] of {category, text, long_text}
#   pass_groups       -> Dictionary of {group_name: [labels]}
#   get_prompts_by_type("truth"|"dare") -> Array[Dictionary]
#
# CSV schema:
#   truths.csv / dares.csv: category,text,long_text
#   pass_options.csv:       group,label
# Quoted fields support embedded commas and "" escapes. No embedded newlines.

const TRUTHS_PATH := "res://data/truths.csv"
const DARES_PATH  := "res://data/dares.csv"
const PASS_PATH   := "res://data/pass_options.csv"

var truths: Array[Dictionary] = []
var dares: Array[Dictionary] = []
var pass_groups: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	truths.clear()
	dares.clear()
	pass_groups.clear()
	_load_prompts(TRUTHS_PATH, truths)
	_load_prompts(DARES_PATH, dares)
	_load_pass_options(PASS_PATH)


func get_prompts_by_type(kind: String) -> Array[Dictionary]:
	return truths if kind == "truth" else dares


# ---------- internals ----------

func _load_prompts(path: String, target: Array[Dictionary]) -> void:
	if not FileAccess.file_exists(path):
		push_warning("CSV not found: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open: " + path)
		return
	f.get_line()  # skip header
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges().is_empty():
			continue
		var cols := _parse_line(line)
		if cols.size() < 2:
			continue
		var entry := {
			"category": cols[0].strip_edges().to_lower(),
			"text": cols[1],
			"long_text": cols[2] if cols.size() >= 3 else "",
		}
		target.append(entry)
	f.close()


func _load_pass_options(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("CSV not found: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open: " + path)
		return
	f.get_line()  # skip header
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges().is_empty():
			continue
		var cols := _parse_line(line)
		if cols.size() < 2:
			continue
		var group := cols[0].strip_edges()
		var label := cols[1].strip_edges()
		if not pass_groups.has(group):
			pass_groups[group] = []
		pass_groups[group].append(label)
	f.close()


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
