class_name ToggleGroup extends HBoxContainer

# Two-button on/off toggle. Emits `changed(is_on)` when state flips.
# Usage:
#   var tg := ToggleGroup.create(true)
#   tg.changed.connect(_on_music_toggle)
#   add_child(tg)

signal changed(is_on: bool)

var _off_btn: ToggleButton
var _on_btn: ToggleButton


static func create(initial: bool) -> ToggleGroup:
	var tg := ToggleGroup.new()
	tg._build(initial)
	return tg


func _build(initial: bool) -> void:
	add_theme_constant_override("separation", 12)

	_off_btn = ToggleButton.create("TURN OFF")
	_on_btn  = ToggleButton.create("TURN ON")
	add_child(_off_btn)
	add_child(_on_btn)

	_off_btn.pressed.connect(_on_off_pressed)
	_on_btn.pressed.connect(_on_on_pressed)

	set_on(initial, false)


func set_on(is_on: bool, emit_signal := true) -> void:
	_off_btn.set_active(not is_on)
	_on_btn.set_active(is_on)
	if emit_signal:
		changed.emit(is_on)


# Lock the toggle: swap to the disabled color, ignore clicks.
func set_locked(locked: bool) -> void:
	_off_btn.set_locked(locked)
	_on_btn.set_locked(locked)


func _on_off_pressed() -> void:
	set_on(false)

func _on_on_pressed() -> void:
	set_on(true)
