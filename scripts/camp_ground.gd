extends Node2D
## Draws subtle ground decoration for the camp — paths, stones, borders.
##
## This is purely visual — no gameplay logic at all.  It just makes
## the camp look nicer than a flat dark background.
##
## Key concept: **visual layering**.
## By drawing this AFTER the background ColorRect but BEFORE the player
## and stations (the scene tree order in camp.tscn), these decorations
## appear on the ground underneath everything else.  This is the same
## technique used in many pixel-art games for floor tiles!

# ── Decorative elements ─────────────────────────────────────────
# Colors are very subtle — just barely visible against the dark background
const COL_PATH     := Color(0.09, 0.08, 0.13, 1.0)  # slightly lighter path
const COL_STONE    := Color(0.08, 0.07, 0.12, 1.0)  # scattered stones
const COL_BORDER   := Color(0.04, 0.04, 0.08, 1.0)  # edge border (darker)


func _draw() -> void:
	# ── Border frame around the play area ──────────────────────
	# Top border
	draw_rect(Rect2(8, 32, 304, 2), COL_BORDER)
	# Bottom border
	draw_rect(Rect2(8, 162, 304, 2), COL_BORDER)
	# Left border
	draw_rect(Rect2(8, 32, 2, 132), COL_BORDER)
	# Right border
	draw_rect(Rect2(310, 32, 2, 132), COL_BORDER)

	# ── Central cross-path connecting stations ─────────────────
	# Horizontal path (connects Dummy ↔ Dungeon area)
	draw_rect(Rect2(40, 108, 240, 4), COL_PATH)
	# Vertical path (connects Forge/Shop ↔ Dungeon entrance)
	draw_rect(Rect2(158, 50, 4, 110), COL_PATH)

	# ── Scattered ground stones for texture ────────────────────
	# Small 2×2 pixel stones placed around the camp
	var stones: Array = [
		Vector2(30, 70), Vector2(80, 120), Vector2(140, 80),
		Vector2(200, 130), Vector2(250, 70), Vector2(290, 110),
		Vector2(60, 140), Vector2(110, 95), Vector2(230, 100),
		Vector2(180, 75), Vector2(100, 50), Vector2(260, 140),
		Vector2(45, 110), Vector2(170, 140), Vector2(300, 85),
	]
	for s in stones:
		draw_rect(Rect2(s.x, s.y, 2, 2), COL_STONE)
