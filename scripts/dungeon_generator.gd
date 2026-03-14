extends RefCounted
## Generates dungeon map layouts for the dungeon crawler.
##
## Key concept: **procedural generation with a grid**.
## Instead of hand-designing dungeon layouts, we grow them randomly
## from a starting point.  Each room sits on a grid (like graph paper),
## and we connect neighboring rooms with doors.
##
## The algorithm:
##   1. Place the start room at grid position (0, 0)
##   2. Pick a random existing room and try to add a neighbor
##   3. Repeat until we have enough rooms
##   4. Find the room furthest from start → that's the boss/goal
##   5. Sprinkle in treasure and empty rooms for variety
##
## This creates organic, branching layouts that feel different every run!

# ── Room type constants ──────────────────────────────────────────
## These integers identify what kind of room each cell is.
## Using constants instead of magic numbers makes the code readable:
##   if room.type == COMBAT   vs   if room.type == 1   ← which is clearer?
const START: int = 0
const COMBAT: int = 1
const TREASURE: int = 2
const EMPTY: int = 3
const BOSS: int = 4
const INGREDIENT: int = 5

# ── Direction helpers ────────────────────────────────────────────
## These two Dictionaries let us work with directions as data.
## DIR_VECTORS converts a direction name into a grid offset:
##   "up" → move 1 cell up on the grid (y decreases)
## OPPOSITES gives us the reverse direction:
##   "up" → "down" (if you walked up into a room, you came from below)
const DIR_VECTORS: Dictionary = {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}

const OPPOSITES: Dictionary = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left",
}


## Generates a complete dungeon layout.
##
## Returns a Dictionary with:
##   "rooms"     → Dictionary of Vector2i → room data
##   "start_pos" → Vector2i where the player begins
##   "goal_pos"  → Vector2i of the boss/final room
##
## Each room data Dictionary looks like:
##   { "type": int, "doors": {"up":bool, ...}, "cleared": bool, "explored": bool }
static func generate(total_rooms: int, has_boss: bool) -> Dictionary:
	# Make sure we have at least 2 rooms (start + 1 other)
	total_rooms = maxi(total_rooms, 2)

	var rooms: Dictionary = {}
	var start_pos := Vector2i(0, 0)

	# ── Create start room ─────────────────────────────────────
	rooms[start_pos] = _make_room(START, true, true)

	# ── Grow the dungeon ──────────────────────────────────────
	# "frontier" = rooms we can still expand from (they might have
	# empty neighbors).  We pick one at random and try to grow.
	var frontier: Array = [start_pos]

	while rooms.size() < total_rooms and not frontier.is_empty():
		# Pick a random room to expand from
		var from_pos: Vector2i = frontier[randi() % frontier.size()]

		# Shuffle directions so growth is unpredictable
		var dirs: Array = ["up", "down", "left", "right"]
		dirs.shuffle()

		var added: bool = false
		for dir in dirs:
			var new_pos: Vector2i = from_pos + DIR_VECTORS[dir]
			if rooms.has(new_pos):
				continue  # Already a room there — try another direction

			# Create new room and connect doors in BOTH rooms
			rooms[new_pos] = _make_room(COMBAT, false, false)
			rooms[from_pos]["doors"][dir] = true
			rooms[new_pos]["doors"][OPPOSITES[dir]] = true

			frontier.append(new_pos)
			added = true
			break

		# If no empty neighbors left, this room can't expand anymore
		if not added:
			frontier.erase(from_pos)

	# ── Add some extra connections (loops) ────────────────────
	# Without this, the dungeon is a tree (only one path between
	# any two rooms).  Adding occasional extra doors creates loops,
	# giving the player alternate routes.  ~20% chance per eligible pair.
	for pos in rooms:
		for dir in DIR_VECTORS:
			var neighbor: Vector2i = pos + DIR_VECTORS[dir]
			if rooms.has(neighbor) and not rooms[pos]["doors"][dir]:
				if randf() < 0.2:
					rooms[pos]["doors"][dir] = true
					rooms[neighbor]["doors"][OPPOSITES[dir]] = true

	# ── Place boss/goal at the furthest room from start ───────
	var goal_pos: Vector2i = _find_furthest(rooms, start_pos)
	if has_boss:
		rooms[goal_pos]["type"] = BOSS
	# (If no boss, the goal room stays COMBAT — clearing it wins)

	# ── Assign variety to remaining rooms ─────────────────────
	_assign_types(rooms, start_pos, goal_pos)

	return {
		"rooms": rooms,
		"start_pos": start_pos,
		"goal_pos": goal_pos,
	}


## Creates a single room data Dictionary with default values.
static func _make_room(type: int, cleared: bool, explored: bool) -> Dictionary:
	return {
		"type": type,
		"doors": {"up": false, "down": false, "left": false, "right": false},
		"cleared": cleared,
		"explored": explored,
	}


## Uses BFS (breadth-first search) to find the room furthest from start.
##
## Key concept: **BFS for shortest paths**.
## BFS explores rooms in order of distance — first all rooms 1 step away,
## then 2 steps, then 3, etc.  The LAST room it visits is the furthest.
## This guarantees the boss room requires the most exploration to reach!
static func _find_furthest(rooms: Dictionary, start: Vector2i) -> Vector2i:
	var visited: Dictionary = {start: true}
	var queue: Array = [[start, 0]]
	var best_pos: Vector2i = start
	var best_dist: int = 0

	while not queue.is_empty():
		var entry: Array = queue.pop_front()
		var pos: Vector2i = entry[0]
		var dist: int = entry[1]

		if dist > best_dist:
			best_dist = dist
			best_pos = pos

		var room: Dictionary = rooms[pos]
		for dir in room["doors"]:
			if room["doors"][dir]:
				var n: Vector2i = pos + DIR_VECTORS[dir]
				if not visited.has(n):
					visited[n] = true
					queue.append([n, dist + 1])

	return best_pos


## Assigns TREASURE and EMPTY types to rooms that aren't START or BOSS.
## ~20% become treasure rooms, ~15% become empty, the rest stay combat.
static func _assign_types(rooms: Dictionary, start: Vector2i, goal: Vector2i) -> void:
	var assignable: Array = []
	for pos in rooms:
		if pos != start and pos != goal:
			assignable.append(pos)

	assignable.shuffle()

	for i in range(assignable.size()):
		var roll: float = randf()
		if roll < 0.18:
			rooms[assignable[i]]["type"] = TREASURE
		elif roll < 0.30:
			rooms[assignable[i]]["type"] = EMPTY
		# else stays COMBAT (the default from _make_room)
