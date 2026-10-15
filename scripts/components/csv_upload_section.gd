class_name CsvUploadSection extends VBoxContainer

const MODE_CARD    := "cards"
const MODE_PENALTY := "penalty"

var _mode := MODE_CARD
var _locked := false

var _card_tab: ToggleButton
var _penalty_tab: ToggleButton
var _title_label: Label
var _path_input: LineEdit
var _clear_btn: StyledButton
var _upload_btn: StyledButton
var _view_btn: StyledButton
var _file_dialog: FileDialog


static func create(locked := false) -> CsvUploadSection:
	var s := CsvUploadSection.new()
	s._locked = locked
	s._build()
	return s


func _build() -> void:
	add_theme_constant_override("separation", 0)

	var box := BorderedBox.create(12)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)

	# Title
	_title_label = Label.new()
	if OS.has_feature("android"):
		_title_label.text = "Choose Upload Type — accept the permission prompt to browse files"
	else:
		_title_label.text = "Choose Upload Type"
	if _locked:
		_title_label.text = "Choose Upload Type (not available in game)"
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Design.apply_label(_title_label, Design.FONT_SIZE_LABEL, Design.GRAY)
	inner.add_child(_title_label)


	inner.add_child(_spacer(12))

	# Radio row
	var radio_row := HBoxContainer.new()
	radio_row.add_theme_constant_override("separation", 12)
	inner.add_child(radio_row)

	_card_tab = ToggleButton.create("CARD")
	_card_tab.suppress_click_sound = true
	_card_tab.pressed.connect(func(): _select_mode(MODE_CARD))
	radio_row.add_child(_card_tab)

	_penalty_tab = ToggleButton.create("PENALTY")
	_penalty_tab.suppress_click_sound = true
	_penalty_tab.pressed.connect(func(): _select_mode(MODE_PENALTY))
	radio_row.add_child(_penalty_tab)

	inner.add_child(_spacer(16))

	# Input + buttons + underline
	var input_col := VBoxContainer.new()
	input_col.add_theme_constant_override("separation", 8)
	inner.add_child(input_col)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 12)
	input_col.add_child(input_row)

	_path_input = LineEdit.new()
	_path_input.placeholder_text = "Choose a .csv file..."
	_path_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_input(_path_input)
	_path_input.text_submitted.connect(_on_path_submitted)
	input_row.add_child(_path_input)

	_clear_btn = StyledButton.create("CLEAR", Design.TERTIARY, "", 32, true, true)
	_clear_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clear_btn.pressed.connect(_on_clear)
	input_row.add_child(_clear_btn)

	_upload_btn = StyledButton.create("UPLOAD", Design.EIGHT, "", 32, true, true)
	_upload_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_upload_btn.pressed.connect(_open_file_dialog)
	input_row.add_child(_upload_btn)

	var underline := ColorRect.new()
	underline.color = Design.GRAY
	underline.custom_minimum_size = Vector2(0, 2)
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_col.add_child(underline)

	inner.add_child(_spacer(16))

	var view_icon := Design.ICON_CSV
	if not ResourceLoader.exists(view_icon):
		view_icon = ""
	_view_btn = StyledButton.create("VIEW CSV FORMAT & EXAMPLE", Design.PRIMARY, view_icon)
	_view_btn.pressed.connect(_show_format)
	inner.add_child(_view_btn)

	box.add_with_margins(inner, 16, 16, 16, 16)
	add_child(box)

	# File dialog
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.add_filter("*.csv", "CSV files")
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

	_refresh_tabs()
	_load_current_path()

	if _locked:
		_card_tab.set_locked(true)
		_penalty_tab.set_locked(true)
		_path_input.editable = false
		_clear_btn.set_disabled_visual(true)
		_upload_btn.set_disabled_visual(true)
		_view_btn.set_disabled_visual(true)


func _select_mode(mode: String) -> void:
	if _locked:
		return
	if _mode == mode:
		AudioManager.play_click()
		return
	_mode = mode
	AudioManager.play_click()
	_refresh_tabs()
	_load_current_path()


func _refresh_tabs() -> void:
	_card_tab.set_active(_mode == MODE_CARD)
	_penalty_tab.set_active(_mode == MODE_PENALTY)


func _load_current_path() -> void:
	if _mode == MODE_CARD:
		_path_input.text = SaveManager.get_cards_display_path()
	else:
		_path_input.text = SaveManager.get_pass_display_path()


func _open_file_dialog() -> void:
	if OS.has_feature("android"):
		# Godot's permission check is broken for MANAGE_EXTERNAL_STORAGE.
		# We request it (for the system prompt) but do NOT gate the dialog on it.
		# The export preset already includes the permission.
		var perm := "MANAGE_EXTERNAL_STORAGE"
		if not OS.get_granted_permissions().has(perm):
			OS.request_permissions()
			# Small delay to let the system dialog appear, then open our dialog.
			await get_tree().create_timer(0.5).timeout

	_file_dialog.popup_centered_ratio(0.8)


func _on_file_selected(path: String) -> void:
	_do_upload(path)


func _on_path_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	_do_upload(text.strip_edges())


func _do_upload(path: String) -> void:
	if _mode == MODE_CARD:
		if DataManager.load_cards(path):
			_path_input.text = path
			AudioManager.play_success()
			ToastManager.show_message("Cards loaded (copy saved)")
		else:
			AudioManager.play_error()
			ToastManager.show_message("Failed to load CSV", 2.0, true)
	else:
		if DataManager.load_pass_options(path):
			_path_input.text = path
			AudioManager.play_success()
			ToastManager.show_message("Penalties loaded (copy saved)")
		else:
			AudioManager.play_error()
			ToastManager.show_message("Failed to load CSV", 2.0, true)


func _on_clear() -> void:
	if _mode == MODE_CARD:
		DataManager.reset_to_default()
		ToastManager.show_message("Reset to default cards")
	else:
		DataManager.reset_pass_options_to_default()
		ToastManager.show_message("Reset to default penalties")
	_path_input.text = ""
	AudioManager.play_success()


func _show_format() -> void:
	var modal := Modal.create()

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)

	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = "CSV FORMAT"
	Design.apply_label(title, Design.FONT_SIZE_TITLE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close := CloseButton.create()
	close.pressed.connect(modal.close)
	title_row.add_child(close)
	col.add_child(title_row)

	col.add_child(_spacer(16))

	var body := BorderedBox.create(12)
	var rich := RichTextLabel.new()
	rich.fit_content = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.custom_minimum_size = Vector2(0, 240)
	Design.apply_rich(rich, 12, Design.WHITE)
	rich.text = _format_text()
	body.add_with_margins(rich, 16, 16, 16, 16)
	col.add_child(body)

	col.add_child(_spacer(16))

	var copy_btn := StyledButton.create("COPY FORMAT", Design.TERTIARY, Design.ICON_COPY)
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(_format_text())
		AudioManager.play_success()
		ToastManager.show_message("Format copied")
	)
	col.add_child(copy_btn)

	modal.set_content(col)
	get_tree().current_scene.add_child(modal)
	modal.closed.connect(modal.queue_free)
	UiUtils.connect_click_sounds(modal)
	modal.open()


func _format_text() -> String:
	if _mode == MODE_PENALTY:
		return "PENALTY OPTIONS CSV\n\n" \
			+ "Header:  group,label\n\n" \
			+ "Drink,Beer\n" \
			+ "Drink,Wine\n" \
			+ "Drink,Spirits\n" \
			+ "Custom 1,Skip next turn\n" \
			+ "Custom 2,Do a shot\n\n" \
			+ "Rows with the same group name are shown together.\n" \
			+ "Only the header row and data rows — no example text."
	return "CARD CSV FORMAT\n\n" \
		+ "Header:  type,category,text\n\n" \
		+ "truth,sober,What is your [b]most useless[/b] talent?\n" \
		+ "truth,tipsy,Reveal your last search.\n" \
		+ "dare,sober,Do 10 push-ups.\n" \
		+ "dare,drunk,Read your last 5 DMs out loud.\n\n" \
		+ "type:     truth | dare\n" \
		+ "category: sober | tipsy | drunk | wasted\n" \
		+ "text:     your prompt. Markup: [b]bold[/b], [i]italic[/i], [color=#c04143]red[/color]\n\n" \
		+ "Only the header row and data rows — no example text."


func _style_input(le: LineEdit) -> void:
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


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
