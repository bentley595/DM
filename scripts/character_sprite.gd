extends Node2D
## Draws a pixel-art character from a grid of color indices, with 4-direction support.
##
## This works EXACTLY like star_field.gd — we override _draw() and use
## draw_rect() to paint colored squares.  The difference is that instead
## of random star positions, we read from a 2D array (the "pixel grid")
## where each number maps to a color in the palette.
##
## Think of it like coloring in graph paper:
##   0 = skip (transparent)
##   1 = outline (dark edge)
##   2 = primary color (armor, robe, etc.)
##   3 = highlight
##   4 = skin color
##   5 = skin shadow (eyes)
##   6 = secondary color (pants, legs)
##   7 = accent color (belt, trim, details)
##
## Key concept: **data-driven rendering**.
## The sprite doesn't "know" what a knight or mage looks like — it just
## reads numbers from an array and paints the matching color.  Change the
## array, and you get a completely different character!
##
## Key concept: **frame-based animation**.
## To make the character look like they're walking, we cycle through 4 grids:
##   Frame 0: idle (standing still)
##   Frame 1: left-step (left leg forward)
##   Frame 2: idle again
##   Frame 3: right-step (right leg forward — mirrored version of left-step)
## This is the classic SNES 4-frame walk cycle!  The trick is that we only
## need to DRAW the left-step by hand — the right-step is computed by
## flipping each row of the left-step grid (reversing the array).
##
## Key concept: **4-directional facing**.
## Classic SNES RPGs show different sprites based on which way the character
## walks — front-facing (down), back-facing (up), left profile, and right
## profile.  We store separate grids for down, up, and left.  Right is
## automatically computed by mirroring the left grids — so we only need to
## hand-draw 3 directions, and we get the 4th for free!
##
## When the player changes direction, set_facing() swaps which set of grids
## the animation system uses.  The animation frame and timer are preserved,
## so the walk cycle doesn't "hiccup" when you change direction mid-stride.

# ── Data that defines what to draw ────────────────────────────────────

## The 2D array of color indices currently being drawn.
## This gets swapped between frames during walk animation.
var pixel_grid: Array = []

## Maps index numbers to actual Colors.
var palette: Array = []

## How many screen pixels each "sprite pixel" takes up.
## At 2, a 14-wide grid becomes 28 pixels on screen — 16-bit sized!
var pixel_size: int = 2

# ── Direction tracking ─────────────────────────────────────────────────
#
# We store a complete set of grids for each direction.  When the player
# faces a new direction, we swap which grids the animation reads from.
# This is much cleaner than having one big if/elif chain every frame!

## Which way the character is currently facing.
## One of: "down", "up", "left", "right"
var facing: String = "down"

## Maps each direction → its idle (standing) grid.
## Example: dir_idle["up"] is the back-of-head grid.
var dir_idle: Dictionary = {}

## Maps each direction → its 4-frame walk cycle array.
## Example: dir_walk_cycle["left"] = [idle, left_step, idle, right_step]
## where all grids show the left-facing profile.
var dir_walk_cycle: Dictionary = {}

# ── Walk animation data ───────────────────────────────────────────────
#
# The walk cycle uses 4 frames at 6 fps (about 167ms per frame).
# A full cycle (idle → left → idle → right) takes ~667ms — just like
# classic SNES RPGs!

## How many walk frames play per second.  6 fps matches that chunky
## retro feel — fast enough to look like walking, slow enough to read.
const WALK_FPS: float = 6.0

## The standing-still grid for the CURRENT direction.
## Updated by set_facing() whenever direction changes.
var idle_grid: Array = []

## The 4-frame walk cycle for the CURRENT direction.
## Updated by set_facing() whenever direction changes.
var walk_cycle: Array = []

## True when the player is holding a movement key.
var is_walking: bool = false

## Counts up every frame (in seconds).  When it passes the frame
## duration (1/WALK_FPS), we advance to the next animation frame.
var anim_timer: float = 0.0

## Which of the 4 walk_cycle frames we're currently showing (0–3).
var anim_frame: int = 0


func set_character(character: Dictionary) -> void:
	## Call this to change which character is displayed.
	##
	## Accepts a character dictionary from CharacterData.characters().
	## The dictionary contains grids for all directions plus the palette.
	##
	## This function builds all 4 directional walk cycles at once, so
	## switching directions later (via set_facing) is instant — just a
	## dictionary lookup, no computation needed!
	palette = character.palette

	# ── Extract grids from the dictionary ──────────────────────────
	# "down" grids are the original front-facing ones (grid / step_grid)
	var grid_down: Array = character.grid
	var step_down: Array = character.get("step_grid", [])

	# "up" and "left" grids were added in the directional sprite update
	var grid_up: Array = character.get("grid_up", [])
	var step_up: Array = character.get("step_grid_up", [])
	var grid_left: Array = character.get("grid_left", [])
	var step_left: Array = character.get("step_grid_left", [])

	# ── Build idle grids for all 4 directions ──────────────────────
	# "right" is just the mirror of "left" — no hand-drawing needed!
	dir_idle = { "down": grid_down }
	if not grid_up.is_empty():
		dir_idle["up"] = grid_up
	if not grid_left.is_empty():
		dir_idle["left"] = grid_left
		dir_idle["right"] = _mirror_grid(grid_left)

	# ── Build walk cycles for all 4 directions ─────────────────────
	# Each direction gets its own 4-frame cycle:
	#   [idle, step_left_leg, idle, step_right_leg]
	#
	# The "step_right_leg" frame is the mirror of "step_left_leg".
	dir_walk_cycle = {}

	# DOWN walk cycle (front-facing)
	if not step_down.is_empty():
		var step_down_mirror: Array = _mirror_grid(step_down)
		dir_walk_cycle["down"] = [grid_down, step_down, grid_down, step_down_mirror]

	# UP walk cycle (back-facing)
	if not step_up.is_empty():
		var step_up_mirror: Array = _mirror_grid(step_up)
		dir_walk_cycle["up"] = [grid_up, step_up, grid_up, step_up_mirror]

	# LEFT walk cycle (left profile)
	# Same "double mirror" problem as the right cycle (explained below)!
	# Mirroring step_left flips the WHOLE grid — head included — so the
	# head would face right on frame 3.  We fix it by compositing the
	# left-facing head with the mirrored (opposite-leg-shift) legs.
	if not step_left.is_empty():
		var step_left_mirror: Array = _mirror_grid(step_left)
		var left_step_other: Array = _build_composite(grid_left, step_left_mirror, 12)
		dir_walk_cycle["left"] = [grid_left, step_left, grid_left, left_step_other]

	# RIGHT walk cycle (mirrored left profile)
	# This is the trickiest one!  Here's why:
	#
	# The right-facing idle grid = mirror of left-facing idle grid.  Easy!
	# The right-facing step grid SHOULD be = mirror of left-facing step grid.
	# And the right-facing "other step" (frame 3) = mirror of left-step's mirror.
	#
	# BUT: mirroring a mirror gives back the ORIGINAL — which is left-facing!
	# That would mean frame 3 shows a LEFT-facing head with right-shifted legs.
	#
	# The fix: we use _build_composite() to take the RIGHT-facing head (rows 0-11)
	# and pair it with the ORIGINAL (un-mirrored) step legs (rows 12-19).
	# This gives us a properly right-facing character with the correct leg shift!
	if not step_left.is_empty():
		var right_idle: Array = _mirror_grid(grid_left)
		var right_step: Array = _mirror_grid(step_left)
		# Frame 3: right head + original left-step legs (because mirroring
		# the already-mirrored right_step would give back left-facing head!)
		var right_step_other: Array = _build_composite(right_idle, step_left, 12)
		dir_walk_cycle["right"] = [right_idle, right_step, right_idle, right_step_other]

	# ── Initialize to face down ────────────────────────────────────
	facing = "down"
	idle_grid = dir_idle.get("down", grid_down)
	walk_cycle = dir_walk_cycle.get("down", [])
	pixel_grid = idle_grid

	# Reset animation state whenever the character changes
	is_walking = false
	anim_timer = 0.0
	anim_frame = 0

	# queue_redraw() is how you tell Godot "hey, my visuals changed,
	# please call _draw() again next frame."  Without this, the old
	# image would stay on screen even though the data changed!
	queue_redraw()


func set_facing(dir: String) -> void:
	## Changes which direction the character faces (up/down/left/right).
	##
	## This swaps the idle_grid and walk_cycle to the ones for that
	## direction.  The animation frame and timer are PRESERVED — so if
	## the character is mid-stride when they turn, the animation
	## continues smoothly from the same point in the cycle.
	##
	## If we don't have grids for the requested direction (e.g. missing
	## data), we silently keep the current direction.  This makes the
	## system robust — it degrades gracefully instead of crashing.
	if dir == facing:
		return  # Already facing that way — nothing to do

	# Check that we have data for this direction
	if not dir_idle.has(dir):
		return  # No grid data for this direction — stay as we are

	facing = dir
	idle_grid = dir_idle[dir]
	walk_cycle = dir_walk_cycle.get(dir, [])

	# Update what's currently being drawn.
	# If we're walking and have animation data, show the current frame
	# from the NEW direction's walk cycle.  Otherwise, show idle.
	if is_walking and not walk_cycle.is_empty():
		pixel_grid = walk_cycle[anim_frame]
	else:
		pixel_grid = idle_grid

	queue_redraw()


func set_walking(walking: bool) -> void:
	## Toggle walk animation on/off.  Called by the player script
	## every frame based on whether movement keys are held.
	##
	## When walking STOPS, we immediately snap back to the idle frame.
	## This prevents the character from "freezing" mid-stride, which
	## would look weird — imagine stopping with one leg in the air!
	if walking == is_walking:
		return  # No change — skip to avoid unnecessary work

	is_walking = walking

	if not walking:
		# Stopped moving — snap to idle immediately
		anim_timer = 0.0
		anim_frame = 0
		pixel_grid = idle_grid
		queue_redraw()


func _process(delta: float) -> void:
	# Only animate if we're walking AND have animation data.
	# walk_cycle is empty on menu screens (no step grid provided),
	# so this check keeps menus perfectly static.
	if not is_walking or walk_cycle.is_empty():
		return

	# Add the time since last frame to our timer.
	# delta is in seconds (e.g. 0.016 for 60fps).
	anim_timer += delta

	# Check if enough time has passed to advance to the next frame.
	# At 6 fps, each frame lasts 1/6 = 0.1667 seconds.
	var frame_duration: float = 1.0 / WALK_FPS
	if anim_timer >= frame_duration:
		# Subtract (don't reset to 0!) to prevent "drift".
		# If the frame took a tiny bit longer than expected, the leftover
		# time carries over to the next frame, keeping the rhythm steady.
		anim_timer -= frame_duration

		# Advance to next frame, wrapping around with modulo (%).
		# 0 → 1 → 2 → 3 → 0 → 1 → ...  (the cycle repeats forever!)
		anim_frame = (anim_frame + 1) % 4

		# Swap in the grid for this frame and tell Godot to redraw.
		# We ONLY call queue_redraw() when the frame actually changes —
		# this is efficient because _draw() only runs when needed!
		pixel_grid = walk_cycle[anim_frame]
		queue_redraw()


static func _mirror_grid(grid: Array) -> Array:
	## Creates a horizontally-flipped copy of a pixel grid.
	## Each row is reversed: [1,2,3,0,0] becomes [0,0,3,2,1].
	##
	## This is how we get the "right step" from the "left step" —
	## if the left leg is shifted left in the original, the mirrored
	## version has the RIGHT leg shifted right instead!
	##
	## It's also how we get right-facing sprites from left-facing ones —
	## the entire character flips horizontally, so the eye that was on
	## the left side now appears on the right side.
	##
	## "static func" means this function doesn't need an instance of the
	## class to work — it's a pure utility that takes input and returns
	## output, like a math function.
	var mirrored: Array = []
	for row in grid:
		var flipped_row: Array = row.duplicate()
		flipped_row.reverse()
		mirrored.append(flipped_row)
	return mirrored


static func _build_composite(head_source: Array, leg_source: Array, split: int = 12) -> Array:
	## Builds a grid by combining the HEAD rows from one grid with the
	## LEG rows from another grid.
	##
	## Why do we need this?  For the RIGHT-facing walk cycle!
	## The right-facing grids are computed by mirroring the left-facing
	## ones.  But the walk cycle's "other step" frame (frame 3) needs:
	##   - Head rows (0-11): right-facing (mirrored left)
	##   - Leg rows (12-19): from the original left-step grid (NOT mirrored
	##     back, because double-mirroring would give us left-facing head!)
	##
	## The "split" parameter says where the head ends and legs begin.
	## For our 20-row sprites, row 12 is where legs start.
	##
	## Think of it like cutting two photos in half and taping the top
	## of one to the bottom of the other!
	var result: Array = []
	for i in head_source.size():
		if i < split:
			result.append(head_source[i])
		else:
			result.append(leg_source[i])
	return result


func _draw() -> void:
	# If no grid data has been set yet, don't try to draw anything.
	# This happens briefly when the scene first loads, before _ready()
	# on the parent script has a chance to call set_character().
	if pixel_grid.is_empty():
		return

	# Figure out the grid dimensions so we can center the drawing.
	var grid_height: int = pixel_grid.size()
	var grid_width: int = pixel_grid[0].size()

	# Calculate offsets to CENTER the sprite on this node's position.
	# Without this, the sprite would draw from the top-left corner,
	# making it hard to position in the scene.
	var offset_x: float = -grid_width * pixel_size / 2.0
	var offset_y: float = -grid_height * pixel_size / 2.0

	# Loop through every cell in the grid, row by row, column by column.
	for row in grid_height:
		for col in grid_width:
			var color_index: int = pixel_grid[row][col]

			# Index 0 means "transparent" — skip it, don't draw anything.
			if color_index == 0:
				continue

			# Look up the actual Color from the palette using the index.
			var color: Color = palette[color_index]

			# Build a Rect2 (rectangle) for this one pixel.
			var rect := Rect2(
				offset_x + col * pixel_size,
				offset_y + row * pixel_size,
				pixel_size,
				pixel_size
			)

			# Paint it!
			draw_rect(rect, color)
