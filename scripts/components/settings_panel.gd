class_name SettingsPanel extends VBoxContainer

# Settings content column — title, close button, music/SFX toggles.
# Emits `close_requested` when the user taps the X. The host screen
# connects that to whatever "close" means in context (e.g. Modal.close).
#
# Usage:
#   var panel := SettingsPanel.create()
#   panel.close_requested.connect(_settings_modal.close)
#   _settings_modal.set_content(panel)

signal close_requested


static func create() -> SettingsPanel:
	var p := SettingsPanel.new()
	p._build()
	return p


func _build() -> void:
	add_theme_constant_override("separation", 0)

	# --- Title row: SETTINGS + X ---
	var title_row := HBoxContainer.new()
	add_child(title_row)

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
	close_rect.gui_input.connect(_on_close_input)
	title_row.add_child(close_rect)

	add_child(_make_spacer(16))

	# --- Music ---
	add_child(_make_section_label("Music"))
	add_child(_make_spacer(12))
	var music_tg := ToggleGroup.create(AudioManager.music_enabled)
	music_tg.changed.connect(func(is_on): AudioManager.set_music_enabled(is_on))
	add_child(music_tg)

	add_child(_make_spacer(16))

	# --- Sound Effect ---
	add_child(_make_section_label("Sound Effect"))
	add_child(_make_spacer(12))
	var sfx_tg := ToggleGroup.create(AudioManager.sfx_enabled)
	sfx_tg.changed.connect(func(is_on): AudioManager.set_sfx_enabled(is_on))
	add_child(sfx_tg)

	add_child(_make_spacer(16))

	# Hidden until navigation exists — will be re-enabled per screen that
	# needs a "back to menu" affordance inside settings.
	var back_btn := StyledButton.create("GO BACK TO MENU", Design.SECONDARY, Design.ICON_HOUSE)
	back_btn.pressed.connect(func(): close_requested.emit())
	back_btn.visible = false
	add_child(back_btn)


func _on_close_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_click()
		close_requested.emit()


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
