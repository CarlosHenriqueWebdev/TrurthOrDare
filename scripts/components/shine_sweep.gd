class_name ShineSweep extends ColorRect

const SHADER_SRC := "shader_type canvas_item;\nuniform float progress : hint_range(0.0, 1.0) = 0.0;\nuniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);\n\nvoid fragment() {\n\tfloat sweep = progress * 1.8 - 0.4;\n\tfloat pos = UV.x + (1.0 - UV.y) * 0.12;\n\tfloat d = abs(pos - sweep);\n\tfloat a = smoothstep(0.18, 0.0, d);\n\tCOLOR = vec4(shine_color.rgb, shine_color.a * a);\n}"

const SWEEP_TIME := 3.25
const REST_TIME  := 6.0

var _mat: ShaderMaterial


static func attach_to(button: Control) -> ShineSweep:
	var s := ShineSweep.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.color = Color(0, 0, 0, 0)  # base rect is transparent; shader adds the stripe
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(s)
	s._build()
	return s


func _build() -> void:
	var shader := Shader.new()
	shader.code = SHADER_SRC
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("progress", 0.0)
	_mat.set_shader_parameter("shine_color", Color(1, 1, 1, 0.08))
	material = _mat
	_loop.call_deferred()


func _loop() -> void:
	await get_tree().create_timer(0.4).timeout
	while is_instance_valid(self):
		var tw := create_tween()
		tw.tween_method(_set_progress, 0.0, 1.0, SWEEP_TIME).set_trans(Tween.TRANS_SINE)
		await tw.finished
		await get_tree().create_timer(REST_TIME).timeout


func _set_progress(v: float) -> void:
	if _mat:
		_mat.set_shader_parameter("progress", v)
