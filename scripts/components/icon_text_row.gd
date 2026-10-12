class_name IconTextRow extends HBoxContainer

# Icon + text row. Clickable via `.clicked` signal if `clickable = true`.
# Usage:
#   var row := IconTextRow.create("res://.../cog.svg", "SETTINGS")
#   row.clicked.connect(_open_settings)
#   add_child(row)

signal clicked

const ICON_SIZE := 24


static func create(icon_path: String, text: String, font_size: int = Design.FONT_SIZE_LABEL, clickable := false) -> IconTextRow:
	var row := IconTextRow.new()
	row._build(icon_path, text, font_size, clickable)
	return row


func _build(icon_path: String, text: String, font_size: int, clickable: bool) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var icon := TextureRect.new()
	var tex := load(icon_path)
	if tex:
		icon.texture = tex
	else:
		push_error("Icon failed to load: " + icon_path)
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, font_size)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	if clickable:
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_input)
		resized.connect(func(): pivot_offset = size / 2)
		mouse_entered.connect(StyledButton._animate_scale.bind(self, Design.HOVER_SCALE, Design.HOVER_TIME))
		mouse_exited.connect(StyledButton._animate_scale.bind(self, 1.0, Design.HOVER_TIME))


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
