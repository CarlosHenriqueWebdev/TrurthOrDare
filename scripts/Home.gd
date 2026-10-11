extends Control

# --- Paths ---
const BG_PATH := "res://assets/MainMenuBackground.png"
const LOGO_PATH := "res://assets/TruthOrDareLogo.png"
const FONT_PATH := "res://assets/fonts/FugazOne-Regular.ttf"
const ICON_CHEVRON := "res://assets/icons/chevron_double.svg"
const ICON_COG := "res://assets/icons/cog.svg"
const ICON_CSV := "res://assets/icons/csv.svg"

# --- Design tokens ---
const COLOR_TEXT := Color("#C8C8C8")
const COLOR_START_BG := Color("#325349")
const COLOR_PREVIEW_BG := Color("#402D3D")
const COLOR_BORDER := Color(10 / 255.0, 10 / 255.0, 10 / 255.0, 0.35)

const SIDE_PADDING := 16
const GROUP_GAP := 24
const BUTTON_GAP := 16
const BUTTON_HEIGHT := 48
const BUTTON_PADDING_H := 16
const BUTTON_BORDER_W := 3
const BUTTON_RADIUS := 8
const LOGO_WIDTH := 306.59
const LOGO_HEIGHT := 68.17
const FONT_SIZE_BTN := 14
const FONT_SIZE_LABEL := 14

# --- Typography tweaks ---
# Figma letter-spacing is em-relative. 0.2% of 14px = 0.028px — invisible.
# Leave at 0 unless you want visible tracking; try 0.5 or 1.0.
const LETTER_SPACING_PX := 0.0
# Figma line-height 100%. Godot adds line_spacing px between lines.
# 0 gives the tightest rendering Godot allows.
const LINE_SPACING_PX := 0

var font: FontFile

func _ready() -> void:
    if ResourceLoader.exists(FONT_PATH):
        font = load(FONT_PATH) as FontFile
    else:
        push_error("Font missing: " + FONT_PATH)
    _build()

# =====================================================================
# Typography helpers — apply to EVERY label
# =====================================================================
func _make_font_variation() -> FontVariation:
    var fv := FontVariation.new()
    if font:
        fv.base_font = font
    fv.spacing_glyph = int(LETTER_SPACING_PX)
    return fv

func _apply_label_style(lbl: Label, size: int) -> void:
    lbl.add_theme_font_override("font", _make_font_variation())
    lbl.add_theme_font_size_override("font_size", size)
    lbl.add_theme_constant_override("line_spacing", LINE_SPACING_PX)
    lbl.add_theme_color_override("font_color", COLOR_TEXT)


func _build() -> void:
    # Background
    var bg := TextureRect.new()
    bg.texture = load(BG_PATH)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    # 16px padding wrapper
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", SIDE_PADDING)
    margin.add_theme_constant_override("margin_right", SIDE_PADDING)
    margin.add_theme_constant_override("margin_top", SIDE_PADDING)
    margin.add_theme_constant_override("margin_bottom", SIDE_PADDING)
    add_child(margin)

    var col := VBoxContainer.new()
    col.alignment = BoxContainer.ALIGNMENT_END
    col.add_theme_constant_override("separation", GROUP_GAP)
    margin.add_child(col)

    # -------- Logo --------
    var logo := TextureRect.new()
    var logo_tex := load(LOGO_PATH) as Texture2D
    if logo_tex:
        logo.texture = logo_tex
        logo.custom_minimum_size = Vector2(LOGO_WIDTH, LOGO_HEIGHT)
    else:
        push_error("Logo failed to load: " + LOGO_PATH)
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    col.add_child(logo)

    # -------- Buttons --------
    var btn_col := VBoxContainer.new()
    btn_col.add_theme_constant_override("separation", BUTTON_GAP)
    col.add_child(btn_col)

    btn_col.add_child(_make_button("START GAME", COLOR_START_BG))
    btn_col.add_child(_make_button("PREVIEW TRUTHS & DARES", COLOR_PREVIEW_BG))

    # -------- Bottom row --------
    var bottom := HBoxContainer.new()
    col.add_child(bottom)

    bottom.add_child(_make_settings_row())

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bottom.add_child(spacer)

    bottom.add_child(_make_upload_row())


func _make_button(text: String, bg_color: Color) -> Button:
    var btn := Button.new()
    btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
    btn.focus_mode = Control.FOCUS_NONE

    var sb := StyleBoxFlat.new()
    sb.bg_color = bg_color
    sb.corner_radius_top_left = BUTTON_RADIUS
    sb.corner_radius_top_right = BUTTON_RADIUS
    sb.corner_radius_bottom_left = BUTTON_RADIUS
    sb.corner_radius_bottom_right = BUTTON_RADIUS
    btn.add_theme_stylebox_override("normal", sb)
    btn.add_theme_stylebox_override("hover", sb)
    btn.add_theme_stylebox_override("pressed", sb)
    btn.add_theme_stylebox_override("focus", sb)

    var border_panel := Panel.new()
    border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var bsb := StyleBoxFlat.new()
    bsb.draw_center = false
    bsb.border_width_left = BUTTON_BORDER_W
    bsb.border_width_top = BUTTON_BORDER_W
    bsb.border_width_right = BUTTON_BORDER_W
    bsb.border_width_bottom = BUTTON_BORDER_W
    bsb.border_color = COLOR_BORDER
    bsb.corner_radius_top_left = BUTTON_RADIUS
    bsb.corner_radius_top_right = BUTTON_RADIUS
    bsb.corner_radius_bottom_left = BUTTON_RADIUS
    bsb.corner_radius_bottom_right = BUTTON_RADIUS
    border_panel.add_theme_stylebox_override("panel", bsb)
    btn.add_child(border_panel)

    var overlay := MarginContainer.new()
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_theme_constant_override("margin_left", BUTTON_PADDING_H)
    overlay.add_theme_constant_override("margin_right", BUTTON_PADDING_H)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.add_child(overlay)

    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(row)

    var lbl := Label.new()
    lbl.text = text
    _apply_label_style(lbl, FONT_SIZE_BTN)
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(lbl)

    var icon := TextureRect.new()
    var icon_tex := load(ICON_CHEVRON)
    if icon_tex:
        icon.texture = icon_tex
    else:
        push_error("Chevron failed to load: " + ICON_CHEVRON)
    icon.custom_minimum_size = Vector2(18, 18)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    icon.modulate = COLOR_TEXT
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(icon)

    return btn


func _make_settings_row() -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    row.size_flags_vertical = Control.SIZE_SHRINK_CENTER

    var icon := TextureRect.new()
    icon.texture = load(ICON_COG)
    icon.custom_minimum_size = Vector2(30, 30)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    icon.modulate = COLOR_TEXT
    row.add_child(icon)

    var lbl := Label.new()
    lbl.text = "SETTINGS"
    _apply_label_style(lbl, FONT_SIZE_LABEL)
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(lbl)

    return row


func _make_upload_row() -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    row.size_flags_vertical = Control.SIZE_SHRINK_CENTER

    var icon := TextureRect.new()
    icon.texture = load(ICON_CSV)
    icon.custom_minimum_size = Vector2(28, 28)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    icon.modulate = COLOR_TEXT
    row.add_child(icon)

    var text_col := VBoxContainer.new()
    text_col.add_theme_constant_override("separation", 4)
    text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(text_col)

    for t in ["UPLOAD", "CUSTOM CSV"]:
        var lbl := Label.new()
        lbl.text = t
        _apply_label_style(lbl, FONT_SIZE_LABEL)
        text_col.add_child(lbl)

    return row
