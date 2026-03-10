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

func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	# Don't process input while the chat console is open
	if has_node("ChatConsole") and $ChatConsole.is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		# If the dungeon is already complete (transitioning), ignore.
		if has_node("DungeonManager") and $DungeonManager.is_complete:
			return

		# Save inventory before returning to camp so nothing is lost.
		var player: Node2D = $Player
		get_tree().set_meta("player_inventory", player.inventory.duplicate(true))

		# Clear the dungeon recipe since the player is abandoning the run.
		# Next time they enter, they'll need to craft a new dungeon.
		if get_tree().has_meta("dungeon_recipe"):
			get_tree().remove_meta("dungeon_recipe")

		get_tree().change_scene_to_file("res://scenes/camp.tscn")
