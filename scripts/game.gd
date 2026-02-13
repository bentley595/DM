extends Node2D
## Main game scene — where gameplay happens!
##
## The Player node is an instanced sub-scene (player.tscn) that handles
## its own setup — it reads the character choice and name from SceneTree
## metadata automatically in its _ready() function.
##
## Key concept: **scene instancing**.
## The Player is a separate scene (player.tscn) placed inside this scene.
## This is how real games work — you build small, reusable pieces (player,
## enemies, items) as their own scenes, then combine them in a level scene.
## For multiplayer later, you'd instance multiple player scenes!


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Escape goes back to file select.
		get_tree().change_scene_to_file("res://scenes/file_select.tscn")
