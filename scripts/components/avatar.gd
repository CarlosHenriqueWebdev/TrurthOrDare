class_name Avatar extends Control

# Player initial avatar with a shader-masked image and 3 concentric rings.
# create_circle(size)  -> perfect circle (PlayerRow)
# create_rounded(size, radius_px) -> rounded square (CurrentPlayerBox)

const ROUNDED_SHADER := "shader_type canvas_item;\nuniform float radius_uv = 0.22;\nvoid fragment() {\n\tvec2 p = abs(UV - 0.5);\n\tvec2 d = p - (vec2(0.5) - vec2(radius_uv));\n\tfloat dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius_uv;\n\tfloat aa = fwidth(dist) * 0.5;\n\tfloat alpha = 1.0 - smoothstep(-aa, aa, dist);\n\tvec4 tex = texture(TEXTURE, UV);\n\ttex.a *= alpha;\n\tCOLOR = tex;\n}"

const CIRCLE_SHADER := "shader_type canvas_item;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tvec2 centered = UV - vec2(0.5);\n\tfloat dist = length(centered);\n\tfloat aa = fwidth(dist) * 1.5;\n\tfloat alpha = 1.0 - smoothstep(0.5 - aa, 0.5, dist);\n\ttex.a *= alpha;\n\tCOLOR = tex;\n}"


static func create_circle(player_name: String, size: float) -> Avatar:
	var a := Avatar.new()
	a._build(player_name, size, 999, true)
	return a


static func create_rounded(player_name: String, size: float, radius_px: float) -> Avatar:
	var a := Avatar.new()
	a._build(player_name, size, int(radius_px), false)
	return a


func _build(player_name: String, size: float, radius: int, is_circle: bool) -> void:
	custom_minimum_size = Vector2(size, size)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clip_contents = true

	var img_host := Control.new()
	img_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img_host.offset_left   = 6
	img_host.offset_top    = 6
	img_host.offset_right  = -6
	img_host.offset_bottom = -6
	img_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(img_host)

	var letter := "?"
	if player_name.length() > 0:
		letter = player_name.substr(0, 1).to_upper()
	var avatar_path := Design.AVATARS_DIR + letter + ".png"

	if ResourceLoader.exists(avatar_path):
		var tex := TextureRect.new()
		tex.texture = load(avatar_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = CIRCLE_SHADER if is_circle else ROUNDED_SHADER
		mat.shader = shader
		if not is_circle:
			# radius as UV fraction of the shorter side
			mat.set_shader_parameter("radius_uv", float(radius) / size)
		tex.material = mat
		img_host.add_child(tex)
	else:
		var disc := Panel.new()
		disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Design.SIX
		fsb.corner_radius_top_left     = radius
		fsb.corner_radius_top_right    = radius
		fsb.corner_radius_bottom_left  = radius
		fsb.corner_radius_bottom_right = radius
		disc.add_theme_stylebox_override("panel", fsb)
		img_host.add_child(disc)

		var lbl := Label.new()
		lbl.text = letter
		Design.apply_label(lbl, int(size * 0.38))
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img_host.add_child(lbl)

	# 3 rings drawn on top of the image
	add_child(_make_ring(Design.GLOBAL_CONTENT_BORDER, 0, radius))
	add_child(_make_ring(Design.BLACK, 2, max(radius - 2, 0)))
	add_child(_make_ring(Design.INNER_BORDER, 4, max(radius - 4, 0)))


func _make_ring(color: Color, inset: int, radius: int) -> Panel:
	var p := Panel.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left   = inset
	p.offset_top    = inset
	p.offset_right  = -inset
	p.offset_bottom = -inset
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.draw_center = false
	sb.border_width_left   = 2
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_color = color
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	p.add_theme_stylebox_override("panel", sb)
	return p
