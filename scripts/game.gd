extends Node2D
## Main game scene -- where gameplay happens!
##
## The Player node is an instanced sub-scene (player.tscn) that handles
## its own setup -- it reads the character choice and name from SceneTree
## metadata automatically in its _ready() function.
##
## Key concept: **scene instancing**.
## The Player is a separate scene (player.tscn) placed inside this scene.
## This is how real games work -- you build small, reusable pieces (player,
## enemies, items) as their own scenes, then combine them in a level scene.

## The darkness overlay -- only created when the recipe has darkness=true.
## It draws a big black rectangle over the whole screen with a circle
## "cut out" around the player, like a spotlight.  This makes it hard
## to see enemies coming from far away!
var _darkness_overlay: Node2D = null

## The radius of the spotlight circle (in viewport pixels).
## Bigger = easier to see.  40px gives you a small area of visibility.
const SPOTLIGHT_RADIUS: float = 40.0

## How often the torches flicker (seconds between redraws).
## 0.15s gives a choppy, pixel-art style flicker -- fast enough to
## feel alive, slow enough to not look like a strobe light.
const FLICKER_INTERVAL: float = 0.15

## Countdown timer for the next torch flicker redraw.
var _flicker_timer: float = 0.0


func _ready() -> void:
	# Force a draw call so _draw() runs on the first frame
	queue_redraw()

	# If the recipe includes the "eternal_night" ingredient, we create
	# a darkness overlay that follows the player around with a spotlight.
	var recipe: Dictionary = get_tree().get_meta("dungeon_recipe", {})
	if recipe.get("darkness", false):
		_create_darkness_overlay()


func _draw() -> void:
	# Draw the dungeon room directly on this Game node.
	#
	# Key concept: **_draw() only works on SELF**.
	# In Godot, draw_rect() and other draw methods MUST be called
	# on the same node whose _draw() is running.  You can't pass
	# "self" to another script and have it call draw_rect() on you --
	# Godot silently ignores those calls!
	# So all room drawing lives here, and we just READ the room state
	# from DungeonManager to know what to draw.
	if has_node("DungeonManager"):
		_draw_room()


## Draws the current dungeon room -- walls, floor, doors, torches, decorations.
##
## Key concept: **separation of data and rendering**.
## DungeonManager handles the GAME LOGIC (which room, door states, enemies).
## This method handles the VISUALS (drawing rectangles for walls, floors, etc).
## We read DungeonManager's variables with .get() to know what to draw,
## but all the actual draw_rect() calls happen here on the Game node --
## because that's how Godot's _draw() system works.
##
## Why .get() instead of .property?  Because $DungeonManager is typed as
## a plain "Node" (it has no class_name), and GDScript might reject
## accessing custom properties on a Node at compile time.  .get() is a
## method on Object that works for ANY property by name -- always safe!
func _draw_room() -> void:
	# Read the current room state from DungeonManager
	var room_doors: Dictionary = $DungeonManager.get("_room_doors")
	var room_locked: bool = $DungeonManager.get("_room_locked")
	var room_type: int = $DungeonManager.get("_room_type")

	# -- Room geometry constants --
	# These define where the room's walls, floor, and doors are drawn.
	# RL/RR/RT/RB = outer wall edges.  il/ir/it/ib = inner floor edges.
	# The 8px gap between outer and inner is the wall thickness.
	var RL := 8.0     # room left (outer wall edge)
	var RR := 312.0   # room right
	var RT := 28.0    # room top
	var RB := 166.0   # room bottom
	var W := 8.0      # wall thickness
	var DW := 32.0    # door width
	var DCX := 160.0  # door center X
	var DCY := 97.0   # door center Y
	var hd := DW / 2.0   # half door width (16px)
	var il := RL + W      # inner left (play area starts here)
	var ir := RR - W      # inner right
	var it := RT + W      # inner top
	var ib := RB - W      # inner bottom

	# -- Colors --
	# Purple-grey stone walls with lighter edges for depth.
	# Dark floor tiles, brown door frames, warm torch colors.
	var WALL_COL := Color(0.45, 0.38, 0.60)
	var WALL_EDGE_COL := Color(0.60, 0.52, 0.75)
	var WALL_OUTER_COL := Color(0.30, 0.25, 0.42)
	var MORTAR_COL := Color(0.28, 0.22, 0.38)
	var DOOR_FRAME_COL := Color(0.75, 0.70, 0.90)
	var FLOOR_A := Color(0.14, 0.12, 0.20)
	var FLOOR_B := Color(0.18, 0.15, 0.24)
	var BRACKET := Color(0.45, 0.30, 0.15)
	var FLAME := Color(1.0, 0.75, 0.2)
	var TIP := Color(1.0, 0.95, 0.6)
	var GLOW_A := Color(1.0, 0.6, 0.1, 0.12)
	var GLOW_B := Color(1.0, 0.5, 0.0, 0.06)
	# Door fill color: brown when locked (enemies alive), near-black when open
	var dc: Color
	if room_locked:
		dc = Color(0.60, 0.35, 0.18)
	else:
		dc = Color(0.06, 0.05, 0.10)

	# -- Dark void (background behind the room) --
	# Everything outside the room walls is near-black void.
	draw_rect(Rect2(0, 0, 320, 180), Color(0.03, 0.03, 0.08))

	# -- Floor checkerboard --
	# 8x8 pixel tiles in alternating dark colors, like stone bricks.
	# We use modulo (%) to alternate: even tiles get FLOOR_A, odd get FLOOR_B.
	var tile := 8.0
	var fx := il
	while fx < ir:
		var fy := it
		while fy < ib:
			var even: bool = (int(fx / tile) + int(fy / tile)) % 2 == 0
			var col: Color = FLOOR_A if even else FLOOR_B
			draw_rect(Rect2(fx, fy, minf(tile, ir - fx), minf(tile, ib - fy)), col)
			fy += tile
		fx += tile

	# -- Floor details (cracks + pebbles) --
	# Small dark lines and dots scattered on the floor to break up
	# the checkerboard pattern and make it feel more like worn stone.
	var crack := Color(0.08, 0.07, 0.11)
	var pebble := Color(0.16, 0.14, 0.20)
	var crack_positions := [
		Vector2(il + 30, it + 15), Vector2(il + 80, it + 40),
		Vector2(il + 150, it + 20), Vector2(il + 200, it + 55),
		Vector2(il + 50, it + 70), Vector2(il + 120, it + 85),
		Vector2(il + 180, it + 30), Vector2(il + 240, it + 60),
	]
	for ci in range(crack_positions.size()):
		var cp: Vector2 = crack_positions[ci]
		if cp.x < ir - 4 and cp.y < ib - 4:
			if ci % 2 == 0:
				draw_rect(Rect2(cp.x, cp.y, 3, 1), crack)  # horizontal crack
			else:
				draw_rect(Rect2(cp.x, cp.y, 1, 3), crack)  # vertical crack
	var pebble_positions := [
		Vector2(il + 20, it + 10), Vector2(il + 100, it + 50),
		Vector2(il + 60, it + 80), Vector2(il + 170, it + 25),
		Vector2(il + 220, it + 70), Vector2(il + 140, it + 95),
	]
	for pp in pebble_positions:
		var ppv: Vector2 = pp
		if ppv.x < ir - 2 and ppv.y < ib - 2:
			draw_rect(Rect2(ppv.x, ppv.y, 1, 1), pebble)

	# -- Torch glow on floor --
	# Semi-transparent warm rectangles near torch positions create
	# the illusion of flickering light on the stone floor.
	# Drawn BEFORE walls so the wall edges clip the glow naturally.
	var ty1 := RT + (RB - RT) * 0.3   # torch Y position 1 (upper)
	var ty2 := RT + (RB - RT) * 0.7   # torch Y position 2 (lower)
	var dt := DCY - hd   # door top edge
	var db := DCY + hd   # door bottom edge
	var has_left: bool = room_doors.get("left", false)
	var has_right: bool = room_doors.get("right", false)
	# Only draw glow if the torch wouldn't overlap with a door opening.
	# Each glow has 3 layers: a faint outer ring, a medium middle, and
	# a brighter inner core.  Stacking semi-transparent rectangles like
	# this creates a soft gradient effect even though we're only using
	# flat rectangles -- the overlapping alpha values add up!
	var GLOW_C := Color(1.0, 0.45, 0.0, 0.03)  # outermost, very faint
	# Glow is centered on the flame position: il+3 for left, ir-4 for right
	if not has_left or ty1 < dt - 8 or ty1 > db + 6:
		draw_rect(Rect2(il + 3 - 18, ty1 - 12, 36, 24), GLOW_C)
		draw_rect(Rect2(il + 3 - 12, ty1 - 8, 24, 16), GLOW_B)
		draw_rect(Rect2(il + 3 - 6, ty1 - 4, 12, 10), GLOW_A)
	if not has_left or ty2 < dt - 8 or ty2 > db + 6:
		draw_rect(Rect2(il + 3 - 18, ty2 - 12, 36, 24), GLOW_C)
		draw_rect(Rect2(il + 3 - 12, ty2 - 8, 24, 16), GLOW_B)
		draw_rect(Rect2(il + 3 - 6, ty2 - 4, 12, 10), GLOW_A)
	if not has_right or ty1 < dt - 8 or ty1 > db + 6:
		draw_rect(Rect2(ir - 4 - 18, ty1 - 12, 36, 24), GLOW_C)
		draw_rect(Rect2(ir - 4 - 12, ty1 - 8, 24, 16), GLOW_B)
		draw_rect(Rect2(ir - 4 - 6, ty1 - 4, 12, 10), GLOW_A)
	if not has_right or ty2 < dt - 8 or ty2 > db + 6:
		draw_rect(Rect2(ir - 4 - 18, ty2 - 12, 36, 24), GLOW_C)
		draw_rect(Rect2(ir - 4 - 12, ty2 - 8, 24, 16), GLOW_B)
		draw_rect(Rect2(ir - 4 - 6, ty2 - 4, 12, 10), GLOW_A)

	# -- Walls --
	# Each wall is a solid rectangle.  If there's a door on that side,
	# we split the wall into two pieces with the door gap between them.
	# Door frames (bright accent lines) mark where the opening is.

	# Top wall
	if room_doors.get("up", false):
		draw_rect(Rect2(RL, RT, DCX - hd - RL, W), WALL_COL)
		draw_rect(Rect2(DCX + hd, RT, RR - DCX - hd, W), WALL_COL)
		draw_rect(Rect2(DCX - hd, RT, DW, W), dc)  # door fill
		draw_rect(Rect2(DCX - hd - 2, RT, 2, W), DOOR_FRAME_COL)
		draw_rect(Rect2(DCX + hd, RT, 2, W), DOOR_FRAME_COL)
	else:
		draw_rect(Rect2(RL, RT, RR - RL, W), WALL_COL)

	# Bottom wall
	if room_doors.get("down", false):
		draw_rect(Rect2(RL, ib, DCX - hd - RL, W), WALL_COL)
		draw_rect(Rect2(DCX + hd, ib, RR - DCX - hd, W), WALL_COL)
		draw_rect(Rect2(DCX - hd, ib, DW, W), dc)
		draw_rect(Rect2(DCX - hd - 2, ib, 2, W), DOOR_FRAME_COL)
		draw_rect(Rect2(DCX + hd, ib, 2, W), DOOR_FRAME_COL)
	else:
		draw_rect(Rect2(RL, ib, RR - RL, W), WALL_COL)

	# Left wall
	if room_doors.get("left", false):
		draw_rect(Rect2(RL, RT, W, DCY - hd - RT), WALL_COL)
		draw_rect(Rect2(RL, DCY + hd, W, RB - DCY - hd), WALL_COL)
		draw_rect(Rect2(RL, DCY - hd, W, DW), dc)
		draw_rect(Rect2(RL, DCY - hd - 2, W, 2), DOOR_FRAME_COL)
		draw_rect(Rect2(RL, DCY + hd, W, 2), DOOR_FRAME_COL)
	else:
		draw_rect(Rect2(RL, RT, W, RB - RT), WALL_COL)

	# Right wall
	if room_doors.get("right", false):
		draw_rect(Rect2(ir, RT, W, DCY - hd - RT), WALL_COL)
		draw_rect(Rect2(ir, DCY + hd, W, RB - DCY - hd), WALL_COL)
		draw_rect(Rect2(ir, DCY - hd, W, DW), dc)
		draw_rect(Rect2(ir, DCY - hd - 2, W, 2), DOOR_FRAME_COL)
		draw_rect(Rect2(ir, DCY + hd, W, 2), DOOR_FRAME_COL)
	else:
		draw_rect(Rect2(ir, RT, W, RB - RT), WALL_COL)

	# -- Mortar lines --
	# Thin dark lines across each wall to suggest stone brickwork.
	# These are subtle but add a lot of texture to the walls.
	var my := RT + 4
	if room_doors.get("up", false):
		draw_rect(Rect2(RL + 1, my, DCX - hd - RL - 1, 1), MORTAR_COL)
		draw_rect(Rect2(DCX + hd, my, RR - DCX - hd - 1, 1), MORTAR_COL)
	else:
		draw_rect(Rect2(RL + 1, my, RR - RL - 2, 1), MORTAR_COL)
	my = RB - W + 4
	if room_doors.get("down", false):
		draw_rect(Rect2(RL + 1, my, DCX - hd - RL - 1, 1), MORTAR_COL)
		draw_rect(Rect2(DCX + hd, my, RR - DCX - hd - 1, 1), MORTAR_COL)
	else:
		draw_rect(Rect2(RL + 1, my, RR - RL - 2, 1), MORTAR_COL)
	var mx := RL + 4
	if room_doors.get("left", false):
		draw_rect(Rect2(mx, RT + 1, 1, DCY - hd - RT - 1), MORTAR_COL)
		draw_rect(Rect2(mx, DCY + hd, 1, RB - DCY - hd - 1), MORTAR_COL)
	else:
		draw_rect(Rect2(mx, RT + 1, 1, RB - RT - 2), MORTAR_COL)
	mx = RR - W + 4
	if room_doors.get("right", false):
		draw_rect(Rect2(mx, RT + 1, 1, DCY - hd - RT - 1), MORTAR_COL)
		draw_rect(Rect2(mx, DCY + hd, 1, RB - DCY - hd - 1), MORTAR_COL)
	else:
		draw_rect(Rect2(mx, RT + 1, 1, RB - RT - 2), MORTAR_COL)

	# -- Inner edge highlights --
	# Bright lines along the inside edge of each wall to give depth.
	# Makes the walls look 3D -- like the floor is recessed below them.
	if room_doors.get("up", false):
		draw_rect(Rect2(il, it, DCX - hd - il, 1), WALL_EDGE_COL)
		draw_rect(Rect2(DCX + hd, it, ir - DCX - hd, 1), WALL_EDGE_COL)
	else:
		draw_rect(Rect2(il, it, ir - il, 1), WALL_EDGE_COL)
	if room_doors.get("down", false):
		draw_rect(Rect2(il, ib - 1, DCX - hd - il, 1), WALL_EDGE_COL)
		draw_rect(Rect2(DCX + hd, ib - 1, ir - DCX - hd, 1), WALL_EDGE_COL)
	else:
		draw_rect(Rect2(il, ib - 1, ir - il, 1), WALL_EDGE_COL)
	if room_doors.get("left", false):
		draw_rect(Rect2(il, it, 1, DCY - hd - it), WALL_EDGE_COL)
		draw_rect(Rect2(il, DCY + hd, 1, ib - DCY - hd), WALL_EDGE_COL)
	else:
		draw_rect(Rect2(il, it, 1, ib - it), WALL_EDGE_COL)
	if room_doors.get("right", false):
		draw_rect(Rect2(ir - 1, it, 1, DCY - hd - it), WALL_EDGE_COL)
		draw_rect(Rect2(ir - 1, DCY + hd, 1, ib - DCY - hd), WALL_EDGE_COL)
	else:
		draw_rect(Rect2(ir - 1, it, 1, ib - it), WALL_EDGE_COL)

	# Outer edge -- dark border around the whole room
	draw_rect(Rect2(RL, RT, RR - RL, 1), WALL_OUTER_COL)
	draw_rect(Rect2(RL, RB - 1, RR - RL, 1), WALL_OUTER_COL)
	draw_rect(Rect2(RL, RT, 1, RB - RT), WALL_OUTER_COL)
	draw_rect(Rect2(RR - 1, RT, 1, RB - RT), WALL_OUTER_COL)

	# -- Torches --
	# Upgraded wall-mounted torches!  Each torch has:
	#   1. A metal bracket (arm sticking out of the wall + cup on top)
	#   2. A multi-layered flame (dark red base -> orange -> yellow -> white tip)
	#   3. The flame shape randomly changes each flicker tick
	#   4. Tiny ember sparks floating upward
	#
	# Key concept: **building detail from simple pieces**.
	# Even though we can only draw rectangles, stacking small 1-2px
	# rectangles in different colors creates the illusion of a detailed,
	# organic flame.  Each layer is a different temperature of fire:
	# red (coolest) -> orange -> yellow -> white (hottest).

	# Which torches are visible (not blocked by doors)
	var show_l1: bool = not has_left or ty1 < dt - 8 or ty1 > db + 6
	var show_l2: bool = not has_left or ty2 < dt - 8 or ty2 > db + 6
	var show_r1: bool = not has_right or ty1 < dt - 8 or ty1 > db + 6
	var show_r2: bool = not has_right or ty2 < dt - 8 or ty2 > db + 6

	# Store torch info: [anchor_x, anchor_y, is_left_wall]
	# anchor = where the bracket meets the wall.  is_left_wall tells us
	# which direction the bracket sticks out.
	var torch_data := []
	if show_l1:
		torch_data.append([il, ty1, true])
	if show_l2:
		torch_data.append([il, ty2, true])
	if show_r1:
		torch_data.append([ir, ty1, false])
	if show_r2:
		torch_data.append([ir, ty2, false])

	# Bracket colors -- iron grey with a highlight
	var IRON := Color(0.35, 0.30, 0.28)
	var IRON_HI := Color(0.50, 0.45, 0.42)
	var IRON_DK := Color(0.22, 0.18, 0.16)

	for t in torch_data:
		var ax: float = t[0]  # anchor x (wall edge)
		var ay: float = t[1]  # anchor y (vertical center)
		var left: bool = t[2] # is this on the left wall?

		# -- BRACKET --
		# The bracket is an iron arm sticking out of the wall with a
		# small cup on top to hold the fire.
		if left:
			# Arm: horizontal bar coming out of the wall (3px wide, 1px tall)
			draw_rect(Rect2(ax, ay + 2, 4, 1), IRON)
			# Highlight on top edge of arm
			draw_rect(Rect2(ax + 1, ay + 1, 3, 1), IRON_HI)
			# Cup: a small U-shape to hold the flame
			draw_rect(Rect2(ax + 2, ay - 1, 1, 3), IRON)     # left side of cup
			draw_rect(Rect2(ax + 4, ay - 1, 1, 3), IRON)     # right side of cup
			draw_rect(Rect2(ax + 2, ay + 1, 3, 1), IRON_DK)  # bottom of cup
			# Wall mount plate (where it attaches to wall)
			draw_rect(Rect2(ax, ay, 1, 4), IRON_HI)

			# -- FLAME --
			# cx/cy = center of the cup opening, where the flame starts
			var cx: float = ax + 3
			var cy: float = ay - 1

			# Randomly decide the flame height this tick (3 to 5 pixels tall).
			# This makes the flame look like it's dancing up and down.
			var flame_h: int = randi_range(3, 5)

			# Also randomly lean left or right by 0 or 1 pixel.
			# Real flames sway side to side!
			var lean: int = randi_range(-1, 1)

			# Layer 1: dark red base (coolest part of the fire)
			var red_base := Color(
				randf_range(0.7, 0.85),
				randf_range(0.15, 0.3),
				randf_range(0.0, 0.1),
			)
			draw_rect(Rect2(cx - 1, cy, 3, 1), red_base)

			# Layer 2: orange middle
			var orange_mid := Color(
				randf_range(0.9, 1.0),
				randf_range(0.45, 0.65),
				randf_range(0.0, 0.15),
			)
			draw_rect(Rect2(cx - 1 + lean, cy - 1, 2, 1), orange_mid)
			if flame_h >= 4:
				draw_rect(Rect2(cx + lean, cy - 2, 2, 1), orange_mid)

			# Layer 3: bright yellow core
			var yellow_core := Color(
				randf_range(0.95, 1.0),
				randf_range(0.75, 0.95),
				randf_range(0.1, 0.3),
			)
			var tip_y: float = cy - flame_h + 1
			draw_rect(Rect2(cx + lean, tip_y + 1, 1, 1), yellow_core)

			# Layer 4: white-hot tip (hottest point)
			var white_tip := Color(
				1.0,
				randf_range(0.9, 1.0),
				randf_range(0.5, 0.85),
			)
			draw_rect(Rect2(cx + lean, tip_y, 1, 1), white_tip)

			# -- EMBERS --
			# 1-2 tiny sparks floating above the flame.  Each spark is
			# a single pixel at a random position above the tip.
			# They appear and disappear each flicker tick, creating the
			# illusion of sparks flying off the fire.
			var num_embers: int = randi_range(1, 2)
			for _e in num_embers:
				var ex: float = cx + randf_range(-2, 3)
				var ey: float = tip_y + randf_range(-4, -1)
				# Only draw if the ember is inside the room
				if ey > it and ex > il and ex < ir:
					var ember_col := Color(
						1.0,
						randf_range(0.4, 0.8),
						randf_range(0.0, 0.2),
						randf_range(0.4, 0.9),
					)
					draw_rect(Rect2(ex, ey, 1, 1), ember_col)

		else:
			# RIGHT WALL -- mirror of the left wall bracket.
			# ax here is the inner right edge (ir), so we draw leftward.
			draw_rect(Rect2(ax - 4, ay + 2, 4, 1), IRON)
			draw_rect(Rect2(ax - 4, ay + 1, 3, 1), IRON_HI)
			draw_rect(Rect2(ax - 5, ay - 1, 1, 3), IRON)
			draw_rect(Rect2(ax - 3, ay - 1, 1, 3), IRON)
			draw_rect(Rect2(ax - 5, ay + 1, 3, 1), IRON_DK)
			draw_rect(Rect2(ax - 1, ay, 1, 4), IRON_HI)

			var cx: float = ax - 4
			var cy: float = ay - 1

			var flame_h: int = randi_range(3, 5)
			var lean: int = randi_range(-1, 1)

			var red_base := Color(
				randf_range(0.7, 0.85),
				randf_range(0.15, 0.3),
				randf_range(0.0, 0.1),
			)
			draw_rect(Rect2(cx - 1, cy, 3, 1), red_base)

			var orange_mid := Color(
				randf_range(0.9, 1.0),
				randf_range(0.45, 0.65),
				randf_range(0.0, 0.15),
			)
			draw_rect(Rect2(cx - 1 + lean, cy - 1, 2, 1), orange_mid)
			if flame_h >= 4:
				draw_rect(Rect2(cx + lean, cy - 2, 2, 1), orange_mid)

			var yellow_core := Color(
				randf_range(0.95, 1.0),
				randf_range(0.75, 0.95),
				randf_range(0.1, 0.3),
			)
			var tip_y: float = cy - flame_h + 1
			draw_rect(Rect2(cx + lean, tip_y + 1, 1, 1), yellow_core)

			var white_tip := Color(
				1.0,
				randf_range(0.9, 1.0),
				randf_range(0.5, 0.85),
			)
			draw_rect(Rect2(cx + lean, tip_y, 1, 1), white_tip)

			var num_embers: int = randi_range(1, 2)
			for _e in num_embers:
				var ex: float = cx + randf_range(-3, 2)
				var ey: float = tip_y + randf_range(-4, -1)
				if ey > it and ex > il and ex < ir:
					var ember_col := Color(
						1.0,
						randf_range(0.4, 0.8),
						randf_range(0.0, 0.2),
						randf_range(0.4, 0.9),
					)
					draw_rect(Rect2(ex, ey, 1, 1), ember_col)

	# Randomize glow intensity too -- the warm glow on the floor
	# changes strength each flicker tick, making the light feel alive.
	# We redraw the glow on top of what was already drawn; the semi-transparent
	# colors blend naturally.  Same 3-layer structure as the static glow,
	# but with randomized alpha so the brightness pulses.
	var glow_var := randf_range(0.7, 1.3)
	var GLOW_A_F := Color(1.0, 0.6, 0.1, 0.12 * glow_var)
	var GLOW_B_F := Color(1.0, 0.5, 0.0, 0.06 * glow_var)
	var GLOW_C_F := Color(1.0, 0.45, 0.0, 0.03 * glow_var)
	if show_l1:
		draw_rect(Rect2(il + 3 - 18, ty1 - 12, 36, 24), GLOW_C_F)
		draw_rect(Rect2(il + 3 - 12, ty1 - 8, 24, 16), GLOW_B_F)
		draw_rect(Rect2(il + 3 - 6, ty1 - 4, 12, 10), GLOW_A_F)
	if show_l2:
		draw_rect(Rect2(il + 3 - 18, ty2 - 12, 36, 24), GLOW_C_F)
		draw_rect(Rect2(il + 3 - 12, ty2 - 8, 24, 16), GLOW_B_F)
		draw_rect(Rect2(il + 3 - 6, ty2 - 4, 12, 10), GLOW_A_F)
	if show_r1:
		draw_rect(Rect2(ir - 4 - 18, ty1 - 12, 36, 24), GLOW_C_F)
		draw_rect(Rect2(ir - 4 - 12, ty1 - 8, 24, 16), GLOW_B_F)
		draw_rect(Rect2(ir - 4 - 6, ty1 - 4, 12, 10), GLOW_A_F)
	if show_r2:
		draw_rect(Rect2(ir - 4 - 18, ty2 - 12, 36, 24), GLOW_C_F)
		draw_rect(Rect2(ir - 4 - 12, ty2 - 8, 24, 16), GLOW_B_F)
		draw_rect(Rect2(ir - 4 - 6, ty2 - 4, 12, 10), GLOW_A_F)

	# -- Room-type icons --
	# Small pixel-art icon in the center of the room to hint at
	# what kind of room this is.
	var cx := (il + ir) / 2.0
	var cy := (it + ib) / 2.0
	if room_type == 2:  # TREASURE -- chest icon
		draw_rect(Rect2(cx - 3, cy - 1, 7, 2), Color(0.60, 0.38, 0.18))
		draw_rect(Rect2(cx - 3, cy + 1, 7, 3), Color(0.50, 0.30, 0.12))
		draw_rect(Rect2(cx, cy, 1, 2), Color(1.0, 0.85, 0.2))
	elif room_type == 5:  # INGREDIENT -- pedestal icon
		draw_rect(Rect2(cx - 2, cy + 1, 5, 2), Color(0.4, 0.38, 0.45))
		draw_rect(Rect2(cx - 1, cy - 1, 3, 2), Color(0.4, 0.38, 0.45))
		draw_rect(Rect2(cx, cy - 2, 1, 1), Color(0.3, 0.85, 1.0))
	elif room_type == 4:  # BOSS -- skull icon
		draw_rect(Rect2(cx - 2, cy - 3, 5, 1), Color(0.85, 0.82, 0.75))
		draw_rect(Rect2(cx - 3, cy - 2, 7, 3), Color(0.85, 0.82, 0.75))
		draw_rect(Rect2(cx - 2, cy + 1, 5, 1), Color(0.85, 0.82, 0.75))
		draw_rect(Rect2(cx - 2, cy - 1, 2, 2), Color(0.15, 0.05, 0.05))
		draw_rect(Rect2(cx + 1, cy - 1, 2, 2), Color(0.15, 0.05, 0.05))
		draw_rect(Rect2(cx - 2, cy + 2, 5, 1), Color(0.85, 0.82, 0.75))
	elif room_type == 3:  # EMPTY -- cobwebs in corners
		var web := Color(0.25, 0.24, 0.30, 0.5)
		draw_rect(Rect2(il + 1, it + 1, 3, 1), web)
		draw_rect(Rect2(il + 1, it + 1, 1, 3), web)
		draw_rect(Rect2(ir - 4, it + 1, 3, 1), web)
		draw_rect(Rect2(ir - 2, it + 1, 1, 3), web)
		draw_rect(Rect2(il + 1, ib - 2, 3, 1), web)
		draw_rect(Rect2(il + 1, ib - 4, 1, 3), web)
	elif room_type == 0:  # START -- diamond marker
		var mark := Color(0.3, 0.5, 0.3, 0.5)
		draw_rect(Rect2(cx, cy - 2, 1, 1), mark)
		draw_rect(Rect2(cx - 2, cy, 1, 1), mark)
		draw_rect(Rect2(cx + 2, cy, 1, 1), mark)
		draw_rect(Rect2(cx, cy + 2, 1, 1), mark)


func _process(delta: float) -> void:
	# -- Torch flicker timer --
	# Every FLICKER_INTERVAL seconds, we call queue_redraw() which triggers
	# _draw() again.  Since the torch colors are randomized each draw (see
	# _draw_room), each redraw makes the flames look different -- that's
	# the flicker!  We only redraw on the timer tick, not every frame,
	# because choppy updates look more like real fire in pixel art.
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = FLICKER_INTERVAL
		queue_redraw()

	# Update the darkness overlay position to follow the player.
	if _darkness_overlay != null and has_node("Player"):
		_darkness_overlay.queue_redraw()


## Creates the darkness overlay as a CanvasLayer with a custom draw node.
##
## Key concept: **CanvasLayer for screen effects**.
## A CanvasLayer sits on top of the game world (like the HUD).  By drawing
## a big black rectangle with a transparent circle cut out, we create a
## "spotlight" effect -- you can only see the area right around the player!
func _create_darkness_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5  # Above game world but below HUD (layer 10+)
	_darkness_overlay = Node2D.new()
	_darkness_overlay.draw.connect(_on_darkness_draw)
	layer.add_child(_darkness_overlay)
	add_child(layer)


## Draws the darkness effect -- a black screen with a circular hole
## around the player's position.
##
## We draw horizontal strips of black rectangles, leaving a circular
## gap centered on the player.  For each row of pixels within the
## circle's Y range, we calculate the gap width using the circle
## equation: x = sqrt(r^2 - y^2)
func _on_darkness_draw() -> void:
	if not has_node("Player"):
		return
	var player_pos: Vector2 = $Player.global_position
	var vp_w: float = 320.0
	var vp_h: float = 180.0
	var r: float = SPOTLIGHT_RADIUS
	var spot_cx: float = player_pos.x
	var spot_cy: float = player_pos.y
	var black: Color = Color(0, 0, 0, 1)

	# Top section (fully black, above the circle)
	var circle_top: float = spot_cy - r
	if circle_top > 0:
		_darkness_overlay.draw_rect(Rect2(0, 0, vp_w, circle_top), black)

	# Bottom section (fully black, below the circle)
	var circle_bottom: float = spot_cy + r
	if circle_bottom < vp_h:
		_darkness_overlay.draw_rect(Rect2(0, circle_bottom, vp_w, vp_h - circle_bottom), black)

	# Middle section -- left and right strips with a circular gap.
	# We step 2px at a time for performance.
	var step: int = 2
	var y_start: int = maxi(0, int(circle_top))
	var y_end: int = mini(int(vp_h), int(circle_bottom))
	var sy: int = y_start
	while sy < y_end:
		# How far this row is from the circle center (vertically)
		var dy: float = float(sy) - spot_cy + 0.5
		# Horizontal half-width of the circle at this row
		var half_w: float = sqrt(maxf(0.0, r * r - dy * dy))
		var gap_left: float = spot_cx - half_w
		var gap_right: float = spot_cx + half_w
		var strip_h: float = float(mini(step, y_end - sy))
		# Draw left black strip (screen edge to circle edge)
		if gap_left > 0:
			_darkness_overlay.draw_rect(Rect2(0, sy, gap_left, strip_h), black)
		# Draw right black strip (circle edge to screen edge)
		if gap_right < vp_w:
			_darkness_overlay.draw_rect(Rect2(gap_right, sy, vp_w - gap_right, strip_h), black)
		sy += step


func _unhandled_input(event: InputEvent) -> void:
	# Don't process input while the chat console is open
	if has_node("ChatConsole") and $ChatConsole.is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		# If the dungeon is already complete (transitioning), ignore.
		if has_node("DungeonManager") and $DungeonManager.is_complete:
			return

		# Save inventory before returning to camp so nothing is lost.
		var player: Node2D = $Player
		get_tree().set_meta("player_inventory", player.inventory.duplicate(true))

		# Clear the dungeon recipe since the player is abandoning the run.
		if get_tree().has_meta("dungeon_recipe"):
			get_tree().remove_meta("dungeon_recipe")

		get_tree().change_scene_to_file("res://scenes/camp.tscn")
