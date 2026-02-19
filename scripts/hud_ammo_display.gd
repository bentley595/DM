extends Node2D
## Displays the current ammo count with a small diamond icon.
##
## Instead of using a font, the numbers are drawn as PIXEL ART — tiny
## 3×5 bitmap digits rendered with draw_rect(), exactly like the health
## bar, roll arrow, and diamond icon.  This guarantees crisp rendering
## because it's just colored rectangles — no font antialiasing issues!
##
## Key concept: **bitmap font**.
## A bitmap font stores each character as a grid of pixels (0 or 1).
## To draw the number "12", we look up the grid for "1", draw it pixel
## by pixel, then move over and draw the grid for "2".  Old games used
## this technique for ALL their text before vector fonts existed!

# ── 3x3 diamond icon ────────────────────────────────────────────

const ICON_DIAMOND: Array = [
	[0, 1, 0],
	[1, 1, 1],
	[0, 1, 0],
]

# ── 3×5 pixel digits ────────────────────────────────────────────
# Each digit is a 5-row × 3-column grid.  1 = draw pixel, 0 = skip.
# At our 4× viewport scale, each pixel becomes 4×4 screen pixels,
# making these 12×20 screen pixels per digit — small but readable!

const DIGITS: Array = [
	# 0
	[[1,1,1],
	 [1,0,1],
	 [1,0,1],
	 [1,0,1],
	 [1,1,1]],
	# 1
	[[0,1,0],
	 [1,1,0],
	 [0,1,0],
	 [0,1,0],
	 [1,1,1]],
	# 2
	[[1,1,1],
	 [0,0,1],
	 [1,1,1],
	 [1,0,0],
	 [1,1,1]],
	# 3
	[[1,1,1],
	 [0,0,1],
	 [0,1,1],
	 [0,0,1],
	 [1,1,1]],
	# 4
	[[1,0,1],
	 [1,0,1],
	 [1,1,1],
	 [0,0,1],
	 [0,0,1]],
	# 5
	[[1,1,1],
	 [1,0,0],
	 [1,1,1],
	 [0,0,1],
	 [1,1,1]],
	# 6
	[[1,1,1],
	 [1,0,0],
	 [1,1,1],
	 [1,0,1],
	 [1,1,1]],
	# 7
	[[1,1,1],
	 [0,0,1],
	 [0,1,0],
	 [0,1,0],
	 [0,1,0]],
	# 8
	[[1,1,1],
	 [1,0,1],
	 [1,1,1],
	 [1,0,1],
	 [1,1,1]],
	# 9
	[[1,1,1],
	 [1,0,1],
	 [1,1,1],
	 [0,0,1],
	 [1,1,1]],
]

## Width of each digit in pixels.
const DIGIT_W: int = 3

## Height of each digit in pixels.
const DIGIT_H: int = 5

## Gap between digits (in pixels).
const DIGIT_GAP: int = 1

# ── Colors ───────────────────────────────────────────────────────

## Normal gold color — used when ammo is available.
const COLOR_NORMAL: Color = Color(0.9, 0.75, 0.3)

## Grey color — used during reload to show you're waiting.
const COLOR_RELOADING: Color = Color(0.45, 0.45, 0.45)

var icon_color: Color = COLOR_NORMAL
var text_color: Color = COLOR_NORMAL

# ── State ────────────────────────────────────────────────────────

var current_ammo: int = 12
var max_ammo: int = 12

## True while reloading — makes everything grey.
var is_reloading: bool = false


func set_ammo(current: int, max_val: int) -> void:
	## Update the displayed ammo count (normal mode — gold color).
	current_ammo = current
	max_ammo = max_val
	is_reloading = false
	icon_color = COLOR_NORMAL
	text_color = COLOR_NORMAL
	queue_redraw()


func set_reload_progress(refilled: int, max_val: int) -> void:
	## Update the display during reload — shows how many rounds have
	## been refilled so far, drawn in grey to show you can't shoot yet.
	##
	## The number counts up from 0 → max as the reload progresses,
	## giving you a clear visual of how much longer you need to wait.
	current_ammo = refilled
	max_ammo = max_val
	is_reloading = true
	icon_color = COLOR_RELOADING
	text_color = COLOR_RELOADING
	queue_redraw()


func _draw() -> void:
	# ── Draw diamond icon (3×3 pixels) ──────────────────────────
	for row in 3:
		for col in 3:
			if ICON_DIAMOND[row][col] == 1:
				draw_rect(Rect2(col, row, 1, 1), icon_color)

	# ── Draw ammo number as pixel-art digits ────────────────────
	# Convert the number to a string so we can draw each digit.
	# For example, 12 → "12" → draw digit 1, then digit 2.
	var text: String = str(current_ammo)
	var x_cursor: int = 5  # Start 5px right of icon (3px icon + 2px gap)
	var y_start: int = -1  # Vertically center digits with diamond icon

	for i in text.length():
		# Get the digit value (0-9) from the character.
		# "0".unicode_at(0) is 48, so subtracting it converts '0'→0, '1'→1, etc.
		var digit: int = text.unicode_at(i) - "0".unicode_at(0)

		# Safety check — skip anything that's not 0-9
		if digit < 0 or digit > 9:
			continue

		# Draw this digit's 3×5 grid
		var grid: Array = DIGITS[digit]
		for row in DIGIT_H:
			for col in DIGIT_W:
				if grid[row][col] == 1:
					draw_rect(Rect2(x_cursor + col, y_start + row, 1, 1), text_color)

		# Move cursor right for the next digit
		x_cursor += DIGIT_W + DIGIT_GAP
