class_name UiUtils


# Recursively connect every Button under `root` to the click SFX.
# StyledButton entries that have suppress_click_sound = true are skipped,
# so the caller doesn't have to filter them out.
static func connect_click_sounds(root: Node, from: Node = null) -> void:
	var start := from if from != null else root
	for child in start.get_children():
		if child is StyledButton:
			if not child.suppress_click_sound:
				child.pressed.connect(AudioManager.play_click)
		elif child is Button:
			child.pressed.connect(AudioManager.play_click)
		connect_click_sounds(root, child)
