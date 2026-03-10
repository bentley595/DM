extends Node2D
## A dungeon enemy that chases the player and deals contact damage.
##
## Key concept: **setup() pattern**.
## Like projectile.gd, enemy behavior is configured at runtime
## via setup() rather than separate scripts per type.  The dungeon
## manager creates enemy nodes and calls setup("slime") or
## setup("skeleton") to pick the right stats and appearance.
## One script handles ALL enemy types — the differences are just
## data (speed, HP, grid art, color palette).
##
## Key concept: **the "targetable" group**.
## By adding ourselves to this group in _ready(), the player's
## swing detection and projectile hit detection AUTOMATICALLY
## work on us with zero changes.  That's the beauty of groups —
## any node wearing the "targetable" badge gets noticed!

signal died(enemy: Node2D, gold_value: int)

# ── Pixel art ───────────────────────────────────────────────────
const PIXEL_SIZE: int = 2
const FLASH_DURATION: float = 0.15
const FLASH_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)

# ── Contact damage settings ─────────────────────────────────────
## How close the enemy must be to hurt the player (in viewport pixels).
const CONTACT_DISTANCE: float = 12.0
## Cooldown between contact damage hits (prevents instant multi-hit).
const CONTACT_COOLDOWN: float = 0.8

# ── Enemy type definitions ──────────────────────────────────────
## Each type has different stats, speed, grid art, and color palette.
## Boss variants are the same enemy but bigger and stronger!
const ENEMY_TYPES: Dictionary = {
	"slime": {
		"name": "Slime",
		"hp": 5, "speed": 20.0, "gold": 8, "damage": 1,
		"palette": [
			Color(0, 0, 0, 0),
			Color(0.1, 0.3, 0.1, 1.0),
			Color(0.2, 0.6, 0.2, 1.0),
			Color(0.4, 0.8, 0.3, 1.0),
		],
		"grid": [
			[0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 1, 1, 0, 0, 0],
			[0, 0, 1, 2, 2, 1, 0, 0],
			[0, 1, 2, 3, 2, 2, 1, 0],
			[0, 1, 2, 2, 3, 2, 1, 0],
			[1, 2, 2, 2, 2, 2, 2, 1],
			[1, 2, 2, 2, 2, 2, 2, 1],
			[0, 1, 1, 1, 1, 1, 1, 0],
		],
	},
	"skeleton": {
		"name": "Skeleton",
		"hp": 3, "speed": 40.0, "gold": 12, "damage": 1,
		"palette": [
			Color(0, 0, 0, 0),
			Color(0.3, 0.3, 0.3, 1.0),
			Color(0.85, 0.82, 0.75, 1.0),
			Color(1.0, 1.0, 0.95, 1.0),
		],
		"grid": [
			[0, 0, 1, 1, 1, 1, 0, 0],
			[0, 1, 3, 1, 1, 3, 1, 0],
			[0, 1, 2, 2, 2, 2, 1, 0],
			[0, 0, 1, 2, 2, 1, 0, 0],
			[0, 1, 0, 1, 1, 0, 1, 0],
			[0, 0, 0, 1, 1, 0, 0, 0],
			[0, 0, 1, 0, 0, 1, 0, 0],
			[0, 0, 1, 0, 0, 1, 0, 0],
		],
	},
	"ghost": {
		"name": "Ghost",
		"hp": 4, "speed": 30.0, "gold": 15, "damage": 1,
		"palette": [
			Color(0, 0, 0, 0),
			Color(0.25, 0.15, 0.35, 1.0),
			Color(0.55, 0.4, 0.7, 1.0),
			Color(0.85, 0.75, 1.0, 1.0),
		],
		"grid": [
			[0, 0, 1, 1, 1, 1, 0, 0],
			[0, 1, 2, 2, 2, 2, 1, 0],
			[1, 2, 3, 2, 2, 3, 2, 1],
			[1, 2, 2, 2, 2, 2, 2, 1],
			[1, 2, 2, 2, 2, 2, 2, 1],
			[0, 1, 2, 2, 2, 2, 1, 0],
			[0, 1, 2, 1, 1, 2, 1, 0],
			[0, 1, 0, 0, 0, 0, 1, 0],
		],
	},
	# ── Boss variants (bigger grids, 4x HP, 5x gold) ───────────
	"boss_slime": {
		"name": "Giant Slime",
		"hp": 20, "speed": 15.0, "gold": 40, "damage": 2,
		"palette": [
			Color(0, 0, 0, 0),
			Color(0.1, 0.3, 0.1, 1.0),
			Color(0.2, 0.6, 0.2, 1.0),
			Color(0.4, 0.8, 0.3, 1.0),
		],
		"grid": [
			[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
			[0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0],
			[0, 0, 1, 2, 3, 2, 2, 3, 2, 1, 0, 0],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
			[0, 1, 2, 3, 2, 2, 2, 2, 3, 2, 1, 0],
			[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
			[1, 2, 2, 2, 2, 3, 3, 2, 2, 2, 2, 1],
			[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
			[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
			[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
		],
	},
	"boss_skeleton": {
		"name": "Skeleton Lord",
		"hp": 15, "speed": 30.0, "gold": 60, "damage": 2,
		"palette": [
			Color(0, 0, 0, 0),
			Color(0.3, 0.3, 0.3, 1.0),
			Color(0.85, 0.82, 0.75, 1.0),
			Color(1.0, 1.0, 0.95, 1.0),
		],
		"grid": [
			[0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
			[0, 0, 1, 3, 1, 2, 2, 1, 3, 1, 0, 0],
			[0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0],
			[0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0],
			[0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0],
			[0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0],
			[0, 0, 0, 1, 1, 2, 2, 1, 1, 0, 0, 0],
			[0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0],
			[0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0],
			[0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
			[0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
		],
	},
	"boss_ghost": {
		"name": "Phantom",
		"hp": 18, "speed": 25.0, "gold": 75, "damage": 2,
		"palette": [
			Color(0, 0, 0, 0),
			Color(0.25, 0.15, 0.35, 1.0),
			Color(0.55, 0.4, 0.7, 1.0),
			Color(0.85, 0.75, 1.0, 1.0),
		],
		"grid": [
			[0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
			[0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0],
			[0, 1, 2, 3, 3, 2, 2, 3, 3, 2, 1, 0],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
			[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
			[1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
			[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
			[0, 0, 1, 2, 1, 2, 2, 1, 2, 1, 0, 0],
			[0, 0, 1, 2, 0, 1, 1, 0, 2, 1, 0, 0],
			[0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0],
		],
	},
}

# ── Instance state (set by setup()) ─────────────────────────────
var enemy_type: String = "slime"
var max_hp: int = 5
var hp: int = 5
var move_speed: float = 20.0
var gold_value: int = 8
var contact_damage: int = 1
var grid: Array = []
var palette: Array = []

# ── Runtime state ───────────────────────────────────────────────
var is_flashing: bool = false
var flash_timer: float = 0.0
var contact_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("targetable")


## Configure this enemy with a type and optional HP bonus.
## Called by the dungeon manager after creating the node.
func setup(type: String, hp_bonus: int = 0) -> void:
	if not ENEMY_TYPES.has(type):
		type = "slime"
	enemy_type = type
	var data: Dictionary = ENEMY_TYPES[type]
	max_hp = data["hp"] + hp_bonus
	hp = max_hp
	move_speed = data["speed"]
	gold_value = data["gold"]
	contact_damage = data["damage"]
	grid = data["grid"]
	palette = data["palette"]
	queue_redraw()


## Called by the player's swing detection and by projectiles.
## Same interface as training_dummy.gd — no parameters needed.
func hit() -> void:
	hp -= 1
	is_flashing = true
	flash_timer = FLASH_DURATION
	queue_redraw()

	if hp <= 0:
		emit_signal("died", self, gold_value)
		queue_free()


func _process(delta: float) -> void:
	# ── Flash timer ─────────────────────────────────────────────
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			queue_redraw()

	# ── Contact damage cooldown ─────────────────────────────────
	if contact_cooldown > 0:
		contact_cooldown -= delta

	# ── Chase the player ────────────────────────────────────────
	var player: Node2D = _find_player()
	if player == null:
		return

	var diff: Vector2 = player.global_position - global_position
	var dist: float = diff.length()

	# Move toward the player
	if dist > 2.0:
		var dir: Vector2 = diff.normalized()
		position += dir * move_speed * delta

	# ── Contact damage ──────────────────────────────────────────
	if dist <= CONTACT_DISTANCE and contact_cooldown <= 0:
		contact_cooldown = CONTACT_COOLDOWN
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)


func _find_player() -> Node2D:
	var parent: Node = get_parent()
	if parent and parent.has_node("Player"):
		return parent.get_node("Player")
	return null


func _draw() -> void:
	if grid.is_empty():
		return
	var grid_h: int = grid.size()
	var grid_w: int = grid[0].size()
	var offset_x: float = -grid_w * PIXEL_SIZE / 2.0
	var offset_y: float = -grid_h * PIXEL_SIZE / 2.0

	for row in grid_h:
		for col in grid_w:
			var ci: int = grid[row][col]
			if ci == 0:
				continue
			var color: Color = FLASH_COLOR if is_flashing else palette[ci]
			draw_rect(Rect2(
				offset_x + col * PIXEL_SIZE,
				offset_y + row * PIXEL_SIZE,
				PIXEL_SIZE, PIXEL_SIZE
			), color)
