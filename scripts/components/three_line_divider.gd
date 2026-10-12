class_name ThreeLineDivider extends VBoxContainer

# Three stacked full-width lines with no gap between them.
# Used as a decorative separator inside boxes, footers, headers.

static func create(c1: Color, c2: Color, c3: Color, line_h := 2) -> ThreeLineDivider:
	var d := ThreeLineDivider.new()
	d.add_theme_constant_override("separation", 0)
	for c in [c1, c2, c3]:
		var line := ColorRect.new()
		line.color = c
		line.custom_minimum_size = Vector2(0, line_h)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(line)
	return d
