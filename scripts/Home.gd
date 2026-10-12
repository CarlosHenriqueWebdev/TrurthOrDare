extends Control

var _header: AppHeader
var _footer: AppFooter
var _settings_modal: Modal


func _ready() -> void:
	_build()
	_connect_click_sounds(self)


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

	_header = AppHeader.create()
	_header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_header.settings_pressed.connect(_on_settings_pressed)
	add_child(_header)

	_footer = AppFooter.create([
		{"id": "preview", "text": "PREVIEW TRUTHS & DARES", "color": Design.PRIMARY, "icon": Design.ICON_SEARCH},
		{"id": "start",   "text": "START GAME",             "color": Design.SECONDARY},
	])
	_footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_footer.button_pressed.connect(_on_footer_button)
	add_child(_footer)

	_settings_modal = Modal.create()
	_settings_modal.set_content(_make_settings_content())
	add_child(_settings_modal)


# Recursively hook every Button's pressed signal to the click SFX.
# Centralized so UI components don't need to know about audio at all.
func _connect_click_sounds(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(AudioManager.play_click)
		_connect_click_sounds(child)


# =====================================================================
# FOOTER / HEADER HANDLERS
# =====================================================================
func _on_footer_button(id: String) -> void:
	match id:
		"preview":
			print("Preview pressed")
		"start":
			print("Start pressed")


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()


# =====================================================================
# SETTINGS CONTENT (goes inside the modal)
# =====================================================================
func _make_settings_content() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)

	# Title + close button row
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
	close_rect.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play_click()
			_settings_modal.close()
	)
	title_row.add_child(close_rect)

	col.add_child(_make_spacer(16))

	col.add_child(_make_section_label("Music"))
	col.add_child(_make_spacer(12))
	var music_tg := ToggleGroup.create(AudioManager.music_enabled)
	music_tg.changed.connect(func(is_on): AudioManager.set_music_enabled(is_on))
	col.add_child(music_tg)

	col.add_child(_make_spacer(16))

	col.add_child(_make_section_label("Sound Effect"))
	col.add_child(_make_spacer(12))
	var sfx_tg := ToggleGroup.create(AudioManager.sfx_enabled)
	sfx_tg.changed.connect(func(is_on): AudioManager.set_sfx_enabled(is_on))
	col.add_child(sfx_tg)

	col.add_child(_make_spacer(16))

	# Hidden until navigation to other screens exists.
	var back_btn := StyledButton.create("GO BACK TO MENU", Design.SECONDARY, Design.ICON_HOUSE)
	back_btn.pressed.connect(func(): _settings_modal.close())
	back_btn.visible = false
	col.add_child(back_btn)

	return col


func _make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, Design.FONT_SIZE_LABEL, Design.GRAY)
	return lbl


func _make_spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
