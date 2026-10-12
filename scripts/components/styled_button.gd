class_name StyledButton extends Button

# Reusable action button: bg color, 3px border, text + trailing icon.
# Usage:
#   var btn := StyledButton.create("START", Design.SECONDARY)
#   btn.pressed.connect(_on_pressed)
#   add_child(btn)

static func create(text: String, bg_color: Color, icon_path: String = Design.ICON_CHEVRON) -> StyledButton:
	var btn := StyledButton.new()
	btn._build(text, bg_color, icon_path)
	return btn


func _build(text: String, bg_color: Color, icon_path: String) -> void:
	custom_minimum_size = Vector2(0, Design.BUTTON_HEIGHT)
	focus_mode = Control.FOCUS_NONE

	# Background
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left     = Design.BUTTON_RADIUS
	sb.corner_radius_top_right    = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left  = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	add_theme_stylebox_override("normal",  sb)
	add_theme_stylebox_override("hover",   sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("focus",   sb)

	# Border overlay (keeps alpha blending clean vs. StyleBoxFlat border)
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

	# Content overlay (text left, icon right — justify-between)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  Design.BUTTON_PADDING_H)
	margin.add_theme_constant_override("margin_right", Design.BUTTON_PADDING_H)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, Design.FONT_SIZE_BTN)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)

	var icon := TextureRect.new()
	var tex := load(icon_path)
	if tex:
		icon.texture = tex
	else:
		push_error("Icon failed to load: " + icon_path)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	# Animation
	resized.connect(func(): pivot_offset = size / 2)
	mouse_entered.connect(_animate_scale.bind(self, Design.HOVER_SCALE, Design.HOVER_TIME))
	mouse_exited.connect(_animate_scale.bind(self, 1.0, Design.HOVER_TIME))
	button_down.connect(_animate_scale.bind(self, Design.PRESS_SCALE, Design.PRESS_TIME))
	button_up.connect(_animate_scale.bind(self, 1.0, Design.PRESS_TIME))


static func _animate_scale(node: Control, target: float, time: float) -> void:
	if not is_instance_valid(node):
		return
	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(target, target), time)
