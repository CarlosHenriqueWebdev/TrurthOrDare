class_name PreviewModal extends Control

# Modal that lists every card in the current pool.
# Truths first, then dares, each rendered as a PreviewCard.
# Opens from Home's PREVIEW button.

const SCROLL_MAX_HEIGHT := 560

var _modal: Modal


static func create() -> PreviewModal:
	var m := PreviewModal.new()
	m._build()
	return m


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_modal = Modal.create()
	add_child(_modal)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)

	col.add_child(_make_title_row())
	col.add_child(_spacer(8))

	# Card count (small gray, same style as Settings section labels)
	var total := DataManager.truths.size() + DataManager.dares.size()
	var count_label := Label.new()
	count_label.text = "Truth and Dare Amount: %d" % total
	Design.apply_label(count_label, 10, Design.GRAY)
	col.add_child(count_label)

	col.add_child(_spacer(12))

	# Scrollable card list
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, SCROLL_MAX_HEIGHT)
	col.add_child(scroll)

	var cards_col := VBoxContainer.new()
	cards_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_col.add_theme_constant_override("separation", 16)
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

	_modal.set_content(col)


func open() -> void:
	_modal.open()


func _make_title_row() -> HBoxContainer:
	var row := HBoxContainer.new()

	var title := Label.new()
	title.text = "PREVIEW TRUTH AND DARE"
	Design.apply_label(title, Design.FONT_SIZE_TITLE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var close := TextureRect.new()
	var tex := load(Design.ICON_CLOSE)
	if tex:
		close.texture = tex
	else:
		push_error("Close icon missing")
	close.custom_minimum_size = Vector2(16, 16)
	close.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.modulate = Design.ERROR_TEXT
	close.mouse_filter = Control.MOUSE_FILTER_STOP
	close.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play_click()
			_modal.close()
	)
	row.add_child(close)
	return row


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
