extends Node2D
## Draws ground decoration + flickering torches for the camp.
##
## This is purely visual -- no gameplay logic.  It draws:
##   1. Border frame around the play area
##   2. Cross-shaped paths connecting stations
##   3. Scattered stones for texture
##   4. Ground torches with warm glow and flickering flames
##
## Key concept: **visual layering**.
## By drawing this AFTER the background ColorRect but BEFORE the player
## and stations (the scene tree order in camp.tscn), these decorations
## appear on the ground underneath everything else.

# -- Decorative colors --
# Very subtle -- just barely visible against the dark background
const COL_PATH     := Color(0.09, 0.08, 0.13, 1.0)
const COL_STONE    := Color(0.08, 0.07, 0.12, 1.0)
const COL_BORDER   := Color(0.04, 0.04, 0.08, 1.0)

# -- Torch positions --
# Placed around the camp to light up key areas.  Each torch is a
# small wooden post with a flame on top and a warm glow circle.
# We picked spots near stations and along paths so the player
# can see where they're going.
const TORCH_POSITIONS: Array = [
	Vector2(85, 75),    # between dummy and forge
	Vector2(85, 135),   # below dummy area
	Vector2(235, 75),   # between shop and infinite dungeon
	Vector2(235, 135),  # right side, lower
	Vector2(160, 70),   # center top (between forge and shop)
	Vector2(130, 148),  # left of dungeon entrance
	Vector2(190, 148),  # right of dungeon entrance
]

# -- Flicker timer --
# Same technique as the dungeon torches!  Every 0.15 seconds we
# call queue_redraw() which triggers _draw() again.  Since the
# flame colors use randf_range(), each redraw looks different.
const FLICKER_INTERVAL: float = 0.15
var _flicker_timer: float = 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = FLICKER_INTERVAL
		queue_redraw()


func _draw() -> void:
	# -- Torch glow (drawn first so it goes UNDER everything) --
	# 3-layer glow: faint outer, medium middle, bright inner.
	# The overlapping semi-transparent rectangles create a soft
	# gradient effect -- brighter in the center, fading at edges.
	for tp in TORCH_POSITIONS:
		var glow_var: float = randf_range(0.7, 1.3)
		var g_outer := Color(1.0, 0.45, 0.0, 0.025 * glow_var)
		var g_mid   := Color(1.0, 0.5, 0.0, 0.05 * glow_var)
		var g_inner := Color(1.0, 0.6, 0.1, 0.09 * glow_var)
		draw_rect(Rect2(tp.x - 20, tp.y - 16, 40, 32), g_outer)
		draw_rect(Rect2(tp.x - 13, tp.y - 10, 26, 20), g_mid)
		draw_rect(Rect2(tp.x - 7, tp.y - 5, 14, 10), g_inner)

	# -- Border frame around the play area --
	draw_rect(Rect2(8, 32, 304, 2), COL_BORDER)    # top
	draw_rect(Rect2(8, 162, 304, 2), COL_BORDER)    # bottom
	draw_rect(Rect2(8, 32, 2, 132), COL_BORDER)     # left
	draw_rect(Rect2(310, 32, 2, 132), COL_BORDER)   # right

	# -- Central cross-path connecting stations --
	draw_rect(Rect2(40, 108, 240, 4), COL_PATH)     # horizontal
	draw_rect(Rect2(158, 50, 4, 110), COL_PATH)     # vertical

	# -- Scattered ground stones for texture --
	var stones: Array = [
		Vector2(30, 70), Vector2(80, 120), Vector2(140, 80),
		Vector2(200, 130), Vector2(250, 70), Vector2(290, 110),
		Vector2(60, 140), Vector2(110, 95), Vector2(230, 100),
		Vector2(180, 75), Vector2(100, 50), Vector2(260, 140),
		Vector2(45, 110), Vector2(170, 140), Vector2(300, 85),
	]
	for s in stones:
		draw_rect(Rect2(s.x, s.y, 2, 2), COL_STONE)

	# -- Ground torches --
	# Each torch is a short wooden post seen from above, with a
	# multi-layered flame on top.  The flame dances each flicker tick.
	#
	# A ground torch looks different from a wall torch -- it's a
	# small circle/square base with fire rising from the center.
	var POST_DARK  := Color(0.30, 0.20, 0.10)  # dark wood
	var POST_LIGHT := Color(0.40, 0.28, 0.14)  # lighter wood edge

	for tp in TORCH_POSITIONS:
		var tx: float = tp.x
		var ty: float = tp.y

		# Wooden post base (3x3 square with highlight)
		draw_rect(Rect2(tx - 1, ty, 3, 3), POST_DARK)
		draw_rect(Rect2(tx - 1, ty, 2, 1), POST_LIGHT)

		# Flame -- same multi-layer approach as dungeon torches.
		# Height and lean randomize each flicker tick.
		var flame_h: int = randi_range(3, 5)
		var lean: int = randi_range(-1, 1)

		# Layer 1: dark red base
		var red_base := Color(
			randf_range(0.7, 0.85),
			randf_range(0.15, 0.3),
			randf_range(0.0, 0.1),
		)
		draw_rect(Rect2(tx - 1, ty - 1, 3, 1), red_base)

		# Layer 2: orange middle
		var orange_mid := Color(
			randf_range(0.9, 1.0),
			randf_range(0.45, 0.65),
			randf_range(0.0, 0.15),
		)
		draw_rect(Rect2(tx - 1 + lean, ty - 2, 2, 1), orange_mid)
		if flame_h >= 4:
			draw_rect(Rect2(tx + lean, ty - 3, 2, 1), orange_mid)

		# Layer 3: yellow core
		var yellow_core := Color(
			randf_range(0.95, 1.0),
			randf_range(0.75, 0.95),
			randf_range(0.1, 0.3),
		)
		var tip_y: float = ty - flame_h
		draw_rect(Rect2(tx + lean, tip_y + 1, 1, 1), yellow_core)

		# Layer 4: white-hot tip
		var white_tip := Color(
			1.0,
			randf_range(0.9, 1.0),
			randf_range(0.5, 0.85),
		)
		draw_rect(Rect2(tx + lean, tip_y, 1, 1), white_tip)

		# Embers -- tiny sparks floating up
		var num_embers: int = randi_range(0, 2)
		for _e in num_embers:
			var ex: float = tx + randf_range(-2, 3)
			var ey: float = tip_y + randf_range(-4, -1)
			var ember_col := Color(
				1.0,
				randf_range(0.4, 0.8),
				randf_range(0.0, 0.2),
				randf_range(0.3, 0.8),
			)
			draw_rect(Rect2(ex, ey, 1, 1), ember_col)
