extends Node2D
## Visual effects for momentum milestones, momentum loss, and healing.
##
## Three effects live here:
##   trigger()       — expanding ring when a milestone is hit (every 10 stacks)
##   trigger_break() — shattered ring when the player takes damage and loses all stacks
##   trigger_heal()  — contracting ring when the player drinks a potion
##
## All use _draw() with queue_redraw() each frame so they animate smoothly.

# ── Expanding ring (milestone hit) ───────────────────────────────────

const DURATION: float       = 0.35
const MIN_RADIUS: float     = 4.0
const LINE_WIDTH: float     = 3.0
const RADIUS_BASE: float    = 10.0
const RADIUS_PER_STACK: float = 0.5

var _active:     bool  = false
var _timer:      float = 0.0
var _color:      Color = Color.WHITE
var _max_radius: float = 24.0


func trigger(color: Color, stacks: int) -> void:
	## Expanding shockwave ring — plays on every 10-stack milestone.
	_color      = color
	_max_radius = RADIUS_BASE + stacks * RADIUS_PER_STACK
	_timer      = DURATION
	_active     = true
	queue_redraw()


# ── Breaking ring (momentum lost) ────────────────────────────────────

## How long the shatter animation lasts.
const BREAK_DURATION: float = 0.5

## Number of arc fragments the ring breaks into.
const N_PIECES: int = 8

## Each piece covers this fraction of its slot — gaps between = shattered look.
## 0.55 means 55% filled, 45% gap.
const PIECE_FILL: float = 0.55

## How far the pieces fly outward from the starting radius (in pixels).
const BREAK_EXPAND: float = 12.0

var _break_active: bool  = false
var _break_timer:  float = 0.0
var _break_color:  Color = Color.WHITE
var _break_radius: float = 20.0


func trigger_break(color: Color, stacks: int) -> void:
	## Shattering ring — plays when the player takes damage and loses all momentum.
	## The ring starts at the size matching the current stack count, then
	## breaks into pieces that fly outward and fade.
	_break_color  = color
	_break_radius = RADIUS_BASE + stacks * RADIUS_PER_STACK
	_break_timer  = BREAK_DURATION
	_break_active = true
	queue_redraw()


# ── Healing ring (potion) ──────────────────────────────────────────────

## How long the heal ring animation lasts.
const HEAL_DURATION: float = 0.4

## The ring starts at this radius and shrinks to nearly zero.
## This creates a "gathering inward" feel — like energy flowing INTO
## the player, which is the opposite of the expanding momentum ring.
const HEAL_START_RADIUS: float = 24.0

var _heal_active: bool  = false
var _heal_timer:  float = 0.0
var _heal_color:  Color = Color.GREEN


func trigger_heal(color: Color) -> void:
	## Contracting ring — plays when the player drinks a potion.
	## The ring starts big and shrinks to nothing, like healing
	## energy being absorbed into the player's body.
	_heal_color  = color
	_heal_timer  = HEAL_DURATION
	_heal_active = true
	queue_redraw()


# ── Shared update / draw ──────────────────────────────────────────────

func _process(delta: float) -> void:
	if _active:
		_timer -= delta
		if _timer <= 0.0:
			_active = false
			_timer  = 0.0
		queue_redraw()

	if _break_active:
		_break_timer -= delta
		if _break_timer <= 0.0:
			_break_active = false
			_break_timer  = 0.0
		queue_redraw()

	if _heal_active:
		_heal_timer -= delta
		if _heal_timer <= 0.0:
			_heal_active = false
			_heal_timer  = 0.0
		queue_redraw()


func _draw() -> void:
	# ── Expanding ring ──────────────────────────────────────────────
	if _active:
		var progress: float = 1.0 - (_timer / DURATION)
		var radius:   float = lerpf(MIN_RADIUS, _max_radius, progress)
		var alpha:    float = 1.0 - progress
		draw_arc(
			Vector2.ZERO, radius,
			0.0, TAU, 32,
			Color(_color.r, _color.g, _color.b, alpha),
			LINE_WIDTH
		)

	# ── Shattering ring ─────────────────────────────────────────────
	if _break_active:
		var progress: float = 1.0 - (_break_timer / BREAK_DURATION)
		var alpha:    float = 1.0 - progress

		## Key concept: **drawing arcs around a circle**.
		## We divide 360° (TAU radians) into N_PIECES equal slots.
		## Each piece starts at its slot's angle and covers PIECE_FILL
		## of that slot — leaving a gap before the next piece starts.
		## As progress increases, each piece moves outward (expand) so
		## they look like they're flying away from each other.
		var slot:   float = TAU / N_PIECES
		var expand: float = progress * BREAK_EXPAND
		var radius: float = _break_radius + expand

		for i in N_PIECES:
			var start_angle: float = i * slot
			var end_angle:   float = start_angle + slot * PIECE_FILL
			draw_arc(
				Vector2.ZERO, radius,
				start_angle, end_angle,
				8,
				Color(_break_color.r, _break_color.g, _break_color.b, alpha),
				LINE_WIDTH
			)

	# ── Contracting heal ring ───────────────────────────────────────
	# The opposite of the expanding ring!  It starts big and shrinks
	# to the player's center.  lerpf goes from HEAL_START_RADIUS
	# down to MIN_RADIUS as progress goes 0 -> 1.
	if _heal_active:
		var progress: float = 1.0 - (_heal_timer / HEAL_DURATION)
		var radius: float = lerpf(HEAL_START_RADIUS, MIN_RADIUS, progress)
		var alpha: float = 1.0 - progress * 0.6  # fades slower so it's visible
		draw_arc(
			Vector2.ZERO, radius,
			0.0, TAU, 32,
			Color(_heal_color.r, _heal_color.g, _heal_color.b, alpha),
			LINE_WIDTH
		)
