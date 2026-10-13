extends Node

# --- Colors ---
const BLACK := Color("#000000")
const WHITE := Color("#fffade")
const GRAY := Color("#83808e")
const TRANSPARENT_BLACK := Color("#000000cc")
const PRIMARY := Color("#393772")
const BUTTON_BORDER := Color("#00000059")
const SECONDARY := Color("#702224")
const TERTIARY := Color("#7a111d")
const FOURTH := Color("#aca3e9")
const INNER_BORDER := Color("#292746")
const GLOBAL_CONTENT_BORDER := Color("#534e8c")
const FIVE := Color("#25265e")
const SIX := Color("#161638")
const SEVEN := Color("#c04143")
const EIGHT := Color("#005a36")
const DISABLED := Color("#2c2b30")

# Error text — bright red, high contrast on black.
const ERROR_TEXT := Color("#ff5c5c")

# --- Category Colors (badge backgrounds) ---
const CATEGORY_COLORS := {
	"sober":  SECONDARY,
	"tipsy":  PRIMARY,
	"drunk":  TERTIARY,
	"wasted": FIVE,
}

# --- Category Display Colors (footer text; bright for contrast on black) ---
const ODDS_DISPLAY_COLORS := {
	"sober":  Color("#4fc3c6"),
	"tipsy":  Color("#b8a8f0"),
	"drunk":  Color("#e87878"),
	"wasted": Color("#7da3e8"),
}

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
const LETTER_SPACING_PX := 0.0
const LINE_SPACING_PX   := 0

# --- Motion ---
const HOVER_SCALE := 1.03
const PRESS_SCALE := 0.97
const HOVER_TIME  := 0.15
const PRESS_TIME  := 0.08

# --- Paths ---
const FONT_PATH        := "res://assets/fonts/FugazOne-Regular.ttf"

const MERIENDA_REGULAR_PATH := "res://assets/fonts/Merienda-Regular.ttf"
const MERIENDA_BOLD_PATH    := "res://assets/fonts/Merienda-ExtraBold.ttf"
const MERIENDA_LIGHT_PATH   := "res://assets/fonts/Merienda-Light.ttf"

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
const SFX_SUCCESS_PATH := "res://assets/audio/success.wav"
const SFX_CARD_FLIP_PATH := "res://assets/audio/card_flip.mp3"
const SFX_PENALTY_PATH   := "res://assets/audio/penalty.wav"
const PLAYER_BG_PATH  := "res://assets/PlayerSetupBackground.png"
const AVATARS_DIR     := "res://assets/avatars/"
const ICON_DICE       := "res://assets/icons/dice.svg"
const ICON_SEND       := "res://assets/icons/send.svg"
const ICON_REMOVE     := "res://assets/icons/remove.svg"
const ICON_COPY       := "res://assets/icons/copy.svg"
const ICON_FORFEIT    := "res://assets/icons/forfeit.svg"
const ICON_ARROW_DOWN       := "res://assets/icons/arrow_down.svg"
const ICON_ARROW_UP         := "res://assets/icons/arrow_up.svg"
const ICON_CHECKBOX         := "res://assets/icons/checkbox.svg"
const ICON_CHECKBOX_CHECKED := "res://assets/icons/checkbox_checked.svg"
const ICON_RESTART          := "res://assets/icons/restart.svg"

const GAME_BG_PATH    := "res://assets/GameBackground.png"
const TRUTH_TITLE_PATH := "res://assets/TruthTitle.svg"
const DARE_TITLE_PATH  := "res://assets/DareTitle.svg"

# Cached resources
var font: FontFile
var font_variation: FontVariation

var font_merienda: FontFile
var font_merienda_bold: FontFile
var font_merienda_light: FontFile
var font_merienda_var: FontVariation
var font_merienda_bold_var: FontVariation
var font_merienda_light_var: FontVariation


func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH) as FontFile
		font_variation = FontVariation.new()
		font_variation.base_font = font
		font_variation.spacing_glyph = int(LETTER_SPACING_PX)
	else:
		push_error("Font missing: " + FONT_PATH)

	if ResourceLoader.exists(MERIENDA_REGULAR_PATH):
		font_merienda = load(MERIENDA_REGULAR_PATH) as FontFile
		font_merienda_var = FontVariation.new()
		font_merienda_var.base_font = font_merienda
	if ResourceLoader.exists(MERIENDA_BOLD_PATH):
		font_merienda_bold = load(MERIENDA_BOLD_PATH) as FontFile
		font_merienda_bold_var = FontVariation.new()
		font_merienda_bold_var.base_font = font_merienda_bold
	if ResourceLoader.exists(MERIENDA_LIGHT_PATH):
		font_merienda_light = load(MERIENDA_LIGHT_PATH) as FontFile
		font_merienda_light_var = FontVariation.new()
		font_merienda_light_var.base_font = font_merienda_light


func apply_label(lbl: Label, font_size: int, color: Color = WHITE) -> void:
	if font_variation:
		lbl.add_theme_font_override("font", font_variation)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_constant_override("line_spacing", LINE_SPACING_PX)
	lbl.add_theme_color_override("font_color", color)


# Apply markup-aware Merienda fonts to a RichTextLabel.
# [b] uses ExtraBold, [i] uses Light (Merienda has no true italic).
func apply_rich(rich: RichTextLabel, font_size: int, color: Color = WHITE) -> void:
	rich.bbcode_enabled = true
	rich.add_theme_font_size_override("normal_font_size", font_size)
	rich.add_theme_color_override("default_color", color)
	if font_merienda_var:
		rich.add_theme_font_override("normal_font", font_merienda_var)
	if font_merienda_bold_var:
		rich.add_theme_font_override("bold_font", font_merienda_bold_var)
		rich.add_theme_font_override("bold_italics_font", font_merienda_bold_var)
	if font_merienda_light_var:
		rich.add_theme_font_override("italics_font", font_merienda_light_var)
	# Fall back to FugazOne if Merienda failed to load
	if not font_merienda_var and font_variation:
		rich.add_theme_font_override("normal_font", font_variation)
