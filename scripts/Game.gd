extends Control

var _current_player_box: CurrentPlayerBox
var _prompt_card: PromptCard
var _prompt_area: Control
var _content_col: VBoxContainer
var _footer: Control
var _info_rich: RichTextLabel
var _forfeit_btn: StyledButton
var _complete_btn: StyledButton
var _penalty_dialog: PenaltyDialog
var _message_modal: MessageModal
var _settings_modal: Modal


func _ready() -> void:
	if GameState.players.is_empty():
		Navigation.go_to(Navigation.PLAYER_SETUP)
		return
	_build()
	UiUtils.connect_click_sounds(self)
	_refresh()

func _build() -> void:
	_build_background()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := AppHeader.create()
	header.settings_pressed.connect(_on_settings_pressed)
	root.add_child(header)

	root.add_child(_spacer(16))

	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left",  16)
	content_margin.add_theme_constant_override("margin_right", 16)
	content_margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(content_margin)

	_content_col = VBoxContainer.new()
	_content_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_col.add_theme_constant_override("separation", 16)
	content_margin.add_child(_content_col)

	_current_player_box = CurrentPlayerBox.make("", "sober", 1, 1)
	_content_col.add_child(_current_player_box)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_col.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(inner)

	_prompt_area = inner

	_build_footer(root)

	_settings_modal = Modal.create()
	var settings_panel := SettingsPanel.create(true, true, true)
	settings_panel.close_requested.connect(_settings_modal.close)
	settings_panel.back_to_menu_requested.connect(_on_back_to_menu)
	_settings_modal.set_content(settings_panel)
	add_child(_settings_modal)

	_penalty_dialog = PenaltyDialog.create()
	_penalty_dialog.confirmed.connect(_on_penalty_confirmed)
	add_child(_penalty_dialog)

	_message_modal = MessageModal.create()
	add_child(_message_modal)


func _build_background() -> void:
	if ResourceLoader.exists(Design.GAME_BG_PATH):
		var bg := TextureRect.new()
		bg.texture = load(Design.GAME_BG_PATH)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var c := ColorRect.new()
		c.color = Design.BLACK
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)


func _build_footer(root: VBoxContainer) -> void:
	_footer = VBoxContainer.new()
	_footer.add_theme_constant_override("separation", 0)

	for c in [Design.GLOBAL_CONTENT_BORDER, Design.BLACK, Design.INNER_BORDER]:
		_footer.add_child(AppHeader._make_line(c))

	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Design.BLACK
	panel.add_theme_stylebox_override("panel", psb)
	_footer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top",   12)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	_info_rich = RichTextLabel.new()
	_info_rich.bbcode_enabled = true
	_info_rich.fit_content = true
	_info_rich.scroll_active = false
	_info_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_rich.add_theme_font_size_override("normal_font_size", 10)
	_info_rich.add_theme_constant_override("line_separation", 4)
	_info_rich.add_theme_color_override("default_color", Design.GRAY)
	if Design.font_variation:
		_info_rich.add_theme_font_override("normal_font", Design.font_variation)
	_info_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_info_rich)

	_forfeit_btn = StyledButton.create("FORFEIT", Design.PRIMARY, Design.ICON_FORFEIT)
	_forfeit_btn.pressed.connect(_on_forfeit)
	col.add_child(_forfeit_btn)

	_complete_btn = StyledButton.create("COMPLETE", Design.SECONDARY)
	_complete_btn.pressed.connect(_on_complete)
	col.add_child(_complete_btn)

	root.add_child(_footer)


# =====================================================================
# STATE
# =====================================================================
func _refresh() -> void:
	# Rebuild player box
	if is_instance_valid(_current_player_box):
		_content_col.remove_child(_current_player_box)
		_current_player_box.queue_free()
	var idx := GameState.current_index + 1
	var total := GameState.players.size()
	_current_player_box = CurrentPlayerBox.make(GameState.current_player(), GameState.current_category, idx, total)
	_content_col.add_child(_current_player_box)
	_content_col.move_child(_current_player_box, 0)

	# Prompt area
	for child in _prompt_area.get_children():
		_prompt_area.remove_child(child)
		child.queue_free()

	if GameState.game_over:
		AudioManager.play_game_over()
		var over := _make_game_over_panel()
		_prompt_area.add_child(over)
		UiUtils.connect_click_sounds(self, over)
		_animate_in(over, 0.0)
	else:
		_prompt_card = PromptCard.make(GameState.current_type, GameState.current_text)
		_prompt_card.copy_requested.connect(_on_copy_requested)
		var stack := PromptStack.create(_prompt_card)
		_prompt_area.add_child(stack)
		# PromptStack plays its own draw animation.

	# Buttons: disabled at game over
	if _forfeit_btn:
		_forfeit_btn.set_disabled_visual(GameState.game_over)
	if _complete_btn:
		_complete_btn.set_disabled_visual(GameState.game_over)

	# Info line
	_update_info()


func _update_info() -> void:
	if _info_rich == null:
		return

	var t := int(round(GameState.truth_chance_for_current() * 100.0))
	var d := int(round(GameState.dare_chance_for_current() * 100.0))
	var p := GameState.category_percentages()

	var c_sober  := Design.odds_color("sober").to_html(false)
	var c_tipsy  := Design.odds_color("tipsy").to_html(false)
	var c_drunk  := Design.odds_color("drunk").to_html(false)
	var c_wasted := Design.odds_color("wasted").to_html(false)

	var green := Design.GLOBAL_CONTENT_BORDER.to_html(false)
	var orange := Design.SEVEN.to_html(false)

	var remaining := GameState.cards_remaining()
	var remaining_text := "∞" if remaining < 0 else str(remaining) + " left"
	_info_rich.text = \
		"Card %02d   Chances [color=#%s]T %d%%[/color] / [color=#%s]D %d%%[/color]\n" % [
			GameState.cards_played, green, t, orange, d,
		] + \
		"Odds [color=#%s]%d[/color] / [color=#%s]%d[/color] / [color=#%s]%d[/color] / [color=#%s]%d[/color]   (%s)" % [
			c_sober,  p.get("sober", 0),
			c_tipsy,  p.get("tipsy", 0),
			c_drunk,  p.get("drunk", 0),
			c_wasted, p.get("wasted", 0),
			remaining_text,
		]


func _make_game_over_panel() -> BorderedBox:
	var box := BorderedBox.create(18)

	var title := Label.new()
	title.text = "ALL CARDS PLAYED"
	Design.apply_label(title, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_with_margins(title, 24, 32, 24, 8)

	var sub := Label.new()
	sub.text = "Nice round. Want to go again?"
	Design.apply_label(sub, 12, Design.GRAY)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_with_margins(sub, 24, 0, 24, 24)

	var restart_icon := Design.ICON_RESTART
	if not ResourceLoader.exists(restart_icon):
		restart_icon = Design.ICON_CHEVRON

	var menu := StyledButton.create("MAIN MENU", Design.PRIMARY, Design.ICON_HOUSE)
	menu.pressed.connect(_on_back_to_menu)
	box.add_with_margins(menu, 16, 0, 16, 12)

	var restart := StyledButton.create("RESTART GAME", Design.SECONDARY, restart_icon)
	restart.pressed.connect(_on_restart)
	box.add_with_margins(restart, 16, 0, 16, 16)

	return box


func _animate_in(node: Control, delay: float) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.94, 0.94)
	await get_tree().process_frame
	node.pivot_offset = node.size / 2
	var tw := create_tween()
	tw.set_parallel(true)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.22)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# =====================================================================
# ACTIONS
# =====================================================================
func _on_forfeit() -> void:
	_penalty_dialog.open()


func _on_penalty_confirmed(selection: Dictionary) -> void:
	var group: String = selection.get("group", "")
	var label: String = selection.get("label", "")
	if group.is_empty() or label.is_empty():
		ToastManager.show_message("Select a penalty", 2.0, true)
		return
	AudioManager.play_penalty()
	ToastManager.show_message("Passed: %s - %s" % [group, label])
	GameState.advance()
	_refresh()


func _on_complete() -> void:
	AudioManager.play_card_flip()
	GameState.advance()
	_refresh()


func _on_restart() -> void:
	GameState.restart()
	_refresh()


func _on_copy_requested() -> void:
	_message_modal.show_message(GameState.current_text)


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()


func _on_back_to_menu() -> void:
	if _settings_modal and _settings_modal.visible:
		_settings_modal.close()
	Navigation.go_home()


func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
