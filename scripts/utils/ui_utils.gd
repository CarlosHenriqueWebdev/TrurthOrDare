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


# Wire a Control to behave like a button: hover pop, click SFX, tap callback.
# Reusable across AppHeader's logo, IconTextRow, and any future clickable
# surface so the motion + audio behaviour stays in one place.
static func make_clickable(node: Control, on_click: Callable, play_sound := true) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.focus_mode = Control.FOCUS_NONE
	node.resized.connect(func(): node.pivot_offset = node.size / 2)
	node.mouse_entered.connect(
		StyledButton._animate_scale.bind(node, Design.HOVER_SCALE, Design.HOVER_TIME)
	)
	node.mouse_exited.connect(
		StyledButton._animate_scale.bind(node, 1.0, Design.HOVER_TIME)
	)
	node.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if play_sound:
				AudioManager.play_click()
			on_click.call()
	)


# Recursively reclassify a subtree so touch-dragging works inside a
# ScrollContainer. In Godot, any Control with mouse_filter = STOP
# consumes drag events before they reach the scroll — even a plain
# Label. This walks the tree and downgrades decorative nodes:
#
#   Label / RichTextLabel / TextureRect / ColorRect / Panel → IGNORE
#   Container / PanelContainer / BorderedBox                → PASS
#
# Interactive Controls (Button, LineEdit, etc.) are left untouched —
# they aren't Containers, so they keep their default STOP filter and
# still consume clicks as expected.
#
# ScrollContainers are skipped so we never accidentally disable their
# own drag handling. Call this once, after the UI is fully built.
static func make_scroll_friendly(root: Node) -> void:
	for child in root.get_children():
		if child is ScrollContainer:
			# Leave the ScrollContainer's own filter alone (it needs
			# STOP to receive drag events) but DO descend into its
			# content — otherwise the boxes and labels inside stay
			# STOP and eat the drag before it reaches the scroll.
			make_scroll_friendly(child)
			continue
		if child is Label or child is RichTextLabel \
				or child is TextureRect or child is ColorRect \
				or (child is Panel and not (child is PanelContainer)):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif child is Container:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		make_scroll_friendly(child)
