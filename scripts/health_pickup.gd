extends Node2D
## A heart pickup that charges the player's health potion.
##
## Key concept: **indirect healing**.
## Hearts don't heal you directly — they fill your potion bar.
## When the potion is full, press Q to drink it and heal!
## This gives the player CONTROL over when to heal, which adds
## a layer of strategy: "Do I drink now or save it for the boss?"

## How much potion charge this heart gives (out of 100 max).
var charge_amount: int = 34

## How close the player must be to pick it up (in pixels).
const PICKUP_RADIUS: float = 12.0

## Animation timer for the floating bob effect.
var _bob_time: float = 0.0

## The base Y position (before bobbing).
var _base_y: float = 0.0

## Has this pickup been collected?
var _collected: bool = false

# ── Heart pixel art (5x5) ────────────────────────────────────────
const HEART_GRID: Array = [
	[0, 1, 0, 1, 0],
	[1, 2, 1, 2, 1],
	[1, 1, 1, 1, 1],
	[0, 1, 1, 1, 0],
	[0, 0, 1, 0, 0],
]

const COLOR_RED := Color(0.9, 0.15, 0.15)
const COLOR_HIGHLIGHT := Color(1.0, 0.45, 0.45)


func _ready() -> void:
	_base_y = position.y
	_bob_time = randf() * TAU


func _process(delta: float) -> void:
	if _collected:
		return

	# ── Bob animation ─────────────────────────────────────────
	_bob_time += delta * 3.0
	position.y = _base_y + sin(_bob_time) * 2.0

	# ── Check for player pickup ───────────────────────────────
	var game: Node = get_parent()
	if not game.has_node("Player"):
		return

	var player: Node2D = game.get_node("Player")
	if player.is_dead:
		return

	var dist: float = position.distance_to(player.position)
	if dist <= PICKUP_RADIUS:
		_collect(player)


## Charges the player's potion and removes this pickup.
func _collect(player: Node2D) -> void:
	_collected = true

	# Add charge to the player's potion (capped at max).
	player.potion_charge = mini(player.potion_charge + charge_amount, player.POTION_MAX)
	player.hud.update_potion(player.potion_charge, player.POTION_MAX)

	queue_free()


func _draw() -> void:
	var pixel_size: float = 2.0
	var grid_w: int = 5
	var grid_h: int = 5
	var offset_x: float = -(grid_w * pixel_size) / 2.0
	var offset_y: float = -(grid_h * pixel_size) / 2.0

	for row in range(grid_h):
		for col in range(grid_w):
			var cell: int = HEART_GRID[row][col]
			if cell == 0:
				continue
			var color: Color = COLOR_RED if cell == 1 else COLOR_HIGHLIGHT
			draw_rect(Rect2(
				offset_x + col * pixel_size,
				offset_y + row * pixel_size,
				pixel_size, pixel_size
			), color)
