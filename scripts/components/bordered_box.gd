class_name BorderedBox extends PanelContainer

# Reusable 3-layer bordered box:
#   outer green border → middle black → inner dark green → content.
# Content has no built-in padding. Use:
#   add_full(node)                                → edge to edge (e.g. dividers)
#   add_with_margins(node, left, top, right, bottom) → custom padding
#   add_spacer(px)                                → vertical gap
# create_circle(size) gives you a circular avatar-shaped box.

const BORDER_W := 2

var content: VBoxContainer


static func create(radius := 18.0) -> BorderedBox:
	var box := BorderedBox.new()
	box._build(int(radius))
	return box


static func create_circle(size: float) -> BorderedBox:
	var box := BorderedBox.new()
	box._build(999)
	box.custom_minimum_size = Vector2(size, size)
	return box


func _build(radius: int) -> void:
	var sb1 := StyleBoxFlat.new()
	sb1.bg_color = Design.BLACK
	_set_border(sb1, Design.GLOBAL_CONTENT_BORDER)
	_set_radius(sb1, radius)
	sb1.content_margin_left   = BORDER_W
	sb1.content_margin_top    = BORDER_W
	sb1.content_margin_right  = BORDER_W
	sb1.content_margin_bottom = BORDER_W
	add_theme_stylebox_override("panel", sb1)

	var mid := PanelContainer.new()
	var sb2 := StyleBoxFlat.new()
	sb2.draw_center = false
	_set_border(sb2, Design.BLACK)
	_set_radius(sb2, max(radius - 2, 0))
	sb2.content_margin_left   = BORDER_W
	sb2.content_margin_top    = BORDER_W
	sb2.content_margin_right  = BORDER_W
	sb2.content_margin_bottom = BORDER_W
	mid.add_theme_stylebox_override("panel", sb2)
	add_child(mid)

	var inner := PanelContainer.new()
	var sb3 := StyleBoxFlat.new()
	sb3.draw_center = false
	_set_border(sb3, Design.INNER_BORDER)
	_set_radius(sb3, max(radius - 4, 0))
	sb3.content_margin_left   = 0
	sb3.content_margin_top    = 0
	sb3.content_margin_right  = 0
	sb3.content_margin_bottom = 0
	inner.add_theme_stylebox_override("panel", sb3)
	mid.add_child(inner)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	inner.add_child(content)


func add_full(node: Control) -> void:
	content.add_child(node)


func add_with_margins(node: Control, left: int, top: int, right: int, bottom: int) -> void:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   left)
	m.add_theme_constant_override("margin_right",  right)
	m.add_theme_constant_override("margin_top",    top)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.add_child(node)
	content.add_child(m)


func add_spacer(height: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(s)


static func _set_border(sb: StyleBoxFlat, color: Color) -> void:
	sb.border_width_left   = BORDER_W
	sb.border_width_top    = BORDER_W
	sb.border_width_right  = BORDER_W
	sb.border_width_bottom = BORDER_W
	sb.border_color = color


static func _set_radius(sb: StyleBoxFlat, r: int) -> void:
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_left  = r
	sb.corner_radius_bottom_right = r
