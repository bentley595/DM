extends Control

# This timer tracks how long until we toggle the "press any key" text
var blink_timer: float = 0.0
# How fast the text blinks (in seconds per toggle)
var blink_speed: float = 0.6
# Whether the prompt text is currently visible
var prompt_visible: bool = true
# Guard flag — once we start switching scenes, ignore further key presses.
# Without this, mashing keys could trigger the transition multiple times!
var transitioning: bool = false


func _ready() -> void:
	# When the scene first loads, nothing special to set up yet.
	# Later, this is where you'd start music or animations!
	pass


func _process(delta: float) -> void:
	# delta is the time (in seconds) since the last frame.
	# We use it to make the blinking work at a steady speed
	# no matter how fast or slow the computer runs.

	blink_timer += delta

	if blink_timer >= blink_speed:
		# Enough time has passed — flip the visibility!
		blink_timer = 0.0
		prompt_visible = not prompt_visible
		$CenterContainer/VBoxContainer/PromptLabel.visible = prompt_visible


func _unhandled_input(event: InputEvent) -> void:
	# This function is called whenever the player presses a key,
	# clicks the mouse, or uses a gamepad — anything Godot considers "input".

	# We check if it's a "pressed" event (not a release) to avoid
	# triggering twice (once on press, once on release).
	if event.is_pressed() and not transitioning:
		# Set the guard so rapid key presses don't trigger this again.
		transitioning = true
		# Switch to the file select screen!
		# change_scene_to_file() unloads the current scene and loads the new one.
		get_tree().change_scene_to_file("res://scenes/file_select.tscn")
