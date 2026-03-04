extends Node2D
## A custom pixel-art cursor that replaces the boring OS arrow.
##
## Key concept: **Input.set_mouse_mode()**.
## This tells Godot what to do with the operating system's mouse cursor.
## MOUSE_MODE_HIDDEN hides it completely, so we can draw our OWN cursor
## using the same _draw() pixel-art technique as everything else in the game.
## MOUSE_MODE_VISIBLE brings it back (used when leaving the game scene).
##
## Key concept: **Groups**.
## Godot lets you tag any node with a string label (a "group").  Then you
## can ask the SceneTree: "give me ALL nodes tagged with this label."
## We use the group "targetable" to find things the player can attack.
## The training dummy adds itself to "targetable" in its _ready(), and
## this cursor script checks that group every frame to see if we're
## hovering over something hittable.  It's like a name badge system —
## any node wearing the "targetable" badge gets noticed!
##
## The cursor has two modes:
##   - Crosshair: normal aiming mode (a tactical scope shape)
##   - Sword: hovering over something you can attack
##
## NEW: Rainbow mode!
## At max momentum (50 stacks), the crosshair turns rainbow.  This uses
## **HSV color space** — instead of picking a fixed color like "white" or
## "blue", we rotate the HUE (position on the color wheel) over time.
## Each pixel gets a slightly different hue based on its grid position,
## which creates a rippling rainbow wave across the crosshair.

# ── Pixel-art settings ─────────────────────────────────────────────
## Each grid cell = 1 viewport pixel = 4 screen pixels at our 4× scale.
const PIXEL_SIZE: int = 1

## Palette — just two colors plus transparent.
## White is bright and easy to see on our dark background.
## Light steel blue adds subtle detail without being distracting.
const CURSOR_PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(1.0, 1.0, 1.0, 1.0),     # 1: white — main cursor color
	Color(0.7, 0.75, 0.9, 1.0),    # 2: light steel blue — detail
]

# ── Crosshair grid (9×9) ────────────────────────────────────────────
## An upgraded "tactical scope" crosshair.  Compared to the old 7×7 "+"
## shape, this one has:
##   - Longer cross arms (3 pixels each) with a white-blue-white gradient
##   - 4 corner markers at the diagonals (like a targeting scope)
##   - Empty center pixel for precise aiming
## The corner markers are what make it look "advanced" — they frame your
## target like a sniper scope!
const CROSSHAIR_GRID: Array = [
	[0, 0, 0, 0, 1, 0, 0, 0, 0],
	[0, 2, 0, 0, 2, 0, 0, 2, 0],
	[0, 0, 0, 0, 1, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[1, 2, 1, 0, 0, 0, 1, 2, 1],
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 1, 0, 0, 0, 0],
	[0, 2, 0, 0, 2, 0, 0, 2, 0],
	[0, 0, 0, 0, 1, 0, 0, 0, 0],
]

# ── Sword grid (7×9) ──────────────────────────────────────────────
## An upgraded sword icon with a longer blade, fuller crossguard, and
## pommel at the bottom.  Compared to the old 5×7 version, this one
## has more detail:
##   - Pointed tip (1px) → blade widens as it goes down
##   - Fuller on the blade (the blue detail pixels)
##   - Wide crossguard with accent details
##   - Wrapped handle with pommel
## Shows up when hovering over something hittable — visual hint for
## "you can attack this!"
const SWORD_GRID: Array = [
	[0, 0, 0, 1, 0, 0, 0],
	[0, 0, 1, 2, 1, 0, 0],
	[0, 0, 1, 2, 1, 0, 0],
	[0, 0, 1, 2, 1, 0, 0],
	[0, 0, 2, 1, 2, 0, 0],
	[1, 2, 1, 2, 1, 2, 1],
	[0, 1, 0, 2, 0, 1, 0],
	[0, 0, 0, 2, 0, 0, 0],
	[0, 0, 1, 1, 1, 0, 0],
]

# ── State ──────────────────────────────────────────────────────────
## Which grid we're currently drawing — crosshair or sword.
var current_grid: Array = CROSSHAIR_GRID

## Track the current mode so we only call queue_redraw() when it CHANGES.
## Calling queue_redraw() every frame would work but waste tiny amounts
## of effort.  This is a micro-optimization but also a good habit!
var is_sword_mode: bool = false

## Reference to the Player node so we can read their momentum.
## We find this in _ready() by climbing up the scene tree.
var _player: Node2D = null

## Timer that drives the rainbow hue rotation.
## It counts up every frame (in seconds) and we use it to calculate
## which color on the rainbow wheel to show.
var _rainbow_time: float = 0.0

## Whether rainbow was active LAST frame.
## We need this so when rainbow turns OFF, we do one final redraw
## to switch back to the normal white/blue palette.
var _was_rainbow: bool = false


func _ready() -> void:
	# Hide the operating system cursor.  From now on, only our pixel-art
	# cursor will be visible.  This is what makes it feel like a "real"
	# game cursor instead of having both the OS arrow AND our crosshair.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Set z_index very high so the cursor always draws on top of everything.
	# z_index is Godot's way of controlling draw order — higher = drawn later = on top.
	z_index = 100

	# Find the Player node.
	# The cursor lives inside CursorLayer (a CanvasLayer), which is a child
	# of the main scene root (Game or Camp).  So we go up two levels:
	#   Cursor → CursorLayer → Game/Camp
	# Then look for a child named "Player".
	var scene_root = get_parent().get_parent()
	if scene_root and scene_root.has_node("Player"):
		_player = scene_root.get_node("Player")


func _exit_tree() -> void:
	# When this node leaves the scene (e.g., pressing Escape to go back
	# to the menu), restore the OS cursor.  Without this, you'd have NO
	# visible cursor on the menu screens!
	#
	# Key concept: **_exit_tree()** is the cleanup callback.
	# Just like _ready() runs when a node ENTERS the scene, _exit_tree()
	# runs when it LEAVES.  It's the perfect place to undo anything
	# _ready() set up.  This pattern (setup in _ready, cleanup in
	# _exit_tree) keeps things self-contained — the cursor manages itself!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(delta: float) -> void:
	# Move the cursor to wherever the mouse is.
	# get_global_mouse_position() returns game-world coordinates (320×180),
	# not screen coordinates (1280×720).  Godot handles the 4× scaling
	# automatically thanks to stretch mode "viewport".
	position = get_global_mouse_position()

	# Check if we're hovering over anything in the "targetable" group.
	var hovering: bool = _is_hovering_target()
	var mode_changed: bool = false

	# Only switch grids when the mode actually changes.
	if hovering and not is_sword_mode:
		is_sword_mode = true
		current_grid = SWORD_GRID
		mode_changed = true
	elif not hovering and is_sword_mode:
		is_sword_mode = false
		current_grid = CROSSHAIR_GRID
		mode_changed = true

	# Check if the player is at max momentum (rainbow time!)
	var is_rainbow: bool = _player != null and _player.momentum >= _player.MAX_MOMENTUM

	if is_rainbow:
		# During rainbow mode, colors change every single frame, so we
		# MUST redraw every frame.  This is one of the few times where
		# calling queue_redraw() every frame is the right thing to do!
		_rainbow_time += delta
		queue_redraw()
	elif _was_rainbow:
		# Rainbow just turned off — need one final redraw to go back
		# to the normal white/blue colors.
		queue_redraw()
	elif mode_changed:
		# Normal mode — only redraw when switching crosshair ↔ sword.
		queue_redraw()

	_was_rainbow = is_rainbow


func _is_hovering_target() -> bool:
	## Checks if the mouse is close enough to any "targetable" node.
	##
	## We use a simple rectangle check: ±10 pixels horizontal, ±14 pixels
	## vertical.  This is a generous hitbox — it feels better when the
	## cursor changes a little BEFORE you're perfectly centered on the
	## target, because it signals "hey, you can hit this!"
	##
	## Key concept: **get_tree().get_nodes_in_group()**.
	## This is the other half of the groups system.  Any node that called
	## add_to_group("targetable") will show up in this list.  It's like
	## calling roll in a classroom — everyone wearing the "targetable"
	## badge raises their hand!
	var targets: Array = get_tree().get_nodes_in_group("targetable")
	for target in targets:
		var diff: Vector2 = position - target.global_position
		if absf(diff.x) <= 10 and absf(diff.y) <= 14:
			return true
	return false


func _draw() -> void:
	# Same _draw() pattern used everywhere in the game!
	# Loop through the grid, skip transparent (0), draw colored pixels.
	var grid_height: int = current_grid.size()
	var grid_width: int = current_grid[0].size()

	# Center the grid on the cursor position.
	# Without this, the top-left corner of the grid would be at the
	# mouse position, which would feel offset and weird.
	var offset_x: float = -grid_width * PIXEL_SIZE / 2.0
	var offset_y: float = -grid_height * PIXEL_SIZE / 2.0

	# Check rainbow mode once so we don't recalculate it per-pixel.
	var is_rainbow: bool = _player != null and _player.momentum >= _player.MAX_MOMENTUM

	for row in grid_height:
		for col in grid_width:
			var color_index: int = current_grid[row][col]
			if color_index == 0:
				continue

			var color: Color
			if is_rainbow:
				# ── Rainbow color calculation ──
				# Key concept: **HSV (Hue, Saturation, Value)**.
				# Normal RGB says "mix this much red + green + blue".
				# HSV instead says "pick a spot on the color wheel (hue),
				# choose how vivid (saturation), and how bright (value)".
				#
				# Hue goes from 0.0 to 1.0 around the wheel:
				#   0.0 = red, 0.17 = yellow, 0.33 = green,
				#   0.5 = cyan, 0.67 = blue, 0.83 = purple, 1.0 = red again
				#
				# Two different rainbow styles:
				#   Crosshair: distance from center — pixels at the same
				#     distance share a color, creating pulsing rings.
				#   Sword: diagonal wave — (row + col) offset, creating
				#     a ripple that flows diagonally across the blade.
				var hue: float
				if not is_sword_mode:
					var center_row: float = grid_height / 2.0
					var center_col: float = grid_width / 2.0
					var dist: float = sqrt((row - center_row) * (row - center_row) + (col - center_col) * (col - center_col))
					hue = fmod(_rainbow_time * 0.8 + dist * 0.15, 1.0)
				else:
					var hue_offset: float = (row + col) * 0.1
					hue = fmod(_rainbow_time * 0.8 + hue_offset, 1.0)
				if color_index == 1:
					# Main color: bright, vivid rainbow
					color = Color.from_hsv(hue, 0.9, 1.0)
				else:
					# Detail color: softer pastel rainbow (lower saturation)
					color = Color.from_hsv(hue, 0.5, 1.0)
			else:
				color = CURSOR_PALETTE[color_index]

			var rect := Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE,
				PIXEL_SIZE
			)
			draw_rect(rect, color)
