extends Node2D
## Camp hub world — the player's home base between dungeon runs.
##
## This is the central hub where the player walks around and visits
## stations like the Forge, Weapon Shop, and Dungeon Entrance.
## Each station is an "interactable" — walk near it and press E!
##
## Key concept: **hub world pattern**.
## Instead of putting everything in one big scene, we use a small
## safe area (the camp) that connects to other scenes (dungeons).
## This is how many RPGs work — think of the town in Zelda or the
## hub in Hades.  It gives the player a calm place to prepare
## before diving into action.

var CampSong = preload("res://music/camp.gd")


func _ready() -> void:
	# Load gold from SceneTree metadata and update the HUD.
	var gold: int = get_tree().get_meta("player_gold", 0)
	$HUD.update_gold(gold)

	# Play the camp background music.
	$MusicPlayer.load_song(CampSong.new().SONG_DATA)
	$MusicPlayer.play_song()


func _unhandled_input(event: InputEvent) -> void:
	# Don't process input while an overlay is open
	if $UnlockPrompt.is_open:
		return
	if has_node("ForgeUI") and $ForgeUI.is_open:
		return
	if has_node("ShopUI") and $ShopUI.is_open:
		return
	if has_node("ChatConsole") and $ChatConsole.is_open:
		return
	if has_node("DungeonCraftUI") and $DungeonCraftUI.is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		# Save the player's inventory and gold before leaving.
		_save_player_state()
		$MusicPlayer.stop_song()
		get_tree().change_scene_to_file("res://scenes/file_select.tscn")


## Called by locked stations when the player tries to interact with them.
## Opens the unlock prompt overlay showing the station name, description,
## and cost with an "UNLOCK" button.
func show_unlock_prompt(station: Node2D, station_name: String, desc: String, cost: int) -> void:
	$UnlockPrompt.open(station, station_name, desc, cost)


## Saves the player's inventory and gold to SceneTree metadata.
## This is called before any scene transition so nothing is lost.
func _save_player_state() -> void:
	var player: Node2D = $Player
	get_tree().set_meta("player_inventory", player.inventory.duplicate(true))
