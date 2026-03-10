extends Node
## Dungeon Manager — generates rooms, spawns enemies, tracks progress.
##
## Key concept: **procedural generation from a recipe**.
## Instead of hand-designing each dungeon, we use a "recipe" Dictionary
## to randomly generate rooms of enemies.  The recipe comes from the
## crafting UI — the player chose WHAT to fight by placing ingredients.
## This means every dungeon run is different!
##
## The dungeon is a sequence of rooms.  Each room spawns a wave of
## enemies.  Kill them all to advance to the next room.  Clear all
## rooms to complete the dungeon and earn gold!
##
## Key concept: **runtime node creation**.
## Enemies don't exist in the scene file — we create them from code
## using Node2D.new() + set_script(), just like projectiles in player.gd.
## This lets us spawn different numbers and types each run!

const EnemyScript = preload("res://scripts/enemy.gd")
const IngredientData = preload("res://scripts/ingredient_data.gd")
const BitmapLabelScript = preload("res://scripts/bitmap_label.gd")

# ── Loot drops ────────────────────────────────────────────────────
## After completing a dungeon, the player gets random ingredient drops.
## This is how players get MORE ingredients without needing the shop!
## Enemy ingredients drop based on what you fought, plus a chance
## for modifier/room ingredients as bonus loot.
const BASE_DROPS: int = 2        ## Minimum ingredients earned per run
const BONUS_DROP_CHANCE: float = 0.4  ## 40% chance for an extra drop
const MODIFIER_IDS: Array = ["gold_dust", "iron_chunk", "lucky_clover", "stone_brick", "dark_crystal"]

# ── Spawn boundaries ──────────────────────────────────────────────
## Enemies spawn at the edges of the play area so they walk in
## from different directions.  These match the player's movement bounds.
const SPAWN_LEFT:   float = 20.0
const SPAWN_RIGHT:  float = 300.0
const SPAWN_TOP:    float = 40.0
const SPAWN_BOTTOM: float = 155.0

# ── Timing ───────────────────────────────────────────────────────
## Pause between rooms — gives the player a moment to breathe.
const BETWEEN_ROOM_DELAY: float = 2.0

## Brief countdown before the first room starts.
const FIRST_ROOM_DELAY: float = 1.5

## Delay before returning to camp after dungeon completion.
const COMPLETE_DELAY: float = 2.5

# ── State ────────────────────────────────────────────────────────
## The recipe Dictionary describing what this dungeon contains.
## Set by the crafting UI, read from SceneTree metadata.
var recipe: Dictionary = {}

## Total number of rooms in this dungeon run.
var room_count: int = 3

## Which room we're currently on (1-indexed for display).
var current_room: int = 0

## How many enemies are still alive in the current room.
var enemies_alive: int = 0

## Gold earned so far this run (awarded on completion).
var total_gold_earned: int = 0

## True when the dungeon is done and we're transitioning back.
var is_complete: bool = false

## True during the pause between rooms.
var is_between_rooms: bool = false

## Countdown timer for the between-room pause.
var between_room_timer: float = 0.0

## HUD bitmap label showing "ROOM 1/5" at the top center of the screen.
## Uses bitmap_label.gd instead of Label for crisp pixel-art text.
var _room_label: Node2D

## HUD bitmap label showing status messages like "ROOM CLEARED!" in the
## center of the screen.  These appear briefly then disappear.
var _status_label: Node2D

## Timer for hiding the status message after a few seconds.
var _status_timer: float = 0.0


func _ready() -> void:
	# ── Read the recipe from metadata ──────────────────────────
	# The crafting UI saves the recipe before transitioning here.
	# If there's no recipe (direct scene entry, testing), we fall
	# back to a safe default: 3 rooms of slimes.
	recipe = get_tree().get_meta("dungeon_recipe", {})
	if recipe.is_empty():
		recipe = {
			"enemy_types": ["slime"],
			"room_count": 3,
			"enemy_hp_bonus": 0,
			"gold_multiplier": 1.0,
			"loot_bonus": false,
			"has_boss": false,
		}

	room_count = recipe.get("room_count", 3)

	# Remove the training dummy — we're in dungeon mode now!
	# The training dummy is great for testing in camp, but the
	# dungeon has real enemies to fight.
	var game: Node = get_parent()
	if game.has_node("TrainingDummy"):
		game.get_node("TrainingDummy").queue_free()

	# Create HUD elements for the room counter and status messages.
	_create_hud_labels()

	# Brief pause before the action starts — lets the player orient.
	_show_status("GET READY!")
	is_between_rooms = true
	between_room_timer = FIRST_ROOM_DELAY


## Creates bitmap label nodes on the HUD CanvasLayer for room progress
## and status messages.
##
## Key concept: **bitmap labels vs. Label nodes**.
## Godot's built-in Label uses a vector font (Pixelify Sans) that gets
## rasterized at runtime.  At the game's tiny 320×180 viewport with 4×
## scaling, vector text can look blurry or misaligned.  Bitmap labels
## draw each letter as a grid of individual pixels — always perfectly
## crisp, just like classic NES/Game Boy text!
func _create_hud_labels() -> void:
	var hud: CanvasLayer = get_parent().get_node("HUD")

	# Room counter (top center) — e.g. "ROOM 1/5"
	# Position is the CENTER of the text (bitmap_label auto-centers).
	# pixel_size=2 makes each font pixel 2×2, so letters are 6×10.
	_room_label = Node2D.new()
	_room_label.set_script(BitmapLabelScript)
	_room_label.position = Vector2(160, 3)
	_room_label.text_color = Color(0.8, 0.8, 0.9, 1.0)
	_room_label.pixel_size = 1
	hud.add_child(_room_label)

	# Status message (center of screen) — "ROOM CLEARED!", etc.
	# pixel_size=2 so it's big and easy to read mid-combat.
	_status_label = Node2D.new()
	_status_label.set_script(BitmapLabelScript)
	_status_label.position = Vector2(160, 85)
	_status_label.text_color = Color(0.4, 1.0, 0.5, 1.0)
	_status_label.pixel_size = 1
	hud.add_child(_status_label)


## Starts the next room — spawns enemies and updates the HUD.
func _start_room() -> void:
	current_room += 1
	is_between_rooms = false
	_status_label.text = ""

	# Update room counter on the HUD.
	_room_label.text = "ROOM " + str(current_room) + "/" + str(room_count)

	# ── Calculate enemy count ──────────────────────────────────
	# Scales up with room number so later rooms are harder.
	# Room 1: 3 enemies, Room 2: 4, Room 3: 5, etc.
	var enemy_count: int = 2 + current_room
	var enemy_types: Array = recipe.get("enemy_types", ["slime"])
	var hp_bonus: int = recipe.get("enemy_hp_bonus", 0)

	# ── Boss room check ────────────────────────────────────────
	# If the recipe includes a boss (dark_crystal ingredient),
	# the LAST room spawns a big boss enemy plus support enemies.
	var is_boss_room: bool = recipe.get("has_boss", false) and current_room == room_count

	if is_boss_room:
		# Pick a random enemy type and spawn its boss variant.
		var boss_type: String = "boss_" + enemy_types[randi() % enemy_types.size()]
		_spawn_enemy(boss_type, hp_bonus)
		# Add a few normal enemies as support — bosses shouldn't
		# fight alone, that would be too predictable!
		for i in range(2):
			var etype: String = enemy_types[randi() % enemy_types.size()]
			_spawn_enemy(etype, hp_bonus)
	else:
		# Normal room — spawn enemy_count random enemies.
		for i in range(enemy_count):
			var etype: String = enemy_types[randi() % enemy_types.size()]
			_spawn_enemy(etype, hp_bonus)


## Creates an enemy node, configures it, and places it at a random edge.
##
## Key concept: **edge spawning**.
## Enemies appear at the edges of the play area and walk toward the
## player.  This looks natural — they're "entering the room" from
## different directions.  We pick a random edge (top/bottom/left/right)
## and a random position along that edge.
func _spawn_enemy(type: String, hp_bonus: int) -> void:
	var enemy := Node2D.new()
	enemy.set_script(EnemyScript)
	get_parent().add_child(enemy)
	enemy.setup(type, hp_bonus)

	# Connect the died signal so we know when to advance rooms.
	enemy.died.connect(_on_enemy_died)

	# Pick a random edge to spawn from.
	var edge: int = randi() % 4
	match edge:
		0: enemy.position = Vector2(randf_range(SPAWN_LEFT, SPAWN_RIGHT), SPAWN_TOP)
		1: enemy.position = Vector2(randf_range(SPAWN_LEFT, SPAWN_RIGHT), SPAWN_BOTTOM)
		2: enemy.position = Vector2(SPAWN_LEFT, randf_range(SPAWN_TOP, SPAWN_BOTTOM))
		3: enemy.position = Vector2(SPAWN_RIGHT, randf_range(SPAWN_TOP, SPAWN_BOTTOM))

	enemies_alive += 1


## Called when an enemy dies — awards gold and checks if the room is clear.
func _on_enemy_died(_enemy: Node2D, gold_value: int) -> void:
	# Apply the gold multiplier from the recipe (gold_dust ingredient).
	var gold: int = int(gold_value * recipe.get("gold_multiplier", 1.0))
	total_gold_earned += gold
	enemies_alive -= 1

	# If all enemies are dead, check what's next.
	if enemies_alive <= 0:
		if current_room >= room_count:
			_dungeon_complete()
		else:
			_show_status("ROOM CLEARED!")
			is_between_rooms = true
			between_room_timer = BETWEEN_ROOM_DELAY


func _process(delta: float) -> void:
	# ── Between-room countdown ─────────────────────────────────
	# After clearing a room, we pause briefly before the next one.
	# This gives the player a moment to breathe and reposition.
	if is_between_rooms:
		between_room_timer -= delta
		if between_room_timer <= 0:
			_start_room()

	# ── Status message auto-hide ───────────────────────────────
	if _status_timer > 0:
		_status_timer -= delta
		if _status_timer <= 0 and _status_label:
			_status_label.text = ""


## Shows a status message in the center of the screen.
func _show_status(text: String) -> void:
	if _status_label:
		_status_label.text = text
		_status_timer = 2.0


## Generates random ingredient drops based on the dungeon recipe.
##
## Key concept: **loot tables**.
## Instead of giving fixed rewards, we pick randomly from a pool.
## Enemy ingredients drop based on what you FOUGHT (so fighting skeletons
## gives bone fragments), and there's a chance for bonus modifier drops.
## The "lucky clover" ingredient increases your bonus chance!
func _generate_loot_drops() -> Array:
	var drops: Array = []
	var enemy_types: Array = recipe.get("enemy_types", ["slime"])
	var has_loot_bonus: bool = recipe.get("loot_bonus", false)

	# ── Enemy ingredient drops (guaranteed) ────────────────────
	# You always get at least BASE_DROPS enemy ingredients.
	# These match the enemies you fought — kill slimes, get slime essence!
	# Map from enemy type to ingredient ID.
	var type_to_ingredient: Dictionary = {
		"slime": "slime_essence",
		"skeleton": "bone_fragment",
		"ghost": "shadow_wisp",
	}

	for i in range(BASE_DROPS):
		var etype: String = enemy_types[randi() % enemy_types.size()]
		var ingr_id: String = type_to_ingredient.get(etype, "slime_essence")
		drops.append({"id": ingr_id, "level": 1})

	# ── Bonus modifier drop (chance-based) ─────────────────────
	# There's a chance to get a random modifier ingredient as a bonus.
	# The lucky_clover ingredient doubles this chance!
	var bonus_chance: float = BONUS_DROP_CHANCE
	if has_loot_bonus:
		bonus_chance *= 2.0  # 40% → 80% with lucky clover!

	if randf() < bonus_chance:
		var mod_id: String = MODIFIER_IDS[randi() % MODIFIER_IDS.size()]
		drops.append({"id": mod_id, "level": 1})

	return drops


## Called when all rooms are cleared — the player won!
## Awards gold, drops ingredients, saves inventory, and returns to camp.
func _dungeon_complete() -> void:
	is_complete = true

	# ── Drop ingredient rewards ────────────────────────────────
	# The player earns random ingredients so they can craft the NEXT
	# dungeon without needing the shop.  This creates a natural loop:
	# use ingredients → beat dungeon → get new ingredients → repeat!
	var drops: Array = _generate_loot_drops()
	var game: Node = get_parent()
	if game.has_node("Player"):
		var player: Node2D = game.get_node("Player")
		for drop in drops:
			IngredientData.add_to_bag(player.inventory["bag"], drop["id"])

	# Show victory message with gold and drops earned.
	var drop_text: String = ""
	if not drops.is_empty():
		drop_text = " +" + str(drops.size()) + " ITEMS"
	_show_status("COMPLETE! +" + str(total_gold_earned) + "G" + drop_text)
	_room_label.text = "VICTORY!"

	# Award gold to the player's total.
	var current_gold: int = get_tree().get_meta("player_gold", 0)
	get_tree().set_meta("player_gold", current_gold + total_gold_earned)

	# Save the player's inventory (now including the loot drops).
	if game.has_node("Player"):
		var player: Node2D = game.get_node("Player")
		get_tree().set_meta("player_inventory", player.inventory.duplicate(true))

	# Clear the recipe — next time they'll need to craft again.
	if get_tree().has_meta("dungeon_recipe"):
		get_tree().remove_meta("dungeon_recipe")

	# Return to camp after a brief victory moment.
	# await pauses this function until the timer fires.
	# If the scene changes before then (e.g. player presses Escape),
	# the coroutine is simply abandoned — no crash!
	await get_tree().create_timer(COMPLETE_DELAY).timeout
	get_tree().change_scene_to_file("res://scenes/camp.tscn")
