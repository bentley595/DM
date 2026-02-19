extends Node2D
## A projectile that flies in a straight line and hits "targetable" things.
##
## Key concept: **spawning nodes at runtime**.
## Unlike the player or training dummy (which are placed in the scene editor),
## projectiles are CREATED while the game is running — every time you shoot,
## the player script builds a new Projectile node, sets it up, and adds it
## to the scene tree.  When the projectile hits something or leaves the screen,
## it removes itself with queue_free().  This "create → fly → destroy" pattern
## is used in almost every game with bullets, arrows, spells, etc.
##
## Key concept: **setup() pattern for runtime nodes**.
## Since we create this node from code (not the editor), we can't use @export
## to configure it.  Instead, the player calls setup() right after creating
## the node to pass in the direction, shape, and colors.  This is a very
## common pattern: create the node, call a setup function, then add it to
## the tree.

# ── Projectile shapes ────────────────────────────────────────────────
# Each template has a unique 5×5 pixel-art grid.
# Grid values:  0 = transparent,  1 = outline,  2 = fill,  3 = bright center
# These get mapped to actual colors from the character's palette in setup().

## ARMORED — Iron Bolt (2 frames): pulsing glow.
## The bright center (3) expands and contracts like energy pulsing through the bolt.
const FRAMES_ARMORED: Array = [
	[  # Frame 0 — normal
		[0, 1, 1, 1, 0],
		[1, 2, 2, 2, 1],
		[1, 2, 3, 2, 1],
		[1, 2, 2, 2, 1],
		[0, 1, 1, 1, 0],
	],
	[  # Frame 1 — brighter (3s expand outward)
		[0, 1, 1, 1, 0],
		[1, 2, 3, 2, 1],
		[1, 3, 3, 3, 1],
		[1, 2, 3, 2, 1],
		[0, 1, 1, 1, 0],
	],
]

## ROBED — Magic Orb (2 frames): sparkle shift.
## Corner sparkles alternate positions — crackling magical energy.
const FRAMES_ROBED: Array = [
	[  # Frame 0 — sparkles at corners
		[3, 0, 2, 0, 3],
		[0, 2, 3, 2, 0],
		[2, 3, 3, 3, 2],
		[0, 2, 3, 2, 0],
		[3, 0, 2, 0, 3],
	],
	[  # Frame 1 — sparkles shifted to edges
		[0, 3, 0, 3, 0],
		[3, 2, 3, 2, 3],
		[0, 3, 3, 3, 0],
		[3, 2, 3, 2, 3],
		[0, 3, 0, 3, 0],
	],
]

## LIGHT — Throwing Knife (4 frames): spinning rotation.
## The knife rotates 90° each frame — tumbling through the air like a real thrown knife.
const FRAMES_LIGHT: Array = [
	[  # Frame 0 — pointing up
		[0, 0, 3, 0, 0],
		[0, 1, 3, 1, 0],
		[0, 1, 2, 1, 0],
		[0, 1, 2, 1, 0],
		[0, 0, 1, 0, 0],
	],
	[  # Frame 1 — pointing right (rotated 90° clockwise)
		[0, 0, 0, 0, 0],
		[0, 1, 1, 1, 0],
		[1, 2, 2, 3, 3],
		[0, 1, 1, 1, 0],
		[0, 0, 0, 0, 0],
	],
	[  # Frame 2 — pointing down (rotated 180°)
		[0, 0, 1, 0, 0],
		[0, 1, 2, 1, 0],
		[0, 1, 2, 1, 0],
		[0, 1, 3, 1, 0],
		[0, 0, 3, 0, 0],
	],
	[  # Frame 3 — pointing left (rotated 270°)
		[0, 0, 0, 0, 0],
		[0, 1, 1, 1, 0],
		[3, 3, 2, 2, 1],
		[0, 1, 1, 1, 0],
		[0, 0, 0, 0, 0],
	],
]

## CLOTHED — Fireball (2 frames): flame flicker.
## Flame wisps alternate positions — like real fire dancing.
const FRAMES_CLOTHED: Array = [
	[  # Frame 0 — wisps at top-left, bottom-right
		[0, 2, 0, 2, 0],
		[2, 3, 3, 3, 2],
		[0, 3, 3, 3, 0],
		[2, 3, 3, 3, 2],
		[0, 2, 0, 2, 0],
	],
	[  # Frame 1 — wisps shifted (inverted pattern)
		[2, 0, 2, 0, 2],
		[0, 3, 3, 3, 0],
		[2, 3, 3, 3, 2],
		[0, 3, 3, 3, 0],
		[2, 0, 2, 0, 2],
	],
]

# ── Constants ─────────────────────────────────────────────────────────

## Each grid cell draws as 2×2 viewport pixels (same scale as character sprites).
const PIXEL_SIZE: int = 2

## Animation speed in frames per second.
## 8 FPS is a nice sweet spot — fast enough to feel animated, slow enough
## that you can still see each frame.  (The character walk cycle uses 12 FPS,
## but projectiles are smaller so a bit slower looks better.)
const ANIM_FPS: float = 8.0

## How fast the projectile moves in pixels per second.
const SPEED: float = 150.0

## How close the projectile needs to be to a target to count as a hit.
## At 5×5 grid × pixel_size 2 = 10×10 viewport pixels, 8px is about
## the distance from center to edge — a fair collision radius.
const HIT_DISTANCE: float = 8.0

## Viewport boundaries — same as the game's logical resolution.
## If the projectile goes outside these, it's off-screen and we destroy it.
const VIEW_LEFT: float = 0.0
const VIEW_RIGHT: float = 320.0
const VIEW_TOP: float = 0.0
const VIEW_BOTTOM: float = 180.0

# ── State ─────────────────────────────────────────────────────────────

## The direction this projectile is flying (normalized Vector2).
var direction: Vector2 = Vector2.ZERO

## All animation frames for this projectile (array of 5×5 grids).
## Could be 2 frames (bolt, orb, fireball) or 4 frames (knife spin).
var frames: Array = []

## Which frame is currently being drawn (0, 1, 2, or 3).
var anim_frame: int = 0

## Timer that accumulates delta each frame.  When it passes the threshold
## (1.0 / ANIM_FPS), we advance to the next frame and reset.
## This is the same technique used in character_sprite.gd for walk cycles!
var anim_timer: float = 0.0

## The 3 colors used for drawing (indices 1, 2, 3 in the grid).
## Index 0 is always transparent.
var colors: Array = []


func setup(dir: Vector2, template: String, palette_colors: Array) -> void:
	## Called by the player right after creating the projectile.
	##
	## Parameters:
	##   dir — normalized direction vector (any angle, not just cardinal)
	##   template — "armored", "robed", "light", or "clothed"
	##   palette_colors — array of 3 Colors: [outline, accent, highlight]
	##                     These map to grid values 1, 2, 3.
	direction = dir
	colors = palette_colors

	# Pick the right animation frames based on the character's body template.
	# "match" is like a switch statement — it compares the value against
	# each option and runs the matching block.
	# Now we store an ARRAY of frames instead of a single shape!
	match template:
		"armored": frames = FRAMES_ARMORED
		"robed": frames = FRAMES_ROBED
		"light": frames = FRAMES_LIGHT
		"clothed": frames = FRAMES_CLOTHED
		_: frames = FRAMES_ARMORED  # Fallback, should never happen


func _process(delta: float) -> void:
	# ── Move forward ──────────────────────────────────────────────
	# position += direction * speed * delta
	# Same formula as player movement!  direction says WHERE,
	# SPEED says HOW FAST, and delta keeps it smooth.
	position += direction * SPEED * delta

	# ── Check viewport bounds ────────────────────────────────────
	# If we've gone off-screen, destroy this node.  Without this,
	# missed shots would fly forever and waste memory!
	if position.x < VIEW_LEFT or position.x > VIEW_RIGHT \
	or position.y < VIEW_TOP or position.y > VIEW_BOTTOM:
		queue_free()
		return

	# ── Check for hits ───────────────────────────────────────────
	# Same pattern as the swing's _check_swing_hits() — loop through
	# all nodes in the "targetable" group and check distance.
	# Projectiles use a smaller hit radius (8px vs 34px for melee)
	# because they're smaller and more precise.
	var targets: Array = get_tree().get_nodes_in_group("targetable")
	for target in targets:
		var dist: float = (target.global_position - global_position).length()
		if dist <= HIT_DISTANCE:
			target.hit()
			queue_free()
			return

	# ── Advance animation ────────────────────────────────────────
	# This is the same timer technique used in character_sprite.gd!
	# We accumulate time each frame.  When we've waited long enough
	# (1/8th of a second at 8 FPS), we advance to the next frame.
	#
	# The modulo (%) operator wraps around: if we have 2 frames,
	# it goes 0 → 1 → 0 → 1 → ...  With 4 frames (the knife),
	# it goes 0 → 1 → 2 → 3 → 0 → 1 → ...
	if frames.size() > 1:
		anim_timer += delta
		if anim_timer >= 1.0 / ANIM_FPS:
			anim_timer -= 1.0 / ANIM_FPS
			anim_frame = (anim_frame + 1) % frames.size()
			queue_redraw()  # Tell Godot to call _draw() again with the new frame


func _draw() -> void:
	# ── Draw the current animation frame ─────────────────────────
	# Same technique as character_sprite.gd!  Loop through a 2D array,
	# skip zeros (transparent), and draw colored rectangles for each
	# non-zero cell.
	#
	# The key difference from before: instead of drawing `shape` (one grid),
	# we draw `frames[anim_frame]` — whichever frame the animation timer
	# has advanced to.  This is what makes the projectiles animate!
	#
	# We offset by -5, -5 so the shape is CENTERED on the node's
	# position.  Without this, the top-left corner of the shape would
	# be at the position, making hit detection feel off.
	# (5×5 grid × pixel_size 2 = 10×10 pixels, so half is 5.)
	if frames.is_empty() or colors.is_empty():
		return

	var current_frame: Array = frames[anim_frame]
	var offset_x: float = -5.0  # Half of 5 * PIXEL_SIZE (= 10 / 2)
	var offset_y: float = -5.0

	for row in 5:
		for col in 5:
			var cell: int = current_frame[row][col]
			if cell == 0:
				continue  # Transparent — skip!

			# cell is 1, 2, or 3 → colors[0], colors[1], colors[2]
			var color: Color = colors[cell - 1]
			draw_rect(
				Rect2(
					offset_x + col * PIXEL_SIZE,
					offset_y + row * PIXEL_SIZE,
					PIXEL_SIZE,
					PIXEL_SIZE
				),
				color
			)
