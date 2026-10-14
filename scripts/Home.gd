extends Control

var _header: AppHeader
var _footer: AppFooter
var _settings_modal: Modal
var _preview_modal: PreviewModal


func _ready() -> void:
	_build()
	UiUtils.connect_click_sounds(self)


func _build() -> void:
	_build_background()

	_header = AppHeader.create()
	_header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_header.settings_pressed.connect(_on_settings_pressed)
	add_child(_header)

	_footer = AppFooter.create([
		{"id": "preview", "text": "PREVIEW TRUTHS & DARES", "color": Design.PRIMARY, "icon": Design.ICON_SEARCH},
		{"id": "start",   "text": "START GAME",             "color": Design.SECONDARY},
	])
	_footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_footer.button_pressed.connect(_on_footer_button)
	add_child(_footer)

	_settings_modal = Modal.create()
	var settings_panel := SettingsPanel.create()
	settings_panel.close_requested.connect(_settings_modal.close)
	_settings_modal.set_content(settings_panel)
	add_child(_settings_modal)

	_preview_modal = PreviewModal.create()
	add_child(_preview_modal)


func _build_background() -> void:
	if ResourceLoader.exists(Design.BG_PATH):
		var bg := TextureRect.new()
		bg.texture = load(Design.BG_PATH)
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

func _on_footer_button(id: String) -> void:
	match id:
		"preview":
			_preview_modal.open()
		"start":
			Navigation.go_to(Navigation.PLAYER_SETUP)


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()
