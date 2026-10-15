class_name SettingsPanel extends VBoxContainer

signal close_requested
signal back_to_menu_requested


static func create(show_back_to_menu := false, lock_endless := false, lock_csv := false) -> SettingsPanel:
	var p := SettingsPanel.new()
	p._build(show_back_to_menu, lock_endless, lock_csv)
	return p


func _build(show_back_to_menu: bool, lock_endless: bool, lock_csv: bool) -> void:
	add_theme_constant_override("separation", 0)

	# Title row
	var title_row := HBoxContainer.new()
	add_child(title_row)

	var title := Label.new()
	title.text = "SETTINGS"
	Design.apply_label(title, Design.FONT_SIZE_TITLE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)

	var close_btn := CloseButton.create()
	close_btn.pressed.connect(func(): close_requested.emit())
	title_row.add_child(close_btn)

	add_child(_make_spacer(16))

	# Music
	add_child(_make_section_label("Music"))
	add_child(_make_spacer(12))
	var music_tg := ToggleGroup.create(AudioManager.music_enabled)
	music_tg.changed.connect(func(is_on): AudioManager.set_music_enabled(is_on))
	add_child(music_tg)

	add_child(_make_spacer(16))

	# Sound Effect
	add_child(_make_section_label("Sound Effect"))
	add_child(_make_spacer(12))
	var sfx_tg := ToggleGroup.create(AudioManager.sfx_enabled)
	sfx_tg.changed.connect(func(is_on): AudioManager.set_sfx_enabled(is_on))
	add_child(sfx_tg)

	add_child(_make_spacer(16))

	# Endless Mode
	var endless_label_text := "Endless Mode (match goes on forever)"
	if lock_endless:
		endless_label_text = "Endless Mode (change in main menu)"
	add_child(_make_section_label(endless_label_text))
	add_child(_make_spacer(12))
	var endless_tg := ToggleGroup.create(SaveManager.get_endless_mode())
	endless_tg.changed.connect(func(is_on): SaveManager.set_endless_mode(is_on))
	if lock_endless:
		endless_tg.set_locked(true)
	add_child(endless_tg)

	add_child(_make_spacer(16))

	# CSV Upload section
	add_child(_make_spacer(16))
	add_child(CsvUploadSection.create(lock_csv))

	# Back to menu
	if show_back_to_menu:
		add_child(_make_spacer(20))
		var back_btn := StyledButton.create("RETURN TO MENU", Design.SECONDARY, Design.ICON_HOUSE)
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
