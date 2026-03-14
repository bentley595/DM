extends RefCounted
## Draws the current dungeon room — walls, floor, doors, and decorations.
##
## Key concept: **draw signal pattern**.
## Instead of overriding _draw() on a Node2D (which can have issues with
## dynamically created nodes), we use the "draw signal" pattern:
##   1. Create a bare Node2D in the scene
##   2. Connect its `draw` signal to a callback
##   3. The callback calls our draw_room() method, passing the Node2D
##   4. We call canvas.draw_rect() etc. to draw on that node
## This is the same pattern used by the darkness overlay in game.gd!

# ── Room boundaries ──────────────────────────────────────────────
const ROOM_LEFT: float = 8.0
const ROOM_RIGHT: float = 312.0
const ROOM_TOP: float = 28.0
const ROOM_BOTTOM: float = 166.0
const WALL: float = 8.0

# ── Door dimensions ──────────────────────────────────────────────
const DOOR_WIDTH: float = 32.0
const DOOR_CENTER_X: float = 160.0
const DOOR_CENTER_Y: float = 97.0

# ── Colors ───────────────────────────────────────────────────────
const WALL_COLOR := Color(0.45, 0.38, 0.60)
const WALL_EDGE := Color(0.60, 0.52, 0.75)
const WALL_OUTER := Color(0.30, 0.25, 0.42)
const MORTAR_COLOR := Color(0.28, 0.22, 0.38)
const DOOR_FRAME := Color(0.75, 0.70, 0.90)
const DOOR_OPEN := Color(0.06, 0.05, 0.10)
const DOOR_LOCKED := Color(0.60, 0.35, 0.18)
const FLOOR_A := Color(0.14, 0.12, 0.20)
const FLOOR_B := Color(0.18, 0.15, 0.24)
const TORCH_BRACKET := Color(0.45, 0.30, 0.15)
const TORCH_FLAME := Color(1.0, 0.75, 0.2)
const TORCH_TIP := Color(1.0, 0.95, 0.6)
const TORCH_GLOW_A := Color(1.0, 0.6, 0.1, 0.12)
const TORCH_GLOW_B := Color(1.0, 0.5, 0.0, 0.06)

# ── State ────────────────────────────────────────────────────────
var doors := {"up": false, "down": false, "left": false, "right": false}
var doors_locked := false
var room_type := 1

## The Node2D we're currently drawing on (set during draw_room).
var _c: Node2D


func setup(room_data: Dictionary, locked: bool, _grid_pos: Vector2i) -> void:
	doors = room_data["doors"]
	doors_locked = locked
	room_type = room_data.get("type", 1)


func set_doors_locked(locked: bool) -> void:
	doors_locked = locked


## Draws the entire room onto the given canvas Node2D.
## Called from the dungeon manager when the canvas's draw signal fires.
func draw_room(canvas: Node2D) -> void:
	_c = canvas
	var hd := DOOR_WIDTH / 2.0
	var il := ROOM_LEFT + WALL
	var ir := ROOM_RIGHT - WALL
	var it := ROOM_TOP + WALL
	var ib := ROOM_BOTTOM - WALL

	# Dark void background
	_c.draw_rect(Rect2(0, 0, 320, 180), Color(0.03, 0.03, 0.08))

	# Floor checkerboard
	var tile := 8.0
	var x := il
	while x < ir:
		var y := it
		while y < ib:
			var col := FLOOR_A if (int(x / tile) + int(y / tile)) % 2 == 0 else FLOOR_B
			_c.draw_rect(Rect2(x, y, minf(tile, ir - x), minf(tile, ib - y)), col)
			y += tile
		x += tile

	# Floor details (cracks + pebbles)
	_draw_floor_details(il, ir, it, ib)

	# Torch glow on floor (drawn before walls)
	_draw_torch_glow(il, ir)

	# Walls
	var dc := DOOR_LOCKED if doors_locked else DOOR_OPEN

	# Top
	if doors.get("up", false):
		_c.draw_rect(Rect2(ROOM_LEFT, ROOM_TOP, DOOR_CENTER_X - hd - ROOM_LEFT, WALL), WALL_COLOR)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, ROOM_TOP, ROOM_RIGHT - DOOR_CENTER_X - hd, WALL), WALL_COLOR)
		_c.draw_rect(Rect2(DOOR_CENTER_X - hd, ROOM_TOP, DOOR_WIDTH, WALL), dc)
		_c.draw_rect(Rect2(DOOR_CENTER_X - hd - 2, ROOM_TOP, 2, WALL), DOOR_FRAME)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, ROOM_TOP, 2, WALL), DOOR_FRAME)
	else:
		_c.draw_rect(Rect2(ROOM_LEFT, ROOM_TOP, ROOM_RIGHT - ROOM_LEFT, WALL), WALL_COLOR)

	# Bottom
	if doors.get("down", false):
		_c.draw_rect(Rect2(ROOM_LEFT, ib, DOOR_CENTER_X - hd - ROOM_LEFT, WALL), WALL_COLOR)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, ib, ROOM_RIGHT - DOOR_CENTER_X - hd, WALL), WALL_COLOR)
		_c.draw_rect(Rect2(DOOR_CENTER_X - hd, ib, DOOR_WIDTH, WALL), dc)
		_c.draw_rect(Rect2(DOOR_CENTER_X - hd - 2, ib, 2, WALL), DOOR_FRAME)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, ib, 2, WALL), DOOR_FRAME)
	else:
		_c.draw_rect(Rect2(ROOM_LEFT, ib, ROOM_RIGHT - ROOM_LEFT, WALL), WALL_COLOR)

	# Left
	if doors.get("left", false):
		_c.draw_rect(Rect2(ROOM_LEFT, ROOM_TOP, WALL, DOOR_CENTER_Y - hd - ROOM_TOP), WALL_COLOR)
		_c.draw_rect(Rect2(ROOM_LEFT, DOOR_CENTER_Y + hd, WALL, ROOM_BOTTOM - DOOR_CENTER_Y - hd), WALL_COLOR)
		_c.draw_rect(Rect2(ROOM_LEFT, DOOR_CENTER_Y - hd, WALL, DOOR_WIDTH), dc)
		_c.draw_rect(Rect2(ROOM_LEFT, DOOR_CENTER_Y - hd - 2, WALL, 2), DOOR_FRAME)
		_c.draw_rect(Rect2(ROOM_LEFT, DOOR_CENTER_Y + hd, WALL, 2), DOOR_FRAME)
	else:
		_c.draw_rect(Rect2(ROOM_LEFT, ROOM_TOP, WALL, ROOM_BOTTOM - ROOM_TOP), WALL_COLOR)

	# Right
	if doors.get("right", false):
		_c.draw_rect(Rect2(ir, ROOM_TOP, WALL, DOOR_CENTER_Y - hd - ROOM_TOP), WALL_COLOR)
		_c.draw_rect(Rect2(ir, DOOR_CENTER_Y + hd, WALL, ROOM_BOTTOM - DOOR_CENTER_Y - hd), WALL_COLOR)
		_c.draw_rect(Rect2(ir, DOOR_CENTER_Y - hd, WALL, DOOR_WIDTH), dc)
		_c.draw_rect(Rect2(ir, DOOR_CENTER_Y - hd - 2, WALL, 2), DOOR_FRAME)
		_c.draw_rect(Rect2(ir, DOOR_CENTER_Y + hd, WALL, 2), DOOR_FRAME)
	else:
		_c.draw_rect(Rect2(ir, ROOM_TOP, WALL, ROOM_BOTTOM - ROOM_TOP), WALL_COLOR)

	# Mortar line on each wall
	var my := ROOM_TOP + 4
	if doors.get("up", false):
		_c.draw_rect(Rect2(ROOM_LEFT + 1, my, DOOR_CENTER_X - hd - ROOM_LEFT - 1, 1), MORTAR_COLOR)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, my, ROOM_RIGHT - DOOR_CENTER_X - hd - 1, 1), MORTAR_COLOR)
	else:
		_c.draw_rect(Rect2(ROOM_LEFT + 1, my, ROOM_RIGHT - ROOM_LEFT - 2, 1), MORTAR_COLOR)

	my = ROOM_BOTTOM - WALL + 4
	if doors.get("down", false):
		_c.draw_rect(Rect2(ROOM_LEFT + 1, my, DOOR_CENTER_X - hd - ROOM_LEFT - 1, 1), MORTAR_COLOR)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, my, ROOM_RIGHT - DOOR_CENTER_X - hd - 1, 1), MORTAR_COLOR)
	else:
		_c.draw_rect(Rect2(ROOM_LEFT + 1, my, ROOM_RIGHT - ROOM_LEFT - 2, 1), MORTAR_COLOR)

	var mx := ROOM_LEFT + 4
	if doors.get("left", false):
		_c.draw_rect(Rect2(mx, ROOM_TOP + 1, 1, DOOR_CENTER_Y - hd - ROOM_TOP - 1), MORTAR_COLOR)
		_c.draw_rect(Rect2(mx, DOOR_CENTER_Y + hd, 1, ROOM_BOTTOM - DOOR_CENTER_Y - hd - 1), MORTAR_COLOR)
	else:
		_c.draw_rect(Rect2(mx, ROOM_TOP + 1, 1, ROOM_BOTTOM - ROOM_TOP - 2), MORTAR_COLOR)

	mx = ROOM_RIGHT - WALL + 4
	if doors.get("right", false):
		_c.draw_rect(Rect2(mx, ROOM_TOP + 1, 1, DOOR_CENTER_Y - hd - ROOM_TOP - 1), MORTAR_COLOR)
		_c.draw_rect(Rect2(mx, DOOR_CENTER_Y + hd, 1, ROOM_BOTTOM - DOOR_CENTER_Y - hd - 1), MORTAR_COLOR)
	else:
		_c.draw_rect(Rect2(mx, ROOM_TOP + 1, 1, ROOM_BOTTOM - ROOM_TOP - 2), MORTAR_COLOR)

	# Inner edge highlight
	_draw_inner_edges(il, ir, it, ib, hd)

	# Outer edge
	_c.draw_rect(Rect2(ROOM_LEFT, ROOM_TOP, ROOM_RIGHT - ROOM_LEFT, 1), WALL_OUTER)
	_c.draw_rect(Rect2(ROOM_LEFT, ROOM_BOTTOM - 1, ROOM_RIGHT - ROOM_LEFT, 1), WALL_OUTER)
	_c.draw_rect(Rect2(ROOM_LEFT, ROOM_TOP, 1, ROOM_BOTTOM - ROOM_TOP), WALL_OUTER)
	_c.draw_rect(Rect2(ROOM_RIGHT - 1, ROOM_TOP, 1, ROOM_BOTTOM - ROOM_TOP), WALL_OUTER)

	# Torches
	_draw_torches(il, ir)

	# Room-type icon in the center
	_draw_room_icon(il, ir, it, ib)


func _draw_inner_edges(il: float, ir: float, it: float, ib: float, hd: float) -> void:
	if doors.get("up", false):
		_c.draw_rect(Rect2(il, it, DOOR_CENTER_X - hd - il, 1), WALL_EDGE)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, it, ir - DOOR_CENTER_X - hd, 1), WALL_EDGE)
	else:
		_c.draw_rect(Rect2(il, it, ir - il, 1), WALL_EDGE)

	if doors.get("down", false):
		_c.draw_rect(Rect2(il, ib - 1, DOOR_CENTER_X - hd - il, 1), WALL_EDGE)
		_c.draw_rect(Rect2(DOOR_CENTER_X + hd, ib - 1, ir - DOOR_CENTER_X - hd, 1), WALL_EDGE)
	else:
		_c.draw_rect(Rect2(il, ib - 1, ir - il, 1), WALL_EDGE)

	if doors.get("left", false):
		_c.draw_rect(Rect2(il, it, 1, DOOR_CENTER_Y - hd - it), WALL_EDGE)
		_c.draw_rect(Rect2(il, DOOR_CENTER_Y + hd, 1, ib - DOOR_CENTER_Y - hd), WALL_EDGE)
	else:
		_c.draw_rect(Rect2(il, it, 1, ib - it), WALL_EDGE)

	if doors.get("right", false):
		_c.draw_rect(Rect2(ir - 1, it, 1, DOOR_CENTER_Y - hd - it), WALL_EDGE)
		_c.draw_rect(Rect2(ir - 1, DOOR_CENTER_Y + hd, 1, ib - DOOR_CENTER_Y - hd), WALL_EDGE)
	else:
		_c.draw_rect(Rect2(ir - 1, it, 1, ib - it), WALL_EDGE)


func _draw_torches(il: float, ir: float) -> void:
	var hd := DOOR_WIDTH / 2.0
	var ty1 := ROOM_TOP + (ROOM_BOTTOM - ROOM_TOP) * 0.3
	var ty2 := ROOM_TOP + (ROOM_BOTTOM - ROOM_TOP) * 0.7
	var dt := DOOR_CENTER_Y - hd
	var db := DOOR_CENTER_Y + hd

	var has_left := doors.get("left", false)
	var has_right := doors.get("right", false)

	# Left wall torches
	if not has_left or ty1 < dt - 8 or ty1 > db + 6:
		_torch(il, ty1, true)
	if not has_left or ty2 < dt - 8 or ty2 > db + 6:
		_torch(il, ty2, true)

	# Right wall torches
	if not has_right or ty1 < dt - 8 or ty1 > db + 6:
		_torch(ir - 1, ty1, false)
	if not has_right or ty2 < dt - 8 or ty2 > db + 6:
		_torch(ir - 1, ty2, false)


func _torch(wx: float, wy: float, right: bool) -> void:
	if right:
		_c.draw_rect(Rect2(wx, wy, 3, 5), TORCH_BRACKET)
		_c.draw_rect(Rect2(wx + 1, wy - 2, 2, 2), TORCH_FLAME)
		_c.draw_rect(Rect2(wx + 1, wy - 3, 1, 1), TORCH_TIP)
	else:
		_c.draw_rect(Rect2(wx - 2, wy, 3, 5), TORCH_BRACKET)
		_c.draw_rect(Rect2(wx - 2, wy - 2, 2, 2), TORCH_FLAME)
		_c.draw_rect(Rect2(wx - 1, wy - 3, 1, 1), TORCH_TIP)


func _draw_torch_glow(il: float, ir: float) -> void:
	var hd := DOOR_WIDTH / 2.0
	var ty1 := ROOM_TOP + (ROOM_BOTTOM - ROOM_TOP) * 0.3
	var ty2 := ROOM_TOP + (ROOM_BOTTOM - ROOM_TOP) * 0.7
	var dt := DOOR_CENTER_Y - hd
	var db := DOOR_CENTER_Y + hd

	var has_left := doors.get("left", false)
	var has_right := doors.get("right", false)

	if not has_left or ty1 < dt - 8 or ty1 > db + 6:
		_glow(il + 2, ty1 + 1)
	if not has_left or ty2 < dt - 8 or ty2 > db + 6:
		_glow(il + 2, ty2 + 1)
	if not has_right or ty1 < dt - 8 or ty1 > db + 6:
		_glow(ir - 3, ty1 + 1)
	if not has_right or ty2 < dt - 8 or ty2 > db + 6:
		_glow(ir - 3, ty2 + 1)


func _glow(gx: float, gy: float) -> void:
	_c.draw_rect(Rect2(gx - 10, gy - 6, 20, 14), TORCH_GLOW_B)
	_c.draw_rect(Rect2(gx - 5, gy - 3, 10, 8), TORCH_GLOW_A)


func _draw_floor_details(il: float, ir: float, it: float, ib: float) -> void:
	var crack := Color(0.08, 0.07, 0.11)
	var pebble := Color(0.16, 0.14, 0.20)

	# Cracks — short dark lines scattered on the floor
	var cracks := [
		Vector2(il + 30, it + 15), Vector2(il + 80, it + 40),
		Vector2(il + 150, it + 20), Vector2(il + 200, it + 55),
		Vector2(il + 50, it + 70), Vector2(il + 120, it + 85),
		Vector2(il + 180, it + 30), Vector2(il + 240, it + 60),
	]
	for i in range(cracks.size()):
		var p := cracks[i]
		if p.x < ir - 4 and p.y < ib - 4:
			if i % 2 == 0:
				_c.draw_rect(Rect2(p.x, p.y, 3, 1), crack)
			else:
				_c.draw_rect(Rect2(p.x, p.y, 1, 3), crack)

	# Pebbles — tiny bright dots
	var pebbles := [
		Vector2(il + 20, it + 10), Vector2(il + 100, it + 50),
		Vector2(il + 60, it + 80), Vector2(il + 170, it + 25),
		Vector2(il + 220, it + 70), Vector2(il + 140, it + 95),
	]
	for p in pebbles:
		if p.x < ir - 2 and p.y < ib - 2:
			_c.draw_rect(Rect2(p.x, p.y, 1, 1), pebble)


func _draw_room_icon(il: float, ir: float, it: float, ib: float) -> void:
	var cx := (il + ir) / 2.0
	var cy := (it + ib) / 2.0

	if room_type == 2:  # TREASURE
		_c.draw_rect(Rect2(cx - 3, cy - 1, 7, 2), Color(0.60, 0.38, 0.18))
		_c.draw_rect(Rect2(cx - 3, cy + 1, 7, 3), Color(0.50, 0.30, 0.12))
		_c.draw_rect(Rect2(cx, cy, 1, 2), Color(1.0, 0.85, 0.2))

	elif room_type == 5:  # INGREDIENT
		_c.draw_rect(Rect2(cx - 2, cy + 1, 5, 2), Color(0.4, 0.38, 0.45))
		_c.draw_rect(Rect2(cx - 1, cy - 1, 3, 2), Color(0.4, 0.38, 0.45))
		_c.draw_rect(Rect2(cx, cy - 2, 1, 1), Color(0.3, 0.85, 1.0))

	elif room_type == 4:  # BOSS
		_c.draw_rect(Rect2(cx - 2, cy - 3, 5, 1), Color(0.85, 0.82, 0.75))
		_c.draw_rect(Rect2(cx - 3, cy - 2, 7, 3), Color(0.85, 0.82, 0.75))
		_c.draw_rect(Rect2(cx - 2, cy + 1, 5, 1), Color(0.85, 0.82, 0.75))
		_c.draw_rect(Rect2(cx - 2, cy - 1, 2, 2), Color(0.15, 0.05, 0.05))
		_c.draw_rect(Rect2(cx + 1, cy - 1, 2, 2), Color(0.15, 0.05, 0.05))
		_c.draw_rect(Rect2(cx - 2, cy + 2, 5, 1), Color(0.85, 0.82, 0.75))

	elif room_type == 3:  # EMPTY — cobwebs in corners
		var web := Color(0.25, 0.24, 0.30, 0.5)
		_c.draw_rect(Rect2(il + 1, it + 1, 3, 1), web)
		_c.draw_rect(Rect2(il + 1, it + 1, 1, 3), web)
		_c.draw_rect(Rect2(ir - 4, it + 1, 3, 1), web)
		_c.draw_rect(Rect2(ir - 2, it + 1, 1, 3), web)
		_c.draw_rect(Rect2(il + 1, ib - 2, 3, 1), web)
		_c.draw_rect(Rect2(il + 1, ib - 4, 1, 3), web)

	elif room_type == 0:  # START — diamond marker
		var mark := Color(0.3, 0.5, 0.3, 0.5)
		_c.draw_rect(Rect2(cx, cy - 2, 1, 1), mark)
		_c.draw_rect(Rect2(cx - 2, cy, 1, 1), mark)
		_c.draw_rect(Rect2(cx + 2, cy, 1, 1), mark)
		_c.draw_rect(Rect2(cx, cy + 2, 1, 1), mark)
