extends Node

# Central audio. Music player + pools of one-shot SFX players.
# Pools let rapid sounds layer instead of cutting each other off.
#
# Public API: play_click(), play_error(), play_success().

signal music_toggled(is_on: bool)
signal sfx_toggled(is_on: bool)

const POOL_SIZE := 4

var music_enabled := true
var sfx_enabled := true

var _music_player: AudioStreamPlayer
var _click_players: Array[AudioStreamPlayer] = []
var _error_players: Array[AudioStreamPlayer] = []
var _success_players: Array[AudioStreamPlayer] = []
var _card_flip_players: Array[AudioStreamPlayer] = []
var _penalty_players: Array[AudioStreamPlayer] = []
var _game_over_players: Array[AudioStreamPlayer] = []
var _click_index := 0
var _error_index := 0
var _success_index := 0
var _card_flip_index := 0
var _penalty_index := 0
var _game_over_index := 0


func _ready() -> void:
	music_enabled = SaveManager.get_audio("music", true)
	sfx_enabled = SaveManager.get_audio("sfx", true)
	_setup_music()
	_setup_sfx()
	if not music_enabled and _music_player:
		_music_player.stream_paused = true


func _setup_music() -> void:
	if not ResourceLoader.exists(Design.MUSIC_PATH):
		push_warning("Music not found: " + Design.MUSIC_PATH)
		return
	var stream := load(Design.MUSIC_PATH)
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = stream
	_music_player.volume_db = -12.0
	add_child(_music_player)
	_music_player.play()


func _setup_sfx() -> void:
	_click_players     = _make_pool(Design.SFX_CLICK_PATH,     -6.0)
	_error_players     = _make_pool(Design.SFX_ERROR_PATH,     -6.0)
	_success_players   = _make_pool(Design.SFX_SUCCESS_PATH,   -6.0)
	_card_flip_players = _make_pool(Design.SFX_CARD_FLIP_PATH, -8.0)
	_penalty_players   = _make_pool(Design.SFX_PENALTY_PATH,   -6.0)
	_game_over_players = _make_pool(Design.SFX_GAME_OVER_PATH, -6.0)


func _make_pool(path: String, volume_db: float) -> Array[AudioStreamPlayer]:
	var out: Array[AudioStreamPlayer] = []
	if not ResourceLoader.exists(path):
		push_warning("SFX not found: " + path)
		return out
	var stream := load(path)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = volume_db
		add_child(p)
		out.append(p)
	return out


# Public API -----------------------------------------------------------

func play_click() -> void:
	_play_pool(_click_players, "click")

func play_error() -> void:
	_play_pool(_error_players, "error")

func play_success() -> void:
	_play_pool(_success_players, "success")

func play_card_flip() -> void:
	_play_pool(_card_flip_players, "card_flip")

func play_penalty() -> void:
	_play_pool(_penalty_players, "penalty")

func play_game_over() -> void:
	_play_pool(_game_over_players, "game_over")


func _play_pool(players: Array[AudioStreamPlayer], kind: String) -> void:
	if not sfx_enabled or players.is_empty():
		return
	var idx: int
	match kind:
		"click":     idx = _click_index;     _click_index     = (_click_index     + 1) % players.size()
		"error":     idx = _error_index;     _error_index     = (_error_index     + 1) % players.size()
		"success":   idx = _success_index;   _success_index   = (_success_index   + 1) % players.size()
		"card_flip": idx = _card_flip_index; _card_flip_index = (_card_flip_index + 1) % players.size()
		"penalty":   idx = _penalty_index;   _penalty_index   = (_penalty_index   + 1) % players.size()
		"game_over": idx = _game_over_index; _game_over_index = (_game_over_index + 1) % players.size()
		_: return
	var p := players[idx]
	p.stop()
	p.play()


func set_music_enabled(is_on: bool) -> void:
	if music_enabled == is_on:
		return
	music_enabled = is_on
	if _music_player:
		_music_player.stream_paused = not is_on
	SaveManager.set_audio("music", is_on)
	music_toggled.emit(is_on)


func set_sfx_enabled(is_on: bool) -> void:
	if sfx_enabled == is_on:
		return
	sfx_enabled = is_on
	SaveManager.set_audio("sfx", is_on)
	sfx_toggled.emit(is_on)
