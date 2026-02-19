extends Node2D
## Arrow-shaped cooldown indicator for the roll ability.
##
## When the roll is ready (fill_percent = 1.0), the whole arrow is bright
## yellow.  When on cooldown (fill_percent closer to 0.0), most of the arrow
## is dark gray.  As the cooldown recharges, yellow fills from left to right
## — giving a visual "charging up" feel.
##
## Key concept: **shape definition with row ranges**.
## Instead of storing every single pixel position, we define the arrow shape
## as a list of rows.  Each row says "fill pixels from x_start to x_end".
## This is compact, easy to read, and easy to modify if we want to tweak
## the arrow's proportions later!
##
## Key concept: **pixel-art outlines**.
## To draw a 1px outline around an irregular shape, we use a clever trick:
## for each pixel IN the shape, we check its 4 neighbors (up/down/left/right).
## If a neighbor is NOT in the shape, we draw an outline pixel there.
## This automatically traces the border of any shape, no matter how complex!

# ── Arrow shape definition ───────────────────────────────────────
# Each entry is [x_start, x_end) for that row — x_end is EXCLUSIVE.
# (Exclusive means "up to but not including" — same as range() works.)
#
# The shape looks like this (█ = filled pixel):
#
#   ░░░░░░░░░░░░░░░░░░██
#   ░░░░░░░░░░░░░░░░░░████
#   ████████████████████████
#   ░░░░░░░░░░░░░░░░░░████
#   ░░░░░░░░░░░░░░░░░░██
#
# Row 2 is the shaft (full 24px width).  The other rows form the arrowhead
# — a triangle pointing right.

const ARROW_ROWS: Array = [
	[18, 20],   # row 0: tip top (2px wide)
	[18, 22],   # row 1: upper arrowhead (4px wide)
	[0, 24],    # row 2: full shaft + arrowhead center (24px wide)
	[18, 22],   # row 3: lower arrowhead (4px wide)
	[18, 20],   # row 4: tip bottom (2px wide)
]

## Total width of the arrow shape in pixels.
const SHAPE_WIDTH: int = 24

# ── Colors ───────────────────────────────────────────────────────

## Bright yellow — shown when the cooldown is charged.
var ready_color: Color = Color(0.9, 0.75, 0.3)

## Dark gray — shown for the uncharged portion.
var cooldown_color: Color = Color(0.2, 0.2, 0.2)

## Dark yellow — used for the 1px border around the arrow.
var outline_color: Color = Color(0.4, 0.3, 0.1)

# ── State ────────────────────────────────────────────────────────

## How full the cooldown is: 1.0 = fully charged (ready), 0.0 = just used.
var fill_percent: float = 1.0


func set_cooldown(percent: float) -> void:
	## Update the cooldown fill amount (0.0 = empty, 1.0 = ready).
	fill_percent = clampf(percent, 0.0, 1.0)
	queue_redraw()


func _is_in_shape(x: int, y: int) -> bool:
	## Returns true if the pixel at (x, y) is inside the arrow shape.
	## Used by the outline-drawing code to figure out which pixels are
	## on the border (they have at least one neighbor outside the shape).
	if y < 0 or y >= ARROW_ROWS.size():
		return false
	return x >= ARROW_ROWS[y][0] and x < ARROW_ROWS[y][1]


func _draw() -> void:
	# How many pixels from the left should be filled with the "ready" color.
	var fill_x: int = int(SHAPE_WIDTH * fill_percent)

	# ── Pass 1: Draw the outline ────────────────────────────────
	# For every pixel in the shape, look at its 4 neighbors.
	# If a neighbor is OUTSIDE the shape, paint an outline pixel there.
	# This traces a perfect 1px border around the entire arrow!
	for row_idx in ARROW_ROWS.size():
		var x_start: int = ARROW_ROWS[row_idx][0]
		var x_end: int = ARROW_ROWS[row_idx][1]
		for x in range(x_start, x_end):
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx: int = x + offset.x
				var ny: int = row_idx + offset.y
				if not _is_in_shape(nx, ny):
					draw_rect(Rect2(nx, ny, 1, 1), outline_color)

	# ── Pass 2: Draw the shape pixels ───────────────────────────
	# Pixels to the LEFT of fill_x get the bright "ready" color.
	# Pixels to the RIGHT get the dark "cooldown" color.
	# This creates the left-to-right fill effect!
	for row_idx in ARROW_ROWS.size():
		var x_start: int = ARROW_ROWS[row_idx][0]
		var x_end: int = ARROW_ROWS[row_idx][1]
		for x in range(x_start, x_end):
			var color: Color = ready_color if x < fill_x else cooldown_color
			draw_rect(Rect2(x, row_idx, 1, 1), color)
