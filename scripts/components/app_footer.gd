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

	# Floor: the footer is at least Design.FOOTER_HEIGHT tall so screens with
	# few buttons keep a consistent minimum, but it grows automatically when
	# more buttons are added (e.g. Home's CONTINUE GAME + NEW GAME + PREVIEW).
	custom_minimum_size.y = Design.FOOTER_HEIGHT

	for c in [Design.GLOBAL_CONTENT_BORDER, Design.BLACK, Design.INNER_BORDER]:
		add_child(AppHeader._make_line(c))

	# PanelContainer sizes to its content — no fixed height, no clipping.
	var content := PanelContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = Design.BLACK
	sb.content_margin_left   = Design.SIDE_PADDING
	sb.content_margin_right  = Design.SIDE_PADDING
	sb.content_margin_top    = Design.SIDE_PADDING
	sb.content_margin_bottom = Design.SIDE_PADDING
	content.add_theme_stylebox_override("panel", sb)
	add_child(content)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", Design.BUTTON_GAP)
	content.add_child(col)

	for cfg in buttons:
		var id: String = cfg.get("id", "")
		var text: String = cfg.get("text", "")
		var color: Color = cfg.get("color", Design.SECONDARY)
		var icon: String = cfg.get("icon", Design.ICON_CHEVRON)
		var hint: String = cfg.get("hint", "")

		# Optional hint label above the button. Used by Home's Continue
		# Game button to warn that Start Game discards the session.
		# No explicit spacer needed — the col's separation (BUTTON_GAP)
		# already puts 16px between this label and the button below it.
		if not hint.is_empty():
			var hint_lbl := Label.new()
			hint_lbl.text = hint
			hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			Design.apply_label(hint_lbl, 14, Design.ERROR_TEXT)
			col.add_child(hint_lbl)

		var btn := StyledButton.create(text, color, icon)
		btn.pressed.connect(func(): button_pressed.emit(id))
		col.add_child(btn)
		_buttons[id] = btn


func get_button(id: String) -> StyledButton:
	return _buttons.get(id)
