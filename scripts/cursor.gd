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
##   - Crosshair: normal aiming mode (a "+" shape)
##   - Sword: hovering over something you can attack

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

# ── Crosshair grid (7×7) ──────────────────────────────────────────
## A "+" shape with a 1-pixel gap in the center so you can see exactly
## where you're aiming.  The gap is important — without it, the center
## pixel would block your view of tiny targets!
const CROSSHAIR_GRID: Array = [
	[0, 0, 0, 1, 0, 0, 0],
	[0, 0, 0, 2, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[1, 2, 0, 0, 0, 2, 1],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 2, 0, 0, 0],
	[0, 0, 0, 1, 0, 0, 0],
]

# ── Sword grid (5×7) ──────────────────────────────────────────────
## A small sword icon — pointed blade at top, crossguard in middle,
## handle at bottom.  Shows up when hovering over something hittable.
## This gives the player a visual hint: "you can attack this!"
const SWORD_GRID: Array = [
	[0, 0, 1, 0, 0],
	[0, 0, 2, 0, 0],
	[0, 1, 2, 1, 0],
	[0, 0, 2, 0, 0],
	[0, 1, 2, 1, 0],
	[1, 2, 1, 2, 1],
	[0, 0, 2, 0, 0],
]

# ── State ──────────────────────────────────────────────────────────
## Which grid we're currently drawing — crosshair or sword.
var current_grid: Array = CROSSHAIR_GRID

## Track the current mode so we only call queue_redraw() when it CHANGES.
## Calling queue_redraw() every frame would work but waste tiny amounts
## of effort.  This is a micro-optimization but also a good habit!
var is_sword_mode: bool = false


func _ready() -> void:
	# Hide the operating system cursor.  From now on, only our pixel-art
	# cursor will be visible.  This is what makes it feel like a "real"
	# game cursor instead of having both the OS arrow AND our crosshair.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Set z_index very high so the cursor always draws on top of everything.
	# z_index is Godot's way of controlling draw order — higher = drawn later = on top.
	z_index = 100


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


func _process(_delta: float) -> void:
	# Move the cursor to wherever the mouse is.
	# get_global_mouse_position() returns game-world coordinates (320×180),
	# not screen coordinates (1280×720).  Godot handles the 4× scaling
	# automatically thanks to stretch mode "viewport".
	position = get_global_mouse_position()

	# Check if we're hovering over anything in the "targetable" group.
	var hovering: bool = _is_hovering_target()

	# Only switch grids and redraw when the mode actually changes.
	# This avoids doing unnecessary work every single frame.
	if hovering and not is_sword_mode:
		is_sword_mode = true
		current_grid = SWORD_GRID
		queue_redraw()
	elif not hovering and is_sword_mode:
		is_sword_mode = false
		current_grid = CROSSHAIR_GRID
		queue_redraw()


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

	for row in grid_height:
		for col in grid_width:
			var color_index: int = current_grid[row][col]
			if color_index == 0:
				continue
			var color: Color = CURSOR_PALETTE[color_index]
			var rect := Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE,
				PIXEL_SIZE
			)
			draw_rect(rect, color)
