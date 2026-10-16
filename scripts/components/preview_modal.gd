class_name PreviewModal extends Control

# Modal that lists every card in the current pool.
# Truths first, then dares, each rendered as a PreviewCard.
# Opens from Home's PREVIEW button.
#
# The card list is rebuilt every time open() is called, so uploads and
# clears in the Settings modal are reflected immediately.

# Caps the modal's overall height. Individual cards hug their own content,
# so this just limits how tall the scroll window can get.
const SCROLL_MAX_HEIGHT := 600

var _modal: Modal
var _cards_col: VBoxContainer
var _count_label: Label


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

	# Card count label — kept as a member so _populate() can update it.
	_count_label = Label.new()
	Design.apply_label(_count_label, 10, Design.GRAY)
	col.add_child(_count_label)

	col.add_child(_spacer(12))

	# Scrollable card list — the container itself stays, only children
	# are rebuilt in _populate().
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, SCROLL_MAX_HEIGHT)
	col.add_child(scroll)

	_cards_col = VBoxContainer.new()
	_cards_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_col.add_theme_constant_override("separation", 16)
	scroll.add_child(_cards_col)

	_modal.set_content(col)
	UiUtils.make_scroll_friendly(self)


# Rebuild the card list from whatever DataManager currently holds.
func _populate() -> void:
	# Clear previous cards.
	for child in _cards_col.get_children():
		_cards_col.remove_child(child)
		child.queue_free()

	var total := DataManager.truths.size() + DataManager.dares.size()
	_count_label.text = "Truth and Dare Amount: %d" % total

	for entry in DataManager.truths:
		_cards_col.add_child(PreviewCard.make(
			"truth",
			entry.get("text", ""),
			entry.get("category", "sober")
		))

	for entry in DataManager.dares:
		_cards_col.add_child(PreviewCard.make(
			"dare",
			entry.get("text", ""),
			entry.get("category", "sober")
		))


func open() -> void:
	_populate()
	# _populate rebuilds the card list; walk the tree again so the fresh
	# PreviewCards don't block the scroll drag on mobile.
	UiUtils.make_scroll_friendly(self)
	_modal.open()


func _make_title_row() -> HBoxContainer:
	var row := HBoxContainer.new()

	var title := Label.new()
	title.text = "PREVIEW TRUTH AND DARE"
	Design.apply_label(title, Design.FONT_SIZE_TITLE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var close := CloseButton.create()
	close.pressed.connect(_modal.close)
	row.add_child(close)
	return row


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
