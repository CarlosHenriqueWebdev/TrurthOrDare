class_name AppHeader extends VBoxContainer

# Top app bar. Settings on the left, logo on the right.
# Emits `settings_pressed` when the settings row is tapped.

signal settings_pressed
signal logo_pressed


static func create() -> AppHeader:
	var h := AppHeader.new()
	h._build()
	return h


func _build() -> void:
	add_theme_constant_override("separation", 0)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var panel := Panel.new()
	# STOP so the header absorbs clicks across its full rect. Without this,
	# content bleeding up from a scroll below sits behind the header
	# visually but still receives clicks, blocking the settings/logo inputs.
	# Marked preserve_mouse_filter so UiUtils.make_scroll_friendly skips it.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("preserve_mouse_filter", true)
	panel.custom_minimum_size = Vector2(0, Design.HEADER_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Design.BLACK
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_right", Design.SIDE_PADDING)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	margin.add_child(row)

	var settings_row := IconTextRow.create(Design.ICON_COG, "SETTINGS", Design.FONT_SIZE_LABEL, true)
	settings_row.clicked.connect(func(): settings_pressed.emit())
	row.add_child(settings_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var logo := _make_logo()
	UiUtils.make_clickable(logo, func(): logo_pressed.emit())
	row.add_child(logo)

	for c in [Design.INNER_BORDER, Design.BLACK, Design.GLOBAL_CONTENT_BORDER]:
		add_child(_make_line(c))


static func _make_logo() -> TextureRect:
	var logo := TextureRect.new()
	var tex := load(Design.LOGO_PATH) as Texture2D
	if tex:
		logo.texture = tex
		var aspect := tex.get_size().x / tex.get_size().y
		logo.custom_minimum_size = Vector2(Design.HEADER_LOGO_H * aspect, Design.HEADER_LOGO_H)
	else:
		push_error("Logo failed to load: " + Design.LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return logo


static func _make_line(c: Color) -> ColorRect:
	var line := ColorRect.new()
	line.color = c
	line.custom_minimum_size = Vector2(0, Design.BORDER_LINE_H)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
