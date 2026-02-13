extends Control
## Name Entry screen — the player types a name for their chosen character.
##
## This screen reads which character was selected (from set_meta on the
## previous screen), displays it, and provides a text input box.
##
## Key concept: **LineEdit** — a built-in Godot node that handles ALL
## keyboard input for a text box.  You don't need to manually track
## keypresses or build a cursor — Godot does it all for you!
##
## Key concept: **grab_focus()** — tells Godot "this is the active UI
## element."  Without this, the LineEdit wouldn't receive keyboard input
## because Godot doesn't know you want to type in it.  Think of it like
## clicking on a text box in a web page — you need to "focus" it first.
##
## Key concept: **signals** — Godot's event system.  When the player
## presses Enter in the LineEdit, it fires a "text_submitted" signal.
## We connect that signal to our function with .connect(), so our code
## runs automatically when Enter is pressed.  It's like saying:
## "Hey LineEdit, when the user presses Enter, call MY function."

# ── Shared data ───────────────────────────────────────────────────────
const CharData = preload("res://scripts/character_data.gd")

# ── State ─────────────────────────────────────────────────────────────

## Which character index was chosen on the previous screen.
var character_index: int = 0

## Guard flag — prevents double-transitions.
var transitioning: bool = false

# ── Node references ───────────────────────────────────────────────────

@onready var sprite: Node2D = $InfoPanel/Sprite
@onready var class_label: Label = $InfoPanel/ClassName
@onready var name_input: LineEdit = $NameInput


func _ready() -> void:
	# Read which character the player selected on the previous screen.
	# get_meta() retrieves the value stored by set_meta() on the character
	# select screen.  If somehow it's missing, default to 0 (first character).
	character_index = get_tree().get_meta("selected_character_index", 0)

	# Look up the character data and display it.
	var chars: Array = CharData.characters()
	var character: Dictionary = chars[character_index]
	sprite.set_character(character)
	class_label.text = character.name

	# ── Set up the text input ──
	# grab_focus() makes the LineEdit the "active" element — without this,
	# the player would have to click on it before they could type!
	name_input.grab_focus()

	# Connect the "text_submitted" signal to our handler function.
	# This signal fires when the player presses Enter while typing.
	# .connect() takes a Callable — that's just a reference to a function.
	# So _on_name_submitted will be called with the text as its argument.
	name_input.text_submitted.connect(_on_name_submitted)


func _on_name_submitted(text: String) -> void:
	## Called when the player presses Enter in the text box.
	if transitioning:
		return

	# strip_edges() removes spaces from the start/end of the text.
	# We don't want someone to submit a name that's all spaces!
	var clean_name: String = text.strip_edges()

	# If the name is empty after stripping spaces, don't accept it.
	if clean_name.is_empty():
		return

	# Store the player's name and character choice on the SceneTree
	# so the game scene can read them later.
	transitioning = true
	get_tree().set_meta("player_name", clean_name)
	get_tree().set_meta("selected_character_index", character_index)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _input(event: InputEvent) -> void:
	# We use _input() instead of _unhandled_input() here because the
	# LineEdit "consumes" the Escape key (it uses it to release focus).
	# _input() fires BEFORE the LineEdit sees the event, so we can
	# catch Escape and go back to character select.
	#
	# Regular typing keys still reach the LineEdit because we only
	# handle ui_cancel here — everything else passes through!
	if transitioning:
		return

	if event.is_action_pressed("ui_cancel"):
		transitioning = true
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")
		get_viewport().set_input_as_handled()
