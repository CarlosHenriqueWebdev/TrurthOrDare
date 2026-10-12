class_name StyledButton extends Button

# Reusable action button. Optional icon, optional disabled visual.
# Layout: [ text (left) ] .... [ icon (right) ]
#
# Parameters:
#   hug      -> size to fit content and keep a tight 8px gap
#   compact  -> small variant: font 9, padding 10, icon 16 (used with hug)

var _bg_color: Color


static func create(
	text: String,
	bg_color: Color,
	icon_path := Design.ICON_CHEVRON,
	height := Design.BUTTON_HEIGHT,
	hug := false,
	compact := false
) -> StyledButton:
	var btn := StyledButton.new()
	btn._build(text, bg_color, icon_path, height, false, hug, compact)
	return btn


static func create_icon_only(icon_path: String, bg_color: Color, height := Design.BUTTON_HEIGHT) -> StyledButton:
	var btn := StyledButton.new()
	btn._build("", bg_color, icon_path, height, true, true, false)
	return btn


func _build(text: String, bg_color: Color, icon_path: String, height: int, icon_only: bool, hug: bool, compact: bool) -> void:
	_bg_color = bg_color
	custom_minimum_size = Vector2(0, height)
	focus_mode = Control.FOCUS_NONE
	_apply_style(false)

	var font_size := 9 if compact else Design.FONT_SIZE_BTN
	var padding_h := 10 if compact else Design.BUTTON_PADDING_H
	var icon_size := 16 if compact else 18

	# Hug mode: refuse stretching so the parent can't inflate the gap.
	# Regular mode: fill available width so the icon reaches the far right.
	if hug:
		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

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

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  padding_h)
	margin.add_theme_constant_override("margin_right", padding_h)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_only:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	if not icon_only:
		var lbl := Label.new()
		lbl.text = text
		Design.apply_label(lbl, font_size)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Hug: don't claim extra space. Regular: push the icon to the right.
		lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if hug else Control.SIZE_EXPAND_FILL
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl)

		var gap := Control.new()
		gap.custom_minimum_size = Vector2(8, 0)
		# Hug: fixed 8px gap. Regular: absorbs width, icon pinned right.
		gap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if hug else Control.SIZE_EXPAND_FILL
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(gap)

	var icon := TextureRect.new()
	var tex := load(icon_path)
	if tex:
		icon.texture = tex
	else:
		push_error("Icon failed to load: " + icon_path)
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	if hug:
		custom_minimum_size.x = _compute_hug_width(text, icon_only, font_size, padding_h, icon_size)

	resized.connect(func(): pivot_offset = size / 2)
	mouse_entered.connect(_animate_scale.bind(self, Design.HOVER_SCALE, Design.HOVER_TIME))
	mouse_exited.connect(_animate_scale.bind(self, 1.0, Design.HOVER_TIME))
	button_down.connect(_animate_scale.bind(self, Design.PRESS_SCALE, Design.PRESS_TIME))
	button_up.connect(_animate_scale.bind(self, 1.0, Design.PRESS_TIME))


func _compute_hug_width(text: String, icon_only: bool, font_size: int, padding_h: int, icon_size: int) -> float:
	if icon_only:
		return float(padding_h * 2 + icon_size)
	var text_w := 0.0
	if Design.font_variation:
		text_w = Design.font_variation.get_string_size(
			text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
		).x
	return float(padding_h * 2) + ceil(text_w) + 8.0 + float(icon_size)


func _apply_style(is_disabled: bool) -> void:
	var color := Design.DISABLED if is_disabled else _bg_color
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left     = Design.BUTTON_RADIUS
	sb.corner_radius_top_right    = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left  = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	add_theme_stylebox_override("normal",   sb)
	add_theme_stylebox_override("hover",    sb)
	add_theme_stylebox_override("pressed",  sb)
	add_theme_stylebox_override("focus",    sb)
	add_theme_stylebox_override("disabled", sb)


func set_disabled_visual(is_disabled: bool) -> void:
	disabled = is_disabled
	_apply_style(is_disabled)
	if is_disabled:
		scale = Vector2.ONE


static func _animate_scale(node: Control, target: float, time: float) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and node.disabled:
		return
	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(target, target), time)
