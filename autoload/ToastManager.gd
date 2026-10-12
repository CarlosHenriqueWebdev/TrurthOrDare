extends Node

# Global toast overlay. Screens call ToastManager.show_message("...").
# Renders a small bordered panel near the bottom of the screen, fades in,
# holds, fades out. Only one toast visible at a time.

var _layer: CanvasLayer
var _current: Control


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 10
	add_child(_layer)


func show_message(text: String, duration := 2.0) -> void:
	# Cancel existing toast so rapid messages don't stack.
	if is_instance_valid(_current):
		_current.queue_free()
		_current = null

	# Center-strip anchored near the bottom, above where footers sit.
	var strip := CenterContainer.new()
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -260
	strip.offset_bottom = -200
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(strip)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Design.BLACK.r, Design.BLACK.g, Design.BLACK.b, 0.95)
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = Design.GLOBAL_CONTENT_BORDER
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
	Design.apply_label(lbl, 12, Design.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)

	_current = strip
	strip.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(strip, "modulate:a", 1.0, 0.15)
	tw.tween_interval(duration)
	tw.tween_property(strip, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		if is_instance_valid(strip):
			strip.queue_free()
		if _current == strip:
			_current = null
	)
