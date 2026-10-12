extends Control

var _header: AppHeader
var _footer: AppFooter
var _settings_modal: Modal


func _ready() -> void:
	_build()
	_connect_click_sounds(self)


# =====================================================================
# BUILD
# =====================================================================
func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load(Design.BG_PATH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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


# Auto-wire click SFX on every Button in the tree.
func _connect_click_sounds(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(AudioManager.play_click)
		_connect_click_sounds(child)


# =====================================================================
# HANDLERS
# =====================================================================
func _on_footer_button(id: String) -> void:
	match id:
		"preview":
			print("Preview pressed")
		"start":
			print("Start pressed")


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()
