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
const WeaponData = preload("res://scripts/weapon_data.gd")
const ArmorData  = preload("res://scripts/armor_data.gd")

## Preload the projectile script so we can create new projectile nodes at runtime.
## Key concept: **preload vs load**.
## preload() reads the file at COMPILE TIME (when the game starts up),
## so it's ready instantly when we need it.  load() reads at RUNTIME,
## which can cause tiny stutters the first time.  Since we know we'll
## need projectiles, preloading is better here.
const ProjectileScript = preload("res://scripts/projectile.gd")

# ── Movement settings ─────────────────────────────────────────────────

## How fast the player moves in pixels per second.
## The viewport is 320×180, so at 75 px/s it takes ~4 seconds to cross.
@export var move_speed: float = 75.0

# ── Screen boundaries ─────────────────────────────────────────────────
# These keep the player from walking off the edge of the screen.
# The margins account for the sprite size and name label above it.
const BOUND_LEFT: float = 16.0
const BOUND_RIGHT: float = 304.0
const BOUND_TOP: float = 36.0
const BOUND_BOTTOM: float = 158.0

# ── Roll settings ────────────────────────────────────────────────────
# The roll is a quick dash that moves you faster than walking.
# After using it, you have to wait for the cooldown before rolling again.

## Pixels per second during a roll (~2.7x normal walk speed).
const ROLL_SPEED: float = 200.0

## How long the roll dash lasts in seconds.
## At 200 px/s for 0.25s, you travel ~50 pixels — a quick burst!
const ROLL_DURATION: float = 0.25

## Momentum bonuses applied to the roll.
## Speed: +2 px/s per stack  → at 50 stacks: 300 px/s
## Duration: +0.002s per stack → at 50 stacks: 0.35s
## Combined distance at max: 300 × 0.35 = 105px vs 50px baseline (+110%)
const ROLL_SPEED_PER_MOMENTUM: float    = 2.0
const ROLL_DURATION_PER_MOMENTUM: float = 0.002

## Time in seconds before you can roll again.
const ROLL_COOLDOWN: float = 1.8

# ── Swing settings ──────────────────────────────────────────────────
# The swing is a quick melee attack — the character freezes briefly
# while an arc appears in front of them.  Short cooldown prevents
# spam but still feels responsive.

## How long the player is locked in place during the swing animation.
## 5 frames at 18 FPS = ~0.28 seconds — quick and snappy!
const SWING_DURATION: float = 0.28

## Time in seconds before you can swing again.
## Short cooldown keeps combat fast-paced.
const SWING_COOLDOWN: float = 0.38

# ── Momentum settings ───────────────────────────────────────────────
# Momentum stacks up as you land hits.  It makes you faster and hits
# harder, but resets to 0 the moment an enemy hits you back.
# Think of it like a risk-reward system: play aggressively to get faster,
# but getting punished wipes your streak!

## Maximum number of momentum stacks.
const MAX_MOMENTUM: int = 50

## Speed boost per momentum stack in pixels/second.
## At max (50 stacks): +100 px/s on top of the base 75 = 175 px/s.
const MOMENTUM_SPEED_BONUS: float = 2.0

## Attack speed bonus per stack — reduces both swing and shoot cooldowns.
## 0.5% per stack means at 50 stacks you attack 25% faster.
const MOMENTUM_ATTACK_SPEED_BONUS: float = 0.005

## Current momentum stacks.  Gained on hit, lost on taking damage.
var momentum: int = 0

## True while the 25-stack ammo bonus is active (max ammo doubled to 24).
var _ammo_doubled: bool = false

# ── Soul settings ────────────────────────────────────────────────────
# Soul is a separate resource gained by landing hits.  It will be used
# to cast spells (to be added later).  Unlike momentum, soul is NOT
# reset when the player takes damage — it's a longer-term resource.

## Maximum soul the player can hold.
const MAX_SOUL: float = 100.0

## How much soul each landed hit gives.
## At 5 per hit, a full bar takes 20 hits.
const SOUL_PER_HIT: float = 5.0

## Current soul amount.
var soul: float = 0.0

# ── Shoot settings ──────────────────────────────────────────────────
# Right-click fires a projectile toward the mouse cursor.  Unlike the
# swing (which is cardinal-locked), projectiles fly at any angle!

## Time in seconds between shots — fast enough to feel snappy,
## slow enough that you can't just spam bullets.
const SHOOT_COOLDOWN: float = 0.35

## How many shots before you need to reload.
const MAX_AMMO: int = 12

## How long it takes to reload (in seconds) once you hit 0 ammo.
const RELOAD_TIME: float = 12.0

# ── Roll state ───────────────────────────────────────────────────────
#
# Key concept: **state variables**.
# The roll has multiple pieces of information that change over time:
# whether we're rolling, how long is left, which direction, and how
# long until we can roll again.  Each gets its own variable.

## True while the player is mid-roll.
var is_rolling: bool = false

## Counts down from ROLL_DURATION to 0 during a roll.
var roll_timer: float = 0.0

## The direction the roll is moving (normalized Vector2).
var roll_direction: Vector2 = Vector2.ZERO

## The speed captured when the roll started (includes momentum bonus).
var roll_speed: float = ROLL_SPEED

## Counts down from ROLL_COOLDOWN to 0 after a roll.
## When this reaches 0, the player can roll again.
var roll_cooldown_timer: float = 0.0

# ── Swing state ──────────────────────────────────────────────────────
# Same pattern as roll state!  A bool for "are we swinging?",
# a timer for the duration, and a cooldown timer to prevent spam.

## True while the player is mid-swing.
var is_swinging: bool = false

## Counts down from SWING_DURATION to 0 during a swing.
var swing_timer: float = 0.0

## Counts down from SWING_COOLDOWN to 0 after a swing.
var swing_cooldown_timer: float = 0.0

# ── Shoot state ────────────────────────────────────────────────────
# Ammo-based ranged attack.  When ammo hits 0, a reload timer starts.

## Current ammo count — starts full.
var ammo: int = MAX_AMMO

## Counts down from SHOOT_COOLDOWN to 0 between shots.
var shoot_cooldown_timer: float = 0.0

## True while the player is reloading (waiting for ammo to refill).
var is_reloading: bool = false

## Counts down from RELOAD_TIME to 0 during a reload.
var reload_timer: float = 0.0

# ── Character info (stored for projectile spawning) ──────────────
# When we create a projectile, it needs to know what SHAPE to be
# (based on the character's body template) and what COLORS to use
# (from the character's palette).  We store these at setup time
# so we don't have to look them up every time we shoot.

## Which body template: "armored", "robed", "light", or "clothed".
var char_template: String = "armored"

## The 3 colors passed to each projectile: [outline, accent, highlight].
var projectile_colors: Array = []

## The player's weapon inventory.
## "melee"  = ID of equipped melee weapon  (e.g. "sword")
## "ranged" = ID of equipped ranged weapon (e.g. "crossbow")
## "bag"    = list of weapon IDs not currently equipped
## Each equipped slot holds a Dictionary {"id": "sword", "level": 1}, or {} when empty.
## Bag items are the same format — this lets two Level-1 and Level-3 swords coexist!
var inventory: Dictionary = {"bag": [], "melee": {}, "ranged": {}, "armor": {}}

# ── Playtest state ───────────────────────────────────────────────
# In playtest mode (P key shortcut), holding right click cycles
# through projectile templates instead of shooting.  A quick tap
# still fires as normal.

## True when the game was launched via the P key shortcut.
var is_playtest: bool = false


# ── Node references ───────────────────────────────────────────────────

@onready var sprite: Node2D = $CharacterSprite
@onready var name_label: Node2D = $NameLabel
@onready var swing_effect: Node2D = $SwingEffect
@onready var momentum_burst: Node2D = $MomentumBurst

## The HUD is a sibling node (both Player and HUD are children of Game).
## get_parent() gives us the Game node, then we find the HUD from there.
@onready var hud: CanvasLayer = get_parent().get_node("HUD")
@onready var _inv_screen = get_parent().get_node("InventoryScreen")


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
	is_playtest = get_tree().get_meta("is_playtest", false)
	setup(char_index, player_name)

	# If there's a saved inventory (from a previous camp/dungeon visit),
	# restore it instead of using the defaults that setup() just created.
	# This is how your items persist when going camp → dungeon → camp!
	var saved_inv: Dictionary = get_tree().get_meta("player_inventory", {})
	if not saved_inv.is_empty():
		inventory = saved_inv

	# Listen for weapon changes from the inventory screen
	_inv_screen.weapon_equipped.connect(_on_weapon_equipped)
	_inv_screen.weapon_unequipped.connect(_on_weapon_unequipped)


func setup(character_index: int, player_name: String) -> void:
	## Configures this player's appearance — sprite and floating name.
	## Right now _ready() calls this automatically from SceneTree meta.
	## For multiplayer later, the server would call this with each player's data.
	var chars: Array = CharData.characters()
	var character: Dictionary = chars[character_index]
	sprite.set_character(character)
	name_label.text = player_name

	# ── Store info for projectile spawning ───────────────────────
	# Figure out which body template this character uses based on
	# their index.  The 20 characters are arranged in order:
	#   0-4   = ARMORED (5 characters)
	#   5-10  = ROBED   (6 characters)
	#   11-15 = LIGHT   (5 characters)
	#   16-19 = CLOTHED (4 characters)
	if character_index <= 4:
		char_template = "armored"
	elif character_index <= 10:
		char_template = "robed"
	elif character_index <= 15:
		char_template = "light"
	else:
		char_template = "clothed"

	# Grab the 3 colors each projectile needs from the character's palette.
	# palette[1] = outline (dark border/structure)
	# palette[7] = accent  (main fill color — makes each character unique!)
	# palette[3] = highlight (bright center/glow)
	var palette: Array = character["palette"]
	projectile_colors = [palette[1], palette[7], palette[3]]

	# Assign starting weapons and armor based on the character's body template.
	# Every character starts at Level 1.  Higher-level gear can drop from dungeon loot later!
	inventory.melee  = {"id": WeaponData.default_melee(char_template),  "level": 1}
	inventory.ranged = {"id": WeaponData.default_ranged(char_template), "level": 1}
	inventory.armor  = {"id": ArmorData.default_armor(char_template),   "level": 1}

	# Set the HUD to show real values instead of placeholders
	hud.update_ammo(ammo, _current_max_ammo())
	hud.update_soul(soul, MAX_SOUL)
	_update_momentum_hud()


func _process(delta: float) -> void:
	# ── Check if ANY overlay is open ────────────────────────────
	# Before doing anything, check if an overlay is blocking input.
	# This prevents hotkeys from opening menus on top of each other
	# (e.g. pressing I while the chat is open, or pressing T while
	# the inventory is open).
	var parent: Node = get_parent()
	var _overlay_open: bool = false
	if _inv_screen.is_open:
		_overlay_open = true
	elif parent:
		for overlay_name in ["ShopUI", "ForgeUI", "UnlockPrompt", "ChatConsole"]:
			if parent.has_node(overlay_name) and parent.get_node(overlay_name).is_open:
				_overlay_open = true
				break

	# ── Inventory toggle ─────────────────────────────────────────
	# Press I to open the inventory — but only if nothing else is open!
	if Input.is_action_just_pressed("inventory") and not _overlay_open:
		_inv_screen.open(inventory)
		return

	# If any overlay is open, skip ALL movement and combat input.
	if _overlay_open:
		return

	# ── Interact with nearby stations ────────────────────────────
	# Press E to interact with the nearest interactable (forge, shop, etc.)
	# This uses the same groups pattern as hit detection — we look for
	# nodes in the "interactable" group, check distance, and call their
	# on_interact() method.  Any node that adds itself to the
	# "interactable" group and has on_interact() will work automatically!
	if Input.is_action_just_pressed("interact"):
		var interactables: Array = get_tree().get_nodes_in_group("interactable")
		for obj in interactables:
			if global_position.distance_to(obj.global_position) <= 30.0:
				obj.on_interact()
				break

	# ── Update roll cooldown ─────────────────────────────────────
	# This runs every frame, even when we're not rolling.
	# It counts down the timer and updates the HUD arrow indicator.
	#
	# Key concept: **cooldown as a countdown timer**.
	# roll_cooldown_timer starts at ROLL_COOLDOWN (2.5) and counts
	# down to 0.  We convert it to a 0-1 percentage for the HUD:
	#   timer = 2.5  →  percent = 0.0  (just rolled, arrow empty)
	#   timer = 1.25 →  percent = 0.5  (halfway recharged)
	#   timer = 0.0  →  percent = 1.0  (ready! arrow full)
	if roll_cooldown_timer > 0:
		roll_cooldown_timer = maxf(roll_cooldown_timer - delta, 0.0)
		var cooldown_percent: float = 1.0 - (roll_cooldown_timer / ROLL_COOLDOWN)
		hud.update_roll_cooldown(cooldown_percent)

	# ── Update swing cooldown ────────────────────────────────────
	# Same pattern as roll cooldown — counts down each frame.
	# No HUD indicator for this one (the cooldown is so short you
	# barely notice it).
	if swing_cooldown_timer > 0:
		swing_cooldown_timer = maxf(swing_cooldown_timer - delta, 0.0)

	# ── Update shoot cooldown ────────────────────────────────────
	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer = maxf(shoot_cooldown_timer - delta, 0.0)

	# ── Update reload timer ──────────────────────────────────────
	# When ammo hits 0, a reload timer counts down.  When it
	# finishes, ammo refills to full automatically.
	#
	# While reloading, we calculate how many rounds have been
	# "refilled" so far and show it on the HUD in grey.  This
	# gives the player a clear countdown: 0 → 1 → 2 → ... → 12.
	#
	# Key concept: **lerp-like progress mapping**.
	# reload_timer goes from RELOAD_TIME down to 0.  We flip that
	# into a 0→1 progress value, then multiply by MAX_AMMO to get
	# how many rounds are "done".  floori() rounds DOWN so you
	# don't see 12 until the reload is truly finished.
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			is_reloading = false
			ammo = _current_max_ammo()
			hud.update_ammo(ammo, _current_max_ammo())
		else:
			var progress: float = 1.0 - (reload_timer / RELOAD_TIME)
			var refilled: int = floori(progress * _current_max_ammo())
			hud.update_reload_progress(refilled, _current_max_ammo())

	# ── Handle active roll ───────────────────────────────────────
	# While rolling, the player zooms in roll_direction at ROLL_SPEED.
	# Normal movement is completely disabled — you're committed to
	# the roll once it starts.  This is called being "locked in" to
	# an action, and it's common in action games.
	#
	# The "return" at the end skips ALL the normal movement code
	# below, so you can't walk, change direction, or start another
	# roll while this one is active.
	if is_rolling:
		roll_timer -= delta
		position += roll_direction * roll_speed * delta
		position.x = clampf(position.x, BOUND_LEFT, BOUND_RIGHT)
		position.y = clampf(position.y, BOUND_TOP, BOUND_BOTTOM)
		if roll_timer <= 0:
			is_rolling = false
			sprite.set_rolling(false)
		return

	# ── Handle active swing timer ────────────────────────────────
	# Count down the swing timer, but DON'T return early!
	# Unlike rolling (which locks you in), swinging lets you keep
	# moving.  This feels great in action games — you can strafe
	# while slashing, kite enemies, and generally stay mobile.
	#
	# The swing_effect node handles its own animation independently.
	# We just track the timer here so we know when swinging ends
	# (which controls whether you can swing again, change facing, etc.)
	if is_swinging:
		swing_timer -= delta
		if swing_timer <= 0:
			is_swinging = false

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
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# ── Check for roll input ─────────────────────────────────────
	# Key concept: **is_action_just_pressed() vs is_action_pressed()**.
	# We use "just_pressed" (not "pressed") because rolling is a
	# single action — tap Space once to roll once.  If we used
	# "pressed", holding Space would try to roll every single frame!
	#
	# We also check: is the cooldown timer at 0?  If not, the roll
	# isn't recharged yet and we ignore the press.
	if Input.is_action_just_pressed("roll") and roll_cooldown_timer <= 0:
		_start_roll(direction)
		return

	# ── Check for attack input ───────────────────────────────────
	# We use "pressed" (not "just_pressed") so HOLDING left click
	# auto-swings as fast as the cooldown allows.  This matters at
	# high momentum — the cooldown gets so short (down to 0.1s!)
	# that no one could click fast enough to keep up.  Holding the
	# button lets the player actually reach max attack speed.
	#
	# The cooldown timer prevents double-swings — you can only
	# swing when it reaches 0, so holding won't bypass anything.
	#
	# Rolling still takes priority (checked above), which is standard
	# in action games — it feels terrible to try to dodge and
	# accidentally attack instead!
	if Input.is_action_pressed("attack") and swing_cooldown_timer <= 0 and not is_rolling:
		_start_swing(_get_attack_direction())

	# ── Check for shoot input ───────────────────────────────────
	# Right-click fires a projectile toward the mouse cursor.
	# One click = one shot (when cooldown is ready and you have ammo).
	if Input.is_action_just_pressed("shoot") and shoot_cooldown_timer <= 0 \
	and not is_rolling and ammo > 0 and not is_reloading:
		_shoot()

	# ── Apply movement ───────────────────────────────────────────
	# position += direction * speed * delta
	#   direction  = WHICH WAY to move (length 1.0 after normalizing)
	#   move_speed = HOW FAST in pixels per second
	#   delta      = seconds since last frame (makes it smooth on any PC)
	position += direction * (move_speed + momentum * MOMENTUM_SPEED_BONUS) * delta

	# ── Stay inside the screen ───────────────────────────────────
	position.x = clampf(position.x, BOUND_LEFT, BOUND_RIGHT)
	position.y = clampf(position.y, BOUND_TOP, BOUND_BOTTOM)

	# ── Update facing direction ──────────────────────────────────
	# Only change direction when the player is actively moving.
	# Horizontal directions (left/right) win ties on diagonals.
	#
	# BUT: skip this while swinging!  During a swing, the character
	# stays facing the attack direction (set in _start_swing).
	# If we let movement keys change facing mid-swing, the character
	# would flip around weirdly and the swing effect would mismatch.
	if direction != Vector2.ZERO and not is_swinging:
		if absf(direction.x) >= absf(direction.y):
			if direction.x < 0.0:
				sprite.set_facing("left")
			else:
				sprite.set_facing("right")
		else:
			if direction.y < 0.0:
				sprite.set_facing("up")
			else:
				sprite.set_facing("down")

	# Tell the sprite whether to animate walking.
	# Skip during swinging — the character holds their attack pose
	# even while sliding around.  Legs animating during a sword
	# slash would look goofy!
	if not is_swinging:
		sprite.set_walking(direction != Vector2.ZERO)


func _start_roll(move_direction: Vector2) -> void:
	## Begins a roll dash.  Called when Space is pressed and cooldown is ready.
	##
	## If the player is holding movement keys, the roll goes in that
	## direction.  If standing still, it goes in the facing direction.
	## This feels natural — you roll WHERE you're heading.
	is_rolling = true
	roll_speed  = ROLL_SPEED    + momentum * ROLL_SPEED_PER_MOMENTUM
	roll_timer  = ROLL_DURATION + momentum * ROLL_DURATION_PER_MOMENTUM
	roll_cooldown_timer = ROLL_COOLDOWN

	# Cancel any active swing — rolling always takes priority!
	# You should always be able to dodge out of an attack.
	is_swinging = false

	# Pick roll direction: movement direction if moving, facing if still
	if move_direction != Vector2.ZERO:
		roll_direction = move_direction
	else:
		roll_direction = _facing_to_vector()

	# Tell the sprite to start the spin animation and stop walking
	sprite.set_walking(false)
	sprite.set_rolling(true)

	# Immediately show the HUD cooldown arrow as empty
	hud.update_roll_cooldown(0.0)


func _start_swing(direction: String) -> void:
	## Begins a melee swing attack toward the mouse cursor.
	##
	## The player can keep moving while swinging!  The character turns
	## to face the attack direction and the swing effect plays, but
	## WASD movement still works.  This is sometimes called "action
	## canceling" — you're not locked into the attack animation.
	##
	## The direction parameter is one of: "up", "down", "left", "right".
	is_swinging = true
	swing_timer = SWING_DURATION
	swing_cooldown_timer = maxf(SWING_COOLDOWN * (1.0 - momentum * MOMENTUM_ATTACK_SPEED_BONUS), 0.1)

	# Pause walk animation during the swing — the character holds
	# their attack pose.  Movement still works (handled in _process),
	# they just slide without leg animation.  Looks like a combat stance!
	sprite.set_walking(false)

	# Turn the character to face the mouse direction.
	# This feels natural — you attack TOWARD where you clicked!
	sprite.set_facing(direction)

	# Tell the swing effect to play its blade animation in that direction.
	swing_effect.start_swing(direction)

	# Check if the swing actually hits anything!
	_check_swing_hits(direction)


func _facing_to_vector() -> Vector2:
	## Converts the sprite's current facing direction string into a Vector2.
	## Used when the player rolls while standing still — we need to know
	## which way "forward" is so the roll has a direction.
	match sprite.facing:
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
		"up": return Vector2.UP
		"down": return Vector2.DOWN
	return Vector2.DOWN  # Fallback (should never happen)


func _check_swing_hits(direction: String) -> void:
	## Checks if anything "targetable" is within range AND in the swing's
	## 180° arc (semicircle).
	##
	## Key concept: **Node communication via groups**.
	## Instead of the player keeping a list of every hittable thing in the
	## game, we ask the SceneTree: "who's in the targetable group?"  Then
	## we check each one — is it close enough?  Is it in the direction we
	## swung?  If both are true, we call hit() on it.
	##
	## This means we can add NEW targetable things (enemies, barrels,
	## whatever) without changing player.gd at all!  They just need to:
	##   1. Add themselves to the "targetable" group
	##   2. Have a hit() method
	## That's it.  The player will automatically find and hit them.
	##
	## Hit detection uses TWO checks:
	##   1. DISTANCE: Is the target within 34px of the player?
	##      (The crescent arc reaches ~33px from center at its farthest.)
	##   2. HEMISPHERE: Is the target on the correct SIDE of the player?
	##      The swing covers a full 180° semicircle, so a "down" swing
	##      hits anything below the player — not just things directly
	##      below, but also things diagonally down-left or down-right.
	##      This matches the visual sweep of the crescent arc!
	##
	## The old code snapped the target to a single cardinal direction
	## (up/down/left/right) and required an exact match.  That was too
	## strict — enemies at the edges of the arc would see the blade pass
	## through them but not get hit.  The hemisphere check is much fairer.
	var targets: Array = get_tree().get_nodes_in_group("targetable")
	for target in targets:
		var diff: Vector2 = target.global_position - global_position
		var dist: float = diff.length()

		# Too far away — skip this target.
		if dist > 34.0:
			continue

		# Hemisphere check: is the target on the correct side?
		# The swing covers a full 180° arc, so we just check if the
		# target is in the correct half of the space around the player.
		# For "down": anything with diff.y >= 0 (below or level).
		# For "right": anything with diff.x >= 0 (right or level).
		var in_arc: bool = false
		match direction:
			"down": in_arc = diff.y >= 0.0
			"up": in_arc = diff.y <= 0.0
			"right": in_arc = diff.x >= 0.0
			"left": in_arc = diff.x <= 0.0

		if in_arc:
			target.hit()
			_on_hit_landed()


func _shoot() -> void:
	## Fires a projectile toward the mouse cursor.
	##
	## Key concept: **creating nodes from code (runtime instantiation)**.
	## In the scene editor, you drag nodes into the tree.  But projectiles
	## don't exist until the player shoots — we need to CREATE them while
	## the game is running.  The steps are:
	##   1. Make a new Node2D
	##   2. Attach the projectile script to it
	##   3. Call setup() to configure its direction, shape, and colors
	##   4. Set its position to where the player is
	##   5. Add it to the scene tree (get_parent() = the Game node)
	##
	## Once added to the tree, the projectile's _process() runs every
	## frame just like any other node — it flies forward, checks for
	## hits, and destroys itself when done.

	# Calculate the direction from the player to the mouse.
	# normalized() makes it length 1.0 so the projectile always
	# moves at SPEED regardless of how far away the mouse is.
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()

	# Build the projectile node
	var projectile := Node2D.new()
	projectile.set_script(ProjectileScript)
	projectile.global_position = global_position
	get_parent().add_child(projectile)

	# Configure it AFTER adding to the tree (some operations need
	# the node to be "inside" the scene tree to work properly).
	# Use the equipped ranged weapon's template so equipping a wand
	# fires magic orbs even if you're playing an armored character!
	var shoot_template: String = char_template
	var ranged_id: String = inventory.get("ranged", {}).get("id", "")
	if ranged_id != "" and WeaponData.WEAPONS.has(ranged_id):
		shoot_template = WeaponData.WEAPONS[ranged_id]["template"]
	projectile.setup(dir, shoot_template, projectile_colors)
	projectile.hit_landed.connect(_on_hit_landed)

	# Use up 1 ammo and start the cooldown
	ammo -= 1
	shoot_cooldown_timer = maxf(SHOOT_COOLDOWN * (1.0 - momentum * MOMENTUM_ATTACK_SPEED_BONUS), 0.1)
	hud.update_ammo(ammo, _current_max_ammo())

	# If we just used the last shot, start reloading!
	if ammo <= 0:
		is_reloading = true
		reload_timer = RELOAD_TIME


func _on_weapon_equipped(slot: String, item: Dictionary) -> void:
	## Called when the player drags a weapon or armor into an equipment slot.
	inventory[slot] = item


func _on_weapon_unequipped(slot: String) -> void:
	## Called when the player drags a weapon or armor OUT of an equipment slot.
	inventory[slot] = {}


func _current_max_ammo() -> int:
	## Returns the effective ammo cap — doubled at 25+ momentum stacks.
	return MAX_AMMO * 2 if _ammo_doubled else MAX_AMMO


## Colors for the burst ring at each 10-stack milestone.
## Each entry matches: [10, 20, 30, 40, 50] stacks.
const BURST_COLORS: Array = [
	Color(1.0, 0.85, 0.2),   # 10 — gold
	Color(1.0, 0.50, 0.1),   # 20 — orange
	Color(1.0, 0.20, 0.2),   # 30 — red
	Color(0.75, 0.2, 1.0),   # 40 — purple
	Color(1.0, 1.0, 1.0),    # 50 — white (max power!)
]


func _on_hit_landed() -> void:
	## Called whenever the player lands a hit (melee or ranged).
	## Adds 1 momentum stack and updates the HUD.
	var prev_momentum: int = momentum
	momentum = mini(momentum + 1, MAX_MOMENTUM)
	_update_momentum_hud()

	# Every 10 stacks, fire a burst ring with a milestone color.
	# The extra check (momentum != prev_momentum) prevents the ring from
	# re-firing when already at max — mini() keeps it at 50, so without
	# this check 50 % 10 == 0 would trigger on every single hit.
	if momentum % 10 == 0 and momentum != prev_momentum:
		var milestone: int = (momentum / 10) - 1   # 0=10stacks, 1=20, … 4=50
		momentum_burst.trigger(BURST_COLORS[milestone], momentum)

	# At exactly 25 stacks, double the ammo cap and fill the extra.
	if momentum == 25 and not _ammo_doubled:
		_ammo_doubled = true
		ammo = mini(ammo * 2, _current_max_ammo())
		hud.update_ammo(ammo, _current_max_ammo())

	# Soul builds up with each hit and persists through damage.
	# It will power spells once those are added!
	soul = minf(soul + SOUL_PER_HIT, MAX_SOUL)
	hud.update_soul(soul, MAX_SOUL)


func take_damage() -> void:
	## Called when an enemy hits the player.
	## Resets ALL momentum and removes the ammo bonus if it was active.
	if momentum == 0:
		return

	# Fire the shatter effect BEFORE resetting, so it knows the current size.
	var break_color: Color = _momentum_color(momentum)
	momentum_burst.trigger_break(break_color, momentum)

	momentum = 0
	_update_momentum_hud()

	if _ammo_doubled:
		_ammo_doubled = false
		ammo = mini(ammo, MAX_AMMO)  # clamp any excess ammo back down
		hud.update_ammo(ammo, MAX_AMMO)


func _momentum_color(stacks: int) -> Color:
	## Returns the fill color matching the current momentum level.
	## Below 10 stacks it's the original blue — no milestone reached yet.
	if stacks >= 50: return BURST_COLORS[4]  # white
	if stacks >= 40: return BURST_COLORS[3]  # purple
	if stacks >= 30: return BURST_COLORS[2]  # red
	if stacks >= 20: return BURST_COLORS[1]  # orange
	if stacks >= 10: return BURST_COLORS[0]  # gold
	return Color(0.2, 0.4, 0.9)              # blue (original bar color)


func _update_momentum_hud() -> void:
	## Updates the momentum bar.  Stays blue from 0–49 stacks,
	## then switches to a scrolling rainbow at max (50 stacks).
	hud.update_momentum(momentum, MAX_MOMENTUM)
	hud.set_momentum_rainbow(momentum == MAX_MOMENTUM)


func _get_attack_direction() -> String:
	## Figures out which direction to swing based on where the mouse is.
	##
	## Key concept: **get_global_mouse_position()**.
	## This returns where the mouse is in GAME coordinates (our 320×180
	## viewport), not in the OS window (1280×720).  Godot handles the 4x
	## scaling automatically because of stretch mode "viewport" — so we
	## don't have to do any math to convert between screen sizes!
	##
	## We calculate the vector from the player to the mouse, then snap it
	## to the nearest cardinal direction (up/down/left/right) using the
	## same horizontal-wins-ties rule as regular movement.
	var mouse_pos: Vector2 = get_global_mouse_position()
	var diff: Vector2 = mouse_pos - global_position

	# Same logic as the facing code in _process():
	# Compare abs(x) vs abs(y) — whichever is bigger wins.
	# Horizontal (left/right) wins ties, just like movement.
	if absf(diff.x) >= absf(diff.y):
		if diff.x < 0.0:
			return "left"
		else:
			return "right"
	else:
		if diff.y < 0.0:
			return "up"
		else:
			return "down"
