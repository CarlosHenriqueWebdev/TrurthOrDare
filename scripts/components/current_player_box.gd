class_name CurrentPlayerBox extends BorderedBox

# Bordered box showing the current player's avatar, name, and category.

const HEIGHT := 134
const AVATAR_SIZE := 90
const AVATAR_RADIUS := 20


static func make(player_name: String, category: String, index: int = 0, total: int = 0) -> CurrentPlayerBox:
	var box := CurrentPlayerBox.new()
	box._build(18)
	box.custom_minimum_size = Vector2(0, HEIGHT)
	box._build_current(player_name, category, index, total)
	return box


func _build_current(player_name: String, category: String, index: int, total: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	row.add_child(Avatar.create_rounded(player_name, AVATAR_SIZE, AVATAR_RADIUS))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(col)

	var current_lbl := Label.new()
	current_lbl.text = "CURRENT PLAYER %d/%d" % [index, total]
	Design.apply_label(current_lbl, 14, Design.GLOBAL_CONTENT_BORDER)
	col.add_child(current_lbl)

	col.add_child(_gap(8))

	var name_lbl := Label.new()
	name_lbl.text = player_name.to_upper() + "'S TURN"
	Design.apply_label(name_lbl, 20)
	col.add_child(name_lbl)

	col.add_child(_gap(8))

	col.add_child(CategoryBadge.create(category))

	add_with_margins(row, 16, 16, 16, 16)


func _gap(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
