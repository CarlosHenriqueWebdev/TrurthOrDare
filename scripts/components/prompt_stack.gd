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


# Use the same 3-layer BorderedBox the real card uses so the ghosts
# have a black background and matching border stack.
func _make_ghost() -> BorderedBox:
	var ghost := BorderedBox.create(18)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ghost


func _start_draw_animation() -> void:
	await get_tree().process_frame
	_play_draw()


# "Drawn from the pile" feel: card scales up from the top-right corner
# (toward the ghost pile), rotating into place with a slight overshoot.
func _play_draw() -> void:
	if not is_instance_valid(_card):
		return
	_card.pivot_offset = Vector2(_card.size.x, 0)
	_card.scale = Vector2(0.72, 0.72)
	_card.rotation = -0.10
	_card.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_card, "modulate:a", 1.0, 0.18)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "rotation", 0.0, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _layout() -> void:
	if not is_instance_valid(_card):
		return
	var pad := OFFSET_STEP * LAYERS
	var card_size := Vector2(maxf(0.0, size.x - pad), maxf(0.0, size.y - pad))
	_card.position = Vector2(0, pad)
	_card.size = card_size
	for ghost in _ghosts:
		var layer: int = ghost.get_meta("layer", 1)
		ghost.position = Vector2(layer * OFFSET_STEP, pad - layer * OFFSET_STEP)
		ghost.size = card_size


func _get_minimum_size() -> Vector2:
	if is_instance_valid(_card):
		var m := _card.get_combined_minimum_size()
		return m + Vector2(OFFSET_STEP * LAYERS, OFFSET_STEP * LAYERS)
	return Vector2(100, 100)
