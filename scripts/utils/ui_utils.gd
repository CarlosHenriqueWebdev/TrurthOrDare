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
# Deprecated — kept so any lingering callers compile without error.
# Does nothing. New code should use make_scroll_content_friendly(scroll).
static func make_scroll_friendly(_root: Node, _from: Node = null) -> void:
	pass


# Scoped variant — walks only the content of the given ScrollContainer.
# Preferred over the whole-tree walker: reclassifying nodes outside a
# scroll (headers, footers, modals) is what silently broke their click
# handlers in earlier revisions. This version can only touch content
# that lives inside the scroll, where downgrading is safe and intended.
static func make_scroll_content_friendly(scroll: ScrollContainer) -> void:
	_walk_scroll_content(scroll)


static func _walk_scroll_content(root: Node) -> void:
	for child in root.get_children():
		if child is ScrollContainer:
			_walk_scroll_content(child)
			continue
		if not child.get_signal_connection_list("gui_input").is_empty():
			_walk_scroll_content(child)
			continue
		if child is Control:
			var c := child as Control
			if c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				if child is Label or child is RichTextLabel \
						or child is TextureRect or child is ColorRect \
						or (child is Panel and not (child is PanelContainer)):
					c.mouse_filter = Control.MOUSE_FILTER_IGNORE
				elif child is Container or child is Button:
					c.mouse_filter = Control.MOUSE_FILTER_PASS
		_walk_scroll_content(child)

# Scroll "bleed" — when enabled, the ScrollContainer's content is not
# clipped at its rect, so it visually flows past the top and bottom
# edges into surrounding chrome (header, footer, spacers). The overlay
# controls are given a higher z_index so they still draw on top of the
# bleeding content. Call this after the scroll and overlays are added.
static func enable_scroll_bleed(scroll: ScrollContainer, top_overlay: Control = null, bottom_overlay: Control = null) -> void:
	scroll.clip_contents = false
	if top_overlay:
		top_overlay.z_index = 1
	if bottom_overlay:
		bottom_overlay.z_index = 1
