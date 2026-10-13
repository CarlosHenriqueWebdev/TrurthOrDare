class_name PreviewCard extends BorderedBox

# Card shown in the Preview screen: title image, quoted prompt, divider,
# category badge pinned to the bottom-left.

const CARD_HEIGHT := 356
const TITLE_WIDTH := 152
const TITLE_HEIGHT := 42


static func make(kind: String, text: String, category: String) -> PreviewCard:
	var c := PreviewCard.new()
	c._build(18)
	c.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	c._build_card(kind, text, category)
	return c


func _build_card(kind: String, text: String, category: String) -> void:
	# Title image (no side lines, left-aligned)
	var title_path := Design.DARE_PREVIEW_TITLE_PATH if kind == "dare" else Design.TRUTH_PREVIEW_TITLE_PATH
	if ResourceLoader.exists(title_path):
		var title := TextureRect.new()
		title.texture = load(title_path)
		title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title.custom_minimum_size = Vector2(TITLE_WIDTH, TITLE_HEIGHT)
		title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_with_margins(title, 16, 16, 16, 0)
	else:
		var fallback := Label.new()
		fallback.text = kind.to_upper()
		Design.apply_label(fallback, 28)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_with_margins(fallback, 16, 16, 16, 0)

	add_spacer(12)

	# Quoted prompt (markup-aware, left-aligned)
	var rich := RichTextLabel.new()
	rich.text = "\u201c" + text + "\u201d"
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	Design.apply_rich(rich, 24, Design.WHITE)
	rich.add_theme_constant_override("line_separation", 4)
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_with_margins(rich, 16, 0, 16, 0)

	# Expanding filler so the divider + badge stick to the bottom.
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(filler)

	# Divider + badge at the bottom
	add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
	add_with_margins(CategoryBadge.create(category), 16, 16, 16, 16)
