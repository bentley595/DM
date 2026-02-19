extends CanvasLayer
## Main HUD controller — manages all on-screen UI elements.
##
## Key concept: **CanvasLayer**.
## A CanvasLayer draws its children on a separate rendering layer.  This
## means the HUD stays fixed on screen even if we add a camera that scrolls
## around the game world later!  Without CanvasLayer, HUD elements would
## move with the camera — imagine your health bar running off-screen when
## you walk right.  Not great!
##
## Key concept: **facade pattern** (a simple API that hides complexity).
## This script provides clean functions like update_health() that forward
## the call to the correct child node.  Other scripts (like player.gd or
## game.gd) only need to know about this ONE script — they don't need to
## care about HealthBar or MomentumBar individually.  If we later redesign
## how the health bar works, we only change code here, not everywhere else!

# ── References to child elements ─────────────────────────────────
# @onready means "set this variable right before _ready() runs" — at
# that point all child nodes exist and can be found with the $ shorthand.
# $HealthBar is the same as get_node("HealthBar").

@onready var health_bar: Node2D = $HealthBar
@onready var momentum_bar: Node2D = $MomentumBar
@onready var roll_cooldown: Node2D = $RollCooldown
@onready var ammo_display: Node2D = $AmmoDisplay


func _ready() -> void:
	## Set initial placeholder values so the HUD looks correct before
	## any gameplay systems are connected.  When combat is added later,
	## these will be replaced with real values.
	health_bar.set_value(100.0, 100.0)
	momentum_bar.set_value(0.0, 100.0)
	roll_cooldown.set_cooldown(1.0)
	ammo_display.set_ammo(12, 12)


# ── Public API ───────────────────────────────────────────────────
# These functions are what other scripts call to update the HUD.
# Each one just forwards the data to the right child node.

func update_health(current: float, max_val: float) -> void:
	health_bar.set_value(current, max_val)


func update_momentum(current: float, max_val: float) -> void:
	momentum_bar.set_value(current, max_val)


func update_roll_cooldown(percent: float) -> void:
	roll_cooldown.set_cooldown(percent)


func update_ammo(current: int, max_val: int) -> void:
	ammo_display.set_ammo(current, max_val)


func update_reload_progress(refilled: int, max_val: int) -> void:
	ammo_display.set_reload_progress(refilled, max_val)
