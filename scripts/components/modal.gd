class_name Modal extends Control

# Bottom-anchored modal with dimmer. Emits `closed` when dismissed.
# Usage:
#   var m := Modal.create()
#   m.set_content(some_node)
#   add_child(m)
#   m.open()

signal closed

var _panel_content: VBoxContainer
var _tween: Tween


static func create() -> Modal:
	var m := Modal.new()
	m._build()
	return m


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

	# Dimmer catches outside clicks
	var dimmer := ColorRect.new()
	dimmer.color = Color(Design.BLACK.r, Design.BLACK.g, Design.BLACK.b, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(_on_dimmer_input)
	add_child(dimmer)

	# Full-rect VBox with END alignment so content stacks from the bottom
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_END
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outer)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	outer.add_child(wrapper)

	for c in [Design.GLOBAL_CONTENT_BORDER, Design.BLACK, Design.INNER_BORDER]:
		wrapper.add_child(AppHeader._make_line(c))

	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Design.BLACK
	panel.add_theme_stylebox_override("panel", psb)
	wrapper.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_right",  Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_top",    Design.SIDE_PADDING)
	margin.add_theme_constant_override("margin_bottom", Design.SIDE_PADDING)
	panel.add_child(margin)

	_panel_content = VBoxContainer.new()
	_panel_content.add_theme_constant_override("separation", 0)
	margin.add_child(_panel_content)


# Add a node to the modal's content column.
func set_content(node: Control) -> void:
	_panel_content.add_child(node)


func open() -> void:
	visible = true
	modulate.a = 0.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func close() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(func():
		visible = false
		closed.emit()
	)


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
