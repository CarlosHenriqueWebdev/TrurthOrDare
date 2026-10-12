class_name PlayerRow extends HBoxContainer

# One player row: [avatar] [ordinal + name] ................ [REMOVE]
# Emits `remove_requested` when REMOVE is tapped.

signal remove_requested

const AVATAR_SIZE := 42
const AVATAR_GAP  := 12


static func create(player_name: String, position: int) -> PlayerRow:
	var row := PlayerRow.new()
	row._build(player_name, position)
	return row


func _build(player_name: String, position: int) -> void:
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	add_child(_make_avatar(player_name))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(AVATAR_GAP, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)

	var name_lbl := Label.new()
	name_lbl.text = _ordinal(position) + " " + player_name
	Design.apply_label(name_lbl, Design.FONT_SIZE_LABEL)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)

	var remove_btn := StyledButton.create("REMOVE", Design.TERTIARY, Design.ICON_REMOVE, 32, true, true)
	remove_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove_btn.pressed.connect(func(): remove_requested.emit())
	add_child(remove_btn)


static func _make_avatar(player_name: String) -> BorderedBox:
	var box := BorderedBox.create_circle(AVATAR_SIZE)
	var letter := "?"
	if player_name.length() > 0:
		letter = player_name.substr(0, 1).to_upper()

	var avatar_path := Design.AVATARS_DIR + letter + ".png"
	if ResourceLoader.exists(avatar_path):
		var tex := TextureRect.new()
		tex.texture = load(avatar_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.content.add_child(tex)
	else:
		# Fallback: dark circle with the letter
		var fallback := Panel.new()
		fallback.custom_minimum_size = Vector2(AVATAR_SIZE - 8, AVATAR_SIZE - 8)
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Design.SIX
		fsb.corner_radius_top_left     = 999
		fsb.corner_radius_top_right    = 999
		fsb.corner_radius_bottom_left  = 999
		fsb.corner_radius_bottom_right = 999
		fallback.add_theme_stylebox_override("panel", fsb)

		var lbl := Label.new()
		lbl.text = letter
		Design.apply_label(lbl, 20)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.add_child(lbl)

		box.content.add_child(fallback)

	return box


static func _ordinal(n: int) -> String:
	var n100 := n % 100
	if n100 >= 11 and n100 <= 13:
		return str(n) + "th"
	match n % 10:
		1: return str(n) + "st"
		2: return str(n) + "nd"
		3: return str(n) + "rd"
		_: return str(n) + "th"
