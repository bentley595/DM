extends Node2D
## A distant diagonal star field drawn with code.
##
## Stars drift diagonally across the screen (upper-left → lower-right),
## like watching a far-away galaxy slowly rotate.  They're small and dim
## to sell the "at a distance" feel.
##
## Key concept: **velocity as a Vector2**.  Instead of separate fall_speed
## and drift values, each star now has a single "velocity" vector that
## stores BOTH the horizontal (x) and vertical (y) speed together.
## This is how real game engines handle movement — one vector for direction
## AND speed combined.

# ── Exported variables ──────────────────────────────────────────────

## How many stars in the field.
@export var star_count: int = 140
## Viewport dimensions.
@export var area_width: float = 320.0
@export var area_height: float = 180.0

## The diagonal angle in degrees.  0 = straight right, -90 = straight up.
## -65 gives a nice steep upward diagonal — like embers rising from a fire.
@export var fall_angle_degrees: float = -65.0

# ── Internal state ──────────────────────────────────────────────────

var stars: Array = []
var time: float = 0.0

# Fire cycle colors — like drifting embers.
var star_colors: Array[Color] = [
	Color(0.9, 0.2, 0.1),      # red
	Color(1.0, 0.5, 0.1),      # orange
	Color(1.0, 0.75, 0.2),     # yellow-orange
	Color(1.0, 0.5, 0.1),      # orange (repeated so it's more common)
	Color(0.9, 0.2, 0.1),      # red (repeated so it's more common)
]


func _ready() -> void:
	for i in star_count:
		stars.append(_make_star(false))


func _make_star(at_edge: bool) -> Dictionary:
	# ── Calculate the velocity vector from angle + random speed ──
	#
	# deg_to_rad() converts degrees → radians (what sin/cos need).
	# Then we use cos() for the x-component and sin() for the y-component.
	# This is how you turn "an angle + a speed" into actual x/y movement.
	#
	# Think of it like this:
	#   - cos(angle) = how much of the movement goes sideways
	#   - sin(angle) = how much of the movement goes downward
	#   - Multiply both by speed to get the final velocity
	var angle_rad: float = deg_to_rad(fall_angle_degrees)
	var speed: float = randf_range(5.0, 18.0)  # slow — they're far away
	var vel: Vector2 = Vector2(cos(angle_rad) * speed, sin(angle_rad) * speed)

	# ── Spawn position ──
	# If at_edge is true, the star enters from offscreen (bottom or left edge).
	# If false (startup), scatter across the whole screen so it's not empty.
	var pos: Vector2
	if at_edge:
		# Randomly choose: spawn from the bottom edge or the left edge.
		# This keeps the upward diagonal flow fed from both directions.
		if randf() > 0.5:
			# Bottom edge — random x, just below the screen.
			pos = Vector2(randf() * area_width, randf_range(area_height + 2.0, area_height + 15.0))
		else:
			# Left edge — just offscreen left, random y.
			pos = Vector2(randf_range(-15.0, -2.0), randf() * area_height)
	else:
		pos = Vector2(randf() * area_width, randf() * area_height)

	return {
		"pos": pos,
		"vel": vel,
		"color": star_colors.pick_random(),
		"twinkle_speed": randf_range(1.5, 4.0),
		"phase": randf() * TAU,
		# All 1px — distant stars are tiny.  A few lucky ones get 2px.
		"size": 1.0 if randf() > 0.1 else 2.0,
	}


func _process(delta: float) -> void:
	time += delta

	for star in stars:
		# Move the star along its diagonal velocity.
		# This one line handles BOTH the downward and sideways movement
		# because vel is a Vector2 with both x and y components.
		star.pos += star.vel * delta

		# ── Screen wrapping ──
		# Star exited past the top OR the right edge?  Respawn it.
		if star.pos.y < -10.0 or star.pos.x > area_width + 10.0:
			var new_star: Dictionary = _make_star(true)
			star.pos = new_star.pos
			star.vel = new_star.vel

	queue_redraw()


func _draw() -> void:
	for star in stars:
		# Twinkle — dimmer range (0.2 → 0.7) to keep stars subtle and distant.
		var raw_sin: float = sin(time * star.twinkle_speed + star.phase)
		var brightness: float = 0.2 + 0.5 * (raw_sin + 1.0) / 2.0

		var col: Color = star.color * brightness
		col.a = brightness

		draw_rect(Rect2(star.pos, Vector2(star.size, star.size)), col)
