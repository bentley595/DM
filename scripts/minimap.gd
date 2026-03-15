extends Node2D
## Draws a minimap on the HUD showing the dungeon layout.
##
## Key concept: **fog of war / exploration**.
## The minimap only shows rooms the player has VISITED.  Unexplored
## rooms are hidden, so the player has to actually walk through doors
## to discover the dungeon layout.  This creates a sense of mystery
## and makes exploration feel rewarding — "what's behind this door?"
##
## The minimap auto-positions itself in the top-right corner of the
## screen, sized to fit the dungeon's grid dimensions.

# ── Cell dimensions ──────────────────────────────────────────────
## Each room is drawn as a small square on the minimap.
const CELL: int = 4        # Size of each room cell (pixels)
const GAP: int = 2         # Space between cells (bigger = connection lines are more visible)
const STEP: int = 6        # CELL + GAP (total step per grid position)
const CONN_WIDTH: int = 2  # Width of connection lines between rooms
const PADDING: int = 2     # Extra space around the minimap background

# ── Colors ───────────────────────────────────────────────────────
## Different colors help the player understand each room's status
## at a glance without needing to read text.

## Current room — bright white so you always know where you are.
const COLOR_CURRENT := Color(1.0, 1.0, 1.0, 1.0)

## Explored but not cleared — you've been here but enemies remain.
const COLOR_EXPLORED := Color(0.4, 0.4, 0.5, 1.0)

## Cleared room — green means "done, safe to pass through."
const COLOR_CLEARED := Color(0.3, 0.7, 0.3, 1.0)

## Boss/goal room — red screams "danger, final challenge!"
const COLOR_BOSS := Color(0.9, 0.2, 0.2, 1.0)

## Treasure room — gold/yellow for "something valuable here."
const COLOR_TREASURE := Color(1.0, 0.85, 0.2, 1.0)

## Ingredient room — cyan/light blue for "discovery awaits!"
const COLOR_INGREDIENT := Color(0.3, 0.85, 1.0, 1.0)

## Stairs room — tan/brown for stone steps.
const COLOR_STAIRS := Color(0.6, 0.55, 0.45, 1.0)

## Exit room — bright yellow-green, inviting "way out!"
const COLOR_EXIT := Color(0.9, 1.0, 0.7, 1.0)

## Connection lines between rooms — white so they're easy to see.
const COLOR_CONN := Color(1.0, 1.0, 1.0, 1.0)

## Semi-transparent background so the minimap is readable over the game.
const COLOR_BG := Color(0.0, 0.0, 0.0, 0.5)

# ── State ────────────────────────────────────────────────────────
## The full dungeon data from the generator.
var dungeon_data: Dictionary = {}

## The grid position of the room the player is currently in.
var current_pos: Vector2i = Vector2i.ZERO

## Cached grid bounds (calculated once in setup, used in _draw).
var _min_grid: Vector2i = Vector2i.ZERO
var _max_grid: Vector2i = Vector2i.ZERO

## Which floor number to display (1-indexed for the player).
var current_floor_number: int = 1


## Initializes the minimap with dungeon data and positions it on screen.
func setup(data: Dictionary) -> void:
	dungeon_data = data
	current_pos = data.get("start_pos", Vector2i.ZERO)
	_calculate_bounds()
	queue_redraw()


## Updates which room is highlighted as "current" and redraws.
func update_current(pos: Vector2i) -> void:
	current_pos = pos
	queue_redraw()


## Sets the floor number displayed on the minimap (1-indexed).
func set_floor(floor_num: int) -> void:
	current_floor_number = floor_num
	queue_redraw()


## Calculates the grid bounds and positions the minimap in the top-right.
func _calculate_bounds() -> void:
	var rooms: Dictionary = dungeon_data.get("rooms", {})
	if rooms.is_empty():
		return

	_min_grid = Vector2i(999, 999)
	_max_grid = Vector2i(-999, -999)

	for pos in rooms:
		_min_grid.x = mini(_min_grid.x, pos.x)
		_max_grid.x = maxi(_max_grid.x, pos.x)
		_min_grid.y = mini(_min_grid.y, pos.y)
		_max_grid.y = maxi(_max_grid.y, pos.y)

	# Calculate total pixel size of the minimap
	var grid_w: int = _max_grid.x - _min_grid.x + 1
	var grid_h: int = _max_grid.y - _min_grid.y + 1
	var map_w: int = grid_w * STEP - GAP + PADDING * 2
	var map_h: int = grid_h * STEP - GAP + PADDING * 2

	# Position at top-right of the 320x180 viewport
	# 316 = 320 - 4px margin from the right edge
	position = Vector2(316 - map_w, 4)


func _draw() -> void:
	if dungeon_data.is_empty():
		return

	var rooms: Dictionary = dungeon_data["rooms"]

	# ── Background rectangle ─────────────────────────────────
	var grid_w: int = _max_grid.x - _min_grid.x + 1
	var grid_h: int = _max_grid.y - _min_grid.y + 1
	var map_w: int = grid_w * STEP - GAP + PADDING * 2
	var map_h: int = grid_h * STEP - GAP + PADDING * 2
	draw_rect(Rect2(0, 0, map_w, map_h), COLOR_BG)

	# ── Floor number label ───────────────────────────────────
	# Draw "F1", "F2", etc. in the top-left corner of the minimap.
	# Uses tiny 3x5 pixel bitmap characters so it fits the pixel art style.
	_draw_floor_label(map_w, map_h)

	# ── Draw connections between explored rooms ──────────────
	# These thin lines show which rooms are connected by doors.
	# We only draw rightward and downward connections to avoid
	# drawing each connection twice (the neighbor would draw it
	# in the opposite direction otherwise).
	for pos in rooms:
		var room: Dictionary = rooms[pos]
		if not room["explored"]:
			continue

		# Top-left corner of this room cell (in minimap pixels)
		var rx: float = PADDING + (pos.x - _min_grid.x) * STEP
		var ry: float = PADDING + (pos.y - _min_grid.y) * STEP

		# Right connection — a small rectangle filling the gap between
		# this room and the room to the right, centered vertically.
		if room["doors"].get("right", false):
			var n_pos: Vector2i = pos + Vector2i(1, 0)
			if rooms.has(n_pos) and rooms[n_pos]["explored"]:
				draw_rect(Rect2(
					rx + CELL,                        # starts at right edge of cell
					ry + (CELL - CONN_WIDTH) / 2.0,   # centered vertically
					GAP, CONN_WIDTH                    # fills the gap
				), COLOR_CONN)

		# Down connection — same idea but vertical.
		if room["doors"].get("down", false):
			var n_pos: Vector2i = pos + Vector2i(0, 1)
			if rooms.has(n_pos) and rooms[n_pos]["explored"]:
				draw_rect(Rect2(
					rx + (CELL - CONN_WIDTH) / 2.0,   # centered horizontally
					ry + CELL,                         # starts at bottom edge of cell
					CONN_WIDTH, GAP                    # fills the gap
				), COLOR_CONN)

	# ── Draw unexplored neighbor hints ───────────────────────
	# If a room is unexplored but sits next to an explored room,
	# draw it as a white border with a black inside.  This tells
	# the player "there's a room here you haven't visited yet!"
	# We use a Dictionary to avoid drawing the same hint twice
	# (multiple explored rooms might share the same unexplored neighbor).
	var _hinted: Dictionary = {}
	for pos in rooms:
		var room: Dictionary = rooms[pos]
		if not room["explored"]:
			continue
		# Check all 4 doors — if a door leads to an unexplored room, hint it
		for dir in room["doors"]:
			if not room["doors"][dir]:
				continue
			var n_pos: Vector2i = pos + Vector2i(
				1 if dir == "right" else (-1 if dir == "left" else 0),
				1 if dir == "down" else (-1 if dir == "up" else 0),
			)
			if rooms.has(n_pos) and not rooms[n_pos]["explored"] and not _hinted.has(n_pos):
				_hinted[n_pos] = true
				var hx: float = PADDING + (n_pos.x - _min_grid.x) * STEP
				var hy: float = PADDING + (n_pos.y - _min_grid.y) * STEP
				# White border (full cell)
				draw_rect(Rect2(hx, hy, CELL, CELL), Color.WHITE)
				# Black inside (1px smaller on each side)
				draw_rect(Rect2(hx + 1, hy + 1, CELL - 2, CELL - 2), Color.BLACK)

	# ── Draw room cells ──────────────────────────────────────
	# Each explored room gets a colored square.  The color tells
	# the player what kind of room it is and whether it's cleared.
	for pos in rooms:
		var room: Dictionary = rooms[pos]
		if not room["explored"]:
			continue

		var rx: float = PADDING + (pos.x - _min_grid.x) * STEP
		var ry: float = PADDING + (pos.y - _min_grid.y) * STEP

		# Pick color based on room status
		var color: Color
		if pos == current_pos:
			# Current room is always white (highest priority)
			color = COLOR_CURRENT
		elif room["type"] == 4:  # BOSS
			color = COLOR_BOSS
		elif room["type"] == 6:  # STAIRS
			color = COLOR_STAIRS
		elif room["type"] == 7:  # EXIT
			color = COLOR_EXIT
		elif room["type"] == 2:  # TREASURE
			color = COLOR_TREASURE if not room["cleared"] else COLOR_CLEARED
		elif room["type"] == 5:  # INGREDIENT
			color = COLOR_INGREDIENT if not room["cleared"] else COLOR_CLEARED
		elif room["cleared"]:
			color = COLOR_CLEARED
		else:
			color = COLOR_EXPLORED

		draw_rect(Rect2(rx, ry, CELL, CELL), color)


## Draws a tiny floor number label like "F1" in the bottom-left of the minimap.
##
## Key concept: **bitmap font rendering**.
## Since we can't use real text at this tiny scale (each room is only
## 4px!), we draw letters pixel-by-pixel using small grid arrays.
## Each character is 3 pixels wide and 5 pixels tall — just enough
## to be readable at the minimap's scale.
func _draw_floor_label(_map_w: int, _map_h: int) -> void:
	var label_col := Color(0.7, 0.7, 0.8, 0.9)
	var lx: float = 1.0        # left edge of label
	var ly: float = _map_h - 6.0  # near bottom of minimap

	# "F" character (3x5 pixels)
	# ###
	# #
	# ##
	# #
	# #
	draw_rect(Rect2(lx, ly, 3, 1), label_col)
	draw_rect(Rect2(lx, ly + 1, 1, 1), label_col)
	draw_rect(Rect2(lx, ly + 2, 2, 1), label_col)
	draw_rect(Rect2(lx, ly + 3, 1, 1), label_col)
	draw_rect(Rect2(lx, ly + 4, 1, 1), label_col)

	# Digit (3x5 pixels) — drawn 4px to the right of "F"
	var dx: float = lx + 4
	_draw_digit(dx, ly, current_floor_number, label_col)


## Draws a single digit (0-9) as a 3x5 pixel bitmap.
func _draw_digit(x: float, y: float, digit: int, col: Color) -> void:
	# Each digit is encoded as an array of 5 rows, each row is 3 bits.
	# 1 = pixel on, 0 = pixel off.
	var glyphs: Array = [
		# 0: ###  #.#  #.#  #.#  ###
		[7, 5, 5, 5, 7],
		# 1: .#.  ##.  .#.  .#.  ###
		[2, 6, 2, 2, 7],
		# 2: ###  ..#  ###  #..  ###
		[7, 1, 7, 4, 7],
		# 3: ###  ..#  ###  ..#  ###
		[7, 1, 7, 1, 7],
		# 4: #.#  #.#  ###  ..#  ..#
		[5, 5, 7, 1, 1],
		# 5: ###  #..  ###  ..#  ###
		[7, 4, 7, 1, 7],
		# 6: ###  #..  ###  #.#  ###
		[7, 4, 7, 5, 7],
		# 7: ###  ..#  ..#  ..#  ..#
		[7, 1, 1, 1, 1],
		# 8: ###  #.#  ###  #.#  ###
		[7, 5, 7, 5, 7],
		# 9: ###  #.#  ###  ..#  ###
		[7, 5, 7, 1, 7],
	]

	var d: int = clampi(digit, 0, 9)
	var glyph: Array = glyphs[d]
	for row in range(5):
		var bits: int = glyph[row]
		for bit in range(3):
			# Check each bit from left (bit 2) to right (bit 0)
			if bits & (1 << (2 - bit)):
				draw_rect(Rect2(x + bit, y + row, 1, 1), col)
