class_name PromptCard extends BorderedBox

signal copy_requested

const TEXT_FONT_SIZE := 28
const LINE_SPACING   := 4
const MAX_CHARS_ON_CARD := 110


static func make(kind: String, text: String) -> PromptCard:
	var c := PromptCard.new()
	c._build(18)

	var display_text := text
	var needs_view := false
	if text.length() > MAX_CHARS_ON_CARD:
		display_text = _truncate(text, MAX_CHARS_ON_CARD)
		needs_view = true

	c._build_prompt(kind, display_text, needs_view)
	return c


static func _truncate(text: String, max_len: int) -> String:
	var cut := text.substr(0, max_len)
	var last_space := cut.rfind(" ")
	if last_space > 20:
		cut = cut.substr(0, last_space)
	return cut + "..."


func _build_prompt(kind: String, text: String, show_view: bool) -> void:
	var title_path := Design.DARE_TITLE_PATH if kind == "dare" else Design.TRUTH_TITLE_PATH
	if ResourceLoader.exists(title_path):
		var title := TextureRect.new()
		title.texture = load(title_path)
		title.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title.custom_minimum_size = Vector2(0, 42)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_with_margins(title, 16, 16, 16, 0)
	else:
		var fallback := Label.new()
		fallback.text = kind.to_upper()
		Design.apply_label(fallback, 32)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_with_margins(fallback, 16, 16, 16, 0)

	add_spacer(16)
	add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
	add_spacer(16)

	var rich := RichTextLabel.new()
	rich.text = text
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Design.apply_rich(rich, TEXT_FONT_SIZE, Design.WHITE)
	rich.add_theme_constant_override("line_separation", LINE_SPACING)
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_with_margins(rich, 16, 0, 16, 16)

	if show_view:
		add_spacer(16)
		add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
		add_spacer(16)

		var btn := StyledButton.create("VIEW / COPY TEXT", Design.TERTIARY, Design.ICON_COPY, Design.BUTTON_HEIGHT, false, false, true)
		btn.pressed.connect(func(): copy_requested.emit())
		add_with_margins(btn, 16, 0, 16, 16)
