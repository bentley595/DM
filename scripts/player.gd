extends Node2D
## The player character — moves around and displays their chosen sprite + name.
##
## Key concept: **Input.is_action_pressed() vs event-based input**.
## On the menu screens, we used _unhandled_input() to respond to single key
## PRESSES — tap a key once, do something once.  But movement is different:
## you HOLD a key and the character moves continuously.  For that, we check
## Input.is_action_pressed() every frame in _process().  It returns true
## the entire time the key is held down, not just on the first press.
##
## Key concept: **Vector2 for direction**.
## Instead of moving X and Y separately with two if-statements, we combine
## them into a single Vector2.  This makes diagonal movement cleaner and
## lets us use .normalized() to prevent the "fast diagonal" problem.
##
## Key concept: **normalized()** — makes a vector's length exactly 1.0.
## If you press Right+Down, direction = (1, 1), which has length ~1.41.
## That means you'd move 41% FASTER diagonally than straight!  Players
## would notice and abuse it.  normalized() fixes this by shrinking the
## vector to length 1.0 while keeping the same angle.

# ── Shared data ───────────────────────────────────────────────────────
const CharData = preload("res://scripts/character_data.gd")

# ── Movement settings ─────────────────────────────────────────────────

## How fast the player moves in pixels per second.
## The viewport is 320×180, so at 55 px/s it takes ~6 seconds to cross.
@export var move_speed: float = 55.0

# ── Screen boundaries ─────────────────────────────────────────────────
# These keep the player from walking off the edge of the screen.
# The margins account for the sprite size and name label above it.
const BOUND_LEFT: float = 16.0
const BOUND_RIGHT: float = 304.0
const BOUND_TOP: float = 36.0
const BOUND_BOTTOM: float = 158.0

# ── Node references ───────────────────────────────────────────────────

@onready var sprite: Node2D = $CharacterSprite
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	# Read the character choice and name directly from SceneTree metadata.
	# This is simpler than waiting for the parent scene to call setup() —
	# the player knows where to find its own data!
	#
	# For future multiplayer, we'd switch to setup() being called with
	# each player's specific data.  But for single-player, reading the
	# meta ourselves is the most reliable approach.
	var char_index: int = get_tree().get_meta("selected_character_index", 0)
	var player_name: String = get_tree().get_meta("player_name", "Test")
	setup(char_index, player_name)


func setup(character_index: int, player_name: String) -> void:
	## Configures this player's appearance — sprite and floating name.
	## Right now _ready() calls this automatically from SceneTree meta.
	## For multiplayer later, the server would call this with each player's data.
	var chars: Array = CharData.characters()
	var character: Dictionary = chars[character_index]
	sprite.set_character(character)
	name_label.text = player_name


func _process(delta: float) -> void:
	# ── Build a direction vector from held keys ──────────────────
	# Start at (0, 0) — no movement.  Then add -1 or +1 for each
	# direction key that's currently held.
	#
	# We use "if" (not "elif") for each direction so the player can
	# hold two keys at once for diagonal movement!
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	if Input.is_action_pressed("move_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("move_down"):
		direction.y += 1.0

	# ── Normalize to fix fast diagonals ──────────────────────────
	# Only normalize when there IS a direction — you can't normalize
	# (0, 0) because a zero-length vector has no direction.
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# ── Apply movement ───────────────────────────────────────────
	# position += direction * speed * delta
	#   direction  = WHICH WAY to move (length 1.0 after normalizing)
	#   move_speed = HOW FAST in pixels per second
	#   delta      = seconds since last frame (makes it smooth on any PC)
	#
	# Why multiply by delta?  Without it, fast computers would move
	# the character faster than slow ones.  delta evens it out.
	position += direction * move_speed * delta

	# ── Stay inside the screen ───────────────────────────────────
	# clampf(value, min, max) squishes the position into bounds.
	# If the player tries to walk past the edge, clampf stops them.
	position.x = clampf(position.x, BOUND_LEFT, BOUND_RIGHT)
	position.y = clampf(position.y, BOUND_TOP, BOUND_BOTTOM)

	# ── Update facing direction ──────────────────────────────────
	# Only change direction when the player is actively moving —
	# when they stop, the character keeps facing the last direction.
	# This is how SNES RPGs work (stop moving = freeze in place).
	#
	# Horizontal directions (left/right) win ties on diagonals.
	# Why?  Because the side-profile sprites look very different from
	# front/back, so they're more visually informative.  If you're
	# walking diagonally up-right, seeing the right-facing profile
	# tells you "I'm heading right" much more clearly than seeing
	# the back-of-head which just says "I'm heading up."
	if direction != Vector2.ZERO:
		if absf(direction.x) >= absf(direction.y):
			# Horizontal wins (including perfect diagonal ties)
			if direction.x < 0.0:
				sprite.set_facing("left")
			else:
				sprite.set_facing("right")
		else:
			# Vertical wins
			if direction.y < 0.0:
				sprite.set_facing("up")
			else:
				sprite.set_facing("down")

	# Tell the sprite whether to animate — if direction is anything
	# other than (0,0), the player is moving and should walk!
	sprite.set_walking(direction != Vector2.ZERO)
