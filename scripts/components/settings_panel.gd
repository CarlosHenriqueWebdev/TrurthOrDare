class_name SettingsPanel extends VBoxContainer

# Settings content. Emits `close_requested` when the user taps X, and
# `back_to_menu_requested` when the optional return button is tapped.
#
# Pass show_back_to_menu = true on screens where returning to the main menu
# is meaningful (i.e. anywhere except Home).

signal close_requested
signal back_to_menu_requested


static func create(show_back_to_menu := false) -> SettingsPanel:
	var p := SettingsPanel.new()
	p._build(show_back_to_menu)
	return p


func _build(show_back_to_menu: bool) -> void:
	add_theme_constant_override("separation", 0)

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

	add_child(_make_section_label("Music"))
	add_child(_make_spacer(12))
	var music_tg := ToggleGroup.create(AudioManager.music_enabled)
	music_tg.changed.connect(func(is_on): AudioManager.set_music_enabled(is_on))
	add_child(music_tg)

	add_child(_make_spacer(16))

	add_child(_make_section_label("Sound Effect"))
	add_child(_make_spacer(12))
	var sfx_tg := ToggleGroup.create(AudioManager.sfx_enabled)
	sfx_tg.changed.connect(func(is_on): AudioManager.set_sfx_enabled(is_on))
	add_child(sfx_tg)

	if show_back_to_menu:
		add_child(_make_spacer(16))
		var back_btn := StyledButton.create("GO BACK TO MENU", Design.TERTIARY, Design.ICON_HOUSE)
		back_btn.pressed.connect(func(): back_to_menu_requested.emit())
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
