extends Node

# Central audio. Owns the music player and the click SFX pool.
# Components and screens never touch AudioStreamPlayer directly — they call
# AudioManager.play_click(), and settings UIs toggle music/sfx here.
#
# Why a pool for SFX: a single AudioStreamPlayer can only play one instance
# at a time. Cycling 4 players lets rapid clicks layer instead of cutting
# each other off.

signal music_toggled(is_on: bool)
signal sfx_toggled(is_on: bool)

const SFX_POOL_SIZE := 4

var music_enabled := true
var sfx_enabled := true

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0


func _ready() -> void:
	_setup_music()
	_setup_sfx()


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
	if not ResourceLoader.exists(Design.SFX_CLICK_PATH):
		push_warning("Click SFX not found: " + Design.SFX_CLICK_PATH)
		return
	var stream := load(Design.SFX_CLICK_PATH)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -6.0
		add_child(p)
		_sfx_players.append(p)


# Public API -----------------------------------------------------------

func play_click() -> void:
	if not sfx_enabled or _sfx_players.is_empty():
		return
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stop()
	p.play()


func set_music_enabled(is_on: bool) -> void:
	if music_enabled == is_on:
		return
	music_enabled = is_on
	if _music_player:
		_music_player.stream_paused = not is_on
	music_toggled.emit(is_on)


func set_sfx_enabled(is_on: bool) -> void:
	if sfx_enabled == is_on:
		return
	sfx_enabled = is_on
	sfx_toggled.emit(is_on)
