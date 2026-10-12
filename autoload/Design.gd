extends Node

# =====================================================================
# Design tokens — single source of truth for colors, sizes, paths.
# Named after Figma CSS variables but stripped of the "color-" prefix
# for readability in code (Design.BLACK vs Design.COLOR_BLACK).
# =====================================================================

# --- Colors ---
const BLACK                 := Color("#0a0a0a")
const WHITE                 := Color("#c8c8c8")
const GRAY                  := Color("#939393")
const TRANSPARENT_BLACK     := Color("#0a0a0acc")
const PRIMARY               := Color("#402d3d")
const BUTTON_BORDER         := Color("#00000059")
const SECONDARY             := Color("#325349")
const TERTIARY              := Color("#990000")
const FOURTH                := Color("#319194")
const INNER_BORDER          := Color("#054333")
const GLOBAL_CONTENT_BORDER := Color("#007d5c")
const FIVE                  := Color("#304e64")
const SIX                   := Color("#211f2d")
const SEVEN                 := Color("#ca7564")
const EIGHT                 := Color("#f5b061")
const DISABLED := Color("#373737")

# --- Layout ---
const SIDE_PADDING     := 16
const BUTTON_GAP       := 16
const BUTTON_HEIGHT    := 48
const BUTTON_PADDING_H := 16
const BUTTON_BORDER_W  := 3
const BUTTON_RADIUS    := 8
const BORDER_LINE_H    := 3
const HEADER_HEIGHT    := 62.0
const HEADER_LOGO_H    := 24.0
const FOOTER_HEIGHT    := 152.0

# --- Typography ---
const FONT_SIZE_BTN   := 14
const FONT_SIZE_LABEL := 14
const FONT_SIZE_TITLE := 16
# Figma letter-spacing 0.2% of 14px ≈ 0.03px → invisible in Godot.
const LETTER_SPACING_PX := 0.0
const LINE_SPACING_PX   := 0

# --- Motion ---
const HOVER_SCALE := 1.03
const PRESS_SCALE := 0.97
const HOVER_TIME  := 0.15
const PRESS_TIME  := 0.08

# --- Paths ---
const FONT_PATH      := "res://assets/fonts/FugazOne-Regular.ttf"
const BG_PATH        := "res://assets/MainMenuBackground.png"
const LOGO_PATH      := "res://assets/TruthOrDareLogo.svg"
const ICON_CHEVRON   := "res://assets/icons/chevron_double.svg"
const ICON_SEARCH    := "res://assets/icons/search.svg"
const ICON_COG       := "res://assets/icons/cog.svg"
const ICON_CLOSE     := "res://assets/icons/close.svg"
const ICON_HOUSE     := "res://assets/icons/house.svg"
const MUSIC_PATH     := "res://assets/audio/music.mp3"
const SFX_CLICK_PATH := "res://assets/audio/click.mp3"
const SFX_ERROR_PATH := "res://assets/audio/error.mp3"
const SFX_SUCCESS_PATH := "res://assets/audio/success.mp3"
const PLAYER_BG_PATH  := "res://assets/PlayerSetupBackground.png"
const AVATARS_DIR     := "res://assets/avatars/"
const ICON_DICE       := "res://assets/icons/dice.svg"
const ICON_SEND       := "res://assets/icons/send.svg"
const ICON_REMOVE     := "res://assets/icons/remove.svg"

# Cached font resources (loaded once at startup).
var font: FontFile
var font_variation: FontVariation


func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH) as FontFile
		font_variation = FontVariation.new()
		font_variation.base_font = font
		font_variation.spacing_glyph = int(LETTER_SPACING_PX)
	else:
		push_error("Font missing: " + FONT_PATH)


# Apply the standard typography style to a Label.
func apply_label(lbl: Label, font_size: int, color: Color = WHITE) -> void:
	if font_variation:
		lbl.add_theme_font_override("font", font_variation)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_constant_override("line_spacing", LINE_SPACING_PX)
	lbl.add_theme_color_override("font_color", color)
