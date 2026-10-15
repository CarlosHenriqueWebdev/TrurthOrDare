class_name CloseButton extends Control

## Reusable close (X) button with a mobile-friendly tap target.
##
## The visible icon stays small (16px) but the tap target is 48px on
## every side. Emits `pressed` when tapped. Plays the standard click SFX.
##
## Usage:
##     var btn := CloseButton.create()
##     btn.pressed.connect(_on_close)
##     add_child(btn)

signal pressed

const ICON_SIZE := 16
const TAP_SIZE  := 48


static func create() -> CloseButton:
	var b := CloseButton.new()
	b._build()
	return b


func _build() -> void:
	custom_minimum_size = Vector2(TAP_SIZE, TAP_SIZE)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_END
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	var icon := TextureRect.new()
	var tex := load(Design.ICON_CLOSE)
	if tex:
		icon.texture = tex
	else:
		push_error("Close icon missing: " + Design.ICON_CLOSE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.anchor_left   = 0.5
	icon.anchor_top    = 0.5
	icon.anchor_right  = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left   = -ICON_SIZE / 2.0
	icon.offset_top    = -ICON_SIZE / 2.0
	icon.offset_right  =  ICON_SIZE / 2.0
	icon.offset_bottom =  ICON_SIZE / 2.0
	add_child(icon)

	gui_input.connect(_on_input)


func _on_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_click()
		pressed.emit()
