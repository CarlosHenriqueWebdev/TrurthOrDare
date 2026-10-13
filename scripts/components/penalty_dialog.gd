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
	if not _sections.is_empty():
		_open_group = _sections[0]["group"]
		_refresh_visibility()
		_refresh_arrows()
		_refresh_checkboxes()


func open() -> void:
	_modal.open()


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

	var close := TextureRect.new()
	var tex := load(Design.ICON_CLOSE)
	if tex:
		close.texture = tex
	close.custom_minimum_size = Vector2(16, 16)
	close.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.modulate = Design.ERROR_TEXT
	close.mouse_filter = Control.MOUSE_FILTER_STOP
	close.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play_click()
			_modal.close()
	)
	row.add_child(close)
	return row


func _make_section(group_name: String) -> Dictionary:
	var header := StyledButton.create(group_name.to_upper(), Design.FIVE, Design.ICON_ARROW_DOWN)
	header.pressed.connect(func(): _toggle_group(group_name))

	var sub_box := BorderedBox.create(12)
	var sub_container := VBoxContainer.new()
	sub_container.add_theme_constant_override("separation", 12)
	sub_box.add_with_margins(sub_container, 12, 12, 12, 12)

	var labels: Array = DataManager.pass_groups.get(group_name, [])
	for i in labels.size():
		sub_container.add_child(_make_option_row(group_name, labels[i]))

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


func _make_option_row(group_name: String, label: String) -> StyledButton:
	var btn := StyledButton.create(label, Design.SIX, Design.ICON_CHECKBOX, SUB_OPTION_HEIGHT)
	btn.suppress_click_sound = true
	btn.pressed.connect(func():
		AudioManager.play_click()
		_select(group_name, label)
	)
	btn.set_meta("group", group_name)
	btn.set_meta("label", label)
	return btn


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
		header.set_icon(Design.ICON_ARROW_UP if is_open else Design.ICON_ARROW_DOWN)


func _select(group_name: String, label: String) -> void:
	_selection = {"group": group_name, "label": label}
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
			btn.set_icon(Design.ICON_CHECKBOX_CHECKED if matched else Design.ICON_CHECKBOX)


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
