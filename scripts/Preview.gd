extends Control

const CONTENT_SIDE_PAD := 16
const SECTION_GAP      := 16
const CARD_GAP         := 16

var _settings_modal: Modal


func _ready() -> void:
	_build()
	_connect_click_sounds(self)


func _connect_click_sounds(node: Node) -> void:
	for child in node.get_children():
		if child is StyledButton:
			if not child.suppress_click_sound:
				child.pressed.connect(AudioManager.play_click)
		elif child is Button:
			child.pressed.connect(AudioManager.play_click)
		_connect_click_sounds(child)


func _build() -> void:
	_build_background()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := AppHeader.create()
	header.settings_pressed.connect(_on_settings_pressed)
	root.add_child(header)

	root.add_child(_spacer(SECTION_GAP))

	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left",  CONTENT_SIDE_PAD)
	content_margin.add_theme_constant_override("margin_right", CONTENT_SIDE_PAD)
	root.add_child(content_margin)

	var content_col := VBoxContainer.new()
	content_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_col.add_theme_constant_override("separation", 4)
	content_margin.add_child(content_col)

	# Title
	var title := Label.new()
	title.text = "PREVIEW TRUTH AND DARE"
	Design.apply_label(title, Design.FONT_SIZE_TITLE, Design.WHITE)
	content_col.add_child(title)

	# Card count (gray, small — same style as Settings labels)
	var total := DataManager.truths.size() + DataManager.dares.size()
	var count_label := Label.new()
	count_label.text = "Truth and Dare Amount: %d" % total
	Design.apply_label(count_label, 10, Design.GRAY)
	content_col.add_child(count_label)

	content_col.add_child(_spacer(12))

	# Scrollable card list
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_col.add_child(scroll)

	var cards_col := VBoxContainer.new()
	cards_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_col.add_theme_constant_override("separation", CARD_GAP)
	scroll.add_child(cards_col)

	for entry in DataManager.truths:
		cards_col.add_child(PreviewCard.make(
			"truth",
			entry.get("text", ""),
			entry.get("category", "sober")
		))

	for entry in DataManager.dares:
		cards_col.add_child(PreviewCard.make(
			"dare",
			entry.get("text", ""),
			entry.get("category", "sober")
		))

	root.add_child(_spacer(SECTION_GAP))

	var footer := AppFooter.create([
		{"id": "back", "text": "RETURN TO MENU", "color": Design.PRIMARY, "icon": Design.ICON_HOUSE},
	])
	footer.button_pressed.connect(_on_footer_button)
	root.add_child(footer)

	_settings_modal = Modal.create()
	var settings_panel := SettingsPanel.create(true)
	settings_panel.close_requested.connect(_settings_modal.close)
	settings_panel.back_to_menu_requested.connect(_on_back_to_menu)
	_settings_modal.set_content(settings_panel)
	add_child(_settings_modal)


func _build_background() -> void:
	var c := ColorRect.new()
	c.color = Design.BLACK
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)


func _on_footer_button(id: String) -> void:
	if id == "back":
		Navigation.go_home()


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()


func _on_back_to_menu() -> void:
	_settings_modal.close()
	Navigation.go_home()


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
