extends Control
## Character Select carousel — lets the player browse through 20 characters.
##
## This screen shows one character at a time with a pixel-art sprite and name.
## The player cycles through them with A/D or arrow keys, then presses Enter
## to pick one and move on to naming their hero.
##
## Key concept: **wrapping with modulo (%)**.
## When you're on character 20 and press Right, you don't want to stop —
## you want to WRAP around back to character 1.  The modulo operator (%)
## gives us the remainder after division, which naturally wraps:
##   (19 + 1) % 20 = 0   →  last character wraps to first!
##   (0 - 1 + 20) % 20 = 19  →  first character wraps to last!
##
## Key concept: **passing data between scenes with set_meta/get_meta**.
## When the player picks a character and moves to the name entry screen,
## we need to tell that screen WHICH character was picked.  We store the
## index on the SceneTree itself (which survives scene changes) using
## set_meta("key", value).  The next scene reads it with get_meta("key").

# ── Shared data ───────────────────────────────────────────────────────
# preload() loads the character_data.gd script at compile time.
# This gives us access to all 20 character definitions (grids + palettes).
# We use preload instead of class_name because preload works even if
# Godot hasn't scanned the project for new class_name declarations yet.
const CharData = preload("res://scripts/character_data.gd")

# ── State ─────────────────────────────────────────────────────────────

## Which character (0–19) is currently displayed.
var selected_index: int = 0

## Guard flag — prevents double-transitions when mashing keys.
var transitioning: bool = false

# ── Node references ───────────────────────────────────────────────────
# @onready means "grab this node reference AFTER the scene tree is built."
# The $ syntax is shorthand for get_node() — it finds a child by its path.

@onready var sprite: Node2D = $CharacterPanel/Sprite
@onready var class_label: Label = $CharacterPanel/ClassName
@onready var counter_label: Label = $CharacterPanel/Counter


func _ready() -> void:
	# If the player is coming BACK from the name entry screen (pressed Esc),
	# restore the character they had selected.  get_meta() reads a value
	# that was stored on the SceneTree.  The second argument (0) is the
	# default — used if no value was stored yet (first visit).
	selected_index = get_tree().get_meta("selected_character_index", 0)
	_update_display()


func _unhandled_input(event: InputEvent) -> void:
	# Ignore everything while a scene transition is happening.
	if transitioning:
		return

	# Only react to fresh key presses, not key releases.
	if not event.is_pressed():
		return

	# ── Left/Right navigation (with wrapping!) ────────────────────
	if event.is_action("move_right"):
		# Move to the next character.
		# The % (modulo) operator wraps around: 19 + 1 = 20, 20 % 20 = 0
		# So after the last character (index 19), we go back to the first (index 0)!
		var total: int = CharData.characters().size()
		selected_index = (selected_index + 1) % total
		_update_display()
		get_viewport().set_input_as_handled()

	elif event.is_action("move_left"):
		# Move to the previous character.
		# We add "total" before subtracting to avoid negative numbers:
		# (0 - 1 + 20) % 20 = 19 — wraps from first to last!
		var total: int = CharData.characters().size()
		selected_index = (selected_index - 1 + total) % total
		_update_display()
		get_viewport().set_input_as_handled()

	elif event.is_action("ui_accept"):
		# Enter/Space — the player chose this character!
		# Store the selection on the SceneTree so the name entry screen
		# can read it.  set_meta() saves a key-value pair that survives
		# scene changes (unlike regular variables which are destroyed).
		transitioning = true
		get_tree().set_meta("selected_character_index", selected_index)
		get_tree().change_scene_to_file("res://scenes/name_entry.tscn")
		get_viewport().set_input_as_handled()

	elif event.is_action("ui_cancel"):
		# Escape — go back to the file select screen.
		transitioning = true
		get_tree().change_scene_to_file("res://scenes/file_select.tscn")
		get_viewport().set_input_as_handled()


func _update_display() -> void:
	## Refreshes the sprite, name label, and counter to show the current character.
	var chars: Array = CharData.characters()
	var character: Dictionary = chars[selected_index]

	# Tell the sprite node to draw the new character's pixel art.
	# set_character() stores the grid + palette and triggers a redraw.
	sprite.set_character(character)

	# Update the text labels.
	class_label.text = character.name
	counter_label.text = "%d / %d" % [selected_index + 1, chars.size()]
