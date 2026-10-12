class_name PlayerRow extends HBoxContainer

signal remove_requested

const AVATAR_SIZE := 42
const AVATAR_GAP  := 12
const ROW_HEIGHT  := 58

const CIRCLE_MASK_SHADER := "shader_type canvas_item;\nvoid fragment() {\n    vec4 tex = texture(TEXTURE, UV);\n    vec2 centered = UV - vec2(0.5);\n    float dist = length(centered);\n    float aa = fwidth(dist) * 1.5;\n    float alpha = 1.0 - smoothstep(0.5 - aa, 0.5, dist);\n    tex.a *= alpha;\n    COLOR = tex;\n}"


static func create(player_name: String, position: int) -> PlayerRow:
	var row := PlayerRow.new()
	row._build(player_name, position)
	return row


func _build(player_name: String, position: int) -> void:
	custom_minimum_size = Vector2(0, ROW_HEIGHT)
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	add_child(_make_avatar(player_name))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(AVATAR_GAP, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)

	var name_lbl := Label.new()
	name_lbl.text = _ordinal(position) + " " + player_name
	Design.apply_label(name_lbl, Design.FONT_SIZE_LABEL)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)

	var remove_btn := StyledButton.create("REMOVE", Design.TERTIARY, Design.ICON_REMOVE, 32, true, true)
	remove_btn.suppress_click_sound = true
	remove_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove_btn.pressed.connect(func(): remove_requested.emit())
	add_child(remove_btn)


static func _make_avatar(player_name: String) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.clip_contents = true

	var img_host := Control.new()
	img_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img_host.offset_left   = 6
	img_host.offset_top    = 6
	img_host.offset_right  = -6
	img_host.offset_bottom = -6
	img_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(img_host)

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
		shader.code = CIRCLE_MASK_SHADER
		mat.shader = shader
		tex.material = mat

		img_host.add_child(tex)
		print("avatar ", letter, " | root=", root.size, " | host=", img_host.size, " | tex=", tex.size)
	else:
		var disc := Panel.new()
		disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Design.SIX
		fsb.corner_radius_top_left     = 999
		fsb.corner_radius_top_right    = 999
		fsb.corner_radius_bottom_left  = 999
		fsb.corner_radius_bottom_right = 999
		disc.add_theme_stylebox_override("panel", fsb)
		img_host.add_child(disc)

		var lbl := Label.new()
		lbl.text = letter
		Design.apply_label(lbl, 16)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img_host.add_child(lbl)

		print("avatar fallback ", letter, " | root=", root.size, " | host=", img_host.size)

	root.add_child(_make_ring(Design.GLOBAL_CONTENT_BORDER, 0))
	root.add_child(_make_ring(Design.BLACK, 2))
	root.add_child(_make_ring(Design.INNER_BORDER, 4))

	return root


static func _make_ring(color: Color, inset: int) -> Panel:
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
	sb.corner_radius_top_left     = 999
	sb.corner_radius_top_right    = 999
	sb.corner_radius_bottom_left  = 999
	sb.corner_radius_bottom_right = 999
	p.add_theme_stylebox_override("panel", sb)
	return p


static func _ordinal(n: int) -> String:
	var n100 := n % 100
	if n100 >= 11 and n100 <= 13:
		return str(n) + "th"
	match n % 10:
		1: return str(n) + "st"
		2: return str(n) + "nd"
		3: return str(n) + "rd"
		_: return str(n) + "th"
