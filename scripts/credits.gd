extends Control
## Opening credits / loading screen.
##
## HOW THIS WORKS:
## As soon as this scene starts, we kick off background loading of the next scene.
## At the same time, the logo animation plays.
## We only switch scenes when BOTH are done — animation finished AND scene loaded.
## This means the logo IS the loading screen, not a delay before it!
##
## Godot's background loader uses a separate thread (think of it like a second
## worker running in parallel) so loading doesn't freeze the animation.

var CreditsSong = preload("res://music/credits_theme.gd")

const FRAME_RATE: float = 3.0
const FRAME_COUNT: int = 4
const NEXT_SCENE: String = "res://scenes/title_screen.tscn"

var _frames: Array = []
var _current_frame: int = 0
var _frame_timer: float = 0.0
var _tween: Tween = null
var _anim_done: bool = false  # Has the fade-out finished?
var _load_done: bool = false  # Has the next scene finished loading?


func _ready() -> void:
	# Start the credits music
	var song = CreditsSong.new()
	$MusicPlayer.load_song(song.SONG_DATA)
	$MusicPlayer.play_song()

	# Kick off background loading of the title screen RIGHT AWAY.
	# This runs on a separate thread so the animation plays smoothly.
	ResourceLoader.load_threaded_request(NEXT_SCENE)

	# Also preload the game scene in the background while the credits play.
	# By the time the player picks a character and enters their name, the
	# heavy scene is already in memory — so the transition feels instant.
	ResourceLoader.load_threaded_request("res://scenes/game.tscn")

	# Load all 4 logo frames
	for i in range(FRAME_COUNT):
		var path: String = "res://textures/Logo_%d.png" % i
		if ResourceLoader.exists(path):
			_frames.append(load(path))

	if _frames.size() > 0:
		$LogoRect.texture = _frames[0]

	# Set up the fade in → hold → fade out sequence
	_tween = create_tween()
	_tween.tween_property($LogoRect, "modulate:a", 1.0, 1.0).from(0.0)
	_tween.tween_interval(6.0)
	_tween.tween_property($LogoRect, "modulate:a", 0.0, 1.0)
	_tween.tween_callback(_on_anim_done)


func _process(delta: float) -> void:
	# Animate logo frames
	if _frames.size() > 1:
		_frame_timer += delta
		if _frame_timer >= 1.0 / FRAME_RATE:
			_frame_timer = 0.0
			_current_frame = (_current_frame + 1) % FRAME_COUNT
			$LogoRect.texture = _frames[_current_frame]

	# Check if background loading has finished
	if not _load_done:
		var status = ResourceLoader.load_threaded_get_status(NEXT_SCENE)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_load_done = true
			_try_switch()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("playtest"):
		return
	# Skip straight to the camp with the test character (Knight + "Test")
	get_tree().set_meta("selected_character_index", 0)
	get_tree().set_meta("player_name", "Test")
	get_tree().set_meta("is_playtest", true)
	get_tree().set_meta("player_gold", 9999)
	# Give the tester 2 of each enemy ingredient plus a gold dust
	# and dark crystal for crafting a dungeon immediately!
	get_tree().set_meta("starting_bag_items", [
		{"id": "slime_essence", "level": 1, "count": 2},
		{"id": "bone_fragment", "level": 1, "count": 2},
		{"id": "shadow_wisp", "level": 1, "count": 2},
		{"id": "gold_dust", "level": 1, "count": 1},
		{"id": "dark_crystal", "level": 1, "count": 1},
	])
	$MusicPlayer.stop_song()
	get_tree().change_scene_to_file("res://scenes/camp.tscn")


func _on_anim_done() -> void:
	_anim_done = true
	_try_switch()


func _try_switch() -> void:
	# Only switch when BOTH conditions are met
	if not (_anim_done and _load_done):
		return
	$MusicPlayer.stop_song()
	var scene = ResourceLoader.load_threaded_get(NEXT_SCENE)
	get_tree().change_scene_to_packed(scene)


