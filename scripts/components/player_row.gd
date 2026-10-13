class_name PlayerRow extends HBoxContainer

signal remove_requested

const AVATAR_SIZE := 42
const AVATAR_GAP  := 12
const ROW_HEIGHT  := 58


static func create(player_name: String, slot: int) -> PlayerRow:
	var row := PlayerRow.new()
	row._build(player_name, slot)
	return row


func _build(player_name: String, slot: int) -> void:
	custom_minimum_size = Vector2(0, ROW_HEIGHT)
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	add_child(Avatar.create_circle(player_name, AVATAR_SIZE))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(AVATAR_GAP, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)

	var name_lbl := Label.new()
	name_lbl.text = _ordinal(slot) + " " + player_name
	Design.apply_label(name_lbl, Design.FONT_SIZE_LABEL)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)

	var remove_btn := StyledButton.create("REMOVE", Design.TERTIARY, Design.ICON_REMOVE, 32, true, true)
	remove_btn.suppress_click_sound = true
	remove_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove_btn.pressed.connect(func(): remove_requested.emit())
	add_child(remove_btn)


static func _ordinal(n: int) -> String:
	var n100 := n % 100
	if n100 >= 11 and n100 <= 13:
		return str(n) + "th"
	match n % 10:
		1: return str(n) + "st"
		2: return str(n) + "nd"
		3: return str(n) + "rd"
		_: return str(n) + "th"
