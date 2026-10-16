class_name PenaltyDialog extends Control

signal confirmed

const TITLE := "SELECT PENALTY TO PASS TURN"
const SUB_OPTION_HEIGHT := 44

var _modal: Modal
var _sections: Array = []
var _open_group: String = ""
var _selection: Dictionary = {"group": "", "label": ""}


static func create() -> PenaltyDialog:
	var p := PenaltyDialog.new()
	p._build()
	return p


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_modal = Modal.create()
	add_child(_modal)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)

	col.add_child(_make_title_row())

	var hint := Label.new()
	hint.text = "Max %d groups · %d options each" % [
		Design.MAX_PENALTY_GROUPS,
		Design.MAX_PENALTY_OPTIONS_GROUP,
	]
	Design.apply_label(hint, 10, Design.GRAY)
	col.add_child(hint)
	col.add_child(_spacer(4))

	var groups := DataManager.pass_groups.keys()
	for group_name in groups:
		var section := _make_section(group_name)
		col.add_child(section["group_box"])
		_sections.append(section)

	col.add_child(_spacer(4))

	var confirm := StyledButton.create("CONFIRM PENALTY & PASS", Design.SECONDARY)
	confirm.pressed.connect(_on_confirm)
	col.add_child(confirm)

	_modal.set_content(col)

	# Open the first group by default and never let it close.
	# Auto-select its first sub-option.
	if not _sections.is_empty():
		_select_default()


func open() -> void:
	# Reset so each call starts fresh with the first group + its first option.
	_selection = {"group": "", "label": "", "level": 1}
	if not _sections.is_empty():
		_select_default()
	_modal.open()


func _select_default() -> void:
	# Picks the first group's first option as the default selection.
	var first: Dictionary = _sections[0]
	_open_group = first["group"]
	_refresh_visibility()
	_refresh_arrows()
	var entries: Array = DataManager.pass_groups.get(first["group"], [])
	if not entries.is_empty():
		var entry: Dictionary = entries[0]
		_selection = {
			"group": first["group"],
			"label": entry.get("label", ""),
			"level": int(entry.get("level", 1)),
		}
	_refresh_checkboxes()


func _on_confirm() -> void:
	_modal.close()
	confirmed.emit(_selection)


func _make_title_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = TITLE
	Design.apply_label(lbl, Design.FONT_SIZE_TITLE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var close := CloseButton.create()
	close.pressed.connect(_modal.close)
	row.add_child(close)
	return row


func _make_section(group_name: String) -> Dictionary:
	var header_label := _truncate_label(group_name.to_upper())
	var header := StyledButton.create(header_label, Design.FIVE, Design.ICON_ARROW_DOWN)
	header.pressed.connect(func(): _toggle_group(group_name))

	var sub_box := BorderedBox.create(12)
	var sub_container := VBoxContainer.new()
	sub_container.add_theme_constant_override("separation", 12)
	sub_box.add_with_margins(sub_container, 12, 12, 12, 12)

	var entries: Array = DataManager.pass_groups.get(group_name, [])
	for entry in entries:
		sub_container.add_child(_make_option_row(
			group_name,
			entry.get("label", ""),
			int(entry.get("level", 1)),
		))

	# Header + 12-gap + sub, wrapped so the gap collapses when sub is hidden.
	var group_box := VBoxContainer.new()
	group_box.add_theme_constant_override("separation", 12)
	group_box.add_child(header)
	group_box.add_child(sub_box)

	return {
		"group": group_name,
		"header": header,
		"sub_container": sub_box,
		"sub_vbox": sub_container,
		"group_box": group_box,
	}


func _make_option_row(group_name: String, label: String, level: int) -> StyledButton:
	# Groups are user-defined (uploaded via CSV), so we don't colour by
	# group name. The luck suffix (shown only for levels 1, 2 and 4)
	# hints at the effect the option will have on the player's next card.
	var luck_text := _level_luck_text(level)
	var display := _truncate_label(label)
	if not luck_text.is_empty():
		display += "   ·   " + luck_text
	var btn := StyledButton.create(display, Design.SIX, "", SUB_OPTION_HEIGHT)
	btn.suppress_click_sound = true
	btn.pressed.connect(func():
		AudioManager.play_click()
		_select(group_name, label, level)
	)
	btn.set_meta("group", group_name)
	btn.set_meta("label", label)
	btn.set_meta("level", level)
	return btn


# Shorthand shown on the penalty button. Level 3 is baseline and shows
# nothing, so the "no effect" case is the empty string.
#   1 → "−2 luck"   2 → "−1 luck"   3 → ""   4 → "+1 luck"
static func _level_luck_text(level: int) -> String:
	match level:
		1: return "−2 luck"
		2: return "−1 luck"
		4: return "+1 luck"
		_: return ""

func _toggle_group(group_name: String) -> void:
	# Only-one-open, and never allow closing the active one.
	if _open_group == group_name:
		return
	_open_group = group_name
	_refresh_visibility()
	_refresh_arrows()


func _refresh_visibility() -> void:
	for s in _sections:
		var is_open: bool = s["group"] == _open_group
		s["sub_container"].visible = is_open


func _refresh_arrows() -> void:
	for s in _sections:
		var is_open: bool = s["group"] == _open_group
		var header: StyledButton = s["header"]
		header.set_icon(Design.ICON_OPEN_CATEGORY if is_open else Design.ICON_ARROW_DOWN)


func _select(group_name: String, label: String, level: int) -> void:
	_selection = {"group": group_name, "label": label, "level": level}
	_refresh_checkboxes()


func _refresh_checkboxes() -> void:
	for s in _sections:
		var sub_vbox: VBoxContainer = s["sub_vbox"]
		for row in sub_vbox.get_children():
			if not row is StyledButton:
				continue
			var btn: StyledButton = row
			if not btn.has_meta("group"):
				continue
			var matched: bool = (
				btn.get_meta("group") == _selection["group"]
				and btn.get_meta("label") == _selection["label"]
			)
			btn.set_bg_color(Design.EIGHT if matched else Design.SIX)


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

# Truncate a label so it can't push the button too wide.
# Only used for user-uploaded penalty names and options.
func _truncate_label(text: String) -> String:
	var limit := Design.MAX_PENALTY_LABEL_CHARS
	if text.length() <= limit:
		return text
	return text.substr(0, limit).strip_edges() + "..."
