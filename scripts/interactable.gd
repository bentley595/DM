extends Node2D
## Base class for interactive stations in the camp.
##
## Any node that extends this script automatically:
##   1. Adds itself to the "interactable" group (so the player can find it)
##   2. Draws a pixel-art "[E]" prompt when the player is nearby
##   3. Calls on_interact() when the player presses E
##
## Key concept: **inheritance for shared behavior**.
## Instead of copy-pasting the same proximity check and prompt code into
## every station, we put it in this BASE class.  Each station (forge,
## shop, dungeon) EXTENDS this class and only needs to override two
## functions:
##   _draw_station() → draw your unique pixel art
##   on_interact()   → what happens when E is pressed
##
## This is the same idea as how all HUD bars share hud_bar.gd — write
## the common code once, customize per-station!

# ── Interaction settings ────────────────────────────────────────
## How close the player needs to be (in pixels) to see the "[E]" prompt
## and to trigger on_interact().
const INTERACT_DISTANCE: float = 30.0

# ── Unlock system ──────────────────────────────────────────────
## How much gold this station costs to unlock.  0 = free (always open).
var unlock_cost: int = 0

## Whether this station is currently unlocked.
var is_unlocked: bool = true

## The key used in SceneTree metadata to remember unlock state.
## Each station sets this to something unique like "unlocked_forge".
var unlock_meta_key: String = ""

# ── Prompt state ────────────────────────────────────────────────
## True when the player is close enough to interact.
var _show_prompt: bool = false

# ── "[E]" prompt bitmap ─────────────────────────────────────────
## A tiny 3×5 letter "E" drawn above the station when in range.
const LETTER_E: Array = [
	[1, 1, 1],
	[1, 0, 0],
	[1, 1, 0],
	[1, 0, 0],
	[1, 1, 1],
]

const PROMPT_COLOR: Color = Color(0.9, 0.75, 0.3, 1.0)      # gold
const PROMPT_BG: Color    = Color(0.06, 0.06, 0.14, 0.85)    # dark bg
const PROMPT_BORDER: Color = Color(0.55, 0.55, 0.75, 1.0)    # light border
const LOCKED_COLOR: Color = Color(0.5, 0.5, 0.5, 1.0)        # grey for locked


func _ready() -> void:
	# Add ourselves to the "interactable" group — same pattern as
	# how the training dummy adds to "targetable".  The player checks
	# this group every frame to find nearby interactables.
	add_to_group("interactable")

	# Check if this station was already unlocked in a previous visit.
	if unlock_cost > 0 and unlock_meta_key != "":
		is_unlocked = get_tree().get_meta(unlock_meta_key, false)
		# In playtest mode, everything is auto-unlocked!
		if get_tree().get_meta("is_playtest", false):
			is_unlocked = true


func _process(_delta: float) -> void:
	# Find the player and check distance.
	# We look for nodes in the "interactable" group's scene tree — the
	# player is always a sibling of interactables in the camp scene.
	var player: Node2D = _find_player()
	if player == null:
		if _show_prompt:
			_show_prompt = false
			queue_redraw()
		return

	var in_range: bool = global_position.distance_to(player.global_position) <= INTERACT_DISTANCE
	if in_range != _show_prompt:
		_show_prompt = in_range
		queue_redraw()


func _draw() -> void:
	# First draw the station's unique art (overridden by subclasses)
	_draw_station()

	# Then draw the "[E]" prompt if the player is nearby
	if _show_prompt:
		_draw_prompt()


func _draw_station() -> void:
	## Override this in subclasses to draw your station's pixel art.
	## Works exactly like training_dummy.gd's _draw() — loop through
	## a grid array and draw colored rectangles.
	pass


func on_interact() -> void:
	## Override this in subclasses to handle what happens when E is pressed.
	## For example: open the forge UI, open the shop UI, or transition
	## to the dungeon scene.
	pass


func _draw_prompt() -> void:
	## Draws a small "[E]" indicator above the station.
	## This tells the player they can press E to interact!
	# Position: centered above the station, 20px up from center
	var px: int = -5   # center a 9px wide box
	var py: int = -28  # above the station art

	# Background box
	draw_rect(Rect2(px, py, 9, 9), PROMPT_BG)
	# Border
	draw_rect(Rect2(px, py, 9, 1), PROMPT_BORDER)
	draw_rect(Rect2(px, py + 8, 9, 1), PROMPT_BORDER)
	draw_rect(Rect2(px, py, 1, 9), PROMPT_BORDER)
	draw_rect(Rect2(px + 8, py, 1, 9), PROMPT_BORDER)

	# Draw the "E" letter centered in the box
	var color: Color = PROMPT_COLOR if is_unlocked else LOCKED_COLOR
	for row in 5:
		for col in 3:
			if LETTER_E[row][col] == 1:
				draw_rect(Rect2(px + 3 + col, py + 2 + row, 1, 1), color)


func _find_player() -> Node2D:
	## Finds the Player node.  Since both the player and interactables
	## are children of the Camp scene, we look up the tree to our parent
	## and find Player there.
	var parent: Node = get_parent()
	if parent and parent.has_node("Player"):
		return parent.get_node("Player")
	return null
