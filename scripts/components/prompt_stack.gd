class_name PromptStack extends Container

const OFFSET_STEP := 8.0
const LAYERS      := 2

var _card: Control
var _ghosts: Array[Control] = []


static func create(card: Control) -> PromptStack:
	var s := PromptStack.new()
	s._build(card)
	return s


func _build(card: Control) -> void:
	_card = card
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	for i in range(LAYERS, 0, -1):
		var ghost := _make_ghost()
		ghost.set_meta("layer", i)
		add_child(ghost)
		_ghosts.append(ghost)

	add_child(card)
	resized.connect(queue_sort)
	call_deferred("_start_draw_animation")


func _make_ghost() -> BorderedBox:
	var ghost := BorderedBox.create(18)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ghost


func _start_draw_animation() -> void:
	await get_tree().process_frame
	_play_draw()


func _play_draw() -> void:
	if not is_instance_valid(_card):
		return
	_card.pivot_offset = Vector2.ZERO
	_card.position.y += 24
	_card.modulate.a = 0.0

	var start_y := _card.position.y
	var end_y := start_y - 24
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_card, "modulate:a", 1.0, 0.22)
	tw.tween_property(_card, "position:y", end_y, 0.42)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _layout() -> void:
	if not is_instance_valid(_card):
		return
	var pad := OFFSET_STEP * LAYERS
	# Card fills width, sits at the bottom of the reserved slot.
	_card.position = Vector2(0, pad)
	_card.size = Vector2(size.x, size.y - pad)
	# Ghosts step up-right, right edges aligned with the card's right edge.
	for ghost in _ghosts:
		var layer: int = ghost.get_meta("layer", 1)
		var inset := layer * OFFSET_STEP
		ghost.position = Vector2(inset, pad - inset)
		ghost.size = Vector2(size.x - inset, size.y - pad)


func _get_minimum_size() -> Vector2:
	if is_instance_valid(_card):
		var m := _card.get_combined_minimum_size()
		# Only reserve vertical space; never widen the parent.
		return Vector2(0, m.y + OFFSET_STEP * LAYERS)
	return Vector2(0, 116)
