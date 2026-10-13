class_name ToggleButton extends Button

var _active: bool = false
var _locked: bool = false


static func create(label_text: String) -> ToggleButton:
	var btn := ToggleButton.new()
	btn._build(label_text)
	return btn


func _build(label_text: String) -> void:
	custom_minimum_size = Vector2(0, Design.BUTTON_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE

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

	var lbl := Label.new()
	lbl.text = label_text
	lbl.name = "ToggleLabel"
	Design.apply_label(lbl, Design.FONT_SIZE_BTN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	resized.connect(func(): pivot_offset = size / 2)
	mouse_entered.connect(StyledButton._animate_scale.bind(self, Design.HOVER_SCALE, Design.HOVER_TIME))
	mouse_exited.connect(StyledButton._animate_scale.bind(self, 1.0, Design.HOVER_TIME))
	button_down.connect(StyledButton._animate_scale.bind(self, Design.PRESS_SCALE, Design.PRESS_TIME))
	button_up.connect(StyledButton._animate_scale.bind(self, 1.0, Design.PRESS_TIME))


func set_active(is_active: bool) -> void:
	_active = is_active
	if _locked:
		_apply_locked_style()
	else:
		_apply_normal_style()


func set_locked(locked: bool) -> void:
	_locked = locked
	disabled = locked
	if locked:
		_apply_locked_style()
	else:
		_apply_normal_style()


func _apply_normal_style() -> void:
	var bg := Design.FIVE if _active else Design.SIX
	var text_color := Design.WHITE if _active else Design.GRAY

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left     = Design.BUTTON_RADIUS
	sb.corner_radius_top_right    = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left  = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	add_theme_stylebox_override("normal",   sb)
	add_theme_stylebox_override("hover",    sb)
	add_theme_stylebox_override("pressed",  sb)
	add_theme_stylebox_override("focus",    sb)
	add_theme_stylebox_override("disabled", sb)

	var lbl := get_node_or_null("ToggleLabel") as Label
	if lbl:
		lbl.add_theme_color_override("font_color", text_color)


func _apply_locked_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Design.DISABLED
	sb.corner_radius_top_left     = Design.BUTTON_RADIUS
	sb.corner_radius_top_right    = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left  = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	add_theme_stylebox_override("normal",   sb)
	add_theme_stylebox_override("hover",    sb)
	add_theme_stylebox_override("pressed",  sb)
	add_theme_stylebox_override("focus",    sb)
	add_theme_stylebox_override("disabled", sb)

	var lbl := get_node_or_null("ToggleLabel") as Label
	if lbl:
		lbl.add_theme_color_override("font_color", Design.WHITE)
