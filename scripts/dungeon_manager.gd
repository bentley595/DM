extends Node
## Dungeon Manager — room-based dungeon crawler!
##
## Key concept: **dungeon crawling vs wave rushing**.
## Instead of spawning waves of enemies in one arena, the dungeon is
## a MAP of connected rooms.  The player explores room by room, walking
## through doors to discover what's behind them.  Some rooms have enemies,
## some have treasure, some are empty rest stops, and the final room has
## the boss (if the recipe includes one).
##
## The flow:
##   1. Generate a random map of connected rooms
##   2. Player starts in a safe "start" room
##   3. Walk to a door opening → teleport to the next room
##   4. Combat rooms LOCK their doors until all enemies are dead
##   5. Clear the goal room (furthest from start) to win!
##
## The recipe system from the crafting UI still controls everything:
## enemy types, room count, boss, gold multiplier, challenges, etc.
## The only difference is HOW the rooms are structured — as a map
## instead of sequential waves.

const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const IngredientData = preload("res://scripts/ingredient_data.gd")
const BitmapLabelScript = preload("res://scripts/bitmap_label.gd")
const DungeonGen = preload("res://scripts/dungeon_generator.gd")
const HealthPickupScript = preload("res://scripts/health_pickup.gd")

# ── Room geometry ────────────────────────────────────────────────
## These match the player's movement bounds exactly.
## The room renderer draws walls just outside these bounds.
const PLAY_LEFT: float = 16.0
const PLAY_RIGHT: float = 304.0
const PLAY_TOP: float = 36.0
const PLAY_BOTTOM: float = 158.0

# ── Door detection ───────────────────────────────────────────────
## The center of the door openings on each wall.
const DOOR_CENTER_X: float = 160.0
const DOOR_CENTER_Y: float = 97.0

## Half the door width — used to check if the player is lined up.
## Door is 32px wide, so player must be within ±16px of center.
const DOOR_HALF: float = 16.0

## How close to the wall the player must be to trigger a door.
## At 2px, they're basically touching the wall.
const DOOR_TRIGGER: float = 2.0

# ── Timing ───────────────────────────────────────────────────────
## After going through a door, ignore door triggers for this long.
## Prevents instantly bouncing back if the player is still holding
## the movement key when they arrive in the new room.
const TRANSITION_COOLDOWN: float = 0.3

## How long to wait before returning to camp after completing the dungeon.
const COMPLETE_DELAY: float = 2.5

# ── Dungeon state ────────────────────────────────────────────────
## The recipe Dictionary from the crafting UI.
var recipe: Dictionary = {}

## The generated dungeon map (from DungeonGenerator).
## Contains "rooms" (Dictionary of Vector2i → room data),
## "start_pos" and "goal_pos" (Vector2i).
var dungeon: Dictionary = {}

## The grid position of the room the player is currently in.
var current_pos: Vector2i = Vector2i.ZERO

## How many enemies are alive in the current room.
var enemies_alive: int = 0

## Total gold earned this dungeon run (awarded on completion).
var total_gold_earned: int = 0

## True when the dungeon is done and we're transitioning back.
var is_complete: bool = false

## True while changing rooms (prevents input during transition).
var is_transitioning: bool = false

## True when the current room's doors are locked (combat in progress).
var doors_locked: bool = false

## Countdown to prevent instant door re-triggers after transitioning.
var _transition_cooldown: float = 0.0

# ── UI nodes ─────────────────────────────────────────────────────
var _minimap: Node2D

# ── Room rendering (inline — no separate script) ────────────────
## Current room's door openings and visual state.
## game.gd calls draw_room() during its _draw() to render this.
var _room_doors := {"up": false, "down": false, "left": false, "right": false}
var _room_locked := false
var _room_type := 1
var _status_label: Node2D
var _status_timer: float = 0.0

# ── Per-run stats ────────────────────────────────────────────────
## Same stat tracking as before — used for ingredient unlock checks.
var _enemies_killed_this_run: int = 0
var _rooms_cleared_this_run: int = 0
var _bosses_defeated_this_run: int = 0


func _ready() -> void:
	# ── Read the recipe ───────────────────────────────────────
	recipe = get_tree().get_meta("dungeon_recipe", {})
	if recipe.is_empty():
		recipe = {
			"enemy_types": ["slime"],
			"room_count": 3,
			"enemy_hp_bonus": 0,
			"gold_multiplier": 1.0,
			"has_boss": false,
			"player_hp_multiplier": 1.0,
			"player_speed_multiplier": 1.0,
			"enemy_count_multiplier": 1,
			"darkness": false,
		}

	# Reset per-run damage tracking (for "no damage" unlock).
	get_tree().set_meta("stats_took_damage_this_run", false)

	var game: Node = get_parent()

	# Remove the training dummy — it's only for camp practice.
	if game.has_node("TrainingDummy"):
		game.get_node("TrainingDummy").queue_free()

	# Remove the Background ColorRect entirely.  The room renderer
	# draws its own dark void, and removing (not just hiding) the
	# ColorRect avoids ANY layering conflicts between Control nodes
	# and Node2D drawing.  We hide it first (immediate) because
	# queue_free() is deferred and it might render for one more frame.
	if game.has_node("Background"):
		var bg: Node = game.get_node("Background")
		bg.visible = false
		bg.queue_free()

	# ── Generate the dungeon map ──────────────────────────────
	# room_count from recipe scales the dungeon size.  We multiply
	# by a big factor so even the default recipe gives a sprawling
	# 10x10-ish grid of rooms to explore.
	var total_rooms: int = (recipe.get("room_count", 3) + 4) * 3
	var has_boss: bool = recipe.get("has_boss", false)
	dungeon = DungeonGen.generate(total_rooms, has_boss)

	# Place special room types (ingredient room, extra treasures)
	_place_special_rooms()

	# ── Apply recipe-based map effects ────────────────────────
	# Map Scroll: reveal the entire minimap from the start!
	if recipe.get("reveal_map", false):
		for pos in dungeon["rooms"]:
			dungeon["rooms"][pos]["explored"] = true

	# Phoenix Feather: set a metadata flag the player can check
	if recipe.get("has_revive", false):
		get_tree().set_meta("dungeon_has_revive", true)

	_minimap = game.get_node("HUD/Minimap")
	_minimap.setup(dungeon)

	# ── Create HUD labels ────────────────────────────────────
	_create_hud_labels()

	# ── Enter the start room ─────────────────────────────────
	_enter_room(dungeon["start_pos"], "")
	_show_status("EXPLORE THE DUNGEON!")


## Creates bitmap labels on the HUD for status messages.
func _create_hud_labels() -> void:
	var hud: CanvasLayer = get_parent().get_node("HUD")

	# Status label — center of screen, shows room type and events.
	_status_label = Node2D.new()
	_status_label.set_script(BitmapLabelScript)
	_status_label.position = Vector2(160, 85)
	_status_label.text_color = Color(0.4, 1.0, 0.5, 1.0)
	_status_label.pixel_size = 1
	hud.add_child(_status_label)


## Transitions the player into a room.
##
## This is the core of the dungeon crawler!  Every time you walk through
## a door, this function:
##   1. Marks the room as explored (for the minimap)
##   2. Positions the player at the opposite door
##   3. Updates the room renderer (walls/doors/lock state)
##   4. Spawns enemies or awards treasure based on room type
func _enter_room(pos: Vector2i, from_dir: String) -> void:
	current_pos = pos
	var room: Dictionary = dungeon["rooms"][pos]
	room["explored"] = true

	# ── Check if this room needs combat ───────────────────────
	var is_combat: bool = (room["type"] == DungeonGen.COMBAT or room["type"] == DungeonGen.BOSS)
	var should_lock: bool = is_combat and not room["cleared"]
	doors_locked = should_lock

	# ── Update visuals ────────────────────────────────────────
	_room_doors = room["doors"]
	_room_locked = should_lock
	_room_type = room.get("type", 1)
	get_parent().queue_redraw()
	_minimap.update_current(pos)

	# ── Position the player ───────────────────────────────────
	# The player appears at the OPPOSITE side of the room from
	# where they came.  If you walked UP through a door, you
	# entered the room above, so you appear at the BOTTOM door.
	var player: Node2D = get_parent().get_node("Player")
	match from_dir:
		"up":
			player.position = Vector2(DOOR_CENTER_X, PLAY_BOTTOM - 4)
		"down":
			player.position = Vector2(DOOR_CENTER_X, PLAY_TOP + 4)
		"left":
			player.position = Vector2(PLAY_RIGHT - 4, DOOR_CENTER_Y)
		"right":
			player.position = Vector2(PLAY_LEFT + 4, DOOR_CENTER_Y)
		_:
			# Start room or unknown — center of room
			player.position = Vector2(DOOR_CENTER_X, DOOR_CENTER_Y)

	# Prevent door re-trigger for a moment
	_transition_cooldown = TRANSITION_COOLDOWN

	# ── Spawn room content ────────────────────────────────────
	if is_combat and not room["cleared"]:
		_spawn_room_enemies(room["type"] == DungeonGen.BOSS)
		# Show room type
		if room["type"] == DungeonGen.BOSS:
			_show_status("!! BOSS !!")
		# Regular combat rooms don't need a message — enemies appearing is clear enough
	elif room["type"] == DungeonGen.TREASURE and not room["cleared"]:
		_award_treasure(room)
	elif room["type"] == DungeonGen.INGREDIENT and not room["cleared"]:
		_discover_ingredient(room)
	# START and EMPTY rooms: nothing to do, just explore!


## Spawns enemies inside the current room.
func _spawn_room_enemies(is_boss: bool) -> void:
	var enemy_types: Array = recipe.get("enemy_types", ["slime"])
	var hp_bonus: int = recipe.get("enemy_hp_bonus", 0)
	var count_mult: int = recipe.get("enemy_count_multiplier", 1)

	if is_boss:
		# Boss + support enemies
		var boss_type: String = "boss_" + enemy_types[randi() % enemy_types.size()]
		_spawn_enemy(boss_type, hp_bonus)
		var support_count: int = 2 * count_mult
		for i in range(support_count):
			var etype: String = enemy_types[randi() % enemy_types.size()]
			_spawn_enemy(etype, hp_bonus)
	else:
		# Regular combat room: 3-5 base enemies, scaled by multiplier
		var base_count: int = 3 + randi() % 3
		var total_count: int = base_count * count_mult
		for i in range(total_count):
			var etype: String = enemy_types[randi() % enemy_types.size()]
			_spawn_enemy(etype, hp_bonus)


## Creates a single enemy at a random position inside the room.
##
## Key difference from the old system: enemies spawn INSIDE the room
## (not at the edges).  We try to place them at least 40px away from
## the player so they don't spawn right on top of you!
func _spawn_enemy(type: String, hp_bonus: int) -> void:
	var enemy := Node2D.new()
	enemy.set_script(EnemyScript)
	get_parent().add_child(enemy)
	enemy.setup(type, hp_bonus)
	enemy.died.connect(_on_enemy_died)

	# Try to find a spawn position away from the player
	var player: Node2D = get_parent().get_node("Player")
	var pos: Vector2 = Vector2.ZERO
	for _attempt in range(10):
		pos = Vector2(
			randf_range(PLAY_LEFT + 20, PLAY_RIGHT - 20),
			randf_range(PLAY_TOP + 20, PLAY_BOTTOM - 20)
		)
		if pos.distance_to(player.position) > 40.0:
			break
	enemy.position = pos
	enemies_alive += 1


## Awards gold for entering a treasure room.
func _award_treasure(room: Dictionary) -> void:
	var gold: int = 20 + randi() % 31  # 20-50 gold
	gold = int(gold * recipe.get("gold_multiplier", 1.0))
	total_gold_earned += gold
	room["cleared"] = true
	_show_status("TREASURE! +" + str(gold) + "G")
	_minimap.queue_redraw()


## Called when an enemy dies — awards gold, tracks stats, checks room clear.
func _on_enemy_died(_enemy: Node2D, gold_value: int, type_name: String) -> void:
	var gold: int = int(gold_value * recipe.get("gold_multiplier", 1.0))
	total_gold_earned += gold
	enemies_alive -= 1
	_enemies_killed_this_run += 1

	# ── Health drop chance ────────────────────────────────────
	# 25% chance to drop a healing heart where the enemy died.
	# This rewards aggressive play — kill fast, heal more!
	if randf() < 0.25:
		_spawn_health_pickup(_enemy.position)

	if type_name.begins_with("boss_"):
		_bosses_defeated_this_run += 1

	# ── Room cleared? ─────────────────────────────────────────
	if enemies_alive <= 0:
		var room: Dictionary = dungeon["rooms"][current_pos]
		room["cleared"] = true
		_rooms_cleared_this_run += 1

		# Unlock doors so the player can leave!
		doors_locked = false
		_room_locked = false
		get_parent().queue_redraw()

		_minimap.queue_redraw()

		# ── Healing Herb effect ───────────────────────────────
		# If the recipe includes heal_per_room, restore HP after
		# clearing each combat room.  Great for longer dungeons!
		var heal: int = recipe.get("heal_per_room", 0)
		var game: Node = get_parent()
		if heal > 0 and game.has_node("Player"):
			var player: Node2D = game.get_node("Player")
			player.health = mini(player.health + heal, player._effective_max_hp)
			player.hud.update_health(player.health, player._effective_max_hp)
			_show_status("ROOM CLEARED! +" + str(heal) + " HP")
		else:
			_show_status("ROOM CLEARED!")

		# Check if this was the goal room — dungeon complete!
		if current_pos == dungeon["goal_pos"]:
			_dungeon_complete()


func _process(delta: float) -> void:
	# ── Status message timer ──────────────────────────────────
	if _status_timer > 0:
		_status_timer -= delta
		if _status_timer <= 0 and _status_label:
			_status_label.text = ""

	# ── Transition cooldown ───────────────────────────────────
	if _transition_cooldown > 0:
		_transition_cooldown -= delta

	# Don't check doors while transitioning, complete, or on cooldown
	if is_complete or is_transitioning or _transition_cooldown > 0:
		return

	# ── Check for door transitions ────────────────────────────
	if not doors_locked:
		var dir: String = _check_door_transition()
		if dir != "":
			_transition_room(dir)


## Checks if the player is at a door and pressing into it.
##
## Key concept: **intentional door activation**.
## The player has to be:
##   1. At the wall (within DOOR_TRIGGER pixels of the boundary)
##   2. Lined up with the door opening (within DOOR_HALF pixels of center)
##   3. Actively pressing the movement key toward the door
## All three conditions must be true!  This prevents accidental
## transitions from just walking near a door.
func _check_door_transition() -> String:
	if not get_parent().has_node("Player"):
		return ""

	var player: Node2D = get_parent().get_node("Player")
	var pos: Vector2 = player.position
	var room: Dictionary = dungeon["rooms"][current_pos]

	# Up door
	if room["doors"].get("up", false):
		if pos.y <= PLAY_TOP + DOOR_TRIGGER:
			if absf(pos.x - DOOR_CENTER_X) <= DOOR_HALF:
				if Input.is_action_pressed("move_up"):
					return "up"

	# Down door
	if room["doors"].get("down", false):
		if pos.y >= PLAY_BOTTOM - DOOR_TRIGGER:
			if absf(pos.x - DOOR_CENTER_X) <= DOOR_HALF:
				if Input.is_action_pressed("move_down"):
					return "down"

	# Left door
	if room["doors"].get("left", false):
		if pos.x <= PLAY_LEFT + DOOR_TRIGGER:
			if absf(pos.y - DOOR_CENTER_Y) <= DOOR_HALF:
				if Input.is_action_pressed("move_left"):
					return "left"

	# Right door
	if room["doors"].get("right", false):
		if pos.x >= PLAY_RIGHT - DOOR_TRIGGER:
			if absf(pos.y - DOOR_CENTER_Y) <= DOOR_HALF:
				if Input.is_action_pressed("move_right"):
					return "right"

	return ""


## Handles transitioning from one room to another.
func _transition_room(dir: String) -> void:
	is_transitioning = true

	# Clear all enemies and projectiles from the current room
	_clear_room_content()

	# Calculate the adjacent room's grid position
	var new_pos: Vector2i = current_pos + DungeonGen.DIR_VECTORS[dir]

	# Enter the new room (player appears at the opposite door)
	_enter_room(new_pos, dir)

	is_transitioning = false


## Removes all enemies and projectiles from the scene.
##
## When you leave a room, everything in it disappears.  If the room
## wasn't cleared, enemies will respawn fresh when you come back.
## Projectiles also get cleaned up so they don't hit things in the
## wrong room!
func _clear_room_content() -> void:
	enemies_alive = 0
	var game: Node = get_parent()

	# Remove all child nodes that are enemies or projectiles.
	# We check the script to identify them — this is reliable because
	# enemies use EnemyScript and projectiles use ProjectileScript.
	for child in game.get_children():
		if not is_instance_valid(child):
			continue
		var script = child.get_script()
		if script == EnemyScript or script == ProjectileScript or script == HealthPickupScript:
			child.queue_free()


## Spawns a health pickup at the given position.
func _spawn_health_pickup(pos: Vector2) -> void:
	var pickup := Node2D.new()
	pickup.set_script(HealthPickupScript)
	pickup.position = pos
	get_parent().add_child(pickup)





func _show_status(text: String) -> void:
	if _status_label:
		_status_label.text = text
		_status_timer = 2.0


## Places special room types after the generator creates the base layout.
##
## Key concept: **layered generation**.
## The generator handles the MAP layout (which rooms connect to which).
## Then WE handle the CONTENT (what's in each room).  This separation
## keeps the generator simple and lets us add new room types without
## changing the generator's algorithm!
func _place_special_rooms() -> void:
	var rooms: Dictionary = dungeon["rooms"]
	var start: Vector2i = dungeon["start_pos"]
	var goal: Vector2i = dungeon["goal_pos"]

	# Collect rooms we can change (not start, not goal)
	var eligible: Array = []
	for pos in rooms:
		if pos != start and pos != goal:
			eligible.append(pos)
	eligible.shuffle()

	# ── Place 1 ingredient room ───────────────────────────────
	# This is where the player can discover and permanently unlock
	# a random locked ingredient during their run!
	if not eligible.is_empty():
		rooms[eligible[0]]["type"] = DungeonGen.INGREDIENT
		eligible.remove_at(0)

	# ── Place extra treasure rooms (from Treasure Map ingredient) ──
	var extra_treasure: int = recipe.get("extra_treasure_rooms", 0)
	var placed: int = 0
	for i in range(eligible.size()):
		if placed >= extra_treasure:
			break
		# Only convert combat rooms to treasure (don't overwrite other specials)
		if rooms[eligible[i]]["type"] == DungeonGen.COMBAT:
			rooms[eligible[i]]["type"] = DungeonGen.TREASURE
			placed += 1


## Handles entering an ingredient room — unlocks a random locked ingredient!
##
## Key concept: **alternative unlock paths**.
## Normally, ingredients unlock through achievements (kill X enemies,
## complete Y dungeons, etc.).  Ingredient rooms give a SECOND way to
## unlock them — by exploring the dungeon!  This rewards curiosity
## and makes dungeon crawling feel more rewarding.
##
## If ALL ingredients are already unlocked, you get bonus gold instead.
## So ingredient rooms are never a waste!
func _discover_ingredient(room: Dictionary) -> void:
	room["cleared"] = true

	# Find which ingredients are still locked
	var unlocked: Array = get_tree().get_meta("unlocked_ingredients", ["slime_essence"])
	var locked: Array = []
	for id in IngredientData.INGREDIENTS:
		if not unlocked.has(id):
			locked.append(id)

	if locked.is_empty():
		# Everything unlocked — give bonus gold instead
		var gold: int = 50 + randi() % 51  # 50-100 gold
		gold = int(gold * recipe.get("gold_multiplier", 1.0))
		total_gold_earned += gold
		_show_status("NOTHING NEW... +" + str(gold) + "G")
	else:
		# Pick a random locked ingredient and unlock it!
		var pick: String = locked[randi() % locked.size()]
		unlocked.append(pick)
		get_tree().set_meta("unlocked_ingredients", unlocked)
		var ingr_name: String = IngredientData.INGREDIENTS[pick]["name"].to_upper()
		_show_status("FOUND " + ingr_name + "!")

	_minimap.queue_redraw()


## Called when the goal room is cleared — the player won!
func _dungeon_complete() -> void:
	is_complete = true

	# ── Update persistent stats ───────────────────────────────
	var prev_dungeons: int = get_tree().get_meta("stats_dungeons_completed", 0)
	var prev_gold: int = get_tree().get_meta("stats_total_gold_earned", 0)
	var prev_kills: int = get_tree().get_meta("stats_total_enemies_killed", 0)
	var prev_bosses: int = get_tree().get_meta("stats_bosses_defeated", 0)

	get_tree().set_meta("stats_dungeons_completed", prev_dungeons + 1)
	get_tree().set_meta("stats_total_gold_earned", prev_gold + total_gold_earned)
	get_tree().set_meta("stats_total_enemies_killed", prev_kills + _enemies_killed_this_run)
	get_tree().set_meta("stats_bosses_defeated", prev_bosses + _bosses_defeated_this_run)

	# ── Check for new ingredient unlocks ──────────────────────
	var new_unlocks: Array = _check_ingredient_unlocks()

	# ── Show victory message ──────────────────────────────────
	var msg: String = "COMPLETE! +" + str(total_gold_earned) + "G"
	if not new_unlocks.is_empty():
		var names: Array = []
		for uid in new_unlocks:
			names.append(IngredientData.INGREDIENTS[uid]["name"].to_upper())
		msg += " NEW: " + ", ".join(names) + "!"
	_show_status(msg)
	# Award gold to the player's total.
	var current_gold: int = get_tree().get_meta("player_gold", 0)
	get_tree().set_meta("player_gold", current_gold + total_gold_earned)

	# Save the player's inventory.
	var game: Node = get_parent()
	if game.has_node("Player"):
		var player: Node2D = game.get_node("Player")
		get_tree().set_meta("player_inventory", player.inventory.duplicate(true))

	# Clear the recipe — next time they'll need to craft again.
	if get_tree().has_meta("dungeon_recipe"):
		get_tree().remove_meta("dungeon_recipe")

	# Return to camp after a brief victory moment.
	await get_tree().create_timer(COMPLETE_DELAY).timeout
	get_tree().change_scene_to_file("res://scenes/camp.tscn")


## Checks ALL ingredients and unlocks any whose conditions are now met.
## This is identical to the previous system — the unlock logic doesn't
## care whether the dungeon was waves or rooms, just the stats!
func _check_ingredient_unlocks() -> Array:
	var unlocked: Array = get_tree().get_meta("unlocked_ingredients", [])
	var new_unlocks: Array = []

	var dungeons: int = get_tree().get_meta("stats_dungeons_completed", 0)
	var total_gold: int = get_tree().get_meta("stats_total_gold_earned", 0)
	var total_kills: int = get_tree().get_meta("stats_total_enemies_killed", 0)
	var bosses: int = get_tree().get_meta("stats_bosses_defeated", 0)
	var took_damage: bool = get_tree().get_meta("stats_took_damage_this_run", false)

	for ingr_id in IngredientData.INGREDIENTS:
		if ingr_id in unlocked:
			continue

		var data: Dictionary = IngredientData.INGREDIENTS[ingr_id]
		var unlock: Dictionary = data.get("unlock", {})
		var utype: String = unlock.get("type", "")
		var ucount: int = unlock.get("count", 0)
		var met: bool = false

		match utype:
			"default":
				met = true
			"dungeons_completed":
				met = dungeons >= ucount
			"enemies_killed_in_run":
				met = _enemies_killed_this_run >= ucount
			"total_gold_earned":
				met = total_gold >= ucount
			"rooms_cleared_in_run":
				met = _rooms_cleared_this_run >= ucount
			"dungeons_completed_no_damage":
				met = not took_damage and dungeons >= ucount
			"bosses_defeated":
				met = bosses >= ucount
			"enemies_killed_total":
				met = total_kills >= ucount

		if met:
			unlocked.append(ingr_id)
			new_unlocks.append(ingr_id)

	if not new_unlocks.is_empty():
		get_tree().set_meta("unlocked_ingredients", unlocked)

	return new_unlocks
