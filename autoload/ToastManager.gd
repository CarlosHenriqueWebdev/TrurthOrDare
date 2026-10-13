extends Node

# Global toast overlay. Screens call ToastManager.show_message("...").
# Pass is_error = true for the red-border variant.

var _layer: CanvasLayer
var _current: Control
var _current_tween: Tween


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 10
	add_child(_layer)


func show_message(text: String, duration := 2.0, is_error := false) -> void:
	# Cancel previous
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	if is_instance_valid(_current):
		_current.queue_free()
		_current = null

	var strip := CenterContainer.new()
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -260
	strip.offset_bottom = -200
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(strip)

	var border_color := Design.ERROR_TEXT if is_error else Design.GLOBAL_CONTENT_BORDER
	var text_color := Design.ERROR_TEXT if is_error else Design.WHITE

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Design.BLACK.r, Design.BLACK.g, Design.BLACK.b, 0.95)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.corner_radius_top_left     = 8
	sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_left  = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left   = 16
	sb.content_margin_right  = 16
	sb.content_margin_top    = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	strip.add_child(panel)

	var lbl := Label.new()
	lbl.text = text
	Design.apply_label(lbl, 12, text_color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Force a fixed inner width so long messages clip with "…".
	lbl.custom_minimum_size.x = Design.MAX_TOAST_WIDTH - 32
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)

	_current = strip
	strip.modulate.a = 0.0

	_current_tween = create_tween()
	_current_tween.tween_property(strip, "modulate:a", 1.0, 0.15)
	_current_tween.tween_interval(duration)
	_current_tween.tween_property(strip, "modulate:a", 0.0, 0.3)
	_current_tween.tween_callback(_clear_toast.bind(strip))


func _clear_toast(strip: Control) -> void:
	if is_instance_valid(strip):
		strip.queue_free()
	if _current == strip:
		_current = null
		_current_tween = null
