extends Node2D
## Draws a short string as crisp pixel-art text using a built-in 3×5 bitmap font.
##
## Key concept: **why bitmap text instead of a font file?**
## Godot renders vector fonts (like Pixelify Sans) by rasterising them at the
## requested size.  At very small sizes — especially through a 4× viewport
## scale — this produces blurry, slightly smeared pixels.  A bitmap font is
## just a grid of 0s and 1s: every pixel is either on or off, no blur possible!
## It's the same technique used by classic Game Boy and NES games.
##
## Text is automatically centered at the node's origin.
## Call set_text() or assign .text directly to update it.

# ── 3×5 bitmap font ──────────────────────────────────────────────
# Each entry is a 5-row × 3-column array.  1 = draw pixel, 0 = skip.
# Characters advance 4px per glyph (3px wide + 1px gap).

const GLYPH_W:   int = 3
const GLYPH_H:   int = 5
const GLYPH_GAP: int = 1

const LETTERS: Dictionary = {
	"A": [[0,1,0],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
	"B": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,1,0]],
	"C": [[0,1,1],[1,0,0],[1,0,0],[1,0,0],[0,1,1]],
	"D": [[1,1,0],[1,0,1],[1,0,1],[1,0,1],[1,1,0]],
	"E": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,1,1]],
	"F": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,0,0]],
	"G": [[0,1,1],[1,0,0],[1,0,1],[1,0,1],[0,1,1]],
	"H": [[1,0,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
	"I": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[1,1,1]],
	"J": [[0,0,1],[0,0,1],[0,0,1],[1,0,1],[0,1,0]],
	"K": [[1,0,1],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
	"L": [[1,0,0],[1,0,0],[1,0,0],[1,0,0],[1,1,1]],
	"M": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
	"N": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
	"O": [[0,1,0],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
	"P": [[1,1,0],[1,0,1],[1,1,0],[1,0,0],[1,0,0]],
	"Q": [[0,1,0],[1,0,1],[1,0,1],[1,1,1],[0,0,1]],
	"R": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
	"S": [[0,1,1],[1,0,0],[0,1,0],[0,0,1],[1,1,0]],
	"T": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[0,1,0]],
	"U": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
	"V": [[1,0,1],[1,0,1],[1,0,1],[0,1,0],[0,1,0]],
	"W": [[1,0,1],[1,0,1],[1,1,1],[1,1,1],[1,0,1]],
	"X": [[1,0,1],[1,0,1],[0,1,0],[1,0,1],[1,0,1]],
	"Y": [[1,0,1],[1,0,1],[0,1,0],[0,1,0],[0,1,0]],
	"Z": [[1,1,1],[0,0,1],[0,1,0],[1,0,0],[1,1,1]],
	"0": [[0,1,0],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
	"1": [[0,1,0],[1,1,0],[0,1,0],[0,1,0],[1,1,1]],
	"2": [[1,1,0],[0,0,1],[0,1,0],[1,0,0],[1,1,1]],
	"3": [[1,1,0],[0,0,1],[0,1,0],[0,0,1],[1,1,0]],
	"4": [[1,0,1],[1,0,1],[1,1,1],[0,0,1],[0,0,1]],
	"5": [[1,1,1],[1,0,0],[1,1,0],[0,0,1],[1,1,0]],
	"6": [[0,1,1],[1,0,0],[1,1,0],[1,0,1],[0,1,0]],
	"7": [[1,1,1],[0,0,1],[0,1,0],[0,1,0],[0,1,0]],
	"8": [[0,1,0],[1,0,1],[0,1,0],[1,0,1],[0,1,0]],
	"9": [[0,1,0],[1,0,1],[0,1,1],[0,0,1],[0,1,0]],
	" ": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],
	"/": [[0,0,1],[0,0,1],[0,1,0],[1,0,0],[1,0,0]],
	"!": [[0,1,0],[0,1,0],[0,1,0],[0,0,0],[0,1,0]],
	"+": [[0,0,0],[0,1,0],[1,1,1],[0,1,0],[0,0,0]],
}

# ── State ─────────────────────────────────────────────────────────

## The string to display.  Assigning it triggers an automatic redraw.
var text: String = "":
	set(value):
		text = value
		queue_redraw()

## Color of the drawn pixels.
@export var text_color: Color = Color.WHITE

## How many screen pixels each font pixel occupies.
## 1 = normal (3×5 per letter), 2 = double size (6×10), etc.
## This is the same concept as character_sprite's pixel_size —
## scaling up pixel art by drawing bigger squares keeps it crisp!
var pixel_size: int = 1:
	set(value):
		pixel_size = value
		queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return

	var upper: String = text.to_upper()
	var ps: int = pixel_size

	# Calculate the total pixel width so we can center it at x=0.
	# Each glyph is GLYPH_W * ps wide, with GLYPH_GAP * ps gap between them.
	var total_w: int = upper.length() * (GLYPH_W + GLYPH_GAP) * ps - GLYPH_GAP * ps
	var x: int      = -total_w / 2
	var y: int      = 0

	for ch in upper:
		if LETTERS.has(ch):
			var glyph: Array = LETTERS[ch]
			for row in GLYPH_H:
				for col in GLYPH_W:
					if glyph[row][col] == 1:
						draw_rect(Rect2(x + col * ps, y + row * ps, ps, ps), text_color)
		x += (GLYPH_W + GLYPH_GAP) * ps
