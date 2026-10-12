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
const BG_PATHS := [
	"res://assets/MainMenuBackground.png",
	"res://assets/MainMenuBackground2.png",
	"res://assets/MainMenuBackground3.png",
]
const BG_CYCLE_TIME := 8.0
const BG_FADE_TIME := 1.0

var _bg_layers: Array[TextureRect] = []
var _bg_index := 0

func _build_background() -> void:
	var any_loaded := false
	for path in BG_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var tex := TextureRect.new()
		tex.texture = load(path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.modulate.a = 0.0
		add_child(tex)
		_bg_layers.append(tex)
		any_loaded = true

	if not any_loaded:
		var c := ColorRect.new()
		c.color = Design.BLACK
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		return

	_bg_layers[0].modulate.a = 1.0

func _start_background_cycle() -> void:
	if _bg_layers.size() < 2:
		return
	var timer := Timer.new()
	timer.wait_time = BG_CYCLE_TIME
	timer.timeout.connect(_advance_background)
	add_child(timer)
	timer.start()


func _advance_background() -> void:
	var next_index := (_bg_index + 1) % _bg_layers.size()
	var current := _bg_layers[_bg_index]
	var next := _bg_layers[next_index]
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(next, "modulate:a", 1.0, BG_FADE_TIME)
	tw.tween_property(current, "modulate:a", 0.0, BG_FADE_TIME)
	_bg_index = next_index

func _build() -> void:
	_build_background()
	_start_background_cycle()

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
			Navigation.go_to(Navigation.PLAYER_SETUP)


func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_settings_modal.open()
