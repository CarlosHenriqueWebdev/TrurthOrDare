extends Node

# Scene router. Screens call Navigation.go_to(path) instead of
# get_tree().change_scene_to_file() so routing lives in one place and
# we can add transitions later without touching every screen.

const HOME := "res://scenes/Home.tscn"
const PLAYER_SETUP := "res://scenes/PlayerSetup.tscn"
const GAME         := "res://scenes/Game.tscn"
const PREVIEW      := "res://scenes/Preview.tscn"

var current_path: String = ""


func go_to(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return
	current_path = scene_path
	get_tree().change_scene_to_file(scene_path)


func go_home() -> void:
	go_to(HOME)
