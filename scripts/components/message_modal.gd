class_name MessageModal extends Control

const TITLE := "MESSAGE BODY TO COPY"

var _modal: Modal
var _body_rich: RichTextLabel
var _text_content: String = ""


static func create() -> MessageModal:
	var m := MessageModal.new()
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
	col.add_child(_spacer(16))

	var body_box := BorderedBox.create(12)

	_body_rich = RichTextLabel.new()
	_body_rich.fit_content = true
	_body_rich.scroll_active = false
	_body_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_rich.custom_minimum_size = Vector2(0, 160)
	Design.apply_rich(_body_rich, 16, Design.WHITE)
	_body_rich.add_theme_constant_override("line_separation", 4)
	body_box.add_with_margins(_body_rich, 16, 16, 16, 16)
	col.add_child(body_box)

	col.add_child(_spacer(16))

	var copy_btn := StyledButton.create("COPY TO CLIPBOARD", Design.TERTIARY, Design.ICON_COPY)
	copy_btn.suppress_click_sound = true
	copy_btn.pressed.connect(_on_copy)
	col.add_child(copy_btn)

	_modal.set_content(col)


func show_message(text: String) -> void:
	_text_content = text
	if _body_rich:
		_body_rich.text = text
	_modal.open()


func _on_copy() -> void:
	# Strip BBCode for the clipboard so it pastes as plain text.
	var stripped := _strip_bbcode(_text_content)
	DisplayServer.clipboard_set(stripped)
	AudioManager.play_success()
	ToastManager.show_message("Copied to clipboard")


func _strip_bbcode(source: String) -> String:
	# Quick regex-ish strip: remove anything like [tag] or [tag=value].
	var out := ""
	var depth := 0
	for i in source.length():
		var c := source[i]
		if c == "[":
			depth += 1
		elif c == "]":
			if depth > 0:
				depth -= 1
		elif depth == 0:
			out += c
	return out


func _make_title_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = TITLE
	Design.apply_label(lbl, Design.FONT_SIZE_TITLE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

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
