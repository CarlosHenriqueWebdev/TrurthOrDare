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


func _ready() -> void:
	_build()
	_connect_click_sounds(self)
	_refresh()


func _connect_click_sounds(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
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

	# Bottom breathing room so the last row can scroll clear of the footer.
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

	_settings_modal = Modal.create()
	var settings_panel := SettingsPanel.create(true)
	settings_panel.close_requested.connect(_settings_modal.close)
	settings_panel.back_to_menu_requested.connect(_on_back_to_menu)
	_settings_modal.set_content(settings_panel)
	add_child(_settings_modal)


func _on_back_to_menu() -> void:
	_settings_modal.close()
	Navigation.go_home()


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

	# Title row: ADD PLAYERS ........ Enter at least 2 players
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

	var hint := Label.new()
	hint.text = "Enter at least 2 players"
	Design.apply_label(hint, 10, Design.GRAY)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(hint)

	box.add_with_margins(title_row, 16, 16, 16, 0)

	box.add_spacer(16)
	box.add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
	box.add_spacer(16)

	# Input row: LineEdit + ADD PLAYER button
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 12)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Player Name..."
	_name_input.max_length = NAME_MAX_LENGTH
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_line_edit(_name_input)
	_name_input.text_submitted.connect(func(_t): _on_add_player())
	input_row.add_child(_name_input)

	_add_player_btn = StyledButton.create("ADD PLAYER", Design.PRIMARY, Design.ICON_SEND, 32, true, true)
	_add_player_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_add_player_btn.pressed.connect(_on_add_player)
	input_row.add_child(_add_player_btn)
	print("btn min size: ", _add_player_btn.get_combined_minimum_size())

	box.add_with_margins(input_row, 16, 0, 16, 16)

	return box


func _build_player_list_box() -> BorderedBox:
	_player_list_box = BorderedBox.create()

	var title := Label.new()
	title.text = "PLAYER LIST"
	Design.apply_label(title, 12)
	_player_list_box.add_with_margins(title, 16, 16, 16, 0)

	_player_list_box.add_spacer(16)
	_player_list_box.add_full(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
	_player_list_box.add_spacer(16)

	# Rows container has no padding — dividers between rows need to reach
	# the border. Each row is padded individually.
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
			_player_rows_container.add_child(_spacer(16))
			_player_rows_container.add_child(ThreeLineDivider.create(Design.INNER_BORDER, Design.BLACK, Design.INNER_BORDER))
			_player_rows_container.add_child(_spacer(16))

	# Bottom padding inside the box
	_player_rows_container.add_child(_spacer(16))


func _update_controls() -> void:
	var has_players := _players.size() > 0
	var at_max := _players.size() >= MAX_PLAYERS

	if _add_player_btn:
		_add_player_btn.set_disabled_visual(at_max)
	if _name_input:
		_name_input.editable = not at_max
	if _randomize_btn:
		_randomize_btn.set_disabled_visual(not has_players)
	if _start_btn:
		_start_btn.set_disabled_visual(not has_players)


# =====================================================================
# ACTIONS
# =====================================================================
func _on_add_player() -> void:
	if _players.size() >= MAX_PLAYERS:
		ToastManager.show_message("Player limit reached")
		return
	var raw := _name_input.text.strip_edges()
	if raw.is_empty():
		ToastManager.show_message("Enter a player name")
		return
	if raw.length() > NAME_MAX_LENGTH:
		ToastManager.show_message("Name too long (max %d)" % NAME_MAX_LENGTH)
		return
	for p in _players:
		if p.to_lower() == raw.to_lower():
			ToastManager.show_message("Player already added")
			return
	_players.append(raw)
	_name_input.text = ""
	_name_input.grab_focus()
	_refresh()


func _on_remove_player(index: int) -> void:
	if index < 0 or index >= _players.size():
		return
	_players.remove_at(index)
	_refresh()


func _on_footer_button(id: String) -> void:
	match id:
		"randomize":
			if _players.is_empty():
				return
			_players.shuffle()
			_refresh()
		"start":
			if _players.size() < 2:
				ToastManager.show_message("Need at least 2 players")
				return
			# TODO: navigate to Game scene once it exists
			print("Start game with: ", _players)


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()


# =====================================================================
# HELPERS
# =====================================================================
func _style_line_edit(le: LineEdit) -> void:
	le.add_theme_color_override("font_color", Design.WHITE)
	le.add_theme_color_override("font_placeholder_color", Design.GRAY)
	le.add_theme_color_override("caret_color", Design.WHITE)
	le.add_theme_color_override("selection_color", Design.GLOBAL_CONTENT_BORDER)
	le.add_theme_font_size_override("font_size", Design.FONT_SIZE_LABEL)
	if Design.font_variation:
		le.add_theme_font_override("font", Design.font_variation)

	# Filled rounded input with gray border; brightens to green on focus.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Design.BLACK
	_apply_le_border(normal, Design.GRAY)
	le.add_theme_stylebox_override("normal", normal)

	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Design.GLOBAL_CONTENT_BORDER
	le.add_theme_stylebox_override("focus", focus)

	var read_only := normal.duplicate() as StyleBoxFlat
	read_only.bg_color = Design.SIX
	_apply_le_border(read_only, Design.DISABLED)
	le.add_theme_stylebox_override("read_only", read_only)


func _apply_le_border(sb: StyleBoxFlat, border_color: Color) -> void:
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.corner_radius_top_left     = 8
	sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_left  = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left   = 12
	sb.content_margin_right  = 12
	sb.content_margin_top    = 8
	sb.content_margin_bottom = 8

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _name_input and _name_input.has_focus():
			_name_input.release_focus()

func _spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
