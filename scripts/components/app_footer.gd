class_name AppFooter extends VBoxContainer

# Bottom action bar. Buttons declared via config array; emits `button_pressed(id)`.
# Config entry: {"id": String, "text": String, "color": Color, "icon": String (optional)}
# Reach a button with get_button(id) to toggle its disabled state.

signal button_pressed(id: String)

var _buttons: Dictionary = {}


static func create(buttons: Array) -> AppFooter:
	var f := AppFooter.new()
	f._build(buttons)
	return f


func _build(buttons: Array) -> void:
	add_theme_constant_override("separation", 0)
	mouse_filter = Control.MOUSE_FILTER_PASS

	for c in [Design.GLOBAL_CONTENT_BORDER, Design.BLACK, Design.INNER_BORDER]:
		add_child(AppHeader._make_line(c))

	var content := Panel.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.custom_minimum_size = Vector2(0, Design.FOOTER_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Design.BLACK
	content.add_theme_stylebox_override("panel", sb)
	add_child(content)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_right",  Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_top",    Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_bottom", Design.SIDE_PADDING)
	content.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", Design.BUTTON_GAP)
	margin.add_child(col)

	for cfg in buttons:
		var id: String = cfg.get("id", "")
		var text: String = cfg.get("text", "")
		var color: Color = cfg.get("color", Design.SECONDARY)
		var icon: String = cfg.get("icon", Design.ICON_CHEVRON)
		var btn := StyledButton.create(text, color, icon)
		btn.pressed.connect(func(): button_pressed.emit(id))
		col.add_child(btn)
		_buttons[id] = btn


func get_button(id: String) -> StyledButton:
	return _buttons.get(id)
