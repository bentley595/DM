extends Node2D
## A stationary training dummy that the player can practice attacking.
##
## This is the simplest kind of "enemy" — it doesn't move, doesn't fight
## back, and doesn't have health.  It just sits there and flashes white
## when you hit it.  But even this simple object teaches important concepts:
##
## Key concept: **Groups for tagging nodes**.
## By adding ourselves to the "targetable" group, other scripts can find us
## without needing a direct reference.  The cursor checks this group to know
## when to show the sword icon, and the player checks it to know what to hit.
## This is called "loose coupling" — the dummy doesn't know WHO will look
## for it, it just wears the "targetable" badge and waits.
##
## Key concept: **Hit flash effect**.
## When something gets hit in a game, it briefly turns all-white for a few
## frames.  This is a SUPER common technique in pixel-art games (think old
## Zelda or Pokemon).  It works because it's instant visual feedback — you
## KNOW you hit something because it lit up.  We do this by temporarily
## replacing all colors with white in _draw().

# ── Visual settings ────────────────────────────────────────────────
## Each grid pixel = 2 viewport pixels — same scale as the player character.
const PIXEL_SIZE: int = 2

## How long the white flash lasts in seconds.
## 0.15s is about 2 frames at 12 FPS — short but noticeable!
const FLASH_DURATION: float = 0.15

# ── Training dummy palette ─────────────────────────────────────────
## Earthy wooden colors — it should look like a practice post made of
## wood with a straw target on top.
const DUMMY_PALETTE: Array = [
	Color(0, 0, 0, 0),              # 0: transparent
	Color(0.25, 0.15, 0.08, 1.0),   # 1: dark brown outline
	Color(0.65, 0.45, 0.25, 1.0),   # 2: light wood body
	Color(0.85, 0.75, 0.5, 1.0),    # 3: tan straw head/target
]

## Pure white for the hit flash effect.
const FLASH_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)

# ── Dummy grid (10×14) ────────────────────────────────────────────
## Classic training dummy shape:
##   - Round straw "head" at the top (rows 0-4) — the target zone
##   - Wooden "body" post (rows 5-10) — wider in the middle
##   - Wide base/stand (rows 11-13) — keeps it upright
##
## At pixel_size=2, this is 20×28 screen pixels — slightly smaller
## than a player character (28×40) which feels right for a target.
const DUMMY_GRID: Array = [
	[0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 1, 3, 3, 3, 3, 1, 0, 0],
	[0, 0, 1, 3, 3, 3, 3, 1, 0, 0],
	[0, 0, 1, 3, 3, 3, 3, 1, 0, 0],
	[0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
	[0, 0, 0, 1, 2, 2, 1, 0, 0, 0],
	[0, 0, 1, 2, 2, 2, 2, 1, 0, 0],
	[0, 0, 1, 2, 2, 2, 2, 1, 0, 0],
	[0, 0, 0, 1, 2, 2, 1, 0, 0, 0],
	[0, 0, 0, 1, 2, 2, 1, 0, 0, 0],
	[0, 1, 1, 1, 2, 2, 1, 1, 1, 0],
	[0, 1, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
]

# ── Hit flash state ────────────────────────────────────────────────
## True while the dummy is showing the white flash.
var is_flashing: bool = false

## Counts down from FLASH_DURATION to 0.
var flash_timer: float = 0.0


func _ready() -> void:
	# Add ourselves to the "targetable" group.
	# This is like putting on a name badge that says "you can hit me!"
	# Now any script can call get_tree().get_nodes_in_group("targetable")
	# and we'll show up in the list.
	add_to_group("targetable")


func hit() -> void:
	## Called by player.gd when a swing connects with this dummy.
	##
	## Starts the white flash effect — all pixels temporarily turn white,
	## then fade back to normal colors.  This is the classic "damage flash"
	## seen in tons of retro games!
	is_flashing = true
	flash_timer = FLASH_DURATION
	queue_redraw()


func _process(delta: float) -> void:
	# Count down the flash timer.  When it reaches 0, go back to normal.
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			queue_redraw()


func _draw() -> void:
	var grid_height: int = DUMMY_GRID.size()
	var grid_width: int = DUMMY_GRID[0].size()

	# Center the drawing on this node's position — same pattern as always!
	var offset_x: float = -grid_width * PIXEL_SIZE / 2.0
	var offset_y: float = -grid_height * PIXEL_SIZE / 2.0

	for row in grid_height:
		for col in grid_width:
			var color_index: int = DUMMY_GRID[row][col]
			if color_index == 0:
				continue

			# Here's the flash trick!  If is_flashing is true, we ignore
			# the normal palette color and use pure white instead.
			# Every visible pixel becomes white — that's what makes it
			# look like it "lit up" from the hit.
			var color: Color
			if is_flashing:
				color = FLASH_COLOR
			else:
				color = DUMMY_PALETTE[color_index]

			var rect := Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE,
				PIXEL_SIZE
			)
			draw_rect(rect, color)
