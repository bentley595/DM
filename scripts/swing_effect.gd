extends Node2D
## Draws a sword-swing arc effect using _draw() — the same pixel-art rendering
## pattern used by character_sprite.gd and all HUD elements.
##
## The crescent arc is PROCEDURALLY GENERATED using circle math instead of
## hand-drawn pixel arrays.  This gives us perfectly smooth curves at any
## resolution with way less code!
##
## How it works:
##   1. _generate_down_frames() creates 5 "down" frames using two circles
##      (outer radius and inner radius) — pixels BETWEEN the two form the
##      crescent band.  A "sweep angle" controls how much of the arc is
##      visible in each frame.
##   2. The other 3 directions are computed from "down" using transforms:
##        "up"    = rotate 180° (flip vertical + mirror horizontal)
##        "right" = rotate 90° counter-clockwise
##        "left"  = rotate 90° clockwise
##
## Key concept: **procedural generation vs hardcoded data**.
## The old version used 5 hand-drawn 22×14 arrays (~1540 numbers!).
## This version uses math to generate 5 smooth 60×34 frames from just a few
## constants (center, radii, sweep angles).  The crescent is MUCH smoother
## because we have ~6x the pixels to define the curve.
##
## This node starts invisible.  When start_swing() is called, it becomes
## visible, plays the 5 frames, then hides itself again.  Godot skips
## _draw() entirely when a node is invisible, so there's zero cost when
## not swinging!

# ── Swing animation settings ────────────────────────────────────────

## Frames per second for the swing animation.
## 5 frames at 18 FPS = ~0.28 seconds — quick and snappy!
const SWING_FPS: float = 18.0

## How many screen pixels each grid cell takes up.
## 1 = each cell is 1 viewport pixel (4 screen pixels at our 4x scale).
## Was 2 before — dropping to 1 doubles our effective resolution!
const PIXEL_SIZE: int = 1

## Total number of animation frames in the swing.
const FRAME_COUNT: int = 5

# ── Crescent arc geometry ───────────────────────────────────────────
## These constants define the shape of the crescent.  Tweak them to
## change the size, thickness, or curvature of the slash arc.
##
## Picture it like this: imagine two circles drawn from the same center
## point (like a bullseye).  The CRESCENT is the donut-shaped ring
## between them.  Then we only keep the BOTTOM HALF of that donut —
## that's our downward-facing slash arc!

const GRID_W: int = 60           # Grid width in cells
const GRID_H: int = 34           # Grid height in cells
const ARC_CX: float = 30.0       # Arc center X (horizontally centered)
const ARC_CY: float = 3.0        # Arc center Y (near the top — arc curves DOWN)
const OUTER_R: float = 27.0      # Outer edge of crescent band
const INNER_R: float = 19.0      # Inner edge (creates the hollow center)
const BRIGHT_WIDTH: float = 0.45  # Radians — how wide the bright leading edge is

# ── Swing palette ────────────────────────────────────────────────────
## 5 colors give us a smooth 3-step gradient: bright → medium → faint.
## The extra "medium trail" color (vs the old 4-color palette) creates
## a much smoother fade-out behind the leading edge.
##
##   0 = transparent (not drawn)
##   1 = dark steel outline (defines the shape border)
##   2 = bright blade (the leading edge — near-white steel)
##   3 = medium trail (70% opacity — the middle zone)
##   4 = faint trail (30% opacity — the oldest part of the sweep)

const SWING_PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(0.35, 0.35, 0.5, 0.5),    # 1: soft outline — semi-transparent so edges feel blurred
	Color(0.92, 0.95, 1.0, 1.0),    # 2: bright blade — near-white, really pops!
	Color(0.7, 0.75, 0.9, 0.7),     # 3: medium trail — 70% opacity
	Color(0.6, 0.65, 0.8, 0.3),     # 4: faint trail — 30% opacity
]

## How much to multiply a color's alpha by for the glow fringe.
## 0.25 = the glow is 25% as visible as the original pixel.
## Lower = more subtle, higher = more visible blur.
const GLOW_ALPHA_MULT: float = 0.25

# ── Precomputed direction frames ─────────────────────────────────────
# Computed once in _ready() from the generated "down" frames.
# After that, switching directions is instant — just a dictionary lookup!

## Maps direction string → array of 5 grids.
## Example: dir_frames["up"] = [frame0, frame1, frame2, frame3, frame4]
var dir_frames: Dictionary = {}

## Maps direction string → Vector2 offset from player center.
## This positions the arc just past the character's body edge.
var dir_offsets: Dictionary = {
	"down": Vector2(0, 20),
	"up": Vector2(0, -20),
	"right": Vector2(20, 0),
	"left": Vector2(-20, 0),
}

# ── Animation state ──────────────────────────────────────────────────

## The grid currently being drawn by _draw().
var current_grid: Array = []

## True while the swing animation is playing.
var is_active: bool = false

## Counts up each frame; when it exceeds 1/SWING_FPS, we advance.
var anim_timer: float = 0.0

## Which of the 5 frames we're showing (0–4).
var anim_frame: int = 0

## The 5-frame array for the current swing direction.
var active_frames: Array = []


func _ready() -> void:
	# Start invisible — we only show during a swing.
	visible = false

	# Generate the "down" frames using circle math, then compute
	# the other 3 directions from those.  This all runs once when
	# the scene loads, so the math is already done before the
	# player ever clicks!
	var down_frames: Array = _generate_down_frames()
	dir_frames["down"] = down_frames

	# "up" = rotate 180° (flip vertical + mirror horizontal).
	var up_frames: Array = []
	for frame in down_frames:
		up_frames.append(_mirror_grid(_flip_vertical(frame)))
	dir_frames["up"] = up_frames

	# "right" = rotate each frame 90° counter-clockwise.
	var right_frames: Array = []
	for frame in down_frames:
		right_frames.append(_rotate_90_ccw(frame))
	dir_frames["right"] = right_frames

	# "left" = rotate each frame 90° clockwise.
	var left_frames: Array = []
	for frame in down_frames:
		left_frames.append(_rotate_90_cw(frame))
	dir_frames["left"] = left_frames


func _generate_down_frames() -> Array:
	## Builds 5 animation frames for the "down" swing using circle math.
	##
	## The crescent is the area BETWEEN two circles (inner and outer radius),
	## limited to the bottom semicircle (angles 0 to PI).  A "sweep" angle
	## controls how much of the arc is revealed in each frame — like drawing
	## an arc with a compass, one section at a time.
	##
	## For each pixel we ask 3 questions:
	##   1. Is it between the two circles? (the "donut band")
	##   2. Is it in the bottom half? (below the arc center)
	##   3. Has the sweep reached it yet? (animation progress)
	##
	## Color assignment:
	##   - Edge pixels (touching transparent) → outline (1)
	##   - Near the sweep front → bright blade (2)
	##   - Middle zone behind → medium trail (3)
	##   - Far behind → faint trail (4)
	##   - Frame 4 (fade): everything → faint trail, no outline
	var frames: Array = []

	# How far the sweep has reached in each frame (in radians).
	# 0 radians = right side, PI radians = left side.
	# The blade starts on the right and sweeps to the left!
	var sweep_ends: Array = [
		PI * 0.12,   # Frame 0: tiny sliver at the right tip
		PI * 0.38,   # Frame 1: right arm + start of bottom curve
		PI * 0.68,   # Frame 2: bottom curve + left arm appearing
		PI,          # Frame 3: full crescent revealed
		PI,          # Frame 4: full crescent fading out
	]

	for f in FRAME_COUNT:
		var sweep_end: float = sweep_ends[f]
		var is_fade: bool = (f == FRAME_COUNT - 1)

		# ── Pass 1: Build a boolean mask ──────────────────────────
		# For each pixel, decide: is it inside the crescent for this frame?
		# We also store each pixel's angle so we can do the gradient later.
		var mask: Array = []
		var pixel_angles: Array = []

		for row in GRID_H:
			var mask_row: Array = []
			var angle_row: Array = []
			for col in GRID_W:
				# How far is this pixel from the arc center?
				var dx: float = float(col) - ARC_CX
				var dy: float = float(row) - ARC_CY
				var dist: float = sqrt(dx * dx + dy * dy)

				# What angle is it at? atan2 gives us the angle in radians.
				# 0 = right, PI/2 = straight down, PI = left
				var angle: float = atan2(dy, dx)
				angle_row.append(angle)

				# Three conditions to be "in the crescent":
				var in_band: bool = dist >= INNER_R and dist <= OUTER_R
				var in_arc: bool = angle >= 0.0    # Bottom half only
				var is_swept: bool = angle <= sweep_end  # Sweep reached here

				mask_row.append(in_band and in_arc and is_swept)
			mask.append(mask_row)
			pixel_angles.append(angle_row)

		# ── Pass 2: Assign colors ────────────────────────────────
		# Now we know which pixels are "in the crescent".  Time to
		# decide what color each one should be!
		var grid: Array = []

		for row in GRID_H:
			var grid_row: Array = []
			for col in GRID_W:
				# Not in the crescent? → transparent
				if not mask[row][col]:
					grid_row.append(0)
					continue

				# Fade frame: entire crescent becomes faint trail
				if is_fade:
					grid_row.append(4)
					continue

				# Edge detection: if ANY cardinal neighbor is outside the
				# crescent, this pixel is on the border → draw as outline.
				# We check the boundary first (row==0, etc.) to avoid
				# reading outside the array — GDScript's "or" short-circuits!
				var is_edge: bool = (
					row == 0 or not mask[row - 1][col]
					or row == GRID_H - 1 or not mask[row + 1][col]
					or col == 0 or not mask[row][col - 1]
					or col == GRID_W - 1 or not mask[row][col + 1]
				)

				if is_edge:
					grid_row.append(1)  # Outline
				else:
					# Gradient: how far behind the leading edge?
					var dist_from_front: float = sweep_end - pixel_angles[row][col]
					if dist_from_front <= BRIGHT_WIDTH:
						grid_row.append(2)  # Bright leading edge
					elif dist_from_front <= BRIGHT_WIDTH * 2.5:
						grid_row.append(3)  # Medium trail
					else:
						grid_row.append(4)  # Faint trail
			grid.append(grid_row)

		frames.append(grid)

	return frames


func start_swing(direction: String) -> void:
	## Called by player.gd to trigger the swing arc.
	## Sets up the correct frames for the given direction, positions
	## the node offset from the player, and makes it visible.
	active_frames = dir_frames.get(direction, dir_frames["down"])
	position = dir_offsets.get(direction, Vector2.ZERO)

	# Reset animation to the first frame
	anim_frame = 0
	anim_timer = 0.0
	is_active = true
	current_grid = active_frames[0]

	# Show the node and request a redraw
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	# Don't do anything when we're not swinging.
	# Since visible is also false, Godot skips _draw() too — zero cost!
	if not is_active:
		return

	anim_timer += delta
	var frame_duration: float = 1.0 / SWING_FPS

	if anim_timer >= frame_duration:
		# Subtract instead of resetting to prevent timing drift
		anim_timer -= frame_duration
		anim_frame += 1

		if anim_frame >= FRAME_COUNT:
			# All 5 frames have played — animation is done!
			is_active = false
			visible = false
			return

		# Show the next frame
		current_grid = active_frames[anim_frame]
		queue_redraw()


func _draw() -> void:
	# Safety check — don't draw if we have no grid data yet.
	if current_grid.is_empty():
		return

	var grid_height: int = current_grid.size()
	var grid_width: int = current_grid[0].size()

	# Center the drawing on this node's position.
	var offset_x: float = -grid_width * PIXEL_SIZE / 2.0
	var offset_y: float = -grid_height * PIXEL_SIZE / 2.0

	# ── Pass 1: Glow fringe ──────────────────────────────────────
	# For every non-transparent pixel, we draw a LARGER rectangle
	# behind it with very low opacity.  This 3×3 rect extends 1 pixel
	# past the original on every side.
	#
	# Why does this create blur?  Think about it:
	#   - Interior pixels (surrounded by other filled pixels) — their
	#     glow is HIDDEN underneath the neighbors' crisp pixels in pass 2.
	#   - Edge pixels (next to transparent space) — their glow BLEEDS
	#     out into the empty area, creating a soft gradient!
	#
	# So we get blur exactly where we want it (the edges) without
	# any extra edge-detection logic.  Pretty neat trick!
	for row in grid_height:
		for col in grid_width:
			var color_index: int = current_grid[row][col]
			if color_index == 0:
				continue

			var base: Color = SWING_PALETTE[color_index]
			var glow_color := Color(base.r, base.g, base.b, base.a * GLOW_ALPHA_MULT)

			# Draw a 3×3 rect centered on this pixel (extends 1px in each direction)
			draw_rect(
				Rect2(
					offset_x + col * PIXEL_SIZE - PIXEL_SIZE,
					offset_y + row * PIXEL_SIZE - PIXEL_SIZE,
					PIXEL_SIZE * 3,
					PIXEL_SIZE * 3
				),
				glow_color
			)

	# ── Pass 2: Crisp pixels ─────────────────────────────────────
	# Draw the actual sharp pixels ON TOP of the glow layer.
	# This keeps the center of the arc looking clean while the
	# edges have a soft halo around them.
	for row in grid_height:
		for col in grid_width:
			var color_index: int = current_grid[row][col]
			if color_index == 0:
				continue

			var color: Color = SWING_PALETTE[color_index]
			draw_rect(
				Rect2(
					offset_x + col * PIXEL_SIZE,
					offset_y + row * PIXEL_SIZE,
					PIXEL_SIZE,
					PIXEL_SIZE
				),
				color
			)


# ── Grid transformation helpers ──────────────────────────────────────
# These are "static" functions — they don't need access to any instance
# variables.  They're pure math: input grid → output grid.

static func _flip_vertical(grid: Array) -> Array:
	## Flips a grid upside-down — the top row becomes the bottom row.
	var flipped: Array = grid.duplicate()
	flipped.reverse()
	return flipped


static func _rotate_90_cw(grid: Array) -> Array:
	## Rotates a grid 90° clockwise.
	## Each NEW row is a COLUMN from the original, read bottom-to-top.
	var h: int = grid.size()
	var w: int = grid[0].size()
	var rotated: Array = []
	for c in w:
		var new_row: Array = []
		for r in range(h - 1, -1, -1):
			new_row.append(grid[r][c])
		rotated.append(new_row)
	return rotated


static func _rotate_90_ccw(grid: Array) -> Array:
	## Rotates a grid 90° counter-clockwise.
	## Each NEW row is a COLUMN from the original, read top-to-bottom,
	## starting from the RIGHTMOST column.
	var h: int = grid.size()
	var w: int = grid[0].size()
	var rotated: Array = []
	for c in range(w - 1, -1, -1):
		var new_row: Array = []
		for r in h:
			new_row.append(grid[r][c])
		rotated.append(new_row)
	return rotated


static func _mirror_grid(grid: Array) -> Array:
	## Mirrors a grid horizontally — each row is reversed.
	var mirrored: Array = []
	for row in grid:
		var flipped_row: Array = row.duplicate()
		flipped_row.reverse()
		mirrored.append(flipped_row)
	return mirrored
