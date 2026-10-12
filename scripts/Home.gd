extends Control

const SFX_POOL_SIZE := 4

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index := 0
var settings_modal: Control

var music_enabled := true
var sfx_enabled := true


func _ready() -> void:
	_setup_audio()
	_build()
	_build_settings_modal()


# =====================================================================
# AUDIO  (temporarily local — moves to AudioManager in Step 3)
# =====================================================================
func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	if ResourceLoader.exists(Design.MUSIC_PATH):
		var stream := load(Design.MUSIC_PATH)
		if stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamOggVorbis:
			stream.loop = true
		music_player.stream = stream
		music_player.volume_db = -12.0
		add_child(music_player)
		music_player.play()
	else:
		push_warning("Music not found: " + Design.MUSIC_PATH)

	if ResourceLoader.exists(Design.SFX_CLICK_PATH):
		var sfx_stream := load(Design.SFX_CLICK_PATH)
		for i in SFX_POOL_SIZE:
			var p := AudioStreamPlayer.new()
			p.stream = sfx_stream
			p.volume_db = -6.0
			add_child(p)
			sfx_players.append(p)
	else:
		push_warning("Click SFX not found: " + Design.SFX_CLICK_PATH)


func _play_click() -> void:
	if not sfx_enabled or sfx_players.is_empty():
		return
	var p := sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % sfx_players.size()
	p.stop()
	p.play()


# =====================================================================
# BUILD
# =====================================================================
func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load(Design.BG_PATH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_header()
	_build_footer()


func _build_header() -> void:
	var wrapper := VBoxContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(wrapper)

	var content := Panel.new()
	content.custom_minimum_size = Vector2(0, Design.HEADER_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Design.BLACK
	content.add_theme_stylebox_override("panel", sb)
	wrapper.add_child(content)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_right", Design.SIDE_PADDING)
	content.add_child(margin)

	var row := HBoxContainer.new()
	margin.add_child(row)

	row.add_child(_make_settings_row())

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var logo := TextureRect.new()
	var logo_tex := load(Design.LOGO_PATH) as Texture2D
	if logo_tex:
		logo.texture = logo_tex
		var tex_size := logo_tex.get_size()
		var aspect := tex_size.x / tex_size.y
		logo.custom_minimum_size = Vector2(Design.HEADER_LOGO_H * aspect, Design.HEADER_LOGO_H)
	else:
		push_error("Logo failed to load: " + Design.LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(logo)

	for c in [Design.INNER_BORDER, Design.BLACK, Design.GLOBAL_CONTENT_BORDER]:
		wrapper.add_child(_make_h_line(c))


func _build_footer() -> void:
	var wrapper := VBoxContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wrapper.grow_vertical = Control.GROW_DIRECTION_BEGIN
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(wrapper)

	for c in [Design.GLOBAL_CONTENT_BORDER, Design.BLACK, Design.INNER_BORDER]:
		wrapper.add_child(_make_h_line(c))

	var content := Panel.new()
	content.custom_minimum_size = Vector2(0, Design.FOOTER_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Design.BLACK
	content.add_theme_stylebox_override("panel", sb)
	wrapper.add_child(content)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_right", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_top", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_bottom", Design.SIDE_PADDING)
	content.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", Design.BUTTON_GAP)
	margin.add_child(col)

	col.add_child(_make_button("PREVIEW TRUTHS & DARES", Design.PRIMARY, Design.ICON_SEARCH))
	col.add_child(_make_button("START GAME", Design.SECONDARY))


func _make_h_line(c: Color) -> ColorRect:
	var line := ColorRect.new()
	line.color = c
	line.custom_minimum_size = Vector2(0, Design.BORDER_LINE_H)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _make_spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


# =====================================================================
# REUSABLE: icon + text row
# =====================================================================
func _make_icon_text_component(icon_path: String, text: String, font_size: int = Design.FONT_SIZE_LABEL) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var icon := TextureRect.new()
	var icon_tex := load(icon_path)
	if icon_tex:
		icon.texture = icon_tex
	else:
		push_error("Icon failed to load: " + icon_path)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, font_size)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)

	return row


func _make_settings_row() -> HBoxContainer:
	var row := _make_icon_text_component(Design.ICON_COG, "SETTINGS")
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(_on_settings_input)
	row.resized.connect(func(): row.pivot_offset = row.size / 2)
	row.mouse_entered.connect(_animate_scale.bind(row, Design.HOVER_SCALE, Design.HOVER_TIME))
	row.mouse_exited.connect(_animate_scale.bind(row, 1.0, Design.HOVER_TIME))
	return row


func _on_settings_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_click()
		_open_settings()


# =====================================================================
# BUTTON FACTORY
# =====================================================================
func _make_button(text: String, bg_color: Color, icon_path: String = Design.ICON_CHEVRON) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, Design.BUTTON_HEIGHT)
	btn.focus_mode = Control.FOCUS_NONE

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left = Design.BUTTON_RADIUS
	sb.corner_radius_top_right = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)

	var border_panel := Panel.new()
	border_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.draw_center = false
	bsb.border_width_left = Design.BUTTON_BORDER_W
	bsb.border_width_top = Design.BUTTON_BORDER_W
	bsb.border_width_right = Design.BUTTON_BORDER_W
	bsb.border_width_bottom = Design.BUTTON_BORDER_W
	bsb.border_color = Design.BUTTON_BORDER
	bsb.corner_radius_top_left = Design.BUTTON_RADIUS
	bsb.corner_radius_top_right = Design.BUTTON_RADIUS
	bsb.corner_radius_bottom_left = Design.BUTTON_RADIUS
	bsb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	border_panel.add_theme_stylebox_override("panel", bsb)
	btn.add_child(border_panel)

	var overlay := MarginContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_constant_override("margin_left", Design.BUTTON_PADDING_H)
	overlay.add_theme_constant_override("margin_right", Design.BUTTON_PADDING_H)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(overlay)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(row)

	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, Design.FONT_SIZE_BTN)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)

	var icon := TextureRect.new()
	var icon_tex := load(icon_path)
	if icon_tex:
		icon.texture = icon_tex
	else:
		push_error("Icon failed to load: " + icon_path)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2)
	btn.mouse_entered.connect(_animate_scale.bind(btn, Design.HOVER_SCALE, Design.HOVER_TIME))
	btn.mouse_exited.connect(_animate_scale.bind(btn, 1.0, Design.HOVER_TIME))
	btn.button_down.connect(_animate_scale.bind(btn, Design.PRESS_SCALE, Design.PRESS_TIME))
	btn.button_up.connect(_animate_scale.bind(btn, 1.0, Design.PRESS_TIME))
	btn.pressed.connect(_play_click)

	return btn


func _animate_scale(node: Control, target: float, time: float) -> void:
	if not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(target, target), time)


# =====================================================================
# TOGGLE GROUP
# =====================================================================
func _make_toggle_button(text: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, Design.BUTTON_HEIGHT)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE

	var border_panel := Panel.new()
	border_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.draw_center = false
	bsb.border_width_left = Design.BUTTON_BORDER_W
	bsb.border_width_top = Design.BUTTON_BORDER_W
	bsb.border_width_right = Design.BUTTON_BORDER_W
	bsb.border_width_bottom = Design.BUTTON_BORDER_W
	bsb.border_color = Design.BUTTON_BORDER
	bsb.corner_radius_top_left = Design.BUTTON_RADIUS
	bsb.corner_radius_top_right = Design.BUTTON_RADIUS
	bsb.corner_radius_bottom_left = Design.BUTTON_RADIUS
	bsb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	border_panel.add_theme_stylebox_override("panel", bsb)
	btn.add_child(border_panel)

	var lbl := Label.new()
	lbl.text = text
	lbl.name = "ToggleLabel"
	Design.apply_label(lbl, Design.FONT_SIZE_BTN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2)
	btn.mouse_entered.connect(_animate_scale.bind(btn, Design.HOVER_SCALE, Design.HOVER_TIME))
	btn.mouse_exited.connect(_animate_scale.bind(btn, 1.0, Design.HOVER_TIME))
	btn.button_down.connect(_animate_scale.bind(btn, Design.PRESS_SCALE, Design.PRESS_TIME))
	btn.button_up.connect(_animate_scale.bind(btn, 1.0, Design.PRESS_TIME))

	return btn


func _style_toggle_button(btn: Button, is_active: bool) -> void:
	var bg_color := Design.FIVE if is_active else Design.SIX
	var text_color := Design.WHITE if is_active else Design.GRAY

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left = Design.BUTTON_RADIUS
	sb.corner_radius_top_right = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_left = Design.BUTTON_RADIUS
	sb.corner_radius_bottom_right = Design.BUTTON_RADIUS
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)

	var lbl := btn.get_node_or_null("ToggleLabel") as Label
	if lbl:
		lbl.add_theme_color_override("font_color", text_color)


func _make_toggle_group(initial: bool, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var off_btn := _make_toggle_button("TURN OFF")
	var on_btn := _make_toggle_button("TURN ON")
	row.add_child(off_btn)
	row.add_child(on_btn)

	var update := func(is_on: bool) -> void:
		_style_toggle_button(off_btn, not is_on)
		_style_toggle_button(on_btn, is_on)

	off_btn.pressed.connect(func():
		update.call(false)
		on_change.call(false)
		_play_click()
	)
	on_btn.pressed.connect(func():
		update.call(true)
		on_change.call(true)
		_play_click()
	)

	update.call(initial)
	return row


# =====================================================================
# SETTINGS MODAL
# =====================================================================
func _build_settings_modal() -> void:
	settings_modal = Control.new()
	settings_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_modal.visible = false
	settings_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_modal.z_index = 100
	add_child(settings_modal)

	var dimmer := ColorRect.new()
	dimmer.color = Color(10 / 255.0, 10 / 255.0, 10 / 255.0, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(_on_dimmer_input)
	settings_modal.add_child(dimmer)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_END
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_modal.add_child(outer)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	outer.add_child(wrapper)

	for c in [Design.GLOBAL_CONTENT_BORDER, Design.BLACK, Design.INNER_BORDER]:
		wrapper.add_child(_make_h_line(c))

	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Design.BLACK
	panel.add_theme_stylebox_override("panel", psb)
	wrapper.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_right", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_top", Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_bottom", Design.SIDE_PADDING)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	margin.add_child(col)

	var title_row := HBoxContainer.new()
	col.add_child(title_row)

	var title := Label.new()
	title.text = "SETTINGS"
	Design.apply_label(title, Design.FONT_SIZE_TITLE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)

	var close_rect := TextureRect.new()
	var close_tex := load(Design.ICON_CLOSE)
	if close_tex:
		close_rect.texture = close_tex
	else:
		push_error("Close icon missing: " + Design.ICON_CLOSE)
	close_rect.custom_minimum_size = Vector2(16, 16)
	close_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	close_rect.gui_input.connect(_on_close_icon_input)
	title_row.add_child(close_rect)

	col.add_child(_make_spacer(16))

	var music_lbl := Label.new()
	music_lbl.text = "Music"
	Design.apply_label(music_lbl, Design.FONT_SIZE_LABEL, Design.GRAY)
	col.add_child(music_lbl)

	col.add_child(_make_spacer(12))

	var music_toggle := _make_toggle_group(music_enabled, _on_music_toggle)
	col.add_child(music_toggle)

	col.add_child(_make_spacer(16))

	var sfx_lbl := Label.new()
	sfx_lbl.text = "Sound Effect"
	Design.apply_label(sfx_lbl, Design.FONT_SIZE_LABEL, Design.GRAY)
	col.add_child(sfx_lbl)

	col.add_child(_make_spacer(12))

	var sfx_toggle := _make_toggle_group(sfx_enabled, _on_sfx_toggle)
	col.add_child(sfx_toggle)

	col.add_child(_make_spacer(16))

	# Hidden until navigation to other screens exists.
	var back_btn := _make_button("GO BACK TO MENU", Design.SECONDARY, Design.ICON_HOUSE)
	back_btn.pressed.connect(_on_back_to_menu)
	back_btn.visible = false
	col.add_child(back_btn)


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_settings()


func _on_close_icon_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_click()
		_close_settings()


func _on_back_to_menu() -> void:
	_close_settings()


func _on_music_toggle(is_on: bool) -> void:
	music_enabled = is_on
	if music_player:
		music_player.stream_paused = not is_on


func _on_sfx_toggle(is_on: bool) -> void:
	sfx_enabled = is_on


func _open_settings() -> void:
	settings_modal.visible = true
	settings_modal.modulate.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(settings_modal, "modulate:a", 1.0, 0.2)


func _close_settings() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(settings_modal, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): settings_modal.visible = false)
