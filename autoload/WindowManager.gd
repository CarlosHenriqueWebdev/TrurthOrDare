## Desktop window sizing.
##
## On launch, resizes the OS window to match the target portrait aspect
## ratio, fits it inside the usable screen area, and centres it near the
## top edge. No-op on mobile, which handles its own window.
extends Node

func _ready() -> void:
	await get_tree().process_frame

  # Only resize the window on desktop platforms.
	if not OS.has_feature("desktop"):
		return

	var window := get_window()
	var screen_id := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen_id)

	var base_width := 390.0
	var base_height := 844.0
	var height_margin := 100

	# Leave space at the bottom of the usable desktop area.
	var available_height := maxi(1, usable.size.y - height_margin)

	# Preserve the original aspect ratio.
	var scale_factor := minf(
		1.0,
		float(available_height) / base_height
	)

	var target_width := roundi(base_width * scale_factor)
	var target_height := roundi(base_height * scale_factor)

	window.size = Vector2i(target_width, target_height)

	# Center within the usable desktop area and stay below its top edge.
	window.position = Vector2i(
		usable.position.x + int((usable.size.x - target_width) / 2.0),
		usable.position.y
	)
