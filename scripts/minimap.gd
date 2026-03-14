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
const GAP: int = 1         # Space between cells
const STEP: int = 5        # CELL + GAP (total step per grid position)
const CONN_WIDTH: int = 1  # Width of connection lines between rooms
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

## Connection lines between rooms — subtle so they don't distract.
const COLOR_CONN := Color(0.3, 0.3, 0.35, 0.8)

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
	var goal_pos: Vector2i = dungeon_data.get("goal_pos", Vector2i.ZERO)

	# ── Background rectangle ─────────────────────────────────
	var grid_w: int = _max_grid.x - _min_grid.x + 1
	var grid_h: int = _max_grid.y - _min_grid.y + 1
	var map_w: int = grid_w * STEP - GAP + PADDING * 2
	var map_h: int = grid_h * STEP - GAP + PADDING * 2
	draw_rect(Rect2(0, 0, map_w, map_h), COLOR_BG)

	# ── Draw connections between explored rooms ──────────────
	# These thin lines show which rooms are connected by doors.
	# We only draw rightward and downward connections to avoid
	# drawing each connection twice (the neighbor would draw it
	# in the opposite direction otherwise).
	for pos in rooms:
		var room: Dictionary = rooms[pos]
		if not room["explored"]:
			continue

		# Convert grid position to pixel position on the minimap
		var cx: float = PADDING + (pos.x - _min_grid.x) * STEP + CELL / 2.0
		var cy: float = PADDING + (pos.y - _min_grid.y) * STEP + CELL / 2.0

		# Right connection
		if room["doors"].get("right", false):
			var n_pos: Vector2i = pos + Vector2i(1, 0)
			if rooms.has(n_pos) and rooms[n_pos]["explored"]:
				draw_rect(Rect2(
					cx + CELL / 2.0, cy - CONN_WIDTH / 2.0,
					GAP, CONN_WIDTH
				), COLOR_CONN)

		# Down connection
		if room["doors"].get("down", false):
			var n_pos: Vector2i = pos + Vector2i(0, 1)
			if rooms.has(n_pos) and rooms[n_pos]["explored"]:
				draw_rect(Rect2(
					cx - CONN_WIDTH / 2.0, cy + CELL / 2.0,
					CONN_WIDTH, GAP
				), COLOR_CONN)

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
		elif pos == goal_pos:
			# Boss/goal room — red (even if cleared, it's memorable)
			color = COLOR_BOSS
		elif room["type"] == 2:  # TREASURE
			color = COLOR_TREASURE if not room["cleared"] else COLOR_CLEARED
		elif room["type"] == 5:  # INGREDIENT
			color = COLOR_INGREDIENT if not room["cleared"] else COLOR_CLEARED
		elif room["cleared"]:
			color = COLOR_CLEARED
		else:
			color = COLOR_EXPLORED

		draw_rect(Rect2(rx, ry, CELL, CELL), color)
