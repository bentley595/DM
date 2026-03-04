extends Node2D
## Displays the player's gold count in the top-right corner of the HUD.
##
## Shows a small gold coin icon (3×3 circle) followed by the gold amount
## in bitmap text.  Uses the same _draw() pixel art approach as every
## other HUD element.
##
## Key concept: **right-aligned HUD elements**.
## Most HUD bars are left-aligned (health, momentum, etc.).  The gold
## display sits on the opposite side to balance the screen and avoid
## overlapping with the combat HUD.

# ── Coin icon (3×3) ──────────────────────────────────────────────
const COIN_ICON: Array = [
	[0, 1, 0],
	[1, 1, 1],
	[0, 1, 0],
]

# ── Colors ────────────────────────────────────────────────────────
const COLOR_COIN: Color = Color(0.9, 0.75, 0.3, 1.0)    # gold
const COLOR_TEXT: Color = Color(0.9, 0.75, 0.3, 1.0)     # gold text

# ── Bitmap font (same as inventory_screen.gd) ────────────────────
const LETTERS: Dictionary = {
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
	"G": [[0,1,1],[1,0,0],[1,0,1],[1,0,1],[0,1,1]],
}

# ── State ─────────────────────────────────────────────────────────
var gold: int = 0


func set_gold(amount: int) -> void:
	gold = amount
	queue_redraw()


func _draw() -> void:
	# Draw coin icon (3×3 pixels)
	for row in 3:
		for col in 3:
			if COIN_ICON[row][col] == 1:
				draw_rect(Rect2(col, row, 1, 1), COLOR_COIN)

	# Draw gold amount as bitmap text, right after the coin
	# Format: "123G" — number followed by G for gold
	var text: String = str(gold) + "G"
	var cx: int = 5  # start right after the coin icon + 2px gap
	for ch in text:
		if LETTERS.has(ch):
			var glyph: Array = LETTERS[ch]
			for row in range(glyph.size()):
				for col_idx in range(glyph[row].size()):
					if glyph[row][col_idx] == 1:
						draw_rect(Rect2(cx + col_idx, row - 1, 1, 1), COLOR_TEXT)
		cx += 4
