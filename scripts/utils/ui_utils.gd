class_name UiUtils


# Recursively connect every Button under `root` to the click SFX.
# Respects suppress_click_sound on ANY Button (including ToggleButton).
# Safe to call multiple times — checks is_connected before wiring.
static func connect_click_sounds(root: Node, from: Node = null) -> void:
	var start := from if from != null else root
	for child in start.get_children():
		if child is Button:
			var suppressed: bool = child.get("suppress_click_sound") == true
			if not suppressed and not child.pressed.is_connected(AudioManager.play_click):
				child.pressed.connect(AudioManager.play_click)
		connect_click_sounds(child)
