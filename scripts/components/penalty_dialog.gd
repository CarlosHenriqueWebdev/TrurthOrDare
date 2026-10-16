class_name PenaltyDialog extends Control

signal confirmed

const TITLE := "SELECT PENALTY TO PASS TURN"
const SUB_OPTION_HEIGHT := 44

var _modal: Modal
var _sections: Array = []
var _open_group: String = ""
var _selection: Dictionary = {"group": "", "label": "", "level": 1, "index": 0}
var _scroll: ScrollContainer
var _scroll_content: VBoxContainer


static func create() -> PenaltyDialog:
	var p := PenaltyDialog.new()
	p._build()
	return p


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_modal = Modal.create()
	add_child(_modal)

	# VBox separation is 0 — all gaps are explicit so the layout can hit
	# exact pixel values (title→caption=16, caption→luck=8, luck→scroll=12).
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)

	col.add_child(_make_title_row())
	col.add_child(_spacer(16))

	# Two stacked labels instead of one. The first is a plain gray caption
	# about the CSV limits; the second is the luck explainer, tinted with
	# Design.EIGHT lightened so it reads on the black background — same
	# trick ODDS_LIGHTEN uses for the category colours.
	var limits := Label.new()
	limits.text = "Max %d groups · %d options each" % [
		Design.MAX_PENALTY_GROUPS,
		Design.MAX_PENALTY_OPTIONS_GROUP,
	]
	limits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	limits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Design.apply_label(limits, 10, Design.GRAY)
	col.add_child(limits)
	col.add_child(_spacer(8))

	var luck_help := Label.new()
	luck_help.text = (
		"\"Luck\" shifts your next card's difficulty:\n"
		+ "  -2 (easy penalty)   ->  harder\n"
		+ "  -1                  ->  slightly harder\n"
		+ "   0                  ->  no change\n"
		+ "  +1 (harsh penalty)  ->  easier\n"
		+ "Harder = more Drunk/Wasted.  Easier = more Sober/Tipsy."
	)
	luck_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	luck_help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Design.apply_label(luck_help, 10, Design.EIGHT.lightened(0.45))
	col.add_child(luck_help)
	col.add_child(_spacer(12))

	# Scroll wrapper — everything between the title and the confirm button
	# scrolls when the option list is taller than the cap. The cap itself
	# is computed in _fit_scroll() once the layout has settled.
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_scroll)

	_scroll_content = VBoxContainer.new()
	_scroll_content.add_theme_constant_override("separation", 12)
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_scroll_content)

	var groups := DataManager.pass_groups.keys()
	for group_name in groups:
		var section := _make_section(group_name)
		_scroll_content.add_child(section["group_box"])
		_sections.append(section)

	col.add_child(_spacer(12))

	var confirm := StyledButton.create("CONFIRM PENALTY & PASS", Design.SECONDARY)
	confirm.pressed.connect(_on_confirm)
	col.add_child(confirm)

	_modal.set_content(col)
	_fit_scroll.call_deferred()
	UiUtils.make_scroll_content_friendly(_scroll)

	# Open the first group by default and never let it close.
	# Auto-select its first sub-option.
	if not _sections.is_empty():
		_select_default()


func open() -> void:
	# Reset so each call starts fresh with the first group + its first option.
	_selection = {"group": "", "label": "", "level": 1, "index": 0}
	if not _sections.is_empty():
		_select_default()
	_fit_scroll.call_deferred()
	# Re-walk the scroll content in case anything was rebuilt.
	if _scroll:
		UiUtils.make_scroll_content_friendly.call_deferred(_scroll)
	_modal.open()


# Size the scroll to its content, up to a cap so the dialog never spills
# off the top of the viewport. Recalculated on every open in case the
# window was resized.
func _fit_scroll() -> void:
	if not is_instance_valid(_scroll) or not is_instance_valid(_scroll_content):
		return
	var content_h := int(_scroll_content.get_combined_minimum_size().y)
	var viewport_h := int(get_viewport_rect().size.y)
	var cap := int(min(420.0, viewport_h * 0.5))
	_scroll.custom_minimum_size.y = min(content_h, cap)


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
			"index": 0,
		}
	_refresh_checkboxes()


func _on_confirm() -> void:
	_modal.close()
	# Strip the internal index — Game only cares about group/label/level.
	confirmed.emit({
		"group": _selection.get("group", ""),
		"label": _selection.get("label", ""),
		"level": int(_selection.get("level", 1)),
	})


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

	# Iterate by index so duplicate labels in the CSV ("Beer, Beer, Beer")
	# get distinct IDs. _refresh_checkboxes matches on (group, index), so
	# only the clicked row is highlighted.
	var entries: Array = DataManager.pass_groups.get(group_name, [])
	for i in entries.size():
		var entry: Dictionary = entries[i]
		sub_container.add_child(_make_option_row(
			group_name,
			entry.get("label", ""),
			int(entry.get("level", 1)),
			i,
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


func _make_option_row(group_name: String, label: String, level: int, index: int) -> StyledButton:
	# Groups are user-defined (uploaded via CSV), so we don't colour by
	# group name. The luck suffix is rendered as a trailing label so it
	# sits at the right edge of the button (CSS justify-between feel).
	var luck_text := _level_luck_text(level)
	var display := _truncate_label(label)
	var btn := StyledButton.create(display, Design.SIX, "", SUB_OPTION_HEIGHT, false, false, false, luck_text)
	btn.suppress_click_sound = true
	btn.pressed.connect(func():
		AudioManager.play_click()
		_select(group_name, label, level, index)
	)
	btn.set_meta("group", group_name)
	btn.set_meta("label", label)
	btn.set_meta("level", level)
	btn.set_meta("index", index)
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


func _select(group_name: String, label: String, level: int, index: int) -> void:
	_selection = {"group": group_name, "label": label, "level": level, "index": index}
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
			# Match on (group, index) rather than (group, label) so
			# duplicate labels in the CSV stay distinct.
			var matched: bool = (
				btn.get_meta("group") == _selection["group"]
				and btn.get_meta("index") == _selection["index"]
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
