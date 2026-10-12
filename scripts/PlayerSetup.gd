extends Control

const MAX_PLAYERS := 8
const NAME_MAX_LENGTH := 16
const CONTENT_SIDE_PAD := 16
const SECTION_GAP := 16

var _players: Array[String] = []

var _name_input: LineEdit
var _add_player_btn: StyledButton
var _player_rows_container: VBoxContainer
var _player_list_box: BorderedBox
var _randomize_btn: StyledButton
var _start_btn: StyledButton
var _settings_modal: Modal
var _add_error := false
var _hint_label: Label
var _player_count_label: Label


func _ready() -> void:
	_build()
	_connect_click_sounds(self)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _name_input and _name_input.has_focus():
			_name_input.release_focus()


func _connect_click_sounds(node: Node) -> void:
	for child in node.get_children():
		if child is StyledButton:
			if not child.suppress_click_sound:
				child.pressed.connect(AudioManager.play_click)
		elif child is Button:
			child.pressed.connect(AudioManager.play_click)
		_connect_click_sounds(child)


# =====================================================================
# BUILD
# =====================================================================
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

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left",  CONTENT_SIDE_PAD)
	content_margin.add_theme_constant_override("margin_right", CONTENT_SIDE_PAD)
	scroll.add_child(content_margin)

	var content_col := VBoxContainer.new()
	content_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_col.add_theme_constant_override("separation", SECTION_GAP)
	content_margin.add_child(content_col)

	content_col.add_child(_build_add_player_box())
	content_col.add_child(_build_player_list_box())
	content_col.add_child(_spacer(24))

	root.add_child(_spacer(SECTION_GAP))

	var footer := AppFooter.create([
		{"id": "randomize", "text": "RANDOMIZE PLAYER ORDER", "color": Design.PRIMARY, "icon": Design.ICON_DICE},
		{"id": "start",     "text": "START GAME",             "color": Design.SECONDARY},
	])
	footer.button_pressed.connect(_on_footer_button)
	root.add_child(footer)

	_randomize_btn = footer.get_button("randomize")
	_start_btn     = footer.get_button("start")
	if _randomize_btn:
		_randomize_btn.suppress_click_sound = true

	_settings_modal = Modal.create()
	var settings_panel := SettingsPanel.create(true)
	settings_panel.close_requested.connect(_settings_modal.close)
	settings_panel.back_to_menu_requested.connect(_on_back_to_menu)
	_settings_modal.set_content(settings_panel)
	add_child(_settings_modal)


func _build_background() -> void:
	if ResourceLoader.exists(Design.PLAYER_BG_PATH):
		var bg := TextureRect.new()
		bg.texture = load(Design.PLAYER_BG_PATH)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = Design.BLACK
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)


func _build_add_player_box() -> BorderedBox:
	var box := BorderedBox.create()

	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = "ADD PLAYERS"
	Design.apply_label(title, Design.FONT_SIZE_TITLE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)

	var t_spacer := Control.new()
	t_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(t_spacer)

	_hint_label = Label.new()
	_hint_label.text = "Enter at least 2 players"
	Design.apply_label(_hint_label, 10, Design.TERTIARY)
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(_hint_label)

	box.add_with_margins(title_row, 16, 16, 16, 0)

	box.add_spacer(16)
	box.add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
	box.add_spacer(16)

	var input_col := VBoxContainer.new()
	input_col.add_theme_constant_override("separation", 8)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 12)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Player Name..."
	_name_input.max_length = NAME_MAX_LENGTH
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_line_edit_bare(_name_input)
	_name_input.text_submitted.connect(_on_name_submitted)
	_name_input.text_changed.connect(_on_name_changed)
	_name_input.focus_entered.connect(_on_input_focus)
	_name_input.focus_exited.connect(_on_input_blur)
	input_row.add_child(_name_input)

	_add_player_btn = StyledButton.create("ADD PLAYER", Design.FIVE, Design.ICON_SEND, 32, true, true)
	_add_player_btn.suppress_click_sound = true
	_add_player_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_add_player_btn.pressed.connect(_on_add_player)
	input_row.add_child(_add_player_btn)

	input_col.add_child(input_row)

	var underline := ColorRect.new()
	underline.color = Design.GRAY
	underline.custom_minimum_size = Vector2(0, 2)
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_col.add_child(underline)

	box.add_with_margins(input_col, 16, 0, 16, 16)

	return box


func _build_player_list_box() -> BorderedBox:
	_player_list_box = BorderedBox.create()

	var title_row := HBoxContainer.new()

	var title := Label.new()
	title.text = "PLAYER LIST"
	Design.apply_label(title, 12)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)

	var t_spacer := Control.new()
	t_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(t_spacer)

	_player_count_label = Label.new()
	_player_count_label.text = "0 / %d" % MAX_PLAYERS
	Design.apply_label(_player_count_label, 10, Design.GRAY)
	_player_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(_player_count_label)

	_player_list_box.add_with_margins(title_row, 16, 16, 16, 0)

	_player_list_box.add_spacer(16)
	_player_list_box.add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))

	_player_rows_container = VBoxContainer.new()
	_player_rows_container.add_theme_constant_override("separation", 0)
	_player_list_box.add_full(_player_rows_container)

	return _player_list_box


# =====================================================================
# STATE
# =====================================================================
func _refresh() -> void:
	_rebuild_player_rows()
	_update_controls()
	if _player_list_box:
		_player_list_box.visible = not _players.is_empty()


func _rebuild_player_rows() -> void:
	for child in _player_rows_container.get_children():
		child.queue_free()

	for i in _players.size():
		var row_wrap := MarginContainer.new()
		row_wrap.add_theme_constant_override("margin_left",  16)
		row_wrap.add_theme_constant_override("margin_right", 16)

		var row := PlayerRow.create(_players[i], i + 1)
		row.remove_requested.connect(_on_remove_player.bind(i))
		row_wrap.add_child(row)
		_player_rows_container.add_child(row_wrap)

		if i < _players.size() - 1:
			_player_rows_container.add_child(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))

	# No trailing spacer — the box's bottom edge sits right under the last row.


func _update_controls() -> void:
	var at_max := _players.size() >= MAX_PLAYERS
	var enough := _players.size() >= 2

	if _add_player_btn:
		_add_player_btn.set_disabled_visual(at_max)
	if _name_input:
		_name_input.editable = not at_max
	if _randomize_btn:
		_randomize_btn.set_disabled_visual(not enough)
	if _start_btn:
		_start_btn.set_disabled_visual(not enough)

	if _hint_label:
		_hint_label.add_theme_color_override(
			"font_color",
			Design.GLOBAL_CONTENT_BORDER if enough else Design.TERTIARY
		)
	if _player_count_label:
		_player_count_label.text = "%d / %d" % [_players.size(), MAX_PLAYERS]


func _refresh_add_button_color() -> void:
	if _add_player_btn:
		var color := Design.TERTIARY if _add_error else Design.FIVE
		_add_player_btn.set_bg_color(color)


# =====================================================================
# INPUT FOCUS
# =====================================================================
func _on_input_focus() -> void:
	_name_input.placeholder_text = ""

func _on_input_blur() -> void:
	if _name_input.text.is_empty():
		_name_input.placeholder_text = "Player Name..."


# =====================================================================
# ACTIONS
# =====================================================================
func _on_name_submitted(_text: String) -> void:
	_on_add_player()

func _on_name_changed(_text: String) -> void:
	if _add_error:
		_add_error = false
		_refresh_add_button_color()


func _on_add_player() -> void:
	if _players.size() >= MAX_PLAYERS:
		_show_add_error("Player limit reached")
		return
	var raw := _name_input.text.strip_edges()
	if raw.is_empty():
		_show_add_error("Enter a player name")
		return
	if not _starts_with_letter(raw):
		_show_add_error("Name must start with a letter")
		return
	if raw.length() > NAME_MAX_LENGTH:
		_show_add_error("Name too long (max %d)" % NAME_MAX_LENGTH)
		return
	for p in _players:
		if p.to_lower() == raw.to_lower():
			_show_add_error("Player already added")
			return

	_players.append(_format_name(raw))
	_name_input.text = ""
	_name_input.grab_focus()
	_add_error = false
	_refresh_add_button_color()
	_refresh()
	AudioManager.play_success()
	ToastManager.show_message("Added " + raw)


func _on_remove_player(index: int) -> void:
	if index < 0 or index >= _players.size():
		return
	var removed := _players[index]
	_players.remove_at(index)
	_refresh()
	AudioManager.play_success()
	ToastManager.show_message("Removed " + removed)


func _on_footer_button(id: String) -> void:
	match id:
		"randomize":
			_randomize_order()
		"start":
			if _players.size() < 2:
				AudioManager.play_error()
				ToastManager.show_message("Need at least 2 players", 2.0, true)
				return
			# TODO: navigate to Game scene once it exists
			print("Start game with: ", _players)


func _randomize_order() -> void:
	if _players.size() < 2:
		return
	var original := _players.duplicate()
	var result := original.duplicate()

	# Try random shuffles until no element keeps its old position.
	# Falls back to a rotation (always a valid derangement).
	var ok := false
	for attempt in 50:
		result.shuffle()
		ok = true
		for i in result.size():
			if result[i] == original[i]:
				ok = false
				break
		if ok:
			break

	if not ok:
		result.clear()
		for i in original.size():
			result.append(original[(i + 1) % original.size()])

	_players = result
	_refresh()
	AudioManager.play_success()
	ToastManager.show_message("Player order shuffled")


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()


func _on_back_to_menu() -> void:
	_settings_modal.close()
	Navigation.go_home()


# =====================================================================
# HELPERS
# =====================================================================
func _show_add_error(msg: String) -> void:
	AudioManager.play_error()
	ToastManager.show_message(msg, 2.0, true)
	_add_error = true
	_refresh_add_button_color()
	_punch(_add_player_btn)


func _punch(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.18)

func _format_name(raw: String) -> String:
	# Title Case: first letter of each word uppercase, rest lowercase.
	# "i do like pudding" -> "I Do Like Pudding"
	# "UppErCase NAme"   -> "Uppercase Name"
	var parts := raw.split(" ", false)
	var words := PackedStringArray()
	for part in parts:
		if part.is_empty():
			continue
		var first := part.substr(0, 1).to_upper()
		var rest := part.substr(1).to_lower()
		words.append(first + rest)
	return " ".join(words)

func _starts_with_letter(name: String) -> bool:
	if name.is_empty():
		return false
	var c := name.substr(0, 1).to_upper()
	return c >= "A" and c <= "Z"


func _style_line_edit_bare(le: LineEdit) -> void:
	le.add_theme_color_override("font_color", Design.WHITE)
	le.add_theme_color_override("font_placeholder_color", Design.GRAY)
	le.add_theme_color_override("caret_color", Design.WHITE)
	le.add_theme_color_override("selection_color", Design.GLOBAL_CONTENT_BORDER)
	le.add_theme_font_size_override("font_size", Design.FONT_SIZE_LABEL)
	if Design.font_variation:
		le.add_theme_font_override("font", Design.font_variation)

	var empty := StyleBoxEmpty.new()
	le.add_theme_stylebox_override("normal",    empty)
	le.add_theme_stylebox_override("focus",     empty)
	le.add_theme_stylebox_override("read_only", empty)


func _spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
