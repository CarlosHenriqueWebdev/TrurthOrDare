class_name CategoryBadge extends Control

const HEIGHT := 32
const PAD_H  := 12
const FONT_SIZE := 10


static func create(category: String) -> CategoryBadge:
	var b := CategoryBadge.new()
	b._build(category)
	return b


func _build(category: String) -> void:
	custom_minimum_size.y = HEIGHT
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var color: Color = Design.CATEGORY_COLORS.get(category, Design.GRAY)

	# Label first so we can measure it and size the badge to fit.
	var text := "CATEGORY " + category.to_upper()

	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, FONT_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Measure the string directly — Label.get_minimum_size() is unreliable
	# before the node is in the tree (falls back to default theme font).
	var text_w := 0.0
	if Design.font_variation:
		text_w = Design.font_variation.get_string_size(
			text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE
		).x
	custom_minimum_size.x = ceil(text_w) + PAD_H * 2

	# Background pill — full rect.
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left     = Design.BUTTON_RADIUS
	sb.corner_radius_top_right    = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left  = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)

	# Border overlay — full rect, own draw pass (matches StyledButton).
	var border := Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.draw_center = false
	bsb.border_width_left   = Design.BUTTON_BORDER_W
	bsb.border_width_top    = Design.BUTTON_BORDER_W
	bsb.border_width_right  = Design.BUTTON_BORDER_W
	bsb.border_width_bottom = Design.BUTTON_BORDER_W
	bsb.border_color = Design.BUTTON_BORDER
	bsb.corner_radius_top_left     = Design.BUTTON_RADIUS
	bsb.corner_radius_top_right    = Design.BUTTON_RADIUS
	bsb.corner_radius_bottom_left  = Design.BUTTON_RADIUS
	bsb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	border.add_theme_stylebox_override("panel", bsb)
	add_child(border)

	# Label on top, centered.
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(lbl)
